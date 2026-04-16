import { Star } from 'lucide-react';
import { SmartIcon } from './SmartIcon';
import { callService } from '../../api/homeAssistant';
import { useLang } from '../../contexts/LanguageContext';
import type { HAEntity } from '../../types';

interface Props {
  entity: HAEntity;
  isFavorite?: boolean;
  onToggleFavorite?: (entityId: string) => void;
}

function friendlyName(entity: HAEntity): string {
  return (entity.attributes.friendly_name as string) || entity.entity_id;
}

// Detect subtype from entity_id or attributes
function detectSubtype(entity: HAEntity): string | undefined {
  const id = entity.entity_id.toLowerCase();
  if (id.includes('strip') || id.includes('led_strip')) return 'strip';
  if (id.includes('dimmer')) return 'dimmer';
  if (id.includes('socket') || id.includes('plug')) return 'socket';
  return undefined;
}

export function DeviceCard({ entity, isFavorite, onToggleFavorite }: Props) {
  const { t } = useLang();
  const domain = entity.entity_id.split('.')[0];
  const isOn = ['on', 'locked', 'open', 'home', 'heat', 'cool', 'auto', 'playing'].includes(entity.state);
  const isSensor = domain === 'sensor' || domain === 'binary_sensor';

  const handleToggle = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (isSensor) return;
    if (domain === 'light' || domain === 'switch' || domain === 'media_player') {
      callService(domain, isOn ? 'turn_off' : 'turn_on', { entity_id: entity.entity_id });
    } else if (domain === 'cover') {
      callService('cover', isOn ? 'close_cover' : 'open_cover', { entity_id: entity.entity_id });
    } else if (domain === 'lock') {
      callService('lock', isOn ? 'unlock' : 'lock', { entity_id: entity.entity_id });
    }
  };

  const brightness = entity.attributes.brightness as number | undefined;
  const temp = entity.attributes.current_temperature as number | undefined;
  const unit = entity.attributes.unit_of_measurement as string | undefined;

  const stateLabel = unit
    ? `${entity.state} ${unit}`
    : temp
    ? `${temp}°C`
    : entity.state === 'on' ? t('dev_on')
    : entity.state === 'off' ? t('dev_off')
    : entity.state;

  return (
    <div
      className={`device-card domain-${domain} ${isOn ? 'device-on' : ''} ${isSensor ? 'domain-sensor' : ''}`}
      onClick={isSensor ? undefined : handleToggle}
    >
      <div className="device-card-top">
        <div className="device-icon-wrap">
          <SmartIcon domain={domain} subtype={detectSubtype(entity)} isOn={isOn} size={44} />
        </div>
        <div className="card-top-right">
          {onToggleFavorite && (
            <button
              className={`fav-btn${isFavorite ? ' active' : ''}`}
              onClick={e => { e.stopPropagation(); onToggleFavorite(entity.entity_id); }}
            >
              <Star size={13} fill={isFavorite ? '#f59e0b' : 'none'} color={isFavorite ? '#f59e0b' : '#475569'} />
            </button>
          )}
          {!isSensor && (
            <div className={`toggle ${isOn ? 'on' : ''}`} onClick={handleToggle} />
          )}
        </div>
      </div>

      <div className="device-card-bottom">
        <div className="device-name">{friendlyName(entity)}</div>
        <div className="device-state">{stateLabel}</div>
        {domain === 'light' && brightness && (
          <div className="brightness-bar">
            <div className="brightness-fill" style={{ width: `${Math.round((brightness / 255) * 100)}%` }} />
          </div>
        )}
      </div>
    </div>
  );
}
