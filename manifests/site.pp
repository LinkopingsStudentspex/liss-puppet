$organization_domain = lookup('organization_domain')
$smtp_host = lookup('smtp_host')
$smtp_user = lookup('smtp_user')
$smtp_password = lookup('smtp_password')
$smtp_port = lookup('smtp_port')

node default {
  include internsidor
  include keycloak_liss
}
