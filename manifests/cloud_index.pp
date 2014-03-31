define solr::cloud_index (
  $index_name = '',
  $num_shards,
  $replication_factor,
  $index_type,
) {

  if ($cluster == '') or ($cluster == undef) {
    fail ('variable $cluster must be defined')
  }

  $index= $index_name? {
    ''      => $name,
    default => $index_name,
  }

  @@solr::exported_cloud_index { "${index}-${fqdn}":
    index               => $index,
    num_shards          => $num_shards,
    replication_factor  => $replication_factor,
    index_type          => $index_type,
    cluster             => $cluster
  }

}
