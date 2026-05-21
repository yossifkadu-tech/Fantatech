import React from "react";
import { View, Text, TouchableOpacity } from "react-native";
import { sendCommand } from "../services/mqttClient";

export default function SmartHome() {
  return (
    <View style={{ flex: 1, padding: 20, backgroundColor: "#0B0F1A" }}>
      <Text style={{ color: "#fff", fontSize: 24 }}>בית חכם</Text>

      <TouchableOpacity
        onPress={() => sendCommand("home/livingroom/light", "ON")}
        style={{
          backgroundColor: "#1E6BFF",
          padding: 15,
          marginTop: 20,
          borderRadius: 10,
        }}
      >
        <Text style={{ color: "#fff" }}>💡 הדלק אור סלון</Text>
      </TouchableOpacity>

      <TouchableOpacity
        onPress={() => sendCommand("home/livingroom/light", "OFF")}
        style={{
          backgroundColor: "#FF3B30",
          padding: 15,
          marginTop: 10,
          borderRadius: 10,
        }}
      >
        <Text style={{ color: "#fff" }}>כבה אור</Text>
      </TouchableOpacity>
    </View>
  );
}
