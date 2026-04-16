
import { Zap, Play, Power } from 'lucide-react';
import { useHomeAssistant } from '../hooks/useHomeAssistant';
import { useLang } from '../contexts/LanguageContext';
import { TopBar } from '../components/Layout/TopBar';
import { callService } from '../api/homeAssistant';

export function AutomationsPage() {
  const { status, entitiesByDomain } = useHomeAssistant();
  const { t } = useLang();
  const automations = entitiesByDomain('automation');
  const scripts = entitiesByDomain('script');

  const trigger = (entityId: string) => callService('automation', 'trigger', { entity_id: entityId });
  const toggleAuto = (entityId: string, state: string) =>
    callService('automation', state === 'on' ? 'turn_off' : 'turn_on', { entity_id: entityId });
  const runScript = (entityId: string) => callService('script', 'turn_on', { entity_id: entityId });

  return (
    <>
      <TopBar title={t('nav_automations')} status={status} />

      <h2 className="section-title">{t('auto_title')}</h2>
      <div className="automation-list">
        {automations.length === 0 ? (
          <div className="empty-state glass-panel">
            <Zap size={40} color="var(--text-secondary)" />
            <p>{t('auto_none')}</p>
          </div>
        ) : (
          automations.map((e) => {
            const name = (e.attributes.friendly_name as string) || e.entity_id;
            const isOn = e.state === 'on';
            return (
              <div key={e.entity_id} className="automation-row glass-panel">
                <div className="auto-info">
                  <Zap size={20} color={isOn ? 'var(--warning)' : 'var(--text-secondary)'} />
                  <span>{name}</span>
                  <span className={`badge ${isOn ? 'badge-success' : 'badge-muted'}`}>
                    {isOn ? t('auto_active') : t('auto_inactive')}
                  </span>
                </div>
                <div className="auto-actions">
                  <button className="btn btn-sm" onClick={() => trigger(e.entity_id)}>
                    <Play size={14} /> {t('auto_trigger')}
                  </button>
                  <button className="btn btn-sm btn-ghost" onClick={() => toggleAuto(e.entity_id, e.state)}>
                    <Power size={14} /> {isOn ? t('auto_disable') : t('auto_enable')}
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {scripts.length > 0 && (
        <>
          <h2 className="section-title">{t('auto_scripts')}</h2>
          <div className="automation-list">
            {scripts.map((e) => {
              const name = (e.attributes.friendly_name as string) || e.entity_id;
              return (
                <div key={e.entity_id} className="automation-row glass-panel">
                  <div className="auto-info">
                    <Zap size={20} color="var(--accent-color)" />
                    <span>{name}</span>
                  </div>
                  <button className="btn btn-sm" onClick={() => runScript(e.entity_id)}>
                    <Play size={14} /> {t('auto_run')}
                  </button>
                </div>
              );
            })}
          </div>
        </>
      )}
    </>
  );
}
