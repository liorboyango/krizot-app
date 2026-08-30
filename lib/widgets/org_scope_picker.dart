import 'package:flutter/material.dart';

import '../app_config/l10n/gen/app_localizations.dart';
import '../entities/org_scope.dart';
import '../utils/l10n_util.dart';

/// Three dropdowns for an org scope (unit / department / role), each with a
/// "None" wildcard. Used by the staff, station and certification editors.
class OrgScopePicker extends StatelessWidget {
  final Site? site;
  final Department? department;
  final JobRole? jobRole;
  final ValueChanged<Site?> onSiteChanged;
  final ValueChanged<Department?> onDepartmentChanged;
  final ValueChanged<JobRole?> onJobRoleChanged;

  const OrgScopePicker({
    super.key,
    required this.site,
    required this.department,
    required this.jobRole,
    required this.onSiteChanged,
    required this.onDepartmentChanged,
    required this.onJobRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<Site?>(
            initialValue: site,
            decoration:
                InputDecoration(labelText: l10n.unitLabel, isDense: true),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.noneOption)),
              for (final value in Site.values)
                DropdownMenuItem(value: value, child: Text(value.wireName)),
            ],
            onChanged: onSiteChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<Department?>(
            initialValue: department,
            decoration: InputDecoration(
                labelText: l10n.departmentLabel, isDense: true),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.noneOption)),
              for (final value in Department.values)
                DropdownMenuItem(
                    value: value,
                    child: Text(L10nUtil.departmentLabel(l10n, value))),
            ],
            onChanged: onDepartmentChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<JobRole?>(
            initialValue: jobRole,
            decoration:
                InputDecoration(labelText: l10n.jobRoleLabel, isDense: true),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.noneOption)),
              for (final value in JobRole.values)
                DropdownMenuItem(
                    value: value,
                    child: Text(L10nUtil.jobRoleLabel(l10n, value))),
            ],
            onChanged: onJobRoleChanged,
          ),
        ),
      ],
    );
  }

  /// 'unit · department · role' summary of a scope; null for an all-null
  /// (everyone) scope.
  static String? scopeLabel(
    AppLocalizations l10n, {
    Site? site,
    Department? department,
    JobRole? jobRole,
  }) {
    final parts = [
      if (site != null) '${l10n.unitLabel} ${site.wireName}',
      if (department != null) L10nUtil.departmentLabel(l10n, department),
      if (jobRole != null) L10nUtil.jobRoleLabel(l10n, jobRole),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}
