
import { useHomeAssistant } from '../hooks/useHomeAssistant';
import { useLang } from '../contexts/LanguageContext';
import { TopBar } from '../components/Layout/TopBar';
import { AlarmPanel } from '../components/Security/AlarmPanel';
import { CameraCard, makeDemoCamera } from '../components/Security/CameraCard';
import { SensorRow } from '../components/Security/SensorRow';
import { loadConfig } from '../api/homeAssistant';

const DEMO_CAMERAS = [
  makeDemoCamera('front_door',    'Front Door'),
  makeDemoCamera('backyard',      'Backyard'),
  makeDemoCamera('garage',        'Garage'),
  makeDemoCamera('living_room',   'Living Room'),
];

export function SecurityPage() {
  const { status, entitiesByDomain } = useHomeAssistant();
  const { t } = useLang();
  const config = loadConfig();
  const token = config?.token ?? '';

  const alarms        = entitiesByDomain('alarm_control_panel');
  const cameras       = entitiesByDomain('camera');
  const binarySensors = entitiesByDomain('binary_sensor');

  const securitySensors = binarySensors.filter((e) =>
    ['motion', 'door', 'window', 'smoke', 'gas', 'moisture',
     'vibration', 'presence', 'occupancy', 'fire', 'flood', 'co']
      .some((k) => e.entity_id.includes(k))
  );

  const motionEntities = binarySensors.filter(
    (e) => e.state === 'on' && e.entity_id.includes('motion')
  );

  const isConnected = status === 'connected';
  const displayCameras = isConnected && cameras.length > 0 ? cameras : [];
  const showDemo = !isConnected || cameras.length === 0;

  const allCameras = displayCameras.length > 0 ? displayCameras : DEMO_CAMERAS;
  const [featured, ...rest] = allCameras;

  const cameraHasMotion = (entityId: string) =>
    motionEntities.some((m) => entityId.includes(m.entity_id.split('.')[1].split('_')[0]));

  return (
    <>
      <TopBar title={t('nav_security')} status={status} />

      {/* Alarm */}
      <AlarmPanel entity={alarms[0]} />

      {/* Cameras */}
      <h2 className="section-title">{t('sec_cameras')}</h2>

      {showDemo && (
        <div className="cam-demo-notice">
          Demo mode — connect Home Assistant to see real cameras
        </div>
      )}

      {/* Featured + grid layout */}
      <div className="cam-layout">
        {/* Main featured camera */}
        <div className="cam-featured-wrap">
          <CameraCard
            entity={featured}
            haUrl={config?.url ?? ''}
            token={token}
            hasMotion={cameraHasMotion(featured.entity_id)}
            featured
            isDemo={showDemo}
          />
        </div>

        {/* Side grid */}
        {rest.length > 0 && (
          <div className="cam-side-grid">
            {rest.map((e) => (
              <CameraCard
                key={e.entity_id}
                entity={e}
                haUrl={config?.url ?? ''}
                token={token}
                hasMotion={cameraHasMotion(e.entity_id)}
                isDemo={showDemo}
              />
            ))}
          </div>
        )}
      </div>

      {/* Sensors */}
      <h2 className="section-title">{t('sec_sensors')}</h2>
      <div className="sensors-list">
        {securitySensors.length === 0 ? (
          <p className="muted" style={{ padding: '1rem' }}>{t('sec_no_sensors')}</p>
        ) : (
          securitySensors.map((e) => <SensorRow key={e.entity_id} entity={e} />)
        )}
      </div>
    </>
  );
}
