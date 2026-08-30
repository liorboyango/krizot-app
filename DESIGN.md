## Mobile & web app called Krizot.

# Interface 1: The Administrative Scheduler (Desktop Optimized, Mobile Functional)
Target User: Shift Managers / Operations Officers.
Key Features:

Dynamic Station Management: Ability to define "Stations." Some stations require 24/7 manning (e.g., Station B), while others are "On-Demand" based on daily needs (e.g., Station A is only active from 08:00-10:00).

Shift Flexibility: Default shifts are 2-hour blocks, but must be fully editable in length.

Certification-Based Logic: A database of users, each tagged with specific certifications/skills. The system must only allow "User X" to be assigned to "Station Y" if they hold the required certification.

AI-Powered Scheduling: * An "Auto-Fill" feature that populates the daily schedule based on user availability and certifications.

"Smart Healing" Logic: If a user is marked as "Sick" or "Unavailable," the AI suggests the best replacement who shares the same certifications without creating overtime conflicts.

Responsive UI: Primary use on Desktop for complex drag-and-drop actions, but must remain fully functional for mobile browsers.

# Interface 2: The User Mobile Interface
Target User: Employees / Field Personnel.
Key Features:

Personal Dashboard: A clear view of the Daily and Weekly schedule.

Focus View: Large, prominent display of the "Current Assignment" and "Upcoming Assignment" (Location, Time, and Station).

Acknowledgement Loop: When a manager changes a user’s schedule, the user receives a push notification. The user must click an "Acknowledge" button. The Scheduler (Interface 1) must show a visual indicator (e.g., a green checkmark) once the user has seen and confirmed the change.

# Interface 3: Emergency Dispatch (The Trigger Interface)
Target User: Dispatchers / Command Staff.
Key Features:

Event-Based Activation: A simplified interface to trigger emergency call-outs.

Logic-Driven Alerts: If "Event Type C" occurs, the system automatically alerts all users classified as "Type C Responders."

Customizable Scenarios: The ability to pre-define various event types and which personnel/stations are tied to each event.

Speed & Simplicity: Minimal clicks required to initiate a high-priority alert.

# Tech:
Backend: node.js (Cloud Functions) with Firebase Firestore as database.
For users sign-in, use Firebase Google Auth.
Use Flutter for the mobile app & frontend of the Web interfaces 1 & 3.  Allow switching between Interface 1 & 3 when in Web, and allow only interface 2 in Mobile.
State management - use RxDart + GetIt; Service + Manager using streams, singletons via GetIt. See ~/Documents/gitProjects/sentry_modder for reference.
# Scheduling Extensions (v2)
1. Availability Calendar: each user records presence windows with per-hour resolution (e.g. arriving 13.9 12:00, leaving 15.9 15:00). A user is only schedulable inside a window; users with no windows are treated as always present. Managers see windows in the scheduler; employees manage their own in Interface 2.

2. Daily Manning Requirements: each day has a definition of exactly how many holders of which certifications are required (`dayRequirements/{dayKey}`). The scheduler day view shows required-vs-covered per certification.

3. Certification Timestamps: each user's certification carries the date it was earned (`users.certificationTimes`), editable on the Staff screen.

4. Training Courses: every user belongs to a fixed common training course (`users.courseNumber`), ascending — a lower number means an earlier, more senior cohort.

5. Training Sessions: schedulable blocks where one or more certified users train an uncertified trainee toward a certification. Types: Simulation (staffing defined per certification — how many holders of which certifications), Spectation (exactly one certified spectator), Tutoring (one-on-one). Session priority defaults to the certification's level (higher level = higher priority) and stays editable. Sessions appear on the scheduler grid, and participants count as busy for shift assignment (client eligibility + backend plan validator + auto-fill).

6. Per-User Schedule: in the scheduler, pressing a staff chip or searching staff opens that user's weekly schedule (presence windows, shifts, training sessions).

# Scheduling Extensions (v3)
1. Auto-fill creates shifts first: the `autoFillSchedule` callable generates every still-missing shift of the day from the stations' manning windows (24/7 → whole day; on-demand → each active window, capacity-aware) before assigning staff. Blocks default to 2 hours and never exceed 3 hours; managers can still edit any single occurrence's duration afterwards.

2. Stations define WHEN, not HOW LONG: the station `location` and `defaultShiftMinutes` fields are gone. Shift durations come from the auto-fill generator (or manual edits of a specific occurrence).

3. Organizational layers on users: `site` ('506' | '509'), `department` ('mesima' | 'taavura') and `jobRole` ('hagana' | 'bakara' | 'officer'), managed from the Staff editor. The Staff screen has a Unit selector plus Department → Role checkbox filters, and the list is sectioned per Department → Role (with an Unassigned tail). The LLM planner receives these tags so manager instructions can reference them.

3b. Org-scoped stations & certifications: stations and certifications may pin any of the three layers (`site`/`department`/`jobRole`; null = everyone). A user may only man a station — or be offered a certification — when every pinned layer matches their placement. Enforced in the client eligibility check, the backend plan validator (auto-fill/replacement), and the seeder's assigner; the editors only offer certifications whose scope is compatible with the user/station being edited.

4. Staff calendar view: the Staff screen toggles between the sectioned list and a users × week-days calendar showing presence windows and assigned shifts, with the AI Auto-Fill button (including the free-text prompt notes box).

5. Per-user availability calendar: every staff row has a calendar button opening a popup week calendar of that user's presence windows, where managers add/edit/delete windows.
