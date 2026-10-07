import 'psgc_place.dart';

/// A Philippine administrative location (region > province > city > barangay).
/// Codes are the PSGC identifiers and are what location matching uses;
/// names are kept for display. Province is empty for NCR (no provinces).
class PsgcLocation {
  const PsgcLocation({
    this.region = '',
    this.regionCode = '',
    this.province = '',
    this.provinceCode = '',
    this.city = '',
    this.cityCode = '',
    this.barangay = '',
    this.barangayCode = '',
  });

  static const empty = PsgcLocation();

  final String region;
  final String regionCode;
  final String province;
  final String provinceCode;
  final String city;
  final String cityCode;
  final String barangay;
  final String barangayCode;

  bool get hasRegion => regionCode.isNotEmpty;
  bool get hasProvince => provinceCode.isNotEmpty;
  bool get hasCity => cityCode.isNotEmpty;
  bool get hasBarangay => barangayCode.isNotEmpty;

  /// Enough to match delivery areas: region, city and barangay chosen.
  bool get isComplete => hasRegion && hasCity && hasBarangay;

  // Picking a level clears everything below it.
  PsgcLocation withRegion(PsgcPlace p) =>
      PsgcLocation(region: p.name, regionCode: p.code);

  PsgcLocation withProvince(PsgcPlace p) => PsgcLocation(
      region: region,
      regionCode: regionCode,
      province: p.name,
      provinceCode: p.code);

  PsgcLocation withCity(PsgcPlace p) => PsgcLocation(
      region: region,
      regionCode: regionCode,
      province: province,
      provinceCode: provinceCode,
      city: p.name,
      cityCode: p.code);

  PsgcLocation withBarangay(PsgcPlace p) => PsgcLocation(
      region: region,
      regionCode: regionCode,
      province: province,
      provinceCode: provinceCode,
      city: city,
      cityCode: cityCode,
      barangay: p.name,
      barangayCode: p.code);

  /// "Matina, Davao City"
  String get shortLabel =>
      [barangay, city].where((s) => s.isNotEmpty).join(', ');

  /// "Matina, Davao City, Davao del Sur, Davao Region"
  String get fullLabel => [barangay, city, province, region]
      .where((s) => s.isNotEmpty)
      .join(', ');

  Map<String, dynamic> toMap() => {
        'region': region,
        'regionCode': regionCode,
        'province': province,
        'provinceCode': provinceCode,
        'city': city,
        'cityCode': cityCode,
        'barangay': barangay,
        'barangayCode': barangayCode,
      };

  factory PsgcLocation.fromMap(Map<String, dynamic> m) => PsgcLocation(
        region: m['region'] as String? ?? '',
        regionCode: m['regionCode'] as String? ?? '',
        province: m['province'] as String? ?? '',
        provinceCode: m['provinceCode'] as String? ?? '',
        city: m['city'] as String? ?? '',
        cityCode: m['cityCode'] as String? ?? '',
        barangay: m['barangay'] as String? ?? '',
        barangayCode: m['barangayCode'] as String? ?? '',
      );

  @override
  bool operator ==(Object o) =>
      o is PsgcLocation &&
      o.regionCode == regionCode &&
      o.provinceCode == provinceCode &&
      o.cityCode == cityCode &&
      o.barangayCode == barangayCode;

  @override
  int get hashCode =>
      Object.hash(regionCode, provinceCode, cityCode, barangayCode);
}
