/// One entry returned by the PSGC API (region, province, city or barangay).
class PsgcPlace {
  const PsgcPlace({required this.code, required this.name, this.subtitle});

  final String code; // 9-digit PSGC code, the reliable identifier
  final String name; // value we store and show
  final String? subtitle; // e.g. "Region XI" under "Davao Region"

  factory PsgcPlace.fromJson(Map<String, dynamic> j, {bool isRegion = false}) {
    final code = (j['code'] ?? '').toString();
    final raw = (j['name'] ?? '').toString().trim();

    if (isRegion) {
      final regionName = (j['regionName'] ?? '').toString().trim();
      return PsgcPlace(
        code: code,
        name: regionName.isEmpty ? raw : regionName,
        subtitle: regionName.isEmpty ? null : raw,
      );
    }
    return PsgcPlace(code: code, name: _friendly(raw));
  }

  /// PSGC writes "City of Davao"; Filipinos say "Davao City".
  static String _friendly(String n) =>
      n.startsWith('City of ') ? '${n.substring(8)} City' : n;
}
