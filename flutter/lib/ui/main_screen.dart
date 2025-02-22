import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:mlperfbench/app_constants.dart';
import 'package:mlperfbench/benchmark/state.dart';
import 'package:mlperfbench/icons.dart';
import 'package:mlperfbench/localizations/app_localizations.dart';
import 'package:mlperfbench/store.dart';
import 'package:mlperfbench/ui/app_bar.dart';
import 'package:mlperfbench/ui/confirm_dialog.dart';
import 'package:mlperfbench/ui/error_dialog.dart';
import 'package:mlperfbench/ui/list_of_benchmark_items.dart';
import 'package:mlperfbench/ui/progress_screen.dart';
import 'package:mlperfbench/ui/result_screen.dart';

class MainKeys {
  // list of widget keys that need to be accessed in the test code
  static const String goButton = 'goButton';
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<BenchmarkState>();
    final stringResources = AppLocalizations.of(context);

    PreferredSizeWidget? appBar;

    switch (state.state) {
      case BenchmarkStateEnum.downloading:
      case BenchmarkStateEnum.waiting:
        appBar = MyAppBar.buildAppBar(stringResources.mainTitle, context, true);
        break;
      case BenchmarkStateEnum.aborting:
        appBar =
            MyAppBar.buildAppBar(stringResources.mainTitle, context, false);
        break;
      case BenchmarkStateEnum.cooldown:
      case BenchmarkStateEnum.running:
        return ProgressScreen();
      case BenchmarkStateEnum.done:
        return ResultScreen();
    }

    return Scaffold(
      appBar: appBar,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(flex: 6, child: _getContainer(context, state.state)),
            Padding(
              padding: EdgeInsets.all(30),
              child: Text(stringResources.measureCapability,
                  style: TextStyle(fontSize: 16, color: AppColors.darkText)),
            ),
            Expanded(
              flex: 5,
              child: Align(
                  alignment: Alignment.topCenter,
                  child: createListOfBenchmarkItemsWidgets(context, state)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getContainer(BuildContext context, BenchmarkStateEnum state) {
    if (state == BenchmarkStateEnum.aborting) {
      return _waitContainer(context);
    }

    if (state == BenchmarkStateEnum.waiting) {
      return _goContainer(context);
    }

    return _downloadContainer(context);
  }

  Widget _waitContainer(BuildContext context) {
    final stringResources = AppLocalizations.of(context);

    return _circleContainerWithContent(
        context, AppIcons.waiting, stringResources.waitBenchmarks);
  }

  Widget _goContainer(BuildContext context) {
    final state = context.watch<BenchmarkState>();
    final store = context.watch<Store>();
    final stringResources = AppLocalizations.of(context);

    return CustomPaint(
      painter: MyPaintBottom(),
      child: GoButtonGradient(() async {
        // TODO (anhappdev) Refactor the code here to avoid duplicated code.
        // The checks before calling state.runBenchmarks() in main_screen and result_screen are similar.
        final wrongPathError = await state.validateExternalResourcesDirectory(
            stringResources.incorrectDatasetsPath);
        if (wrongPathError.isNotEmpty) {
          await showErrorDialog(context, [wrongPathError]);
          return;
        }
        if (store.offlineMode) {
          final offlineError = await state
              .validateOfflineMode(stringResources.warningOfflineModeEnabled);
          if (offlineError.isNotEmpty) {
            switch (await showConfirmDialog(context, offlineError)) {
              case ConfirmDialogAction.ok:
                break;
              case ConfirmDialogAction.cancel:
                return;
              default:
                break;
            }
          }
        }
        state.runBenchmarks();
      }),
    );
  }

  Widget _downloadContainer(BuildContext context) {
    final stringResources = AppLocalizations.of(context);
    final textLabel = Text(context.watch<BenchmarkState>().downloadingProgress,
        style: TextStyle(color: AppColors.lightText, fontSize: 40));

    return _circleContainerWithContent(
        context, textLabel, stringResources.loadingContent);
  }
}

class MyPaintBottom extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect =
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: size.height);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomLeft,
        colors: AppColors.mainScreenGradient,
      ).createShader(rect);
    canvas.drawArc(rect, 0, pi, true, paint);
  } // paint

  @override
  bool shouldRepaint(MyPaintBottom old) => false;
}

class GoButtonGradient extends StatelessWidget {
  final AsyncCallback onPressed;

  GoButtonGradient(this.onPressed);

  @override
  Widget build(BuildContext context) {
    final stringResources = AppLocalizations.of(context);

    var decoration = BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: AppColors.runBenchmarkCircleGradient,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          offset: Offset(15, 15),
          blurRadius: 10,
        )
      ],
    );

    return Container(
      decoration: decoration,
      width: MediaQuery.of(context).size.width * 0.35,
      child: MaterialButton(
        key: Key(MainKeys.goButton),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        splashColor: Colors.black,
        shape: CircleBorder(),
        onPressed: onPressed,
        child: Text(
          stringResources.go,
          style: TextStyle(
            color: AppColors.lightText,
            fontSize: 40,
          ),
        ),
      ),
    );
  }
}

Widget _circleContainerWithContent(
    BuildContext context, Widget contentInCircle, String label) {
  return CustomPaint(
    painter: MyPaintBottom(),
    child: Stack(alignment: Alignment.topCenter, children: [
      Container(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            label,
            style: TextStyle(color: AppColors.lightText, fontSize: 15),
          ),
        ),
      ),
      Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.progressCircle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(15, 15),
                  blurRadius: 10,
                )
              ],
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            alignment: Alignment.center,
            child: contentInCircle,
          )
        ],
      )
    ]),
  );
}
