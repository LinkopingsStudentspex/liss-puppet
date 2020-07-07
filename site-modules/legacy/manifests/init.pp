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
    default_client_scopes => ['profile', 'email'],
  }

  keycloak_client_protocol_mapper { 'member number for legacy site':
    claim_name      => 'member_number',
    user_attribute  => 'member_number',
    json_type_label => 'int',
    resource_name   => 'member number',
    type            => 'oidc-usermodel-attribute-mapper',
    client          => $oidc_clientid,
    realm           => 'liss',
  }
}
