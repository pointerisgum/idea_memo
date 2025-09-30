import 'package:flutter/foundation.dart';
import 'package:ideamemo/core/services/firestore_service.dart';
import 'package:ideamemo/domain/entities/idea.dart';

/// 개발용 데이터 관리 서비스
/// 디버그 모드에서만 사용되는 데이터 리셋 기능 제공
class DevDataService {
  /// 아이디어 데이터 리셋 (기존 데이터 삭제 + 샘플 데이터 추가)
  static Future<void> resetIdeasData() async {
    if (!kDebugMode) {
      throw Exception('개발 모드에서만 사용 가능한 기능입니다.');
    }

    // 1. 기존 데이터 삭제
    await FirestoreService.deleteAllUserIdeas();

    // 2. 새로운 샘플 데이터 추가
    await _addSampleIdeas();
  }

  /// 샘플 아이디어 데이터 추가
  static Future<void> _addSampleIdeas() async {
    final now = DateTime.now();

    final ideas = [
      Idea(
        id: 'idea_001',
        title: '스마트 식물 관리 앱',
        content: 'IoT 센서와 연동하여 화분의 토양 습도, 조도, 온도를 실시간 모니터링하고, 물주기 알림과 최적의 관리 팁을 제공하는 앱. 식물별 맞춤 케어 가이드와 성장 일기 기능도 포함.',
        createdAt: now.subtract(const Duration(days: 9)),
      ),
      Idea(
        id: 'idea_002',
        title: 'AI 기반 요리 추천 서비스',
        content: '냉장고에 있는 재료를 사진으로 찍으면 AI가 인식하여 만들 수 있는 요리를 추천해주는 서비스. 유통기한 관리, 영양소 분석, 개인 취향 학습을 통한 맞춤형 레시피 제공까지.',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      Idea(
        id: 'idea_003',
        title: '공유 주차장 플랫폼',
        content: '개인이 소유한 주차공간을 시간대별로 대여할 수 있는 플랫폼. GPS 기반 위치 검색, 실시간 예약, 자동 결제 시스템을 통해 도심 주차난 해결과 부수입 창출을 동시에.',
        createdAt: now.subtract(const Duration(days: 7)),
        isPinned: true,
        pinnedAt: now.subtract(const Duration(days: 1)),
      ),
      Idea(
        id: 'idea_004',
        title: '운동 메이트 매칭 앱',
        content: '같은 지역, 비슷한 실력의 운동 파트너를 찾아주는 앱. 테니스, 배드민턴, 러닝 등 다양한 운동별 매칭과 함께 운동 기록 관리, 실력 향상 트래킹 기능 제공.',
        createdAt: now.subtract(const Duration(days: 6)),
        isBookmarked: true,
        bookmarkedAt: now.subtract(const Duration(days: 2)),
      ),
      Idea(
        id: 'idea_005',
        title: '중고 전자기기 신뢰도 검증 서비스',
        content: '중고 스마트폰, 노트북 등의 하드웨어 상태를 AI로 자동 진단하고 신뢰도 점수를 매기는 서비스. 블록체인 기반 거래 이력 관리로 사기 거래 방지.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      Idea(
        id: 'idea_006',
        title: '개인 맞춤형 학습 플래너',
        content: '개인의 학습 패턴과 집중력을 분석하여 최적의 학습 스케줄을 자동 생성하는 AI 플래너. 뽀모도로 기법, 복습 주기 최적화, 목표 달성률 분석 기능 포함.',
        createdAt: now.subtract(const Duration(days: 4)),
        isPinned: true,
        pinnedAt: now.subtract(const Duration(hours: 12)),
      ),
      Idea(
        id: 'idea_007',
        title: '지역 소상공인 배달 통합 플랫폼',
        content: '대형 배달앱의 높은 수수료 부담을 줄이기 위한 지역 기반 배달 플랫폼. 동네 소상공인들이 공동으로 배달원을 운영하고 수익을 공유하는 협동조합 모델.',
        createdAt: now.subtract(const Duration(days: 3)),
        isBookmarked: true,
        bookmarkedAt: now.subtract(const Duration(hours: 6)),
      ),
      Idea(
        id: 'idea_008',
        title: '반려동물 건강 모니터링 IoT',
        content: '반려동물의 활동량, 수면 패턴, 식사량을 자동으로 모니터링하는 웨어러블 디바이스. 수의사와 연계한 건강 상담 서비스와 응급상황 알림 기능 제공.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Idea(
        id: 'idea_009',
        title: '친환경 포장재 구독 서비스',
        content: '온라인 쇼핑몰과 카페를 위한 생분해성 포장재 정기 구독 서비스. 사용량 예측 AI와 재고 관리 자동화로 환경 보호와 비용 절감을 동시에 실현.',
        createdAt: now.subtract(const Duration(days: 1)),
        isPinned: true,
        pinnedAt: now.subtract(const Duration(hours: 3)),
      ),
      Idea(
        id: 'idea_010',
        title: '실시간 소음 지도 앱',
        content: '사용자들이 실시간으로 소음 수준을 측정하고 공유하여 도시 전체의 소음 지도를 만드는 크라우드소싱 앱. 조용한 카페, 공부하기 좋은 장소 추천 기능 포함.',
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
    ];

    // 각 아이디어를 순차적으로 추가
    for (final idea in ideas) {
      await FirestoreService.addIdea(idea);
      // API 호출 제한을 피하기 위해 잠시 대기
      await Future.delayed(const Duration(milliseconds: 200));
    }

    debugPrint('✅ [DEV_DATA] 샘플 아이디어 ${ideas.length}개 추가 완료');
  }
}
