// This file provides a robust fallback for the web when external plugins fail
// It uses the standard sqflite interface so your Repositories don't have to change.

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';

Future<void> initWebDatabase() async {
  // Use the no web worker factory to avoid service worker communication errors 
  // during standard local browser development
  databaseFactory = databaseFactoryFfiWebNoWebWorker;
}
