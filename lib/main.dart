import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DrawingBoard(),
    );
  }
}

class DrawingBoard extends StatefulWidget {
  @override
  _DrawingBoardState createState() => _DrawingBoardState();
}

class _DrawingBoardState extends State<DrawingBoard> {
  //defining the globalkey
  GlobalKey globalKey = GlobalKey();
  //for the pen color
  Color selectedColor = Colors.red;
  //for changing the background
  Color defaultColor = Colors.white;
  //for changing the strokewidth
  double strokeWidth = 5;
  //for the drawing points
  List<DrawingPoint> drawingPoints = [];

  //making the save functionality in flutter
  Future<void> save() async {
    RenderRepaintBoundary boundary =
        globalKey.currentContext.findRenderObject();
    ui.Image image = await boundary.toImage();
    ByteData byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData.buffer.asUint8List();
    //request the permission to write in the phone's gallery:
    if (!(await Permission.storage.status.isGranted))
      await Permission.storage.request();
    final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 60,
        name: randomAlpha(8));
    print(result);
  }

  //function for changing the state
  void changeColor(Color color) => setState(() => defaultColor = color);
  //function for changing the state
  void changeselectedColor(Color color) =>
      setState(() => selectedColor = color);
//for the stroke input
  final strokeController = TextEditingController();
  void getresult() {
    double strokecasting = double.parse(strokeController.text);
    setState(() {
      strokeWidth = strokecasting;
    });
    Navigator.pop(context);
  }

  File _image;
  final picker = ImagePicker();
//function to get the image from the gallery
  Future getImageFromGallery() async {
    final pickedImage = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      } else {
        print("No image is selected yet");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepaintBoundary(
        key: globalKey,
        child: Container(
          color: defaultColor,
          child: Stack(
            children: [
              Center(
                child: Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: _image == null ? null : Image.file(_image),
                  ),
                ),
              ),
              GestureDetector(
                onPanStart: (details) {
                  setState(() {
                    drawingPoints.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = selectedColor
                          ..isAntiAlias = true
                          ..strokeWidth = strokeWidth
                          ..strokeCap = StrokeCap.round,
                      ),
                    );
                  });
                },
                onPanUpdate: (details) {
                  setState(() {
                    drawingPoints.add(
                      DrawingPoint(
                        details.localPosition,
                        Paint()
                          ..color = selectedColor
                          ..isAntiAlias = true
                          ..strokeWidth = strokeWidth
                          ..strokeCap = StrokeCap.round,
                      ),
                    );
                  });
                },
                onPanEnd: (details) {
                  setState(() {
                    drawingPoints.add(null);
                  });
                },
                child: CustomPaint(
                  painter: _DrawingPainter(drawingPoints),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          InkWell(
            onTap: () => setState(() => drawingPoints = []),
            child: Container(
              width: MediaQuery.of(context).size.width / 7,
              color: Colors.green,
              height: 50,
              child: Column(
                children: [
                  Padding(padding: EdgeInsets.only(top: 5.0)),
                  Icon(Icons.clear),
                  Text("Clear"),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              setState(() {
                save();
              });
              //if the permission is granted  then while saving show the message of save
              if ((await Permission.storage.status.isGranted)) {
                Alert(
                  context: context,
                  type: AlertType.success,
                  title: "Saved",
                  desc: "Location: file:///storage/emulated/0/Pictures",
                  buttons: [
                    DialogButton(
                      child: Text(
                        "OK",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () => Navigator.pop(context),
                      width: 120,
                    )
                  ],
                ).show();
              }
            },
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width / 7,
              color: Colors.green,
              child: Column(children: [
                Padding(padding: EdgeInsets.only(top: 5.0)),
                Icon(Icons.save),
                Text("Save"),
              ]),
            ),
          ),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey[200],
                    titlePadding: const EdgeInsets.all(0.0),
                    contentPadding: const EdgeInsets.all(0.0),
                    content: SingleChildScrollView(
                        child: Column(
                      children: [
                        Text("Enter the stroke value"),
                        TextField(
                          controller: strokeController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Enter thickness for pen",
                          ),
                        ),
                        MaterialButton(
                            onPressed: () {
                              getresult();
                            },
                            child: Text("Ok")),
                      ],
                    )),
                  );
                },
              );
            },
            child: Container(
              height: 50,
              width: MediaQuery.of(context).size.width / 7,
              color: Colors.green,
              child: Column(children: [
                Padding(padding: EdgeInsets.only(top: 5.0)),
                Icon(Icons.colorize),
                Text("Stroke"),
              ]),
            ),
          ),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    titlePadding: const EdgeInsets.all(0.0),
                    contentPadding: const EdgeInsets.all(0.0),
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          ColorPicker(
                            pickerColor: selectedColor,
                            onColorChanged: changeselectedColor,
                            colorPickerWidth: 300.0,
                            pickerAreaHeightPercent: 0.7,
                            enableAlpha: true,
                            displayThumbColor: true,
                            showLabel: true,
                            paletteType: PaletteType.hsv,
                            pickerAreaBorderRadius: const BorderRadius.only(
                              topLeft: const Radius.circular(2.0),
                              topRight: const Radius.circular(2.0),
                            ),
                          ),
                          MaterialButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Ok"))
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
              height: 50,
              color: Colors.green,
              width: MediaQuery.of(context).size.width / 7,
              child: Column(children: [
                Padding(padding: EdgeInsets.only(top: 5.0)),
                Icon(Icons.colorize),
                Text(
                  "Pen",
                ),
              ]),
            ),
          ),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    titlePadding: const EdgeInsets.all(0.0),
                    contentPadding: const EdgeInsets.all(0.0),
                    content: SingleChildScrollView(
                      child: Column(
                        children: [
                          ColorPicker(
                            pickerColor: defaultColor,
                            onColorChanged: changeColor,
                            colorPickerWidth: 300.0,
                            pickerAreaHeightPercent: 0.7,
                            enableAlpha: true,
                            displayThumbColor: true,
                            showLabel: true,
                            paletteType: PaletteType.hsv,
                            pickerAreaBorderRadius: const BorderRadius.only(
                              topLeft: const Radius.circular(2.0),
                              topRight: const Radius.circular(2.0),
                            ),
                          ),
                          MaterialButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Ok"))
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            child: Container(
              height: 50,
              color: Colors.green,
              width: MediaQuery.of(context).size.width / 7,
              child: Column(children: [
                Padding(padding: EdgeInsets.only(top: 5.0)),
                Icon(Icons.colorize),
                Text("Color"),
              ]),
            ),
          ),
          InkWell(
            onTap: () => getImageFromGallery(),
            child: Container(
              color: Colors.green,
              width: MediaQuery.of(context).size.width / 7,
              height: 50,
              child: Column(children: [
                Padding(padding: EdgeInsets.only(top: 5.0)),
                Icon(Icons.upload_file),
                Text("Photo"),
              ]),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _image = null;
              });
            },
            child: Container(
              color: Colors.green,
              width: MediaQuery.of(context).size.width / 7,
              height: 50,
              child: Column(children: [
                Padding(padding: EdgeInsets.only(top: 5.0)),
                Icon(Icons.photo),
                Text("Clear Pic"),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}


class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  _DrawingPainter(this.drawingPoints);

  List<Offset> offsetsList = [];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < drawingPoints.length; i++) {
      if (drawingPoints[i] != null && drawingPoints[i + 1] != null) {
        canvas.drawLine(drawingPoints[i].offset, drawingPoints[i + 1].offset,
            drawingPoints[i].paint);
      } else if (drawingPoints[i] != null && drawingPoints[i + 1] == null) {
        offsetsList.clear();
        offsetsList.add(drawingPoints[i].offset);

        canvas.drawPoints(
            ui.PointMode.points, offsetsList, drawingPoints[i].paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class DrawingPoint {
  Offset offset;
  Paint paint;

  DrawingPoint(this.offset, this.paint);
}
