import 'package:get/get.dart';

class UserController extends GetxController {
  var name = "".obs;
  var age = 0.obs;
  var gender = "".obs;
  var profileImage = RxnString();

  void setUser(String n, int a, String g) {
    name.value = n;
    age.value = a;
    gender.value = g;
  }

  void setProfileImage(String? url) {
    profileImage.value = url;
  }
}