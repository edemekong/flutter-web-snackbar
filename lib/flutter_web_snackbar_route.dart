import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:flutter_web_snackbar/flutter_web_snackbar.dart';

class FlutterWebSnackbarRoute<T> extends OverlayRoute<T> {
  final FlutterWebSnackbar snackbar;
  final Builder _builder;
  final Completer<T> _transitionCompleter = Completer<T>();
  final FlushbarStatusCallback _onStatusChanged;

  Animation<double> _filterBlurAnimation;
  Animation<Color> _filterColorAnimation;

  Offset _initiallOffset;
  Offset _endOffset;

  bool _wasDismissedBySwipe = false;
  Timer _timer;
  T _result;
  FlutterWebSnackStatus currentStatus;

  FlutterWebSnackbarRoute({
    @required this.snackbar,
    RouteSettings settings,
  })  : _builder = Builder(builder: (BuildContext innerContext) {
          return GestureDetector(
            child: snackbar,
            onTap:
                snackbar.onTap != null ? () => snackbar.onTap(snackbar) : null,
          );
        }),
        _onStatusChanged = snackbar.onStatusChanged,
        super(settings: settings) {
    _configureAlignment(this.snackbar.snackbarPosition);
  }

  void _configureAlignment(FlutterWebSnackPosition snackbarPosition) {
    switch (snackbar.snackbarPosition) {
      case FlutterWebSnackPosition.TopRight:
        {
          _initiallOffset = Offset(0.55, -0.4);
          _endOffset = Offset(0.30, -0.4);
          break;
        }
      case FlutterWebSnackPosition.BottomRight:
        {
          _initiallOffset = Offset(0.55, 0.4);
          _endOffset = Offset(0.30, 0.4);
          break;
        }
      case FlutterWebSnackPosition.Center:
        // TODO: Handle this case.
        break;
      case FlutterWebSnackPosition.TopCenter:
        // TODO: Handle this case.
        break;
      case FlutterWebSnackPosition.BottomCenter:
        // TODO: Handle this case.
        break;
      case FlutterWebSnackPosition.TopLeft:
        // TODO: Handle this case.
        break;
      case FlutterWebSnackPosition.BottomLeft:
        // TODO: Handle this case.
        break;
    }
  }

  Future<T> get completed => _transitionCompleter.future;
  bool get opaque => false;

  @override
  Iterable<OverlayEntry> createOverlayEntries() {
    final List<OverlayEntry> overlays = [];

    if (snackbar.blockBackgroundInteraction) {
      overlays.add(
        OverlayEntry(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: snackbar.isDismissible ? () => snackbar.dismiss() : null,
                child: _createBackgroundOverlay(),
              );
            },
            maintainState: false,
            opaque: opaque),
      );
    }

    overlays.add(
      OverlayEntry(
          builder: (BuildContext context) {
            final Widget annotatedChild = Semantics(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                        parent: _fadeController, curve: Curves.easeInOut)),
                child: SlideTransition(
                  position:
                      Tween<Offset>(begin: _initiallOffset, end: _endOffset)
                          .animate(CurvedAnimation(
                              parent: _controller, curve: Curves.easeInOut)),
                  child: snackbar.isDismissible
                      ? _getDismissibleFlushbar(_builder)
                      : _getFlushbar(),
                ),
              ),
              focused: false,
              container: true,
              explicitChildNodes: true,
            );
            return annotatedChild;
          },
          maintainState: false,
          opaque: opaque),
    );

    return overlays;
  }

  Widget _createBackgroundOverlay() {
    if (_filterBlurAnimation != null && _filterColorAnimation != null) {
      return AnimatedBuilder(
        animation: _filterBlurAnimation,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: _filterBlurAnimation.value,
                sigmaY: _filterBlurAnimation.value),
            child: Container(
              constraints: BoxConstraints.expand(),
              color: _filterColorAnimation.value,
            ),
          );
        },
      );
    }

    if (_filterBlurAnimation != null) {
      return AnimatedBuilder(
        animation: _filterBlurAnimation,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(
                sigmaX: _filterBlurAnimation.value,
                sigmaY: _filterBlurAnimation.value),
            child: Container(
              constraints: BoxConstraints.expand(),
              color: Colors.transparent,
            ),
          );
        },
      );
    }

    if (_filterColorAnimation != null) {
      AnimatedBuilder(
        animation: _filterColorAnimation,
        builder: (context, child) {
          return Container(
            constraints: BoxConstraints.expand(),
            color: _filterColorAnimation.value,
          );
        },
      );
    }

    return Container(
      constraints: BoxConstraints.expand(),
      color: Colors.transparent,
    );
  }

  /// This string is a workaround until Dismissible supports a returning item
  String dismissibleKeyGen = "";

  Widget _getDismissibleFlushbar(Widget child) {
    return Dismissible(
      direction: _getDismissDirection(),
      resizeDuration: null,
      confirmDismiss: (_) {
        if (currentStatus == FlutterWebSnackStatus.IS_APPEARING ||
            currentStatus == FlutterWebSnackStatus.IS_HIDING) {
          return Future.value(false);
        }
        return Future.value(true);
      },
      key: Key(dismissibleKeyGen),
      onDismissed: (_) {
        dismissibleKeyGen += "1";
        _cancelTimer();
        _wasDismissedBySwipe = true;

        // if (isCurrent) {
        //   navigator.pop();
        // } else {
        //   navigator.removeRoute(this);
        // }
      },
      child: _getFlushbar(),
    );
  }

  DismissDirection _getDismissDirection() {
    if (snackbar.dismissDirection ==
        FlutterWebSnackDismissDirection.HORIZONTAL) {
      return DismissDirection.horizontal;
    } else {
      if (snackbar.snackbarPosition == FlutterWebSnackPosition.BottomRight) {
        return DismissDirection.up;
      } else {
        return DismissDirection.down;
      }
    }
  }

  Widget _getFlushbar() {
    return Container(
      margin: snackbar.margin,
      child: _builder,
    );
  }

  @override
  bool get finishedWhenPopped =>
      _controller.status == AnimationStatus.dismissed;

  /// The animation that drives the route's transition and the previous route's
  /// forward transition.
  Animation<Alignment> get animation => _alignmentAnimation;
  Animation<Alignment> _alignmentAnimation;

  /// The animation controller that the route uses to drive the transitions.
  ///
  /// The animation itself is exposed by the [animation] property.
  // @protected
  AnimationController get controller => _controller;
  AnimationController _controller;
  AnimationController _fadeController;

  /// Called to create the animation controller that will drive the transitions to
  /// this route from the previous one, and back to the previous route from this
  /// one.
  ///
  ///
  AnimationController createAnimationController() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(snackbar.animationDuration != null &&
        snackbar.animationDuration >= Duration.zero);
    return AnimationController(
      duration: Duration(seconds: 1),
      debugLabel: debugLabel,
      vsync: navigator,
    );
  }

  AnimationController createFadeAnimationController() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(snackbar.animationDuration != null &&
        snackbar.animationDuration >= Duration.zero);
    return AnimationController(
      duration: Duration(milliseconds: 600),
      debugLabel: debugLabel,
      vsync: navigator,
    );
  }

  /// Called to create the animation that exposes the current progress of
  /// the transition controlled by the animation controller created by
  /// [createAnimationController()].
  Animation<Alignment> createAnimation() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    assert(_controller != null);
    return AlignmentTween(
            begin: Alignment.topCenter, end: Alignment.bottomCenter)
        .animate(
      CurvedAnimation(
        parent: _controller,
        curve: snackbar.forwardAnimationCurve,
        reverseCurve: snackbar.reverseAnimationCurve,
      ),
    );
  }

  Animation<double> createBlurFilterAnimation() {
    if (snackbar.routeBlur == null) return null;

    return Tween(begin: 0.0, end: snackbar.routeBlur).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  Animation<Color> createColorFilterAnimation() {
    if (snackbar.routeColor == null) return null;

    return ColorTween(begin: Colors.transparent, end: snackbar.routeColor)
        .animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          0.0,
          0.35,
          curve: Curves.easeInOutCirc,
        ),
      ),
    );
  }

  //copy of `routes.dart`
  void _handleStatusChanged(AnimationStatus status) {
    switch (status) {
      case AnimationStatus.completed:
        currentStatus = FlutterWebSnackStatus.SHOWING;
        _onStatusChanged(currentStatus);
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = opaque;

        break;
      case AnimationStatus.forward:
        currentStatus = FlutterWebSnackStatus.IS_APPEARING;
        _onStatusChanged(currentStatus);
        break;
      case AnimationStatus.reverse:
        currentStatus = FlutterWebSnackStatus.IS_HIDING;
        _onStatusChanged(currentStatus);
        if (overlayEntries.isNotEmpty) overlayEntries.first.opaque = false;
        break;
      case AnimationStatus.dismissed:
        assert(!overlayEntries.first.opaque);
        // We might still be the current route if a subclass is controlling the
        // the transition and hits the dismissed status. For example, the iOS
        // back gesture drives this animation to the dismissed status before
        // popping the navigator.
        currentStatus = FlutterWebSnackStatus.DISMISSED;
        _onStatusChanged(currentStatus);

        if (!isCurrent) {
          navigator.finalizeRoute(this);
          if (overlayEntries.isNotEmpty) {
            overlayEntries.clear();
          }
          assert(overlayEntries.isEmpty);
        }
        break;
    }
    changedInternalState();
  }

  @override
  void install() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot install a $runtimeType after disposing it.');
    _controller = createAnimationController();
    _fadeController = createFadeAnimationController();
    assert(_controller != null,
        '$runtimeType.createAnimationController() returned null.');
    _filterBlurAnimation = createBlurFilterAnimation();
    _filterColorAnimation = createColorFilterAnimation();
    _alignmentAnimation = createAnimation();
    assert(_alignmentAnimation != null,
        '$runtimeType.createAnimation() returned null.');
    super.install();
  }

  @override
  TickerFuture didPush() {
    assert(_controller != null,
        '$runtimeType.didPush called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    _alignmentAnimation.addStatusListener(_handleStatusChanged);
    _configureTimer();
    super.didPush();
    _fadeController.forward();
    return _controller.forward();
  }

  @override
  void didReplace(Route<dynamic> oldRoute) {
    assert(_controller != null,
        '$runtimeType.didReplace called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');
    if (oldRoute is FlutterWebSnackbarRoute)
      _controller.value = oldRoute._controller.value;

    _alignmentAnimation.addStatusListener(_handleStatusChanged);
    super.didReplace(oldRoute);
  }

  @override
  bool didPop(T result) {
    assert(_controller != null,
        '$runtimeType.didPop called before calling install() or after calling dispose().');
    assert(!_transitionCompleter.isCompleted,
        'Cannot reuse a $runtimeType after disposing it.');

    _result = result;
    _cancelTimer();

    if (_wasDismissedBySwipe) {
      Timer(Duration(milliseconds: 200), () {
        _controller.reset();
        _fadeController.reset();
      });

      _wasDismissedBySwipe = false;
    } else {
      _fadeController.reverse();
      _controller.reverse();
    }
    return super.didPop(result);
  }

  void _configureTimer() {
    if (snackbar.duration != null) {
      if (_timer != null && _timer.isActive) {
        _timer.cancel();
      }
      _timer = Timer(snackbar.duration, () {
        if (this.isCurrent) {
          navigator.pop();
        } else if (this.isActive) {
          navigator.removeRoute(this);
        }
      });
    } else {
      if (_timer != null) {
        _timer.cancel();
      }
    }
  }

  void _cancelTimer() {
    if (_timer != null && _timer.isActive) {
      _timer.cancel();
    }
  }

  /// Whether this route can perform a transition to the given route.
  ///
  /// Subclasses can override this method to restrict the set of routes they
  /// need to coordinate transitions with.
  bool canTransitionTo(FlutterWebSnackbarRoute<dynamic> nextRoute) => true;

  /// Whether this route can perform a transition from the given route.
  ///
  /// Subclasses can override this method to restrict the set of routes they
  /// need to coordinate transitions with.
  bool canTransitionFrom(FlutterWebSnackbarRoute<dynamic> previousRoute) =>
      true;

  @override
  void dispose() {
    assert(!_transitionCompleter.isCompleted,
        'Cannot dispose a $runtimeType twice.');
    _controller?.dispose();
    _transitionCompleter.complete(_result);
    super.dispose();
  }

  /// A short description of this route useful for debugging.
  String get debugLabel => '$runtimeType';

  @override
  String toString() => '$runtimeType(animation: $_controller)';
}

FlutterWebSnackbarRoute showWebSnack<T>(
    {BuildContext context, FlutterWebSnackbar snackbar}) {
  assert(snackbar != null);
  return FlutterWebSnackbarRoute<T>(
    snackbar: snackbar,
    // settings: RouteSettings(name: FLUSHBAR_ROUTE_NAME),
  );
}
