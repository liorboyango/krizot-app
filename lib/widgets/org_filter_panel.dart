import 'package:flutter/material.dart';

import '../app_config/l10n/gen/app_localizations.dart';
import '../app_config/service_locator.dart';
import '../entities/org_scope.dart';
import '../managers/org_filter_manager.dart';
import '../utils/app_colors.dart';
import '../utils/l10n_util.dart';

/// The dashboard-wide filter panel backed by [OrgFilterManager]: the unit
/// selector plus the department/role checkbox tree. `onDark` styles it for
/// the navy sidebar; the light variant is used inside [OrgFilterButton]'s
/// dialog. `unitOnly` drops the department/role tree — used for dispatchers,
/// whose only filterable surface (dispatch) is scoped by unit alone.
class OrgFilterPanel extends StatelessWidget {
  final bool onDark;
  final bool unitOnly;

  const OrgFilterPanel({super.key, this.onDark = false, this.unitOnly = false});

  Color get _label => onDark ? Colors.white : AppColors.textPrimary;
  Color get _muted =>
      onDark ? AppColors.sidebarTextMuted : AppColors.textSecondary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orgFilter = locator<OrgFilterManager>();
    return StreamBuilder<void>(
      stream: orgFilter.changesStream,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.unitLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
          const SizedBox(height: 6),
          OrgUnitSelector(onDark: onDark),
          if (!unitOnly) ...[
            const SizedBox(height: 12),
            Text(
              '${l10n.departmentLabel} · ${l10n.jobRoleLabel}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
            for (final department in Department.values)
              _departmentFilter(l10n, orgFilter, department),
          ],
        ],
      ),
    );
  }

  /// One department's tri-state checkbox with its role checkboxes indented
  /// below it.
  Widget _departmentFilter(
    AppLocalizations l10n,
    OrgFilterManager orgFilter,
    Department department,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _checkboxRow(
          tristate: true,
          value: orgFilter.departmentState(department),
          onChanged: (_) => orgFilter.toggleDepartment(department),
          label: L10nUtil.departmentLabel(l10n, department),
          bold: true,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final jobRole in JobRole.values)
                _checkboxRow(
                  value: orgFilter.isRoleSelected(department, jobRole),
                  onChanged: (checked) => orgFilter.toggleRole(
                    department,
                    jobRole,
                    checked ?? false,
                  ),
                  label: L10nUtil.jobRoleLabel(l10n, jobRole),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _checkboxRow({
    required bool? value,
    required ValueChanged<bool?> onChanged,
    required String label,
    bool tristate = false,
    bool bold = false,
  }) {
    return InkWell(
      onTap: () => onChanged(value == true ? false : true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            tristate: tristate,
            value: value,
            onChanged: onChanged,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            activeColor: AppColors.accent,
            checkColor: Colors.white,
            side: onDark
                ? const BorderSide(color: Colors.white54, width: 2)
                : null,
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
                color: bold ? _label : _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The unit (site) segmented selector — "All" plus one segment per site.
class OrgUnitSelector extends StatelessWidget {
  final bool onDark;

  const OrgUnitSelector({super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orgFilter = locator<OrgFilterManager>();
    return StreamBuilder<void>(
      stream: orgFilter.changesStream,
      builder: (context, _) => SegmentedButton<Site?>(
        segments: [
          ButtonSegment<Site?>(value: null, label: Text(l10n.allUnits)),
          for (final site in Site.values)
            ButtonSegment<Site?>(value: site, label: Text(site.wireName)),
        ],
        selected: {orgFilter.site},
        onSelectionChanged: (selection) => orgFilter.site = selection.first,
        showSelectedIcon: false,
        style: onDark ? _darkStyle : _lightStyle,
      ),
    );
  }

  static const _lightStyle = ButtonStyle(visualDensity: VisualDensity.compact);

  static final _darkStyle = ButtonStyle(
    visualDensity: VisualDensity.compact,
    side: const WidgetStatePropertyAll(BorderSide(color: Colors.white30)),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Colors.white
          : AppColors.sidebarTextMuted,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppColors.accent
          : Colors.transparent,
    ),
  );
}

/// Compact filter entry point: an icon button (badged while any filter is
/// active) opening the full panel in a dialog. Used where the sidebar has
/// no room for the inline panel.
class OrgFilterButton extends StatelessWidget {
  final Color? color;
  final bool unitOnly;

  const OrgFilterButton({super.key, this.color, this.unitOnly = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final orgFilter = locator<OrgFilterManager>();
    return StreamBuilder<void>(
      stream: orgFilter.changesStream,
      builder: (context, _) => IconButton(
        tooltip: l10n.filtersTitle,
        icon: Badge(
          isLabelVisible: unitOnly
              ? orgFilter.site != null
              : orgFilter.hasActiveFilter,
          child: Icon(Icons.filter_alt_outlined, color: color),
        ),
        onPressed: () => showDialog(
          context: context,
          routeSettings: const RouteSettings(name: 'org_filter_dialog'),
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.filtersTitle),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: OrgFilterPanel(unitOnly: unitOnly),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.close),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Narrow-layout (bottom-navigation) substitute for the sidebar filter: a
/// slim strip with the unit selector inline and the rest behind the dialog.
class OrgFilterBar extends StatelessWidget {
  final bool unitOnly;

  const OrgFilterBar({super.key, this.unitOnly = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Text(
            l10n.unitLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          const OrgUnitSelector(),
          const Spacer(),
          // With the unit selector already inline there is nothing more to
          // configure for unit-only users.
          if (!unitOnly) const OrgFilterButton(),
        ],
      ),
    );
  }
}
