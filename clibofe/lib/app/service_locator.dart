import 'package:get_it/get_it.dart';
import '../core/services/capture/screen_capturer.dart';
import '../core/services/capture/implementations/android_screen_capturer.dart';
import '../core/services/overlay/overlay_controller.dart';
import '../core/services/overlay/implementations/android_overlay_controller.dart';
import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/user/user_repository.dart';
import '../data/repositories/user/user_repository_local.dart';

final locator = GetIt.instance;

void setupServices() {
  locator.registerLazySingleton<ScreenCapturer>(() => AndroidScreenCapturer());
  locator.registerLazySingleton<OverlayController>(() => AndroidOverlayController());

  locator.registerLazySingleton<AuthRepository>(() => AuthRepositoryRemote());
  locator.registerLazySingleton<UserRepository>(() => UserRepositoryLocal());
}