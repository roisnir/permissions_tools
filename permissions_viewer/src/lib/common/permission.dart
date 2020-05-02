import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:example_flutter/common/rights.dart';
import 'package:flutter/foundation.dart';

class Permission {
  final String path;
  final String username;
  final String displayName;
  final Rights rights;
  final String type;
  final bool isInherited;

  Permission(this.path, this.username, this.displayName,
      this.rights, this.type, this.isInherited);

  Permission.fromJson(Map<String, dynamic> json) : this(
    json['dirPath'],
    '',
    json['displayName'],
    json['rights'] is num ? Rights.fromValue(json['rights']) : parseRights(json['rights']),
    json['type'],
    json['isInherited']
  );
}

Rights parseRights(String rights){
  try {
    if (rights == null || rights.isEmpty) return null;
    final rightsStrings = rights.split(', ');
    int rightsValue = rightsStrings.fold<int>(0, (int value, String element) =>
    value | Rights
        .fromName(element)
        .value);
    return Rights.fromValue(rightsValue);
  }
  catch (ex) {
    print(ex);
  }
}

class Directory {
  String path;
  List<Directory> children;
  List<Permission> permissions;

  Directory(this.path, this.permissions, this.children){
    this.permissions ??= [];
  }

  Directory.fromJson(Map<String, dynamic> json){
    path = json['path'];
    permissions = json['permissions'].map<Permission>((pJson) => Permission.fromJson(pJson)).toList();
    children = json['children'].map<Directory>((cJson) => Directory.fromJson(cJson)).toList();
  }
}

//Future<Map<Directory, List<Directory>>> readPermissionsCsv(File csvFile) async {
//  final dir = <Directory, List<Directory>>{Directory('/', []): []};
//  final linesStream = StreamIterator(csvFile.openRead()
//      .transform(utf8.decoder)
//      .transform(CsvToListConverter()));
//  while (await linesStream.moveNext()){
//    final line = linesStream.current;
//    final perm = Permission("${line[0]}\\${line[1]}", line[2], line[3], line[4]);
//    final path = perm.path.split('\\');
//
//  }
//  return dir;
//}
Future<Directory> readPermissionsJson(File jsonFile) async {
  final data = await jsonFile.readAsString();
//  return compute(parseString, data);
  return parseString(data);
}

Directory parseString(String data){
  return Directory.fromJson(jsonDecode(data));
}



//void updateDirTree(Map<Directory, List<Directory>> map, Permission perm){
//  final path = perm.path.split('\\');
//  if (path.length == 0)
//    return;
//  if ()
//}

