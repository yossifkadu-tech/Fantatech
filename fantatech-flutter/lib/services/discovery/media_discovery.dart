// ─────────────────────────────────────────────────────────────────────────────
// MediaDiscovery — finds smart speakers / TVs / cast targets on the LAN via mDNS.
//
//   _googlecast._tcp     → Chromecast / Google TV / Nest speakers
//   _airplay._tcp        → Apple TV / AirPlay speakers
//   _raop._tcp           → AirPlay audio (Remote Audio Output Protocol)
//   _sonos._tcp          → Sonos speakers
//   _spotify-connect._tcp→ Spotify Connect endpoints
// ─────────────────────────────────────────────────────────────────────────────
import 'dart:async';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import '../../models/media_module.dart';

class MediaDiscovery {
  static const _services = <String, MediaProtocol>{
    '_googlecast._tcp.local': MediaProtocol.chromecast,
    '_airplay._tcp.local': MediaProtocol.airplay,
    '_raop._tcp.local': MediaProtocol.airplay,
    '_sonos._tcp.local': MediaProtocol.sonos,
    '_spotify-connect._tcp.local': MediaProtocol.spotifyConnect,
  };

  /// Scan the LAN and yield discovered media endpoints.
  Stream<MediaDevice> scan() async* {
    final client = MDnsClient(
      rawDatagramSocketFactory: (dynamic host, int port,
              {bool reuseAddress = true,
              bool reusePort = true,
              int ttl = 255}) =>
          RawDatagramSocket.bind(host, port,
              reuseAddress: reuseAddress, reusePort: reusePort, ttl: ttl),
    );

    try {
      await client.start();
    } catch (_) {
      return; // mDNS unavailable (e.g. permissions / platform)
    }

    final seen = <String>{};

    for (final entry in _services.entries) {
      final serviceType = entry.key;
      final protocol = entry.value;
      try {
        await for (final PtrResourceRecord ptr in client
            .lookup<PtrResourceRecord>(
              ResourceRecordQuery.serverPointer(serviceType),
            )
            .timeout(const Duration(milliseconds: 2000),
                onTimeout: (sink) => sink.close())) {
          final instanceName = ptr.domainName;

          String? host;
          final txt = <String, String>{};

          await for (final SrvResourceRecord srv in client
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(instanceName),
              )
              .timeout(const Duration(milliseconds: 500),
                  onTimeout: (sink) => sink.close())) {
            host = srv.target;
            break;
          }

          await for (final TxtResourceRecord t in client
              .lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(instanceName),
              )
              .timeout(const Duration(milliseconds: 500),
                  onTimeout: (sink) => sink.close())) {
            for (final line in t.text.split('\n')) {
              final i = line.indexOf('=');
              if (i > 0) txt[line.substring(0, i)] = line.substring(i + 1);
            }
            break;
          }

          String? ip;
          if (host != null) {
            await for (final IPAddressResourceRecord a in client
                .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(host),
                )
                .timeout(const Duration(milliseconds: 500),
                    onTimeout: (sink) => sink.close())) {
              ip = a.address.address;
              break;
            }
          }

          final id = 'media_${ip ?? instanceName}';
          if (seen.contains(id)) continue;
          seen.add(id);

          final rawName = instanceName.split('.').first;
          final friendly =
              (txt['fn'] ?? txt['n'] ?? rawName).replaceAll('-', ' ').trim();

          yield MediaDevice(
            id: id,
            name: friendly.isEmpty ? 'Media device' : friendly,
            kind: _kindFor(protocol, friendly),
            protocol: protocol,
            ip: ip,
            manufacturer: _manufacturerFor(protocol, friendly),
            model: txt['md'] ?? txt['model'],
          );
        }
      } catch (_) {
        // non-fatal per service type
      }
    }

    client.stop();
  }

  MediaDeviceKind _kindFor(MediaProtocol p, String name) {
    final n = name.toLowerCase();
    if (n.contains('tv') || n.contains('display') || n.contains('chromecast')) {
      return MediaDeviceKind.tv;
    }
    if (n.contains('soundbar') || n.contains('beam') || n.contains('arc')) {
      return MediaDeviceKind.soundbar;
    }
    if (p == MediaProtocol.sonos ||
        p == MediaProtocol.spotifyConnect ||
        n.contains('speaker') ||
        n.contains('nest') ||
        n.contains('homepod')) {
      return MediaDeviceKind.speaker;
    }
    return MediaDeviceKind.castTarget;
  }

  String? _manufacturerFor(MediaProtocol p, String name) {
    final n = name.toLowerCase();
    if (p == MediaProtocol.chromecast || n.contains('nest') || n.contains('google')) {
      return 'Google';
    }
    if (p == MediaProtocol.airplay || n.contains('apple') || n.contains('homepod')) {
      return 'Apple';
    }
    if (p == MediaProtocol.sonos || n.contains('sonos')) return 'Sonos';
    if (n.contains('samsung')) return 'Samsung';
    if (n.contains('lg')) return 'LG';
    return null;
  }
}
