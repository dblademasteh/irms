import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'core/storage.dart';
import 'core/dio_client.dart';
import 'core/socket_client.dart';
import 'core/network_discovery.dart';
import 'core/locale_cubit.dart';
import 'core/theme_cubit.dart';
import 'features/auth/repo/auth_repo.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'features/incidents/repo/incident_repo.dart';
import 'features/incidents/cubit/incident_cubit.dart';
import 'features/dispatcher/repo/dispatcher_repo.dart';
import 'features/dispatcher/cubit/dispatcher_cubit.dart';
import 'features/admin/repo/admin_repo.dart';
import 'features/admin/cubit/admin_cubit.dart';
import 'features/contacts/repo/contacts_repo.dart';
import 'features/contacts/cubit/contacts_cubit.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureStorage();

  final baseUrl = await NetworkDiscovery.detect();
  final dioClient = DioClient(storage, baseUrl: baseUrl);
  final socketClient = SocketClient(storage, baseUrl: baseUrl);

  final authRepo = AuthRepo(dioClient);
  final incidentRepo = IncidentRepo(dioClient);
  final dispatcherRepo = DispatcherRepo(dioClient);
  final adminRepo = AdminRepo(dioClient);
  final contactsRepo = ContactsRepo(dioClient);

  final token = await storage.getAccessToken();
  Map<String, dynamic>? user;
  if (token != null) {
    try {
      user = await authRepo.getCurrentUser();
    } catch (e) {
      await storage.clearAll();
      user = null;
    }
  }

  final router = createRouter(user != null);
  final localeCubit = LocaleCubit();
  final themeCubit = ThemeCubit();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storage),
        RepositoryProvider.value(value: dioClient),
        RepositoryProvider.value(value: socketClient),
        RepositoryProvider.value(value: authRepo),
        RepositoryProvider.value(value: incidentRepo),
        RepositoryProvider.value(value: dispatcherRepo),
        RepositoryProvider.value(value: adminRepo),
        RepositoryProvider.value(value: contactsRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthCubit(authRepo, storage)..restoreSession(user),
          ),
          BlocProvider.value(value: localeCubit),
          BlocProvider.value(value: themeCubit),
          BlocProvider(
            create: (_) => IncidentCubit(incidentRepo),
          ),
          BlocProvider(
            create: (_) => DispatcherCubit(dispatcherRepo),
          ),
          BlocProvider(
            create: (_) => AdminCubit(adminRepo),
          ),
          BlocProvider(
            create: (_) => ContactsCubit(contactsRepo)..loadContacts(),
          ),
        ],
        child: IrmsApp(router: router),
      ),
    ),
  );
}

class IrmsApp extends StatelessWidget {
  final GoRouter router;
  const IrmsApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp.router(
              title: 'IRMS',
              debugShowCheckedModeBanner: false,
              theme: IrmsTheme.light,
              darkTheme: IrmsTheme.dark,
              themeMode: themeMode,
              routerConfig: router,
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        );
      },
    );
  }
}
