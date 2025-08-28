class PeriodData {
  final DateTime startDate;
  final DateTime? endDate;
  final int durationDays;
  final List<DateTime> changeTimes;
  final Map<String, dynamic> symptoms;
  /// 현재 주기가 진행 중인지 여부 (Firestore periods.isOnPeriod 대응)
  final bool isOnPeriod;
  
  PeriodData({
    required this.startDate,
    this.endDate,
    required this.durationDays,
    required this.changeTimes,
    required this.symptoms,
    required this.isOnPeriod,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'durationDays': durationDays,
      'changeTimes': changeTimes.map((t) => t.toIso8601String()).toList(),
      'symptoms': symptoms,
      'isOnPeriod': isOnPeriod,
    };
  }
  
  factory PeriodData.fromJson(Map<String, dynamic> json) {
    final DateTime s = DateTime.parse(json['startDate']);
    final DateTime? e = json['endDate'] != null ? DateTime.parse(json['endDate']) : null;
    final int dur = json['durationDays'];

    return PeriodData(
      startDate: s,
      endDate: e,
      durationDays: dur,
      changeTimes: (json['changeTimes'] as List)
          .map((t) => DateTime.parse(t))
          .toList(),
      symptoms: json['symptoms'] ?? {},
      // 서버/저장소에 필드가 없을 수도 있으므로 안전하게 계산하여 디폴트 적용
      isOnPeriod: (json['isOnPeriod'] as bool?) ?? _computeIsOnPeriod(s, e, dur),
    );
  }

  /// endDate가 비어 있으면 [durationDays]를 이용해 진행 중 여부를 계산
  /// endDate가 있으면 해당 날짜(일까지)를 포함해 진행 중으로 간주
  static bool _computeIsOnPeriod(DateTime start, DateTime? end, int durationDays) {
    final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final DateTime startD = DateTime(start.year, start.month, start.day);

    if (end != null) {
      final DateTime endD = DateTime(end.year, end.month, end.day);
      return (today.isAfter(startD) || today.isAtSameMomentAs(startD)) &&
             (today.isBefore(endD)   || today.isAtSameMomentAs(endD));
    }

    // end가 없으면 기간(durationDays)로 가상의 종료일 계산 (예: 5일이면 시작일 포함 5일간 진행)
    final pseudoEnd = startD.add(Duration(days: durationDays - 1));
    return (today.isAfter(startD) || today.isAtSameMomentAs(startD)) &&
           (today.isBefore(pseudoEnd) || today.isAtSameMomentAs(pseudoEnd));
  }
}