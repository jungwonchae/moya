import 'package:flutter/material.dart';
import '../usage/usage_screens_container.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moya_app/themes/colortheme.dart';
import 'package:moya_app/screens/home/home_screen.dart';

// Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatelessWidget {

  const LoginScreen({super.key});

  // 비회원 로그인을 위함
  // 익명 로그인 → Users/{uid} 초기화 → true/false 반환
  Future<bool> _signInAnonymouslyAndInit(BuildContext context) async {
    try {
      // 1) 익명 로그인
      final cred = await FirebaseAuth.instance.signInAnonymously();
      final uid = cred.user!.uid;
      debugPrint('[Auth] Anonymous signed in. uid=$uid');

      // 2) Users/{uid} 문서가 없으면 생성 (merge로 안전하게)
      final usersRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await usersRef.get();
      if (!snap.exists) {
        await usersRef.set({
          'name': '사용자',          // 기본 표시 이름(원하면 닉네임 설정 화면에서 변경)
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('[Firestore] users/$uid initialized.');
      } else {
        debugPrint('[Firestore] users/$uid already exists.');
      }

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] Anonymous sign-in failed: ${e.code} ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[Auth] Anonymous sign-in failed: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 배경 원형 디자인
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: ColorTheme.subColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 왼쪽 아래 원형
          Positioned(
            top: 390,
            left: -200, // 왼쪽으로 빼기
            child: Container(
              width: 365,
              height: 365,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ColorTheme.subColor.withOpacity(0.1), // subColor, 10% 투명도
                  width: 3, // 테두리 두께 (원하는 대로 조정)
                ),
              ),
            ),
          ),
          
          // 메인 컨텐츠
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 120),
                  
                  // 로고 아이콘
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.centerLeft,
                    child: SvgPicture.asset(
                        'assets/icons/moya.svg',
                        width: 30,
                        height: 30,
                        color: ColorTheme.subColor, // 필요하다면 색상 입히기 가능
                      ),
                    ),
                  
                  SizedBox(height: 20),

                  // 제목 텍스트 1
                  Text(
                    '안녕하세요.',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.normal,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                  
                  // 제목 텍스트 2
                  Text(
                    'MOYA 입니다.',
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: Colors.black87,
                    ),
                  ),
                  
                  Spacer(),
                  
                  // 회원가입 버튼
                  // Container(
                  //   width: double.infinity,
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       // 직접 UsageFirstScreen으로 이동하면서 파라미터 전달
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => UsageScreensContainer(isFromOnboarding: true),
                  //         ),
                  //       );
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Color(0xFFFF85B4),
                  //       foregroundColor: Colors.white,
                  //       padding: EdgeInsets.symmetric(vertical: 16),
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(12),
                  //       ),
                  //       elevation: 0,
                  //     ),
                  //     child: Text(
                  //       '회원가입 하기',
                  //       style: TextStyle(
                  //         fontSize: 16,
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                  
                  // SizedBox(height: 15),
                  
                  // 비회원 시작 버튼 (익명 로그인 연결) -> MVP 로 회원가입 없애고 일단 비회원 로그인만 받기

                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        // 1) 익명 로그인 & users/{uid} 준비
                        final ok = await _signInAnonymouslyAndInit(context);
                        if (!ok) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('비회원 로그인에 실패했어요. 잠시 후 다시 시도해주세요.')),
                            );
                          }
                          return;
                        }

                        if (!context.mounted) return;

                        // 2) name 존재 여부 체크
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
                        final hasName = ((userDoc.data()?['name'] as String?)?.trim().isNotEmpty ?? false);

                        // 3) 분기 이동
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => hasName
                                  ? HomeScreen() // 이름이 있으면 바로 홈
                                  : const UsageScreensContainer(isFromOnboarding: true), // 없으면 온보딩
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF85B4),  // 회원가입 버튼과 같은 배경색
                        foregroundColor: Colors.white,       // 회원가입 버튼과 같은 텍스트 색상
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '시작하기', // 비회원 시작하기로 추후에 변경
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,  // 회원가입 버튼과 같은 폰트 굵기
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}