// Re-export useLang from the store-based hook so all imports still work
export { useLang } from '../hooks/useLang';
export { LANGUAGES, changeLang as setLang } from '../i18n/store';
export type { Language, TranslationKey } from '../i18n/store';

// translate helper for App.tsx
export { tr as translate } from '../i18n/store';
