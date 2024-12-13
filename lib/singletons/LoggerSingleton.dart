import 'package:logger/logger.dart';

class LoggerSingleton {
  final logger = Logger();
  static final _instance = LoggerSingleton._();

  LoggerSingleton._() {}

  factory LoggerSingleton() {
    return _instance;
  }
}
