import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme.dart';
import 'core/router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'core/services/api_client.dart';
import 'core/services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const KaziApp());
}

class KaziApp extends StatelessWidget {
  const KaziApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => StorageService()),
        RepositoryProvider(create: (ctx) => ApiClient(ctx.read<StorageService>())),
        RepositoryProvider(
          create: (ctx) => AuthRepository(ctx.read<ApiClient>()),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthBloc(ctx.read<AuthRepository>())
              ..add(AuthCheckStatusEvent()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Kazi',
          theme: KaziTheme.lightTheme,
          routerConfig: AppRouter().router,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
