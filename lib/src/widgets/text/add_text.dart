import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tapioca_v2/tapioca_v2.dart';
import 'package:video_editor/src/controller.dart';
import 'package:video_editor/src/utils/helpers.dart';
import 'package:video_editor/src/models/transform_data.dart';
import 'package:video_editor/src/widgets/crop/crop_mixin.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_kit/video_kit.dart';







class AddTextViewer extends StatefulWidget {
  /// It is the viewer that show the selected cover
   AddTextViewer({
    super.key,
    required this.controller,
    this.noCoverText = 'No selection',
    this.text = '',
    this.x = 100,
    this.y = 100,
    this.size = 100,
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate the crop parameters in the cover view
  final VideoEditorController controller;
  String? text;
  int? x;
  int?  y;
  int? size;

  /// The [noCoverText] param specifies the text to display when selectedCover is `null`
  final String noCoverText;

  @override
  State<AddTextViewer> createState() => _AddTextViewerState();
}

class _AddTextViewerState extends State<AddTextViewer> with CropPreviewMixin {

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
        // TapiocaBall.filter(Filters.pink, 0.2),
        TapiocaBall.textOverlay(
            widget.text!, widget.x!, widget.y!, widget.size!, const Color(0xffffc0cb)),
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
    vText();
    super.initState();
    widget.controller.addListener(_scaleRect);              
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
    // return ValueListenableBuilder(
    //   valueListenable: widget.controller.selectedCoverNotifier,
    //   builder: (_, CoverData? selectedCover, __) {
    //     if (selectedCover?.thumbData == null) {
    //       return Center(child: Text(widget.noCoverText));
    //     }

        // return buildImageView(
        //   controller,
        //   selectedCover!.thumbData!,
        //   transform,
        // );

       return  controller.initialized ?  CropGridViewer.preview(controller: controller) : const Center(child: CircularProgressIndicator());
      // },
    //);
  }
}




class SplitVideoSelection extends StatefulWidget {
  /// Slider that allow to select a generated cover
  const SplitVideoSelection({
    super.key,
    required this.controller,
    this.size = 60,
    this.quantity = 5,
    this.wrap,
    this.selectedCoverBuilder,
  });

  /// The [controller] param is mandatory so every change in the controller settings will propagate in the cover selection view
  final VideoEditorController controller;

  /// The [size] param specifies the size to display the generated thumbnails
  ///
  /// Defaults to `60`
  final double size;

  /// The [quantity] param specifies the quantity of thumbnails to generate
  ///
  /// Default to `5`
  final int quantity;

  /// Specifies a [wrap] param to change how should be displayed the covers thumbnails
  /// the `children` param will be ommited
  final Wrap? wrap;

  /// Returns how the selected cover should be displayed
  final Widget Function(Widget selectedCover, Size)? selectedCoverBuilder;

  @override
  State<SplitVideoSelection> createState() => _SplitVideoSelectionState();
}

class _SplitVideoSelectionState extends State<SplitVideoSelection>
     {




  @override
   initState() async*{
   await _splitVideo();
    
    super.initState();
  }

  @override
  void dispose() {
  
    super.dispose();
  }

  // late Stream<List<VideoEditorController>> _thumbnailsVideoEditorController;
  late List<VideoEditorController> _thumbnailsVideoEditorController;
  late List<Widget> trimSlider = [];
    final double height = 60;

  Future<void> _splitVideo() async {
    
      try {
        var outputPaths = await VideoKit.splitVideo(widget.controller.file.path, 3); // Split into 3 segments
        outputPaths.forEach((outputPath) {
          print('Segment saved at: $outputPath');
          // _thumbnailsVideoEditorController.add(VideoEditorController.file(File(outputPath)));
          trimSlider.add(
            Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(vertical: height / 4),
              child: TrimSlider(
                controller: VideoEditorController.file(File(outputPath)),
                height: height,
                horizontalMargin: height / 4,
                child: TrimTimeline(
                  controller: VideoEditorController.file(File(outputPath)),
                  padding: const EdgeInsets.only(top: 10),
                ),
              ),
            )
          );
           setState(() { });
        });
        setState(() { });
      } catch (e) {
        print('Error splitting video: $e');
      }
   
  }
 



 
  

  @override
  Widget build(BuildContext context) {
    if (trimSlider.isEmpty) {
      return Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.symmetric(vertical: height / 4),
              child: TrimSlider(
                controller: widget.controller,
                height: height,
                horizontalMargin: height / 4,
                child: TrimTimeline(
                  controller: widget.controller,
                  padding: const EdgeInsets.only(top: 10),
                ),
              ));
    }else{
      return Column(
        children: trimSlider,
      );
    }
    
  }


}


