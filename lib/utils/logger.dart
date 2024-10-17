import 'package:logger/logger.dart' as logger_package;

// Define the possible log levels
enum LogLevel {
  fatal,
  error,
  warn,
  info,
  debug,
  trace,
  silent,
}

class ReclaimLogger {
  static final ReclaimLogger _instance = ReclaimLogger._internal();
  late final logger_package.Logger _logger;

  factory ReclaimLogger() {
    return _instance;
  }

  ReclaimLogger._internal() {
    _logger = logger_package.Logger(
      printer: logger_package.PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 5,
        lineLength: 50,
        colors: true,
        printEmojis: true,
        printTime: false,
      ),
    );
  }

  static void setLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.fatal:
      case LogLevel.error:
        logger_package.Logger.level = logger_package.Level.error;
        break;
      case LogLevel.warn:
        logger_package.Logger.level = logger_package.Level.warning;
        break;
      case LogLevel.info:
        logger_package.Logger.level = logger_package.Level.info;
        break;
      case LogLevel.debug:
        logger_package.Logger.level = logger_package.Level.debug;
        break;
      case LogLevel.trace:
        logger_package.Logger.level = logger_package.Level.trace;
        break;
      case LogLevel.silent:
        logger_package.Logger.level = logger_package.Level.off;
        break;
    }
  }

  void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void warn(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }
}

// Create a global instance of the logger
final logger = ReclaimLogger();
