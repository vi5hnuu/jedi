class Constants {
  static const String baseUrl = "https://pdf-studio-pdf-craft-api.onrender.com/api/v1";
  static const String processedDirPath = "storage/emulated/0/ilvPdf";
  static const String binDirPath = "storage/emulated/0/ilvPdfBin";
  static const String rootStoragePath = "storage/emulated/0";
  static const String downloadsStoragePath =
      '${Constants.rootStoragePath}/Download';
  static const String documentsStoragePath =
      '${Constants.rootStoragePath}/Documents';

  static const List<String> excludedPaths = [
    // System directories (restricted by OS)
    '/system',
    '/vendor',
    '/proc',
    '/sys',
    '/dev',
    '/data',
    '/cache',
    '/storage/self',
    '/storage/secure',

    // Common Android directories that are unnecessary for search
    '/storage/emulated/0/Android', // App-specific files
    '/storage/emulated/0/DCIM/.thumbnails', // Thumbnail cache
    '/storage/emulated/0/Android/data', // App private data
    '/storage/emulated/0/Android/obb', // Game data
    '/storage/emulated/0/WhatsApp', // WhatsApp data (optional)
    '/storage/emulated/0/Tencent', // Tencent app data (optional)
    '/storage/emulated/0/.Trash', // Trash or recycle bin
  ];

  static const fileIcons={
    'apk':'assets/file-types/apk.webp',
    'dat':'assets/file-types/dat.webp',
    'dll':'assets/file-types/dll.webp',
    'flv':'assets/file-types/flv.webp',
    'iso':'assets/file-types/iso.webp',
    'java':'assets/file-types/java.webp',
    'log':'assets/file-types/log.webp',
    'mov':'assets/file-types/mov.webp',
    'mp4':'assets/file-types/mov.webp',
    'mp3':'assets/file-types/mp3.webp',
    'mpeg':'assets/file-types/mpeg.webp',
    'png':'assets/file-types/png.webp',
    'ppt':'assets/file-types/ppt.webp',
    'pptx':'assets/file-types/ppt.webp',
    'rar':'assets/file-types/rar.webp',
    'sql':'assets/file-types/sql.webp',
    'sqlite':'assets/file-types/sql.webp',
    'tex':'assets/file-types/tex.webp',
    'tiff':'assets/file-types/tiff.webp',
    'wav':'assets/file-types/wav.webp',
    'wma':'assets/file-types/wma.webp',
    'xml':'assets/file-types/xml.webp',
    'zip':'assets/file-types/zip.webp',
    'folder':'assets/file-types/folder.webp',
    'jpg':'assets/file-types/img.webp',
    'jpeg':'assets/file-types/jpeg.webp',
    'bmp':'assets/file-types/img.webp',
    'pdf':'assets/file-types/pdf.webp',
    'exe':'assets/file-types/exe.webp',
    'js':'assets/file-types/js.webp',
    'pub':'assets/file-types/pub.webp',
    'csv':'assets/file-types/csv.webp',
    'xls':'assets/file-types/csv.webp',
    'xlsx':'assets/file-types/csv.webp',
    'doc':'assets/file-types/doc.webp',
    'docx':'assets/file-types/docx.webp',
    'html':'assets/file-types/html.webp',
    'json':'assets/file-types/json.webp',
    'torrent':'assets/file-types/torrent.webp',
  };

  static const Map<String,String> extrnalOpenSupportedFiles={
    ".3gp": "video/3gpp",
    ".torrent":"application/x-bittorrent",
    ".kml":    "application/vnd.google-earth.kml+xml",
    ".gpx":    "application/gpx+xml",
    ".csv":    "application/vnd.ms-excel",
    ".apk":    "application/vnd.android.package-archive",
    ".asf":    "video/x-ms-asf",
    ".avi":    "video/x-msvideo",
    ".bin":    "application/octet-stream",
    ".bmp":    "image/bmp",
    ".c":      "text/plain",
    ".class":  "application/octet-stream",
    ".conf":   "text/plain",
    ".cpp":    "text/plain",
    ".doc":    "application/msword",
    ".docx":   "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    ".xls":    "application/vnd.ms-excel",
    ".xlsx":   "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".exe":    "application/octet-stream",
    ".gif":    "image/gif",
    ".gtar":   "application/x-gtar",
    ".gz":     "application/x-gzip",
    ".h":      "text/plain",
    ".htm":    "text/html",
    ".html":   "text/html",
    ".jar":    "application/java-archive",
    ".java":   "text/plain",
    ".jpeg":   "image/jpeg",
    ".jpg":    "image/jpeg",
    ".js":     "application/x-javascript",
    ".log":    "text/plain",
    ".m3u":    "audio/x-mpegurl",
    ".m4a":    "audio/mp4a-latm",
    ".m4b":    "audio/mp4a-latm",
    ".m4p":    "audio/mp4a-latm",
    ".m4u":    "video/vnd.mpegurl",
    ".m4v":    "video/x-m4v",
    ".mov":    "video/quicktime",
    ".mp2":    "audio/x-mpeg",
    ".mp3":    "audio/x-mpeg",
    ".mp4":    "video/mp4",
    ".mpc":    "application/vnd.mpohun.certificate",
    ".mpe":    "video/mpeg",
    ".mpeg":   "video/mpeg",
    ".mpg":    "video/mpeg",
    ".mpg4":   "video/mp4",
    ".mpga":   "audio/mpeg",
    ".msg":    "application/vnd.ms-outlook",
    ".ogg":    "audio/ogg",
    ".pdf":    "application/pdf",
    ".png":    "image/png",
    ".pps":    "application/vnd.ms-powerpoint",
    ".ppt":    "application/vnd.ms-powerpoint",
    ".pptx":   "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    ".prop":   "text/plain",
    ".rc":     "text/plain",
    ".rmvb":   "audio/x-pn-realaudio",
    ".rtf":    "application/rtf",
    ".sh":     "text/plain",
    ".tar":    "application/x-tar",
    ".tgz":    "application/x-compressed",
    ".txt":    "text/plain",
    ".wav":    "audio/x-wav",
    ".wma":    "audio/x-ms-wma",
    ".wmv":    "audio/x-ms-wmv",
    ".wps":    "application/vnd.ms-works",
    ".xml":    "text/plain",
    ".z":      "application/x-compress",
    ".zip":    "application/x-zip-compressed",
  };

  static bool isHiddenFileOrDir(String path) {
    return path.split('/').any((segment) => segment.startsWith('.'));
  }
}
