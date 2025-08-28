import 'package:flutter/material.dart';
import 'package:moya_app/themes/colortheme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final List<_Notice> _items = [
    _Notice(title: '생리대 교체 확인 필요', time: '2025-08-20 오후 03:56', isRead: false, type: NoticeType.warning),
    _Notice(title: '생리대 교체',        time: '2025-08-20 오후 03:56', isRead: false, type: NoticeType.normal),
    _Notice(title: '생리대 교체',        time: '2025-08-20 오후 03:56', isRead: true,  type: NoticeType.normal),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 28, color: ColorTheme.subColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '최근 알림 내역',
                    style: TextStyle(
                      color: ColorTheme.subColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFEAEAF1)),
                itemBuilder: (context, i) {
                  final n = _items[i];
                  return InkWell(
                    onTap: () => _openDetailModal(context, i),
                    onLongPress: () => setState(() {
                      _items[i] = n.copyWith(isRead: !n.isRead); // 길게 눌러 토글
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                      child: Row(
                        children: [
                          // 안읽음 점
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: n.isRead ? Colors.transparent : ColorTheme.subColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          // 제목
                          Expanded(
                            child: Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: n.isRead
                                    ? const Color(0xFF3B3B3B)
                                    : Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // 시간
                          Text(
                            n.time,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDetailModal(BuildContext context, int index) async {
    final n = _items[index];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 10,
            bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // grab handle
              Center(
                child: Container(
                  width: 44, height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 타이틀 + 상태칩
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    n.type == NoticeType.warning
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    color: n.type == NoticeType.warning
                        ? Colors.amber[700]
                        : ColorTheme.subColor,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _StatusChip(isRead: n.isRead),
                ],
              ),
              const SizedBox(height: 8),

              // 시간 표시
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    n.time,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),

              const SizedBox(height: 14),

              // 설명
              Text(
                n.type == NoticeType.warning
                    ? '흡수량이 높게 감지됐어요. 생리대 상태를 확인하고 필요하면 교체해 주세요.'
                    : '정상적으로 교체가 기록되었어요. 수분 보충과 휴식도 잊지 마세요.',
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF374151),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 14),

              // 관련 정보 칩
              Wrap(
                spacing: 8, runSpacing: 8,
                children: const [
                  _InfoChip(label: '오늘 교체 횟수 2회'),
                  _InfoChip(label: '마지막 교체 0.5시간 전'),
                  _InfoChip(label: '권장 교체 주기 4~6시간'),
                ],
              ),

              const SizedBox(height: 18),

              // 액션 버튼들
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _items[index] = n.copyWith(isRead: !n.isRead);
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTheme.subColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(n.isRead ? '다시 안 읽음으로' : '읽음 처리'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: '삭제',
                    onPressed: () {
                      setState(() {
                        _items.removeAt(index);
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('알림이 삭제되었습니다.')),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        );
      },
    );
  }
}

enum NoticeType { normal, warning }

class _Notice {
  final String title;
  final String time;
  final bool isRead;
  final NoticeType type;

  const _Notice({
    required this.title,
    required this.time,
    required this.isRead,
    this.type = NoticeType.normal,
  });

  _Notice copyWith({String? title, String? time, bool? isRead, NoticeType? type}) {
    return _Notice(
      title: title ?? this.title,
      time: time ?? this.time,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isRead;
  const _StatusChip({required this.isRead});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRead ? const Color(0xFFF3F4F6) : ColorTheme.subColor.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead ? const Color(0xFFE5E7EB) : ColorTheme.subColor.withOpacity(.4),
        ),
      ),
      child: Text(
        isRead ? '읽음' : '안 읽음',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: isRead ? const Color(0xFF6B7280) : ColorTheme.subColor,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAF1)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF374151),
        ),
      ),
    );
  }
}
