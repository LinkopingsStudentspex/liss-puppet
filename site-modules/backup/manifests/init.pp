# Defines the backup jobs that should be done
class backup (
  $recipient = "root@${::hostname}",
  $db_backup_location = '/backups/databases',
) {

  dirtree {$db_backup_location:
    ensure  => present,
    parents => true,
  }

  file {$db_backup_location:
    ensure => directory,
    mode   => 'a+rw',
  }

  $pg_backup_script = '/usr/local/bin/backup_db_postgres.sh'
  file {$pg_backup_script:
    source => 'puppet:///modules/backup/backup_db_postgres.sh',
    mode   => 'a+x',
  }

  $mysql_backup_script = '/usr/local/bin/backup_db_mysql.sh'
  file {$mysql_backup_script:
    source => 'puppet:///modules/backup/backup_db_mysql.sh',
    mode   => 'a+x',
  }

  cron {'backup database django':
    command => "${pg_backup_script} django ${db_backup_location} ${recipient}",
    user    => 'root',
    weekday => '*',
    hour    => '03',
    minute  => '05',
    require => [
      File[$db_backup_location, $pg_backup_script],
      Package['gnupg'],
    ],
  }

  cron {'backup database keycloak':
    command => "${pg_backup_script} keycloak ${db_backup_location} ${recipient}",
    user    => 'root',
    weekday => '*',
    hour    => '03',
    minute  => '10',
    require => [
      File[$db_backup_location, $pg_backup_script],
      Package['gnupg'],
    ],
  }

  cron {'backup database wikidb':
    command => "${mysql_backup_script} wikidb ${db_backup_location} ${recipient}",
    user    => 'root',
    weekday => '*',
    hour    => '03',
    minute  => '15',
    require => [
      File[$db_backup_location, $mysql_backup_script],
      Package['gnupg'],
    ],
  }
}
