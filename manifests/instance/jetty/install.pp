define solr::instance::jetty::install (
  $jetty_version,
  $jetty_s3_bucket,
  $jetty_download_url,
  $jetty_root,
  $jetty_user,
  $jetty_uid  = undef,
  $jetty_gid  = undef,
  $listen,
  $port,
  $solr_version,
  $solr_root,
) {

  $in = $name

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
    content => template("solr/solr-${solr_version}.xml.default.erb"),
    require => File["${solr_root}/solr-${in}"],
  }

  file {"${solr_root}/solr-${in}/contrib":
    ensure  => directory,
    owner   => $jetty_user,
    group   => $jetty_user,
    mode    => '0755',
    source  => "puppet:///solr/solr-${solr_version}/contrib",
    recurse => 'remote',
    require => File["${solr_root}/solr-${in}"],
  }

  exec {"cp solr.xml.default -> solr.xml ${in}":
    command => "/bin/cp -a ${solr_root}/solr-${in}/solr.xml.default ${solr_root}/solr-${in}/solr.xml",
    creates => "${solr_root}/solr-${in}/solr.xml",
    require => File["${solr_root}/solr-${in}/solr.xml.default"]
  }

}