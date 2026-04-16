// ── Authentication Store ──
// Local multi-user auth with SHA-256 hashed passwords.
// Session stored in sessionStorage (clears on tab close).

export type UserRole = 'admin' | 'user' | 'viewer';

export interface AppUser {
  id: string;
  username: string;
  displayName: string;
  passwordHash: string;
  role: UserRole;
  avatar: string;        // emoji avatar
  createdAt: number;
  lastLogin?: number;
}

export interface Session {
  userId: string;
  username: string;
  displayName: string;
  role: UserRole;
  avatar: string;
  loggedInAt: number;
}

const USERS_KEY   = 'fantatech_users';
const SESSION_KEY = 'fantatech_session';

// ── Crypto helpers ──
export async function hashPassword(password: string): Promise<string> {
  const buf  = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(password));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2, '0')).join('');
}

// ── User storage ──
export function loadUsers(): AppUser[] {
  try { return JSON.parse(localStorage.getItem(USERS_KEY) ?? '[]'); } catch { return []; }
}

function saveUsers(users: AppUser[]) {
  try { localStorage.setItem(USERS_KEY, JSON.stringify(users)); } catch {}
}

// Create default admin on first run
export async function ensureDefaultAdmin() {
  const users = loadUsers();
  if (users.length === 0) {
    const hash = await hashPassword('1234');
    saveUsers([{
      id: 'admin-1',
      username: 'admin',
      displayName: 'Administrator',
      passwordHash: hash,
      role: 'admin',
      avatar: '👤',
      createdAt: Date.now(),
    }]);
  }
}

// ── Session ──
export function loadSession(): Session | null {
  try { return JSON.parse(sessionStorage.getItem(SESSION_KEY) ?? 'null'); } catch { return null; }
}

function saveSession(s: Session) {
  try { sessionStorage.setItem(SESSION_KEY, JSON.stringify(s)); } catch {}
}

function clearSession() {
  try { sessionStorage.removeItem(SESSION_KEY); } catch {}
}

// ── Pub-sub ──
const _listeners = new Set<() => void>();
let _session: Session | null = loadSession();

export function getSession(): Session | null { return _session; }

function notify() { _listeners.forEach(fn => fn()); }

export function subscribeAuth(fn: () => void): () => void {
  _listeners.add(fn);
  return () => _listeners.delete(fn);
}

// ── Auth actions ──
export async function login(username: string, password: string): Promise<{ ok: boolean; error?: string }> {
  const users = loadUsers();
  const user  = users.find(u => u.username.toLowerCase() === username.toLowerCase());
  if (!user) return { ok: false, error: 'user_not_found' };

  const hash = await hashPassword(password);
  if (hash !== user.passwordHash) return { ok: false, error: 'wrong_password' };

  // Update last login
  const updated = users.map(u => u.id === user.id ? { ...u, lastLogin: Date.now() } : u);
  saveUsers(updated);

  _session = {
    userId:      user.id,
    username:    user.username,
    displayName: user.displayName,
    role:        user.role,
    avatar:      user.avatar,
    loggedInAt:  Date.now(),
  };
  saveSession(_session);
  notify();
  return { ok: true };
}

export function logout() {
  _session = null;
  clearSession();
  notify();
}

export async function createUser(
  username: string, displayName: string, password: string,
  role: UserRole = 'user', avatar = '👤'
): Promise<{ ok: boolean; error?: string }> {
  const users = loadUsers();
  if (users.find(u => u.username.toLowerCase() === username.toLowerCase()))
    return { ok: false, error: 'username_taken' };

  const hash = await hashPassword(password);
  saveUsers([...users, {
    id: `user-${Date.now()}`,
    username, displayName, passwordHash: hash, role, avatar,
    createdAt: Date.now(),
  }]);
  return { ok: true };
}

export async function changePassword(userId: string, oldPass: string, newPass: string): Promise<{ ok: boolean; error?: string }> {
  const users = loadUsers();
  const user = users.find(u => u.id === userId);
  if (!user) return { ok: false, error: 'not_found' };
  const oldHash = await hashPassword(oldPass);
  if (oldHash !== user.passwordHash) return { ok: false, error: 'wrong_password' };
  const newHash = await hashPassword(newPass);
  saveUsers(users.map(u => u.id === userId ? { ...u, passwordHash: newHash } : u));
  return { ok: true };
}

export function deleteUser(userId: string) {
  saveUsers(loadUsers().filter(u => u.id !== userId));
}
