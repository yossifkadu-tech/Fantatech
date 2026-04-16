import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Cpu, ShieldCheck, Settings, Zap, LogOut } from 'lucide-react';
import { useLang } from '../../contexts/LanguageContext';
import { logout } from '../../stores/authStore';

export function Sidebar() {
  const { t } = useLang();

  const navItems = [
    { to: '/',            icon: LayoutDashboard, label: t('nav_dashboard')   },
    { to: '/devices',     icon: Cpu,             label: t('nav_devices')     },
    { to: '/security',    icon: ShieldCheck,     label: t('nav_security')    },
    { to: '/automations', icon: Zap,             label: t('nav_automations') },
    { to: '/settings',    icon: Settings,        label: t('nav_settings')    },
  ];

  return (
    <nav className="sidebar">
      {/* Logo */}
      <div className="logo">
        <span className="logo-part1">Fanta</span>
        <span className="logo-part2">Tech</span>
      </div>

      {/* Nav */}
      <ul className="nav-links">
        {navItems.map(({ to, icon: Icon, label }) => (
          <li key={to}>
            <NavLink
              to={to}
              end={to === '/'}
              className={({ isActive }) => (isActive ? 'active' : '')}
            >
              <Icon size={19} strokeWidth={1.8} />
              <span>{label}</span>
            </NavLink>
          </li>
        ))}
      </ul>

      {/* Logout */}
      <button className="sidebar-logout" onClick={logout}>
        <LogOut size={17} strokeWidth={1.8} />
        <span>{t('auth_logout')}</span>
      </button>

      {/* Footer */}
      <div className="sidebar-footer">
        FantaTech v1.0 · Home Assistant
      </div>
    </nav>
  );
}
