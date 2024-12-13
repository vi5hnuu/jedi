import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class StoragePermissions {
  static Future<bool> requestStoragePermissions() async {
    if(await isStoragePermissionGranted()) return true;

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo build=await deviceInfo.androidInfo;
    if(build.version.sdkInt>=33){
      var re=await Permission.manageExternalStorage.request();
      return re.isGranted;
    }else{
      var res=await Permission.storage.request();
      return res.isGranted;
    }
  }

  static Future<bool> isStoragePermissionGranted() async{
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo build=await deviceInfo.androidInfo;

    if(build.version.sdkInt>=33){
      return await Permission.manageExternalStorage.isGranted;
    }else{
      return await Permission.storage.isGranted;
    }
  }
}
