# Defines the backup jobs that should be done
class backup (
  $recipient = "root@${::hostname}",
  $db_backup_location = '/backups/databases',
) {

  backup::encrypted_db_dump_job{'django':
    provider        => 'postgres',
    recipient       => $recipient,
    backup_location => $db_backup_location,
    hour            => '03',
    minute          => '05',
  }

  backup::encrypted_db_dump_job{'keycloak':
    provider        => 'postgres',
    recipient       => $recipient,
    backup_location => $db_backup_location,
    hour            => '03',
    minute          => '10',
  }

  backup::encrypted_db_dump_job{'wikidb':
    provider        => 'mysql',
    recipient       => $recipient,
    backup_location => $db_backup_location,
    hour            => '03',
    minute          => '15',
  }
}
