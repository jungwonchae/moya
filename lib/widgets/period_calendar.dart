import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';

/// 날짜별 로그 모델
class DayLog {
  final TimeOfDay time;
  final String title;
  const DayLog({required this.time, required this.title});
}

/// 생리 달력 + 선택일 바 + 로그 리스트까지 한 번에 보여주는 패널
class PeriodCalendar extends StatefulWidget {
  /// 초기 포커스 월(기본: 오늘의 월)
  final DateTime? initialMonth;

  /// 초기 선택일(기본: 오늘)
  final DateTime? initialSelected;

  /// 날짜 → 로그 목록 (키는 "연-월-일"만 유지되는 DateTime이어야 함)
  final Map<DateTime, List<DayLog>> events;

  /// 생리 날짜들 (배경색 표시용)
  final Set<DateTime>? periodDates;

  /// 날짜 선택 콜백(선택된 day를 넘겨줌)
  final ValueChanged<DateTime>? onSelected;

  /// 좌우/상하 패딩(기본: 좌우 24)
  final EdgeInsets padding;

  const PeriodCalendar({
    super.key,
    required this.events,
    this.periodDates,
    this.initialMonth,
    this.initialSelected,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  @override
  State<PeriodCalendar> createState() => _PeriodCalendarState();

  /// 날짜만 보존(시간 제거)
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}

class _PeriodCalendarState extends State<PeriodCalendar> {
  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = widget.initialMonth != null
        ? DateTime(widget.initialMonth!.year, widget.initialMonth!.month, 1)
        : DateTime(now.year, now.month, 1);
    _selectedDay =
        PeriodCalendar.normalize(widget.initialSelected ?? now);
  }

  List<DayLog> _logsOf(DateTime day) {
    final key = PeriodCalendar.normalize(day);
    return widget.events[key] ?? const [];
  }

  bool _isPeriodDay(DateTime day) {
    final key = PeriodCalendar.normalize(day);
    return widget.periodDates?.contains(key) ?? false;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth =
          DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final logs = _logsOf(_selectedDay);
    final isStartDay = logs.any((e) => e.title.contains('생리 시작')); // 단순 키워드 체크
    final isPeriodDay = _isPeriodDay(_selectedDay);

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          _MonthHeader(
            date: _focusedMonth,
            onPrev: _prevMonth,
            onNext: _nextMonth,
          ),
          const SizedBox(height: 12),
          _MonthGrid(
            focusedMonth: _focusedMonth,
            selected: _selectedDay,
            periodDates: widget.periodDates,
            onSelect: (d) {
              setState(() => _selectedDay = d);
              widget.onSelected?.call(d);
            },
          ),
          const SizedBox(height: 16),

          // 선택일 바
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: ColorTheme.subColor.withOpacity(.45),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Row(
              children: [
                Text(
                  _fmtDate(_selectedDay),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                if (isStartDay)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: const Text(
                      '생리 시작일',
                      style: TextStyle(
                        color: ColorTheme.textWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else if (isPeriodDay)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: const Text(
                      '생리 기간',
                      style: TextStyle(
                        color: ColorTheme.textWhite,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 선택일 로그
          if (logs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  '기록이 없어요',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (_, i) => _LogTile(log: logs[i]),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: logs.length,
            ),
        ],
      ),
    );
  }
}

/// 달 이름/월 변경
class _MonthHeader extends StatelessWidget {
  final DateTime date;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthHeader({
    required this.date,
    required this.onPrev,
    required this.onNext,
  });

  static const _enMonths = [
    'JANUARY','FEBRUARY','MARCH','APRIL','MAY','JUNE',
    'JULY','AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER'
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left_rounded, size: 28),
          color: Colors.grey[700],
          splashRadius: 20,
        ),
        Expanded(
          child: Center(
            child: Text(
              '${_enMonths[date.month - 1]} ${date.year}',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: 1.2,
                color: ColorTheme.subColor,
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded, size: 28),
          color: Colors.grey[700],
          splashRadius: 20,
        ),
      ],
    );
  }
}

/// 월 그리드(요일 + 날짜 선택)
class _MonthGrid extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selected;
  final Set<DateTime>? periodDates;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.focusedMonth,
    required this.selected,
    this.periodDates,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final first =
        DateTime(focusedMonth.year, focusedMonth.month, 1);
    final daysInMonth =
        DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
    final leading = first.weekday - 1; // Monday=1 -> 0
    final total = leading + daysInMonth;
    final trailing = (7 - (total % 7)) % 7;
    final cellCount = total + trailing;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            _WeekCell('MON'), _WeekCell('TUE'), _WeekCell('WED'),
            _WeekCell('THU'), _WeekCell('FRI'), _WeekCell('SAT'), _WeekCell('SUN'),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: cellCount,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 6,
          ),
          itemBuilder: (_, idx) {
            if (idx < leading || idx >= leading + daysInMonth) {
              return const SizedBox.shrink();
            }
            final dayNum = idx - leading + 1;
            final day = DateTime(
                focusedMonth.year, focusedMonth.month, dayNum);

            bool sameDay(DateTime a, DateTime b) =>
                a.year == b.year &&
                a.month == b.month &&
                a.day == b.day;

            final isToday = sameDay(day, DateTime.now());
            final isSelected = sameDay(day, selected);
            final isPeriodDay = periodDates?.contains(PeriodCalendar.normalize(day)) ?? false;

            Color? bg;
            Color fg;

            if (isSelected) {
              // 선택된 날짜 - 메인 색상
              bg = ColorTheme.subColor;
              fg = Colors.white;
            } else if (isPeriodDay) {
              // 생리 날짜 - 분홍색 배경
              bg = ColorTheme.mainColor;
              fg = Colors.white;
            } else if (isToday) {
              // 오늘 날짜 - 테두리만
              bg = null;
              fg = ColorTheme.subColor;
            } else {
              // 일반 날짜
              bg = null;
              fg = const Color(0xFF222222);
            }

            return GestureDetector(
              onTap: () => onSelect(day),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  border: isToday && !isSelected && !isPeriodDay 
                    ? Border.all(color: ColorTheme.subColor, width: 2)
                    : null,
                ),
                child: Text(
                  '$dayNum',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekCell extends StatelessWidget {
  final String label;
  const _WeekCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }
}

/// 로그 한 줄
class _LogTile extends StatelessWidget {
  final DayLog log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final hh = log.time.hour.toString().padLeft(2, '0');
    final mm = log.time.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$hh:$mm',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            log.title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}