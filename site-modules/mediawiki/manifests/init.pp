# Konfigurerar och installerar Mediawiki
class mediawiki (
  $admin_email = "root@${::organization_domain}",
  $baseurl = '',
  $domain = '',
  $oidc_clientid = 'mediawiki',
  $oidc_clientsecret = '',
  $secretkey = '',
  $upgradekey = '',
  $version_major_minor = '',
  $version_patch = '',
  $wiki_admin_pass = '',
  $wiki_admin_user = 'admin',
  $wiki_db_host = 'localhost',
  $wiki_db_name = 'wikidb',
  $wiki_db_pass = '',
  $wiki_db_user = 'wikiuser',
  $wiki_title = 'Internwiki',

) {
  require mysql::server
  contain mediawiki::nginx_config
  contain mediawiki::install

  keycloak_client { $oidc_clientid:
    realm                 => 'liss',
    secret                => $oidc_clientsecret,
    redirect_uris         => ["https://${domain}/index.php?title=Special:PluggableAuthLogin"],
    default_client_scopes => ['profile', 'email'],
  }

  file {'/var/www/mediawiki/LocalSettings.php':
    ensure  => file,
    content => epp('mediawiki/LocalSettings.php.epp'),
    require => Exec['mediawiki_install_script'],
  }
}
