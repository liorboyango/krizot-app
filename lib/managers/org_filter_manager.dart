import 'package:rxdart/rxdart.dart';

import '../entities/app_user.dart';
import '../entities/station.dart';

/// The dashboard-wide org filter that lives in the web sidebar: a unit
/// (site) selector plus department→role checkboxes. Every admin surface
/// (scheduler, stations, staff, roster) renders through it.
class OrgFilterManager {
  /// Emits after every mutation; seeded so StreamBuilders paint immediately.
  final _changes = BehaviorSubject<void>.seeded(null);
  Stream<void> get changesStream => _changes.stream;

  Site? _site;

  /// Selected unit — null shows every site.
  Site? get site => _site;

  set site(Site? value) {
    _site = value;
    _changes.sink.add(null);
  }

  /// Department → still-included roles ("checkboxes of Department and
  /// deeper to Role"). Everything starts checked.
  final Map<Department, Set<JobRole>> _selectedRoles = {
    for (final department in Department.values) department: {...JobRole.values},
  };

  bool isRoleSelected(Department department, JobRole jobRole) =>
      _selectedRoles[department]!.contains(jobRole);

  /// Tri-state checkbox value: true = every role checked, false = none,
  /// null = partial.
  bool? departmentState(Department department) {
    final selected = _selectedRoles[department]!;
    if (selected.length == JobRole.values.length) return true;
    if (selected.isEmpty) return false;
    return null;
  }

  void toggleRole(Department department, JobRole jobRole, bool selected) {
    if (selected) {
      _selectedRoles[department]!.add(jobRole);
    } else {
      _selectedRoles[department]!.remove(jobRole);
    }
    _changes.sink.add(null);
  }

  /// Checks every role of the department, or clears them all when every
  /// role was already checked.
  void toggleDepartment(Department department) {
    final selected = _selectedRoles[department]!;
    if (selected.length == JobRole.values.length) {
      selected.clear();
    } else {
      selected.addAll(JobRole.values);
    }
    _changes.sink.add(null);
  }

  /// Whether anything deviates from the everything-visible default (drives
  /// the badge on the compact filter button).
  bool get hasActiveFilter =>
      _site != null ||
      _selectedRoles.values.any(
        (roles) => roles.length != JobRole.values.length,
      );

  /// Staff visibility: the unit must match when one is selected; users
  /// without a full placement stay visible (the "Unassigned" sections).
  bool matchesUser(AppUser user) {
    if (_site != null && user.site != _site) return false;
    if (user.department == null || user.jobRole == null) return true;
    return _selectedRoles[user.department]!.contains(user.jobRole);
  }

  /// Whether a scope's unit layer passes the selected unit — null on either
  /// side is a wildcard. Used directly by unit-only scopes (event types,
  /// emergency events).
  bool matchesSite(Site? scopeSite) =>
      _site == null || scopeSite == null || scopeSite == _site;

  /// Station visibility by its org scope. A null scope layer is a wildcard,
  /// so globally-scoped stations show under every unit.
  bool matchesStation(Station station) {
    if (!matchesSite(station.site)) return false;
    if (station.department != null) {
      final selected = _selectedRoles[station.department]!;
      return station.jobRole == null
          ? selected.isNotEmpty
          : selected.contains(station.jobRole);
    }
    if (station.jobRole != null) {
      return _selectedRoles.values.any(
        (roles) => roles.contains(station.jobRole),
      );
    }
    return true;
  }

  Future<void> dispose() => _changes.close();
}
