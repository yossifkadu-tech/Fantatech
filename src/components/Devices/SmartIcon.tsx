/**
 * SmartLife / Tuya-style device icons.
 * Each icon is a rounded-square with a gradient background + white SVG symbol.
 * Color and shape match Tuya's SmartLife app palette.
 */

interface SmartIconProps {
  domain: string;
  subtype?: string;   // e.g. "fan", "socket", "strip", "dimmer"
  isOn: boolean;
  size?: number;
}

// Domain → gradient colors (on / off)
const GRADIENTS: Record<string, [string, string]> = {
  light:        ['#f59e0b', '#f97316'],
  switch:       ['#8b5cf6', '#6d28d9'],
  cover:        ['#3b82f6', '#06b6d4'],
  lock:         ['#10b981', '#059669'],
  climate:      ['#06b6d4', '#0284c7'],
  media_player: ['#ec4899', '#db2777'],
  sensor:       ['#64748b', '#475569'],
  binary_sensor:['#64748b', '#475569'],
  camera:       ['#1d4ed8', '#2563eb'],
  alarm_control_panel: ['#ef4444', '#b91c1c'],
  fan:          ['#0ea5e9', '#0284c7'],
  humidifier:   ['#22d3ee', '#06b6d4'],
  vacuum:        ['#a78bfa', '#7c3aed'],
  device_tracker:['#0ea5e9', '#0284c7'],
  wifi:          ['#0ea5e9', '#0284c7'],
  default:       ['#3b82f6', '#1d4ed8'],
};

const OFF_BG = ['#1e293b', '#0f172a'] as [string, string];

function getGradient(domain: string, subtype: string, isOn: boolean): [string, string] {
  if (!isOn) return OFF_BG;
  const key = subtype || domain;
  return GRADIENTS[key] ?? GRADIENTS[domain] ?? GRADIENTS.default;
}

// ── Icon shapes ──
function Symbol({ domain, subtype, isOn }: { domain: string; subtype?: string; isOn: boolean }) {
  const c = isOn ? '#fff' : '#475569';
  const sw = isOn ? 2 : 1.5;

  // Light variants
  if (domain === 'light') {
    if (subtype === 'strip')
      return <><rect x="4" y="10" width="16" height="4" rx="2" fill={c} opacity=".9"/>
        {isOn && <><rect x="6" y="14" width="2" height="3" rx="1" fill={c} opacity=".5"/>
        <rect x="11" y="14" width="2" height="3" rx="1" fill={c} opacity=".5"/>
        <rect x="16" y="14" width="2" height="3" rx="1" fill={c} opacity=".5"/></>}</>
    if (subtype === 'dimmer')
      return <><circle cx="12" cy="10" r="4" fill="none" stroke={c} strokeWidth={sw}/>
        <line x1="12" y1="2" x2="12" y2="5" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
        <line x1="12" y1="19" x2="12" y2="22" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
        <line x1="4.22" y1="4.22" x2="6.34" y2="6.34" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
        <path d="M8 16H16" stroke={c} strokeWidth={sw} strokeLinecap="round"/></>
    // Default bulb
    return <><path d="M9 21h6M10 17.5a5 5 0 1 1 4 0" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/>
      <line x1="12" y1="17.5" x2="12" y2="13" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      {isOn && <circle cx="12" cy="8" r="2" fill={c} opacity=".5"/>}</>
  }

  // Switch variants
  if (domain === 'switch') {
    if (subtype === 'socket' || subtype === 'plug')
      return <><rect x="7" y="5" width="10" height="14" rx="3" fill="none" stroke={c} strokeWidth={sw}/>
        <circle cx="10" cy="11" r="1.2" fill={c}/>
        <circle cx="14" cy="11" r="1.2" fill={c}/>
        <line x1="12" y1="14" x2="12" y2="16" stroke={c} strokeWidth={sw} strokeLinecap="round"/></>
    // Power button
    return <><circle cx="12" cy="12" r="7" fill="none" stroke={c} strokeWidth={sw}/>
      <line x1="12" y1="5" x2="12" y2="12" stroke={c} strokeWidth={sw+0.5} strokeLinecap="round"/>
      {isOn && <path d="M7.76 7.76a7 7 0 1 0 8.48 0" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/>}</>
  }

  // Cover / blinds
  if (domain === 'cover')
    return <><rect x="3" y="3" width="18" height="3" rx="1" fill={c}/>
      <line x1="12" y1="6" x2="12" y2="20" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      <path d="M7 10h10M7 14h10M7 18h10" stroke={c} strokeWidth={1.2} opacity=".7" strokeLinecap="round"/></>

  // Lock
  if (domain === 'lock')
    return isOn
      ? <><rect x="6" y="11" width="12" height="10" rx="2" fill="none" stroke={c} strokeWidth={sw}/>
          <path d="M8 11V7a4 4 0 0 1 8 0v4" fill="none" stroke={c} strokeWidth={sw}/>
          <circle cx="12" cy="16" r="1.5" fill={c}/></>
      : <><rect x="6" y="11" width="12" height="10" rx="2" fill="none" stroke={c} strokeWidth={sw}/>
          <path d="M8 11V7a4 4 0 0 1 8 0v4" fill="none" stroke={c} strokeWidth={sw} strokeDasharray="3 2"/>
          <circle cx="12" cy="16" r="1.5" fill={c} opacity=".5"/></>

  // Climate / AC
  if (domain === 'climate')
    return <><path d="M12 2v20M2 12h20M5.64 5.64l12.72 12.72M18.36 5.64 5.64 18.36" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      <circle cx="12" cy="12" r="3" fill="none" stroke={c} strokeWidth={sw}/></>

  // Media player
  if (domain === 'media_player')
    return <><rect x="3" y="5" width="18" height="14" rx="2" fill="none" stroke={c} strokeWidth={sw}/>
      <polygon points="10,9 16,12 10,15" fill={c}/>
      <line x1="3" y1="19" x2="21" y2="19" stroke={c} strokeWidth={sw} strokeLinecap="round"/></>

  // Camera
  if (domain === 'camera')
    return <><path d="M23 7 16 12l7 5V7z" fill="none" stroke={c} strokeWidth={sw} strokeLinejoin="round"/>
      <rect x="1" y="5" width="15" height="14" rx="2" fill="none" stroke={c} strokeWidth={sw}/>
      {isOn && <circle cx="8" cy="12" r="2" fill={c} opacity=".6"/>}</>

  // Sensor / Binary sensor
  if (domain === 'sensor' || domain === 'binary_sensor')
    return <><path d="M12 2a10 10 0 0 1 0 20" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      <path d="M12 6a6 6 0 0 1 0 12" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      <circle cx="12" cy="12" r="2" fill={c}/></>

  // Alarm
  if (domain === 'alarm_control_panel')
    return <><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9" fill="none" stroke={c} strokeWidth={sw}/>
      <path d="M10.3 21a1.94 1.94 0 0 0 3.4 0" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      {isOn && <line x1="12" y1="2" x2="12" y2="4" stroke={c} strokeWidth={sw+1} strokeLinecap="round"/>}</>

  // WiFi / device_tracker
  if (domain === 'device_tracker' || domain === 'wifi')
    return <><path d="M5 12.55a11 11 0 0 1 14.08 0" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      <path d="M1.42 9a16 16 0 0 1 21.16 0" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      <path d="M8.53 16.11a6 6 0 0 1 6.95 0" fill="none" stroke={c} strokeWidth={sw} strokeLinecap="round"/>
      <circle cx="12" cy="20" r="1.5" fill={c}/></>

  // Default
  return <><circle cx="12" cy="12" r="7" fill="none" stroke={c} strokeWidth={sw}/>
    <line x1="12" y1="8" x2="12" y2="12" stroke={c} strokeWidth={sw+0.5} strokeLinecap="round"/>
    <circle cx="12" cy="15.5" r="1" fill={c}/></>
}

export function SmartIcon({ domain, subtype, isOn, size = 44 }: SmartIconProps) {
  const [c1, c2] = getGradient(domain, subtype ?? '', isOn);
  const r = size * 0.28; // corner radius
  const gradId = `sg-${domain}-${subtype ?? 'x'}-${isOn ? '1' : '0'}`;

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 44 44"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
      style={{ display: 'block', flexShrink: 0 }}
    >
      <defs>
        <linearGradient id={gradId} x1="0" y1="0" x2="44" y2="44" gradientUnits="userSpaceOnUse">
          <stop offset="0%" stopColor={c1}/>
          <stop offset="100%" stopColor={c2}/>
        </linearGradient>
      </defs>
      {/* Background */}
      <rect x="0" y="0" width="44" height="44" rx={r} fill={`url(#${gradId})`}/>
      {/* Subtle inner glow when on */}
      {isOn && <rect x="0" y="0" width="44" height="44" rx={r} fill="white" opacity="0.07"/>}
      {/* Icon symbol — scaled to fit 44×44 viewBox */}
      <g transform="translate(10 10) scale(1)">
        <Symbol domain={domain} subtype={subtype} isOn={isOn}/>
      </g>
    </svg>
  );
}
