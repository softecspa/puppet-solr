define solr::instance::jetty::config (
  $cloud,
  $zookeeper_ensemble = '',
  $solr_root,
  $solr_version
) {

  $in = $name

  jetty::instance::java_options{"solr_home-${in}":
    instance_name => $in,
    option        => "-Dsolr.solr.home=${solr_root}/solr-${in}"
  }

  if ($cloud) {

    if $zookeeper_ensemble == '' {
      fail ('Please specify zookeeper_ensemble parameter')
    }

    jetty::instance::java_options{"zookeepers-${in}":
      instance_name => $in,
      option        => "-DzkHost=${zookeeper_ensemble}"
    }
  }

  if !defined(File["${solr_root}/solr-${solr_version}-scripts/"]) {
    file {"${solr_root}/solr-${solr_version}-scripts/":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0775',
      recurse => 'remote',
      source  => "puppet:///modules/solr/solr-${solr_version}/scripts/"
    }
  }
}
