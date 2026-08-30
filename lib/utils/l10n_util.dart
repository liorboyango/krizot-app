import '../app_config/l10n/gen/app_localizations.dart';
import '../entities/app_user.dart';
import '../entities/training_session.dart';

/// Localized labels for enums whose `.name` used to be shown raw in the UI.
class L10nUtil {
  L10nUtil._();

  static String roleLabel(AppLocalizations l10n, UserRole role) =>
      switch (role) {
        UserRole.admin => l10n.roleAdmin,
        UserRole.manager => l10n.roleManager,
        UserRole.dispatcher => l10n.roleDispatcher,
        UserRole.employee => l10n.roleEmployee,
      };

  static String statusLabel(AppLocalizations l10n, UserStatus status) =>
      switch (status) {
        UserStatus.available => l10n.statusAvailable,
        UserStatus.sick => l10n.statusSick,
        UserStatus.unavailable => l10n.statusUnavailable,
      };

  static String trainingTypeLabel(AppLocalizations l10n, TrainingType type) =>
      switch (type) {
        TrainingType.simulation => l10n.trainingTypeSimulation,
        TrainingType.spectation => l10n.trainingTypeSpectation,
        TrainingType.tutoring => l10n.trainingTypeTutoring,
      };
}
