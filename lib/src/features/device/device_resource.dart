// ignore_for_file: prefer_interpolation_to_compose_strings

import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:backend/src/core/services/database/remote_database.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_modular/shelf_modular.dart';

import '../auth/guard/auth_guard.dart';

class DeviceResource extends Resource {
  @override
  List<Route> get routes => [
        Route.get('/devices', _getAllDevices,
            middlewares: [AuthGuard()]), // AuthGuard()
        Route.post('/register-device', _registerDevice,
            middlewares: [AuthGuard()]),
      ];

  FutureOr<Response> _registerDevice(
      ModularArguments arguments, Injector injector) async {
    final deviceParams = (arguments.data as Map).cast<String, dynamic>();
    final deviceId = deviceParams['deviceId'];
    print('DeviceId: ' + deviceId);

    final database = injector.get<RemoteDatabase>();

    try {
      final consultaDevice = await database.query(
          'SELECT id, "deviceId", platform FROM "Device" WHERE "deviceId" = @deviceId;',
          variables: {'deviceId': deviceId});

      if (consultaDevice.isEmpty) {
        final result = await database.query(
          'INSERT INTO "Device" ( "deviceId", platform, "fcmToken", locale, "buildNumber", "userId") VALUES ( @deviceId, @platform, @fcmToken, @locale, @buildNumber, @userId ) RETURNING id, "deviceId", "userId";',
          variables: deviceParams,
        );
        final deviceMap = result.map((element) => element['Device']).first;
        return Response.ok(jsonEncode(deviceMap));
      } else {
        final columns = deviceParams.keys
            .where(
                (key) => key != "id" && key != "deviceId" && key != "createdAt")
            .map(
              (key) => '"$key"=@$key',
            )
            .toList();

        final query =
            'UPDATE "Device" SET ${columns.join(',')} WHERE "deviceId"=@deviceId RETURNING id, "deviceId", "userId";';

        final database = injector.get<RemoteDatabase>();
        final result = await database.query(
          query,
          variables: deviceParams,
        );
        final deviceMap = result.map((element) => element['Device']).first;
        return Response.ok(jsonEncode(deviceMap));
      }
    } catch (e) {
      print("Erro: $e");
      return Response.forbidden({'Erro': e.toString()});
    }
  }

  FutureOr<Response> _getAllDevices(Injector injector) async {
    final database = injector.get<RemoteDatabase>();
    final result = await database.query(
        'SELECT id, "updatedAt", "createdAt", "deviceId", platform, "fcmToken", locale, "buildNumber", "userId" FROM "Device";');

    // final listDevices = result.map((e) => e['Device']).toList();

    // Quando tem campo data tem que converter para String senão dá pau
    final listDevices = result.map((e) {
      String updateAt =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(e['Device']!['updatedAt']);
      String createdAt =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(e['Device']!['createdAt']);

      return {
        'id': e['Device']!['id'],
        'updatedAt': updateAt, // DateTime convertido para String
        'createdAt': createdAt, // DateTime convertido para String
        'deviceId': e['Device']!['deviceId'],
        'platform': e['Device']!['platform'],
        'fcmToken': e['Device']!['fcmToken'],
        'locale': e['Device']!['locale'],
        'buildNumber': e['Device']!['buildNumber'],
        'userId': e['Device']!['userId'],
      };
    }).toList();

    return Response.ok(jsonEncode(listDevices));
  }
}
