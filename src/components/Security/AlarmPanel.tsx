import { useState } from 'react';
import { ShieldCheck, ShieldAlert, ShieldOff, KeyRound } from 'lucide-react';
import { callService } from '../../api/homeAssistant';
import { useLang } from '../../contexts/LanguageContext';
import type { HAEntity } from '../../types';

interface Props {
  entity: HAEntity | undefined;
}

export function AlarmPanel({ entity }: Props) {
  const { t } = useLang();
  const [code, setCode] = useState('');
  const state = entity?.state ?? 'disconnected';
  const isTriggered = state === 'triggered';
  const isDisarmed = state === 'disarmed';

  const STATE_LABELS: Record<string, string> = {
    disarmed: t('sec_alarm_disarmed'),
    armed_home: t('sec_alarm_armed_home'),
    armed_away: t('sec_alarm_armed_away'),
    armed_night: t('sec_alarm_armed_night'),
    pending: t('sec_alarm_pending'),
    triggered: t('sec_alarm_triggered'),
    arming: t('sec_alarm_arming'),
  };

  const arm = (mode: string) => {
    if (!entity) return;
    callService('alarm_control_panel', `alarm_arm_${mode}`, { entity_id: entity.entity_id, code });
    setCode('');
  };

  const disarm = () => {
    if (!entity) return;
    callService('alarm_control_panel', 'alarm_disarm', { entity_id: entity.entity_id, code });
    setCode('');
  };

  return (
    <div className={`alarm-panel glass-panel ${isTriggered ? 'alarm-triggered' : ''}`}>
      <div className="alarm-status">
        {isTriggered ? (
          <ShieldAlert size={48} color="var(--danger)" />
        ) : isDisarmed ? (
          <ShieldOff size={48} color="var(--text-secondary)" />
        ) : (
          <ShieldCheck size={48} color="var(--success)" />
        )}
        <div>
          <h2>{t('sec_alarm_title')}</h2>
          <p className={`alarm-state ${isTriggered ? 'danger' : isDisarmed ? '' : 'success'}`}>
            {entity ? STATE_LABELS[state] || state : t('sec_alarm_undefined')}
          </p>
        </div>
      </div>

      {entity && (
        <div className="alarm-controls">
          <div className="code-input-wrap">
            <KeyRound size={18} />
            <input
              type="password"
              placeholder={t('sec_code_placeholder')}
              value={code}
              onChange={(e) => setCode(e.target.value)}
              className="code-input"
              maxLength={8}
            />
          </div>
          <div className="alarm-buttons">
            <button onClick={() => arm('away')} className="btn btn-arm" disabled={!isDisarmed}>{t('sec_arm_away')}</button>
            <button onClick={() => arm('home')} className="btn btn-arm" disabled={!isDisarmed}>{t('sec_arm_home')}</button>
            <button onClick={() => arm('night')} className="btn btn-arm" disabled={!isDisarmed}>{t('sec_arm_night')}</button>
            <button onClick={disarm} className="btn btn-disarm" disabled={isDisarmed}>{t('sec_disarm')}</button>
          </div>
        </div>
      )}
    </div>
  );
}
