# Sets up a cron job to take a database dump and store it compressed and encrypted
define backup::encrypted_db_dump_job (
  Enum['postgres', 'mysql'] $provider,
  String $recipient,
  $backup_location,
  $day           = '*',
  $db_name       = $title,
  $hour          = '03',
  $minute        = '00',
) {

  dirtree {$backup_location:
    ensure  => present,
    parents => true,
  }

  file {$backup_location:
    ensure => directory,
    mode   => 'a+rw',
  }

  package{'gnupg':}

  case $provider {
    'postgres': {
      package{'postgresql-client-common':}

      $script_file = '/usr/local/bin/backup_db_postgres.sh'
      file {$script_file:
        source => 'puppet:///modules/backup/backup_db_postgres.sh',
        mode   => 'a+x',
      }
      cron {"backup database ${db_name}":
        command => "${script_file} ${db_name} ${backup_location} ${recipient}",
        user    => 'root',
        day     => $day,
        hour    => $hour,
        minute  => $minute,
        require => [
          File[$backup_location, $script_file],
          Package['postgresql-client-common', 'gnupg'],
        ],
      }
    }
    'mysql': {
      package{['mysql-client']:}

      $script_file = '/usr/local/bin/backup_db_mysql.sh'
      file {$script_file:
        source => 'puppet:///modules/backup/backup_db_mysql.sh',
        mode   => 'a+x',
      }
      cron {"backup database ${db_name}":
        command => "${script_file} ${db_name} ${backup_location} ${recipient}",
        user    => 'root',
        day     => $day,
        hour    => $hour,
        minute  => $minute,
        require => [
          File[$backup_location, $script_file],
          Package['mysql-client', 'gnupg'],
        ],
      }
    }
    default: {
      fail('No database provider specified!')
    }
  }
}
