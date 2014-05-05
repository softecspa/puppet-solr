define solr::instance::jetty::monitoring (
  $instance_name  = '',
  $monitored_hostname,
  $notifications_enabled  = undef,
  $notification_period    = undef,
) {

  $in = $instance_name?{
    ''      => $name,
    default => $instance_name
  }

  nrpe::check_procs { "jetty-${in}":
    crit            => '1:1',
    command         => 'java',
    argument_array  => "jetty-${in}"
  }

  $nrpe_check_name = $monitored_hostname? {
    $::hostname => "!check_proc_jetty-${in}",
    default     => "!check_proc_jetty-${in}_${::hostname}"
  }

  $service_description = $monitored_hostname? {
    $::hostname => "jetty-$in",
    default     => "${::hostname} jetty-${in}",
  }

  @@nagios::check { "jetty-${in}-${::hostname}":
    host                  => $monitored_hostname,
    checkname             => 'check_nrpe_1arg',
    service_description   => $service_description,
    notifications_enabled => $notifications_enabled,
    notification_period   => $notification_period,
    target                => "solr_${::hostname}.cfg",
    params                => $nrpe_check_name,
    tag                   => "nagios_check_solr_${nagios_hostname}",
  }
}
