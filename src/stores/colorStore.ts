// ── Font color customization store ──
// Manages CSS custom properties for text colors.
// Architecture mirrors i18n/store.ts: module-level state + pub-sub.

export interface ColorConfig {
  primary:   string; // --text-primary
  secondary: string; // --text-secondary
  muted:     string; // --text-muted
  accent:    string; // --accent
}

export const DEFAULTS: ColorConfig = {
  primary:   '#f1f5f9',
  secondary: '#94a3b8',
  muted:     '#475569',
  accent:    '#3b82f6',
};

// Preset palettes per color slot
export const PRESETS: Record<keyof ColorConfig, string[]> = {
  primary:   ['#f1f5f9', '#ffffff', '#e2e8f0', '#fde68a', '#f0fdf4', '#fce7f3'],
  secondary: ['#94a3b8', '#64748b', '#a5b4fc', '#6ee7b7', '#fca5a5', '#fcd34d'],
  muted:     ['#475569', '#334155', '#6b7280', '#7c3aed', '#0891b2', '#b45309'],
  accent:    ['#3b82f6', '#06b6d4', '#8b5cf6', '#10b981', '#f59e0b', '#ef4444'],
};

const STORAGE_KEY = 'fantatech_colors';

function loadFromStorage(): ColorConfig {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return { ...DEFAULTS, ...JSON.parse(raw) };
  } catch {}
  return { ...DEFAULTS };
}

let _colors: ColorConfig = loadFromStorage();
const _listeners = new Set<() => void>();

function applyToDom(c: ColorConfig) {
  const root = document.documentElement;
  root.style.setProperty('--text-primary',   c.primary);
  root.style.setProperty('--text-secondary',  c.secondary);
  root.style.setProperty('--text-muted',      c.muted);
  root.style.setProperty('--accent',          c.accent);
}

// Apply on module load
applyToDom(_colors);

export function getColors(): ColorConfig {
  return _colors;
}

export function setColor(key: keyof ColorConfig, value: string) {
  _colors = { ..._colors, [key]: value };
  applyToDom(_colors);
  try { localStorage.setItem(STORAGE_KEY, JSON.stringify(_colors)); } catch {}
  _listeners.forEach(fn => fn());
}

export function resetColors() {
  _colors = { ...DEFAULTS };
  applyToDom(_colors);
  try { localStorage.removeItem(STORAGE_KEY); } catch {}
  _listeners.forEach(fn => fn());
}

export function subscribeColors(fn: () => void): () => void {
  _listeners.add(fn);
  return () => _listeners.delete(fn);
}
