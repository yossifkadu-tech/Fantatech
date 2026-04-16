import { useState, useEffect } from 'react';
import {
  getSession, subscribeAuth, login as doLogin,
  logout as doLogout, ensureDefaultAdmin,
  type Session,
} from '../stores/authStore';
import { recordLoginAttempt, isLocked, getLockRemaining } from '../stores/securityStore';

// Ensure default admin exists on first load
ensureDefaultAdmin();

export function useAuth() {
  const [session, setSession] = useState<Session | null>(getSession);

  useEffect(() => {
    setSession(getSession());
    return subscribeAuth(() => setSession(getSession()));
  }, []);

  async function login(username: string, password: string) {
    if (isLocked(username)) {
      const secs = getLockRemaining(username);
      recordLoginAttempt(username, false, 'locked');
      return { ok: false, error: 'locked', lockSecs: secs };
    }
    const result = await doLogin(username, password);
    recordLoginAttempt(username, result.ok, result.error);
    return result;
  }

  function logout() { doLogout(); }

  return { session, login, logout, isLoggedIn: !!session };
}
