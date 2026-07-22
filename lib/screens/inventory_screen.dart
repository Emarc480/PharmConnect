import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/drug.dart';
import '../providers/drug_provider.dart';
import '../core/constants/drug_categories.dart';
import '../core/constants/countries.dart';


class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drugProvider = context.watch<DrugProvider>();
    final drugs = drugProvider.allDrugs.where((drug) {
      final matchesQuery = drug.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory = drugProvider.selectedCategory == 'All' ||
          drug.category == drugProvider.selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    // Group into per-category sections, in the same fixed order as
    // kDrugCategories (so "Painkillers"-style sections always appear
    // in a stable order), skipping any category with no matches.
    final grouped = <String, List<Drug>>{};
    for (final category in kDrugCategories) {
      final inCategory = drugs.where((d) => d.category == category).toList();
      if (inCategory.isNotEmpty) grouped[category] = inCategory;
    }
    // Anything with a category outside the known list (shouldn't
    // normally happen) still shows up, grouped by its own category
    // name at the end.
    final knownCategories = kDrugCategories.toSet();
    final leftoverCategories = drugs
        .map((d) => d.category)
        .where((c) => !knownCategories.contains(c))
        .toSet();
    for (final category in leftoverCategories) {
      grouped[category] = drugs.where((d) => d.category == category).toList();
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Inventory',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Add drug',
            onPressed: () => _showAddDrugSheet(context),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: SafeArea(
        child: drugProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search inventory...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: drugProvider.categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final category = drugProvider.categories[i];
                        final isSelected = category == drugProvider.selectedCategory;
                        return ChoiceChip(
                          avatar: category == 'All'
                              ? null
                              : Icon(
                                  categoryIcon(category),
                                  size: 16,
                                  color: isSelected ? Colors.white : categoryColor(category),
                                ),
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                          onSelected: (_) => drugProvider.setCategory(category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                 Expanded(
                    child: grouped.isEmpty
                        ? const Center(child: Text('No drugs found'))
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            children: [
                              for (final entry in grouped.entries) ...[
                                _CategorySectionHeader(
                                  category: entry.key,
                                  count: entry.value.length,
                                ),
                                const SizedBox(height: 10),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: entry.value.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.46,
                                  ),
                                  itemBuilder: (context, i) {
                                    final drug = entry.value[i];
                                    return _InventoryGridCard(
                                      drug: drug,
                                      onTap: () => _showEditDrugSheet(context, drug),
                                      onDecrement: drug.stockQuantity > 0
                                          ? () => drugProvider.adjustStock(drug.id, -1)
                                          : null,
                                      onIncrement: () => drugProvider.adjustStock(drug.id, 1),
                                    );
                                  },
                                ),
                                const SizedBox(height: 22),
                              ],
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showAddDrugSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _DrugForm(),
    );
  }

  /// Opens the same form used to add a drug, pre-filled with this
  /// drug's current details so staff can edit name, category, stock,
  /// reorder level, price, discount and photo in one place, or delete
  /// the drug entirely.
  void _showEditDrugSheet(BuildContext context, Drug drug) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _DrugForm(existingDrug: drug),
    );
  }
}

/// Section title shown above each category's group of cards — e.g.
/// "Pain & Fever" above Paracetamol/Tramadol, matching the pharmacy's
/// own category breakdown (drug_details.pdf) rather than a flat list.
class _CategorySectionHeader extends StatelessWidget {
  const _CategorySectionHeader({required this.category, required this.count});

  final String category;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(categoryIcon(category), size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            category,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Two-column inventory card matching the customer-facing
/// [ProductGridCard]'s visual language (rounded photo tile, stock
/// pill, white card with soft shadow) but built for staff: a
/// low-stock/out-of-stock badge instead of a discount badge, an edit
/// pencil instead of a wishlist heart, a country-of-origin flag row,
/// and an inline +/- stepper for adjusting stock without opening the
/// full edit form.
class _InventoryGridCard extends StatelessWidget {
  const _InventoryGridCard({
    required this.drug,
    required this.onTap,
    required this.onDecrement,
    required this.onIncrement,
  });

  final Drug drug;
  final VoidCallback onTap;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  Color get _stockColor {
    if (drug.stockQuantity <= 0) return Colors.grey;
    return drug.isLowStock ? Colors.orange.shade700 : Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOutOfStock = drug.stockQuantity <= 0;
    final countryName = countryNameForCode(drug.countryOfOrigin);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1.35,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: drug.hasImage
                        ? Image.memory(
                            base64Decode(drug.imageBase64!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: categoryColor(drug.category).withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(categoryIcon(drug.category), size: 40, color: categoryColor(drug.category)),
                            ),
                          ),
                  ),
                  if (isOutOfStock || drug.isLowStock)
                    Positioned(
                      left: 0,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey.shade600 : Colors.orange.shade700,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                        ),
                        child: Text(
                          isOutOfStock ? 'Out of Stock' : 'Low Stock',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_outlined, size: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.25),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(categoryIcon(drug.category), size: 12, color: categoryColor(drug.category)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          drug.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  if (drug.hasManufacturer) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Manufactured by:',
                      style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                    ),
                    Text(
                      drug.manufacturerName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.black87),
                    ),
                  ],
                  if (countryName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(countryFlagEmoji(drug.countryOfOrigin), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            countryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    drug.formattedPrice,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 34,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _StepperButton(icon: Icons.remove, onTap: onDecrement),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${drug.stockQuantity}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _stockColor),
                              ),
                              Text(
                                'units',
                                style: TextStyle(fontSize: 8, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                        _StepperButton(icon: Icons.add, onTap: onIncrement),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small square tap target used inside the stock stepper. Disabled
/// (greyed, no tap) when [onTap] is null — e.g. can't decrement below
/// zero units.
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 34,
        child: Icon(icon, size: 16, color: enabled ? Colors.black87 : Colors.grey.shade300),
      ),
    );
  }
}

/// One form for both "Add drug" and "Edit drug". Pass [existingDrug] to
/// pre-fill every field for editing (name, category, stock, reorder
/// level, price, discount, photo) and to enable the delete action;
/// leave it null to add a brand-new drug.
class _DrugForm extends StatefulWidget {
  const _DrugForm({this.existingDrug});

  final Drug? existingDrug;

  bool get isEditing => existingDrug != null;

  @override
  State<_DrugForm> createState() => _DrugFormState();
}

class _DrugFormState extends State<_DrugForm> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.existingDrug?.name ?? '');
  late final _manufacturerController =
      TextEditingController(text: widget.existingDrug?.manufacturerName ?? '');
  late final _stockController =
      TextEditingController(text: widget.existingDrug?.stockQuantity.toString() ?? '');
  late final _reorderLevelController =
      TextEditingController(text: widget.existingDrug?.reorderLevel.toString() ?? '');
  late final _priceController =
      TextEditingController(text: widget.existingDrug?.price.toStringAsFixed(0) ?? '');
  late final _discountController =
      TextEditingController(text: widget.existingDrug?.discountPercent.toString() ?? '0');
  late String _category = widget.existingDrug?.category ?? kDrugCategories.first;

  /// ISO country code (e.g. 'UG') for the "Country of origin"
  /// dropdown. Null/unselected is allowed — country of manufacture
  /// isn't always known when a drug is first added.
  late String? _countryCode = widget.existingDrug?.countryOfOrigin;

  /// A freshly picked photo (camera/gallery), overriding whatever
  /// photo the drug already had.
  File? _pickedImage;

  /// True once staff explicitly remove the existing photo without
  /// picking a new one.
  bool _removeExistingPhoto = false;

  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _manufacturerController.dispose();
    _stockController.dispose();
    _reorderLevelController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  bool get _hasExistingPhoto => widget.existingDrug?.hasImage ?? false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, maxWidth: 800, imageQuality: 60);
      if (picked != null) {
        setState(() {
          _pickedImage = File(picked.path);
          _removeExistingPhoto = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the camera/gallery.')),
      );
    }
  }

  void _showSourceSheet() {
    final canRemove = _pickedImage != null || (_hasExistingPhoto && !_removeExistingPhoto);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (canRemove)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Remove photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _pickedImage = null;
                    _removeExistingPhoto = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final showExistingPhoto = _hasExistingPhoto && !_removeExistingPhoto && _pickedImage == null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isEditing ? 'Edit drug' : 'Add drug',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _showSourceSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_pickedImage!, width: double.infinity, fit: BoxFit.cover),
                        )
                      : showExistingPhoto
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(widget.existingDrug!.imageBase64!),
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade500),
                                const SizedBox(height: 6),
                                Text('Add a photo (optional)', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Drug name', border: OutlineInputBorder()),
                validator: _requiredText,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _manufacturerController,
                decoration: const InputDecoration(
                  labelText: 'Manufacturer (optional)',
                  hintText: 'e.g. Bayer AG',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: [
                  for (final category in kDrugCategories)
                    DropdownMenuItem(
                      value: category,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(categoryIcon(category), size: 18, color: categoryColor(category)),
                          const SizedBox(width: 8),
                          Text(category),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reorderLevelController,
                decoration: const InputDecoration(labelText: 'Reorder level', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  labelText: 'Discount %  (0 for none)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: _requiredNumber,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _countryCode,
                decoration: const InputDecoration(labelText: 'Country of origin', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Not specified'),
                  ),
                  for (final country in kManufacturerCountries)
                    DropdownMenuItem<String?>(
                      value: country.code,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(countryFlagEmoji(country.code), style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(country.name),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _countryCode = value),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving || _isDeleting ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isEditing ? 'Save changes' : 'Save drug'),
              ),
              if (widget.isEditing) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _isSaving || _isDeleting ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  icon: _isDeleting
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Delete drug'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    return null;
  }

  String? _requiredNumber(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null || number < 0) return 'Enter a valid number';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final navigator = Navigator.of(context);
    final drugProvider = context.read<DrugProvider>();
    try {
      // Resolve the final photo: a newly picked file wins, otherwise
      // keep the existing one unless it was explicitly removed.
      String? imageBase64;
      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        imageBase64 = base64Encode(bytes);
      } else if (!_removeExistingPhoto) {
        imageBase64 = widget.existingDrug?.imageBase64;
      }

      final existing = widget.existingDrug;
      final manufacturerText = _manufacturerController.text.trim();
      final manufacturerName = manufacturerText.isEmpty ? null : manufacturerText;
      if (existing == null) {
        await drugProvider.addDrug(
          name: _nameController.text.trim(),
          category: _category,
          stockQuantity: int.parse(_stockController.text),
          reorderLevel: int.parse(_reorderLevelController.text),
          price: double.parse(_priceController.text),
          discountPercent: int.parse(_discountController.text).clamp(0, 99),
          imageBase64: imageBase64,
          countryOfOrigin: _countryCode,
          manufacturerName: manufacturerName,
        );
      } else {
        await drugProvider.updateDrug(
          Drug(
            id: existing.id,
            name: _nameController.text.trim(),
            description: existing.description,
            category: _category,
            price: double.parse(_priceController.text),
            stockQuantity: int.parse(_stockController.text),
            reorderLevel: int.parse(_reorderLevelController.text),
            discountPercent: int.parse(_discountController.text).clamp(0, 99),
            imageBase64: imageBase64,
            countryOfOrigin: _countryCode,
            manufacturerName: manufacturerName,
          ),
        );
      }
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save ${widget.isEditing ? 'changes' : 'drug'}. Please try again.')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existingDrug;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete drug?'),
        content: Text('This permanently removes "${existing.name}" from inventory. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    final navigator = Navigator.of(context);
    final drugProvider = context.read<DrugProvider>();
    try {
      await drugProvider.deleteDrug(existing.id);
      navigator.pop();
    } catch (_) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete drug. Please try again.')),
        );
      }
    }
  }
}