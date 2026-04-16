import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Cpu, ShieldCheck, Zap, Settings } from 'lucide-react';
import { useLang } from '../../contexts/LanguageContext';

export function BottomNav() {
  const { t } = useLang();

  const items = [
    { to: '/',            icon: LayoutDashboard, label: t('nav_dashboard')   },
    { to: '/devices',     icon: Cpu,             label: t('nav_devices')     },
    { to: '/security',    icon: ShieldCheck,     label: t('nav_security')    },
    { to: '/automations', icon: Zap,             label: t('nav_automations') },
    { to: '/settings',    icon: Settings,        label: t('nav_settings')    },
  ];

  return (
    <nav className="bottom-nav">
      {items.map(({ to, icon: Icon, label }) => (
        <NavLink
          key={to}
          to={to}
          end={to === '/'}
          className={({ isActive }) => `bottom-nav-item${isActive ? ' active' : ''}`}
        >
          <Icon size={22} strokeWidth={1.8} />
          <span>{label}</span>
        </NavLink>
      ))}
    </nav>
  );
}
