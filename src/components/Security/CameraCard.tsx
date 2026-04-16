import { useState, useEffect, useRef } from 'react';
import {
  Camera, Maximize2, Download, RefreshCw,
  Wifi, WifiOff, Activity,
} from 'lucide-react';
import { useLang } from '../../contexts/LanguageContext';
import type { HAEntity } from '../../types';

interface Props {
  entity: HAEntity;
  haUrl: string;
  token: string;
  hasMotion?: boolean;
  featured?: boolean;
  isDemo?: boolean;
}

function useClock() {
  const [time, setTime] = useState(() => new Date().toLocaleTimeString());
  useEffect(() => {
    const id = setInterval(() => setTime(new Date().toLocaleTimeString()), 1000);
    return () => clearInterval(id);
  }, []);
  return time;
}

export function CameraCard({ entity, haUrl, token, hasMotion = false, featured = false, isDemo = false }: Props) {
  const { t } = useLang();
  const containerRef = useRef<HTMLDivElement>(null);
  const [online, setOnline] = useState(true);
  const [refreshKey, setRefreshKey] = useState(0);
  const time = useClock();

  const name = (entity.attributes.friendly_name as string) || entity.entity_id;

  // MJPEG live stream — browsers support this natively via <img>
  const streamUrl = token && haUrl
    ? `${haUrl}/api/camera_proxy_stream/${entity.entity_id}?token=${token}&_=${refreshKey}`
    : null;

  const snapshotUrl = token && haUrl
    ? `${haUrl}/api/camera_proxy/${entity.entity_id}?token=${token}`
    : null;

  const handleFullscreen = () => {
    if (!containerRef.current) return;
    if (document.fullscreenElement) {
      document.exitFullscreen();
    } else {
      containerRef.current.requestFullscreen();
    }
  };

  const handleDownload = () => {
    if (!snapshotUrl) return;
    const a = document.createElement('a');
    a.href = snapshotUrl;
    a.download = `${name}-${Date.now()}.jpg`;
    a.click();
  };

  const handleRefresh = () => {
    setOnline(true);
    setRefreshKey((k) => k + 1);
  };

  return (
    <div className={`cam-card ${featured ? 'cam-featured' : ''} ${hasMotion ? 'cam-motion' : ''}`} ref={containerRef}>

      {/* Feed */}
      <div className="cam-feed">
        {isDemo ? (
          <div className="cam-demo">
            <div className="cam-demo-scanner" />
            <div className="cam-demo-grid" />
            <div className="cam-demo-label">
              <Camera size={28} color="rgba(59,130,246,0.6)" />
              <span>{name}</span>
            </div>
          </div>
        ) : streamUrl && online ? (
          <img
            key={refreshKey}
            src={streamUrl}
            alt={name}
            className="cam-img"
            onError={() => setOnline(false)}
          />
        ) : (
          <div className="cam-offline">
            <WifiOff size={28} color="#475569" />
            <span>{online ? t('sec_cam_no_auth') : 'Camera offline'}</span>
            <button className="btn btn-sm" onClick={handleRefresh}>
              <RefreshCw size={13} /> {t('sec_cam_refresh')}
            </button>
          </div>
        )}

        {/* Top overlay */}
        <div className="cam-overlay-top">
          <div className="cam-badge-row">
            {hasMotion && (
              <span className="cam-badge cam-badge-motion">
                <Activity size={10} /> MOTION
              </span>
            )}
            <span className="cam-badge cam-badge-live">
              <span className="cam-dot" /> LIVE
            </span>
          </div>
          <div className="cam-controls">
            <button className="cam-btn" onClick={handleDownload} title="Snapshot">
              <Download size={14} />
            </button>
            <button className="cam-btn" onClick={handleRefresh} title={t('sec_cam_refresh')}>
              <RefreshCw size={14} />
            </button>
            <button className="cam-btn" onClick={handleFullscreen} title="Fullscreen">
              <Maximize2 size={14} />
            </button>
          </div>
        </div>

        {/* Bottom overlay */}
        <div className="cam-overlay-bottom">
          <div className="cam-name-row">
            <div className="cam-status-dot" style={{ background: online || isDemo ? '#10b981' : '#ef4444' }} />
            <span className="cam-name">{name}</span>
            {online || isDemo
              ? <Wifi size={12} color="#10b981" />
              : <WifiOff size={12} color="#ef4444" />}
          </div>
          <span className="cam-time">{time}</span>
        </div>
      </div>
    </div>
  );
}

/* ── Demo entity factory ── */
export function makeDemoCamera(id: string, name: string): HAEntity {
  return {
    entity_id: `camera.${id}`,
    state: 'streaming',
    attributes: { friendly_name: name },
    last_changed: new Date().toISOString(),
    last_updated: new Date().toISOString(),
  };
}
