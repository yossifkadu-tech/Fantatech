/**
 * Web entry — renders the FantaTech Dashboard directly inside expo-router.
 * We skip NavigationContainer (expo-router owns it) and show the main screen.
 */
import React, { useState } from "react";
import {
  View, Text, StyleSheet, TouchableOpacity,
  ScrollView, SafeAreaView, StatusBar, Switch,
} from "react-native";
import { MqttProvider, useMqtt } from "../context/MqttContext";

const C = {
  bg: "#0D1117", card: "#161B27", card2: "#1E2535",
  blue: "#2563EB", blueGlow: "#3B82F6", green: "#22C55E",
  red: "#EF4444", orange: "#F97316", text: "#F5F5F7",
  sub: "#8892A4", border: "#2A3044", navBg: "#111827",
};

function Card({ children, style }: any) {
  return (
    <View style={[{ backgroundColor: C.card, borderRadius: 18, padding: 16, borderWidth: 1, borderColor: C.border, marginBottom: 12 }, style]}>
      {children}
    </View>
  );
}

function Header({ tab, setTab }: any) {
  const tabs = ["🏠 בית", "🤖 AI", "🛡️ אבטחה", "👤 פרופיל"];
  return (
    <View style={{ backgroundColor: C.navBg, borderBottomWidth: 1, borderBottomColor: C.border }}>
      <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", paddingHorizontal: 20, paddingVertical: 14 }}>
        <Text style={{ fontSize: 22, fontWeight: "800", color: C.text }}>
          Fanta<Text style={{ color: C.blue }}>Tech</Text>
        </Text>
        <Text style={{ fontSize: 20 }}>🔔</Text>
      </View>
      <View style={{ flexDirection: "row", borderTopWidth: 1, borderTopColor: C.border }}>
        {tabs.map((t, i) => (
          <TouchableOpacity key={i} onPress={() => setTab(i)}
            style={{ flex: 1, alignItems: "center", paddingVertical: 10,
              borderBottomWidth: 2, borderBottomColor: tab === i ? C.blue : "transparent" }}>
            <Text style={{ fontSize: 12, fontWeight: "700", color: tab === i ? C.blue : C.sub }}>{t}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
}

function DashboardScreen() {
  const { alarmActive, lights, ac, toggleLight, setAcPower, setAcTemp, toggleBlinds, blinds } = useMqtt();

  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.bg }} contentContainerStyle={{ padding: 16, paddingBottom: 24 }}>
      {/* Alarm Banner */}
      {alarmActive && (
        <View style={{ backgroundColor: C.red + "22", borderRadius: 14, padding: 14, marginBottom: 12, borderWidth: 1, borderColor: C.red, flexDirection: "row", alignItems: "center", gap: 10 }}>
          <Text style={{ fontSize: 22 }}>🚨</Text>
          <Text style={{ color: C.red, fontWeight: "800", fontSize: 15 }}>אזעקה פעילה!</Text>
        </View>
      )}

      {/* Status Row */}
      <View style={{ flexDirection: "row", gap: 10, marginBottom: 12 }}>
        {[
          { icon: "💡", label: "אורות", val: Object.values(lights).filter(v => v === "ON").length + "/" + Object.keys(lights).length },
          { icon: "❄️", label: "מזגן", val: ac.bedroom === "ON" ? "פועל" : "כבוי" },
          { icon: "🔒", label: "דלת", val: "נעולה" },
          { icon: "📷", label: "מצלמות", val: "2 פעיל" },
        ].map((s, i) => (
          <View key={i} style={{ flex: 1, backgroundColor: C.card2, borderRadius: 14, padding: 10, alignItems: "center", borderWidth: 1, borderColor: C.border }}>
            <Text style={{ fontSize: 20 }}>{s.icon}</Text>
            <Text style={{ color: C.text, fontSize: 11, fontWeight: "700", marginTop: 4 }}>{s.val}</Text>
            <Text style={{ color: C.sub, fontSize: 10 }}>{s.label}</Text>
          </View>
        ))}
      </View>

      {/* Lights Card */}
      <Card>
        <Text style={{ color: C.text, fontWeight: "700", fontSize: 15, marginBottom: 12 }}>💡 תאורה</Text>
        {Object.entries(lights).map(([room, state]) => (
          <View key={room} style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between", marginBottom: 10 }}>
            <Text style={{ color: C.sub, fontSize: 14 }}>
              {room === "livingroom" ? "🛋️ סלון" : room === "bedroom" ? "🛏️ חדר שינה" : "🍳 מטבח"}
            </Text>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 8 }}>
              <View style={{ width: 8, height: 8, borderRadius: 4, backgroundColor: state === "ON" ? C.green : C.sub }} />
              <Switch
                value={state === "ON"}
                onValueChange={() => toggleLight(room)}
                trackColor={{ false: C.border, true: C.blue + "88" }}
                thumbColor={state === "ON" ? C.blue : C.sub}
              />
            </View>
          </View>
        ))}
      </Card>

      {/* AC Card */}
      <Card>
        <View style={{ flexDirection: "row", justifyContent: "space-between", alignItems: "center", marginBottom: 8 }}>
          <Text style={{ color: C.text, fontWeight: "700", fontSize: 15 }}>❄️ מיזוג — חדר שינה</Text>
          <Switch
            value={ac.bedroom === "ON"}
            onValueChange={(v) => setAcPower("bedroom", v ? "ON" : "OFF")}
            trackColor={{ false: C.border, true: C.blue + "88" }}
            thumbColor={ac.bedroom === "ON" ? C.blue : C.sub}
          />
        </View>
        <View style={{ flexDirection: "row", gap: 8 }}>
          {[18, 20, 22, 24, 26].map(t => (
            <TouchableOpacity key={t} onPress={() => setAcTemp("bedroom", t)}
              style={{ flex: 1, backgroundColor: C.card2, borderRadius: 10, paddingVertical: 8, alignItems: "center", borderWidth: 1, borderColor: C.border }}>
              <Text style={{ color: C.text, fontSize: 13, fontWeight: "700" }}>{t}°</Text>
            </TouchableOpacity>
          ))}
        </View>
      </Card>

      {/* Quick Grid */}
      <Card>
        <Text style={{ color: C.text, fontWeight: "700", fontSize: 15, marginBottom: 12 }}>פעולות מהירות</Text>
        <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 10 }}>
          {[
            { icon: "📷", label: "מצלמות" },
            { icon: "⚡", label: "אנרגיה" },
            { icon: "🤖", label: "אוטומציות" },
            { icon: "🔔", label: "התראות" },
          ].map((item, i) => (
            <View key={i} style={{ width: "22%", alignItems: "center", backgroundColor: C.card2, borderRadius: 14, paddingVertical: 14, borderWidth: 1, borderColor: C.border }}>
              <Text style={{ fontSize: 24 }}>{item.icon}</Text>
              <Text style={{ color: C.sub, fontSize: 11, marginTop: 4 }}>{item.label}</Text>
            </View>
          ))}
        </View>
      </Card>
    </ScrollView>
  );
}

function AIScreen() {
  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.bg }} contentContainerStyle={{ padding: 16 }}>
      <Card>
        <Text style={{ color: C.blue, fontWeight: "800", fontSize: 18, marginBottom: 8 }}>🤖 FantaTech AI</Text>
        <Text style={{ color: C.sub, fontSize: 14, lineHeight: 22 }}>
          העוזר החכם שלך מוכן לעזור בניהול הבית. שאל אותי כל שאלה על המכשירים שלך!
        </Text>
      </Card>
      <View style={{ backgroundColor: C.card2, borderRadius: 16, padding: 14, borderWidth: 1, borderColor: C.border }}>
        <Text style={{ color: C.sub, fontSize: 13 }}>💬 כבה את כל האורות לפני השינה</Text>
      </View>
      <View style={{ backgroundColor: C.card2, borderRadius: 16, padding: 14, borderWidth: 1, borderColor: C.border, marginTop: 8 }}>
        <Text style={{ color: C.sub, fontSize: 13 }}>🌡️ הגדר טמפרטורה אוטומטית ב-22°</Text>
      </View>
    </ScrollView>
  );
}

function SecurityScreen() {
  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.bg }} contentContainerStyle={{ padding: 16 }}>
      <Card>
        <Text style={{ color: C.green, fontWeight: "800", fontSize: 18, marginBottom: 8 }}>🛡️ מצב אבטחה</Text>
        <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
          <View style={{ width: 12, height: 12, borderRadius: 6, backgroundColor: C.green }} />
          <Text style={{ color: C.text, fontSize: 15 }}>הבית מאובטח</Text>
        </View>
      </Card>
      {[
        { icon: "🔒", label: "דלת כניסה", state: "נעולה", color: C.green },
        { icon: "🚪", label: "דלת אחורית", state: "נעולה", color: C.green },
        { icon: "📷", label: "מצלמת סלון", state: "פעילה", color: C.blue },
        { icon: "📷", label: "מצלמת חוץ", state: "פעילה", color: C.blue },
      ].map((item, i) => (
        <Card key={i}>
          <View style={{ flexDirection: "row", alignItems: "center", justifyContent: "space-between" }}>
            <View style={{ flexDirection: "row", alignItems: "center", gap: 10 }}>
              <Text style={{ fontSize: 22 }}>{item.icon}</Text>
              <Text style={{ color: C.text, fontSize: 14, fontWeight: "600" }}>{item.label}</Text>
            </View>
            <View style={{ backgroundColor: item.color + "22", paddingHorizontal: 10, paddingVertical: 4, borderRadius: 20 }}>
              <Text style={{ color: item.color, fontSize: 12, fontWeight: "700" }}>{item.state}</Text>
            </View>
          </View>
        </Card>
      ))}
    </ScrollView>
  );
}

function ProfileScreen() {
  return (
    <ScrollView style={{ flex: 1, backgroundColor: C.bg }} contentContainerStyle={{ padding: 16 }}>
      <Card style={{ alignItems: "center", paddingVertical: 24 }}>
        <View style={{ width: 72, height: 72, borderRadius: 36, backgroundColor: C.blue + "33", alignItems: "center", justifyContent: "center", marginBottom: 12, borderWidth: 2, borderColor: C.blue }}>
          <Text style={{ fontSize: 32 }}>👤</Text>
        </View>
        <Text style={{ color: C.text, fontSize: 18, fontWeight: "800" }}>יוסי</Text>
        <Text style={{ color: C.sub, fontSize: 13, marginTop: 4 }}>yossi.fkadu@gmail.com</Text>
      </Card>
      {[
        { icon: "🏠", label: "הגדרות בית" },
        { icon: "🔔", label: "התראות" },
        { icon: "🌐", label: "שרת MQTT" },
        { icon: "🔐", label: "אבטחה וסיסמאות" },
        { icon: "📱", label: "אודות האפליקציה" },
      ].map((item, i) => (
        <Card key={i}>
          <View style={{ flexDirection: "row", alignItems: "center", gap: 14 }}>
            <Text style={{ fontSize: 20 }}>{item.icon}</Text>
            <Text style={{ color: C.text, fontSize: 15, fontWeight: "600" }}>{item.label}</Text>
            <Text style={{ color: C.sub, marginLeft: "auto" }}>›</Text>
          </View>
        </Card>
      ))}
    </ScrollView>
  );
}

export default function WebApp() {
  const [tab, setTab] = useState(0);
  const screens = [DashboardScreen, AIScreen, SecurityScreen, ProfileScreen];
  const Screen = screens[tab];

  return (
    <MqttProvider>
      <SafeAreaView style={{ flex: 1, backgroundColor: C.bg }}>
        <StatusBar barStyle="light-content" backgroundColor={C.bg} />
        <Header tab={tab} setTab={setTab} />
        <Screen />
      </SafeAreaView>
    </MqttProvider>
  );
}
