# Configures a service that runs the mail filtering
class internsidor::milter {

  file {'/etc/systemd/system/lissmilter.service':
    ensure  => file,
    content => epp('internsidor/lissmilter.service.epp'),
  }

  service {'lissmilter':
    ensure    => running,
    enable    => true,
    require   => Vcsrepo[$internsidor::project_path],
    subscribe => File['/etc/systemd/system/lissmilter.service'],
  }
}
