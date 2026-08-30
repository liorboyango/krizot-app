// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appName => 'קריזות';

  @override
  String get appTagline => 'שיבוץ משמרות ומוקד חירום';

  @override
  String get cancel => 'ביטול';

  @override
  String get close => 'סגירה';

  @override
  String get save => 'שמירה';

  @override
  String get create => 'יצירה';

  @override
  String get delete => 'מחיקה';

  @override
  String get edit => 'עריכה';

  @override
  String get saving => 'שומר…';

  @override
  String get signOut => 'התנתקות';

  @override
  String get signInFailed => 'ההתחברות נכשלה. נסו שוב.';

  @override
  String get signingIn => 'מתחבר…';

  @override
  String get continueWithGoogle => 'המשך עם Google';

  @override
  String get navScheduler => 'לוח שיבוץ';

  @override
  String get navStations => 'עמדות';

  @override
  String get navStaff => 'צוות';

  @override
  String get navDispatch => 'מוקד חירום';

  @override
  String get schedulerTitle => 'לוח שיבוץ';

  @override
  String get noActiveStations => 'אין עמדות פעילות — צרו עמדה במסך העמדות.';

  @override
  String get previousWeek => 'שבוע קודם';

  @override
  String get nextWeek => 'שבוע הבא';

  @override
  String get today => 'היום';

  @override
  String get autoFillWhichDay => 'איזה יום למלא אוטומטית?';

  @override
  String get autoFill => 'מילוי אוטומטי';

  @override
  String get stationColumn => 'עמדה';

  @override
  String get twentyFourSeven => '24/7';

  @override
  String get openShiftShort => 'פנויה';

  @override
  String get assignmentFailed => 'השיבוץ נכשל.';

  @override
  String get openShift => 'משמרת פנויה';

  @override
  String assignedTo(String name) {
    return 'משובץ: $name';
  }

  @override
  String get acknowledgedCheck => 'אושר ✓';

  @override
  String get notAcknowledgedYet => 'טרם אושר';

  @override
  String get findReplacementAi => 'חיפוש מחליף (AI)';

  @override
  String get reassign => 'שיבוץ מחדש';

  @override
  String get assign => 'שיבוץ';

  @override
  String get editTimes => 'עריכת שעות';

  @override
  String get unassign => 'ביטול שיבוץ';

  @override
  String get deleteShift => 'מחיקת משמרת';

  @override
  String get aiAutoFillTitle => 'מילוי אוטומטי (AI)';

  @override
  String autoFillExplainer(String date) {
    return 'מילוי כל המשמרות הפנויות ב$date לפי זמינות והסמכות הצוות.';
  }

  @override
  String get aiInstructionsLabel => 'הנחיות ל-AI (לא חובה)';

  @override
  String get aiInstructionsHint =>
      'לדוגמה: לפזר משמרות באופן שווה; להימנע ממשמרות לילה לעובדים חדשים';

  @override
  String get planningSchedule => 'מתכנן את הלוח…';

  @override
  String get autoFillFailed =>
      'המילוי האוטומטי נכשל — ודאו שפונקציית הענן פרוסה ושמפתח ה-LLM מוגדר.';

  @override
  String filledShifts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'מולאו $count משמרות',
      one: 'מולאה משמרת אחת',
    );
    return '$_temp0';
  }

  @override
  String leftOpen(int count) {
    return ', $count נותרו פנויות';
  }

  @override
  String get runAutoFill => 'הפעלת מילוי אוטומטי';

  @override
  String findReplacementTitle(String station) {
    return 'חיפוש מחליף — $station';
  }

  @override
  String assignTitle(String station) {
    return 'שיבוץ — $station';
  }

  @override
  String get thinking => 'חושב…';

  @override
  String get aiSuggest => 'הצעת AI';

  @override
  String get eligibleStaffOnly =>
      'מוצגים רק אנשי צוות מוסמכים, זמינים וללא חפיפות.';

  @override
  String get aiNoReplacement => 'ה-AI לא מצא מחליף מתאים.';

  @override
  String get nobodyEligible =>
      'אף אחד אינו מתאים למשמרת זו — בדקו הסמכות, זמינות ושיבוצים חופפים.';

  @override
  String get suggestionServiceUnavailable => 'שירות ההצעות אינו זמין.';

  @override
  String editShiftTitle(String station) {
    return 'עריכת משמרת — $station';
  }

  @override
  String newShiftTitle(String station) {
    return 'משמרת חדשה — $station';
  }

  @override
  String get shiftStart => 'תחילת משמרת';

  @override
  String get shiftEnd => 'סיום משמרת';

  @override
  String startAt(String time) {
    return 'התחלה $time';
  }

  @override
  String endAt(String time) {
    return 'סיום $time';
  }

  @override
  String get failedToSaveShift => 'שמירת המשמרת נכשלה.';

  @override
  String get staffTitle => 'צוות';

  @override
  String get dragToAssign => 'גררו אל משמרת כדי לשבץ';

  @override
  String certificationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count הסמכות',
      one: 'הסמכה אחת',
    );
    return '$_temp0';
  }

  @override
  String get statusAvailable => 'זמין';

  @override
  String get statusSick => 'מחלה';

  @override
  String get statusUnavailable => 'לא זמין';

  @override
  String get roleAdmin => 'מנהל מערכת';

  @override
  String get roleManager => 'מנהל';

  @override
  String get roleDispatcher => 'מוקדן';

  @override
  String get roleEmployee => 'עובד';

  @override
  String get certificationsTitle => 'הסמכות';

  @override
  String get noStaffYet =>
      'אין צוות עדיין — משתמשים יופיעו כאן לאחר ההתחברות הראשונה שלהם.';

  @override
  String get noCertifications => 'ללא הסמכות';

  @override
  String get editStaffMember => 'עריכת איש צוות';

  @override
  String get availabilityLabel => 'זמינות';

  @override
  String get noCertificationsInCatalog => 'אין עדיין הסמכות בקטלוג.';

  @override
  String get roleLabel => 'תפקיד';

  @override
  String get failedToSaveChanges => 'שמירת השינויים נכשלה.';

  @override
  String get newCertification => 'הסמכה חדשה';

  @override
  String get failedToAddCertification => 'הוספת ההסמכה נכשלה.';

  @override
  String get certCatalogEmptyExample =>
      'אין כאן עדיין כלום — לדוגמה: \"מאבטח חמוש\", \"חובש\", \"כונן סוג ג\".';

  @override
  String get stationsTitle => 'עמדות';

  @override
  String get newStation => 'עמדה חדשה';

  @override
  String get searchStations => 'חיפוש עמדות…';

  @override
  String get noStations => 'אין עמדות';

  @override
  String get createFirstStation => 'צרו את העמדה הראשונה כדי להתחיל לשבץ.';

  @override
  String noStationsMatch(String query) {
    return 'אין עמדות התואמות ל\"$query\".';
  }

  @override
  String get manning247 => 'איוש מסביב לשעון';

  @override
  String onDemandWindows(String windows) {
    return 'לפי דרישה: $windows';
  }

  @override
  String requiresCerts(String certs) {
    return 'דרושות: $certs';
  }

  @override
  String get deleteStationTitle => 'למחוק את העמדה?';

  @override
  String deleteStationBody(String name) {
    return '\"$name\" והגדרותיה יוסרו. משמרות קיימות לא יימחקו.';
  }

  @override
  String get failedToDeleteStation => 'מחיקת העמדה נכשלה.';

  @override
  String get onDemandNeedsWindow =>
      'עמדות לפי דרישה צריכות לפחות חלון פעילות אחד.';

  @override
  String get failedToSaveStation => 'שמירת העמדה נכשלה.';

  @override
  String get windowStart => 'תחילת חלון';

  @override
  String get windowEnd => 'סיום חלון';

  @override
  String get editStation => 'עריכת עמדה';

  @override
  String get nameLabel => 'שם';

  @override
  String get nameRequired => 'חובה להזין שם';

  @override
  String get locationLabel => 'מיקום';

  @override
  String get locationRequired => 'חובה להזין מיקום';

  @override
  String get defaultShiftLength => 'אורך משמרת ברירת מחדל (בדקות)';

  @override
  String get positiveMinutes => 'הזינו מספר דקות חיובי';

  @override
  String get stationActive => 'פעילה';

  @override
  String get stationClosed => 'סגורה';

  @override
  String get manningLabel => 'איוש';

  @override
  String get onDemand => 'לפי דרישה';

  @override
  String get addWindow => 'הוספת חלון';

  @override
  String get requiredCertificationsLabel => 'הסמכות נדרשות';

  @override
  String get noCertsDefinedAddOnStaff =>
      'לא הוגדרו הסמכות עדיין — הוסיפו אותן במסך הצוות.';

  @override
  String get notesLabel => 'הערות';

  @override
  String get chipCovered => 'מאויש';

  @override
  String get chipOpen => 'פנוי';

  @override
  String get chipCritical => 'קריטי';

  @override
  String get emergencyDispatchTitle => 'מוקד חירום';

  @override
  String get eventTypesTitle => 'סוגי אירועים';

  @override
  String get triggerCallout => 'הפעלת קריאה';

  @override
  String get noEventTypesConfigured =>
      'לא הוגדרו סוגי אירועים עדיין — הגדירו תרחישים תחת סוגי אירועים.';

  @override
  String get activeEvents => 'אירועים פעילים';

  @override
  String get noActiveEmergencies => 'אין אירועי חירום פעילים.';

  @override
  String triggerEventConfirmTitle(String name) {
    return 'להפעיל \"$name\"?';
  }

  @override
  String get triggerEventConfirmBody => 'כל הכוננים המתאימים יוזעקו מיידית.';

  @override
  String get triggerAction => 'הפעלה';

  @override
  String get failedToTrigger =>
      'ההפעלה נכשלה — ודאו שהכוננים מחזיקים בהסמכות הנדרשות.';

  @override
  String alertedResponders(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'הוזעקו $count כוננים.',
      one: 'הוזעק כונן אחד.',
    );
    return '$_temp0';
  }

  @override
  String acknowledgedTally(int acked, int total) {
    return '$acked/$total אישרו';
  }

  @override
  String get resolve => 'סגירת אירוע';

  @override
  String get newEventType => 'סוג אירוע חדש';

  @override
  String get noScenariosYet =>
      'אין תרחישים עדיין — לדוגמה: \"אירוע סוג ג\" שמזעיק את כל כונני סוג ג.';

  @override
  String get inactiveTag => '(לא פעיל)';

  @override
  String respondersLabel(String certs) {
    return 'כוננים: $certs';
  }

  @override
  String stationsLabel(String stations) {
    return 'עמדות: $stations';
  }

  @override
  String get pickOneResponderCert => 'בחרו לפחות הסמכת כונן אחת.';

  @override
  String get failedToSaveEventType => 'שמירת סוג האירוע נכשלה.';

  @override
  String get editEventType => 'עריכת סוג אירוע';

  @override
  String get eventTypeNameLabel => 'שם (לדוגמה: אירוע סוג ג)';

  @override
  String get descriptionLabel => 'תיאור';

  @override
  String get priorityLabel => 'עדיפות';

  @override
  String get priorityHigh => 'גבוהה';

  @override
  String get priorityCritical => 'קריטית';

  @override
  String get responderCertsAnyLabel => 'הסמכות כוננים (מספיקה אחת מהן)';

  @override
  String get noCertsDefinedStaffFirst =>
      'לא הוגדרו הסמכות — הוסיפו אותן קודם במסך הצוות.';

  @override
  String get stationsInvolved => 'עמדות מעורבות';

  @override
  String get eventTypeActive => 'פעיל';

  @override
  String get inactiveHiddenFromBoard => 'תרחישים לא פעילים מוסתרים מלוח המוקד';

  @override
  String hiUser(String name) {
    return 'שלום, $name';
  }

  @override
  String get currentAssignment => 'שיבוץ נוכחי';

  @override
  String get upcomingAssignment => 'שיבוץ קרוב';

  @override
  String get noUpcomingAssignments => 'אין שיבוצים קרובים.';

  @override
  String get mySchedule => 'הלוח שלי';

  @override
  String emergencyBanner(String name) {
    return 'חירום: $name';
  }

  @override
  String get ackStandBy => 'אושר — המתינו להנחיות.';

  @override
  String get youAreNeeded => 'אתם נדרשים. אשרו כעת.';

  @override
  String get failedToAcknowledge => 'האישור נכשל.';

  @override
  String get acknowledgeAction => 'אישור';

  @override
  String get acknowledge => 'אישור קבלה';

  @override
  String get failedToAcknowledgeRetry => 'האישור נכשל — נסו שוב.';
}
