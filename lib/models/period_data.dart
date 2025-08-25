class PeriodData {
  final DateTime startDate;
  final DateTime? endDate;
  final int durationDays;
  final List<DateTime> changeTimes;
  final Map<String, dynamic> symptoms;
  
  PeriodData({
    required this.startDate,
    this.endDate,
    required this.durationDays,
    required this.changeTimes,
    required this.symptoms,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'durationDays': durationDays,
      'changeTimes': changeTimes.map((t) => t.toIso8601String()).toList(),
      'symptoms': symptoms,
    };
  }
  
  factory PeriodData.fromJson(Map<String, dynamic> json) {
    return PeriodData(
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      durationDays: json['durationDays'],
      changeTimes: (json['changeTimes'] as List)
          .map((t) => DateTime.parse(t))
          .toList(),
      symptoms: json['symptoms'] ?? {},
    );
  }
}