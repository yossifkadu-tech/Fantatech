import React from "react";
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
} from "react-native";
import { NavigationContainer } from "@react-navigation/native";
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import { MqttProvider, useMqtt } from "./context/MqttContext";

const Tab = createBottomTabNavigator();

/* ---------- DASHBOARD ---------- */
function Dashboard() {
  const { connected, alarmActive, turnAllOff, triggerAlarm, disarmAlarm } =
    useMqtt();

  const alarm = alarmActive;

  return (
    <View style={dash.screen}>
      {/* Brand */}
      <Text style={dash.brand}>FantaTech</Text>

      {/* Status circle */}
      <View style={[dash.circle, alarm ? dash.circleAlarm : dash.circleOk]}>
        <Text style={dash.circleIcon}>{alarm ? "🚨" : "🏠"}</Text>
        <Text style={dash.circleLabel}>{alarm ? "אזעקה" : "מאובטח"}</Text>
      </View>

      {/* Connection dot */}
      <Text style={[dash.dot, connected ? dash.dotOn : dash.dotOff]}>
        {connected ? "● מחובר" : "○ מנותק"}
      </Text>

      {/* Actions */}
      <View style={dash.actions}>
        <TouchableOpacity style={dash.btnSecondary} onPress={turnAllOff}>
          <Text style={dash.btnText}>כיבוי הכל</Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[dash.btnPrimary, alarm && dash.btnAlarm]}
          onPress={alarm ? disarmAlarm : triggerAlarm}
        >
          <Text style={dash.btnText}>
            {alarm ? "בטל אזעקה" : "אזעקה"}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

/* ---------- SMART HOME ---------- */
function SmartHome() {
  const { lights, ac, blinds, toggleLight, setAcPower, setAcTemp, toggleBlinds } =
    useMqtt();

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>בית חכם</Text>

      <TouchableOpacity
        style={styles.card}
        onPress={() => toggleLight("livingroom")}
      >
        <Text style={styles.cardText}>
          💡 תאורה - סלון{" "}
          <Text style={lights.livingroom === "ON" ? styles.on : styles.off}>
            [{lights.livingroom === "ON" ? "דלוק" : "כבוי"}]
          </Text>
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.card}
        onPress={() => toggleLight("bedroom")}
      >
        <Text style={styles.cardText}>
          💡 תאורה - חדר שינה{" "}
          <Text style={lights.bedroom === "ON" ? styles.on : styles.off}>
            [{lights.bedroom === "ON" ? "דלוק" : "כבוי"}]
          </Text>
        </Text>
      </TouchableOpacity>

      <View style={styles.card}>
        <Text style={styles.cardText}>
          🌡 מזגן - חדר שינה{" "}
          <Text style={ac.bedroom.on ? styles.on : styles.off}>
            [{ac.bedroom.on ? `פועל ${ac.bedroom.temp}°` : "כבוי"}]
          </Text>
        </Text>
        <View style={styles.row}>
          <TouchableOpacity
            style={styles.smallBtn}
            onPress={() => setAcPower("bedroom", !ac.bedroom.on)}
          >
            <Text style={styles.buttonText}>
              {ac.bedroom.on ? "כבה" : "הדלק"}
            </Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.smallBtn}
            onPress={() => setAcTemp("bedroom", ac.bedroom.temp - 1)}
          >
            <Text style={styles.buttonText}>▼</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.smallBtn}
            onPress={() => setAcTemp("bedroom", ac.bedroom.temp + 1)}
          >
            <Text style={styles.buttonText}>▲</Text>
          </TouchableOpacity>
        </View>
      </View>

      <TouchableOpacity
        style={styles.card}
        onPress={() => toggleBlinds("kitchen")}
      >
        <Text style={styles.cardText}>
          🪟 תריסים - מטבח{" "}
          <Text style={blinds.kitchen === "OPEN" ? styles.on : styles.off}>
            [{blinds.kitchen === "OPEN" ? "פתוח" : "סגור"}]
          </Text>
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

/* ---------- SECURITY ---------- */
function Security() {
  const { locks, alarmActive, toggleLock, triggerAlarm, disarmAlarm } =
    useMqtt();

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>אבטחה</Text>

      <View style={styles.card}>
        <Text style={styles.cardText}>
          🔐 מצב מערכת:{" "}
          <Text style={alarmActive ? styles.danger : styles.on}>
            {alarmActive ? "אזעקה פעילה" : "פעיל"}
          </Text>
        </Text>
      </View>

      <TouchableOpacity
        style={styles.card}
        onPress={() => toggleLock("entrance")}
      >
        <Text style={styles.cardText}>
          🚪 דלת כניסה:{" "}
          <Text
            style={locks.entrance === "LOCK" ? styles.on : styles.warning}
          >
            {locks.entrance === "LOCK" ? "נעולה" : "פתוחה"}
          </Text>
        </Text>
      </TouchableOpacity>

      <TouchableOpacity
        style={styles.emergency}
        onPress={alarmActive ? disarmAlarm : triggerAlarm}
      >
        <Text style={styles.buttonText}>
          {alarmActive ? "🔕 בטל חירום" : "🚨 הפעל חירום"}
        </Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

/* ---------- CAMERAS ---------- */
function Cameras() {
  const { cameras } = useMqtt();

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>מצלמות</Text>

      <View style={styles.card}>
        <Text style={styles.cardText}>
          📷 מצלמת סלון{" "}
          <Text
            style={cameras.salon === "ONLINE" ? styles.on : styles.off}
          >
            [{cameras.salon === "ONLINE" ? "LIVE" : "לא מחובר"}]
          </Text>
        </Text>
      </View>

      <View style={styles.card}>
        <Text style={styles.cardText}>
          📷 מצלמת חוץ{" "}
          <Text
            style={cameras.exterior === "ONLINE" ? styles.on : styles.off}
          >
            [{cameras.exterior === "ONLINE" ? "LIVE" : "לא מחובר"}]
          </Text>
        </Text>
      </View>
    </ScrollView>
  );
}

/* ---------- ALERTS ---------- */
function Alerts() {
  const { alerts } = useMqtt();

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.title}>התראות</Text>

      {alerts.length === 0 ? (
        <View style={styles.card}>
          <Text style={styles.cardText}>אין התראות חדשות</Text>
        </View>
      ) : (
        alerts.map((a, i) => (
          <View key={i} style={styles.card}>
            <Text style={styles.cardText}>
              🔔 {a.message}
            </Text>
            {a.ts && (
              <Text style={styles.timestamp}>
                {new Date(a.ts).toLocaleTimeString("he-IL")}
              </Text>
            )}
          </View>
        ))
      )}
    </ScrollView>
  );
}

/* ---------- APP ---------- */
export default function App() {
  return (
    <MqttProvider>
      <NavigationContainer>
        <Tab.Navigator
          screenOptions={{
            tabBarStyle: { backgroundColor: "#0B0F1A" },
            tabBarActiveTintColor: "#1E6BFF",
            tabBarInactiveTintColor: "#555",
            headerStyle: { backgroundColor: "#0B0F1A" },
            headerTintColor: "#fff",
          }}
        >
          <Tab.Screen name="Dashboard" component={Dashboard} />
          <Tab.Screen name="בית חכם" component={SmartHome} />
          <Tab.Screen name="אבטחה" component={Security} />
          <Tab.Screen name="מצלמות" component={Cameras} />
          <Tab.Screen name="התראות" component={Alerts} />
        </Tab.Navigator>
      </NavigationContainer>
    </MqttProvider>
  );
}

/* ---------- STYLES ---------- */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0B0F1A",
    padding: 20,
  },
  title: {
    fontSize: 28,
    color: "#fff",
    fontWeight: "bold",
    marginTop: 10,
  },
  subtitle: {
    color: "#aaa",
    marginBottom: 20,
  },
  card: {
    backgroundColor: "#1A2233",
    padding: 15,
    borderRadius: 12,
    marginVertical: 8,
  },
  cardTitle: {
    color: "#fff",
    fontSize: 16,
    fontWeight: "bold",
  },
  cardText: {
    color: "#fff",
    fontSize: 15,
  },
  status: {
    color: "#20E3A2",
    marginTop: 5,
    fontSize: 16,
  },
  timestamp: {
    color: "#666",
    fontSize: 11,
    marginTop: 4,
  },
  row: {
    flexDirection: "row",
    justifyContent: "space-between",
    marginTop: 10,
  },
  button: {
    backgroundColor: "#1E6BFF",
    padding: 12,
    borderRadius: 10,
    flex: 1,
    marginRight: 10,
    alignItems: "center",
  },
  smallBtn: {
    backgroundColor: "#1E6BFF",
    paddingVertical: 6,
    paddingHorizontal: 14,
    borderRadius: 8,
    marginRight: 6,
    alignItems: "center",
  },
  danger: {
    backgroundColor: "#FF3B30",
  },
  emergency: {
    backgroundColor: "#FF3B30",
    padding: 15,
    borderRadius: 12,
    marginTop: 20,
    alignItems: "center",
  },
  buttonText: {
    color: "#fff",
    fontWeight: "bold",
  },
  on: { color: "#20E3A2" },
  off: { color: "#888" },
  warning: { color: "#FFB800" },
});

const dash = StyleSheet.create({
  screen: {
    flex: 1,
    backgroundColor: "#0B0F1A",
    alignItems: "center",
    justifyContent: "center",
    paddingHorizontal: 32,
  },
  brand: {
    color: "#fff",
    fontSize: 22,
    fontWeight: "bold",
    letterSpacing: 2,
    marginBottom: 36,
    opacity: 0.7,
  },
  circle: {
    width: 160,
    height: 160,
    borderRadius: 80,
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 20,
  },
  circleOk:    { backgroundColor: "#0d3b2e", borderWidth: 3, borderColor: "#20E3A2" },
  circleAlarm: { backgroundColor: "#3b1a1a", borderWidth: 3, borderColor: "#FF3B30" },
  circleIcon:  { fontSize: 42, marginBottom: 4 },
  circleLabel: { color: "#fff", fontSize: 16, fontWeight: "600" },
  dot: {
    fontSize: 12,
    marginBottom: 40,
  },
  dotOn:  { color: "#20E3A2" },
  dotOff: { color: "#555" },
  actions: {
    flexDirection: "row",
    gap: 12,
    width: "100%",
  },
  btnPrimary: {
    flex: 1,
    backgroundColor: "#1E6BFF",
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: "center",
  },
  btnSecondary: {
    flex: 1,
    backgroundColor: "#1A2233",
    paddingVertical: 14,
    borderRadius: 12,
    alignItems: "center",
  },
  btnAlarm: { backgroundColor: "#FF3B30" },
  btnText:  { color: "#fff", fontWeight: "600", fontSize: 15 },
});
