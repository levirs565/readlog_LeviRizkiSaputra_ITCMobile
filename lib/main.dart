import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/data_impl.dart';
import 'package:readlog/route_observer_provider.dart';
import 'package:readlog/ui/books.dart';
import 'package:readlog/ui/home.dart';

late RepositoryProviderImpl _repositoryProvider;
RouteObserver _routeObserver = RouteObserver();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _repositoryProvider = RepositoryProviderImpl();
  await _repositoryProvider.open();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RouteObserverProvider(
      observer: _routeObserver,
      child: RepositoryProviderContext(
        provider: _repositoryProvider,
        child: MaterialApp(
          navigatorObservers: [_routeObserver],
          title: 'Read Log',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
            useMaterial3: true,
          ),
          home: const HomePage(),
        ),
      ),
    );
  }
}