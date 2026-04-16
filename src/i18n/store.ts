import { LANGUAGES, t as translate, type Language, type TranslationKey } from './index';

// ── Global language state, lives outside React ──
let _lang: Language = (() => {
  try {
    const saved = localStorage.getItem('lang') as Language;
    return saved && ['he', 'en', 'ar', 'ru', 'es', 'am'].includes(saved) ? saved : 'he';
  } catch {
    return 'he';
  }
})();

const _listeners = new Set<() => void>();

export function getCurrentLang(): Language {
  return _lang;
}

export function changeLang(l: Language) {
  _lang = l;
  try { localStorage.setItem('lang', l); } catch {}
  document.documentElement.setAttribute('dir', LANGUAGES.find(x => x.code === l)?.dir ?? 'rtl');
  document.documentElement.setAttribute('lang', l);
  _listeners.forEach(fn => fn());
}

export function subscribe(fn: () => void): () => void {
  _listeners.add(fn);
  return () => _listeners.delete(fn);
}

export function tr(key: TranslationKey): string {
  return translate(_lang, key);
}

// Apply on load
document.documentElement.setAttribute('dir', LANGUAGES.find(x => x.code === _lang)?.dir ?? 'rtl');
document.documentElement.setAttribute('lang', _lang);

export { LANGUAGES, type Language, type TranslationKey };
