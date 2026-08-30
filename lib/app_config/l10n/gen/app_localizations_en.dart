// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Krizot';

  @override
  String get appTagline => 'Shift scheduling';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get saving => 'Saving…';

  @override
  String get signOut => 'Sign out';

  @override
  String get signInFailed => 'Sign-in failed. Please try again.';

  @override
  String get signingIn => 'Signing in…';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get navScheduler => 'Scheduler';

  @override
  String get navStations => 'Stations';

  @override
  String get navStaff => 'Staff';

  @override
  String get navDispatch => 'Dispatch';

  @override
  String get schedulerTitle => 'Scheduler';

  @override
  String get noActiveStations =>
      'No active stations — create one on the Stations screen.';

  @override
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get previousDay => 'Previous day';

  @override
  String get nextDay => 'Next day';

  @override
  String get dayView => 'Day';

  @override
  String get weekView => 'Week';

  @override
  String get today => 'Today';

  @override
  String get autoFillWhichDay => 'Auto-fill which day?';

  @override
  String get autoFill => 'Auto-Fill';

  @override
  String get stationColumn => 'Station';

  @override
  String get twentyFourSeven => '24/7';

  @override
  String get openShiftShort => 'Open';

  @override
  String get assignmentFailed => 'Assignment failed.';

  @override
  String get openShift => 'Open shift';

  @override
  String assignedTo(String name) {
    return 'Assigned to $name';
  }

  @override
  String get acknowledgedCheck => 'acknowledged ✓';

  @override
  String get notAcknowledgedYet => 'not acknowledged yet';

  @override
  String get findReplacementAi => 'Find replacement (AI)';

  @override
  String get reassign => 'Reassign';

  @override
  String get assign => 'Assign';

  @override
  String get editTimes => 'Edit times';

  @override
  String get unassign => 'Unassign';

  @override
  String get deleteShift => 'Delete shift';

  @override
  String get aiAutoFillTitle => 'AI Auto-Fill';

  @override
  String autoFillExplainer(String date) {
    return 'Fill all open shifts on $date using staff availability and certifications.';
  }

  @override
  String get aiInstructionsLabel => 'Instructions for the AI (optional)';

  @override
  String get aiInstructionsHint =>
      'e.g. Spread shifts evenly; avoid night shifts for new staff';

  @override
  String get planningSchedule => 'Planning schedule…';

  @override
  String get autoFillFailed =>
      'Auto-fill failed — check that the Cloud Function is deployed and an LLM API key is configured.';

  @override
  String filledShifts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Filled $count shifts',
      one: 'Filled 1 shift',
    );
    return '$_temp0';
  }

  @override
  String leftOpen(int count) {
    return ', $count left open';
  }

  @override
  String get runAutoFill => 'Run Auto-Fill';

  @override
  String findReplacementTitle(String station) {
    return 'Find replacement — $station';
  }

  @override
  String assignTitle(String station) {
    return 'Assign — $station';
  }

  @override
  String get thinking => 'Thinking…';

  @override
  String get aiSuggest => 'AI suggest';

  @override
  String get eligibleStaffOnly =>
      'Only certified, available, conflict-free staff are listed.';

  @override
  String get aiNoReplacement => 'AI found no eligible replacement.';

  @override
  String get nobodyEligible =>
      'Nobody is eligible for this shift — check certifications, availability and overlapping assignments.';

  @override
  String get suggestionServiceUnavailable => 'Suggestion service unavailable.';

  @override
  String editShiftTitle(String station) {
    return 'Edit shift — $station';
  }

  @override
  String newShiftTitle(String station) {
    return 'New shift — $station';
  }

  @override
  String get shiftStart => 'Shift start';

  @override
  String get shiftEnd => 'Shift end';

  @override
  String startAt(String time) {
    return 'Start $time';
  }

  @override
  String endAt(String time) {
    return 'End $time';
  }

  @override
  String get failedToSaveShift => 'Failed to save shift.';

  @override
  String get staffTitle => 'Staff';

  @override
  String get dragToAssign => 'Drag onto a shift to assign';

  @override
  String certificationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count certifications',
      one: '1 certification',
    );
    return '$_temp0';
  }

  @override
  String get statusAvailable => 'Available';

  @override
  String get statusSick => 'Sick';

  @override
  String get statusUnavailable => 'Unavailable';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get roleManager => 'Manager';

  @override
  String get roleDispatcher => 'Dispatcher';

  @override
  String get roleEmployee => 'Employee';

  @override
  String get certificationsTitle => 'Certifications';

  @override
  String get noStaffYet =>
      'No staff yet — users appear here after their first sign-in.';

  @override
  String get noCertifications => 'No certifications';

  @override
  String get editStaffMember => 'Edit staff member';

  @override
  String get availabilityLabel => 'Availability';

  @override
  String get noCertificationsInCatalog =>
      'No certifications in the catalog yet.';

  @override
  String get roleLabel => 'Role';

  @override
  String get failedToSaveChanges => 'Failed to save changes.';

  @override
  String get newCertification => 'New certification';

  @override
  String get failedToAddCertification => 'Failed to add certification.';

  @override
  String get certCatalogEmptyExample =>
      'Nothing here yet — e.g. \"Armed Guard\", \"Medic\", \"Type C Responder\".';

  @override
  String get stationsTitle => 'Stations';

  @override
  String get newStation => 'New Station';

  @override
  String get searchStations => 'Search stations…';

  @override
  String get noStations => 'No stations';

  @override
  String get createFirstStation =>
      'Create your first station to start scheduling.';

  @override
  String noStationsMatch(String query) {
    return 'No stations match \"$query\".';
  }

  @override
  String get manning247 => '24/7 manning';

  @override
  String onDemandWindows(String windows) {
    return 'On-demand: $windows';
  }

  @override
  String requiresCerts(String certs) {
    return 'Requires: $certs';
  }

  @override
  String get deleteStationTitle => 'Delete station?';

  @override
  String deleteStationBody(String name) {
    return '\"$name\" and its configuration will be removed. Existing shifts are not deleted.';
  }

  @override
  String get failedToDeleteStation => 'Failed to delete station.';

  @override
  String get onDemandNeedsWindow =>
      'On-demand stations need at least one active window.';

  @override
  String get failedToSaveStation => 'Failed to save station.';

  @override
  String get windowStart => 'Window start';

  @override
  String get windowEnd => 'Window end';

  @override
  String get editStation => 'Edit Station';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get locationLabel => 'Location';

  @override
  String get locationRequired => 'Location is required';

  @override
  String get defaultShiftLength => 'Default shift length (minutes)';

  @override
  String get positiveMinutes => 'Enter a positive number of minutes';

  @override
  String get stationActive => 'Active';

  @override
  String get stationClosed => 'Closed';

  @override
  String get manningLabel => 'Manning';

  @override
  String get onDemand => 'On-demand';

  @override
  String get addWindow => 'Add window';

  @override
  String get requiredCertificationsLabel => 'Required certifications';

  @override
  String get noCertsDefinedAddOnStaff =>
      'No certifications defined yet — add them on the Staff screen.';

  @override
  String get notesLabel => 'Notes';

  @override
  String get chipCovered => 'Covered';

  @override
  String get chipOpen => 'Open';

  @override
  String get chipCritical => 'Critical';

  @override
  String get trainingRowTitle => 'Training';

  @override
  String get newTrainingSession => 'New training session';

  @override
  String get editTrainingSession => 'Edit training session';

  @override
  String get deleteTrainingSession => 'Delete session';

  @override
  String get trainingTypeLabel => 'Session type';

  @override
  String get trainingTypeSimulation => 'Simulation';

  @override
  String get trainingTypeSpectation => 'Spectation';

  @override
  String get trainingTypeTutoring => 'Tutoring';

  @override
  String get certificationLabel => 'Certification';

  @override
  String get traineeLabel => 'Trainee';

  @override
  String get trainerLabel => 'Trainer';

  @override
  String get trainersLabel => 'Trainers';

  @override
  String get noTraineeYet => 'No trainee yet';

  @override
  String get busyTag => '(busy)';

  @override
  String get offSiteTag => '(off-site)';

  @override
  String simulationStaffingRule(String reqs) {
    return 'Simulation staffing: $reqs';
  }

  @override
  String get oneTrainerRule =>
      'Exactly one trainer holding the certification is required.';

  @override
  String get staffingUnsatisfied =>
      'Trainer selection doesn\'t meet the staffing requirement.';

  @override
  String get noUncertifiedUsers => 'Everyone already holds this certification.';

  @override
  String get failedToSaveTraining => 'Failed to save training session.';

  @override
  String defaultFromCertLevel(int level) {
    return 'Default: certification level ($level)';
  }

  @override
  String get dayRequirementsTitle => 'Daily requirements';

  @override
  String dayRequirementsFor(String date) {
    return 'Requirements — $date';
  }

  @override
  String get editRequirements => 'Edit requirements';

  @override
  String get addRequirement => 'Add requirement';

  @override
  String get noDayRequirements => 'No requirements defined for this day.';

  @override
  String get failedToSaveRequirements => 'Failed to save requirements.';

  @override
  String get requiredCountLabel => 'Required';

  @override
  String get searchStaffHint => 'Search staff…';

  @override
  String get findUserSchedule => 'Find user schedule';

  @override
  String userScheduleTitle(String name) {
    return '$name — schedule';
  }

  @override
  String weekOf(String date) {
    return 'Week of $date';
  }

  @override
  String get shiftsSectionTitle => 'Shifts';

  @override
  String get noShiftsThisWeek => 'No shifts this week.';

  @override
  String get noTrainingThisWeek => 'No training this week.';

  @override
  String get noAvailabilityThisWeek => 'No presence windows this week.';

  @override
  String courseTag(int number) {
    return 'Course $number';
  }

  @override
  String get viewScheduleTooltip => 'View schedule';

  @override
  String noUsersMatch(String query) {
    return 'No staff match \"$query\".';
  }

  @override
  String get myAvailabilityTitle => 'My availability';

  @override
  String get addAvailabilityWindow => 'Add window';

  @override
  String get arrivalLabel => 'Arrival';

  @override
  String get departureLabel => 'Departure';

  @override
  String get noAvailabilityYet =>
      'No presence windows yet — add your arrival and departure times.';

  @override
  String get departureAfterArrival => 'Departure must be after arrival.';

  @override
  String get failedToSaveAvailability => 'Failed to save availability.';

  @override
  String get deleteWindowAction => 'Delete window';

  @override
  String get editWindowAction => 'Edit window';

  @override
  String get courseNumberLabel => 'Course number';

  @override
  String earnedOnDate(String date) {
    return 'Earned $date';
  }

  @override
  String get certLevelLabel => 'Level';

  @override
  String get simulationStaffTitle => 'Simulation staffing';

  @override
  String get simulationStaffHint =>
      'Which certification holders (and how many) are needed to run a simulation for this certification.';

  @override
  String get editCertification => 'Edit certification';

  @override
  String get emergencyDispatchTitle => 'Emergency Dispatch';

  @override
  String get eventTypesTitle => 'Event Types';

  @override
  String get triggerCallout => 'TRIGGER CALL-OUT';

  @override
  String get noEventTypesConfigured =>
      'No event types configured yet — define scenarios under Event Types.';

  @override
  String get activeEvents => 'ACTIVE EVENTS';

  @override
  String get noActiveEmergencies => 'No active emergencies.';

  @override
  String triggerEventConfirmTitle(String name) {
    return 'Trigger \"$name\"?';
  }

  @override
  String get triggerEventConfirmBody =>
      'All matching responders will be alerted immediately.';

  @override
  String get triggerAction => 'TRIGGER';

  @override
  String get failedToTrigger =>
      'Failed to trigger — check responders hold the required certifications.';

  @override
  String alertedResponders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Alerted $count responders.',
      one: 'Alerted 1 responder.',
    );
    return '$_temp0';
  }

  @override
  String acknowledgedTally(int acked, int total) {
    return '$acked/$total acknowledged';
  }

  @override
  String get resolve => 'Resolve';

  @override
  String get newEventType => 'New Event Type';

  @override
  String get noScenariosYet =>
      'No scenarios yet — e.g. \"Event Type C\" alerting all Type C Responders.';

  @override
  String get inactiveTag => '(inactive)';

  @override
  String respondersLabel(String certs) {
    return 'Responders: $certs';
  }

  @override
  String stationsLabel(String stations) {
    return 'Stations: $stations';
  }

  @override
  String get pickOneResponderCert =>
      'Pick at least one responder certification.';

  @override
  String get failedToSaveEventType => 'Failed to save event type.';

  @override
  String get editEventType => 'Edit Event Type';

  @override
  String get eventTypeNameLabel => 'Name (e.g. Event Type C)';

  @override
  String get descriptionLabel => 'Description';

  @override
  String get priorityLabel => 'Priority';

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityCritical => 'Critical';

  @override
  String get responderCertsAnyLabel =>
      'Responder certifications (holder of ANY)';

  @override
  String get noCertsDefinedStaffFirst =>
      'No certifications defined — add them on the Staff screen first.';

  @override
  String get stationsInvolved => 'Stations involved';

  @override
  String get eventTypeActive => 'Active';

  @override
  String get inactiveHiddenFromBoard =>
      'Inactive scenarios are hidden from the dispatch board';

  @override
  String hiUser(String name) {
    return 'Hi, $name';
  }

  @override
  String get currentAssignment => 'CURRENT ASSIGNMENT';

  @override
  String get upcomingAssignment => 'UPCOMING ASSIGNMENT';

  @override
  String get noUpcomingAssignments => 'No upcoming assignments.';

  @override
  String get mySchedule => 'My schedule';

  @override
  String emergencyBanner(String name) {
    return 'EMERGENCY: $name';
  }

  @override
  String get ackStandBy => 'Acknowledged — stand by.';

  @override
  String get youAreNeeded => 'You are needed. Acknowledge now.';

  @override
  String get failedToAcknowledge => 'Failed to acknowledge.';

  @override
  String get acknowledgeAction => 'ACKNOWLEDGE';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get failedToAcknowledgeRetry => 'Failed to acknowledge — try again.';
}
