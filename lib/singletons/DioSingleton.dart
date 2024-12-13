import 'package:jedi/singletons/LoggerSingleton.dart';
import 'package:dio/dio.dart';

class DioSingleton {
  final Dio dio = Dio();
  static final DioSingleton _instance = DioSingleton._();

  DioSingleton._() {
    dio.interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) async {
          LoggerSingleton().logger.i('REQUEST [${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
            onResponse: (response, handler) async {
              LoggerSingleton().logger.i('RESPONSE [${response.statusCode}] => PATH: ${response.requestOptions.path}');
              return handler.next(response);
            },
            onError: (DioException e, handler) {
              print(e.error);
              LoggerSingleton().logger.i('ERROR [${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
              return handler.next(e);
            }));
  }

  factory DioSingleton() {
    return _instance;
  }
}
