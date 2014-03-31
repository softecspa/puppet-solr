define solr::instance::jetty::service (
  $instance_name = '',
  $listen,
  $port,
) {

  $in = $instance_name?{
    ''      => $name,
    default => $instance_name
  }

  exec {"restart_jetty_${in}":
    command => "/etc/init.d/jetty-${in} restart",
    unless  => "/usr/bin/curl -I -w \"%{http_code}\" \"http://${listen}:${port}/solr/\" -o /dev/null | grep 200",
  }
}
