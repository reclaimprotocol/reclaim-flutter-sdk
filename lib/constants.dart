const String BACKEND_BASE_URL = 'https://api.reclaimprotocol.org';

class Constants {
  static const String GET_PROVIDERS_BY_ID_API =
      '$BACKEND_BASE_URL/api/applications';
  static const String DEFAULT_RECLAIM_CALLBACK_URL =
      '$BACKEND_BASE_URL/api/sdk/callback?callbackId=';
  static const String DEFAULT_RECLAIM_STATUS_URL =
      '$BACKEND_BASE_URL/api/sdk/session/';
  static const String RECLAIM_SHARE_URL =
      'https://share.reclaimprotocol.org/instant/?template=';
  static const String BRANCH_KEY = 'key_live_lqcVdeunUUDSrPmxrMETzdjhDvhcw5CF';
  static const String RECLAIM_GET_BRANCH_URL =
      '$BACKEND_BASE_URL/api/sdk/get-branch-url';
}
