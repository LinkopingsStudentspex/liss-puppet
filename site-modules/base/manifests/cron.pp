# Configures the times of the automatic cron jobs in /etc/cron.xxxx
class base::cron (
  $hourly_minute  = 17,
  $daily_hour     = 6,
  $daily_minute   = 25,
  $weekly_weekday = 7,
  $weekly_hour    = 6,
  $weekly_minute  = 47,
  $montly_dom     = 1,
  $monthly_hour   = 6,
  $montly_minute  = 52,
) {
  file {'/etc/crontab':
    ensure  => file,
    content => epp('base/crontab.epp'),
  }
}
