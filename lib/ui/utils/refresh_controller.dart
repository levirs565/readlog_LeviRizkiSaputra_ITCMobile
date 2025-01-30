import 'package:flutter/cupertino.dart';
import 'package:readlog/ui/utils/route_observer_provider.dart';

class RefreshController with RouteAware {
  RouteObserver? _observer;
  List<Listenable> _notifiers = [];
  bool _isInRoute = true;
  bool _needRefresh = false;

  final void Function() doRefresh;

  RefreshController(this.doRefresh);

  @override
  void didPushNext() {
    _isInRoute = false;
    super.didPushNext();
  }

  @override
  void didPopNext() {
    _isInRoute = true;
    if (_needRefresh) {
      doRefresh();
      _needRefresh = false;
    }
    super.didPopNext();
  }


  void _onNotify() {
    if (_isInRoute) {
      doRefresh();
    } else {
      _needRefresh = true;
    }
  }

  void _subscribeNotifier() {
    for (final notifier in _notifiers) {
      notifier.addListener(_onNotify);
    }
  }

  void _unsubscribeNotifier() {
    for (final notifier in _notifiers) {
      notifier.removeListener(_onNotify);
    }
  }

  void init(BuildContext context, List<Listenable> notifiers) {
    final oldObserver = _observer;
    _observer = RouteObserverProvider.of(context);
    if (oldObserver != _observer) {
      oldObserver?.unsubscribe(this);
      _observer?.subscribe(this, ModalRoute.of(context)!);
    }

    if (notifiers != _notifiers) {
      _unsubscribeNotifier();
      _notifiers = notifiers;
      _subscribeNotifier();
    }

    if (oldObserver == null) {
      doRefresh();
    }
  }

  void dispose() {
    _observer?.unsubscribe(this);
    _unsubscribeNotifier();
  }
}
