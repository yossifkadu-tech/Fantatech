// ─────────────────────────────────────────────────────────────────────────────
// MediaScreen — smart-media hub.
//   • Discovered speakers / cast targets (play-pause + volume)
//   • Quick shortcuts: YouTube Music, Spotify
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_state.dart';
import '../../models/media_module.dart';
import '../../services/discovery/media_discovery.dart';
import '../../theme/app_theme.dart';
import '../../utils/haptics.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  bool _scanning = false;

  Future<void> _scan() async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final state = context.read<AppState>();
    try {
      await for (final d in MediaDiscovery().scan()) {
        if (!mounted) break;
        state.addMediaDevice(d);
      }
    } catch (_) {
      // mDNS may be unavailable — silent
    }
    if (mounted) setState(() => _scanning = false);
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      // Try the external app/browser first, then fall back to in-app webview.
      var ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ok = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<AppState>().strings.storeBrowserError),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.read<AppState>().strings.storeBrowserError),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final devices = state.mediaDevices;

    return Scaffold(
      backgroundColor: context.tBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: context.tText2(0.7), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(s.mediaTitle,
            style: TextStyle(
                color: context.tText,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // ── Now Playing ──────────────────────────────────────
            if (state.nowPlaying != null) ...[
              _NowPlayingCard(device: state.nowPlaying!),
              const SizedBox(height: 18),
            ],

            // ── Streaming shortcuts ──────────────────────────────
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.82,
              children: [
                _ServiceCard(
                  label: 'YT Music',
                  icon: Icons.play_circle_fill,
                  color: const Color(0xFFFF0000),
                  onTap: () => _open('https://music.youtube.com'),
                ),
                _ServiceCard(
                  label: 'Spotify',
                  icon: Icons.music_note,
                  color: const Color(0xFF1DB954),
                  onTap: () => _open('https://open.spotify.com'),
                ),
                _ServiceCard(
                  label: 'Apple Music',
                  icon: Icons.library_music,
                  color: const Color(0xFFFA2D48),
                  onTap: () => _open('https://music.apple.com'),
                ),
                _ServiceCard(
                  label: 'YouTube',
                  icon: Icons.smart_display,
                  color: const Color(0xFFFF0000),
                  onTap: () => _open('https://www.youtube.com'),
                ),
                _ServiceCard(
                  label: 'Netflix',
                  icon: Icons.movie_outlined,
                  color: const Color(0xFFE50914),
                  onTap: () => _open('https://www.netflix.com'),
                ),
                _ServiceCard(
                  label: 'Deezer',
                  icon: Icons.graphic_eq,
                  color: const Color(0xFFA238FF),
                  onTap: () => _open('https://www.deezer.com'),
                ),
                _ServiceCard(
                  label: 'Radio',
                  icon: Icons.radio,
                  color: const Color(0xFF00B4D8),
                  onTap: () => _open('https://tunein.com'),
                ),
                _ServiceCard(
                  label: 'Podcasts',
                  icon: Icons.podcasts,
                  color: const Color(0xFF9C7AFF),
                  onTap: () => _open('https://podcasts.google.com'),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Speakers header + scan ───────────────────────────
            Row(
              children: [
                Text(s.mediaSpeakers,
                    style: TextStyle(
                        color: context.tText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _scanning ? null : _scan,
                  icon: _scanning
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primary),
                        )
                      : Icon(Icons.wifi_find_outlined,
                          color: AppColors.primary, size: 18),
                  label: Text(s.mediaScan,
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Group / multi-room (only with 2+ speakers) ───────
            if (devices.length >= 2) ...[
              _GroupCard(),
              const SizedBox(height: 12),
            ],

            if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.speaker_outlined,
                          color: context.tText2(0.2),
                          size: 44),
                      const SizedBox(height: 12),
                      Text(s.mediaNoDevices,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: context.tText2(0.4),
                              fontSize: 13)),
                    ],
                  ),
                ),
              )
            else
              ...devices.map((d) => _SpeakerTile(device: d)),
          ],
        ),
      ),
    );
  }
}

// ── Group / multi-room card ───────────────────────────────────
class _GroupCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final party = state.mediaGroupActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Column(
        children: [
          // Master volume
          Row(
            children: [
              Icon(Icons.tune, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(s.mediaMaster,
                  style: TextStyle(color: context.tText, fontSize: 13)),
              Expanded(
                child: Slider(
                  value: state.masterMediaVolume.toDouble().clamp(0, 100),
                  min: 0,
                  max: 100,
                  activeColor: AppColors.primary,
                  inactiveColor: context.tText2(0.12),
                  onChanged: (v) => state.setAllMediaVolume(v.round()),
                ),
              ),
              SizedBox(
                width: 32,
                child: Text('${state.masterMediaVolume}%',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                        color: context.tText2(0.6),
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Party / Stop all
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: () {
                Haptics.medium();
                if (party) {
                  state.mediaStopAll();
                } else {
                  state.mediaPlayAll();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: party
                      ? null
                      : const LinearGradient(
                          colors: [Color(0xFF7B2FFF), Color(0xFF1A73E8)]),
                  color: party ? context.tText2(0.08) : null,
                  borderRadius: BorderRadius.circular(12),
                  border: party
                      ? Border.all(color: context.tText2(0.2))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(party ? Icons.stop_circle_outlined : Icons.groups,
                        color: context.tText, size: 18),
                    const SizedBox(width: 8),
                    Text(party ? s.mediaStopAll : s.mediaParty,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Now Playing card ──────────────────────────────────────────
class _NowPlayingCard extends StatelessWidget {
  final MediaDevice device;
  const _NowPlayingCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final track = device.track.isEmpty ? '—' : device.track;
    final artist = device.artist.isEmpty ? '' : device.artist;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7B2FFF), Color(0xFF1A73E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B2FFF).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Album art
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.tText2(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.music_note,
                    color: context.tText, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Text(artist,
                        style: TextStyle(
                            color: context.tText2(0.75),
                            fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(
                          device.kind == MediaDeviceKind.tv
                              ? Icons.tv
                              : Icons.speaker,
                          color: context.tText2(0.6),
                          size: 12),
                      const SizedBox(width: 4),
                      Text(device.name,
                          style: TextStyle(
                              color: context.tText2(0.6),
                              fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: device.progress.toDouble().clamp(0, 100),
              min: 0,
              max: 100,
              activeColor: context.tText,
              inactiveColor: context.tText2(0.25),
              onChanged: (v) => state.setMediaProgress(device.id, v.round()),
            ),
          ),

          // Transport controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ctrlBtn(Icons.skip_previous, 32, () {
                Haptics.light();
                state.mediaPrev(device.id);
              }),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () {
                  Haptics.medium();
                  state.toggleMediaPlay(device.id);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: context.tText,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    device.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: const Color(0xFF7B2FFF),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              _ctrlBtn(Icons.skip_next, 32, () {
                Haptics.light();
                state.mediaNext(device.id);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctrlBtn(IconData icon, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: size),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ServiceCard(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: color.withValues(alpha: 0.30), width: 1.2),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.tText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SpeakerTile extends StatelessWidget {
  final MediaDevice device;
  const _SpeakerTile({required this.device});

  IconData get _icon {
    switch (device.kind) {
      case MediaDeviceKind.tv:
        return Icons.tv_outlined;
      case MediaDeviceKind.soundbar:
        return Icons.speaker_group_outlined;
      case MediaDeviceKind.speaker:
        return Icons.speaker_outlined;
      default:
        return Icons.cast_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    const color = AppColors.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.tCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.tText2(0.07)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(_icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.name,
                        style: TextStyle(
                            color: context.tText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(
                      device.manufacturer ?? device.protocol.name,
                      style: TextStyle(
                          color: context.tText2(0.4),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              // TV → remote button
              if (device.kind == MediaDeviceKind.tv) ...[
                GestureDetector(
                  onTap: () => showTvRemote(context, device),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.settings_remote,
                        color: color, size: 20),
                  ),
                ),
              ],
              GestureDetector(
                onTap: () => state.toggleMediaPlay(device.id),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: device.isPlaying
                        ? color
                        : color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    device.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: device.isPlaying ? context.tText : color,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          // Volume
          Row(
            children: [
              Icon(Icons.volume_down,
                  color: context.tText2(0.38), size: 18),
              Expanded(
                child: Slider(
                  value: device.volume.toDouble(),
                  min: 0,
                  max: 100,
                  activeColor: color,
                  inactiveColor: context.tText2(0.12),
                  onChanged: (v) =>
                      state.setMediaVolume(device.id, v.round()),
                ),
              ),
              Icon(Icons.volume_up, color: context.tText2(0.38), size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TV Remote sheet
// ─────────────────────────────────────────────────────────────
void showTvRemote(BuildContext context, MediaDevice device) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TvRemoteSheet(device: device),
  );
}

class _TvRemoteSheet extends StatefulWidget {
  final MediaDevice device;
  const _TvRemoteSheet({required this.device});

  @override
  State<_TvRemoteSheet> createState() => _TvRemoteSheetState();
}

class _TvRemoteSheetState extends State<_TvRemoteSheet> {
  static const _sources = ['TV', 'HDMI 1', 'HDMI 2', 'HDMI 3', 'USB'];
  String _source = 'TV';
  int _channel = 1;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.strings;
    final d = widget.device;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: context.tText2(0.24), borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Icon(Icons.tv, color: AppColors.primary, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${s.tvRemote} · ${d.name}',
                  style: TextStyle(
                      color: context.tText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            GestureDetector(
              onTap: () {
                Haptics.medium();
                state.toggleMediaPlay(d.id);
              },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (d.isPlaying ? AppColors.unsecured : AppColors.secured)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.power_settings_new,
                    color:
                        d.isPlaying ? AppColors.unsecured : AppColors.secured,
                    size: 22),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(s.tvSource,
                style: TextStyle(
                    color: context.tText2(0.5), fontSize: 12)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sources.map((src) {
              final sel = src == _source;
              return GestureDetector(
                onTap: () {
                  Haptics.select();
                  setState(() => _source = src);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : context.tText2(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: sel
                            ? AppColors.primary
                            : context.tText2(0.1)),
                  ),
                  child: Text(src,
                      style: TextStyle(
                          color: sel ? context.tText : context.tText2(0.6),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          _DPad(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _Rocker(
                  label: 'VOL',
                  onUp: () {
                    Haptics.light();
                    state.setMediaVolume(d.id, d.volume + 5);
                  },
                  onDown: () {
                    Haptics.light();
                    state.setMediaVolume(d.id, d.volume - 5);
                  },
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () {
                  Haptics.light();
                  state.setMediaVolume(d.id, 0);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: context.tText2(0.06),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: context.tText2(0.1)),
                  ),
                  child: Icon(Icons.volume_off,
                      color: context.tText2(0.7), size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _Rocker(
                  label: 'CH',
                  onUp: () {
                    Haptics.light();
                    setState(() => _channel++);
                  },
                  onDown: () {
                    Haptics.light();
                    setState(() => _channel = (_channel > 1) ? _channel - 1 : 1);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('${s.tvChannel} $_channel · $_source',
              style: TextStyle(
                  color: context.tText2(0.4), fontSize: 12)),
        ],
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  Widget _arrow(IconData icon, Alignment a) => Align(
        alignment: a,
        child: IconButton(
          icon: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 26),
          onPressed: () => Haptics.select(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: context.tText2(0.04),
        shape: BoxShape.circle,
        border: Border.all(color: context.tText2(0.08)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          _arrow(Icons.keyboard_arrow_up, Alignment.topCenter),
          _arrow(Icons.keyboard_arrow_down, Alignment.bottomCenter),
          _arrow(Icons.keyboard_arrow_left, Alignment.centerLeft),
          _arrow(Icons.keyboard_arrow_right, Alignment.centerRight),
          GestureDetector(
            onTap: () => Haptics.medium(),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Color(0xFF7B2FFF), Color(0xFF1A73E8)]),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('OK',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rocker extends StatelessWidget {
  final String label;
  final VoidCallback onUp;
  final VoidCallback onDown;
  const _Rocker(
      {required this.label, required this.onUp, required this.onDown});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.tText2(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.tText2(0.1)),
      ),
      child: Column(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: context.tText, size: 24),
            onPressed: onUp,
          ),
          Text(label,
              style: TextStyle(
                  color: context.tText2(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w700)),
          IconButton(
            icon: Icon(Icons.remove, color: context.tText, size: 24),
            onPressed: onDown,
          ),
        ],
      ),
    );
  }
}

