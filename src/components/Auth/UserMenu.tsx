import { useState, useRef, useEffect } from 'react';
import { LogOut, Shield, ChevronDown } from 'lucide-react';
import { useAuth } from '../../hooks/useAuth';
import { useLang } from '../../contexts/LanguageContext';
import { getSecurityScore } from '../../stores/securityStore';

export function UserMenu() {
  const { session, logout } = useAuth();
  const { t } = useLang();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handler(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  if (!session) return null;

  const score = getSecurityScore();
  const scoreColor = score >= 80 ? 'var(--success)' : score >= 50 ? 'var(--warning)' : 'var(--danger)';

  return (
    <div className="user-menu-wrap" ref={ref}>
      <button className="user-menu-trigger" onClick={() => setOpen(v => !v)}>
        <span className="user-avatar">{session.avatar}</span>
        <span className="user-name">{session.displayName}</span>
        <ChevronDown size={13} style={{ opacity: 0.5 }} />
      </button>

      {open && (
        <div className="user-dropdown glass-panel">
          {/* User info */}
          <div className="user-dropdown-header">
            <span className="user-avatar-lg">{session.avatar}</span>
            <div>
              <div className="user-dd-name">{session.displayName}</div>
              <div className="user-dd-role">
                <Shield size={11}/> {session.role}
              </div>
            </div>
          </div>

          {/* Security score */}
          <div className="user-dd-score">
            <span>{t('auth_security_score')}</span>
            <span style={{ color: scoreColor, fontWeight: 700 }}>{score}/100</span>
          </div>

          <div className="user-dd-divider"/>

          <button className="user-dd-item" onClick={() => { logout(); setOpen(false); }}>
            <LogOut size={15}/>
            <span>{t('auth_logout')}</span>
          </button>
        </div>
      )}
    </div>
  );
}
