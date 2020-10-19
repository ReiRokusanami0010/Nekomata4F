import 'dart:async';
import 'dart:convert';

import 'package:Nekomata/DataBase/ConstantURL.dart';
import 'package:Nekomata/DataBase/Controller/LiveDataController.dart';
import 'package:Nekomata/DataBase/Provider/APIProvider.dart';
import 'package:Nekomata/DataBase/Structure.dart';
import 'package:Nekomata/Logger/NekomataLogger.dart';

enum DataBase {
  HOLOLIVE,
  NIJISANJI,
  ANIMARE
}

class DataStreamProvider {
  void aggregateRaw(DataBase database) {
    switch(database) {
      case DataBase.HOLOLIVE:
        _liveSearch(RequestURL.COLLECTION_HOLOLIVE, RequestURL.DATABASE_HOLOLIVE);
        break;
      case DataBase.NIJISANJI:
        _liveSearch(RequestURL.COLLECTION_NIJISANJI, RequestURL.DATABASE_NIJISANJI);
        break;
      case DataBase.ANIMARE:
        _liveSearch(RequestURL.COLLECTION_ANIMARE, RequestURL.DATABASE_ANIMARE);
        break;
    }
  }

  StreamTransformer<List<String>, List<DataBaseStructure>> streamTransformer() {
    List<DataBaseStructure> structureArray = new List<DataBaseStructure>();
    return StreamTransformer<List<String>, List<DataBaseStructure>>.fromHandlers(
      handleData: (value, sink) {
        for (String disParse in value) {
          List<DataBaseStructure> parsed = _TryParser.databaseStructureList(disParse);
          for(DataBaseStructure structure in parsed) {
            structureArray.add(structure);
          }
        }
        sink.add(structureArray);
      }
    );
  }

  void initAggregate() {
    _liveSearch(RequestURL.COLLECTION_NIJISANJI, RequestURL.DATABASE_NIJISANJI);
  }

  void _liveSearch(String collectUrl, String searchUrl) async {
    List<String> rawDataArray = new List<String>();
    List<String> requestArray = _TryParser.stringList(await APIProvider.requestSearch(RequestType.ONLY_LIVER, collectUrl));
    for (String targetChannel in requestArray) {
      rawDataArray.add(await APIProvider.requestSearch(RequestType.DETAILS, searchUrl, targetChannel));
    }
    LiveDataController().rawCapturam.add(rawDataArray);
  }

}

class _TryParser {
  static List<DataBaseStructure> databaseStructureList(String targetString) {
    List<DataBaseStructure> castedResult = new List<DataBaseStructure>();
    List<dynamic>          decodeObjects = new List<dynamic>();
    try {
      decodeObjects = jsonDecode(targetString);
    } catch (excp) {
      NekomataLogger().printErr("Refactor Result", "情報の正規化に失敗しました。");
    }

    for (Map<dynamic, dynamic> item in decodeObjects) {
      DataBaseStructure structure = DataBaseStructure.fromJson(item);
      castedResult.add(structure);
    }

    return castedResult;
  }

  static List<String> stringList(String targetString) {
    List<String>  castedResult  = new List<String>();
    List<dynamic> decodeObjects = new List<dynamic>();
    try {
      decodeObjects = jsonDecode(targetString);
    } catch (excp) {
      NekomataLogger().printErr("Refactor Result", "情報の正規化に失敗しました。");
    }

    //NekomataLogger().printInfo("Refactor Result", "情報の正規化が終了しました。");
    for (dynamic item in decodeObjects) {
      castedResult.add(item);
    }
    return castedResult;
  }
}