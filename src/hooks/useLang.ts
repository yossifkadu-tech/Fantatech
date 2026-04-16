import { useState, useEffect } from 'react';
import { getCurrentLang, changeLang, subscribe, tr, LANGUAGES } from '../i18n/store';
import type { TranslationKey } from '../i18n/store';

export function useLang() {
  const [lang, setLang] = useState(getCurrentLang);

  useEffect(() => {
    // Sync in case lang changed before this effect ran (StrictMode double-invoke)
    setLang(getCurrentLang());
    return subscribe(() => setLang(getCurrentLang()));
  }, []);

  function setLangFn(l: Parameters<typeof changeLang>[0]) {
    changeLang(l);
  }

  // t is NOT memoized — always a fresh closure so it picks up the latest _lang
  function t(key: TranslationKey): string {
    return tr(key);
  }

  const dir = LANGUAGES.find(l => l.code === lang)?.dir ?? 'rtl';

  return { lang, setLang: setLangFn, t, dir };
}
