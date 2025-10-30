// lib/models/railway_crossing.dart
class RailwayCrossing {
  final String crossingId;
  final String railroadCode;
  final String reportingAgency;
  final String stateName;
  final String countyName;
  final String cityName;
  final String street;
  final String crossingType;
  final double latitude;
  final double longitude;
  final int maxTrainSpeed;
  final String movementsPerDay;
  final String emergencyPhone;
  final String railroadPhone;
  final bool hasSignals;
  final bool hasGates;
  final int highwaySpeedLimit;

  RailwayCrossing({
    required this.crossingId,
    required this.railroadCode,
    required this.reportingAgency,
    required this.stateName,
    required this.countyName,
    required this.cityName,
    required this.street,
    required this.crossingType,
    required this.latitude,
    required this.longitude,
    required this.maxTrainSpeed,
    required this.movementsPerDay,
    required this.emergencyPhone,
    required this.railroadPhone,
    required this.hasSignals,
    required this.hasGates,
    required this.highwaySpeedLimit,
  });

  factory RailwayCrossing.fromJson(Map<String, dynamic> json) {
    return RailwayCrossing(
      crossingId: json['crossingid'] ?? 'N/A',
      railroadCode: json['railroadcode'] ?? 'Unknown',
      reportingAgency: json['reportingagencyname'] ?? 'Unknown',
      stateName: json['statename'] ?? 'Unknown',
      countyName: json['countyname'] ?? 'Unknown',
      cityName: json['cityname'] ?? 'Unknown',
      street: json['street'] ?? 'Unknown',
      crossingType: json['crossingtype'] ?? 'Unknown',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
      maxTrainSpeed: int.tryParse(json['maximumspeedrangeovercrossing']?.toString() ?? '0') ?? 0,
      movementsPerDay: json['movementsperday'] ?? 'Unknown',
      emergencyPhone: json['emergencytelephonenumber'] ?? 'N/A',
      railroadPhone: json['railroadcontacttelephonenumber'] ?? 'N/A',
      hasSignals: (json['signsorsignals']?.toString() ?? '').toLowerCase() == 'yes',
      hasGates: (json['countroadwaygatearms']?.toString() ?? '0') != '0',
      highwaySpeedLimit: int.tryParse(json['highwayspeedlimit']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crossingid': crossingId,
      'railroadcode': railroadCode,
      'reportingagencyname': reportingAgency,
      'statename': stateName,
      'countyname': countyName,
      'cityname': cityName,
      'street': street,
      'crossingtype': crossingType,
      'latitude': latitude,
      'longitude': longitude,
      'maximumspeedrangeovercrossing': maxTrainSpeed,
      'movementsperday': movementsPerDay,
      'emergencytelephonenumber': emergencyPhone,
      'railroadcontacttelephonenumber': railroadPhone,
      'signsorsignals': hasSignals ? 'Yes' : 'No',
      'countroadwaygatearms': hasGates ? '1' : '0',
      'highwayspeedlimit': highwaySpeedLimit,
    };
  }

  String get locationDescription => '$street, $cityName, $stateName';

  String get safetyFeatures {
    final features = [];
    if (hasSignals) features.add('Signals');
    if (hasGates) features.add('Gates');
    return features.isNotEmpty ? features.join(' + ') : 'None';
  }
}