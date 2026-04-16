import { useState } from 'react';
import { Save, Plug, Info, Radio, Wifi, Bluetooth, Camera, Thermometer, Lock, Shield, Globe, Palette, RotateCcw } from 'lucide-react';
import { TopBar } from '../components/Layout/TopBar';
import { saveConfig, connectHA, loadConfig } from '../api/homeAssistant';
import { useHomeAssistant } from '../hooks/useHomeAssistant';
import { useLang } from '../contexts/LanguageContext';
import { useColors } from '../hooks/useColors';
import { PRESETS } from '../stores/colorStore';
import type { ColorConfig } from '../stores/colorStore';
import { LANGUAGES } from '../i18n';
import type { Language } from '../i18n';

export function SettingsPage() {
  const { status } = useHomeAssistant();
  const { t, lang, setLang } = useLang();
  const { colors, setColor, resetColors } = useColors();
  const saved = loadConfig();
  const [url, setUrl] = useState(saved?.url ?? 'http://homeassistant.local:8123');
  const [token, setToken] = useState(saved?.token ?? '');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSave = async () => {
    if (!url || !token) {
      setMessage(t('set_fill_fields'));
      return;
    }
    setLoading(true);
    setMessage('');
    const config = { url: url.replace(/\/$/, ''), token };
    saveConfig(config);
    try {
      await connectHA(config);
      setMessage(t('set_success'));
    } catch (err: unknown) {
      setMessage(`${t('set_error')}: ${err instanceof Error ? err.message : 'לא ניתן להתחבר'}`);
    }
    setLoading(false);
  };

  const categories = [
    {
      icon: <Radio size={15} />,
      title: t('cat_wireless'),
      items: [
        { name: 'Zigbee', proto: 'Zigbee 3.0' },
        { name: 'Z-Wave', proto: 'Z-Wave Plus' },
        { name: 'Matter / Thread', proto: 'IEEE 802.15.4' },
        { name: 'Bluetooth / BLE', proto: 'BT 5.0' },
        { name: '433MHz RF', proto: 'RF Generic' },
        { name: 'KNX', proto: 'KNX / EIB' },
        { name: 'EnOcean', proto: 'Energy Harvest' },
        { name: 'IR', proto: 'Broadlink / IR' },
      ],
    },
    {
      icon: <Wifi size={15} />,
      title: t('cat_lights'),
      items: [
        { name: 'Philips Hue', proto: 'Zigbee' },
        { name: 'IKEA Tradfri', proto: 'Zigbee' },
        { name: 'Nanoleaf', proto: 'Matter / WiFi' },
        { name: 'LIFX', proto: 'WiFi' },
        { name: 'WiZ', proto: 'WiFi' },
        { name: 'Govee', proto: 'WiFi / BLE' },
        { name: 'Lutron Caseta', proto: 'Lutron Clear Connect' },
      ],
    },
    {
      icon: <Wifi size={15} />,
      title: t('cat_switches'),
      items: [
        { name: 'Shelly', proto: 'WiFi / Matter' },
        { name: 'Sonoff', proto: 'WiFi / Zigbee' },
        { name: 'Tuya / Smart Life', proto: 'WiFi / Zigbee' },
        { name: 'TP-Link Kasa / Tapo', proto: 'WiFi' },
        { name: 'Aqara', proto: 'Zigbee / Matter' },
        { name: 'Xiaomi Mi', proto: 'WiFi / Zigbee / BLE' },
        { name: 'SwitchBot', proto: 'BLE / WiFi' },
      ],
    },
    {
      icon: <Camera size={15} />,
      title: t('cat_cameras'),
      items: [
        { name: 'Hikvision', proto: 'ONVIF / RTSP' },
        { name: 'Dahua', proto: 'ONVIF / RTSP' },
        { name: 'Reolink', proto: 'RTSP / ONVIF' },
        { name: 'Amcrest', proto: 'ONVIF / RTSP' },
        { name: 'Unifi Protect', proto: 'Ubiquiti' },
        { name: 'Ring', proto: 'WiFi / Cloud' },
        { name: 'Frigate NVR', proto: 'AI Detection' },
        { name: 'TP-Link Tapo', proto: 'WiFi / RTSP' },
      ],
    },
    {
      icon: <Thermometer size={15} />,
      title: t('cat_thermostats'),
      items: [
        { name: 'Nest', proto: 'WiFi / Matter' },
        { name: 'ecobee', proto: 'WiFi / Matter' },
        { name: 'Tado', proto: 'WiFi' },
        { name: 'Bosch', proto: 'Z-Wave / WiFi' },
        { name: 'OpenTherm', proto: 'OpenTherm' },
        { name: 'Modbus', proto: 'Modbus RTU/TCP' },
      ],
    },
    {
      icon: <Lock size={15} />,
      title: t('cat_locks'),
      items: [
        { name: 'Yale', proto: 'Z-Wave / Zigbee' },
        { name: 'Nuki', proto: 'BLE / WiFi' },
        { name: 'August', proto: 'BLE / WiFi / Z-Wave' },
        { name: 'Schlage', proto: 'Z-Wave' },
        { name: 'Somfy', proto: 'RTS / io-homecontrol' },
        { name: 'Velux', proto: 'io-homecontrol' },
      ],
    },
    {
      icon: <Shield size={15} />,
      title: t('cat_alarms'),
      items: [
        { name: 'Paradox', proto: 'Serial / IP' },
        { name: 'Risco', proto: 'IP / Cloud' },
        { name: 'Visonic PowerG', proto: 'RF / IP' },
        { name: 'Crow', proto: 'Serial / IP' },
        { name: 'DSC', proto: 'IT-100 / Serial' },
        { name: 'Bosch Solution', proto: 'IP' },
      ],
    },
    {
      icon: <Bluetooth size={15} />,
      title: t('cat_iot'),
      items: [
        { name: 'MQTT', proto: 'Mosquitto Broker' },
        { name: 'ESPHome', proto: 'DIY / ESP32' },
        { name: 'Tasmota', proto: 'DIY / WiFi' },
        { name: 'Samsung SmartThings', proto: 'Zigbee / Z-Wave' },
        { name: 'Google Home', proto: 'Matter / Cloud' },
        { name: 'Apple HomeKit', proto: 'Matter / HAP' },
      ],
    },
  ];

  return (
    <>
      <TopBar title={t('set_title')} status={status} />

      {/* Language selector */}
      <div className="settings-section glass-panel">
        <h2><Globe size={20} /> {t('set_language')}</h2>
        <p className="muted">{t('set_language_desc')}</p>
        <div className="lang-selector">
          {LANGUAGES.map((l) => (
            <button
              key={l.code}
              className={`lang-btn ${lang === l.code ? 'active' : ''}`}
              onClick={() => setLang(l.code as Language)}
            >
              <span className="lang-flag">{l.flag}</span>
              <span>{l.label}</span>
            </button>
          ))}
        </div>
      </div>

      {/* Font Colors */}
      <div className="settings-section glass-panel">
        <h2><Palette size={20} /> {t('set_colors')}</h2>
        <p className="muted">{t('set_colors_desc')}</p>

        {(Object.keys(PRESETS) as (keyof ColorConfig)[]).map((key) => (
          <div key={key} className="color-row">
            <span className="color-row-label">{t(`set_color_${key}` as Parameters<typeof t>[0])}</span>
            <div className="color-swatches">
              {PRESETS[key].map((hex) => (
                <button
                  key={hex}
                  className={`color-swatch${colors[key] === hex ? ' active' : ''}`}
                  style={{ background: hex }}
                  title={hex}
                  onClick={() => setColor(key, hex)}
                />
              ))}
              {/* Custom color picker */}
              <label className="color-swatch color-swatch-custom" title="Custom color" style={{ background: colors[key] }}>
                <input
                  type="color"
                  value={colors[key]}
                  onChange={(e) => setColor(key, e.target.value)}
                />
              </label>
            </div>
          </div>
        ))}

        <button className="btn btn-ghost" onClick={resetColors}>
          <RotateCcw size={14} /> {t('set_color_reset')}
        </button>
      </div>

      {/* HA Connection */}
      <div className="settings-section glass-panel">
        <h2><Plug size={20} /> {t('set_ha_connection')}</h2>
        <p className="muted">{t('set_ha_desc')}</p>

        <div className="form-group">
          <label>{t('set_url_label')}</label>
          <input
            type="url"
            value={url}
            onChange={(e) => setUrl(e.target.value)}
            placeholder="http://homeassistant.local:8123"
            className="text-input"
          />
          <span className="hint">{t('set_url_hint')}</span>
        </div>

        <div className="form-group">
          <label>{t('set_token_label')}</label>
          <input
            type="password"
            value={token}
            onChange={(e) => setToken(e.target.value)}
            placeholder="eyJ..."
            className="text-input"
          />
          <span className="hint">{t('set_token_hint')}</span>
        </div>

        <button className="btn btn-primary" onClick={handleSave} disabled={loading}>
          <Save size={16} /> {loading ? t('set_saving') : t('set_save')}
        </button>

        {message && (
          <p className={`form-message ${message.includes(t('set_error')) || message.includes('שגיאה') ? 'error' : 'success'}`}>
            {message}
          </p>
        )}
      </div>

      {/* Brands */}
      <div className="settings-section glass-panel">
        <h2><Info size={20} /> {t('set_brands_title')}</h2>
        {categories.map((cat) => (
          <div key={cat.title} className="brands-category">
            <div className="brands-category-title">{cat.icon} {cat.title}</div>
            <div className="brands-grid">
              {cat.items.map(({ name, proto }) => (
                <div key={name} className="brand-chip glass-panel">
                  <strong>{name}</strong>
                  <span className="badge badge-muted">{proto}</span>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>
    </>
  );
}
