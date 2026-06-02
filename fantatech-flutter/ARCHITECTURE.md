# FantaTech — מדריך ארכיטקטורה

מסמך זה מתאר איך האפליקציה בנויה ואת **כללי הפרדת התחומים** (Separation of Concerns)
שיש לשמור עליהם כדי שהאפליקציה תישאר יציבה וקלה לתחזוקה ככל שהיא גדלה.

> כלל זהב אחד: **כל שכבה מכירה רק את השכבה שמתחתיה. שכבה תחתונה לעולם לא מכירה את זו שמעליה.**

---

## כיוון התלות (Dependency Direction)

```
   UI            screens/  ·  widgets/
    │  קורא בלבד ↓
   State         models/  (AppState, Device, MediaModule, CustomScene)
    │  קורא בלבד ↓
   Services      services/  (discovery, gateways, cameras, auth, sensors, switches)
    │            ↓
   External      גשרים · מכשירים · ענן · רשת מקומית
```

UI מדבר עם State. State מדבר עם Services. Services מדברים עם העולם החיצון.
אסור לדלג שכבות כלפי מעלה.

---

## מבנה התיקיות

| תיקייה | תפקיד | מותר | אסור |
|--------|-------|------|------|
| `lib/main.dart` | נקודת כניסה + ניווט ראשי + Providers | אתחול | לוגיקה עסקית |
| `lib/models/` | נתונים + מצב גלובלי | מחלקות נתונים, `AppState` | לייבא `screens/` או Flutter UI |
| `lib/screens/` | מסכי UI לפי פיצ'ר | תצוגה, `context.watch/read` | קריאות רשת, לוגיקה עסקית |
| `lib/widgets/` | רכיבי UI לשימוש חוזר | UI טהור | החזקת מצב גלובלי |
| `lib/services/` | לוגיקה + תקשורת רשת | HTTP, גילוי, פרוטוקולים | לייבא `screens/` |
| `lib/l10n/` | מחרוזות + 6 שפות (`strings.dart`) | טקסט בלבד | קוד לוגי |
| `lib/theme/` | צבעים + עיצוב (`app_theme.dart`) | סגנון בלבד | — |
| `lib/utils/` | עזרים קטנים (haptics, price_format) | פונקציות טהורות | תלות ב-UI |
| `lib/mock/` | נתוני דמו ראשוניים | — | בקוד אמת בלבד |

---

## ניהול מצב (State Management)

האפליקציה משתמשת ב-**Provider (ChangeNotifier)**. שלושה providers גלובליים:

| Provider | אחריות |
|----------|--------|
| `AppState` | מקור האמת היחיד: מכשירים, חדרים, מדיה, סצנות, שפה, אבטחה, פרופיל |
| `GatewayManager` | חיבור וייבוא מגשרים (Hue / Tuya / Z2M / deCONZ / SmartThings / MQTT) |
| `RealDiscoveryEngine` | גילוי מכשירים ברשת (BLE / mDNS / WiFi / LAN) |

זרימת עדכון:
```
משתמש → Screen → state.someAction() → notifyListeners() → כל ה-watchers מתעדכנים
```

---

## 4 הכללים המעשיים

**1. UI לא מחזיק נתונים** — כל נתון חי ב-`AppState`, לא ב-`State` של מסך.

**2. Service לא יודע על UI** — service מחזיר `Future<List<Device>>`, המסך מצייר.

**3. שינוי מצב רק דרך AppState** — `state.toggleDevice(id)`, אף פעם לא משנים נתון ישירות מ-UI.

**4. תקשורת דרך מודלים** — Services ↔ State ↔ UI מעבירים אובייקטי `models/`, לא widgets.

---

## "איפה זה הולך?" — שאלון מהיר לפני הוספת פיצ'ר

1. **נתון חדש?** → `models/` (+ getter/setter ב-`AppState`)
2. **לוגיקה / רשת?** → `services/`
3. **מסך / תצוגה?** → `screens/` או `widgets/`
4. **טקסט למשתמש?** → `l10n/strings.dart` (חובה 6 שפות)
5. **צבע / סגנון?** → `theme/app_theme.dart`

---

## נקודות תשומת לב (Gotchas)

- **הוספת `DeviceType` חדש** → יש לעדכן את כל ה-`switch` הממצים (אייקון/צבע/תווית) ב:
  `widgets/device_card.dart`, `screens/devices/devices_screen.dart`,
  `screens/notifications/notifications_screen.dart`. אחרת הקומפילציה תיכשל.
- **הוספת שפה** → `AppLocale` enum + `strings.dart` + `supportedLocales` ב-`main.dart`.
- **מחרוזות** → אסור טקסט מקודד קשיח ב-UI. הכל דרך `s.<key>` מ-`context.watch<AppState>().strings`.
- **`const`** → אסור `const Text(s.key)` (ערך לא-const) — להסיר `const`.

---

## בנייה (Build)

```bash
flutter build apk --split-per-abi --release --no-tree-shake-icons
# פלט: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

לפני בנייה — תמיד:
```bash
flutter analyze    # חייב 0 errors
```

---

## אינטגרציות מכשירים (Device Integrations)

| חיבור | מימוש | מיקום |
|-------|-------|-------|
| WiFi (Shelly/Sonoff/Tuya/Tapo) | גילוי LAN ישיר | `services/discovery/` |
| Tuya / Moes (ענן) | Tuya OpenAPI + HMAC | `services/gateways/clients/tuya_cloud_client.dart` |
| Zigbee | Zigbee2MQTT REST | `services/gateways/clients/z2m_client.dart` |
| מצלמות | ONVIF / RTSP / MJPEG | `services/cameras/` |
| Matter/Thread | mDNS discovery (שלד) | `services/discovery/matter_discovery.dart` |

---

*מסמך זה הוא חוזה האדריכלות של הפרויקט. שמירה עליו = אפליקציה שתמשיך לעבוד גם בגודל פי 10.*
