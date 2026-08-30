import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Krizot'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Shift scheduling & dispatch'**
  String get appTagline;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get saving;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please try again.'**
  String get signInFailed;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in…'**
  String get signingIn;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @navScheduler.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get navScheduler;

  /// No description provided for @navStations.
  ///
  /// In en, this message translates to:
  /// **'Stations'**
  String get navStations;

  /// No description provided for @navStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get navStaff;

  /// No description provided for @navDispatch.
  ///
  /// In en, this message translates to:
  /// **'Dispatch'**
  String get navDispatch;

  /// No description provided for @schedulerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get schedulerTitle;

  /// No description provided for @noActiveStations.
  ///
  /// In en, this message translates to:
  /// **'No active stations — create one on the Stations screen.'**
  String get noActiveStations;

  /// No description provided for @previousWeek.
  ///
  /// In en, this message translates to:
  /// **'Previous week'**
  String get previousWeek;

  /// No description provided for @nextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get nextWeek;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @autoFillWhichDay.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill which day?'**
  String get autoFillWhichDay;

  /// No description provided for @autoFill.
  ///
  /// In en, this message translates to:
  /// **'Auto-Fill'**
  String get autoFill;

  /// No description provided for @stationColumn.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get stationColumn;

  /// No description provided for @twentyFourSeven.
  ///
  /// In en, this message translates to:
  /// **'24/7'**
  String get twentyFourSeven;

  /// No description provided for @openShiftShort.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get openShiftShort;

  /// No description provided for @assignmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Assignment failed.'**
  String get assignmentFailed;

  /// No description provided for @openShift.
  ///
  /// In en, this message translates to:
  /// **'Open shift'**
  String get openShift;

  /// No description provided for @assignedTo.
  ///
  /// In en, this message translates to:
  /// **'Assigned to {name}'**
  String assignedTo(String name);

  /// No description provided for @acknowledgedCheck.
  ///
  /// In en, this message translates to:
  /// **'acknowledged ✓'**
  String get acknowledgedCheck;

  /// No description provided for @notAcknowledgedYet.
  ///
  /// In en, this message translates to:
  /// **'not acknowledged yet'**
  String get notAcknowledgedYet;

  /// No description provided for @findReplacementAi.
  ///
  /// In en, this message translates to:
  /// **'Find replacement (AI)'**
  String get findReplacementAi;

  /// No description provided for @reassign.
  ///
  /// In en, this message translates to:
  /// **'Reassign'**
  String get reassign;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @editTimes.
  ///
  /// In en, this message translates to:
  /// **'Edit times'**
  String get editTimes;

  /// No description provided for @unassign.
  ///
  /// In en, this message translates to:
  /// **'Unassign'**
  String get unassign;

  /// No description provided for @deleteShift.
  ///
  /// In en, this message translates to:
  /// **'Delete shift'**
  String get deleteShift;

  /// No description provided for @aiAutoFillTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Auto-Fill'**
  String get aiAutoFillTitle;

  /// No description provided for @autoFillExplainer.
  ///
  /// In en, this message translates to:
  /// **'Fill all open shifts on {date} using staff availability and certifications.'**
  String autoFillExplainer(String date);

  /// No description provided for @aiInstructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructions for the AI (optional)'**
  String get aiInstructionsLabel;

  /// No description provided for @aiInstructionsHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Spread shifts evenly; avoid night shifts for new staff'**
  String get aiInstructionsHint;

  /// No description provided for @planningSchedule.
  ///
  /// In en, this message translates to:
  /// **'Planning schedule…'**
  String get planningSchedule;

  /// No description provided for @autoFillFailed.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill failed — check that the Cloud Function is deployed and an LLM API key is configured.'**
  String get autoFillFailed;

  /// No description provided for @filledShifts.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Filled 1 shift} other{Filled {count} shifts}}'**
  String filledShifts(int count);

  /// No description provided for @leftOpen.
  ///
  /// In en, this message translates to:
  /// **', {count} left open'**
  String leftOpen(int count);

  /// No description provided for @runAutoFill.
  ///
  /// In en, this message translates to:
  /// **'Run Auto-Fill'**
  String get runAutoFill;

  /// No description provided for @findReplacementTitle.
  ///
  /// In en, this message translates to:
  /// **'Find replacement — {station}'**
  String findReplacementTitle(String station);

  /// No description provided for @assignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign — {station}'**
  String assignTitle(String station);

  /// No description provided for @thinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking…'**
  String get thinking;

  /// No description provided for @aiSuggest.
  ///
  /// In en, this message translates to:
  /// **'AI suggest'**
  String get aiSuggest;

  /// No description provided for @eligibleStaffOnly.
  ///
  /// In en, this message translates to:
  /// **'Only certified, available, conflict-free staff are listed.'**
  String get eligibleStaffOnly;

  /// No description provided for @aiNoReplacement.
  ///
  /// In en, this message translates to:
  /// **'AI found no eligible replacement.'**
  String get aiNoReplacement;

  /// No description provided for @nobodyEligible.
  ///
  /// In en, this message translates to:
  /// **'Nobody is eligible for this shift — check certifications, availability and overlapping assignments.'**
  String get nobodyEligible;

  /// No description provided for @suggestionServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Suggestion service unavailable.'**
  String get suggestionServiceUnavailable;

  /// No description provided for @editShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit shift — {station}'**
  String editShiftTitle(String station);

  /// No description provided for @newShiftTitle.
  ///
  /// In en, this message translates to:
  /// **'New shift — {station}'**
  String newShiftTitle(String station);

  /// No description provided for @shiftStart.
  ///
  /// In en, this message translates to:
  /// **'Shift start'**
  String get shiftStart;

  /// No description provided for @shiftEnd.
  ///
  /// In en, this message translates to:
  /// **'Shift end'**
  String get shiftEnd;

  /// No description provided for @startAt.
  ///
  /// In en, this message translates to:
  /// **'Start {time}'**
  String startAt(String time);

  /// No description provided for @endAt.
  ///
  /// In en, this message translates to:
  /// **'End {time}'**
  String endAt(String time);

  /// No description provided for @failedToSaveShift.
  ///
  /// In en, this message translates to:
  /// **'Failed to save shift.'**
  String get failedToSaveShift;

  /// No description provided for @staffTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get staffTitle;

  /// No description provided for @dragToAssign.
  ///
  /// In en, this message translates to:
  /// **'Drag onto a shift to assign'**
  String get dragToAssign;

  /// No description provided for @certificationCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 certification} other{{count} certifications}}'**
  String certificationCount(int count);

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get statusSick;

  /// No description provided for @statusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get statusUnavailable;

  /// No description provided for @roleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get roleAdmin;

  /// No description provided for @roleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get roleManager;

  /// No description provided for @roleDispatcher.
  ///
  /// In en, this message translates to:
  /// **'Dispatcher'**
  String get roleDispatcher;

  /// No description provided for @roleEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleEmployee;

  /// No description provided for @certificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certificationsTitle;

  /// No description provided for @noStaffYet.
  ///
  /// In en, this message translates to:
  /// **'No staff yet — users appear here after their first sign-in.'**
  String get noStaffYet;

  /// No description provided for @noCertifications.
  ///
  /// In en, this message translates to:
  /// **'No certifications'**
  String get noCertifications;

  /// No description provided for @editStaffMember.
  ///
  /// In en, this message translates to:
  /// **'Edit staff member'**
  String get editStaffMember;

  /// No description provided for @availabilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availabilityLabel;

  /// No description provided for @noCertificationsInCatalog.
  ///
  /// In en, this message translates to:
  /// **'No certifications in the catalog yet.'**
  String get noCertificationsInCatalog;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @failedToSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes.'**
  String get failedToSaveChanges;

  /// No description provided for @newCertification.
  ///
  /// In en, this message translates to:
  /// **'New certification'**
  String get newCertification;

  /// No description provided for @failedToAddCertification.
  ///
  /// In en, this message translates to:
  /// **'Failed to add certification.'**
  String get failedToAddCertification;

  /// No description provided for @certCatalogEmptyExample.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet — e.g. \"Armed Guard\", \"Medic\", \"Type C Responder\".'**
  String get certCatalogEmptyExample;

  /// No description provided for @stationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stations'**
  String get stationsTitle;

  /// No description provided for @newStation.
  ///
  /// In en, this message translates to:
  /// **'New Station'**
  String get newStation;

  /// No description provided for @searchStations.
  ///
  /// In en, this message translates to:
  /// **'Search stations…'**
  String get searchStations;

  /// No description provided for @noStations.
  ///
  /// In en, this message translates to:
  /// **'No stations'**
  String get noStations;

  /// No description provided for @createFirstStation.
  ///
  /// In en, this message translates to:
  /// **'Create your first station to start scheduling.'**
  String get createFirstStation;

  /// No description provided for @noStationsMatch.
  ///
  /// In en, this message translates to:
  /// **'No stations match \"{query}\".'**
  String noStationsMatch(String query);

  /// No description provided for @manning247.
  ///
  /// In en, this message translates to:
  /// **'24/7 manning'**
  String get manning247;

  /// No description provided for @onDemandWindows.
  ///
  /// In en, this message translates to:
  /// **'On-demand: {windows}'**
  String onDemandWindows(String windows);

  /// No description provided for @requiresCerts.
  ///
  /// In en, this message translates to:
  /// **'Requires: {certs}'**
  String requiresCerts(String certs);

  /// No description provided for @deleteStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete station?'**
  String get deleteStationTitle;

  /// No description provided for @deleteStationBody.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" and its configuration will be removed. Existing shifts are not deleted.'**
  String deleteStationBody(String name);

  /// No description provided for @failedToDeleteStation.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete station.'**
  String get failedToDeleteStation;

  /// No description provided for @onDemandNeedsWindow.
  ///
  /// In en, this message translates to:
  /// **'On-demand stations need at least one active window.'**
  String get onDemandNeedsWindow;

  /// No description provided for @failedToSaveStation.
  ///
  /// In en, this message translates to:
  /// **'Failed to save station.'**
  String get failedToSaveStation;

  /// No description provided for @windowStart.
  ///
  /// In en, this message translates to:
  /// **'Window start'**
  String get windowStart;

  /// No description provided for @windowEnd.
  ///
  /// In en, this message translates to:
  /// **'Window end'**
  String get windowEnd;

  /// No description provided for @editStation.
  ///
  /// In en, this message translates to:
  /// **'Edit Station'**
  String get editStation;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get nameRequired;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// No description provided for @locationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required'**
  String get locationRequired;

  /// No description provided for @defaultShiftLength.
  ///
  /// In en, this message translates to:
  /// **'Default shift length (minutes)'**
  String get defaultShiftLength;

  /// No description provided for @positiveMinutes.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive number of minutes'**
  String get positiveMinutes;

  /// No description provided for @stationActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get stationActive;

  /// No description provided for @stationClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get stationClosed;

  /// No description provided for @manningLabel.
  ///
  /// In en, this message translates to:
  /// **'Manning'**
  String get manningLabel;

  /// No description provided for @onDemand.
  ///
  /// In en, this message translates to:
  /// **'On-demand'**
  String get onDemand;

  /// No description provided for @addWindow.
  ///
  /// In en, this message translates to:
  /// **'Add window'**
  String get addWindow;

  /// No description provided for @requiredCertificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Required certifications'**
  String get requiredCertificationsLabel;

  /// No description provided for @noCertsDefinedAddOnStaff.
  ///
  /// In en, this message translates to:
  /// **'No certifications defined yet — add them on the Staff screen.'**
  String get noCertsDefinedAddOnStaff;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// No description provided for @chipCovered.
  ///
  /// In en, this message translates to:
  /// **'Covered'**
  String get chipCovered;

  /// No description provided for @chipOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get chipOpen;

  /// No description provided for @chipCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get chipCritical;

  /// No description provided for @emergencyDispatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Dispatch'**
  String get emergencyDispatchTitle;

  /// No description provided for @eventTypesTitle.
  ///
  /// In en, this message translates to:
  /// **'Event Types'**
  String get eventTypesTitle;

  /// No description provided for @triggerCallout.
  ///
  /// In en, this message translates to:
  /// **'TRIGGER CALL-OUT'**
  String get triggerCallout;

  /// No description provided for @noEventTypesConfigured.
  ///
  /// In en, this message translates to:
  /// **'No event types configured yet — define scenarios under Event Types.'**
  String get noEventTypesConfigured;

  /// No description provided for @activeEvents.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE EVENTS'**
  String get activeEvents;

  /// No description provided for @noActiveEmergencies.
  ///
  /// In en, this message translates to:
  /// **'No active emergencies.'**
  String get noActiveEmergencies;

  /// No description provided for @triggerEventConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Trigger \"{name}\"?'**
  String triggerEventConfirmTitle(String name);

  /// No description provided for @triggerEventConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All matching responders will be alerted immediately.'**
  String get triggerEventConfirmBody;

  /// No description provided for @triggerAction.
  ///
  /// In en, this message translates to:
  /// **'TRIGGER'**
  String get triggerAction;

  /// No description provided for @failedToTrigger.
  ///
  /// In en, this message translates to:
  /// **'Failed to trigger — check responders hold the required certifications.'**
  String get failedToTrigger;

  /// No description provided for @alertedResponders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Alerted 1 responder.} other{Alerted {count} responders.}}'**
  String alertedResponders(int count);

  /// No description provided for @acknowledgedTally.
  ///
  /// In en, this message translates to:
  /// **'{acked}/{total} acknowledged'**
  String acknowledgedTally(int acked, int total);

  /// No description provided for @resolve.
  ///
  /// In en, this message translates to:
  /// **'Resolve'**
  String get resolve;

  /// No description provided for @newEventType.
  ///
  /// In en, this message translates to:
  /// **'New Event Type'**
  String get newEventType;

  /// No description provided for @noScenariosYet.
  ///
  /// In en, this message translates to:
  /// **'No scenarios yet — e.g. \"Event Type C\" alerting all Type C Responders.'**
  String get noScenariosYet;

  /// No description provided for @inactiveTag.
  ///
  /// In en, this message translates to:
  /// **'(inactive)'**
  String get inactiveTag;

  /// No description provided for @respondersLabel.
  ///
  /// In en, this message translates to:
  /// **'Responders: {certs}'**
  String respondersLabel(String certs);

  /// No description provided for @stationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Stations: {stations}'**
  String stationsLabel(String stations);

  /// No description provided for @pickOneResponderCert.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one responder certification.'**
  String get pickOneResponderCert;

  /// No description provided for @failedToSaveEventType.
  ///
  /// In en, this message translates to:
  /// **'Failed to save event type.'**
  String get failedToSaveEventType;

  /// No description provided for @editEventType.
  ///
  /// In en, this message translates to:
  /// **'Edit Event Type'**
  String get editEventType;

  /// No description provided for @eventTypeNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Event Type C)'**
  String get eventTypeNameLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @priorityLabel.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priorityLabel;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get priorityCritical;

  /// No description provided for @responderCertsAnyLabel.
  ///
  /// In en, this message translates to:
  /// **'Responder certifications (holder of ANY)'**
  String get responderCertsAnyLabel;

  /// No description provided for @noCertsDefinedStaffFirst.
  ///
  /// In en, this message translates to:
  /// **'No certifications defined — add them on the Staff screen first.'**
  String get noCertsDefinedStaffFirst;

  /// No description provided for @stationsInvolved.
  ///
  /// In en, this message translates to:
  /// **'Stations involved'**
  String get stationsInvolved;

  /// No description provided for @eventTypeActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get eventTypeActive;

  /// No description provided for @inactiveHiddenFromBoard.
  ///
  /// In en, this message translates to:
  /// **'Inactive scenarios are hidden from the dispatch board'**
  String get inactiveHiddenFromBoard;

  /// No description provided for @hiUser.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hiUser(String name);

  /// No description provided for @currentAssignment.
  ///
  /// In en, this message translates to:
  /// **'CURRENT ASSIGNMENT'**
  String get currentAssignment;

  /// No description provided for @upcomingAssignment.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING ASSIGNMENT'**
  String get upcomingAssignment;

  /// No description provided for @noUpcomingAssignments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming assignments.'**
  String get noUpcomingAssignments;

  /// No description provided for @mySchedule.
  ///
  /// In en, this message translates to:
  /// **'My schedule'**
  String get mySchedule;

  /// No description provided for @emergencyBanner.
  ///
  /// In en, this message translates to:
  /// **'EMERGENCY: {name}'**
  String emergencyBanner(String name);

  /// No description provided for @ackStandBy.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged — stand by.'**
  String get ackStandBy;

  /// No description provided for @youAreNeeded.
  ///
  /// In en, this message translates to:
  /// **'You are needed. Acknowledge now.'**
  String get youAreNeeded;

  /// No description provided for @failedToAcknowledge.
  ///
  /// In en, this message translates to:
  /// **'Failed to acknowledge.'**
  String get failedToAcknowledge;

  /// No description provided for @acknowledgeAction.
  ///
  /// In en, this message translates to:
  /// **'ACKNOWLEDGE'**
  String get acknowledgeAction;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @failedToAcknowledgeRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to acknowledge — try again.'**
  String get failedToAcknowledgeRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
