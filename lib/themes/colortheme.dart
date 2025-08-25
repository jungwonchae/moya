import 'package:flutter/material.dart';

class ColorTheme {
  // 메인 브랜드 컬러
  static const Color mainColor = Color(0xFFFCBAD2);           // 메인 핑크 (메인페이지, 연 분홍)
  static const Color subColor = Color(0xFFFF85B4);         // 진한 핑크 (호버, 선택 상태,버튼, 물방울)
  
  // 배경 컬러
  static const Color background = Color(0xFFFFFFFF);           // 메인 배경 (흰색)
  static const Color backgroundGray = Color(0xFFF7F7F7);           // 블루투스 시 사용하는 배경
  
  // 텍스트 스케일
  static const Color textBlack = Color(0xFF000000);          // 메인 제목
  static const Color textWhite = Color(0xFFFFFFFF);          // 메인 제목
  static const Color textGray = Color(0xFF5F5F5F);        // 부제목, 설명
  static const Color textLightGray = Color(0xFFA2A2A2);        // 연한 그레이
  static const Color textPink = Color(0xFFFF85B4);         // 힌트, 비활성 텍스트
  static const Color textLightPink = Color(0xFFFCBAD2);         // 비활성화된 텍스트
  
  // 보더 & 아이콘
  static const Color borderGray = Color(0xFF5F5F5F);               // 기본 테두리
  static const Color iconGray = Color(0xFFD2D2D2);               // 아이콘 (얘만 다른 그레이)
  
  // 생리 주기 상태 컬러
  static const Color periodSafe = Color(0xFF55BE79);           // "아직은 보송보송 해요"
  static const Color periodWarning = Color(0xFFFFD500);        // "곧 교체할 시간이 다가와요"
  static const Color periodNeed = Color(0xFFFF6406);           // "교체가 필요해요"
  static const Color periodBefore = Color(0xFFA2A2A2);         // "아직은 시작 전이에요"
  
  // 블루투스 관련
  static const Color bluetoothConnected = Color(0xFFFF85B4);   // 블루투스 연결됨
  static const Color bluetoothDisconnected = Color(0xFF3182F7); // 블루투스 연결 안됨

  // 알림 관련
  static const Color notificationIcon = Color(0xFFFF6406);     // 알림 아이콘 빨간색 점

  // 그림자 & 오버레이
  static const Color shadow = Color(0x192E3176);  // 그림자 (10% 투명도)
  static const Color scrim  = Color(0x99000000);  // 모달 배경 (60% 투명도)
  
}