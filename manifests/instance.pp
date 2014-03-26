define solr::instance (
  $instance_name        = '',
  $app_server           = 'jetty',
  $jetty_version        = '',
  $jetty_s3_bucket      = '',
  $jetty_download_url   = '',
  $jetty_root           = '/opt',
  $jetty_user           = 'jetty',
  $jetty_uid            = undef,
  $jetty_gid            = undef,
  $listen_address       = '',
  $listen_interface     = '',
  $port,
  $solr_version,
  $solr_root            = '/opt',
) {

  $in = $instance_name?{
    ''      => $name,
    default => $instance_name
  }

  $listen = $listen_address?{
    ''      => inline_template("<%= ipaddress_${listen_interface} %>"),
    default => $listen_address,
  }

  case $app_server {
    'jetty': {
      jetty::instance{$in:
        version               => $jetty_version,
        package_s3_bucket     => $jetty_s3_bucket,
        package_download_url  => $jetty_download_url,
        root                  => $jetty_root,
        user                  => $jetty_user,
        user_uid              => $jetty_uid,
        user_gid              => $jetty_gid,
        listen                => $listen,
        port                  => $port,
      }

      jetty::instance::deploy {"solr-${in}":
        context_name  => 'solr',
        instance_name => $in,
        war_source    => "puppet:///modules/solr/solr-${solr_version}.war",
        war_path      => '/opt',
        war_name      => "solr-${solr_version}.war",
      }

      jetty::instance::java_options{"solr_home-${in}":
        instance_name => $in,
        option        => "-Dsolr.solr.home=${solr_root}/solr-${in}"
      }

      file {"${solr_root}/solr-${in}":
        ensure  => directory,
        owner   => $jetty_user,
        group   => $jetty_user,
        mode    => '0775',
      }

      file{"${solr_root}/solr-${in}/bin":
        ensure  => directory,
        owner   => $jetty_user,
        group   => $jetty_user,
        mode    => '0775',
        require => File["${solr_root}/solr-${in}"],
      }

      file {"${solr_root}/solr-${in}/solr.xml.default":
        ensure  => present,
        owner   => $jetty_user,
        group   => $jetty_user,
        mode    => '0664',
        content => template('solr/solr.xml.default.erb'),
        require => File["${solr_root}/solr-${in}"],
      }

      exec {"cp solr.xml.default -> solr.xml ${in}":
        command => "/bin/cp ${solr_root}/solr-${in}/solr.xml.default ${solr_root}/solr-${in}/solr.xml",
        creates => "${solr_root}/solr-${in}/solr.xml",
        require => File["${solr_root}/solr-${in}/solr.xml.default"]
      }

      $test = puppetdb_query('https://puppetmaster.vagrant.local:8081','resources','["=", "title", "Apt"]')
      notice($test)

      #Jetty::Instance[$in] ->
      #Jetty::Instance::Deploy['solr']
      #Jetty::Instance::Java_options['solr_home']
    }
  }

}
