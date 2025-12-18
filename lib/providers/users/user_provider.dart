import 'dart:async';

import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/services/users/user_info_service.dart';

class UserProvider extends BaseDataProvider<GuserInfoData_user> {
  UserProvider(this._userName);
  final String _userName;

  @override
  Future<GuserInfoData_user> setInitData(
          {final bool isInitialisation = false}) =>
      UserInfoService.getUserInfoGraphQL(_userName);
}
