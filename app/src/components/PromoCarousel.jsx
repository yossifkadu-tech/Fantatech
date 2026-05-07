import { useState, useRef, useEffect } from 'react'
import { useLang } from '../context/LangContext'

/* ── Product catalogue — multilingual ─────────────────────────────────────── */
const PROMOS = [
  {
    id: 'moes-gw',
    icon: '📡',
    imageUrl: 'https://www.moes-smarthome.com/wp-content/uploads/2022/06/ZB-GW04.jpg',
    badge:    { he: '🔥 חם', en: '🔥 HOT', ar: '🔥 رائج', ru: '🔥 Хит', es: '🔥 TOP', fr: '🔥 TOP', de: '🔥 TOP', pt: '🔥 HOT', am: '🔥 HOT' },
    badgeColor: '#ef4444',
    title: 'Moes Multi Gateway',
    subtitle: { he: 'Zigbee 3.0 + BLE + WiFi', en: 'Zigbee 3.0 + BLE + WiFi', ar: 'Zigbee 3.0 + BLE + WiFi', ru: 'Zigbee 3.0 + BLE + WiFi', es: 'Zigbee 3.0 + BLE + WiFi', fr: 'Zigbee 3.0 + BLE + WiFi', de: 'Zigbee 3.0 + BLE + WiFi', pt: 'Zigbee 3.0 + BLE + WiFi', am: 'Zigbee 3.0 + BLE + WiFi' },
    desc: {
      he: 'גייטווי כל-בשלושה — שולט על עשרות מכשירי Zigbee, חיישנים ונורות בבית החכם.',
      en: 'All-in-three gateway — controls dozens of Zigbee devices, sensors and bulbs in your smart home.',
      ar: 'بوابة متعددة — تتحكم في عشرات أجهزة Zigbee والمستشعرات والمصابيح.',
      ru: 'Многофункциональный шлюз — управляет десятками Zigbee-устройств, датчиков и ламп.',
      es: 'Gateway todo-en-uno — controla docenas de dispositivos Zigbee, sensores y bombillas.',
      fr: 'Passerelle tout-en-un — contrôle des dizaines d\'appareils Zigbee, capteurs et ampoules.',
      de: 'Alles-in-einem Gateway — steuert Dutzende Zigbee-Geräte, Sensoren und Lampen.',
      pt: 'Gateway tudo-em-um — controla dezenas de dispositivos Zigbee, sensores e lâmpadas.',
      am: 'All-in-three gateway',
    },
    price: '₪79–120',
    tag: 'Tuya',
    tagColor: '#f59e0b',
    search: 'Moes ZB-GW04 Zigbee Gateway',
    bg: 'linear-gradient(135deg,#1c1007 0%,#1a1200 100%)',
    border: '#f59e0b',
    aff: 'https://www.aliexpress.com/w/wholesale-moes-zigbee-gateway.html',
  },
  {
    id: 'sonoff-basic',
    icon: '🔌',
    imageUrl: 'https://itead.cc/wp-content/uploads/2022/12/BASIC-R4-1.jpg',
    badge:    { he: '⚡ פופולרי', en: '⚡ Popular', ar: '⚡ شائع', ru: '⚡ Хит', es: '⚡ Popular', fr: '⚡ Populaire', de: '⚡ Beliebt', pt: '⚡ Popular', am: '⚡ Popular' },
    badgeColor: '#1d4ed8',
    title: 'Sonoff BASIC R4',
    subtitle: { he: 'מפסק WiFi חכם', en: 'Smart WiFi Switch', ar: 'مفتاح WiFi ذكي', ru: 'Умный WiFi выключатель', es: 'Interruptor WiFi inteligente', fr: 'Interrupteur WiFi intelligent', de: 'Smarter WLAN-Schalter', pt: 'Interruptor WiFi inteligente', am: 'Smart WiFi Switch' },
    desc: {
      he: 'מפסק WiFi לחיתוך גחלת — תואם Tasmota, ESPHome, MQTT. הכי נמכר בקטגוריה.',
      en: 'WiFi inline switch — compatible with Tasmota, ESPHome, MQTT. Best-seller in its category.',
      ar: 'مفتاح WiFi — متوافق مع Tasmota وESPHome وMQTT. الأكثر مبيعاً في فئته.',
      ru: 'WiFi выключатель — совместим с Tasmota, ESPHome, MQTT. Лидер продаж.',
      es: 'Interruptor WiFi — compatible con Tasmota, ESPHome, MQTT. El más vendido.',
      fr: 'Interrupteur WiFi — compatible Tasmota, ESPHome, MQTT. Best-seller.',
      de: 'WiFi Schalter — kompatibel mit Tasmota, ESPHome, MQTT. Meistverkauft.',
      pt: 'Interruptor WiFi — compatível com Tasmota, ESPHome, MQTT. Mais vendido.',
      am: 'WiFi switch compatible with Tasmota, ESPHome, MQTT.',
    },
    price: '₪25–45',
    tag: 'WiFi',
    tagColor: '#22c55e',
    search: 'Sonoff BASIC R4 WiFi switch',
    bg: 'linear-gradient(135deg,#0c1a0c 0%,#0a1f0a 100%)',
    border: '#22c55e',
    aff: 'https://itead.cc/product/sonoff-basic-wifi-smart-switch/',
  },
  {
    id: 'ezviz-cam',
    icon: '📷',
    imageUrl: 'https://image.ezviz.com/upload/product/2022/images/c6cn/01-D.jpg',
    badge:    { he: '🛡️ אבטחה', en: '🛡️ Security', ar: '🛡️ أمان', ru: '🛡️ Охрана', es: '🛡️ Seguridad', fr: '🛡️ Sécurité', de: '🛡️ Sicherheit', pt: '🛡️ Segurança', am: '🛡️ Security' },
    badgeColor: '#7c3aed',
    title: 'EZVIZ C6 Pro',
    subtitle: { he: 'מצלמת אבטחה 360°', en: '360° Security Camera', ar: 'كاميرا أمان 360°', ru: 'Камера безопасности 360°', es: 'Cámara de seguridad 360°', fr: 'Caméra de sécurité 360°', de: '360° Sicherheitskamera', pt: 'Câmera de segurança 360°', am: '360° Security Camera' },
    desc: {
      he: 'מצלמת 4MP עם Pan/Tilt 360°, ראיית לילה, זיהוי תנועה AI וצפייה מכל מקום.',
      en: '4MP camera with 360° Pan/Tilt, night vision, AI motion detection and remote viewing.',
      ar: 'كاميرا 4MP مع Pan/Tilt 360°، رؤية ليلية، كشف حركة AI ومشاهدة عن بُعد.',
      ru: 'Камера 4MP с поворотом 360°, ночным видением, AI-детекцией движения.',
      es: 'Cámara 4MP con Pan/Tilt 360°, visión nocturna, detección de movimiento AI.',
      fr: 'Caméra 4MP avec Pan/Tilt 360°, vision nocturne, détection de mouvement AI.',
      de: '4MP Kamera mit 360° Pan/Tilt, Nachtsicht, KI-Bewegungserkennung.',
      pt: 'Câmera 4MP com Pan/Tilt 360°, visão noturna, detecção de movimento AI.',
      am: '4MP camera with 360° Pan/Tilt and AI motion detection.',
    },
    price: '₪150–220',
    tag: 'Smart Cam',
    tagColor: '#7c3aed',
    search: 'EZVIZ C6 Pro smart camera',
    bg: 'linear-gradient(135deg,#1a0c2e 0%,#120a22 100%)',
    border: '#7c3aed',
    aff: 'https://www.ezviz.com/product/c6-pro/1284',
  },
  {
    id: 'aqara-motion',
    icon: '👤',
    imageUrl: 'https://www.aqara.com/media/media_gallery/FP2_400x400.webp',
    badge:    { he: '🌟 מומלץ', en: '🌟 Recommended', ar: '🌟 موصى به', ru: '🌟 Рекомендуем', es: '🌟 Recomendado', fr: '🌟 Recommandé', de: '🌟 Empfohlen', pt: '🌟 Recomendado', am: '🌟 Recommended' },
    badgeColor: '#38bdf8',
    title: 'Aqara Motion Sensor P2',
    subtitle: { he: 'חיישן תנועה + מרחק', en: 'Presence + Distance Sensor', ar: 'حساس حركة + مسافة', ru: 'Датчик присутствия + дистанция', es: 'Sensor de presencia + distancia', fr: 'Capteur de présence + distance', de: 'Anwesenheits- und Distanzsensor', pt: 'Sensor de presença + distância', am: 'Presence + Distance Sensor' },
    desc: {
      he: 'חיישן עם גלאי רדאר mmWave — מזהה נוכחות ברדיוס 7 מטר, תואם HomeKit / Z2M.',
      en: 'mmWave radar sensor — detects presence within 7m radius, compatible with HomeKit / Z2M.',
      ar: 'حساس رادار mmWave — يكشف الوجود في نطاق 7 أمتار، متوافق مع HomeKit / Z2M.',
      ru: 'mmWave радар — обнаруживает присутствие в радиусе 7м, совместим с HomeKit / Z2M.',
      es: 'Sensor radar mmWave — detecta presencia en 7m, compatible con HomeKit / Z2M.',
      fr: 'Capteur radar mmWave — détecte la présence à 7m, compatible HomeKit / Z2M.',
      de: 'mmWave Radarsensor — erkennt Anwesenheit bis 7m, HomeKit / Z2M kompatibel.',
      pt: 'Sensor radar mmWave — detecta presença em 7m, compatível com HomeKit / Z2M.',
      am: 'mmWave radar sensor, detects presence in 7m radius.',
    },
    price: '₪90–140',
    tag: 'Zigbee',
    tagColor: '#38bdf8',
    search: 'Aqara FP2 motion presence sensor',
    bg: 'linear-gradient(135deg,#0c1d29 0%,#0a1722 100%)',
    border: '#38bdf8',
    aff: 'https://www.aqara.com/en/product/presence-sensor-fp2',
  },
  {
    id: 'smart-lock',
    icon: '🔒',
    imageUrl: 'https://images.tuyaeu.com/smart/product-img/B2B/2022/02/17/bcf61fa8-3494-4834-95a6-7a6f3bf35f02.jpg',
    badge:    { he: '🏠 אבטחה', en: '🏠 Security', ar: '🏠 أمان', ru: '🏠 Охрана', es: '🏠 Seguridad', fr: '🏠 Sécurité', de: '🏠 Sicherheit', pt: '🏠 Segurança', am: '🏠 Security' },
    badgeColor: '#ef4444',
    title: 'Tuya Smart Lock',
    subtitle: { he: 'מנעול טביעת אצבע + קוד + מפתח', en: 'Fingerprint + Code + Key Lock', ar: 'قفل بصمة + رمز + مفتاح', ru: 'Замок: отпечаток + код + ключ', es: 'Cerradura: huella + código + llave', fr: 'Verrou: empreinte + code + clé', de: 'Schloss: Fingerabdruck + Code + Schlüssel', pt: 'Fechadura: digital + código + chave', am: 'Fingerprint + Code + Key Lock' },
    desc: {
      he: 'מנעול חכם עם 5 שיטות פתיחה: אצבע, קוד, כרטיס, מפתח ואפליקציה. IP65.',
      en: 'Smart lock with 5 unlock methods: fingerprint, code, card, key and app. IP65 rated.',
      ar: 'قفل ذكي بـ5 طرق فتح: بصمة، رمز، بطاقة، مفتاح وتطبيق. مقاومة IP65.',
      ru: 'Умный замок с 5 способами открытия: отпечаток, код, карта, ключ, приложение. IP65.',
      es: 'Cerradura inteligente con 5 métodos: huella, código, tarjeta, llave y app. IP65.',
      fr: 'Serrure intelligente avec 5 méthodes: empreinte, code, carte, clé et app. IP65.',
      de: 'Smartes Schloss mit 5 Methoden: Fingerabdruck, Code, Karte, Schlüssel, App. IP65.',
      pt: 'Fechadura inteligente com 5 métodos: digital, código, cartão, chave e app. IP65.',
      am: 'Smart lock with fingerprint, code, card, key and app. IP65.',
    },
    price: '₪280–450',
    tag: 'Smart Lock',
    tagColor: '#ef4444',
    search: 'Tuya fingerprint smart lock door',
    bg: 'linear-gradient(135deg,#1c0a0a 0%,#180808 100%)',
    border: '#ef4444',
    aff: 'https://www.aliexpress.com/w/wholesale-tuya-smart-lock-fingerprint.html',
  },
  {
    id: 'shelly-plus',
    icon: '💡',
    imageUrl: 'https://www.shelly.com/en/media/catalog/product/cache/c46e0d65fa10c4e40cf7f5d5c8e54a78/p/l/plus1pm.png',
    badge:    { he: '🔧 Pro', en: '🔧 Pro', ar: '🔧 Pro', ru: '🔧 Pro', es: '🔧 Pro', fr: '🔧 Pro', de: '🔧 Pro', pt: '🔧 Pro', am: '🔧 Pro' },
    badgeColor: '#fb923c',
    title: 'Shelly Plus 1PM',
    subtitle: { he: 'מפסק + מד חשמל WiFi', en: 'Switch + Energy Meter WiFi', ar: 'مفتاح + عداد طاقة WiFi', ru: 'Выключатель + счётчик WiFi', es: 'Interruptor + medidor WiFi', fr: 'Interrupteur + compteur WiFi', de: 'Schalter + Energiezähler WiFi', pt: 'Interruptor + medidor WiFi', am: 'Switch + Energy Meter WiFi' },
    desc: {
      he: 'מפסק WiFi בגודל אגוז עם מדידת צריכת חשמל בזמן אמת. מתחבר ישירות לרשת.',
      en: 'Walnut-sized WiFi switch with real-time energy monitoring. Connects directly to your network.',
      ar: 'مفتاح WiFi بحجم الجوزة مع مراقبة الطاقة في الوقت الفعلي.',
      ru: 'WiFi выключатель размером с грецкий орех с мониторингом энергопотребления.',
      es: 'Interruptor WiFi del tamaño de una nuez con monitoreo de energía en tiempo real.',
      fr: 'Interrupteur WiFi de la taille d\'une noix avec surveillance d\'énergie en temps réel.',
      de: 'WLAN-Schalter in Walnussgröße mit Echtzeit-Energieüberwachung.',
      pt: 'Interruptor WiFi do tamanho de uma noz com monitoramento de energia.',
      am: 'Walnut-sized WiFi switch with real-time energy monitoring.',
    },
    price: '₪55–80',
    tag: 'WiFi',
    tagColor: '#fb923c',
    search: 'Shelly Plus 1PM smart switch energy monitor',
    bg: 'linear-gradient(135deg,#1c1007 0%,#160e04 100%)',
    border: '#fb923c',
    aff: 'https://www.shelly.com/en/products/shop/shelly-plus-1-pm',
  },
  {
    id: 'door-sensor',
    icon: '🚪',
    imageUrl: 'https://www.aqara.com/media/media_gallery/Door_and_Window_Sensor_E1_400x400.webp',
    badge:    { he: '🔔 חיישן', en: '🔔 Sensor', ar: '🔔 حساس', ru: '🔔 Датчик', es: '🔔 Sensor', fr: '🔔 Capteur', de: '🔔 Sensor', pt: '🔔 Sensor', am: '🔔 Sensor' },
    badgeColor: '#22c55e',
    title: 'Aqara Door Sensor E1',
    subtitle: { he: 'חיישן דלת/חלון Zigbee', en: 'Zigbee Door/Window Sensor', ar: 'حساس باب/نافذة Zigbee', ru: 'Zigbee датчик двери/окна', es: 'Sensor de puerta/ventana Zigbee', fr: 'Capteur porte/fenêtre Zigbee', de: 'Zigbee Tür-/Fenstersensor', pt: 'Sensor de porta/janela Zigbee', am: 'Zigbee Door/Window Sensor' },
    desc: {
      he: 'חיישן מגנטי קטנטן ל-Zigbee — מתריע בפתיחה/סגירה, סוללה שנה, תואם Z2M.',
      en: 'Tiny magnetic Zigbee sensor — alerts on open/close events, 1-year battery, Z2M compatible.',
      ar: 'حساس مغناطيسي Zigbee صغير — ينبه عند الفتح/الإغلاق، بطارية سنة.',
      ru: 'Крошечный магнитный Zigbee датчик — оповещает при открытии/закрытии, батарея 1 год.',
      es: 'Pequeño sensor magnético Zigbee — alertas de apertura/cierre, batería 1 año.',
      fr: 'Petit capteur magnétique Zigbee — alertes ouverture/fermeture, batterie 1 an.',
      de: 'Kleiner magnetischer Zigbee-Sensor — Benachrichtigungen bei Öffnen/Schließen, 1 Jahr Batterie.',
      pt: 'Pequeno sensor magnético Zigbee — alertas de abertura/fechamento, bateria 1 ano.',
      am: 'Tiny Zigbee magnetic sensor, 1-year battery.',
    },
    price: '₪35–55',
    tag: 'Zigbee',
    tagColor: '#22c55e',
    search: 'Aqara door window sensor E1 Zigbee',
    bg: 'linear-gradient(135deg,#0c1f0c 0%,#081508 100%)',
    border: '#22c55e',
    aff: 'https://www.aqara.com/en/product/door-and-window-sensor-e1',
  },
  {
    id: 'bulb-rgb',
    icon: '🎨',
    imageUrl: 'https://www.moes-smarthome.com/wp-content/uploads/2021/11/QA67.jpg',
    badge:    { he: '🌈 RGB', en: '🌈 RGB', ar: '🌈 RGB', ru: '🌈 RGB', es: '🌈 RGB', fr: '🌈 RGB', de: '🌈 RGB', pt: '🌈 RGB', am: '🌈 RGB' },
    badgeColor: '#ec4899',
    title: 'Moes Zigbee Bulb RGBCW',
    subtitle: { he: 'נורה חכמה 10W צבעונית', en: 'Smart 10W Color Bulb', ar: 'لمبة ذكية 10W ملونة', ru: 'Умная цветная лампа 10W', es: 'Bombilla inteligente 10W color', fr: 'Ampoule intelligente 10W couleur', de: 'Smarte Farblampe 10W', pt: 'Lâmpada inteligente 10W colorida', am: 'Smart 10W Color Bulb' },
    desc: {
      he: 'נורה Zigbee 10W עם 16M צבעים + טמפ\' צבע + עמעום. תואמת Fantatech Hub.',
      en: '10W Zigbee bulb with 16M colors + color temperature + dimming. Compatible with Fantatech Hub.',
      ar: 'لمبة Zigbee 10W مع 16M لون + درجة حرارة لون + تعتيم. متوافقة مع Fantatech Hub.',
      ru: 'Zigbee лампа 10W с 16M цветов + цветовая температура + диммирование.',
      es: 'Bombilla Zigbee 10W con 16M colores + temperatura de color + atenuación.',
      fr: 'Ampoule Zigbee 10W avec 16M couleurs + température de couleur + variation.',
      de: 'Zigbee Lampe 10W mit 16M Farben + Farbtemperatur + Dimmen.',
      pt: 'Lâmpada Zigbee 10W com 16M cores + temperatura de cor + regulação.',
      am: 'Zigbee 10W bulb with 16M colors and dimming.',
    },
    price: '₪30–55',
    tag: 'Zigbee',
    tagColor: '#ec4899',
    search: 'Moes Zigbee RGBCW smart bulb E27',
    bg: 'linear-gradient(135deg,#1c0a1c 0%,#150815 100%)',
    border: '#ec4899',
    aff: 'https://www.aliexpress.com/w/wholesale-moes-zigbee-bulb-rgbcw.html',
  },
  {
    id: 'smoke-detector',
    icon: '🔥',
    imageUrl: 'https://ae01.alicdn.com/kf/Sc6e8ce65e5234fca9a9f7a3c50c90e2bN.jpg',
    badge:    { he: '🆘 בטיחות', en: '🆘 Safety', ar: '🆘 سلامة', ru: '🆘 Безопасность', es: '🆘 Seguridad', fr: '🆘 Sécurité', de: '🆘 Sicherheit', pt: '🆘 Segurança', am: '🆘 Safety' },
    badgeColor: '#ef4444',
    title: 'Zigbee Smoke Detector',
    subtitle: { he: 'גלאי עשן חכם Zigbee', en: 'Smart Zigbee Smoke Detector', ar: 'كاشف دخان ذكي Zigbee', ru: 'Умный Zigbee дымовой детектор', es: 'Detector de humo Zigbee inteligente', fr: 'Détecteur de fumée Zigbee intelligent', de: 'Smarter Zigbee Rauchmelder', pt: 'Detector de fumaça Zigbee inteligente', am: 'Smart Zigbee Smoke Detector' },
    desc: {
      he: 'גלאי עשן אלקטרוכימי עם התראה קולית 85dB + שליחת התראה לאפליקציה בזמן אמת.',
      en: 'Electrochemical smoke detector with 85dB alarm + real-time push notification to the app.',
      ar: 'كاشف دخان كيميائي مع إنذار 85dB + إشعار فوري للتطبيق.',
      ru: 'Электрохимический детектор дыма с сигналом 85дБ + push-уведомления.',
      es: 'Detector electroquímico con alarma 85dB + notificación push en tiempo real.',
      fr: 'Détecteur électrochimique avec alarme 85dB + notification push en temps réel.',
      de: 'Elektrochemischer Rauchmelder mit 85dB Alarm + Echtzeit-Push-Benachrichtigung.',
      pt: 'Detector eletroquímico com alarme 85dB + notificação push em tempo real.',
      am: 'Smoke detector with 85dB alarm and push notifications.',
    },
    price: '₪45–80',
    tag: 'Safety',
    tagColor: '#ef4444',
    search: 'Zigbee smoke detector sensor smart home',
    bg: 'linear-gradient(135deg,#1c0a00 0%,#180800 100%)',
    border: '#ef4444',
    aff: 'https://www.aliexpress.com/w/wholesale-zigbee-smoke-detector.html',
  },
]

/* ── URL builder ──────────────────────────────────────────────────────────── */
function buildUrl(promo) {
  if (promo.aff) return promo.aff
  return `https://www.amazon.com/s?k=${encodeURIComponent(promo.search)}&tag=fantatech-20`
}

/* ── Get localised string from multilingual field ─────────────────────────── */
function loc(field, lang) {
  if (!field) return ''
  if (typeof field === 'string') return field
  // Priority: current lang → English → Hebrew → first available
  return field[lang] || field.en || field.he
    || Object.values(field).find(v => v) || ''
}

/* ── Product image with emoji fallback ───────────────────────────────────── */
function ProductImage({ src, icon, size = 70, radius = 12 }) {
  const [err, setErr] = useState(false)
  return (
    <div style={{
      width: size, height: size, borderRadius: radius,
      background: '#0f172a', flexShrink: 0,
      overflow: 'hidden', display: 'flex',
      alignItems: 'center', justifyContent: 'center',
    }}>
      {err || !src
        ? <span style={{ fontSize: size * 0.5 }}>{icon}</span>
        : <img src={src} alt="" onError={() => setErr(true)}
            style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
      }
    </div>
  )
}

/* ── Main component ─────────────────────────────────────────────────────── */
export default function PromoCarousel() {
  const { t, lang } = useLang()
  const [active, setActive] = useState(0)
  const [dismissed, setDismissed] = useState(
    () => localStorage.getItem('promo_dismissed') === '1'
  )
  const [expanded, setExpanded] = useState(false)
  const scrollRef = useRef(null)
  const autoRef   = useRef(null)

  useEffect(() => {
    if (dismissed) return
    autoRef.current = setInterval(() => {
      setActive(p => (p + 1) % PROMOS.length)
    }, 5000)
    return () => clearInterval(autoRef.current)
  }, [dismissed])

  useEffect(() => {
    if (!scrollRef.current) return
    const card = scrollRef.current.children[active]
    if (card) card.scrollIntoView({ behavior: 'smooth', inline: 'center', block: 'nearest' })
  }, [active])

  const dismiss = () => { setDismissed(true); localStorage.setItem('promo_dismissed', '1') }
  const restore = () => { setDismissed(false); localStorage.removeItem('promo_dismissed') }

  if (dismissed) {
    return (
      <div style={{ textAlign: 'center', marginBottom: 16 }}>
        <button onClick={restore} style={{
          background: 'none', border: '1px solid #334155', borderRadius: 8,
          color: '#475569', fontSize: 11, cursor: 'pointer', padding: '4px 12px',
        }}>
          {t.show_recommendations}
        </button>
      </div>
    )
  }

  const p = PROMOS[active]

  return (
    <div style={{ marginBottom: 24 }}>
      {/* Section title */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <h3 style={{ margin: 0, fontSize: 14, color: '#e2e8f0' }}>{t.recommended_products}</h3>
        <div style={{ display: 'flex', gap: 6 }}>
          <button onClick={() => setExpanded(!expanded)} style={{
            background: 'none', border: '1px solid #334155', borderRadius: 6,
            color: '#64748b', fontSize: 11, cursor: 'pointer', padding: '3px 8px',
          }}>
            {expanded ? t.show_less : t.show_all}
          </button>
          <button onClick={dismiss} style={{
            background: 'none', border: 'none', color: '#334155',
            fontSize: 16, cursor: 'pointer', lineHeight: 1, padding: '0 2px',
          }} title={t.close}>✕</button>
        </div>
      </div>

      {/* ── Carousel (default view) ── */}
      {!expanded && (
        <>
          <a href={buildUrl(p)} target="_blank" rel="noreferrer"
            style={{ textDecoration: 'none', display: 'block' }}>
            <div style={{
              background: p.bg, border: `1px solid ${p.border}`,
              borderRadius: 16, padding: '14px 16px', marginBottom: 10,
              position: 'relative', overflow: 'hidden', transition: 'all 0.4s',
            }}>
              <div style={{ position: 'absolute', top: -30, right: -30,
                width: 100, height: 100, borderRadius: '50%',
                background: p.border + '22', filter: 'blur(20px)', pointerEvents: 'none',
              }} />
              <span style={{
                position: 'absolute', top: 10, left: 10,
                fontSize: 10, fontWeight: 700, padding: '2px 8px',
                borderRadius: 20, background: p.badgeColor + '33',
                border: `1px solid ${p.badgeColor}`, color: p.badgeColor,
              }}>{loc(p.badge, lang)}</span>

              <div style={{ display: 'flex', gap: 14, alignItems: 'flex-start' }}>
                <ProductImage src={p.imageUrl} icon={p.icon} size={80} radius={12} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontWeight: 700, fontSize: 14, color: '#f1f5f9', marginBottom: 2 }}>{p.title}</div>
                  <div style={{ fontSize: 11, color: p.border, marginBottom: 6, fontWeight: 600 }}>{loc(p.subtitle, lang)}</div>
                  <div style={{ fontSize: 11, color: '#94a3b8', lineHeight: 1.6, marginBottom: 10 }}>{loc(p.desc, lang)}</div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{
                      fontSize: 10, fontWeight: 700, padding: '2px 8px', borderRadius: 20,
                      background: p.tagColor + '22', border: `1px solid ${p.tagColor}`, color: p.tagColor,
                    }}>{p.tag}</span>
                    <span style={{ fontSize: 13, fontWeight: 800, color: '#22c55e' }}>{p.price}</span>
                    <span style={{
                      marginInlineStart: 'auto', padding: '5px 14px', borderRadius: 8,
                      background: p.border, color: '#fff', fontWeight: 700, fontSize: 12, flexShrink: 0,
                    }}>{t.buy_now}</span>
                  </div>
                </div>
              </div>
            </div>
          </a>

          {/* Thumbnail strip */}
          <div ref={scrollRef} style={{
            display: 'flex', gap: 6, overflowX: 'auto', paddingBottom: 4, scrollbarWidth: 'none',
          }}>
            {PROMOS.map((item, i) => (
              <button key={item.id} onClick={() => { clearInterval(autoRef.current); setActive(i) }} style={{
                flexShrink: 0, width: 52, height: 52, borderRadius: 12, padding: 0,
                border: `2px solid ${i === active ? item.border : '#334155'}`,
                background: '#0f172a', cursor: 'pointer', overflow: 'hidden',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                transition: 'all .2s',
              }}>
                <ProductImage src={item.imageUrl} icon={item.icon} size={50} radius={10} />
              </button>
            ))}
          </div>
        </>
      )}

      {/* ── Expanded grid ── */}
      {expanded && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          {PROMOS.map((item) => (
            <a key={item.id} href={buildUrl(item)} target="_blank" rel="noreferrer"
              style={{
                background: item.bg, border: `1px solid ${item.border}`,
                borderRadius: 14, padding: 12, textDecoration: 'none',
                display: 'flex', flexDirection: 'column', gap: 6,
              }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <ProductImage src={item.imageUrl} icon={item.icon} size={44} radius={8} />
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: '#f1f5f9', lineHeight: 1.3 }}>{item.title}</div>
                  <div style={{ fontSize: 10, color: item.border }}>{loc(item.subtitle, lang)}</div>
                </div>
              </div>
              <div style={{ fontSize: 10, color: '#64748b', lineHeight: 1.5 }}>{loc(item.desc, lang)}</div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 2 }}>
                <span style={{ fontSize: 12, fontWeight: 700, color: '#22c55e' }}>{item.price}</span>
                <span style={{
                  fontSize: 9, fontWeight: 700, padding: '2px 6px', borderRadius: 20,
                  background: item.tagColor + '22', border: `1px solid ${item.tagColor}`, color: item.tagColor,
                }}>{item.tag}</span>
              </div>
            </a>
          ))}
        </div>
      )}
    </div>
  )
}
