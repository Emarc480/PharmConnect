/// Countries of manufacture used across the app — the Add/Edit Drug
/// form's "Country of origin" dropdown, and the flag shown on
/// Inventory's drug cards. Sourced from the pharmacy's own
/// drug-reference sheet (common countries of manufacture for the 18
/// drug categories), not hardcoded per-drug — staff pick one when
/// adding a drug, same as they pick a category.
library;

class Country {
  final String code; // ISO 3166-1 alpha-2, used to derive the flag emoji
  final String name;

  const Country(this.code, this.name);
}

const List<Country> kManufacturerCountries = [
  Country('UG', 'Uganda'),
  Country('IN', 'India'),
  Country('DE', 'Germany'),
  Country('FR', 'France'),
  Country('DK', 'Denmark'),
  Country('BE', 'Belgium'),
  Country('KE', 'Kenya'),
  Country('CN', 'China'),
];

/// Converts a 2-letter ISO country code into its flag emoji by
/// shifting each letter into the Unicode "regional indicator symbol"
/// range — no image assets or packages needed. Falls back to a plain
/// pin icon glyph if the code isn't recognized/empty.
String countryFlagEmoji(String? isoCode) {
  if (isoCode == null || isoCode.length != 2) return '';
  final code = isoCode.toUpperCase();
  const base = 0x1F1E6; // regional indicator symbol letter A
  final first = base + (code.codeUnitAt(0) - 'A'.codeUnitAt(0));
  final second = base + (code.codeUnitAt(1) - 'A'.codeUnitAt(0));
  return String.fromCharCode(first) + String.fromCharCode(second);
}

/// Full country name for a stored ISO code, or null if unset/unknown.
String? countryNameForCode(String? isoCode) {
  if (isoCode == null) return null;
  for (final c in kManufacturerCountries) {
    if (c.code == isoCode) return c.name;
  }
  return null;
}
