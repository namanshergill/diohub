import 'package:diohub/graphql/queries/users/__generated__/user_info.data.gql.dart';
import 'package:diohub/providers/base_provider.dart';
import 'package:diohub/services/users/user_info_service.dart';

class UserProvider extends BaseDataProvider<GuserInfoData_repositoryOwner> {
  UserProvider(this._userName);
  final String _userName;

  @override
  Future<GuserInfoData_repositoryOwner> setInitData(
          {final bool isInitialisation = false}) =>
      UserInfoService.getUserInfoGraphQL(_userName);
}
