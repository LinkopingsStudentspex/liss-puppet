# Defines the backup jobs that should be done
class backup (
  # GPG user IDs that can decrypt the backups
  Array[String] $recipients = [],
  $db_backup_location = '/backups/databases',
) {

  dirtree {$db_backup_location:
    ensure  => present,
    parents => true,
  }

  file {$db_backup_location:
    ensure => directory,
    mode   => '0755',
  }

  $pg_backup_script = '/usr/local/bin/backup_db_postgres.sh'
  file {$pg_backup_script:
    content => epp('backup/backup_db_postgres.sh.epp'),
    mode    => 'a+x',
  }

  $mysql_backup_script = '/usr/local/bin/backup_db_mysql.sh'
  file {$mysql_backup_script:
    content => epp('backup/backup_db_mysql.sh.epp'),
    mode    => 'a+x',
  }

  cron {'backup database django':
    command => "${pg_backup_script} django ${db_backup_location}",
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
    command => "${pg_backup_script} keycloak ${db_backup_location}",
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
    command => "${mysql_backup_script} wikidb ${db_backup_location}",
    user    => 'root',
    weekday => '*',
    hour    => '03',
    minute  => '15',
    require => [
      File[$db_backup_location, $mysql_backup_script],
      Package['gnupg'],
    ],
  }

  # Only keeps database backups within the last 30 days
  cron {'remove old database backups':
    command => "find ${db_backup_location}/* -mtime +30 -type f -delete",
    user    => 'root',
    weekday => '*',
    hour    => '03',
    minute  => '30',
    require => [
      File[$db_backup_location],
    ],
  }
}
