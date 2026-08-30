/// The organizational layers: unit (site), department, and professional
/// role. Users are placed in them; stations and certifications may be
/// scoped to them (a null layer means "applies to everyone").
library;

/// Organizational unit (site). Wire values: '506' / '509'.
enum Site {
  site506('506'),
  site509('509');

  final String wireName;
  const Site(this.wireName);

  static Site? fromString(String? value) =>
      Site.values.where((site) => site.wireName == value).firstOrNull;
}

enum Department {
  mesima,
  taavura;

  static Department? fromString(String? value) =>
      Department.values.where((department) => department.name == value)
          .firstOrNull;
}

/// Professional role within a department — distinct from `UserRole`, which
/// is the app permission level.
enum JobRole {
  hagana,
  bakara,
  officer;

  static JobRole? fromString(String? value) =>
      JobRole.values.where((jobRole) => jobRole.name == value).firstOrNull;
}
