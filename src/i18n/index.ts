import he from './he';
import en from './en';
import ar from './ar';
import ru from './ru';
import es from './es';
import am from './am';

export type Language = 'he' | 'en' | 'ar' | 'ru' | 'es' | 'am';
export type TranslationKey = keyof typeof he;

export const translations = { he, en, ar, ru, es, am } as const;

export const LANGUAGES: { code: Language; label: string; flag: string; dir: 'rtl' | 'ltr' }[] = [
  { code: 'he', label: 'עברית',    flag: '🇮🇱', dir: 'rtl' },
  { code: 'en', label: 'ENGLISH USA', flag: '🇺🇸', dir: 'ltr' },
  { code: 'ar', label: 'العربية',  flag: '🇸🇦', dir: 'rtl' },
  { code: 'ru', label: 'Русский',  flag: '🇷🇺', dir: 'ltr' },
  { code: 'es', label: 'Español',  flag: '🇪🇸', dir: 'ltr' },
  { code: 'am', label: 'አማርኛ',    flag: '🇪🇹', dir: 'ltr' },
];

export function t(lang: Language, key: TranslationKey): string {
  return (translations[lang] as Record<string, string>)[key] ?? (translations.he as Record<string, string>)[key] ?? key;
}
