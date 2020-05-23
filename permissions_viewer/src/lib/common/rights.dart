import 'package:quiver/collection.dart';

class Rights {
  //# region consts
  static final listDirectory = Rights.fromValue(1);
  static final createFiles = Rights.fromValue(2);
  static final createDirectories = Rights.fromValue(4);
  static final readExtendedAttributes = Rights.fromValue(8);
  static final writeExtendedAttributes = Rights.fromValue(16);
  static final traverse = Rights.fromValue(32);
  static final deleteSubdirectoriesAndFiles = Rights.fromValue(64);
  static final readAttributes = Rights.fromValue(128);
  static final writeAttributes = Rights.fromValue(256);
  static final write = Rights.fromValue(278);
  static final delete = Rights.fromValue(65536);
  static final readPermissions = Rights.fromValue(131072);
  static final read = Rights.fromValue(131209);
  static final readAndExecute = Rights.fromValue(131241);
  static final modify = Rights.fromValue(197055);
  static final changePermissions = Rights.fromValue(262144);
  static final takeOwnership = Rights.fromValue(524288);
  static final synchronize = Rights.fromValue(1048576);
  static final fullControl = Rights.fromValue(2032127);
  //# endregion
  static final fileSystemRights = HashBiMap<int, String>()..addAll(
      {
        1: 'ListDirectory',
        2: 'CreateFiles',
        4: 'CreateDirectories',
        8: 'ReadExtendedAttributes',
        16: 'WriteExtendedAttributes',
        32: 'Traverse',
        64: 'DeleteSubdirectoriesAndFiles',
        128: 'ReadAttributes',
        256: 'WriteAttributes',
        278: 'Write',
        65536: 'Delete',
        131072: 'ReadPermissions',
        131209: 'Read',
        131241: 'ReadAndExecute',
        197055: 'Modify',
        262144: 'ChangePermissions',
        524288: 'TakeOwnership',
        1048576: 'Synchronize',
        2032127: 'FullControl'
      }
  );
  static Iterable<int> _decodeFlag(int value) sync* {
    for (var k in fileSystemRights.keys)
      if ((k & value) == k)
        yield k ;
  }

  bool contains(Rights other) =>
      (value & other.value) == other.value;

  final int value;
  final Set<int> flags;

  Rights._(this.value, this.flags);

  Rights.fromValue(int value): this._(value, _decodeFlag(value).toSet());

  Rights.fromName(String name) : this.fromValue(fileSystemRights.inverse[name]);

  @override
  int get hashCode => value;

  @override
  bool operator ==(dynamic other) => other is Rights && value == other.value;

  String get simpleName {
    if (contains(Rights.fullControl))
      return 'Full control';
    final simpleRights = <String>[];
    if (contains(Rights.read)) {
      simpleRights.add('Read');
    } else {
      if (contains(Rights.listDirectory)) simpleRights.add('List Files');
    }
    if (contains(Rights.createDirectories) && contains(Rights.createFiles)) {
      if (contains(Rights.write)) {
        simpleRights.add('Write');
      } else {
        simpleRights.add('Create');
      }
    }
    if (contains(Rights.write)) simpleRights.add('Write');
    if (contains(Rights.delete)) simpleRights.add('Delete');
    if (simpleRights.isEmpty)
      return flags.map((v) => fileSystemRights[v]).join(', ');
    if (simpleRights.length == 1) return simpleRights[0];
    return '${simpleRights.sublist(0, simpleRights.length - 1).join(', ')}'
        ' and ${simpleRights.last}';
  }
}