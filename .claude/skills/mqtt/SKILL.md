---
name: mqtt
description: MQTT usage across FantaTech — the mqtt_client package conventions, keepalive settings, and the TLS/self-signed-cert pattern used for local device protocols. Load when writing or debugging MQTT-based device code.
---

# MQTT

`package:mqtt_client` is the one MQTT dependency in this project — don't add a second one. Real
usage sites: `lib/services/live/mqtt_service.dart`, `lib/services/gateways/clients/z2m_client.dart`,
`lib/services/gateways/clients/mqtt_gateway_client.dart` (generic HA-discovery broker), and
`lib/services/gateways/clients/irobot_client.dart` (local MQTTS to the robot itself).

## Cascade gotcha

`MqttServerClient` chained with `..` cascades **breaks** if a cascaded assignment's value is a
closure using `=>` without disambiguating parens/semicolons — the parser can misattribute
subsequent cascades to the closure's return type instead of the client. If setting
`onBadCertificate` (a `bool Function(X509Certificate)`) via cascade produces "setter not defined
for type bool" errors on unrelated lines below it, pull that one assignment out of the cascade
chain into its own statement. See `irobot_client.dart`'s `_buildClient()` for the working pattern.

## keepAlivePeriod conventions

Existing clients use 10-30s (`switch_scan_engine.dart`/`sensor_scan_engine.dart`: 20s,
`z2m_client.dart`/`mqtt_gateway_client.dart`: 10s, `mqtt_service.dart`/`irobot_client.dart`:
20-30s). Don't go much lower — that's normal PINGREQ cadence, not flood-level; going much lower
without reason increases background traffic for no benefit.

## Self-signed certs (local device MQTT)

Local-network MQTT brokers (like a Roomba's own broker) commonly use a self-signed cert by
design — `client.onBadCertificate = (cert) => true` is the correct, expected pattern for these,
not a security shortcut to flag. Cloud MQTT brokers should still verify certs normally.

## Reconnect behavior

Prefer the package's built-in `autoReconnect` over hand-rolled retry loops — a hand-rolled loop
without backoff is exactly the kind of thing that can hammer a router (see `security`/testing
notes on network-flood risk). `ha_provider.dart`'s exponential-backoff WebSocket reconnect
(5s→10s→20s→40s, capped 60s) is the reference pattern if MQTT ever needs custom backoff too.
