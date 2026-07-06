// Shared cloud-camera model — used by all vendor cloud camera clients
// (Arlo, Eufy, Nest, Ring, Wyze) to describe a camera fetched from the
// vendor's cloud API.
class CloudCamera {
  final String id;
  final String name;
  final String? thumbnailUrl;
  final bool isOnline;
  final String? liveStreamUrl;
  final String? snapshotUrl;

  const CloudCamera({
    required this.id,
    required this.name,
    this.thumbnailUrl,
    this.isOnline = false,
    this.liveStreamUrl,
    this.snapshotUrl,
  });
}
