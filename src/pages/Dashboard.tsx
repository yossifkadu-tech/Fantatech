import { Lightbulb, ShieldCheck, Thermometer, Power, Home, Wifi } from 'lucide-react';
import { useHomeAssistant } from '../hooks/useHomeAssistant';
import { useLang } from '../contexts/LanguageContext';
import { TopBar } from '../components/Layout/TopBar';
import { DeviceCard } from '../components/Devices/DeviceCard';

function StatCard({
  label, value, icon: Icon, color, glow,
}: {
  label: string; value: number | string; icon: React.ElementType; color: string; glow: string;
}) {
  return (
    <div className="stat-card" style={{ borderColor: `rgba(${glow},0.2)` }}>
      <div className="stat-icon" style={{ background: color, boxShadow: `0 4px 16px rgba(${glow},0.35)` }}>
        <Icon size={22} color="#fff" />
      </div>
      <div>
        <p className="stat-value">{value}</p>
        <p className="stat-label">{label}</p>
      </div>
    </div>
  );
}

export function DashboardPage() {
  const { entities, status, entitiesByDomain } = useHomeAssistant();
  const { t } = useLang();

  const lights   = entitiesByDomain('light');
  const switches = entitiesByDomain('switch');
  const sensors  = entitiesByDomain('binary_sensor');
  const alarms   = entitiesByDomain('alarm_control_panel');

  const lightsOn     = lights.filter((e) => e.state === 'on').length;
  const switchesOn   = switches.filter((e) => e.state === 'on').length;
  const sensorsAlert = sensors.filter((e) => e.state === 'on').length;
  const alarmState   = alarms[0]?.state ?? '—';

  const previewDevices = [...lights, ...switches].slice(0, 8);

  return (
    <>
      <TopBar title={t('nav_dashboard')} status={status} />

      {status === 'disconnected' || status === 'error' ? (
        <div className="empty-state">
          <div style={{ padding: '1rem', background: 'rgba(59,130,246,0.1)', borderRadius: '50%' }}>
            <Wifi size={40} color="var(--accent)" />
          </div>
          <h2>{t('dash_not_connected_title')}</h2>
          <p>{t('dash_not_connected_desc').replace('{settings}', t('dash_settings_link'))}</p>
        </div>
      ) : (
        <>
          {/* Stats */}
          <div className="stats-row">
            <StatCard label={t('dash_lights_on')}     value={`${lightsOn}/${lights.length}`}    icon={Lightbulb}   color="linear-gradient(135deg,#d97706,#f59e0b)" glow="245,158,11" />
            <StatCard label={t('dash_switches_on')}   value={`${switchesOn}/${switches.length}`} icon={Power}       color="linear-gradient(135deg,#7c3aed,#8b5cf6)" glow="139,92,246" />
            <StatCard label={t('dash_sensors_active')} value={sensorsAlert}                      icon={Thermometer} color="linear-gradient(135deg,#db2777,#ec4899)" glow="236,72,153" />
            <StatCard
              label={`${t('dash_alarm')}`}
              value={alarmState === '—' ? t('dash_alarm_undefined') : alarmState}
              icon={ShieldCheck}
              color="linear-gradient(135deg,#0891b2,#06b6d4)"
              glow="6,182,212"
            />
            <StatCard label={t('dash_total')} value={entities.length} icon={Home} color="linear-gradient(135deg,#059669,#10b981)" glow="16,185,129" />
          </div>

          {/* Devices preview */}
          <h2 className="section-title">{t('dash_recent_devices')}</h2>

          {previewDevices.length === 0 && status === 'connecting' ? (
            <p className="muted">{t('dash_loading')}</p>
          ) : previewDevices.length === 0 ? (
            <p className="muted">{t('dash_no_devices')}</p>
          ) : (
            <div className="widgets-grid">
              {previewDevices.map((e) => <DeviceCard key={e.entity_id} entity={e} />)}
            </div>
          )}

          {/* Summary */}
          <div className="summary-bar">
            <span>{t('dash_total')}: <strong>{entities.length}</strong></span>
            <span>{t('dash_lights')}: <strong>{lights.length}</strong></span>
            <span>{t('dash_switches')}: <strong>{switches.length}</strong></span>
            <span>{t('dash_sensors')}: <strong>{sensors.length}</strong></span>
          </div>
        </>
      )}
    </>
  );
}
