import 'dart:io';

class Utility{
  static String bytesToSize(int bytes) {
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    if (bytes <= 0) return '0 B';

    // Determine which size suffix to use
    int i = (bytes > 0) ? (bytes.bitLength - 1) ~/ 10 : 0;
    double size = bytes / (1 << (i * 10));

    // Format to 2 decimal places for readability
    return '${size.toStringAsFixed(2)} ${sizes[i]}';
  }

  static bool isPdf(String path) {
    return path.endsWith('pdf');
  }

  static String fileName({required File file}) {
    return file.path.split('/').last;
  }

  static fileExtension(File file) {
    return '.${file.path.split('.').last}';
  }
}