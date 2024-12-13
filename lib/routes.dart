class AppRoute{
  final String name;
  final String path;//relative
  AppRoute({required this.name,required this.path});
}

class AppRoutes{
  static AppRoute splashRoute=AppRoute(name: 'splash', path: '/splash');

  static AppRoute errorRoute=AppRoute(name: 'error', path: '/error');

  static AppRoute searchRoute=AppRoute(name: 'search', path: '/search');

  static AppRoute fileManagement=AppRoute(name: 'file-management', path: '/file-management');

  static AppRoute mergePdfRoute=AppRoute(name: 'merge-pdf-tool', path: '/merge-pdf-tool');
  static AppRoute reorderPdfPagesRoute=AppRoute(name: 'reorder-pages-pdf-tool', path: '/reorder-pages-pdf-tool');
  static AppRoute pdfToJpgRoute=AppRoute(name: 'pdf-to-jpg-tool', path: '/pdf-to-jpg-tool');
  static AppRoute imageToPdfRoute=AppRoute(name: 'image-to-pdf-tool', path: '/image-to-pdf-tool');
  static AppRoute pageNumbersRoute=AppRoute(name: 'page-numbers-tool', path: '/page-numbers-tool');
  static AppRoute splitPdfRoute=AppRoute(name: 'split-pdf-tool', path: '/split-pdf-tool');
  static AppRoute unprotectPdfRoute=AppRoute(name: 'unprotect-pdf-tool', path: '/unprotect-pdf-tool');
  static AppRoute protectPdfRoute=AppRoute(name: 'protect-pdf-tool', path: '/protect-pdf-tool');
  static AppRoute rotatePdfRoute=AppRoute(name: 'rotate-pdf-tool', path: '/rotate-pdf-tool');
  static AppRoute pdfFilePreviewRoute=AppRoute(name: 'pdf-file-preview', path: '/pdf-file-preview/:pdfFilePath');


  static AppRoute homeRoute=AppRoute(name: 'home', path: '/');

  static AppRoute filesRoute=AppRoute(name: 'files', path: '/files');
  static AppRoute filesListingRoute=AppRoute(name: 'list', path: 'list');

  static AppRoute toolsRoute=AppRoute(name: 'tools', path: '/tools');

  static AppRoute scannerRoute=AppRoute(name: 'scanner', path: '/scanner');

  static AppRoute settingsRoute=AppRoute(name: 'setting', path: '/setting');


}