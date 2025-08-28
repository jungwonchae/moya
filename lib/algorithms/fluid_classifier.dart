// lib/algorithms/fluid_classifier.dart

/// 유체 분류 결과
enum FluidType { blood, sweat, unknown }

/// 1분 이내에 3축이 모두 '큰 변화'를 보이면 땀(sweat)으로 분류하는 상태형 분류기
/// - 매 샘플(prev, cur)을 넣을 때 축별 변화량을 계산해, 임계치 이상이면 해당 축의
///   마지막 감지 시간을 now로 갱신합니다
/// - 이후 now 기준으로 1분(window) 이내에 3축의 마지막 감지 시간이 모두 존재하면
///   sweat을 반환합니다
/// - 그렇지 않으면 blood를 반환합니다(= 기본값)
/// - prev/cur 길이가 3 미만이면 unknown
class FluidClassifier {
  /// 각 축에서 '큰 변화'라고 볼 최소 변화량
  final int diffThreshold;

  /// 축 감지 유효 시간 윈도우(기본 1분)
  final Duration window;

  /// 각 축 마지막으로 임계치 이상 변화를 감지한 시각(없으면 null)
  final List<DateTime?> _lastAxisHit = List<DateTime?>.filled(3, null);

  FluidClassifier({
    this.diffThreshold = 40,
    this.window = const Duration(minutes: 1),
  });

  /// 새로운 샘플을 추가하고, 현재 시점에서의 분류 결과를 반환합니다
  /// - [prev], [cur]는 길이 3이어야 합니다
  /// - [now]를 넘기지 않으면 DateTime.now() 사용
  FluidType addSample(List<int> prev, List<int> cur, {DateTime? now}) {
    if (prev.length < 3 || cur.length < 3) {
      return FluidType.unknown;
    }

    final t = now ?? DateTime.now();

    // 축별 변화량 계산 및 임계치 이상이면 해당 축 타임스탬프 갱신
    for (int i = 0; i < 3; i++) {
      final diff = (cur[i] - prev[i]).abs();
      if (diff >= diffThreshold) {
        _lastAxisHit[i] = t;
      }
    }

    // 윈도우 내에 3축 모두가 최근에 감지되었는지 검사
    final allAxesHit = _lastAxisHit.every(
      (hit) => hit != null && t.difference(hit!).abs() <= window,
    );

    if (allAxesHit) {
      return FluidType.sweat;
    }
    return FluidType.blood;
  }

  /// 내부 상태 리셋(모든 축 타임스탬프 초기화)
  void reset() {
    for (int i = 0; i < _lastAxisHit.length; i++) {
      _lastAxisHit[i] = null;
    }
  }

  /// 디버깅용: 축별 마지막 감지 시각을 노출
  List<DateTime?> get lastAxisHit => List.unmodifiable(_lastAxisHit);
}