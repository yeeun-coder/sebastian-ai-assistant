import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sebastian_app/services/persona_service.dart';

class AIController extends GetxController {
  var id = "sebastian1".obs;
  var name = "비서봇".obs;
  var image = "assets/images/logo.png".obs;
  var message = "안녕하세요. 무엇을 도와드릴까요?".obs;

  /// 페르소나 변경 시 증가. TC 위젯이 이 값을 감시하여 채팅 히스토리를 리로드한다.
  final RxInt chatHistoryVersion = 0.obs;

  // 서버 페르소나 type → id 캐시 (앱 시작 시 1회만 조회)
  Map<String, int>? _personaTypeMap;

  @override
  void onInit() {
    super.onInit();
    loadAI();
  }

  Future<void> selectAI(
    String i,
    String n,
    String img,
    String m,
    String personaType,
  ) async {
    id.value = i;
    name.value = n;
    image.value = img;
    message.value = m;
    saveAI();

    // 서버에 활성 페르소나 변경 요청 (실패해도 로컬 UI는 유지)
    try {
      _personaTypeMap ??= await PersonaService.getPersonaTypeMap();
      final personaId = _personaTypeMap![personaType];
      if (personaId != null) {
        await PersonaService.setActivePersona(personaId);
        // 서버가 히스토리를 삭제했으므로 TC에 리로드 신호를 보낸다.
        chatHistoryVersion.value++;
      }
    } catch (_) {
      // 비로그인 상태 또는 네트워크 오류 시 무시
    }
  }

  // 저장
  void saveAI() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("ai_id", id.value);
    await prefs.setString("ai_name", name.value);
    await prefs.setString("ai_image", image.value);
    await prefs.setString("ai_message", message.value);
  }

  // 불러오기
  void loadAI() async {
    final prefs = await SharedPreferences.getInstance();

    id.value = prefs.getString("ai_id") ?? id.value;
    name.value = prefs.getString("ai_name") ?? name.value;
    image.value = prefs.getString("ai_image") ?? image.value;
    message.value = prefs.getString("ai_message") ?? message.value;
  }
}
