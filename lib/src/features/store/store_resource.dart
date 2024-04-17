import 'dart:async';
import 'dart:convert';

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
      'INSERT INTO "Store" (id, "createdAt", "updatedAt", "storeId", "storeTitle") VALUES ( @id, @updatedAt, @createdAt, @storeId, @storeTitle ) RETURNING id, "storeId", "storeTitle";',
      variables: storeParams,
    );
    final userMap = result.map((element) => element['Store']).first;
    return Response.ok(jsonEncode(userMap));
  }

  FutureOr<Response> _getAllStore(Injector injector) async {
    final database = injector.get<RemoteDatabase>();

    final result = await database
        .query('SELECT id, "storeId", "storeTitle" FROM "Store";');

    final listUsers = result.map((e) => e['Store']).toList();

    return Response.ok(jsonEncode(listUsers));
  }

  FutureOr<Response> _getStoreByid(
      ModularArguments arguments, Injector injector) async {
    final id = arguments.params['id'];
    final database = injector.get<RemoteDatabase>();
    final result = await database.query(
        'SELECT id, "storeId", "storeTitle" FROM "Store" WHERE id = @id;',
        variables: {'id': id});
    final userMap = result.map((element) => element['Store']).first;
    return Response.ok(jsonEncode(userMap));
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
    final userParams = (arguments.data as Map).cast<String, dynamic>();

    final columns = userParams.keys
        .where((key) => key != 'id' || key != 'createdAt')
        .map(
          (key) => '$key=@$key',
        )
        .toList();

    try {
      final query =
          'UPDATE "Store" SET ${columns.join(',')} WHERE id=@id RETURNING id, "storeTitle";';

      final database = injector.get<RemoteDatabase>();
      final result = await database.query(
        query,
        variables: userParams,
      );
      final userMap = result.map((element) => element['Store']).first;
      return Response.ok(jsonEncode(userMap));
    } catch (err) {
      return Response.notFound(jsonEncode({'erro': err.toString()}));
    }
  }
}
