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

  keycloak_client_scope { 'member_number':
    realm => 'liss',
  }

  keycloak_protocol_mapper { 'member_number':
    user_attribute  => 'member_number',
    claim_name      => 'member_number',
    json_type_label => 'int',
    client_scope    => 'member_number',
    realm           => 'liss',
    require         => Keycloak_client_scope['member_number'],
  }
}
