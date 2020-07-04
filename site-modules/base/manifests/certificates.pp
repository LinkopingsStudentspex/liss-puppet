# SSL certificates for all domains via letsencrypt
class base::certificates {
  include letsencrypt
  letsencrypt::certonly {'sites':
    domains              => [
      lookup('keycloak_liss::domain'),
      lookup('internsidor::domain'),
      lookup('mediawiki::domain'),
    ],
    manage_cron          => true,
    suppress_cron_output => true,
    cron_hour            => '4',
    cron_minute          => '10',
    pre_hook_commands    => ['/bin/systemctl stop nginx',],
    post_hook_commands   => ['/bin/systemctl restart nginx',],
  }
}
