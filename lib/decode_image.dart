//import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
//import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart';
import 'package:r_scan/r_scan.dart';

var data;
var imageDecoded;
var dataOriginal;

List puzzleList = [];
Future<String> processImage(Uint8List imageList) async {
  try {
    imageDecoded = decodeImage(imageList);
    data = imageDecoded.getBytes();
    dataOriginal = data;
    for (var x = 0; x < data.length; x += 4) {
      // GBAR
      // calcular a média das cores do GBAR, para saber a sua intensidade
      int avg = ((data[x + 1] + data[x] + data[x + 2]) / 3).floor();
      // diferenca na escala de cinzentos
      int expression = (data[x + 2] - data[x]).abs() +
          (data[x + 1] - data[x]).abs() +
          (data[x + 2] - data[x + 1]).abs();
      if (avg > 52 && expression < 20) {
        data[x + 3] = avg; // modular a média para o canal alfa
      } else {
        data[x + 3] = 0; // modular a média para o canal alfa
      }
    }

    return data;
  } catch (e) {
    print(e);
  }
}

// Desconsiderar redundancias dos códigos Qr encontrados
bool addQr(int firstPos, int decodedQrWidth, List squares) {
  try {
    num actualX = (firstPos) % (4 * imageDecoded.width); //After 2025 : Changed actualX from int to num
    int actualY = ((firstPos) / (4 * imageDecoded.width)).truncate();
    for (var pos = 0; pos < (squares.length); pos += 2) {
      int puzzleX = squares[pos] % (4 * imageDecoded.width);
      int puzzleY = (squares[pos] / (4 * imageDecoded.width)).truncate();
      if (actualX < puzzleX + squares[pos + 1] &&
          actualX > puzzleX - decodedQrWidth &&
          actualY < puzzleY + squares[pos + 1] &&
          actualY > puzzleY - decodedQrWidth) {
        return (false);
      }
    }
    return (true);
  } catch (e) {
    print(e);
  }
}

// fazer o corte da zona do código QR para depois descodificar
List<int> cutQr(int firstPoint, int decodedQrWidth, int skip) {
  List<int> decodedQr = [];
  int? lastPoint = firstPoint + (decodedQrWidth - 1) * 4;
  for (int h = -skip; h < decodedQrWidth + skip; h += 1) {
    for (int k = (firstPoint - 4 * skip); k <= (lastPoint + 4 * skip); k += 4) {
      if (k > -1 && k < data.length && data[k + 3] > 52) {
        decodedQr.add(255);
        decodedQr.add(255);
        decodedQr.add(255);
        decodedQr.add(255);
      } else {
        decodedQr.add(0);
        decodedQr.add(0);
        decodedQr.add(0);
        decodedQr.add(255);
      }
    }
    
    /*-------Before 2025 ------------
    lastPoint = (lastPoint + 4 * imageDecoded.width);
    firstPoint = (firstPoint + 4 * imageDecoded.width);*/

    //-------After 2025------- TODO
    lastPoint = (lastPoint + 4 * imageDecoded.width);
    firstPoint = (firstPoint + 4 * imageDecoded.width);
  }
  return decodedQr;
}

// transformar a parte cortada em File
Future<File> getFile(int decodedQrWidth, var data) async {
  Directory appDocumentsDirectory = await getApplicationDocumentsDirectory();
  String appDocumentsPath = appDocumentsDirectory.path;
  final File file = await File(appDocumentsPath + '/decodedeQrFile.png')
      .writeAsBytes(
          encodePng(Image.fromBytes(decodedQrWidth, decodedQrWidth, data)));
  return file;
}

//descodificar o código Qr que está em forma de File
Future<String> decodeQrFileToString(int decodedQrWidth, var decodedQr) async {
  final File decodedQrFile = await getFile(decodedQrWidth, decodedQr);

  var result;
  try {
    // var x = await _qrCodeFile.readAsBytes();
    result = await RScan.scanImagePath(decodedQrFile.path);
    print(result);
  } catch (e) {
    print(e);
  }

  return result.message;
}

// Funcao para cortar os vários códigos QR, e enviar informacao
Future<List> getPuzzleList() async {
  try {
    int skip = 20;
    List puzzleList = [];
    int decodedQrWidth = 0;
    int firstPos;
    bool checkLine = false;
    List squares = [];
    //var origData = imageDecoded.getBytes();

    // Ciclo para reconhecer zonas onde se encontra código QR
    try {
      for (var x = 0; x < data.length; x += 4) {
        decodedQrWidth = 0;
        if (data[x + 3] > 52) {
          firstPos = x;
          checkLine = true;
          decodedQrWidth = 1;
          while (checkLine) {
            x += 4;
            decodedQrWidth += 1;
            if (data[x + 3] < 52) {
              checkLine = false;
            }
          }
          // aqui copia-se para outra imagem a parte respectiva do código QR
          if (decodedQrWidth > 100 &&
              addQr(firstPos, decodedQrWidth, squares)) {
            var decodedQr = cutQr(firstPos, decodedQrWidth, skip);
            String result = await decodeQrFileToString(
                decodedQrWidth + 2 * skip, decodedQr);
            if (result != null) {
              puzzleList.add(result);
              puzzleList.add(firstPos % imageDecoded.width);
              puzzleList.add((firstPos / imageDecoded.width).truncate());
              squares.add(firstPos - skip);
              squares.add(decodedQrWidth + 2 * skip);
            }
          }
        }
      }
    } catch (e) {
      print(e);
    }
    var puzzleList2 = puzzleList;
    return puzzleList2;

    //return puzzleList;
  } catch (e) {
    print(e);
  }
}

Future<String> messageQr(Uint8List image) async {
  imageDecoded = decodeImage(image);
  var data = imageDecoded.getBytes();

  File file = await getFile(imageDecoded.width, data);
  var result = await RScan.scanImagePath(file.path);
  return result.message;
}
