import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:ideamemo/domain/entities/idea.dart';

/// Firestore 데이터베이스 서비스
/// users/{userId}/ideas/{ideaId} 구조로 아이디어 데이터 관리
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 현재 로그인된 사용자의 아이디어 컬렉션 참조
  static CollectionReference<Map<String, dynamic>>? get _ideasCollection {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore.collection('users').doc(user.uid).collection('ideas');
  }

  /// 아이디어 추가
  static Future<void> addIdea(Idea idea) async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      await collection.doc(idea.id).set({
        'id': idea.id,
        'title': idea.title,
        'content': idea.content,
        'createdAt': Timestamp.fromDate(idea.createdAt),
        'updatedAt': idea.updatedAt != null ? Timestamp.fromDate(idea.updatedAt!) : null,
        'isPinned': idea.isPinned,
        'pinnedAt': idea.pinnedAt != null ? Timestamp.fromDate(idea.pinnedAt!) : null,
        'isBookmarked': idea.isBookmarked,
        'bookmarkedAt': idea.bookmarkedAt != null ? Timestamp.fromDate(idea.bookmarkedAt!) : null,
      });

      debugPrint('✅ [FIRESTORE] 아이디어 추가 성공: ${idea.id}');
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 아이디어 추가 실패: $e');
      rethrow;
    }
  }

  /// 아이디어 수정
  static Future<void> updateIdea(Idea idea) async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      await collection.doc(idea.id).update({
        'title': idea.title,
        'content': idea.content,
        'updatedAt': Timestamp.fromDate(idea.updatedAt ?? DateTime.now()),
        'isPinned': idea.isPinned,
        'pinnedAt': idea.pinnedAt != null ? Timestamp.fromDate(idea.pinnedAt!) : null,
        'isBookmarked': idea.isBookmarked,
        'bookmarkedAt': idea.bookmarkedAt != null ? Timestamp.fromDate(idea.bookmarkedAt!) : null,
      });

      debugPrint('✅ [FIRESTORE] 아이디어 수정 성공: ${idea.id}');
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 아이디어 수정 실패: $e');
      rethrow;
    }
  }

  /// 아이디어 삭제
  static Future<void> deleteIdea(String ideaId) async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      await collection.doc(ideaId).delete();

      debugPrint('✅ [FIRESTORE] 아이디어 삭제 성공: $ideaId');
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 아이디어 삭제 실패: $e');
      rethrow;
    }
  }

  /// 아이디어 목록 조회 (최신순)
  static Future<List<Idea>> getIdeas() async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final querySnapshot = await collection
          .orderBy('createdAt', descending: true) // 최신순 정렬
          .get();

      final ideas = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
          isPinned: data['isPinned'] as bool? ?? false,
          pinnedAt: data['pinnedAt'] != null ? (data['pinnedAt'] as Timestamp).toDate() : null,
          isBookmarked: data['isBookmarked'] as bool? ?? false,
          bookmarkedAt: data['bookmarkedAt'] != null ? (data['bookmarkedAt'] as Timestamp).toDate() : null,
        );
      }).toList();

      debugPrint('✅ [FIRESTORE] 아이디어 목록 조회 성공: ${ideas.length}개');
      return ideas;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 아이디어 목록 조회 실패: $e');
      rethrow;
    }
  }

  /// 아이디어 실시간 스트림 (최신순)
  static Stream<List<Idea>> getIdeasStream() {
    final collection = _ideasCollection;
    if (collection == null) {
      return Stream.value([]);
    }

    return collection
        .orderBy('createdAt', descending: true) // 최신순 정렬
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Idea(
          id: data['id'] as String,
          title: data['title'] as String,
          content: data['content'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
        );
      }).toList();
    });
  }

  /// 특정 아이디어 조회
  static Future<Idea?> getIdea(String ideaId) async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final docSnapshot = await collection.doc(ideaId).get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data()!;
      return Idea(
        id: data['id'] as String,
        title: data['title'] as String,
        content: data['content'] as String,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
        updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      );
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 아이디어 조회 실패: $e');
      rethrow;
    }
  }

  /// 사용자의 모든 아이디어 삭제 (계정 탈퇴 시 사용)
  static Future<void> deleteAllUserIdeas() async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final querySnapshot = await collection.get();

      // 배치 삭제
      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      debugPrint('✅ [FIRESTORE] 사용자 모든 아이디어 삭제 성공');
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 사용자 모든 아이디어 삭제 실패: $e');
      rethrow;
    }
  }

  /// 아이디어 고정/해제 토글
  static Future<void> togglePinIdea(String ideaId) async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 현재 아이디어 정보 조회
      final docSnapshot = await collection.doc(ideaId).get();
      if (!docSnapshot.exists) {
        throw Exception('아이디어를 찾을 수 없습니다.');
      }

      final data = docSnapshot.data()!;
      final currentIsPinned = data['isPinned'] as bool? ?? false;

      if (!currentIsPinned) {
        // 고정하려는 경우: 현재 고정된 아이디어 개수 확인
        final pinnedQuery = await collection.where('isPinned', isEqualTo: true).get();

        if (pinnedQuery.docs.length >= 3) {
          throw Exception('고정할 수 있는 아이디어는 최대 3개입니다.');
        }

        // 고정 처리
        await collection.doc(ideaId).update({
          'isPinned': true,
          'pinnedAt': Timestamp.fromDate(DateTime.now()),
        });

        debugPrint('✅ [FIRESTORE] 아이디어 고정 성공: $ideaId');
      } else {
        // 고정 해제 처리
        await collection.doc(ideaId).update({
          'isPinned': false,
          'pinnedAt': null,
        });

        debugPrint('✅ [FIRESTORE] 아이디어 고정 해제 성공: $ideaId');
      }
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 아이디어 고정 토글 실패: $e');
      rethrow;
    }
  }

  /// 고정된 아이디어 개수 조회
  static Future<int> getPinnedIdeasCount() async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      final pinnedQuery = await collection.where('isPinned', isEqualTo: true).get();

      return pinnedQuery.docs.length;
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 고정된 아이디어 개수 조회 실패: $e');
      return 0;
    }
  }

  /// 아이디어 북마크/해제 토글
  static Future<void> toggleBookmarkIdea(String ideaId) async {
    try {
      final collection = _ideasCollection;
      if (collection == null) {
        throw Exception('로그인된 사용자가 없습니다.');
      }

      // 현재 아이디어 정보 조회
      final docSnapshot = await collection.doc(ideaId).get();
      if (!docSnapshot.exists) {
        throw Exception('아이디어를 찾을 수 없습니다.');
      }

      final data = docSnapshot.data()!;
      final currentIsBookmarked = data['isBookmarked'] as bool? ?? false;

      if (!currentIsBookmarked) {
        // 북마크 추가
        await collection.doc(ideaId).update({
          'isBookmarked': true,
          'bookmarkedAt': Timestamp.fromDate(DateTime.now()),
        });

        debugPrint('✅ [FIRESTORE] 아이디어 북마크 성공: $ideaId');
      } else {
        // 북마크 해제
        await collection.doc(ideaId).update({
          'isBookmarked': false,
          'bookmarkedAt': null,
        });

        debugPrint('✅ [FIRESTORE] 아이디어 북마크 해제 성공: $ideaId');
      }
    } catch (e) {
      debugPrint('❌ [FIRESTORE] 아이디어 북마크 토글 실패: $e');
      rethrow;
    }
  }
}
