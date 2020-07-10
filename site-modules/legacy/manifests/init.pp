# Defines resources for interoperability with legacy site
class legacy (
  $oidc_clientid = 'old_site',
  $oidc_clientsecret = '',
  $domain = '',
) {
  keycloak_client { $oidc_clientid:
    realm                 => 'liss',
    secret                => $oidc_clientsecret,
    redirect_uris         => ["https://${domain}/*"],
    default_client_scopes => ['profile', 'email', 'member_number'],
  }
}
