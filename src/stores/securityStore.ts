// ── Cyber Security Store ──
// Tracks login events, failed attempts, and sessions.

export interface LoginEvent {
  id: string;
  username: string;
  timestamp: number;
  success: boolean;
  reason?: string;       // 'wrong_password' | 'user_not_found' | 'locked'
  userAgent?: string;
}

const LOG_KEY      = 'fantatech_login_log';
const MAX_LOG_SIZE = 100;
const MAX_ATTEMPTS = 5;
const LOCK_DURATION_MS = 5 * 60 * 1000; // 5 minutes

// failed attempt counters: { [username]: { count, lastAt } }
const ATTEMPTS_KEY = 'fantatech_attempts';

function loadLog(): LoginEvent[] {
  try { return JSON.parse(localStorage.getItem(LOG_KEY) ?? '[]'); } catch { return []; }
}
function saveLog(log: LoginEvent[]) {
  try { localStorage.setItem(LOG_KEY, JSON.stringify(log.slice(-MAX_LOG_SIZE))); } catch {}
}

interface AttemptRecord { count: number; lastAt: number; lockedUntil?: number }
function loadAttempts(): Record<string, AttemptRecord> {
  try { return JSON.parse(localStorage.getItem(ATTEMPTS_KEY) ?? '{}'); } catch { return {}; }
}
function saveAttempts(a: Record<string, AttemptRecord>) {
  try { localStorage.setItem(ATTEMPTS_KEY, JSON.stringify(a)); } catch {}
}

export function getLoginLog(): LoginEvent[] { return loadLog(); }

export function isLocked(username: string): boolean {
  const a = loadAttempts()[username.toLowerCase()];
  if (!a?.lockedUntil) return false;
  if (Date.now() < a.lockedUntil) return true;
  // Lock expired — clear
  const all = loadAttempts();
  delete all[username.toLowerCase()];
  saveAttempts(all);
  return false;
}

export function getLockRemaining(username: string): number {
  const a = loadAttempts()[username.toLowerCase()];
  if (!a?.lockedUntil) return 0;
  return Math.max(0, Math.ceil((a.lockedUntil - Date.now()) / 1000));
}

export function recordLoginAttempt(username: string, success: boolean, reason?: string) {
  // Log event
  const log = loadLog();
  log.push({
    id: `ev-${Date.now()}`,
    username,
    timestamp: Date.now(),
    success,
    reason,
    userAgent: navigator.userAgent.split(')')[0].split('(')[1] ?? 'Unknown',
  });
  saveLog(log);

  // Update failed attempts
  const all = loadAttempts();
  const key = username.toLowerCase();
  if (success) {
    delete all[key]; // reset on success
  } else {
    const prev = all[key] ?? { count: 0, lastAt: 0 };
    const newCount = prev.count + 1;
    all[key] = {
      count: newCount,
      lastAt: Date.now(),
      lockedUntil: newCount >= MAX_ATTEMPTS ? Date.now() + LOCK_DURATION_MS : undefined,
    };
  }
  saveAttempts(all);
}

export function getFailedAttempts(username: string): number {
  return loadAttempts()[username.toLowerCase()]?.count ?? 0;
}

export function clearLoginLog() {
  try { localStorage.removeItem(LOG_KEY); } catch {}
}

export function getSecurityScore(): number {
  const log = loadLog().slice(-20);
  const failedRecent = log.filter(e => !e.success).length;
  const score = Math.max(0, 100 - failedRecent * 10);
  return score;
}
