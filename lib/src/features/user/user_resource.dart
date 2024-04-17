import 'dart:async';
import 'dart:convert';

import 'package:backend/src/core/services/bcrypt/bcrypt_service.dart';
import 'package:backend/src/core/services/database/remote_database.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_modular/shelf_modular.dart';

import '../auth/guard/auth_guard.dart';

class UserResource extends Resource {
  @override
  List<Route> get routes => [
        Route.get('/user', _getAllUser,
            middlewares: [AuthGuard()]), // AuthGuard()
        Route.get('/user/:id', _getUserByid,
            middlewares: [AuthGuard()]), // AuthGuard()
        Route.post('/user', _createUser),
        Route.put('/user', _updateUser,
            middlewares: [AuthGuard()]), // AuthGuard()
        Route.delete('/user/:id', _deleteUser,
            middlewares: [AuthGuard()]), // AuthGuard()
      ];

  FutureOr<Response> _getAllUser(Injector injector) async {
    final database = injector.get<RemoteDatabase>();
    final result = await database.query(
        'SELECT id, "username", "fullname", "email", "cpf", "storeId", "role" FROM "User";');

    final listUsers = result.map((e) => e['User']).toList();

    return Response.ok(jsonEncode(listUsers));
  }

  FutureOr<Response> _getUserByid(
      ModularArguments arguments, Injector injector) async {
    final id = arguments.params['id'];
    final database = injector.get<RemoteDatabase>();
    final result = await database.query(
        'SELECT id, "username", "fullname", "email", "cpf", "storeId", "role", "password" FROM "User" WHERE id = @id;',
        variables: {'id': id});
    final userMap = result.map((element) => element['User']).first;
    return Response.ok(jsonEncode(userMap));
  }

  FutureOr<Response> _deleteUser(
      ModularArguments arguments, Injector injector) async {
    final id = arguments.params['id'];

    final database = injector.get<RemoteDatabase>();
    await database
        .query('DELETE FROM "User" WHERE id = @id;', variables: {'id': id});
    return Response.ok(jsonEncode({'message': 'deleted $id'}));
  }

  FutureOr<Response> _createUser(
      ModularArguments arguments, Injector injector) async {
    final bcrypt = injector.get<BCryptService>();

    final userParams = (arguments.data as Map).cast<String, dynamic>();
    userParams['password'] = bcrypt.generateHash(userParams['password']);

    final database = injector.get<RemoteDatabase>();
    final result = await database.query(
      'INSERT INTO "User" (id, "updatedAt", "createdAt", "username", "fullname", "cpf", "email", "password", "storeId") VALUES ( @id, @updatedAt, @createdAt, @username, @fullname, @cpf, @email, @password, @storeId ) RETURNING id, "email", "username", "fullname", "cpf", "storeId";',
      variables: userParams,
    );
    final userMap = result.map((element) => element['User']).first;
    return Response.ok(jsonEncode(userMap));
  }

  FutureOr<Response> _updateUser(
      ModularArguments arguments, Injector injector) async {
    final userParams = (arguments.data as Map).cast<String, dynamic>();

    final columns = userParams.keys
        .where((key) => key != 'id' || key != 'password' || key != 'createdAt')
        .map(
          (key) => '$key=@$key',
        )
        .toList();

    try {
      final query =
          'UPDATE "User" SET ${columns.join(',')} WHERE id=@id RETURNING id, "username";';

      final database = injector.get<RemoteDatabase>();
      final result = await database.query(
        query,
        variables: userParams,
      );
      final userMap = result.map((element) => element['User']).first;
      return Response.ok(jsonEncode(userMap));
    } catch (err) {
      return Response.notFound(jsonEncode({'erro': err.toString()}));
    }
  }
}
