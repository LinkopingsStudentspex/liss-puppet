# Configures a service that runs the recipient lookup for mailing lists
class internsidor::recipient_lookup {

  file {'/etc/systemd/system/recipient-lookup.service':
    ensure  => file,
    content => epp('internsidor/recipient-lookup.service.epp'),
  }

  service {'recipient-lookup':
    ensure    => running,
    enable    => true,
    require   => Vcsrepo[$internsidor::project_path],
    subscribe => File['/etc/systemd/system/recipient-lookup.service'],
  }
}
