
import { Flame, Droplets, Activity, DoorOpen, Wind, Thermometer } from 'lucide-react';
import { useLang } from '../../contexts/LanguageContext';
import type { HAEntity } from '../../types';

interface Props {
  entity: HAEntity;
}

function SensorIcon({ entityId }: { entityId: string }) {
  if (entityId.includes('smoke') || entityId.includes('fire')) return <Flame size={18} color="var(--danger)" />;
  if (entityId.includes('moisture') || entityId.includes('flood')) return <Droplets size={18} color="#4FC3F7" />;
  if (entityId.includes('motion') || entityId.includes('occupancy')) return <Activity size={18} color="var(--warning)" />;
  if (entityId.includes('door') || entityId.includes('window')) return <DoorOpen size={18} color="var(--accent-color)" />;
  if (entityId.includes('gas') || entityId.includes('co')) return <Wind size={18} color="var(--danger)" />;
  return <Thermometer size={18} color="var(--text-secondary)" />;
}

export function SensorRow({ entity }: Props) {
  const { t } = useLang();
  const name = (entity.attributes.friendly_name as string) || entity.entity_id;
  const isAlert = entity.state === 'on' || entity.state === 'detected';
  const unit = entity.attributes.unit_of_measurement as string | undefined;

  return (
    <div className={`sensor-row ${isAlert ? 'sensor-alert' : ''}`}>
      <div className="sensor-icon">
        <SensorIcon entityId={entity.entity_id} />
      </div>
      <span className="sensor-name">{name}</span>
      <span className={`sensor-state ${isAlert ? 'danger' : 'muted'}`}>
        {unit ? `${entity.state} ${unit}` : isAlert ? t('sec_sensor_active') : t('sec_sensor_ok')}
      </span>
    </div>
  );
}
