import React, { useState } from "react";
import {
  View, Text, StyleSheet, TouchableOpacity, ScrollView,
  TextInput, Switch, SafeAreaView, StatusBar,
} from "react-native";
import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { MqttProvider, useMqtt } from "./context/MqttContext";

const Tab = createBottomTabNavigator();

/* ─── Design tokens (exact from mockup) ─────────────────────── */
const C = {
  bg:       "#0D1117",
  card:     "#161B27",
  card2:    "#1E2535",
  blue:     "#2563EB",
  blueGlow: "#3B82F6",
  green:    "#22C55E",
  red:      "#EF4444",
  orange:   "#F97316",
  text:     "#F5F5F7",
  sub:      "#8892A4",
  border:   "#2A3044",
  navBg:    "#111827",
};

/* ─── Reusable atoms ────────────────────────────────────────── */
function Header({ title, showBell = true, onBell }) {
  return (
    <View style={hdr.wrap}>
      <Text style={hdr.logo}>Fanta<Text style={{ color: C.blue }}>Tech</Text></Text>
      {title ? <Text style={hdr.title}>{title}</Text> : null}
      {showBell && (
        <TouchableOpacity onPress={onBell} style={hdr.bell}>
          <Text style={{ fontSize: 20 }}>🔔</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}
const hdr = StyleSheet.create({
  wrap:  { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 20, paddingVertical: 14 },
  logo:  { fontSize: 22, fontWeight: "800", color: C.text },
  title: { fontSize: 18, fontWeight: "700", color: C.text },
  bell:  { width: 38, height: 38, borderRadius: 19, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" },
});

function Card({ children, style }) {
  return <View style={[{ backgroundColor: C.card, borderRadius: 18, padding: 16, borderWidth: 1, borderColor: C.border }, style]}>{children}</View>;
}

function Divider() {
  return <View style={{ height: 1, backgroundColor: C.border, marginVertical: 8 }} />;
}

/* ══════════════════════════════════════════════════════════════
   1. LOGIN SCREEN
══════════════════════════════════════════════════════════════ */
function LoginScreen({ onLogin }) {
  const [email, setEmail]       = useState("");
  const [password, setPassword] = useState("");

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <ScrollView contentContainerStyle={login.scroll} keyboardShouldPersistTaps="handled">

        {/* Logo */}
        <View style={login.logoWrap}>
          <View style={login.logoCircle}>
            <Text style={{ fontSize: 36 }}>🏠</Text>
          </View>
          <Text style={login.brand}>Fanta<Text style={{ color: C.blue }}>Tech</Text></Text>
          <Text style={login.tagline}>Smart Living & Security</Text>
        </View>

        {/* Greeting */}
        <Text style={login.greeting}>שלום! 👋</Text>
        <Text style={login.sub}>התחבר לבית החכם שלך</Text>

        {/* Fields */}
        <View style={login.fieldWrap}>
          <TextInput
            style={login.input}
            placeholder="אימייל"
            placeholderTextColor={C.sub}
            value={email}
            onChangeText={setEmail}
            keyboardType="email-address"
            autoCapitalize="none"
            textAlign="right"
          />
          <TextInput
            style={login.input}
            placeholder="סיסמה"
            placeholderTextColor={C.sub}
            value={password}
            onChangeText={setPassword}
            secureTextEntry
            textAlign="right"
          />
        </View>

        {/* Connect */}
        <TouchableOpacity style={login.btn} onPress={onLogin}>
          <Text style={login.btnText}>התחבר</Text>
        </TouchableOpacity>

        {/* Divider */}
        <View style={login.orRow}>
          <View style={{ flex: 1, height: 1, backgroundColor: C.border }} />
          <Text style={{ color: C.sub, marginHorizontal: 12 }}>או</Text>
          <View style={{ flex: 1, height: 1, backgroundColor: C.border }} />
        </View>

        {/* Google */}
        <TouchableOpacity style={login.googleBtn} onPress={onLogin}>
          <Text style={{ fontSize: 18, marginRight: 8 }}>G</Text>
          <Text style={{ color: C.text, fontWeight: "600" }}>המשך עם Google</Text>
        </TouchableOpacity>

      </ScrollView>
    </SafeAreaView>
  );
}
const login = StyleSheet.create({
  scroll:     { flexGrow: 1, backgroundColor: C.bg, alignItems: "center", justifyContent: "center", padding: 28 },
  logoWrap:   { alignItems: "center", marginBottom: 32 },
  logoCircle: { width: 80, height: 80, borderRadius: 40, backgroundColor: C.card2, alignItems: "center", justifyContent: "center", marginBottom: 12, borderWidth: 2, borderColor: C.blue },
  brand:      { fontSize: 34, fontWeight: "900", color: C.text, letterSpacing: 1 },
  tagline:    { color: C.sub, fontSize: 13, marginTop: 4 },
  greeting:   { fontSize: 26, fontWeight: "800", color: C.text, alignSelf: "flex-end", marginBottom: 4 },
  sub:        { color: C.sub, fontSize: 14, alignSelf: "flex-end", marginBottom: 28 },
  fieldWrap:  { width: "100%", gap: 12, marginBottom: 20 },
  input:      { backgroundColor: C.card2, borderRadius: 14, padding: 16, color: C.text, fontSize: 15, borderWidth: 1, borderColor: C.border },
  btn:        { width: "100%", backgroundColor: C.blue, borderRadius: 14, padding: 16, alignItems: "center", marginBottom: 20 },
  btnText:    { color: "#fff", fontWeight: "700", fontSize: 17 },
  orRow:      { flexDirection: "row", alignItems: "center", width: "100%", marginBottom: 20 },
  googleBtn:  { flexDirection: "row", alignItems: "center", justifyContent: "center", backgroundColor: C.card2, borderRadius: 14, padding: 14, width: "100%", borderWidth: 1, borderColor: C.border },
});

/* ══════════════════════════════════════════════════════════════
   2. DASHBOARD — בית
══════════════════════════════════════════════════════════════ */
function Dashboard() {
  const { alarmActive, lights, cameras, turnAllOff } = useMqtt();
  const [nightMode, setNightMode] = useState(false);

  const allLightsOff = Object.values(lights).every(v => v === "OFF");

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <Header />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 24 }} showsVerticalScrollIndicator={false}>

        {/* Greeting */}
        <Text style={db.greeting}>שלום יוסי 👋</Text>
        <Text style={db.greetSub}>הבית שלך תחת שליטה</Text>

        {/* Status hero card */}
        <Card style={[db.heroCard, { borderColor: alarmActive ? C.red : C.green }]}>
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
            <View style={{ flex: 1 }}>
              <Text style={db.heroTitle}>{alarmActive ? "⚠️ אזעקה פעילה" : "✅ הבית מוגן"}</Text>
              <Text style={db.heroSub}>כל המערכות פועלות תקין</Text>
              <View style={{ flexDirection: "row", gap: 8, marginTop: 12 }}>
                <View style={[db.badge, { backgroundColor: alarmActive ? "#3b0a0a" : "#0a2e1a" }]}>
                  <Text style={[db.badgeText, { color: alarmActive ? C.red : C.green }]}>📷 מצלמות</Text>
                </View>
                <View style={[db.badge, { backgroundColor: "#0a2e1a" }]}>
                  <Text style={[db.badgeText, { color: C.green }]}>🔒 מוגן</Text>
                </View>
              </View>
            </View>
            <View style={[db.shieldWrap, { borderColor: alarmActive ? C.red : C.green }]}>
              <Text style={{ fontSize: 40 }}>{alarmActive ? "🚨" : "🛡️"}</Text>
            </View>
          </View>
        </Card>

        {/* Quick grid */}
        <View style={db.grid}>
          {[
            { icon: "📷", label: "מצלמות",    sub: "2 מחוברות",   color: C.blue   },
            { icon: "⚡", label: "אנרגיה",     sub: "245 kWh",     color: C.orange },
            { icon: "🤖", label: "אוטומציות",  sub: "4 פעילות",   color: C.blueGlow },
            { icon: "🔔", label: "התראות",     sub: "2 חדשות",    color: C.red    },
          ].map((item) => (
            <TouchableOpacity key={item.label} style={db.gridItem}>
              <View style={[db.gridIcon, { backgroundColor: item.color + "22" }]}>
                <Text style={{ fontSize: 24 }}>{item.icon}</Text>
              </View>
              <Text style={db.gridLabel}>{item.label}</Text>
              <Text style={db.gridSub}>{item.sub}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Climate card */}
        <Card style={{ marginBottom: 14 }}>
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
            <View>
              <Text style={{ color: C.sub, fontSize: 12, marginBottom: 4 }}>אקלים — חדר שינה</Text>
              <Text style={{ color: C.text, fontSize: 32, fontWeight: "800" }}>24°<Text style={{ fontSize: 18 }}>C</Text></Text>
              <Text style={{ color: C.sub, fontSize: 12, marginTop: 2 }}>⏱ עוד 8 שעות</Text>
            </View>
            <View style={{ alignItems: "flex-end", gap: 8 }}>
              <View style={[db.badge, { backgroundColor: "#1e3a5f" }]}>
                <Text style={{ color: C.blueGlow, fontSize: 12 }}>🌡 מזגן פעיל</Text>
              </View>
              <Text style={{ color: C.blue, fontSize: 22 }}>❄️</Text>
            </View>
          </View>
        </Card>

        {/* Quick actions */}
        <Card style={{ marginBottom: 14 }}>
          <Text style={db.sectionTitle}>פעולות מהירות</Text>
          <View style={{ flexDirection: "row", justifyContent: "space-between", marginTop: 12 }}>
            <TouchableOpacity style={db.action} onPress={turnAllOff}>
              <Text style={{ fontSize: 22 }}>💡</Text>
              <Text style={db.actionLabel}>כיבוי מהיר</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[db.action, nightMode && { borderColor: C.blue }]} onPress={() => setNightMode(v => !v)}>
              <Text style={{ fontSize: 22 }}>🌙</Text>
              <Text style={db.actionLabel}>מצב לילה</Text>
            </TouchableOpacity>
            <TouchableOpacity style={db.action}>
              <Text style={{ fontSize: 22 }}>🚪</Text>
              <Text style={db.actionLabel}>דלת כניסה</Text>
            </TouchableOpacity>
            <TouchableOpacity style={db.action}>
              <Text style={{ fontSize: 22 }}>🪟</Text>
              <Text style={db.actionLabel}>תריסים</Text>
            </TouchableOpacity>
          </View>
        </Card>

        {/* Fanta AI card */}
        <Card style={{ borderColor: C.blue + "55", backgroundColor: "#0d1b3e" }}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <View style={db.aiOrb}>
              <Text style={{ fontSize: 28 }}>🤖</Text>
            </View>
            <View style={{ flex: 1 }}>
              <Text style={{ color: C.blue, fontWeight: "700", fontSize: 15 }}>Fanta AI</Text>
              <Text style={{ color: C.sub, fontSize: 13, marginTop: 2 }}>אני כאן לעזור לך!</Text>
            </View>
            <View style={[db.badge, { backgroundColor: C.blue }]}>
              <Text style={{ color: "#fff", fontSize: 11, fontWeight: "600" }}>שאל אותי</Text>
            </View>
          </View>
        </Card>

      </ScrollView>
    </SafeAreaView>
  );
}
const db = StyleSheet.create({
  greeting:   { fontSize: 24, fontWeight: "800", color: C.text, textAlign: "right", marginBottom: 2 },
  greetSub:   { color: C.sub, fontSize: 13, textAlign: "right", marginBottom: 16 },
  heroCard:   { marginBottom: 14, borderWidth: 1.5 },
  heroTitle:  { color: C.text, fontSize: 20, fontWeight: "800", textAlign: "right" },
  heroSub:    { color: C.sub,  fontSize: 13, textAlign: "right", marginTop: 4 },
  shieldWrap: { width: 72, height: 72, borderRadius: 36, borderWidth: 2, alignItems: "center", justifyContent: "center", backgroundColor: C.card2 },
  badge:      { paddingHorizontal: 10, paddingVertical: 5, borderRadius: 20 },
  badgeText:  { fontSize: 12, fontWeight: "600" },
  grid:       { flexDirection: "row", flexWrap: "wrap", gap: 10, marginBottom: 14 },
  gridItem:   { flex: 1, minWidth: "44%", backgroundColor: C.card, borderRadius: 16, padding: 14, borderWidth: 1, borderColor: C.border },
  gridIcon:   { width: 44, height: 44, borderRadius: 12, alignItems: "center", justifyContent: "center", marginBottom: 8 },
  gridLabel:  { color: C.text, fontWeight: "700", fontSize: 14, textAlign: "right" },
  gridSub:    { color: C.sub,  fontSize: 11, textAlign: "right", marginTop: 2 },
  sectionTitle: { color: C.text, fontWeight: "700", fontSize: 15, textAlign: "right" },
  action:     { alignItems: "center", gap: 6, backgroundColor: C.card2, borderRadius: 14, padding: 12, flex: 1, marginHorizontal: 3, borderWidth: 1, borderColor: C.border },
  actionLabel:{ color: C.sub, fontSize: 10, textAlign: "center" },
  aiOrb:      { width: 52, height: 52, borderRadius: 26, backgroundColor: "#1a2f5e", borderWidth: 2, borderColor: C.blue, alignItems: "center", justifyContent: "center" },
});

/* ══════════════════════════════════════════════════════════════
   3. AI — עוזר AI
══════════════════════════════════════════════════════════════ */
function AIScreen() {
  const [messages, setMessages] = useState([
    { from: "ai",   text: "היי! 👋 אני Fanta AI, העוזר החכם של הבית שלך." },
    { from: "ai",   text: "אני יכול לכבות את כל האורות, לנעול את הדלת, ועוד. איך אפשר לעזור?" },
  ]);
  const [input, setInput] = useState("");

  function send() {
    if (!input.trim()) return;
    const userMsg = input.trim();
    setMessages(prev => [...prev, { from: "user", text: userMsg }]);
    setInput("");
    setTimeout(() => {
      setMessages(prev => [...prev, { from: "ai", text: "בסדר, מבצע את הפעולה... ✅" }]);
    }, 800);
  }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <Header title="עוזר AI" showBell={false} />

      {/* Orb */}
      <View style={ai.orbSection}>
        <View style={ai.orbOuter}>
          <View style={ai.orbInner}>
            <Text style={{ fontSize: 44 }}>🤖</Text>
          </View>
        </View>
        <Text style={ai.orbTitle}>Fanta AI</Text>
        <Text style={ai.orbSub}>עוזר אישי חכם לבית שלך</Text>
      </View>

      {/* Chat */}
      <ScrollView style={{ flex: 1, paddingHorizontal: 16 }} contentContainerStyle={{ gap: 10, paddingBottom: 8 }}>
        {messages.map((m, i) => (
          <View key={i} style={[ai.bubble, m.from === "user" ? ai.bubbleUser : ai.bubbleAI]}>
            <Text style={[ai.bubbleText, m.from === "user" && { color: "#fff" }]}>{m.text}</Text>
          </View>
        ))}
      </ScrollView>

      {/* Quick prompts */}
      <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={ai.promptsRow}>
        {["כבה את כל האורות", "נעל את הדלת", "מה הטמפרטורה?", "הפעל מצב לילה"].map(p => (
          <TouchableOpacity key={p} style={ai.promptChip} onPress={() => setInput(p)}>
            <Text style={{ color: C.blue, fontSize: 12, fontWeight: "600" }}>{p}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Input */}
      <View style={ai.inputRow}>
        <TouchableOpacity style={ai.micBtn}>
          <Text style={{ fontSize: 20 }}>🎤</Text>
        </TouchableOpacity>
        <TextInput
          style={ai.input}
          placeholder="שאל אותי משהו..."
          placeholderTextColor={C.sub}
          value={input}
          onChangeText={setInput}
          onSubmitEditing={send}
          textAlign="right"
        />
        <TouchableOpacity style={ai.sendBtn} onPress={send}>
          <Text style={{ fontSize: 18, color: "#fff" }}>➤</Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
}
const ai = StyleSheet.create({
  orbSection: { alignItems: "center", paddingVertical: 20 },
  orbOuter:   { width: 110, height: 110, borderRadius: 55, borderWidth: 2, borderColor: C.blue + "55", alignItems: "center", justifyContent: "center", backgroundColor: "#0d1b3e" },
  orbInner:   { width: 86, height: 86, borderRadius: 43, backgroundColor: "#1a2f5e", borderWidth: 2, borderColor: C.blue, alignItems: "center", justifyContent: "center" },
  orbTitle:   { color: C.text, fontWeight: "800", fontSize: 20, marginTop: 10 },
  orbSub:     { color: C.sub, fontSize: 13, marginTop: 4 },
  bubble:     { maxWidth: "80%", borderRadius: 16, padding: 12 },
  bubbleAI:   { backgroundColor: C.card2, alignSelf: "flex-start", borderBottomLeftRadius: 4 },
  bubbleUser: { backgroundColor: C.blue, alignSelf: "flex-end", borderBottomRightRadius: 4 },
  bubbleText: { color: C.text, fontSize: 14, lineHeight: 20 },
  promptsRow: { paddingHorizontal: 16, gap: 8, paddingBottom: 8 },
  promptChip: { backgroundColor: "#0d1b3e", borderRadius: 20, paddingHorizontal: 14, paddingVertical: 8, borderWidth: 1, borderColor: C.blue + "55" },
  inputRow:   { flexDirection: "row", alignItems: "center", padding: 12, gap: 8, backgroundColor: C.card, borderTopWidth: 1, borderTopColor: C.border },
  micBtn:     { width: 42, height: 42, borderRadius: 21, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" },
  input:      { flex: 1, backgroundColor: C.card2, borderRadius: 22, paddingHorizontal: 16, paddingVertical: 10, color: C.text, fontSize: 14, borderWidth: 1, borderColor: C.border },
  sendBtn:    { width: 42, height: 42, borderRadius: 21, backgroundColor: C.blue, alignItems: "center", justifyContent: "center" },
});

/* ══════════════════════════════════════════════════════════════
   4. SECURITY — אבטחה
══════════════════════════════════════════════════════════════ */
function SecurityScreen() {
  const { alarmActive, locks, triggerAlarm, disarmAlarm, toggleLock } = useMqtt();

  const sensors = [
    { icon: "🚪", label: "דלת כניסה",    state: locks.entrance === "LOCK" ? "נעולה" : "פתוחה", ok: locks.entrance === "LOCK" },
    { icon: "🪟", label: "חלונות",        state: "נעולים",  ok: true  },
    { icon: "👁",  label: "חיישן תנועה",  state: "תקין",    ok: true  },
    { icon: "💨", label: "גלאי עשן",      state: "תקין",    ok: true  },
  ];

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <Header title="אבטחה" />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 28 }}>

        {/* Shield status */}
        <View style={sec.heroWrap}>
          <View style={[sec.shield, { borderColor: alarmActive ? C.red : C.green }]}>
            <Text style={{ fontSize: 52 }}>{alarmActive ? "🚨" : "🛡️"}</Text>
          </View>
          <Text style={[sec.heroTitle, { color: alarmActive ? C.red : C.green }]}>
            {alarmActive ? "אזעקה פעילה!" : "הבית מוגן"}
          </Text>
          <Text style={sec.heroSub}>
            {alarmActive ? "מערכת האזעקה פעילה" : "כל המערכות פועלות תקין"}
          </Text>
        </View>

        {/* Sensors */}
        <Card style={{ marginBottom: 14 }}>
          <Text style={[db.sectionTitle, { marginBottom: 12 }]}>סטטוס מערכות</Text>
          {sensors.map((s, i) => (
            <View key={i}>
              <TouchableOpacity
                style={sec.sensorRow}
                onPress={s.label === "דלת כניסה" ? () => toggleLock("entrance") : undefined}
              >
                <View style={[sec.sensorDot, { backgroundColor: s.ok ? C.green : C.red }]} />
                <Text style={sec.sensorState}>{s.state}</Text>
                <View style={{ flex: 1 }} />
                <Text style={sec.sensorIcon}>{s.icon}</Text>
                <Text style={sec.sensorLabel}>{s.label}</Text>
              </TouchableOpacity>
              {i < sensors.length - 1 && <Divider />}
            </View>
          ))}
        </Card>

        {/* Arm / Disarm */}
        <TouchableOpacity
          style={[sec.armBtn, { backgroundColor: alarmActive ? C.card2 : C.green + "22", borderColor: alarmActive ? C.border : C.green }]}
          onPress={alarmActive ? disarmAlarm : undefined}
        >
          <Text style={{ color: alarmActive ? C.sub : C.green, fontWeight: "700", fontSize: 15 }}>
            {alarmActive ? "בטל אזעקה" : "✅ המערכת מופעלת"}
          </Text>
        </TouchableOpacity>

        {/* PANIC */}
        <TouchableOpacity style={sec.panicBtn} onPress={alarmActive ? disarmAlarm : triggerAlarm}>
          <Text style={sec.panicIcon}>🆘</Text>
          <Text style={sec.panicText}>PANIC</Text>
          <Text style={sec.panicSub}>לחץ לסיוע חירום</Text>
        </TouchableOpacity>

      </ScrollView>
    </SafeAreaView>
  );
}
const sec = StyleSheet.create({
  heroWrap:   { alignItems: "center", paddingVertical: 24 },
  shield:     { width: 110, height: 110, borderRadius: 55, borderWidth: 2.5, backgroundColor: C.card2, alignItems: "center", justifyContent: "center", marginBottom: 14 },
  heroTitle:  { fontSize: 24, fontWeight: "800", marginBottom: 4 },
  heroSub:    { color: C.sub, fontSize: 13 },
  sensorRow:  { flexDirection: "row", alignItems: "center", paddingVertical: 10, gap: 10 },
  sensorDot:  { width: 10, height: 10, borderRadius: 5 },
  sensorLabel:{ color: C.text, fontSize: 15, fontWeight: "600" },
  sensorState:{ color: C.sub, fontSize: 13 },
  sensorIcon: { fontSize: 20, marginRight: 8 },
  armBtn:     { borderRadius: 16, padding: 16, alignItems: "center", marginBottom: 12, borderWidth: 1 },
  panicBtn:   { backgroundColor: "#2a0a0a", borderRadius: 18, padding: 20, alignItems: "center", borderWidth: 2, borderColor: C.red },
  panicIcon:  { fontSize: 36, marginBottom: 4 },
  panicText:  { color: C.red, fontSize: 22, fontWeight: "900", letterSpacing: 3 },
  panicSub:   { color: C.sub, fontSize: 12, marginTop: 4 },
});

/* ══════════════════════════════════════════════════════════════
   5. PROFILE — פרופיל
══════════════════════════════════════════════════════════════ */
function ProfileScreen({ onLogout }) {
  const menuItems = [
    { icon: "⚙️",  label: "הגדרות" },
    { icon: "🔐", label: "אבטחה ופרטיות" },
    { icon: "📱", label: "מכשירים מחוברים" },
    { icon: "⚡", label: "אנרגיה וצריכה" },
    { icon: "🔔", label: "התראות" },
    { icon: "❓", label: "מידע ותמיכה" },
  ];

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <Header title="פרופיל" showBell={false} />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 28 }}>

        {/* Avatar */}
        <View style={prof.avatarSection}>
          <View style={prof.avatar}>
            <Text style={{ fontSize: 38, color: "#fff", fontWeight: "800" }}>י</Text>
          </View>
          <Text style={prof.name}>יוסי פקאדו</Text>
          <Text style={prof.email}>yossi.fkadu@gmail.com</Text>
          <View style={[db.badge, { backgroundColor: C.blue + "33", marginTop: 8 }]}>
            <Text style={{ color: C.blue, fontWeight: "700", fontSize: 12 }}>⭐ Premium</Text>
          </View>
        </View>

        {/* Stats row */}
        <View style={{ flexDirection: "row", gap: 10, marginBottom: 16 }}>
          {[{ value: "12", label: "מכשירים" }, { value: "4", label: "אוטומציות" }, { value: "3", label: "חדרים" }].map(s => (
            <Card key={s.label} style={{ flex: 1, alignItems: "center" }}>
              <Text style={{ color: C.text, fontSize: 22, fontWeight: "800" }}>{s.value}</Text>
              <Text style={{ color: C.sub, fontSize: 11, marginTop: 2 }}>{s.label}</Text>
            </Card>
          ))}
        </View>

        {/* Menu */}
        <Card style={{ marginBottom: 14 }}>
          {menuItems.map((item, i) => (
            <View key={item.label}>
              <TouchableOpacity style={prof.menuRow}>
                <Text style={{ color: C.sub, fontSize: 18 }}>‹</Text>
                <View style={{ flex: 1 }} />
                <Text style={prof.menuLabel}>{item.label}</Text>
                <Text style={{ fontSize: 18, marginRight: 10 }}>{item.icon}</Text>
              </TouchableOpacity>
              {i < menuItems.length - 1 && <Divider />}
            </View>
          ))}
        </Card>

        {/* Logout */}
        <TouchableOpacity style={prof.logoutBtn} onPress={onLogout}>
          <Text style={prof.logoutText}>יציאה מהחשבון</Text>
        </TouchableOpacity>

      </ScrollView>
    </SafeAreaView>
  );
}
const prof = StyleSheet.create({
  avatarSection: { alignItems: "center", paddingVertical: 24 },
  avatar:        { width: 88, height: 88, borderRadius: 44, backgroundColor: C.blue, alignItems: "center", justifyContent: "center", marginBottom: 12, borderWidth: 3, borderColor: C.blueGlow },
  name:          { color: C.text, fontSize: 22, fontWeight: "800" },
  email:         { color: C.sub, fontSize: 13, marginTop: 4 },
  menuRow:       { flexDirection: "row", alignItems: "center", paddingVertical: 13 },
  menuLabel:     { color: C.text, fontSize: 15, fontWeight: "600", textAlign: "right" },
  logoutBtn:     { backgroundColor: "#2a0a0a", borderRadius: 14, padding: 16, alignItems: "center", borderWidth: 1, borderColor: C.red + "55" },
  logoutText:    { color: C.red, fontWeight: "700", fontSize: 15 },
});

/* ══════════════════════════════════════════════════════════════
   APP ROOT
══════════════════════════════════════════════════════════════ */
export default function App() {
  const [loggedIn, setLoggedIn] = useState(false);

  if (!loggedIn) {
    return <LoginScreen onLogin={() => setLoggedIn(true)} />;
  }

  return (
    <MqttProvider>
      <NavigationContainer>
        <Tab.Navigator
          screenOptions={({ route }) => ({
            headerShown: false,
            tabBarStyle: {
              backgroundColor: C.navBg,
              borderTopColor: C.border,
              borderTopWidth: 1,
              height: 60,
              paddingBottom: 8,
            },
            tabBarActiveTintColor:   C.blue,
            tabBarInactiveTintColor: C.sub,
            tabBarLabelStyle: { fontSize: 11, fontWeight: "700" },
            tabBarIcon: ({ color, focused }) => {
              const icons = { "בית": "🏠", "AI": "🤖", "אבטחה": "🛡️", "פרופיל": "👤" };
              return (
                <View style={{
                  alignItems: "center", justifyContent: "center",
                  width: 32, height: 32, borderRadius: 10,
                  backgroundColor: focused ? C.blue + "22" : "transparent",
                }}>
                  <Text style={{ fontSize: 18, opacity: focused ? 1 : 0.5 }}>{icons[route.name]}</Text>
                </View>
              );
            },
          })}
        >
          <Tab.Screen name="בית"     component={Dashboard} />
          <Tab.Screen name="AI"      component={AIScreen} />
          <Tab.Screen name="אבטחה"   component={SecurityScreen} />
          <Tab.Screen name="פרופיל"  children={() => <ProfileScreen onLogout={() => setLoggedIn(false)} />} />
        </Tab.Navigator>
      </NavigationContainer>
    </MqttProvider>
  );
}
