import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapioca_v2/tapioca_v2.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/utils/helpers.dart';
import 'package:video_editor/src/models/cover_data.dart';
import 'package:video_editor/src/models/transform_data.dart';
import 'package:video_editor/src/widgets/crop/crop_mixin.dart';
import 'package:video_editor/video_editor.dart';

class AddTextViewer extends StatefulWidget {
  /// It is the viewer that show the selected cover
  const AddTextViewer({
    super.key,
    required this.controller,
    this.noCoverText = 'No selection',
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate the crop parameters in the cover view
  final VideoEditorController controller;

  /// The [noCoverText] param specifies the text to display when selectedCover is `null`
  final String noCoverText;

  @override
  State<AddTextViewer> createState() => _CoverViewerState();
}

class _CoverViewerState extends State<AddTextViewer> with CropPreviewMixin {

  late VideoEditorController controller;
  late File _video;
  bool isLoading = false;
  static const EventChannel _channel =
      const EventChannel('video_editor_progress');
  late StreamSubscription _streamSubscription;
  int processPercentage = 0;

  void _enableEventReceiver() {
    _streamSubscription =
        _channel.receiveBroadcastStream().listen((dynamic event) {
      setState(() {
        processPercentage = (event.toDouble() * 100).round();
      });
    }, onError: (dynamic error) {
      print('Received error: ${error.message}');
    }, cancelOnError: true);
  }

  void _disableEventReceiver() {
    _streamSubscription.cancel();
  }


  vText() async{
    var tempDir = await getTemporaryDirectory();
                      final path =
                          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}result.mp4';
                      print(tempDir);
    try {
      final tapiocaBalls = [
        TapiocaBall.filter(Filters.pink, 0.2),
        TapiocaBall.textOverlay(
            "text", 100, 100, 100, const Color(0xffffc0cb)),
      ];
      print("will start");
      final cup = Cup(Content(widget.controller.file.path), tapiocaBalls);
      cup.suckUp(path).then((_) async {
        print("finished");
        setState(() {
          processPercentage = 0;
        });
        print("path");
        print(path);
print("path");
      controller =  VideoEditorController.file(
          File(path),
          minDuration: const Duration(seconds: 1),
          maxDuration: const Duration(seconds: 90),
        );
        controller.initialize().then((_) => setState(() {}));
      // controller.video.play();
        // GallerySaver.saveVideo(path).then((bool? success) {
        //   print(success.toString());
        // });
        // final currentState = navigatorKey.currentState;
        // if (currentState != null) {
        //   currentState.push(
        //     MaterialPageRoute(
        //         builder: (context) => VideoScreen(path)),
        //   );
        // }

        setState(() {
          isLoading = false;
        });
      }).catchError((e) {
        print('Got error: $e');
      });
    } on PlatformException {
      print("error!!!!");
    }
                    

    

  }


  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scaleRect);

    vText();
                       
                        
    _checkIfCoverIsNull();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scaleRect);
    super.dispose();
    _disableEventReceiver();
  }

  void _scaleRect() {
    layout = computeLayout(widget.controller);
    rect.value = calculateCroppedRect(widget.controller, layout);
    transform.value = TransformData.fromRect(
      rect.value,
      layout,
      viewerSize,
      widget.controller,
    );

    _checkIfCoverIsNull();
  }

  void _checkIfCoverIsNull() {
    if (widget.controller.selectedCoverVal!.thumbData == null) {
      widget.controller.generateDefaultCoverThumbnail();
    }
  }

  @override
  void updateRectFromBuild() => _scaleRect();

  @override
  Widget buildView(BuildContext context, TransformData transform) {
    return ValueListenableBuilder(
      valueListenable: widget.controller.selectedCoverNotifier,
      builder: (_, CoverData? selectedCover, __) {
        if (selectedCover?.thumbData == null) {
          return Center(child: Text(widget.noCoverText));
        }

        // return buildImageView(
        //   controller,
        //   selectedCover!.thumbData!,
        //   transform,
        // );

       return  CropGridViewer.preview(controller: controller);
      },
    );
  }
}
