import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sebastian_app/routes/app_routes.dart';
import 'package:sebastian_app/services/auth_session.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
  with TickerProviderStateMixin {                     // 움직이는? 애니메이션 기능..? 암튼 이거 쓰겟습니다
    late AnimationController _animationController;    // 애니메이션 관리하는 리모컨
    late Animation<double> _fadeAnimation;            // 투명 -> 불투명 효과
    late Animation<double> _scaleAnimation;           // 작앗다가 점점 커지는!! 효과

    @override
    void initState() {                                // 시작하자마자 자동으로 실행합니다?
      super.initState();                              // 필수로 해야되는? 부모 초기화...? 사실 이거 ㅁㄹ겟어요ㅠ

      _animationController = AnimationController(     // 애니메이션 리모컨 생성
        duration: const Duration(seconds: 2),         // 2초동안 실행합니다?   
        vsync: this                                   // 화면, 애니 동기화해서 버..ㅂ벅..버벅...임 방지
      ); 

      _fadeAnimation = Tween<double> (                // 값 변경 설정?
        begin: 0.0,                                   // 안보여유~
        end: 1.0,                                     // 보여유~
      ).animate(CurvedAnimation(                      // 부드럽게 변화
        parent: _animationController,                 // 컨트롤러 연결
        curve: Curves.easeIn,                         // 천천~히~ 나타남
      ));

      _scaleAnimation = Tween<double>(                // 크기 변경 설정
        begin: 0.5,                                   // 작아유~
        end: 1.0,                                     // 커유~
      ).animate(CurvedAnimation(                      // 부드럽게 변화
        parent: _animationController,                 // 컨트롤러 연결
        curve: Curves.elasticOut,                     // 튕겨지면서 커지는...? 효과
      ));

      _animationController.forward();
      _navigateAfterSplash();
    }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    final restored = await AuthSession.tryRestore();
    if (!mounted) return;

    if (restored) {
      Get.offAllNamed(
        AppRoutes.briefing,
        arguments: {'fromLogin': true},
      );
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

    @override
    void dispose() {                                   // 종료될 때 실행합니다?
      _animationController.dispose();                  // 애니메이션 메모리 정리
      super.dispose();                                 // 부모... 정리...
    }

  @override
  Widget build(BuildContext context) {                // UI 만드는 함수
    return Scaffold(                                  // 기본 화면 틀
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),           // 배경색 설정
      body: Center(                                   // 가운데로 모여~~
        child: AnimatedBuilder(                       // 애니메이션 상태 확인하고 UI 업뎃
          animation: _animationController,            // 컨트롤러 연결
          builder: (context, child) {                 // 애니메이션이 변할 때마다 실행하셈
            return FadeTransition(                    // 투명도 적용
              opacity: _fadeAnimation,                // fade 애니메이션 연결	
              child: ScaleTransition(                 // 크기 변화 적용
                scale: _scaleAnimation,               // scale 애니 연결
                child: Column(                        // UI 세로 배치
                  mainAxisAlignment: MainAxisAlignment.center, // 가운데로 모여~
                  children: [                         // 내부 요소? 시작
                    Container(                        // 박스 하나 생성
                      width: 180,                     // 가로
                      height: 300,                    // 세로
                      child: Image.asset(             // 이미지 삽입
                        'assets/images/logo2.png',    // 이미지 위치
                        fit: BoxFit.contain,          // 비율 깨짐 방지 
                      ),
                    ),
                    const SizedBox(height: 32),
                    const SizedBox(height: 64),

                    const CircularProgressIndicator(  // 처리 중이니까 기다리셈~
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}