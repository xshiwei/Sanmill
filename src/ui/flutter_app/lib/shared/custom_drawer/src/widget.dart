// This file is part of Sanmill.
// Copyright (C) 2019-2023 The Sanmill developers (see AUTHORS file)
//
// Sanmill is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Sanmill is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

part of '../custom_drawer.dart';

/// CustomDrawer Widget
///
/// The widget laying out the custom drawer
class CustomDrawer extends StatefulWidget {
  const CustomDrawer({
    super.key,
    required this.child,
    required this.items,
    required this.header,
    this.controller,
    this.disabledGestures = false,
    required this.orientation,
  });

  /// Child widget. (Usually a widget that represents the main screen)
  final Widget child;

  /// Controller that controls the widget state. By default a new controller will be generated.
  final CustomDrawerController? controller;

  /// Disables the gestures.
  final bool disabledGestures;

  /// Items the drawer holds
  // ignore: always_specify_types
  final List<CustomDrawerItem<dynamic>> items;

  /// Header widget of the drawer
  final Widget header;

  final Orientation orientation;

  @override
  CustomDrawerState createState() => CustomDrawerState();
}

class CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  late final CustomDrawerController _controller;
  late final AnimationController _animationController;
  late Animation<Offset> _childSlideAnimation;
  late final Animation<Offset> _overlaySlideAnimation;
  late double _offsetValue;
  late Offset _freshPosition;
  late Offset _startPosition;
  bool _captured = false;

  static const Duration _duration = Duration(milliseconds: 250);
  static const double _slideThreshold = 0.25;
  static const int _slideVelocityThreshold = 1300;
  late double _openRatio;
  static const double _overlayRadius = 28.0;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? CustomDrawerController();
    _controller.addListener(_handleControllerChanged);

    _animationController = AnimationController(
      vsync: this,
      duration: _duration,
      value: _controller.value.visible ? 1 : 0,
    );

    _overlaySlideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(
      _animationController,
    );

    _openRatio = widget.orientation == Orientation.portrait ? 0.75 : 0.45;

    _childSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(_openRatio, 0),
    ).animate(
      _animationController,
    );
  }

  Widget buildListMenus() {
    return SliverToBoxAdapter(
      child: ListView.builder(
        controller: ScrollController(),
        padding: const EdgeInsets.only(top: 4.0),
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.items.length,
        itemBuilder: _buildItem,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant CustomDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orientation != widget.orientation) {
      _openRatio = widget.orientation == Orientation.portrait ? 0.75 : 0.45;

      _childSlideAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: Offset(_openRatio, 0),
      ).animate(
        _animationController,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Align drawer = Align(
      alignment: AlignmentDirectional.topStart,
      child: FractionallySizedBox(
        widthFactor: _openRatio,
        child: Material(
          color: DB().colorSettings.drawerColor,
          child: CustomScrollView(
            slivers: <Widget>[
              SliverPinnedToBoxAdapter(
                child: Container(
                    decoration:
                        BoxDecoration(color: DB().colorSettings.drawerColor),
                    child: widget.header),
              ),
              buildListMenus()
            ],
          ),
        ),
      ),
    );

    /// Menu and arrow icon animation overlay
    final IconButton drawerOverlay = IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.arrow_menu,
        progress: ReverseAnimation(_animationController),
        color: Colors.white,
      ),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: () => _controller.toggleDrawer(),
    );

    final SlideTransition mainView = SlideTransition(
      position: _childSlideAnimation,
      textDirection: Directionality.of(context),
      child: ValueListenableBuilder<CustomDrawerValue>(
        valueListenable: _controller,
        // TODO: [Leptopoda] Why isn't it working with GestureDetector?
        builder: (_, CustomDrawerValue value, Widget? child) => InkWell(
          onTap: _controller.hideDrawer,
          focusColor: Colors.transparent,
          child: IgnorePointer(
            ignoring: value.visible,
            child: child,
          ),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.drawerBoxerShadowColor,
                blurRadius: 24,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );

    return GestureDetector(
      onHorizontalDragStart: widget.disabledGestures ? null : _handleDragStart,
      onHorizontalDragUpdate:
          widget.disabledGestures ? null : _handleDragUpdate,
      onHorizontalDragEnd: widget.disabledGestures ? null : _handleDragEnd,
      onHorizontalDragCancel:
          widget.disabledGestures ? null : _handleDragCancel,
      child: Stack(
        children: <Widget>[
          drawer,
          DrawerIcon(
            icon: drawerOverlay,
            child: mainView,
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    // ignore: always_specify_types
    final CustomDrawerItem<dynamic> item = widget.items[index];

    final double itemPadding = window.physicalSize.height >= 1080
        ? AppTheme.drawerItemPadding
        : AppTheme.drawerItemPaddingSmallScreen;

    final Widget child;

    if (item.selected) {
      final SlideTransition overlay = SlideTransition(
        position: _overlaySlideAnimation,
        textDirection: Directionality.of(context),
        child: Container(
          width: MediaQuery.of(context).size.width * _openRatio * 0.9,
          height: AppTheme.drawerItemHeight +
              (DB().displaySettings.fontScale - 1) * 12,
          decoration: BoxDecoration(
            color: DB().colorSettings.drawerHighlightItemColor,
            borderRadius: const BorderRadiusDirectional.horizontal(
              end: Radius.circular(_overlayRadius),
            ),
          ),
        ),
      );

      child = Stack(
        children: <Widget>[
          overlay,
          item,
        ],
      );
    } else {
      child = item;
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: itemPadding),
      child: child,
    );
  }

  void _handleControllerChanged() {
    _controller.value.visible
        ? _animationController.forward()
        : _animationController.reverse();
  }

  void _handleDragStart(DragStartDetails details) {
    _captured = true;
    _startPosition = details.globalPosition;
    _offsetValue = _animationController.value;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_captured) {
      return;
    }

    final Size screenSize = MediaQuery.of(context).size;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    _freshPosition = details.globalPosition;

    final double diff = (_freshPosition - _startPosition).dx;

    _animationController.value = _offsetValue +
        (diff / (screenSize.width * _openRatio)) * (rtl ? -1 : 1);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_captured) {
      return;
    }

    _captured = false;

    if (_controller.value.visible) {
      if (_animationController.value <= 1 - _slideThreshold ||
          details.primaryVelocity! <= -_slideVelocityThreshold) {
        _controller.hideDrawer();
      } else {
        _animationController.forward();
      }
    } else {
      if (_animationController.value >= _slideThreshold ||
          details.primaryVelocity! >= _slideVelocityThreshold) {
        _controller.showDrawer();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _handleDragCancel() {
    _captured = false;
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _animationController.dispose();

    _controller.dispose();

    super.dispose();
  }
}
