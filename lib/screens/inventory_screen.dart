import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/drug.dart';
import '../providers/drug_provider.dart';
import '../core/constants/drug_categories.dart';
import '../core/theme/app_theme.dart';

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
      return drug.name.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Inventory',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (drugProvider.allDrugs.isEmpty && !drugProvider.isLoading)
            TextButton(
              onPressed: () => drugProvider.seedSampleCatalog(),
              child: const Text('Seed sample data'),
            ),
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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, AppTheme.navBarClearance),
                      children: [
                        for (final drug in drugs)
                          _InventoryRow(
                            drug: drug,
                            onEdit: () => _showEditDrugSheet(context, drug),
                          ),
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

class _InventoryRow extends StatelessWidget {
  const _InventoryRow({
    required this.drug,
    required this.onEdit,
  });

  final Drug drug;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: drug.hasImage
                  ? Image.memory(base64Decode(drug.imageBase64!), width: 44, height: 44, fit: BoxFit.cover)
                  : Container(
                      width: 44,
                      height: 44,
                      color: categoryColor(drug.category).withValues(alpha: 0.1),
                      child: Icon(categoryIcon(drug.category), color: categoryColor(drug.category)),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drug.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${drug.stockQuantity} units',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: drug.isLowStock ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
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
  late final _stockController =
      TextEditingController(text: widget.existingDrug?.stockQuantity.toString() ?? '');
  late final _reorderLevelController =
      TextEditingController(text: widget.existingDrug?.reorderLevel.toString() ?? '');
  late final _priceController =
      TextEditingController(text: widget.existingDrug?.price.toStringAsFixed(0) ?? '');
  late final _discountController =
      TextEditingController(text: widget.existingDrug?.discountPercent.toString() ?? '0');
  late String _category = widget.existingDrug?.category ?? kDrugCategories.first;

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
      if (existing == null) {
        await drugProvider.addDrug(
          name: _nameController.text.trim(),
          category: _category,
          stockQuantity: int.parse(_stockController.text),
          reorderLevel: int.parse(_reorderLevelController.text),
          price: double.parse(_priceController.text),
          discountPercent: int.parse(_discountController.text).clamp(0, 99),
          imageBase64: imageBase64,
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