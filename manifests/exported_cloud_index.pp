define solr::exported_cloud_index (
  $index,
  $cluster,
  $num_shards,
  $replication_factor,
  $address,
  $port,
  $zookeeper_ensemble,
  $solr_root,
  $solr_version,
  $index_type,
  solr_balanced,
  $zookeeper_balanced,
) {

  if !defined(Solr::Create_cloud_index[$index]) {
    solr::create_cloud_index{$index:
      num_shards          => $num_shards,
      replication_factor  => $replication_factor,
      address             => $address,
      port                => $port,
      zookeeper_ensemble  => $zookeeper_ensemble,
      solr_root           => $solr_root,
      solr_version        => $solr_version,
      index_type          => $index_type,
      solr_balanced       => $solr_balanced,
      zookeeper_balanced  => $zookeeper_balanced
    }
  }

}
