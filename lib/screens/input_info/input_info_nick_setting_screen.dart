import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:moya_app/services/period_service.dart';
import 'package:moya_app/themes/colortheme.dart';

class InputInfoNickSettingScreen extends StatefulWidget {
  const InputInfoNickSettingScreen({super.key});

  @override
  State<InputInfoNickSettingScreen> createState() => _InputInfoNickSettingScreenState();
}

class _InputInfoNickSettingScreenState extends State<InputInfoNickSettingScreen> {
  final TextEditingController nickController = TextEditingController();
  final FocusNode nickFocusNode = FocusNode();
  final PeriodService _periodService = PeriodService();

  String? _periodId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // 포커스 잃으면 자동 저장
    nickFocusNode.addListener(() {
      if (!nickFocusNode.hasFocus) {
        _saveNick();
      }
    });
    _loadLatestPeriodNick();
  }

  @override
  void dispose() {
    nickController.dispose();
    nickFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLatestPeriodNick() async {
    setState(() => _loading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        nickController.text = '';
        setState(() => _loading = false);
        return;
      }

      // 최신 period 문서 가져오기
      final latest = await _periodService.getLatestPeriod(uid);
      if (latest == null) {
        // 생리 기록이 없어도 화면은 표시하되 저장은 불가능하게
        nickController.text = '';
        _periodId = null;
      } else {
        _periodId = latest['periodId'] as String;
        final nick = (latest['nick'] as String?) ?? '';
        nickController.text = nick;
      }
    } catch (e) {
      // 실패해도 화면은 그려줌
      nickController.text = '';
      _periodId = null;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveNick() async {
    try {
      if (_periodId == null) {
        // 생리 기록이 없으면 저장 불가
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('생리 기록이 없어 별명을 저장할 수 없습니다. 먼저 생리 기록을 추가해주세요.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final nick = nickController.text.trim();
      final success = await _periodService.updatePeriodData(_periodId!, {
        'nick': nick,
      });

      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('별명이 저장되었습니다.'),
            backgroundColor: ColorTheme.subColor,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('별명 저장에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('별명 저장에 실패했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorTheme.subColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 별명
                  const Text(
                    '별명 입력',
                    style: TextStyle(
                      fontSize: 18,
                      color: ColorTheme.subColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  // 설명 텍스트
                  Text(
                    '알림에 표시될 문구를 정해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nickController,
                          focusNode: nickFocusNode, // 포커스 해제 시 자동 저장
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveNick(), // 키보드 완료로도 저장
                          decoration: const InputDecoration(
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: ColorTheme.textGray, width: 0.5),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: ColorTheme.subColor, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16),
                            hintText: '알림에 사용될 별명을 입력하세요',
                            hintStyle: TextStyle(color: ColorTheme.textLightGray, fontSize: 16),
                          ),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const Icon(Icons.edit, color: ColorTheme.iconGray, size: 20),
                    ],
                  ),

                  const SizedBox(height: 16),

                  const Spacer(),

                  // 상태 표시 (생리 기록이 없는 경우)
                  if (_periodId == null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[600], size: 24),
                          const SizedBox(height: 8),
                          Text(
                            '생리 기록이 없습니다',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '별명을 저장하려면 먼저 생리 기록을 추가해주세요.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }
}