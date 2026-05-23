// context/LanguageContext.js
// Language / i18n context for FantaTech
// Supports: Hebrew (RTL), Arabic (RTL), English, Russian, Spanish, Amharic, German
// No external packages — plain JS object lookup with Hebrew fallback.

import React, { createContext, useContext, useState } from "react";
import { translations } from "../i18n/translations";

/** Ordered list of supported languages. Order determines the cycle in the profile picker. */
export const LANGUAGES = [
  { code: "he", label: "עברית",   flag: "🇮🇱", rtl: true  },
  { code: "ar", label: "العربية", flag: "🇸🇦", rtl: true  },
  { code: "en", label: "English", flag: "🇺🇸", rtl: false },
  { code: "ru", label: "Русский", flag: "🇷🇺", rtl: false },
  { code: "es", label: "Español", flag: "🇪🇸", rtl: false },
  { code: "am", label: "አማርኛ",   flag: "🇪🇹", rtl: false },
  { code: "de", label: "Deutsch", flag: "🇩🇪", rtl: false },
];

const LanguageContext = createContext(null);

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState("he"); // Hebrew default

  const currentLangMeta = LANGUAGES.find((l) => l.code === language) || LANGUAGES[0];
  const isRTL = currentLangMeta.rtl;

  /**
   * t(key) — translate a string key.
   * Fallback chain: requested language → Hebrew → raw key (never blank).
   */
  function t(key) {
    const dict = translations[language] || translations["he"];
    return dict[key] ?? translations["he"][key] ?? key;
  }

  /** Advance to the next language in the LANGUAGES cycle. */
  function nextLanguage() {
    const idx = LANGUAGES.findIndex((l) => l.code === language);
    const next = LANGUAGES[(idx + 1) % LANGUAGES.length];
    setLanguage(next.code);
  }

  return (
    <LanguageContext.Provider
      value={{
        language,
        setLanguage,
        t,
        isRTL,
        currentLangMeta,
        nextLanguage,
        LANGUAGES,
      }}
    >
      {children}
    </LanguageContext.Provider>
  );
}

export function useLanguage() {
  const ctx = useContext(LanguageContext);
  if (!ctx) throw new Error("useLanguage must be used inside <LanguageProvider>");
  return ctx;
}
