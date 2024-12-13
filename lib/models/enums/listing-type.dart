import 'package:jedi/utils/Constants.dart';

enum ListingType {
  INTERNAL_STORAGE("INTERNAL_STORAGE",Constants.rootStoragePath),
  DOWNLOADS("DOWNLOADS",Constants.downloadsStoragePath),
  DOCUMENTS("DOCUMENTS",Constants.documentsStoragePath);

  final String value;
  final String path;
  const ListingType(this.value,this.path);

  static ListingType fromJson(String value,{bool throwOnNull=false}){
    return ListingType.values.firstWhere((element) => element.value==value,orElse: () => throw Exception(""),);
  }
}
