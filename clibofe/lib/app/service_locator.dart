import 'package:get_it/get_it.dart';
import 'package:clibofe/core/services/capture/screen_capturer.dart';
import 'package:clibofe/core/services/capture/implementations/android_screen_capturer.dart';
import 'package:clibofe/core/services/overlay/overlay_controller.dart';
import 'package:clibofe/core/services/overlay/implementations/android_overlay_controller.dart';
import 'package:clibofe/data/repositories/auth/auth_repository.dart';
import 'package:clibofe/data/repositories/auth/auth_repository_remote.dart';
import 'package:clibofe/data/repositories/user/user_repository.dart';
import 'package:clibofe/data/repositories/user/user_repository_local.dart';
import 'package:clibofe/data/services/config_service.dart';
import 'package:clibofe/data/services/chat_history_service.dart';
import 'package:clibofe/data/services/analytics_service.dart';
import 'package:clibofe/data/services/remote_config_service.dart';
import 'package:clibofe/interface/clibo_aI_client.dart';

final locator = GetIt.instance;

void setupServices() {
  locator.registerLazySingleton<ConfigService>(() => ConfigService());
  locator.registerLazySingleton<ChatHistoryService>(() => ChatHistoryService());
  locator.registerLazySingleton<AnalyticsService>(() => AnalyticsService());
  locator.registerLazySingleton<RemoteConfigService>(() => RemoteConfigService());
  locator.registerLazySingleton<ScreenCapturer>(() => AndroidScreenCapturer());
  locator.registerLazySingleton<OverlayController>(() => AndroidOverlayController());

  locator.registerLazySingleton<AuthRepository>(() => AuthRepositoryRemote());
  locator.registerLazySingleton<UserRepository>(() => UserRepositoryLocal());
  locator.registerLazySingleton<CliboAIClient>(() => BackendProxyAIClient());
}
