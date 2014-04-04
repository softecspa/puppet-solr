define solr::create_cloud_index (
  $index_name = '',
  $num_shards,
  $replication_factor,
  $address,
  $port,
  $zookeeper_ensemble,
  $solr_root,
  $solr_version,
  $index_type,
  $solr_balanced,
  $zookeeper_balanced,
) {

  $index = $index_name ?{
    ''      => $name,
    default => $index_name
  }

  # prendo l'ultimo elemento in quanto queto contiene un eventuale /chroot
  $zookeeper_addr=inline_template("<%= @zookeeper_ensemble.split(',').at(-1) %>")

  if !defined(File["/usr/local/etc/solr_xml_config"]) {
    file {"/usr/local/etc/solr_xml_config":
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }

  if !defined(File["/usr/local/etc/solr_xml_config/${index_type}"]) {
    file {"/usr/local/etc/solr_xml_config/${index_type}":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      recurse => 'remote',
      source  => "puppet:///modules/solr/etc/xml_configs/${index_type}",
      require => File["/usr/local/etc/solr_xml_config"]
    }
  }

  if !defined(Exec["update_zookeeper_conf_${index_type}"]) {
    exec {"update_zookeeper_conf_${index_type}":
      command     => "${solr_root}/solr-${solr_version}-scripts/zkcli.sh -z ${zookeeper_balanced} -cmd upconfig -confdir /usr/local/etc/solr_xml_config/${index_type} -confname ${index_type}",
      refreshonly => true,
      subscribe   => File["/usr/local/etc/solr_xml_config/${index_type}"]
    }
  }

  exec {"upload_zookeeper_conf_${index_type}_${index}":
    command => "${solr_root}/solr-${solr_version}-scripts/zkcli.sh -z ${zookeeper_balanced} -cmd upconfig -confdir /usr/local/etc/solr_xml_config/${index_type} -confname ${index_type}",
    unless  => "${solr_root}/solr-${solr_version}-scripts/zkcli.sh -z ${zookeeper_balanced}/configs/${index_type} -cmd list 2> /dev/null",
    require => File["/usr/local/etc/solr_xml_config/${index_type}"]
  }

  exec {"create_collection_${index}":
    # la curl prende lo stato di uscita della chiamata. Se 200 OK
    command => "/usr/bin/curl -IL -w \"%{response_code}\" 'http://${solr_balanced}/solr/admin/collections?action=CREATE&name=${index}&numShards=${num_shards}&replicationFactor=${replication_factor}&collection.configName=${index_type}' -o /dev/null -q | grep 200",
    unless  => "${solr_root}/solr-${solr_version}-scripts/zkcli.sh -z ${zookeeper_balanced}/collections/${index} -cmd list 2> /dev/null",
    require => Exec["upload_zookeeper_conf_${index_type}_${index}"]
  }

}
