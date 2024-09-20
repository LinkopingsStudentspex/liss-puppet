# Defines resources for interoperability with legacy site
class legacy (
  $oidc_clientid = 'old_site',
  $oidc_clientsecret = '',
  $domain = '',
  $spexflix_domain = '',
) {
  keycloak_client { $oidc_clientid:
    ensure                => 'absent',
    realm                 => 'liss',
    secret                => $oidc_clientsecret,
    redirect_uris         => ["https://${domain}/*", "https://${spexflix_domain}/*"],
    default_client_scopes => ['profile', 'email', 'member_number'],
  }
}
