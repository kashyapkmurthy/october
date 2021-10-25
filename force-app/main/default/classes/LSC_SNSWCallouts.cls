/**
 * @description       : Callout to Service NSW Logout API to end Service NSW session
 * @author            : Emily Jiang
 * @group             :
 * @last modified on  : 07/09/2021
 * @last modified by  : Emily Jiang
 **/
public with sharing class LSC_SNSWCallouts {
  final static String SNSW_AUTH_PROVIDER = 'myservicensw';
  final static String PROVIDER_NAME = 'Open ID Connect';
  public static ResultWrapper logoutSNSWUser() {
    ResultWrapper result = new ResultWrapper(false);
    List<AuthProvider> providerList = LSC_AuthProviderSelector.getAuthProviderByDeveloperName(
      SNSW_AUTH_PROVIDER
    );
    if (!providerList.isEmpty()) {
      Http h = new Http();
      HttpRequest req = new HttpRequest();
      String token = Auth.AuthToken.getAccessToken(
        providerList[0].Id,
        PROVIDER_NAME
      );
      String namedCredentialEndpoint = 'callout:SNSWProd';
      if (LSC_Utility.isSandbox()) {
        namedCredentialEndpoint = 'callout:SNSWStaging';
      }
      String endPointUrl =
        namedCredentialEndpoint +
        '/v1/identity/oauth/tokens/' +
        token;
      req.setEndpoint(endPointUrl);
      req.setMethod('DELETE');
      HttpResponse res = h.send(req);
      if (res.getStatusCode() == 200) {
        result.success = true;
      } else {
        result.errorMessage = 'Error occurred while calling SNSW logout service.';
      }
    } else {
      result.errorMessage = 'No Auth. Provider found';
    }
    return result;
  }

  public class ResultWrapper {
    public Boolean success { get; set; }
    public String errorMessage { get; set; }

    public ResultWrapper(Boolean success) {
      this.success = success;
    }
  }
}