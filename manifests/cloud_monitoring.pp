define solr::cloud_monitoring (
  $zookeeper_ensemble,
  $notifications_enabled   = undef,
  $notification_period     = undef,
) {

  nrpe::check_solr_cloud { 'solr_cloud':
    zookeeper_ensemble  => $zookeeper_ensemble
  }

  @@nagios::check { "colr_cloud-${::hostname}":
    host                  => $::hostname,
    checkname             => 'check_nrpe_1arg',
    service_description   => 'solr cloud',
    notifications_enabled => $notifications_enabled,
    notification_period   => $notification_period,
    target                => "solr_${::hostname}.cfg",
    params                => "!check_solr_cloud",
    tag                   => "nagios_check_solr_${nagios_hostname}",
  }

}
