import 'dart:convert';
import 'save_migration.dart';
/// JSON codec only. Host app decides where bytes are stored (SharedPreferences/files/etc.).
class ExpansionSaveManager { String encode(Map<String,dynamic> state)=>jsonEncode({'schemaVersion':SaveMigration.currentVersion,'expansion':state}); Map<String,dynamic>? decode(String source){try{final raw=jsonDecode(source);if(raw is! Map)return null;final migrated=SaveMigration.migrate(Map<String,dynamic>.from(raw));final expansion=migrated['expansion'];return expansion is Map?Map<String,dynamic>.from(expansion):<String,dynamic>{};}catch(_){return null;}} }
