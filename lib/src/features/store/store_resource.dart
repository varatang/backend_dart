import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:backend/src/core/services/database/remote_database.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_modular/shelf_modular.dart';

import '../auth/guard/auth_guard.dart';

class StoreResource extends Resource {
  @override
  List<Route> get routes => [
        Route.get('/store', _getAllStore,
            middlewares: [AuthGuard()]), // AuthGuard()
        Route.get('/store/:id', _getStoreByid,
            middlewares: [AuthGuard()]), // AuthGuard()
        Route.post('/store', _createStore),
        Route.put('/store', _updateStore,
            middlewares: [AuthGuard()]), // AuthGuard()
        Route.delete('/store/:id', _deleteStore,
            middlewares: [AuthGuard()]), // AuthGuard()
      ];

  FutureOr<Response> _createStore(
      ModularArguments arguments, Injector injector) async {
    final storeParams = (arguments.data as Map).cast<String, dynamic>();
    final database = injector.get<RemoteDatabase>();
    final result = await database.query(
      'INSERT INTO "Store" ("storeId", "storeTitle") VALUES (  @storeId, @storeTitle ) RETURNING id, "storeId", "storeTitle";',
      variables: storeParams,
    );
    final storeMap = result.map((element) => element['Store']).first;
    return Response.ok(jsonEncode(storeMap));
  }

  FutureOr<Response> _getAllStore(Injector injector) async {
    final database = injector.get<RemoteDatabase>();

    final result = await database.query(
        'SELECT id, "updatedAt", "createdAt", "storeId", "storeTitle" FROM "Store";');

    // Quando tem campo data tem que converter para String senão dá pau
    final listStore = result.map((e) {
      String updateAt =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(e['Store']!['updatedAt']);
      String createdAt =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(e['Store']!['createdAt']);

      return {
        'id': e['Store']!['id'],
        'updatedAt': updateAt, // DateTime convertido para String
        'createdAt': createdAt, // DateTime convertido para String
        'storeId': e['Store']!['storeId'],
        'storeTitle': e['Store']!['storeTitle'],
      };
    }).toList();

    return Response.ok(jsonEncode(listStore));
  }

  FutureOr<Response> _getStoreByid(
      ModularArguments arguments, Injector injector) async {
    final id = arguments.params['id'];
    final database = injector.get<RemoteDatabase>();
    final result = await database.query(
        'SELECT id, "storeId", "storeTitle" FROM "Store" WHERE id = @id;',
        variables: {'id': id});
    final storeMap = result.map((element) => element['Store']).first;
    return Response.ok(jsonEncode(storeMap));
  }

  FutureOr<Response> _deleteStore(
      ModularArguments arguments, Injector injector) async {
    final id = arguments.params['id'];

    final database = injector.get<RemoteDatabase>();
    try {
      await database
          .query('DELETE FROM "Store" WHERE id = @id;', variables: {'id': id});
      return Response.ok(jsonEncode({'message': 'deleted $id'}));
    } catch (err) {
      return Response.ok(jsonEncode({'erro': err.toString()}));
    }
  }

  FutureOr<Response> _updateStore(
      ModularArguments arguments, Injector injector) async {
    final storeParams = (arguments.data as Map).cast<String, dynamic>();

/*  Esse é o jeito mais elegante, mas com for{} funciona tb 
    final columns = storeParams.keys
        .where((key) => key != 'id' && key != 'createdAt')
        .map(
          (key) => '$key=@$key',
        )
        .toList();
*/
    List<String> columns = [];

    for (String key in storeParams.keys) {
      if (key != 'id' && key != 'createdAt') {
        columns.add('"$key"=@$key');
      }
    }

    try {
      final query =
          'UPDATE "Store" SET ${columns.join(',')} WHERE id=@id RETURNING id, "storeId", "storeTitle" ;';

      final database = injector.get<RemoteDatabase>();

      final result = await database.query(
        query,
        variables: storeParams,
      );

      final storeMap = result.map((element) => element['Store']).first;

      return Response.ok(jsonEncode(storeMap));
    } catch (err) {
      return Response.notFound(jsonEncode({'erro': err.toString()}));
    }
  }
}
