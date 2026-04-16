import { useState, useEffect } from 'react';
import { Eye, EyeOff, Shield, AlertTriangle, Lock } from 'lucide-react';
import { useAuth } from '../hooks/useAuth';
import { useLang } from '../contexts/LanguageContext';
import { getLockRemaining } from '../stores/securityStore';

export function LoginPage() {
  const { login } = useAuth();
  const { t } = useLang();

  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [loading, setLoading]   = useState(false);
  const [error, setError]       = useState('');
  const [lockSecs, setLockSecs] = useState(0);

  // Countdown timer for locked account
  useEffect(() => {
    if (lockSecs <= 0) return;
    const id = setInterval(() => setLockSecs(s => Math.max(0, s - 1)), 1000);
    return () => clearInterval(id);
  }, [lockSecs]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!username || !password) { setError(t('auth_fill_fields')); return; }
    if (lockSecs > 0) return;

    setLoading(true);
    setError('');
    const result = await login(username.trim(), password);
    setLoading(false);

    if (!result.ok) {
      if (result.error === 'locked') {
        setLockSecs(getLockRemaining(username));
        setError(t('auth_locked'));
      } else if (result.error === 'user_not_found') {
        setError(t('auth_user_not_found'));
      } else {
        setError(t('auth_wrong_password'));
      }
    }
  }

  const isLocked = lockSecs > 0;

  return (
    <div className="login-bg">
      {/* Animated background blobs */}
      <div className="login-blob blob-1"/>
      <div className="login-blob blob-2"/>
      <div className="login-blob blob-3"/>

      <div className="login-card glass-panel">
        {/* Logo */}
        <div className="login-logo">
          <div className="login-logo-icon">
            <Shield size={28} color="#3b82f6"/>
          </div>
          <div className="login-logo-text">
            <span className="logo-part1">Fanta</span>
            <span className="logo-part2">Tech</span>
          </div>
          <p className="login-subtitle">{t('auth_subtitle')}</p>
        </div>

        {/* Form */}
        <form className="login-form" onSubmit={handleSubmit} autoComplete="on">
          {/* Locked warning */}
          {isLocked && (
            <div className="login-alert locked">
              <Lock size={16}/>
              <span>{t('auth_locked_msg').replace('{s}', String(lockSecs))}</span>
            </div>
          )}

          {/* Error */}
          {error && !isLocked && (
            <div className="login-alert error">
              <AlertTriangle size={16}/>
              <span>{error}</span>
            </div>
          )}

          <div className="form-group">
            <label>{t('auth_username')}</label>
            <input
              className="text-input"
              type="text"
              value={username}
              onChange={e => setUsername(e.target.value)}
              placeholder={t('auth_username_ph')}
              autoComplete="username"
              disabled={isLocked}
            />
          </div>

          <div className="form-group">
            <label>{t('auth_password')}</label>
            <div className="input-row">
              <input
                className="text-input"
                type={showPass ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                autoComplete="current-password"
                disabled={isLocked}
              />
              <button
                type="button"
                className="btn btn-ghost btn-icon"
                onClick={() => setShowPass(v => !v)}
                tabIndex={-1}
              >
                {showPass ? <EyeOff size={16}/> : <Eye size={16}/>}
              </button>
            </div>
          </div>

          <button
            type="submit"
            className="btn btn-primary login-btn"
            disabled={loading || isLocked}
          >
            {loading ? t('auth_logging_in') : t('auth_login')}
          </button>
        </form>

        <p className="login-hint">{t('auth_default_hint')}</p>
      </div>
    </div>
  );
}
