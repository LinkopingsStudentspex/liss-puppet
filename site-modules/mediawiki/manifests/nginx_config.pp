# Configures nginx to serve mediawiki
class mediawiki::nginx_config {
  include php::fpm

  nginx::resource::server { $mediawiki::domain:
    autoindex            => 'off',
    index_files          => ['index.php'],
    www_root             => '/var/www/mediawiki/',
    require              => Class['::base::certificates'],
    ssl_redirect         => true,
    ssl                  => true,
    use_default_location => false,
    ssl_cert             => '/etc/letsencrypt/live/all-sites/fullchain.pem',
    ssl_key              => '/etc/letsencrypt/live/all-sites/privkey.pem',
  }

  nginx::resource::location{'/':
    server      => $mediawiki::domain,
    index_files => [],
    try_files   => ['$uri', '$uri/', '/index.php'],
    ssl         => true,
    ssl_only    => true,
  }

  nginx::resource::location{'~ \.php$':
    server        => $mediawiki::domain,
    index_files   => [],
    fastcgi_param => {
      'SCRIPT_FILENAME' => '$document_root$fastcgi_script_name',
    },
    include       => ['fastcgi_params'],
    fastcgi       => '127.0.0.1:9000',
    ssl           => true,
    ssl_only      => true,
  }

  nginx::resource::location { '~* \.(js|css|png|jpg|jpeg|gif|ico)$':
    server      => $mediawiki::domain,
    index_files => [],
    try_files   => ['$uri', '/index.php'],
    expires     => 'max',
    ssl         => true,
    ssl_only    => true,
  }

  nginx::resource::location { '^~ ^/(cache|includes|maintenance|languages|serialized|tests|images/deleted)/':
    server              => $mediawiki::domain,
    index_files         => [],
    ssl                 => true,
    ssl_only            => true,
    location_custom_cfg => {
      'deny' => 'all',
    },
  }

  nginx::resource::location { '^~ ^/(bin|docs|extensions|includes|maintenance|mw-config|resources|serialized|tests)/':
    server      => $mediawiki::domain,
    index_files => [],
    internal    => true,
    ssl         => true,
    ssl_only    => true,
  }

  nginx::resource::location { '~* ^/images/.*\.(html|htm|php|shtml)$':
    server              => $mediawiki::domain,
    index_files         => [],
    ssl                 => true,
    ssl_only            => true,
    #location_cfg_append => 'types { }',
    location_custom_cfg => {
      'default_type' => 'text/plain',
    },
  }

  nginx::resource::location { '^~ /images/':
    server      => $mediawiki::domain,
    index_files => [],
    try_files   => ['$uri', '/index.php'],
    ssl         => true,
    ssl_only    => true,
  }
}
