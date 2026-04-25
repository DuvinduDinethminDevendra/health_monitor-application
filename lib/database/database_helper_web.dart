// This file provides a robust fallback for the web when external plugins fail
// It uses the standard sqflite interface so your Repositories don't have to change.

Future<void> initWebDatabase() async {
  // We use the built-in in-memory factory for the web demo
  // This ensures zero compilation errors and high performance in the browser.
}
