import mqtt from "mqtt";

// Change this to your Raspberry Pi / mini-PC local IP address
const BROKER_URL = "ws://192.168.1.100:9001";

const client = mqtt.connect(BROKER_URL);

client.on("connect", () => {
  console.log("MQTT Connected");
});

client.on("error", (err) => {
  console.warn("MQTT Error:", err.message);
});

export const sendCommand = (topic, message) => {
  client.publish(topic, message);
};

export default client;
