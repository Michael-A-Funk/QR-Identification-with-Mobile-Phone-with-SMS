import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'MainPage.dart';
import 'decode_image.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      // color: Colors.red,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File _image;

  final imagePicker = ImagePicker();
  List _qrCodeList = [];
  File _qrCodeFile;
  var message;

  // Criar imagem temporário para depois reconhecer código QR
  String _qrcodeFile = '';
  String _data = '';
  @override
  void initState() {
    super.initState();
  }

  Future getImage() async {
    final image = await imagePicker.getImage(source: ImageSource.gallery);
    await processImage(await image.readAsBytes());
    List _qrCodeListCopy = await getPuzzleList();

    //message = await messageQr(await image.readAsBytes());
    //_getPhotoByGallery();
    //print(_qrCodeList);
    //_qrCodeList = await decodedQrCodeList(_qrCodeFile);
    setState(() {
      _qrCodeList = _qrCodeListCopy;
    });
  }

  void goToBroadcastMain() async {
    data = json.encode(_qrCodeList);
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MainPage(
                  data: data,
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Leitor do Robot-Puzzle"),
          backgroundColor: Colors.blue,
          centerTitle: true,
        ),
        body: Center(
          child: _qrCodeList.isEmpty
              ? Text("Tire foto do puzzle")
              : Column(
                  //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                      /*Image.file(
                        _image,
                        width: 250.0,
                        height: 250.0,
                      ),*/
                      if (_qrCodeList != null)
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text('List: ${_qrCodeList.toString()}'),
                              //Text(message.toString()),
                              TextButton(
                                  onPressed: goToBroadcastMain,
                                  child: Icon(Icons.send))
                            ])
                      //Text('List: $_data')
                      else
                        Text('Tire Foto do Puzzle finalizado'),
                    ]),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blue,
          onPressed: getImage,
          child: Icon(Icons.camera_alt),
        ));
  }
}
