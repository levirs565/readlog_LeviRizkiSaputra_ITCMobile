import 'package:flutter/widgets.dart';
import 'repositories.dart';

class RepositoryProviderContext extends InheritedWidget {
  final RepositoryProvider provider;

  const RepositoryProviderContext({
    super.key,
    required this.provider,
    required super.child
  });

  // static RepositoryProvider of(BuildContext context) {
  //   final result = context.dependOnInheritedWidgetOfExactType<RepositoryProviderContext>();
  //   assert(result != null, "No RepositoryProviderContext found");
  //   return result!.provider;
  // }

  static RepositoryProvider get(BuildContext context) {
    final result = context.getInheritedWidgetOfExactType<RepositoryProviderContext>();
    assert(result != null, "Not RepositoryProviderContext found");
    return result!.provider;
  }

  @override
  bool updateShouldNotify(RepositoryProviderContext oldContext) =>
      provider != oldContext.provider;
}
