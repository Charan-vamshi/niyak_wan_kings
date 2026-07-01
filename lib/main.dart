import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/game_state.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final gameState = GameState();
  await gameState.load();
  runApp(NiyakApp(gameState: gameState));
}

class NiyakApp extends StatelessWidget {
  final GameState gameState;
  const NiyakApp({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameState,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: gameState.isDarkTheme ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: gameState.isDarkTheme
                ? const Color(0xFF0D0D1A)
                : const Color(0xFFF5F5F5),
          ),
          home: HomeScreen(gameState: gameState),
        );
      },
    );
  }
}