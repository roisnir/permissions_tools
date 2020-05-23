import 'package:example_flutter/common/rights.dart';

class RightsFilter {
  bool showListFiles;
  bool showRead;
  bool showCreate;
  bool showWrite;
  bool showFullControl;

  RightsFilter({this.showListFiles=false, this.showRead=false,
    this.showCreate=true, this.showWrite=true, this.showFullControl=true});

  bool shouldShow(Rights right){
    final create = Rights.fromValue(Rights.createFiles.value | Rights.createDirectories.value);
    return {
      create: showCreate,
      Rights.fullControl: showFullControl,
      Rights.listDirectory: showListFiles,
      Rights.read: showRead,
      Rights.write: showWrite}.entries.any((entry) {
        final conditionRight = entry.key;
        final conditionEnabled = entry.value;
        return conditionEnabled && right.contains(conditionRight);
      } );
  }
}