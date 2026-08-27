import 'package:core/errors/result.dart';

typedef ActivationCodeIssuer =
    Future<Result<String>> Function(int actorUserId, String email);
