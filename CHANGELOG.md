# Fantatech Home & Security — Changelog

כל שינוי משמעותי במערכת מתועד כאן.
פורמט: `[גרסה] — תאריך`

---

## [1.6.1] — 2026-05-01 ← נוכחי

### תוקן / שופר
- **DeviceCard** — מציג שם חדר ואייקון במקום ID גולמי
- **Dashboard** — כמות אוטומציות ממשית (מה-API), כמות חדרים, מכשירים מוצמדים ב-"פועלים עכשיו", אייקוני היסטוריה (💡/🌙), כפתור "הכל ›" להיסטוריה, אזהרה ויזואלית כש-Hub לא מחובר
- **Header** — מציג גרסת App וגרסת Hub · באנר צהוב אם הגרסאות לא תואמות (→ הפעל מחדש start-hub.bat)
- **Hub startup** — חיבור WiFi אוטומטי לפרופיל שמור בהפעלת Hub
- **`GET /api/version`** — endpoint חדש עם גרסת Hub
- **Hub title** → `Fantatech Home & Security v1.6.1`
- **APK v1.6.1**

---

## [1.6.0] — 2026-05-01

### נוסף — ניהול ראוטרים מרובים (Multi-Router)
- **סריקה + רשימה** — כל הרשתות הנראות מוצגות עם עוצמת אות, מנעול, תג "שמור" / "מחובר"
- **חיבור לכל ראוטר** — מודל עם שדה סיסמה (👁 חשיפה), שמירה וחיבור אוטומטי
- **ניהול פרופילים שמורים**:
  - חץ ▲▼ לשינוי עדיפות (הראשון = יתנסה ראשון בחיבור אוטומטי)
  - toggle לכל ראוטר: "חיבור אוטומטי" פועל/כבוי
  - כפתור 🗑️ למחיקת פרופיל
- **כפתור "🔄 התחבר אוטו"** — מנסה להתחבר לראוטרים השמורים לפי עדיפות עד שמצליח
- **`POST /api/network/auto-connect`** — endpoint חדש לחיבור אוטומטי מסודר
- **`PUT /api/network/saved/{ssid}/priority`** — עדכון עדיפות
- **`PUT /api/network/saved/{ssid}/auto-connect`** — הפעל/כבה אוטו לכל ראוטר
- **DB**: עמודות `priority`, `auto_connect` ב-`wifi_profiles`

---

## [1.5.0] — 2026-05-01

### נוסף
- **טאב 🔵 Bluetooth** בעמוד הרשת
  - סריקת BLE אמיתית (12 שניות, עצירה ידנית) — מציגה שם, עוצמת אות (dBm), סוג משוער
  - זיהוי אוטומטי של סוג: נורה / חיישן / מתג / מנעול / מאוורר לפי שם המכשיר
  - כפתור "+ הוסף" לרישום מכשיר BLE ב-Hub עם שם, סוג וחדר
  - הרשאות Android: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT` (Android 12+) + `BLUETOOTH`, `ACCESS_FINE_LOCATION` (Android <12)
  - בדפדפן: הודעה "אינו זמין — השתמש ב-APK"

### תוקן
- **שגיאת NOT FOUND בחדרים** — הודעת שגיאה ברורה מדריכה להפעיל מחדש את start-hub.bat
- **סריקת WiFi נכשלת** — נוסף כפתור "הזן SSID ידנית" תמיד זמין
- **APK v1.5.0**

---

## [1.4.1] — 2026-05-01

### תוקן
- **שגיאת NOT FOUND בחדרים** — הודעת שגיאה ברורה מדריכה להפעיל מחדש את start-hub.bat
- **סריקת WiFi נכשלת** — נוסף כפתור "הזן SSID ידנית" שמאפשר להקיש שם רשת ידנית כשהסריקה לא עובדת
- **APK v1.4.1**

---

## [1.4.0] — 2026-05-01

### נוסף
- **עמוד רשת (📡 מכשירים / 📶 WiFi)** — טאב חדש בניווט
  - **סריקת מכשירים אמיתית** — ping sweep ל-254 כתובות + קריאת ARP table
  - **זיהוי אוטומטי לפי פרוטוקול**: 🟠 Tasmota · 🔴 Shelly · 🔵 ESPHome · 🌐 HTTP
  - **צימוד אוטומטי Tasmota** — מגדיר `MqttHost/MqttPort/Topic` ישירות על המכשיר דרך HTTP
  - **צימוד אוטומטי Shelly** — מגדיר `settings/mqtt` דרך HTTP
  - **הוספה ידנית** לכל מכשיר HTTP/ESPHome עם בחירת שם, סוג, חדר
  - **חיבור WiFi** — סריקת SSIDים, חיבור עם סיסמה (כפתור 👁 לחשיפה), שמירת חיבור קבוע
  - **שיוך חדר** בעת חיבור WiFi
- **`POST /api/network/pair`** — endpoint חדש לצימוד אוטומטי + רישום ב-DB
- **`GET /api/network/scan-devices`** — סריקת subnet אמיתית עם ARP + ping + HTTP probe

### תוקן
- **שמירת שם מכשיר/חדר לא עבדה** — נוסף migration אוטומטי ב-`init_db` שמוסיף עמודות חסרות (`label`, `pinned`) לכל DB קיים
- **כפתורי עריכה/מחיקה** — הועברו לפס בולט מתחת לכל כרטיס/שורה, גדולים וקלים ללחיצה במובייל
- **Rename modal** — שדות מחוברים נכון לפקודת PUT, תמיכה ב-Enter לשמירה מהירה, הודעת שגיאה ברורה

### שונה
- **שם האפליקציה** → `Fantatech Home & Security` (strings.xml, capacitor.config, PWA manifest, כותרת)
- **תצוגת מכשירים** — רשימה שטוחה (לא לפי חדרים): מוצמדים → מחוברים → מנותקים; תגית חדר על הכרטיס
- **APK v1.4.0** — `SmartHomeHub-v1.4.0.apk`

---

## [1.3.0] — 2026-05-01

### נוסף
- **עריכת ומחיקת חדרים** — כפתורי ✏️ ו-🗑️ בכל חדר, מכשירים עוברים ל"ללא חדר" אוטומטית
- **חיפוש מכשירים** — שדה חיפוש בראש עמוד המכשירים (שם + תווית)
- **הצמדת מכשיר** — כפתור 📌 לכל מכשיר, מכשירים מוצמדים מופיעים ראשונים
- **שינוי שם ותווית** — כפתור ✏️ לכל מכשיר לעדכון שם + ספק/תווית
- **DeviceCard** — מציג סמל 📌 כשמוצמד, תווית (ספק) בכחול מתחת לשם
- **Backend**: `POST /api/devices/{id}/pin`, `PUT /api/devices/{id}/rename`
- **Database**: עמודות `pinned INTEGER`, `label TEXT` בטבלת devices

---

## [1.2.0] — 2026-04-30

### נוסף
- **App מלא (React + Vite + PWA)**
  - דשבורד עם סטטיסטיקות, מכשירים פעילים, היסטוריה אחרונה
  - עמוד מכשירים עם כרטיסיות, דימר, חיישנים, WebSocket real-time
  - עמוד אוטומציות — Cron, טריגר מצב מכשיר, הפעלה ידנית
  - עמוד חדרים עם אייקונים
  - עמוד היסטוריה עם חיפוש וסינון
  - ניווט תחתון (Bottom Nav) בסגנון מובייל
  - WebSocket — עדכון מצב בזמן אמת
  - PWA — ניתן להתקין מהדפדפן
- **start-app.bat** — הפעלת App בלחיצה אחת
- **APK v1.2.0**

### שונה
- `start-all.bat` — תוקן נתיב Mosquitto ל-`C:\Program Files\mosquitto\`

---

## [1.1.0] — 2026-04-30

### נוסף
- **WiFi Bridge** (`bridges/wifi/wifi_bridge.py`)
  - סריקת subnet אוטומטית (192.168.10.x)
  - זיהוי אוטומטי של Tasmota / ESPHome
  - Polling כל 30 שניות
  - שליטה: הדלקה/כיבוי, בהירות, צבע
- **Zigbee Bridge** (`bridges/zigbee/zigbee_bridge.py`)
  - תמיכה ב-Sonoff Zigbee 3.0 (znp) ו-ConBee II (deconz)
  - קריאת מצב: מתג, בהירות, טמפרטורה, לחות, תנועה
  - Permit Join מ-MQTT
- **start-zigbee.bat**, **start-wifi.bat**

---

## [1.0.0] — 2026-04-30

### נוסף
- **MQTT Broker (Mosquitto)** — פורטים 1883, 9001
- **Smart Home Hub** (`hub/`) — FastAPI על פורט 8080
  - MQTT Client, WebSocket, Rule Engine (Cron + device_state)
- **Database (SQLite)** — טבלאות: `devices`, `history`, `rules`, `rooms`
- **REST API** — CRUD מלא לכל הישויות
- **start-hub.bat**, **start-all.bat**, **install.bat**

---

## פרוטוקולים נתמכים

| פרוטוקול | סטטוס | Bridge |
|----------|--------|--------|
| WiFi — Tasmota | ✅ פעיל + צימוד אוטומטי | network.py + wifi_bridge.py |
| WiFi — Shelly | ✅ פעיל + צימוד אוטומטי | network.py |
| WiFi — ESPHome | ✅ זיהוי + הוספה ידנית | wifi_bridge.py |
| Zigbee (znp/CC2652) | ✅ מוכן | zigbee_bridge.py |
| Zigbee (deconz/ConBee) | ✅ מוכן | zigbee_bridge.py |
| MQTT Generic | ✅ פעיל | hub ישיר |
| Cameras (RTSP) | 🔜 בתכנון | — |
| Z-Wave | 🔜 בתכנון | — |
| Matter | 🔜 בתכנון | — |

---

## תכנון עתידי

- [ ] Camera bridge (RTSP + motion detection)
- [ ] Z-Wave bridge
- [ ] Matter bridge
- [ ] Scenes (סצנות — הפעלת קבוצת מכשירים)
- [ ] Energy monitoring dashboard
- [ ] Push notifications למובייל
- [ ] ESPHome native API pairing
