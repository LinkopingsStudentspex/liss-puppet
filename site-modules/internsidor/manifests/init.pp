# Configures and installs the django application
class internsidor (
  $admin_email           = "root@${::organization_domain}",
  $debug                 = false,
  $django_db_name        = 'django',
  $django_db_pass        = '',
  $django_db_user        = 'django',
  $django_secret_key     = '',
  $domain                = '',
  $oidc_clientid         = 'internsidor',
  $oidc_clientsecret     = '',
  $project_path          = '/opt/internsidor/src',
  $static_files_path     = '/var/www/internsidor/static',
  $venv_path             = '/opt/internsidor/venv',
  $milter_port           = undef,
  $recipient_lookup_port = undef,
  $gunicorn_port         = undef,
) {
  include nginx
  include postgresql::server
  include postfix
  include base::certificates
  contain internsidor::install
  contain internsidor::milter
  contain internsidor::recipient_lookup
  contain internsidor::web_server

  keycloak_client { $oidc_clientid:
    realm                 => 'liss',
    secret                => $oidc_clientsecret,
    redirect_uris         => ["https://${domain}/*"],
    default_client_scopes => ['profile', 'email'],
  }

  file {"${project_path}/internsidor/settings/local.py":
    ensure  => file,
    content => epp('internsidor/settings/local.py.epp'),
    notify  => Service['internsidor-gunicorn'],
  }

  # Create and manage a user that can connect from the old system
  user {'lisse':
    home => '/home/lisse',
  }

  # Only allow lisse to run the sync/export script from ssh
  ssh_authorized_key {'lisse-export':
    type    => 'ssh-rsa',
    key     => 'AAAAB3NzaC1yc2EAAAADAQABAAACAQDCN+sK0tX9K1hteFRnykLqxwsyHLjhEvsMgMR/uEyTNx2+aUwtD33sM6+4eyQYviNWb1lvQaPQN9tFVZPEMH/25+l/X3uUKlyIrW3qveoVZlVy1bzOoEHIBKStccFUhFIiKjqyHQXMIk8aBIElPXJkd//kLhkQqVZEjHY3e8pPuKt4ETQgiodVwefnVTAkTeOBMFWFmAAdTas8jB35QCgpOVHVaq1allEcm2Jl6ok/Vy85ds4Vc0m2ijs1tDrCIye9KrU7rrENKxgsBTUsRTChPfUVh1Zt4LSRCOEDCha/Wuh90CKhssuW2BmN3+mYWNS6VykIqKm+uhMTzVJGyIt1O86O/VTUFjV4V9gCaXS40WCFRQEuNghTLeRfm+fO9I8NHYB4Fl4ua82ztmkMS9xiwOcLd36cLtTtlZJPVscrLmSdV6C5spm2tru8jetRwqK14X55uon63VikxacsXytHp7S/MABolMfqupG7JAZx4z7ItotFXkaLugGGQLISGPUTQ9HoXUrzDDQbg1uSgpZZzL5hoM80yTTNkyGCBt6ot5d2+omY9DaYbLNnBD2dO6a3cjiaQJ8QS9O4hEblP2Cwu/9vBcVUSua3b+GKQMYrZs6Jj65/SGKudTuObdwpqop1oIfi+WPVyriZu4otbNacYkg2SG13MZdCAKWPC9/xwQ==',
    user    => 'lisse',
    options => ["command=\"PYTHONIOENCODING='utf8' ${venv_path}/bin/python ${project_path}/legacy_export.py\""],
  }
}
