import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:readlog/data_context.dart';
import 'package:readlog/data_impl.dart';
import 'package:readlog/ui/home.dart';

late RepositoryProviderImpl repositoryProvider;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  repositoryProvider = RepositoryProviderImpl();
  await repositoryProvider.open();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return RepositoryProviderContext(
      provider: repositoryProvider,
      child: MaterialApp(
        title: 'Read Log',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: Builder(builder: (context) => HomePage.create(context)),
      ),
    );
  }
}