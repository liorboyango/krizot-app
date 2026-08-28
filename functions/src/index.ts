import { initializeApp } from 'firebase-admin/app';

initializeApp();

export { autoFillSchedule } from './callable/autoFillSchedule';
export { suggestReplacement } from './callable/suggestReplacement';
export { triggerEmergency } from './callable/triggerEmergency';
export { setUserRole } from './callable/setUserRole';
export { onAuthUserCreate } from './triggers/onAuthUserCreate';
export { onShiftWrite } from './triggers/onShiftWrite';
export { onEmergencyEventCreate } from './triggers/onEmergencyEventCreate';
