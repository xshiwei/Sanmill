import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sanmill/generated/l10n.dart';
import 'package:sanmill/style/app_theme.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer(
      {Key? key,
      this.screenIndex,
      this.iconAnimationController,
      this.callBackIndex})
      : super(key: key);

  final AnimationController? iconAnimationController;
  final DrawerIndex? screenIndex;
  final Function(DrawerIndex?)? callBackIndex;

  @override
  _HomeDrawerState createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  late List<DrawerList> drawerList;
  @override
  void initState() {
    super.initState();
  }

  void setDrawerListArray() {
    drawerList = <DrawerList>[
      DrawerList(
        index: DrawerIndex.humanVsAi,
        labelName: S.of(context).humanVsAi,
        icon: Icon(Icons.person),
      ),
      DrawerList(
        index: DrawerIndex.humanVsHuman,
        labelName: S.of(context).humanVsHuman,
        icon: Icon(Icons.group),
      ),
      DrawerList(
        index: DrawerIndex.aiVsAi,
        labelName: S.of(context).aiVsAi,
        icon: Icon(Icons.computer),
      ),
      DrawerList(
        index: DrawerIndex.settings,
        labelName: S.of(context).settings,
        icon: Icon(Icons.settings),
      ),
      DrawerList(
        index: DrawerIndex.ruleSettings,
        labelName: S.of(context).ruleSettings,
        icon: Icon(Icons.rule),
      ),
      DrawerList(
        index: DrawerIndex.personalization,
        labelName: S.of(context).personalization,
        icon: Icon(Icons.color_lens),
      ),
      DrawerList(
        index: DrawerIndex.Help,
        labelName: S.of(context).help,
        icon: Icon(Icons.help),
      ),
      /*
      DrawerList(
        index: DrawerIndex.FeedBack,
        labelName: S.of(context).feedback,
        icon: Icon(Icons.feedback),
      ),
      DrawerList(
        index: DrawerIndex.Invite,
        labelName: S.of(context).inviteFriend,
        icon: Icon(Icons.group),
      ),
      DrawerList(
        index: DrawerIndex.Share,
        labelName: S.of(context).rateTheApp,
        icon: Icon(Icons.share),
      ),
      */
      DrawerList(
        index: DrawerIndex.About,
        labelName: S.of(context).about,
        icon: Icon(Icons.info),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    setDrawerListArray();

    const colorizeColors = AppTheme.animatedTextsColors;

    const colorizeTextStyle = TextStyle(
      fontSize: 24.0,
      fontWeight: FontWeight.w600,
    );

    var animatedBuilder = AnimatedBuilder(
      animation: widget.iconAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return ScaleTransition(
          scale: AlwaysStoppedAnimation<double>(
              1.0 - (widget.iconAnimationController!.value) * 0.2),
          child: RotationTransition(
            turns: AlwaysStoppedAnimation<double>(
                Tween<double>(begin: 0.0, end: 24.0)
                        .animate(CurvedAnimation(
                            parent: widget.iconAnimationController!,
                            curve: Curves.fastOutSlowIn))
                        .value /
                    360),
          ),
        );
      },
    );

    var animatedTextKit = AnimatedTextKit(
      animatedTexts: [
        ColorizeAnimatedText(
          S.of(context).appName,
          textStyle: colorizeTextStyle,
          colors: colorizeColors,
          textAlign: TextAlign.start,
          speed: const Duration(milliseconds: 3000),
        ),
      ],
      pause: const Duration(milliseconds: 30000),
      repeatForever: true,
      stopPauseOnTap: true,
    );

    return Scaffold(
      backgroundColor: AppTheme.drawerBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 0.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  animatedBuilder,
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 4),
                    child: animatedTextKit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Divider(
            height: 1,
            color: AppTheme.drawerDividerColor,
          ),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(0.0),
              itemCount: drawerList.length,
              itemBuilder: (BuildContext context, int index) {
                return inkwell(drawerList[index]);
              },
            ),
          ),
          Divider(
            height: 1,
            color: AppTheme.drawerDividerColor,
          ),
          Column(
            children: <Widget>[
              ListTile(
                title: Text(
                  S.of(context).exit,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: AppTheme.exitTextColor,
                  ),
                  textAlign: TextAlign.left,
                ),
                trailing: Icon(
                  Icons.power_settings_new,
                  color: AppTheme.exitIconColor,
                ),
                onTap: () async {
                  await SystemChannels.platform
                      .invokeMethod<void>('SystemNavigator.pop');
                },
              ),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget inkwell(DrawerList listData) {
    var animatedBuilder = AnimatedBuilder(
      animation: widget.iconAnimationController!,
      builder: (BuildContext context, Widget? child) {
        return Transform(
          transform: Matrix4.translationValues(
              (MediaQuery.of(context).size.width * 0.75 - 64) *
                  (1.0 - widget.iconAnimationController!.value - 1.0),
              0.0,
              0.0),
          child: Padding(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.75 - 64,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.drawerHighlightItemColor,
                borderRadius: new BorderRadius.only(
                  topLeft: Radius.circular(0),
                  topRight: Radius.circular(28),
                  bottomLeft: Radius.circular(0),
                  bottomRight: Radius.circular(28),
                ),
              ),
            ),
          ),
        );
      },
    );

    var listDataText = Text(
      listData.labelName,
      style: TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 16,
        color: widget.screenIndex == listData.index
            ? AppTheme.drawerHighlightTextColor
            : AppTheme.drawerTextColor,
      ),
      textAlign: TextAlign.left,
    );

    var listDataIcon = Icon(listData.icon!.icon,
        color: widget.screenIndex == listData.index
            ? AppTheme.drawerHighlightIconColor
            : AppTheme.drawerIconColor);

    var children3 = <Widget>[
      Container(
        width: 6.0,
        height: 46.0,
      ),
      const Padding(
        padding: EdgeInsets.all(4.0),
      ),
      listData.isAssetsImage // TODO
          ? Container(
              width: 24,
              height: 24,
              child: Image.asset(listData.imageName,
                  color: widget.screenIndex == listData.index
                      ? AppTheme.drawerHighlightIconColor
                      : AppTheme.drawerIconColor),
            )
          : listDataIcon,
      const Padding(
        padding: EdgeInsets.all(4.0),
      ),
      listDataText,
    ];

    var children2 = <Widget>[
      Container(
        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
        child: Row(
          children: children3,
        ),
      ),
      widget.screenIndex == listData.index ? animatedBuilder : const SizedBox()
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        splashColor: AppTheme.drawerSplashColor,
        highlightColor: AppTheme.drawerHightlightColor,
        onTap: () {
          navigationToScreen(listData.index);
        },
        child: Stack(
          children: children2,
        ),
      ),
    );
  }

  Future<void> navigationToScreen(DrawerIndex? indexScreen) async {
    widget.callBackIndex!(indexScreen);
  }
}

enum DrawerIndex {
  humanVsAi,
  humanVsHuman,
  aiVsAi,
  settings,
  ruleSettings,
  personalization,
  Help,
  About
}

class DrawerList {
  DrawerList({
    this.isAssetsImage = false,
    this.labelName = '',
    this.icon,
    this.index,
    this.imageName = '',
  });

  String labelName;
  Icon? icon;
  bool isAssetsImage;
  String imageName;
  DrawerIndex? index;
}
