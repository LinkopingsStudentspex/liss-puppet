$organization_domain = lookup('organization_domain')
$smtp_host = lookup('smtp_host')
$smtp_password = lookup('smtp_password')
$smtp_port = lookup('smtp_port')
$keycloak_auth_url = lookup('keycloak_auth_url')
$nfs_storage_path = lookup('nfs_storage_path')

node default {
  include base
  include backup
  include internsidor
  include keycloak_liss
  include mediawiki
}
