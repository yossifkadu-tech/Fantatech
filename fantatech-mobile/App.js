import React, { useState } from "react";
import {
  View, Text, StyleSheet, TouchableOpacity, ScrollView,
  TextInput, Switch, SafeAreaView, StatusBar, ActivityIndicator,
} from "react-native";
import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { MqttProvider, useMqtt } from "./context/MqttContext";
import { LanguageProvider, useLanguage } from "./context/LanguageContext";

const Tab = createBottomTabNavigator();

/* ─── Design tokens ─────────────────────────────────────────── */
const C = {
  bg:       "#001117",
  card:     "#0D1824",
  card2:    "#1A1F2B",
  blue:     "#2563EB",
  blueGlow: "#3B82F6",
  green:    "#22C55E",
  red:      "#FF3830",
  orange:   "#F97316",
  text:     "#F5F5F7",
  sub:      "#7A8499",
  border:   "#1E2A40",
  navBg:    "#001117",
};

/* ─── Shared atoms ──────────────────────────────────────────── */
function Card({ children, style }) {
  return (
    <View style={[{ backgroundColor: C.card, borderRadius: 16, padding: 16, borderWidth: 1, borderColor: C.border }, style]}>
      {children}
    </View>
  );
}

function Divider() {
  return <View style={{ height: 1, backgroundColor: C.border, marginVertical: 6 }} />;
}

/** Top bar for sub-screens */
function BackBar({ onBack, title, rightEl }) {
  return (
    <View style={bb.wrap}>
      <TouchableOpacity onPress={onBack} style={bb.backBtn} hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
        <Text style={bb.arrow}>{"<"}</Text>
      </TouchableOpacity>
      <Text style={bb.title}>{title}</Text>
      <View style={{ width: 36 }}>{rightEl || null}</View>
    </View>
  );
}
const bb = StyleSheet.create({
  wrap:    { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 18, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: C.border },
  backBtn: { width: 36, height: 36, borderRadius: 10, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" },
  arrow:   { color: C.text, fontSize: 18, fontWeight: "700", lineHeight: 22 },
  title:   { color: C.text, fontSize: 18, fontWeight: "700", flex: 1, textAlign: "center" },
});

/** Dashboard/tab top bar */
function TopBar({ onMenu }) {
  return (
    <View style={tb.wrap}>
      <TouchableOpacity style={tb.iconBtn} onPress={onMenu}>
        <Text style={tb.hamburger}>≡</Text>
      </TouchableOpacity>
      <Text style={tb.logo}>Fanta<Text style={{ color: C.blue }}>Tech</Text></Text>
      <TouchableOpacity style={tb.iconBtn}>
        <Text style={{ fontSize: 18 }}>🔔</Text>
      </TouchableOpacity>
    </View>
  );
}
const tb = StyleSheet.create({
  wrap:      { flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 18, paddingVertical: 12, borderBottomWidth: 1, borderBottomColor: C.border },
  logo:      { fontSize: 22, fontWeight: "900", color: C.text, letterSpacing: 0.5 },
  iconBtn:   { width: 38, height: 38, borderRadius: 10, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" },
  hamburger: { color: C.text, fontSize: 22, fontWeight: "700" },
});

/** Filter tab strip */
function FilterTabs({ tabs, selected, onSelect }) {
  return (
    <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={{ flexDirection: "row", gap: 8, paddingHorizontal: 16, paddingVertical: 12 }}>
      {tabs.map((tab) => (
        <TouchableOpacity
          key={tab}
          onPress={() => onSelect(tab)}
          style={{ paddingHorizontal: 16, paddingVertical: 7, borderRadius: 20, backgroundColor: selected === tab ? C.blue : C.card2, borderWidth: 1, borderColor: selected === tab ? C.blue : C.border }}
        >
          <Text style={{ color: selected === tab ? "#fff" : C.sub, fontWeight: "600", fontSize: 13 }}>{tab}</Text>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

/** Language picker for Profile */
function LanguagePickerRow() {
  const { currentLangMeta, nextLanguage } = useLanguage();
  return (
    <TouchableOpacity
      style={{ flexDirection: "row", alignItems: "center", paddingVertical: 16, paddingHorizontal: 4 }}
      onPress={nextLanguage}
      activeOpacity={0.7}
    >
      <Text style={{ color: C.sub, fontSize: 18, marginLeft: 8 }}>{">"}</Text>
      <View style={{ flex: 1 }} />
      <Text style={{ color: C.text, fontSize: 15, fontWeight: "600", marginRight: 10 }}>שפה / Language</Text>
      <Text style={{ fontSize: 22, marginRight: 6 }}>{currentLangMeta.flag}</Text>
      <Text style={{ color: C.sub, fontSize: 13, minWidth: 50 }}>{currentLangMeta.label}</Text>
    </TouchableOpacity>
  );
}

/* ══════════════════════════════════════════════════════════════
   1. LOGIN SCREEN
══════════════════════════════════════════════════════════════ */
function LoginScreen({ onLogin }) {
  const { t, isRTL } = useLanguage();
  const [email, setEmail]           = useState("");
  const [password, setPassword]     = useState("");
  const [showPassword, setShowPass] = useState(false);
  const [emailFocus, setEmailFocus] = useState(false);
  const [passFocus,  setPassFocus]  = useState(false);

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <ScrollView contentContainerStyle={ls.scroll} keyboardShouldPersistTaps="handled" showsVerticalScrollIndicator={false}>

        {/* Brand */}
        <View style={ls.brandWrap}>
          <View style={ls.chevronWrap}>
            <View style={ls.chevronL} />
            <View style={ls.chevronR} />
          </View>
          <Text style={ls.brand}>Fanta<Text style={{ color: C.blue }}>Tech</Text></Text>
        </View>

        {/* Greeting */}
        <View style={{ width: "100%", marginBottom: 32 }}>
          <Text style={[ls.greeting, { textAlign: isRTL ? "right" : "left" }]}>{t("loginGreeting")}</Text>
          <Text style={[ls.greetSub, { textAlign: isRTL ? "right" : "left" }]}>{t("loginSub")}</Text>
        </View>

        {/* Email */}
        <View style={ls.fieldWrap}>
          <View style={[ls.inputWrap, emailFocus && ls.inputFocused]}>
            <View style={ls.icon}><Text style={{ fontSize: 15, opacity: 0.5 }}>👤</Text></View>
            <TextInput
              style={[ls.input, { textAlign: isRTL ? "right" : "left" }]}
              placeholder={isRTL ? "אימייל או טלפון" : "Email or phone"}
              placeholderTextColor={C.sub}
              value={email}
              onChangeText={setEmail}
              keyboardType="email-address"
              autoCapitalize="none"
              onFocus={() => setEmailFocus(true)}
              onBlur={() => setEmailFocus(false)}
            />
          </View>

          {/* Password */}
          <View style={[ls.inputWrap, passFocus && ls.inputFocused]}>
            <View style={ls.icon}><Text style={{ fontSize: 15, opacity: 0.5 }}>🔒</Text></View>
            <TextInput
              style={[ls.input, { textAlign: isRTL ? "right" : "left" }]}
              placeholder={t("loginPassword")}
              placeholderTextColor={C.sub}
              value={password}
              onChangeText={setPassword}
              secureTextEntry={!showPassword}
              onFocus={() => setPassFocus(true)}
              onBlur={() => setPassFocus(false)}
            />
            <TouchableOpacity style={ls.eye} onPress={() => setShowPass(v => !v)} hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}>
              <Text style={{ fontSize: 15, opacity: showPassword ? 0.9 : 0.4 }}>{showPassword ? "👁" : "🙈"}</Text>
            </TouchableOpacity>
          </View>

          <TouchableOpacity style={{ alignSelf: isRTL ? "flex-start" : "flex-end", marginTop: 4 }}>
            <Text style={{ color: C.blue, fontSize: 13, fontWeight: "600" }}>שכחת סיסמה?</Text>
          </TouchableOpacity>
        </View>

        <TouchableOpacity style={ls.btn} onPress={onLogin} activeOpacity={0.85}>
          <Text style={ls.btnText}>{t("loginBtn")}</Text>
        </TouchableOpacity>

        <View style={ls.orRow}>
          <View style={{ flex: 1, height: 1, backgroundColor: C.border }} />
          <Text style={{ color: C.sub, fontSize: 13, marginHorizontal: 14 }}>{t("loginOr")}</Text>
          <View style={{ flex: 1, height: 1, backgroundColor: C.border }} />
        </View>

        <TouchableOpacity style={ls.googleBtn} onPress={onLogin} activeOpacity={0.85}>
          <View style={ls.gCircle}><Text style={ls.gLetter}>G</Text></View>
          <Text style={{ color: C.text, fontWeight: "600", fontSize: 15 }}>{t("loginGoogle")}</Text>
        </TouchableOpacity>

        <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "center", marginTop: 4 }}>
          <Text style={{ color: C.sub, fontSize: 13 }}>אין לך חשבון? </Text>
          <TouchableOpacity onPress={onLogin}><Text style={{ color: C.blue, fontSize: 13, fontWeight: "700" }}>הירשם עכשיו</Text></TouchableOpacity>
        </View>

      </ScrollView>
    </SafeAreaView>
  );
}
const ls = StyleSheet.create({
  scroll:       { flexGrow: 1, alignItems: "center", justifyContent: "center", padding: 28, paddingTop: 40 },
  brandWrap:    { alignItems: "center", marginBottom: 36 },
  chevronWrap:  { flexDirection: "row", marginBottom: 10, gap: 4 },
  chevronL:     { width: 18, height: 18, borderLeftWidth: 3, borderBottomWidth: 3, borderColor: C.blue, transform: [{ rotate: "45deg" }] },
  chevronR:     { width: 18, height: 18, borderRightWidth: 3, borderBottomWidth: 3, borderColor: C.text, transform: [{ rotate: "-45deg" }] },
  brand:        { fontSize: 30, fontWeight: "900", color: C.text },
  greeting:     { fontSize: 28, fontWeight: "800", color: C.text, marginBottom: 6 },
  greetSub:     { color: C.sub, fontSize: 14 },
  fieldWrap:    { width: "100%", gap: 12, marginBottom: 24 },
  inputWrap:    { flexDirection: "row", alignItems: "center", backgroundColor: C.card2, borderRadius: 14, borderWidth: 1, borderColor: C.border, paddingHorizontal: 14, height: 54 },
  inputFocused: { borderColor: C.blue },
  icon:         { width: 28, alignItems: "center" },
  input:        { flex: 1, color: C.text, fontSize: 15, paddingVertical: 0 },
  eye:          { width: 32, alignItems: "center" },
  btn:          { width: "100%", backgroundColor: C.blue, borderRadius: 14, height: 52, alignItems: "center", justifyContent: "center", marginBottom: 22 },
  btnText:      { color: "#fff", fontWeight: "700", fontSize: 17 },
  orRow:        { flexDirection: "row", alignItems: "center", width: "100%", marginBottom: 20 },
  googleBtn:    { flexDirection: "row", alignItems: "center", justifyContent: "center", backgroundColor: C.card2, borderRadius: 14, height: 52, width: "100%", borderWidth: 1, borderColor: C.border, gap: 10, marginBottom: 28 },
  gCircle:      { width: 28, height: 28, borderRadius: 14, backgroundColor: "#fff", alignItems: "center", justifyContent: "center" },
  gLetter:      { fontSize: 15, fontWeight: "900", color: "#4285F4" },
});

/* ══════════════════════════════════════════════════════════════
   2. DASHBOARD — בית
══════════════════════════════════════════════════════════════ */
function Dashboard({ onNavigate }) {
  const { alarmActive } = useMqtt();

  const statusGrid = [
    { icon: "🛡️", label: "אזעקה",     value: alarmActive ? "פעילה" : "מוגן",   sub: null,    color: alarmActive ? C.red : C.green,  nav: null      },
    { icon: "📷", label: "מצלמות",    value: "פעיל",                        sub: null,    color: C.blue,                         nav: "cameras" },
    { icon: "💡", label: "תאורה",     value: "8 אורות דולקים",              sub: null,    color: C.orange,                       nav: "alerts"  },
    { icon: "🌡", label: "טמפרטורה", value: "24°C",                         sub: "נעים",  color: C.blueGlow,                     nav: null      },
  ];

  const quickActions = [
    { icon: "🌙", label: "לילה טוב",    nav: "automations" },
    { icon: "⚡", label: "כבה הכל",      nav: null           },
    { icon: "🚶", label: "יציאה מהבית", nav: null           },
  ];

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <TopBar />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 28 }} showsVerticalScrollIndicator={false}>

        {/* Hero greeting card */}
        <View style={[db.hero, { borderColor: alarmActive ? C.red + "88" : C.green + "55" }]}>
          {/* Shield icon */}
          <View style={[db.heroShield, { borderColor: alarmActive ? C.red : C.green, backgroundColor: (alarmActive ? C.red : C.green) + "18" }]}>
            <Text style={{ fontSize: 30 }}>{alarmActive ? "🚨" : "🛡️"}</Text>
          </View>
          <View style={{ flex: 1, marginRight: 12 }}>
            <Text style={db.heroName}>שלום דוד.</Text>
            <Text style={[db.heroStatus, { color: alarmActive ? C.red : C.green }]}>
              {alarmActive ? "אזעקה פעילה!" : "הבית שלך מוגן"}
            </Text>
            <Text style={db.heroSub}>כל המערכות פעילות</Text>
          </View>
        </View>

        {/* 2×2 status grid */}
        <View style={db.grid}>
          {statusGrid.map((item, i) => (
            <TouchableOpacity
              key={i}
              style={db.gridCard}
              onPress={() => item.nav && onNavigate(item.nav)}
              activeOpacity={item.nav ? 0.75 : 1}
            >
              <View style={[db.gridIconWrap, { backgroundColor: item.color + "20" }]}>
                <Text style={{ fontSize: 22 }}>{item.icon}</Text>
              </View>
              <Text style={db.gridLabel}>{item.label}</Text>
              <Text style={[db.gridValue, { color: item.color }]}>{item.value}</Text>
              {item.sub ? <Text style={{ color: C.sub, fontSize: 11, textAlign: "right", marginTop: 2 }}>{item.sub}</Text> : null}
            </TouchableOpacity>
          ))}
        </View>

        {/* Fanta AI card */}
        <TouchableOpacity style={db.aiCard} activeOpacity={0.85}>
          {/* Robot face */}
          <View style={db.faceOuter}>
            <View style={db.faceInner}>
              <View style={{ flexDirection: "row", gap: 14 }}>
                <View style={db.eye} />
                <View style={db.eye} />
              </View>
            </View>
          </View>
          <View style={{ flex: 1 }}>
            <Text style={db.aiTitle}>Fanta AI</Text>
            <Text style={db.aiSub}>במה אוכל לעזור לך היום?</Text>
          </View>
          <View style={db.aiArrow}>
            <Text style={{ color: C.blue, fontSize: 16 }}>›</Text>
          </View>
        </TouchableOpacity>

        {/* Quick actions */}
        <Text style={db.sectionTitle}>פעולות מהירות</Text>
        <View style={db.qaRow}>
          {quickActions.map((a, i) => (
            <TouchableOpacity
              key={i}
              style={db.qaBtn}
              onPress={() => a.nav && onNavigate(a.nav)}
              activeOpacity={0.8}
            >
              <Text style={{ fontSize: 22, marginBottom: 6 }}>{a.icon}</Text>
              <Text style={db.qaLabel}>{a.label}</Text>
            </TouchableOpacity>
          ))}
        </View>

        {/* Navigation tiles (energy, automations, alerts) */}
        <View style={{ flexDirection: "row", gap: 10 }}>
          {[
            { icon: "⚡", label: "אנרגיה", sub: "245 kWh", nav: "energy" },
            { icon: "🤖", label: "אוטומציות", sub: "4 פעילות", nav: "automations" },
            { icon: "🔔", label: "התראות", sub: "2 חדשות", nav: "alerts" },
          ].map((item) => (
            <TouchableOpacity
              key={item.nav}
              style={db.tileBtn}
              onPress={() => onNavigate(item.nav)}
              activeOpacity={0.8}
            >
              <Text style={{ fontSize: 20, marginBottom: 4 }}>{item.icon}</Text>
              <Text style={db.tileLabel}>{item.label}</Text>
              <Text style={db.tileSub}>{item.sub}</Text>
            </TouchableOpacity>
          ))}
        </View>

      </ScrollView>
    </SafeAreaView>
  );
}
const db = StyleSheet.create({
  hero:       { flexDirection: "row", alignItems: "center", backgroundColor: C.card, borderRadius: 18, padding: 16, marginBottom: 14, borderWidth: 1.5 },
  heroShield: { width: 60, height: 60, borderRadius: 30, borderWidth: 2, alignItems: "center", justifyContent: "center", marginLeft: 12 },
  heroName:   { color: C.text, fontSize: 20, fontWeight: "800", textAlign: "right", marginBottom: 2 },
  heroStatus: { fontSize: 15, fontWeight: "700", textAlign: "right", marginBottom: 2 },
  heroSub:    { color: C.sub, fontSize: 12, textAlign: "right" },
  grid:       { flexDirection: "row", flexWrap: "wrap", gap: 10, marginBottom: 14 },
  gridCard:   { flex: 1, minWidth: "44%", backgroundColor: C.card, borderRadius: 16, padding: 14, borderWidth: 1, borderColor: C.border, alignItems: "flex-end" },
  gridIconWrap:{ width: 44, height: 44, borderRadius: 12, alignItems: "center", justifyContent: "center", marginBottom: 8 },
  gridLabel:  { color: C.sub, fontSize: 12, fontWeight: "600", marginBottom: 4 },
  gridValue:  { fontSize: 14, fontWeight: "800" },
  aiCard:     { flexDirection: "row", alignItems: "center", backgroundColor: "#08112E", borderRadius: 18, padding: 14, marginBottom: 20, borderWidth: 1, borderColor: C.blue + "44", gap: 14 },
  faceOuter:  { width: 54, height: 54, borderRadius: 27, backgroundColor: "#0A1535", borderWidth: 1.5, borderColor: C.blue + "88", alignItems: "center", justifyContent: "center" },
  faceInner:  { width: 42, height: 42, borderRadius: 21, backgroundColor: "#0D1A3E", alignItems: "center", justifyContent: "center" },
  eye:        { width: 10, height: 10, borderRadius: 5, backgroundColor: C.blueGlow },
  aiTitle:    { color: C.text, fontWeight: "800", fontSize: 15, textAlign: "right" },
  aiSub:      { color: C.sub, fontSize: 12, textAlign: "right", marginTop: 3 },
  aiArrow:    { width: 28, height: 28, borderRadius: 14, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" },
  sectionTitle:{ color: C.text, fontSize: 15, fontWeight: "800", textAlign: "right", marginBottom: 12 },
  qaRow:      { flexDirection: "row", gap: 10, marginBottom: 14 },
  qaBtn:      { flex: 1, backgroundColor: C.card, borderRadius: 16, padding: 14, alignItems: "center", borderWidth: 1, borderColor: C.border },
  qaLabel:    { color: C.sub, fontSize: 11, fontWeight: "600", textAlign: "center" },
  tileBtn:    { flex: 1, backgroundColor: C.card, borderRadius: 14, padding: 12, alignItems: "flex-end", borderWidth: 1, borderColor: C.border },
  tileLabel:  { color: C.text, fontSize: 12, fontWeight: "700" },
  tileSub:    { color: C.sub, fontSize: 10, marginTop: 2 },
});

/* ══════════════════════════════════════════════════════════════
   3. AI SCREEN — Fanta AI
══════════════════════════════════════════════════════════════ */
function AIScreen() {
  const [input, setInput] = useState("");
  const [chatHistory, setChatHistory] = useState([]);

  const quickPrompts = [
    "כבה את כל האורות",
    "מה מצב הבית עכשיו?",
    "הפעל מצב לילה",
    "האם יש תנועה בחניה?",
  ];

  function send(text) {
    const msg = (text || input).trim();
    if (!msg) return;
    setChatHistory(prev => [...prev, { from: "user", text: msg }]);
    setInput("");
    setTimeout(() => {
      setChatHistory(prev => [...prev, { from: "ai", text: "בסדר גמור! מבצע את הפעולה... ✅" }]);
    }, 700);
  }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />

      {/* Header */}
      <View style={ais.header}>
        <Text style={ais.headerTitle}>Fanta AI</Text>
      </View>

      <ScrollView contentContainerStyle={{ paddingBottom: 16 }} showsVerticalScrollIndicator={false}>
        {/* Robot face */}
        <View style={ais.faceSection}>
          <View style={ais.faceOuter}>
            <View style={ais.faceMid}>
              <View style={ais.faceInner}>
                <View style={{ flexDirection: "row", gap: 20 }}>
                  <View style={ais.eye} />
                  <View style={ais.eye} />
                </View>
              </View>
            </View>
          </View>
          <Text style={ais.greeting}>דוד! 👋</Text>
          <Text style={ais.greetSub}>אני כאן כדי לעזור לך ולנהל את הבית שלך</Text>
        </View>

        {/* Chat bubbles (if any) */}
        {chatHistory.length > 0 && (
          <View style={{ paddingHorizontal: 16, gap: 8, marginBottom: 8 }}>
            {chatHistory.map((m, i) => (
              <View key={i} style={[ais.bubble, m.from === "user" ? ais.bubbleUser : ais.bubbleAI]}>
                <Text style={{ color: m.from === "user" ? "#fff" : C.text, fontSize: 14 }}>{m.text}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Quick action buttons */}
        <View style={{ paddingHorizontal: 16, gap: 10 }}>
          {quickPrompts.map((p) => (
            <TouchableOpacity key={p} style={ais.promptBtn} onPress={() => send(p)} activeOpacity={0.8}>
              <Text style={ais.promptText}>{p}</Text>
            </TouchableOpacity>
          ))}
        </View>
      </ScrollView>

      {/* Input bar */}
      <View style={ais.inputBar}>
        <TouchableOpacity style={ais.micBtn} onPress={() => send("הפעל מצב לילה")}>
          <Text style={{ fontSize: 20 }}>🎤</Text>
        </TouchableOpacity>
        <TextInput
          style={ais.input}
          placeholder="הקש! או דברי אלי..."
          placeholderTextColor={C.sub}
          value={input}
          onChangeText={setInput}
          onSubmitEditing={() => send()}
          textAlign="right"
        />
      </View>
    </SafeAreaView>
  );
}
const ais = StyleSheet.create({
  header:      { alignItems: "center", paddingVertical: 16, borderBottomWidth: 1, borderBottomColor: C.border },
  headerTitle: { color: C.text, fontSize: 18, fontWeight: "700" },
  faceSection: { alignItems: "center", paddingVertical: 28, paddingHorizontal: 16 },
  faceOuter:   { width: 180, height: 180, borderRadius: 90, backgroundColor: "#050A18", borderWidth: 1, borderColor: "#1A2845", alignItems: "center", justifyContent: "center", marginBottom: 20 },
  faceMid:     { width: 148, height: 148, borderRadius: 74, backgroundColor: "#080E20", borderWidth: 1, borderColor: "#1E3060", alignItems: "center", justifyContent: "center" },
  faceInner:   { width: 110, height: 110, borderRadius: 55, backgroundColor: "#0A1228", alignItems: "center", justifyContent: "center" },
  eye:         { width: 22, height: 22, borderRadius: 11, backgroundColor: C.blueGlow },
  greeting:    { color: C.text, fontSize: 26, fontWeight: "800", textAlign: "center", marginBottom: 8 },
  greetSub:    { color: C.sub, fontSize: 13, textAlign: "center", lineHeight: 20, paddingHorizontal: 20 },
  bubble:      { maxWidth: "80%", borderRadius: 16, padding: 12 },
  bubbleAI:    { backgroundColor: C.card2, alignSelf: "flex-start" },
  bubbleUser:  { backgroundColor: C.blue, alignSelf: "flex-end" },
  promptBtn:   { backgroundColor: C.card2, borderRadius: 14, padding: 16, borderWidth: 1, borderColor: C.border },
  promptText:  { color: C.text, fontSize: 14, fontWeight: "600", textAlign: "right" },
  inputBar:    { flexDirection: "row", alignItems: "center", padding: 12, gap: 10, backgroundColor: C.card, borderTopWidth: 1, borderTopColor: C.border },
  micBtn:      { width: 46, height: 46, borderRadius: 23, backgroundColor: C.blue, alignItems: "center", justifyContent: "center" },
  input:       { flex: 1, backgroundColor: C.card2, borderRadius: 22, paddingHorizontal: 16, paddingVertical: 10, color: C.text, fontSize: 14, borderWidth: 1, borderColor: C.border },
});

/* ══════════════════════════════════════════════════════════════
   4. SECURITY SCREEN — אבטחה
══════════════════════════════════════════════════════════════ */
function SecurityScreen({ onNavigate }) {
  const { alarmActive, locks, triggerAlarm, disarmAlarm, toggleLock } = useMqtt();

  const sensors = [
    { icon: "🔒", label: "דלת כניסה",    statusIcon: "✓", ok: locks.entrance === "LOCK", onPress: () => toggleLock("entrance") },
    { icon: "🪟", label: "חלונות",          statusIcon: "✓", ok: true  },
    { icon: "📡", label: "חיישני תנועה", statusIcon: "◎", ok: true  },
    { icon: "🛡", label: "גלאי עשן",      statusIcon: "✓", ok: true  },
  ];

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <BackBar onBack={() => {}} title="אבטחה" />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 28 }} showsVerticalScrollIndicator={false}>

        {/* Shield hero */}
        <View style={sec.heroWrap}>
          <View style={[sec.shieldRing3, { borderColor: (alarmActive ? C.red : C.green) + "20" }]}>
            <View style={[sec.shieldRing2, { borderColor: (alarmActive ? C.red : C.green) + "45" }]}>
              <View style={[sec.shieldRing1, { borderColor: alarmActive ? C.red : C.green, backgroundColor: (alarmActive ? C.red : C.green) + "18" }]}>
                <Text style={{ fontSize: 46 }}>{alarmActive ? "🚨" : "🛡️"}</Text>
              </View>
            </View>
          </View>
          <Text style={[sec.heroTitle, { color: alarmActive ? C.red : C.green }]}>
            {alarmActive ? "אזעקה פעילה!" : "הבית מוגן"}
          </Text>
          <Text style={sec.heroSub}>כל המערכות פעילות</Text>
        </View>

        {/* Sensor list */}
        <Card style={{ marginBottom: 16 }}>
          {sensors.map((s, i) => (
            <View key={i}>
              <TouchableOpacity style={sec.sensorRow} onPress={s.onPress} activeOpacity={s.onPress ? 0.7 : 1}>
                {/* Status icon right */}
                <View style={[sec.statusBadge, { backgroundColor: (s.ok ? C.green : C.red) + "20" }]}>
                  <Text style={{ color: s.ok ? C.green : C.red, fontSize: 14, fontWeight: "700" }}>{s.statusIcon}</Text>
                </View>
                <View style={{ flex: 1 }} />
                <Text style={sec.sensorLabel}>{s.label}</Text>
                <View style={sec.sensorIconWrap}>
                  <Text style={{ fontSize: 18 }}>{s.icon}</Text>
                </View>
              </TouchableOpacity>
              {i < sensors.length - 1 && <Divider />}
            </View>
          ))}
        </Card>

        {/* Cameras shortcut */}
        <TouchableOpacity
          style={[sec.shortcutBtn, { marginBottom: 14 }]}
          onPress={() => onNavigate && onNavigate("cameras")}
          activeOpacity={0.8}
        >
          <Text style={{ color: C.blue, fontWeight: "700", fontSize: 14 }}>📷 צפה במצלמות</Text>
          <Text style={{ color: C.blue, fontSize: 16 }}>›</Text>
        </TouchableOpacity>

        {/* PANIC button */}
        <TouchableOpacity
          style={sec.panicBtn}
          onPress={alarmActive ? disarmAlarm : triggerAlarm}
          activeOpacity={0.85}
        >
          <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
            <View style={sec.panicIcon}>
              <Text style={{ fontSize: 22 }}>🚨</Text>
            </View>
            <View>
              <Text style={sec.panicText}>PANIC</Text>
              <Text style={sec.panicSub}>לחץ לסיוע חירום</Text>
            </View>
          </View>
        </TouchableOpacity>

      </ScrollView>
    </SafeAreaView>
  );
}
const sec = StyleSheet.create({
  heroWrap:    { alignItems: "center", paddingVertical: 28 },
  shieldRing3: { width: 180, height: 180, borderRadius: 90, borderWidth: 1, alignItems: "center", justifyContent: "center" },
  shieldRing2: { width: 148, height: 148, borderRadius: 74, borderWidth: 1.5, alignItems: "center", justifyContent: "center" },
  shieldRing1: { width: 110, height: 110, borderRadius: 55, borderWidth: 2.5, alignItems: "center", justifyContent: "center" },
  heroTitle:   { fontSize: 22, fontWeight: "800", marginTop: 16, marginBottom: 4 },
  heroSub:     { color: C.sub, fontSize: 13 },
  sensorRow:   { flexDirection: "row", alignItems: "center", paddingVertical: 12, gap: 10 },
  sensorLabel: { color: C.text, fontSize: 14, fontWeight: "600", textAlign: "right" },
  sensorIconWrap: { width: 36, height: 36, borderRadius: 10, backgroundColor: C.card2, alignItems: "center", justifyContent: "center", marginLeft: 8 },
  statusBadge: { width: 34, height: 34, borderRadius: 10, alignItems: "center", justifyContent: "center" },
  shortcutBtn: { flexDirection: "row", alignItems: "center", justifyContent: "space-between", backgroundColor: C.card2, borderRadius: 14, padding: 14, borderWidth: 1, borderColor: C.blue + "44" },
  panicBtn:    { backgroundColor: "#1A0808", borderRadius: 18, padding: 18, borderWidth: 2, borderColor: C.red, alignItems: "center" },
  panicIcon:   { width: 46, height: 46, borderRadius: 23, backgroundColor: C.red + "22", alignItems: "center", justifyContent: "center" },
  panicText:   { color: C.red, fontSize: 20, fontWeight: "900", letterSpacing: 2, textAlign: "right" },
  panicSub:    { color: C.sub, fontSize: 12, textAlign: "right", marginTop: 2 },
});

/* ══════════════════════════════════════════════════════════════
   5. PROFILE SCREEN — פרופיל
══════════════════════════════════════════════════════════════ */
function ProfileScreen({ onLogout, onNavigate }) {
  const menuItems = [
    { icon: "🏠", label: "הבתים שלי",       key: null,        arrow: true },
    { icon: "👥", label: "משתמשים",          key: null,        arrow: true },
    { icon: "📅", label: "מנוי וחיוב",        key: null,        arrow: true },
    { icon: "⚙️", label: "הגדרות",            key: null,        arrow: true },
    { icon: "💬", label: "עזרה ותמיכה",     key: null,        arrow: true },
  ];

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />

      {/* Header */}
      <View style={pf.header}>
        <Text style={pf.headerTitle}>פרופיל שלי</Text>
      </View>

      <ScrollView contentContainerStyle={{ paddingBottom: 36 }} showsVerticalScrollIndicator={false}>

        {/* Avatar */}
        <View style={pf.avatarSection}>
          <View style={pf.avatar}>
            <Text style={{ fontSize: 40 }}>👤</Text>
          </View>
          <Text style={pf.name}>יוסי פקאדו</Text>
          <Text style={pf.email}>yossi.fkadu@gmail.com</Text>
        </View>

        {/* Menu list */}
        <Card style={{ marginHorizontal: 16, marginBottom: 10 }}>
          {menuItems.map((item, i) => (
            <View key={item.label}>
              <TouchableOpacity
                style={pf.menuRow}
                onPress={() => item.key && onNavigate && onNavigate(item.key)}
                activeOpacity={0.7}
              >
                <Text style={{ color: C.sub, fontSize: 16 }}>{">"}</Text>
                <View style={{ flex: 1 }} />
                <Text style={pf.menuLabel}>{item.label}</Text>
                <View style={pf.menuIcon}>
                  <Text style={{ fontSize: 18 }}>{item.icon}</Text>
                </View>
              </TouchableOpacity>
              {i < menuItems.length - 1 && <Divider />}
            </View>
          ))}
        </Card>

        {/* Logout */}
        <Card style={{ marginHorizontal: 16 }}>
          <TouchableOpacity style={pf.menuRow} onPress={onLogout} activeOpacity={0.7}>
            <Text style={{ color: C.red, fontSize: 16 }}>{">"}</Text>
            <View style={{ flex: 1 }} />
            <Text style={[pf.menuLabel, { color: C.red }]}>יציאה מהחשבון</Text>
            <View style={pf.menuIcon}>
              <Text style={{ fontSize: 18 }}>🚪</Text>
            </View>
          </TouchableOpacity>
        </Card>

      </ScrollView>
    </SafeAreaView>
  );
}
const pf = StyleSheet.create({
  header:        { alignItems: "center", paddingVertical: 16, borderBottomWidth: 1, borderBottomColor: C.border },
  headerTitle:   { color: C.text, fontSize: 18, fontWeight: "700" },
  avatarSection: { alignItems: "center", paddingVertical: 24 },
  avatar:        { width: 88, height: 88, borderRadius: 44, backgroundColor: C.card2, alignItems: "center", justifyContent: "center", marginBottom: 12, borderWidth: 2, borderColor: C.border },
  name:          { color: C.text, fontSize: 20, fontWeight: "800", marginBottom: 4 },
  email:         { color: C.sub, fontSize: 13 },
  menuRow:       { flexDirection: "row", alignItems: "center", paddingVertical: 12 },
  menuLabel:     { color: C.text, fontSize: 15, fontWeight: "600" },
  menuIcon:      { width: 36, height: 36, borderRadius: 10, backgroundColor: C.card2, alignItems: "center", justifyContent: "center", marginLeft: 10 },
});

/* ══════════════════════════════════════════════════════════════
   6. CAMERAS SCREEN — מצלמות
══════════════════════════════════════════════════════════════ */
const CAMERA_DEFS = [
  { key: "salon",   label: "סלון"        },
  { key: "parking", label: "חניה"        },
  { key: "yard",    label: "חצר"         },
  { key: "all",     label: "כל המצלמות" },
];

const CAMERA_FEEDS = [
  { key: "feed1", label: "חוץ",          bg: "#0A1520" },
  { key: "feed2", label: "סלון",         bg: "#0D1A12" },
  { key: "feed3", label: "כניסה ראשית", bg: "#12100A" },
  { key: "feed4", label: "חניה",         bg: "#080F1A" },
];

function CamerasScreen({ onBack }) {
  const [filter, setFilter] = useState("כל המצלמות");

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <BackBar onBack={onBack} title="מצלמות" />
      <FilterTabs tabs={CAMERA_DEFS.map(c => c.label)} selected={filter} onSelect={setFilter} />

      <ScrollView contentContainerStyle={{ padding: 14, paddingBottom: 28, gap: 12 }} showsVerticalScrollIndicator={false}>
        {/* Large top feed */}
        <View style={[cam.largeCard, { backgroundColor: CAMERA_FEEDS[0].bg }]}>
          <View style={cam.liveBadge}>
            <View style={cam.liveDot} />
            <Text style={cam.liveText}>LIVE</Text>
          </View>
          <TouchableOpacity style={cam.playBtn}>
            <Text style={{ color: "#fff", fontSize: 18 }}>▶</Text>
          </TouchableOpacity>
          <View style={{ position: "absolute", bottom: 10, left: 12 }}>
            <Text style={{ color: "#fff", fontSize: 13, fontWeight: "600", textShadowColor: "#000", textShadowRadius: 4 }}>
              {CAMERA_FEEDS[0].label}
            </Text>
          </View>
          {/* Simulated house silhouette */}
          <View style={cam.silhouette} />
        </View>

        {/* 3 smaller feeds */}
        {CAMERA_FEEDS.slice(1).map((feed) => (
          <View key={feed.key} style={[cam.card, { backgroundColor: feed.bg }]}>
            <View style={cam.liveBadge}>
              <View style={cam.liveDot} />
              <Text style={cam.liveText}>LIVE</Text>
            </View>
            <TouchableOpacity style={cam.playBtn}>
              <Text style={{ color: "#fff", fontSize: 16 }}>▶</Text>
            </TouchableOpacity>
            <View style={{ position: "absolute", bottom: 10, left: 12 }}>
              <Text style={{ color: "#fff", fontSize: 13, fontWeight: "600", textShadowColor: "#000", textShadowRadius: 4 }}>
                {feed.label}
              </Text>
            </View>
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}
const cam = StyleSheet.create({
  largeCard:  { height: 200, borderRadius: 16, overflow: "hidden", position: "relative", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: C.border },
  card:       { height: 150, borderRadius: 16, overflow: "hidden", position: "relative", alignItems: "center", justifyContent: "center", borderWidth: 1, borderColor: C.border },
  liveBadge:  { position: "absolute", top: 10, left: 10, flexDirection: "row", alignItems: "center", gap: 5, backgroundColor: C.green + "CC", borderRadius: 6, paddingHorizontal: 8, paddingVertical: 4 },
  liveDot:    { width: 6, height: 6, borderRadius: 3, backgroundColor: "#fff" },
  liveText:   { color: "#fff", fontSize: 11, fontWeight: "800", letterSpacing: 0.5 },
  playBtn:    { width: 44, height: 44, borderRadius: 22, backgroundColor: "rgba(0,0,0,0.5)", alignItems: "center", justifyContent: "center", position: "absolute", right: 16 },
  silhouette: { position: "absolute", bottom: 0, left: 0, right: 0, height: 60, backgroundColor: "#05090F", opacity: 0.7 },
});

/* ══════════════════════════════════════════════════════════════
   7. AUTOMATIONS SCREEN — אוטומציות
══════════════════════════════════════════════════════════════ */
const AUTO_DEFS = [
  { icon: "🌙", name: "לילה טוב",        desc: "כיבוי אורות, נעילת דלתות, הפעלת אקווה",  defaultOn: true  },
  { icon: "🏠", name: "יציאה מהבית",     desc: "כיבוי אורות, נעילה ופעולות אקווה",        defaultOn: true  },
  { icon: "☀️", name: "בוקר טוב",        desc: "פתיחת תריסים, הגבת אורות",               defaultOn: true  },
  { icon: "🔙", name: "חזרה הביתה",      desc: "ביטול אזעקה והדלקת אורות",               defaultOn: true  },
];

function AutomationsScreen({ onBack }) {
  const [filter, setFilter] = useState("כל האוטומציות");
  const [enabled, setEnabled] = useState(AUTO_DEFS.map(a => a.defaultOn));

  function toggle(i) { setEnabled(prev => prev.map((v, j) => j === i ? !v : v)); }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <BackBar onBack={onBack} title="אוטומציות" />
      <FilterTabs tabs={["המלצות", "כל האוטומציות"]} selected={filter} onSelect={setFilter} />

      <ScrollView contentContainerStyle={{ padding: 14, paddingBottom: 28, gap: 10 }} showsVerticalScrollIndicator={false}>
        {AUTO_DEFS.map((rule, i) => (
          <Card key={i}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 12 }}>
              {/* Toggle on left */}
              <Switch
                value={enabled[i]}
                onValueChange={() => toggle(i)}
                trackColor={{ false: C.border, true: C.blue }}
                thumbColor={"#fff"}
              />
              {/* Text */}
              <View style={{ flex: 1 }}>
                <Text style={{ color: C.text, fontSize: 15, fontWeight: "700", textAlign: "right", marginBottom: 3 }}>
                  {rule.name}
                </Text>
                <Text style={{ color: C.sub, fontSize: 12, textAlign: "right" }}>
                  {rule.desc}
                </Text>
              </View>
              {/* Icon circle */}
              <View style={{ width: 44, height: 44, borderRadius: 12, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" }}>
                <Text style={{ fontSize: 22 }}>{rule.icon}</Text>
              </View>
            </View>
          </Card>
        ))}

        {/* Add button */}
        <TouchableOpacity style={{ backgroundColor: C.blue, borderRadius: 14, height: 52, alignItems: "center", justifyContent: "center", marginTop: 6 }}>
          <Text style={{ color: "#fff", fontWeight: "700", fontSize: 15 }}>+ הוסף אוטומציה</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}

/* ══════════════════════════════════════════════════════════════
   8. ENERGY SCREEN — אנרגיה
══════════════════════════════════════════════════════════════ */
const BAR_DATA = [
  { label: "1.5",  val: 32 },
  { label: "8.5",  val: 45 },
  { label: "15.5", val: 38 },
  { label: "22.5", val: 60 },
  { label: "29.5", val: 42 },
];
const MAX_BAR = Math.max(...BAR_DATA.map(d => d.val));
const BAR_H   = 90;

const DEVICES = [
  { icon: "❄️", label: "מזגן",         watt: "1200W", color: C.green   },
  { icon: "🔥", label: "תנור",          watt: "800W",  color: C.card2   },
  { icon: "🔌", label: "מכונת כביסה",  watt: "480W",  color: C.card2   },
];

function EnergyScreen({ onBack }) {
  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <BackBar onBack={onBack} title="אנרגיה" />
      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 28, gap: 14 }} showsVerticalScrollIndicator={false}>

        {/* Monthly hero */}
        <Card>
          <Text style={{ color: C.sub, fontSize: 13, textAlign: "right", marginBottom: 4 }}>צריכה חודשית</Text>
          <Text style={{ color: C.text, fontSize: 38, fontWeight: "900", textAlign: "right", marginBottom: 4 }}>245 kWh</Text>
          <View style={{ flexDirection: "row", justifyContent: "flex-end", alignItems: "center", gap: 4 }}>
            <Text style={{ color: C.green, fontSize: 13, fontWeight: "600" }}>-12%</Text>
            <Text style={{ color: C.green, fontSize: 13 }}>מהחודש הקודם ▼</Text>
          </View>

          {/* Bar chart */}
          <View style={{ flexDirection: "row", alignItems: "flex-end", justifyContent: "space-between", marginTop: 20, height: BAR_H + 24 }}>
            {BAR_DATA.map((d, i) => {
              const h = Math.max(10, Math.round((d.val / MAX_BAR) * BAR_H));
              const isTall = d.val === MAX_BAR;
              return (
                <View key={i} style={{ alignItems: "center", flex: 1 }}>
                  <View style={{ flex: 1, justifyContent: "flex-end" }}>
                    <View style={{
                      width: 28, height: h,
                      backgroundColor: isTall ? C.blueGlow : C.blue,
                      borderRadius: 6, opacity: isTall ? 1 : 0.5,
                    }} />
                  </View>
                  <Text style={{ color: C.sub, fontSize: 9, marginTop: 6 }}>{d.label}</Text>
                </View>
              );
            })}
          </View>
        </Card>

        {/* Active devices */}
        <Text style={{ color: C.text, fontSize: 15, fontWeight: "700", textAlign: "right" }}>מכשירים פעילים</Text>
        <Card>
          {DEVICES.map((dev, i) => (
            <View key={i}>
              <View style={{ flexDirection: "row", alignItems: "center", paddingVertical: 10 }}>
                <Text style={{ color: C.blue, fontSize: 15, fontWeight: "700" }}>{dev.watt}</Text>
                <View style={{ flex: 1 }} />
                <Text style={{ color: C.text, fontSize: 14, fontWeight: "600", marginRight: 10 }}>{dev.label}</Text>
                <View style={{ width: 36, height: 36, borderRadius: 10, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" }}>
                  <Text style={{ fontSize: 18 }}>{dev.icon}</Text>
                </View>
              </View>
              {i < DEVICES.length - 1 && <Divider />}
            </View>
          ))}
        </Card>

        {/* Full report button */}
        <TouchableOpacity style={{ backgroundColor: C.blue, borderRadius: 14, height: 52, alignItems: "center", justifyContent: "center" }}>
          <Text style={{ color: "#fff", fontWeight: "700", fontSize: 15 }}>צפה בדוח מלא</Text>
        </TouchableOpacity>

      </ScrollView>
    </SafeAreaView>
  );
}

/* ══════════════════════════════════════════════════════════════
   9. ALERTS SCREEN — התראות
══════════════════════════════════════════════════════════════ */
const ALERT_LIST = [
  { icon: "🔥", text: "זיהתה תנועה בחצר",           time: "לפני 2 דקות",  color: C.red,   thumbnail: "🌃" },
  { icon: "🔔", text: "הדלת הראשית נפתחה",         time: "לפני 10 דקות", color: C.orange, thumbnail: "🚪" },
  { icon: "😊", text: "חיישן עשן - תקין",           time: "לפני 15 דקות", color: C.green, thumbnail: null  },
  { icon: "🌡", text: "טמפרטורה גבוהה בחדר",       time: "לפני 30 דקות", color: C.orange, thumbnail: null, extra: "28°C" },
  { icon: "💡", text: "ביצוע אוטומציה: לילה טוב",  time: "לפני שעה",     color: C.blue,  thumbnail: null  },
];

function AlertsScreen({ onBack }) {
  const [filter, setFilter] = useState("הכל");
  const [read, setRead] = useState(ALERT_LIST.map(() => false));

  function markAll() { setRead(ALERT_LIST.map(() => true)); }

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <BackBar onBack={onBack} title="התראות" />

      {/* Filter */}
      <View style={{ paddingHorizontal: 16, paddingTop: 10, paddingBottom: 4, flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
        <TouchableOpacity style={{ backgroundColor: C.blue + "22", borderRadius: 20, paddingHorizontal: 16, paddingVertical: 7, borderWidth: 1, borderColor: C.blue }}>
          <Text style={{ color: C.blue, fontWeight: "600", fontSize: 13 }}>הכל</Text>
        </TouchableOpacity>
        <TouchableOpacity hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}>
          <Text style={{ color: C.sub, fontSize: 22 }}>⋮</Text>
        </TouchableOpacity>
      </View>

      <ScrollView contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 28 }} showsVerticalScrollIndicator={false}>
        {ALERT_LIST.map((alert, i) => (
          <TouchableOpacity
            key={i}
            onPress={() => setRead(prev => prev.map((v, j) => j === i ? true : v))}
            activeOpacity={0.8}
          >
            <View style={[alt.row, { opacity: read[i] ? 0.55 : 1 }]}>
              {/* Thumbnail / Extra */}
              <View style={alt.thumb}>
                {alert.thumbnail ? (
                  <Text style={{ fontSize: 28 }}>{alert.thumbnail}</Text>
                ) : alert.extra ? (
                  <Text style={{ color: C.orange, fontWeight: "700", fontSize: 15 }}>{alert.extra}</Text>
                ) : (
                  <View style={{ width: 24, height: 24, borderRadius: 12, backgroundColor: alert.color + "33", alignItems: "center", justifyContent: "center" }}>
                    <Text style={{ fontSize: 12 }}>{alert.icon}</Text>
                  </View>
                )}
              </View>

              <View style={{ flex: 1 }}>
                <Text style={[alt.alertText, { textAlign: "right" }]}>{alert.text}</Text>
                <Text style={[alt.alertTime, { textAlign: "right" }]}>{alert.time}</Text>
              </View>

              {/* Icon */}
              <View style={[alt.iconWrap, { backgroundColor: alert.color + "20" }]}>
                <Text style={{ fontSize: 20 }}>{alert.icon}</Text>
              </View>

              {!read[i] && <View style={[alt.unreadDot, { backgroundColor: alert.color }]} />}
            </View>
            {i < ALERT_LIST.length - 1 && <Divider />}
          </TouchableOpacity>
        ))}

        {/* Mark all read */}
        <TouchableOpacity
          style={{ backgroundColor: C.card2, borderRadius: 14, height: 50, alignItems: "center", justifyContent: "center", marginTop: 16, borderWidth: 1, borderColor: C.border }}
          onPress={markAll}
        >
          <Text style={{ color: C.text, fontWeight: "600", fontSize: 14 }}>סמן הכל כנקרא</Text>
        </TouchableOpacity>
      </ScrollView>
    </SafeAreaView>
  );
}
const alt = StyleSheet.create({
  row:       { flexDirection: "row", alignItems: "center", paddingVertical: 12, gap: 10 },
  iconWrap:  { width: 40, height: 40, borderRadius: 12, alignItems: "center", justifyContent: "center" },
  thumb:     { width: 52, height: 40, borderRadius: 8, backgroundColor: C.card2, alignItems: "center", justifyContent: "center", overflow: "hidden" },
  alertText: { color: C.text, fontSize: 13, fontWeight: "600", marginBottom: 3 },
  alertTime: { color: C.sub, fontSize: 11 },
  unreadDot: { width: 8, height: 8, borderRadius: 4, position: "absolute", top: 14, left: 0 },
});

/* ══════════════════════════════════════════════════════════════
   10. ADD DEVICE SCREEN — הוספת מכשיר
══════════════════════════════════════════════════════════════ */
const FOUND_DEVICES = [
  { icon: "📷", name: "Camera Outdoor Pro" },
  { icon: "🔒", name: "Door Sensor"        },
];

function AddDeviceScreen({ onBack }) {
  const [added, setAdded] = useState({});
  const [scanning, setScanning] = useState(true);

  return (
    <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
      <StatusBar barStyle="light-content" backgroundColor={C.bg} />
      <BackBar onBack={onBack} title="הוסף מכשיר" />

      <ScrollView contentContainerStyle={{ padding: 16, paddingBottom: 28 }} showsVerticalScrollIndicator={false}>

        {/* Scanning animation (static concentric rings) */}
        <View style={{ alignItems: "center", paddingVertical: 28 }}>
          {/* Rings */}
          <View style={add.ring4}>
            <View style={add.ring3}>
              <View style={add.ring2}>
                <View style={add.ring1}>
                  {scanning && <ActivityIndicator size="small" color={C.blue} />}
                </View>
              </View>
            </View>
          </View>

          <Text style={{ color: C.text, fontSize: 18, fontWeight: "700", marginTop: 20, marginBottom: 8 }}>
            מחפש מכשירים...
          </Text>
          <Text style={{ color: C.sub, fontSize: 13, textAlign: "center", lineHeight: 20, paddingHorizontal: 30 }}>
            ו/א שהמכשיר במצב צימוד ושמחובר לחשמל
          </Text>

          {/* Pagination dots */}
          <View style={{ flexDirection: "row", gap: 6, marginTop: 16 }}>
            {[0, 1, 2].map(i => (
              <View key={i} style={{ width: i === 1 ? 20 : 8, height: 8, borderRadius: 4, backgroundColor: i === 1 ? C.blue : C.border }} />
            ))}
          </View>
        </View>

        {/* Found devices */}
        <Text style={{ color: C.text, fontSize: 15, fontWeight: "700", textAlign: "right", marginBottom: 12 }}>
          מכשירים שנמצאו
        </Text>
        {FOUND_DEVICES.map((dev) => (
          <Card key={dev.name} style={{ flexDirection: "row", alignItems: "center", marginBottom: 10, gap: 12 }}>
            <TouchableOpacity
              style={[add.addBtn, { backgroundColor: added[dev.name] ? C.green : C.blue }]}
              onPress={() => setAdded(prev => ({ ...prev, [dev.name]: true }))}
              activeOpacity={0.85}
            >
              <Text style={{ color: "#fff", fontWeight: "700", fontSize: 13 }}>
                {added[dev.name] ? "✓" : "הוסף"}
              </Text>
            </TouchableOpacity>
            <View style={{ flex: 1 }}>
              <Text style={{ color: C.text, fontSize: 14, fontWeight: "600", textAlign: "right" }}>{dev.name}</Text>
            </View>
            <View style={add.devIcon}>
              <Text style={{ fontSize: 22 }}>{dev.icon}</Text>
            </View>
          </Card>
        ))}

      </ScrollView>
    </SafeAreaView>
  );
}
const add = StyleSheet.create({
  ring4:  { width: 200, height: 200, borderRadius: 100, borderWidth: 1, borderColor: C.blue + "18", alignItems: "center", justifyContent: "center" },
  ring3:  { width: 160, height: 160, borderRadius: 80,  borderWidth: 1, borderColor: C.blue + "30", alignItems: "center", justifyContent: "center" },
  ring2:  { width: 120, height: 120, borderRadius: 60,  borderWidth: 1.5, borderColor: C.blue + "55", alignItems: "center", justifyContent: "center" },
  ring1:  { width: 80,  height: 80,  borderRadius: 40,  borderWidth: 2, borderColor: C.blue, backgroundColor: C.blue + "18", alignItems: "center", justifyContent: "center" },
  addBtn: { borderRadius: 10, paddingHorizontal: 14, paddingVertical: 8 },
  devIcon:{ width: 44, height: 44, borderRadius: 12, backgroundColor: C.card2, alignItems: "center", justifyContent: "center" },
});

/* ══════════════════════════════════════════════════════════════
   TAB WRAPPERS
══════════════════════════════════════════════════════════════ */
function HomeTab() {
  const [screen, setScreen] = useState("dashboard");

  if (screen === "cameras")     return <CamerasScreen     onBack={() => setScreen("dashboard")} />;
  if (screen === "automations") return <AutomationsScreen onBack={() => setScreen("dashboard")} />;
  if (screen === "energy")      return <EnergyScreen      onBack={() => setScreen("dashboard")} />;
  if (screen === "alerts")      return <AlertsScreen      onBack={() => setScreen("dashboard")} />;

  return <Dashboard onNavigate={setScreen} />;
}

function SecurityTab() {
  const [screen, setScreen] = useState("security");

  if (screen === "cameras") return <CamerasScreen onBack={() => setScreen("security")} />;

  return <SecurityScreen onNavigate={setScreen} />;
}

function ProfileTab({ onLogout }) {
  const [screen, setScreen] = useState("profile");

  if (screen === "addDevice") return <AddDeviceScreen onBack={() => setScreen("profile")} />;

  return <ProfileScreen onLogout={onLogout} onNavigate={setScreen} />;
}

/* ══════════════════════════════════════════════════════════════
   APP ROOT
══════════════════════════════════════════════════════════════ */
function AppInner() {
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
              height: 62,
              paddingBottom: 8,
              paddingTop: 4,
            },
            tabBarActiveTintColor:   C.blue,
            tabBarInactiveTintColor: C.sub,
            tabBarLabelStyle: { fontSize: 11, fontWeight: "700" },
            tabBarIcon: ({ focused }) => {
              const icons = { "בית": "🏠", "AI": "🤖", "אבטחה": "🛡️", "פרופיל": "👤" };
              return (
                <View style={{
                  alignItems: "center", justifyContent: "center",
                  width: 34, height: 34, borderRadius: 10,
                  backgroundColor: focused ? C.blue + "22" : "transparent",
                }}>
                  <Text style={{ fontSize: 18, opacity: focused ? 1 : 0.5 }}>{icons[route.name]}</Text>
                </View>
              );
            },
          })}
        >
          <Tab.Screen name="בית"    component={HomeTab} />
          <Tab.Screen name="AI"     component={AIScreen} />
          <Tab.Screen name="אבטחה"  component={SecurityTab} />
          <Tab.Screen name="פרופיל" children={() => <ProfileTab onLogout={() => setLoggedIn(false)} />} />
        </Tab.Navigator>
      </NavigationContainer>
    </MqttProvider>
  );
}

export default function App() {
  return (
    <LanguageProvider>
      <AppInner />
    </LanguageProvider>
  );
}
