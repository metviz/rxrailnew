import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'app/notification_service.dart';
import 'app/routes/app_pages.dart';
import 'app/shared_preferences/preference_manager.dart';
import 'app/utils/app_strings.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  // HttpOverrides.global = MyHttpOverrides();
  await PreferencesManager.getInstance();
  await NotificationService().init();
  Object? initErr;
  try {
    await FMTCObjectBoxBackend().initialise();
    // We don't know what errors will be thrown, we want to handle them all
    // later
    // ignore: avoid_catches_without_on_clauses
  } catch (err) {
    initErr = err;
  }
  // Initialize notification service
  // try {
  //   await NotificationService().init();
  // } catch (e) {
  //   print("Error initializing notifications: $e");
  //   // Continue anyway, we'll request permissions later
  // }

  // Basic permissions only - we'll request more as needed
  // try {
  //   await Permission.location.request();
  //   await NotificationService().requestPermissions();
  // } catch (e) {
  //   print("Error requesting initial permissions: $e");
  //   // Continue anyway, we'll request again when needed
  // }
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: ThemeData(
          fontFamily: 'Poppins',
        ),
        initialRoute: AppStrings.splashRoute,
        getPages: AppPages.routes,
      ),
    );
  }
}
// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_flow/flutter_flow_util.dart';

Future<String> uploadFileAndGetUrl(FFUploadedFile uploadedFile) async {
  try {
    // Check file validity
    if (uploadedFile.bytes == null || uploadedFile.bytes!.isEmpty) {
      throw Exception('Uploaded file has no data.');
    }

    // Generate unique file path
    final fileName =
        uploadedFile.name ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
    final filePath = 'uploads/$fileName';

    // Reference to Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child(filePath);

    // Upload file
    final uploadTask = await storageRef.putData(
      uploadedFile.bytes!,
      SettableMetadata(contentType: uploadedFile.contentType),
    );

    // Get download url
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    return downloadUrl;
  } catch (e) {
    print('Firebase Upload Error: $e');
    return '';
  }
}