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
  $cloud                = true,
  $zookeeper_servers    = '',
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

      solr::instance::jetty::install {$in:
        jetty_version       => $jetty_version,
        jetty_s3_bucket     => $jetty_s3_bucket,
        jetty_download_url  => $jetty_download_url,
        jetty_root          => $jetty_root,
        jetty_user          => $jetty_user,
        jetty_uid           => $jetty_uid,
        jetty_gid           => $jetty_gid,
        listen              => $listen,
        port                => $port,
        solr_version        => $solr_version,
        solr_root           => $solr_root,
      }

      if ($cloud) {
        if ($zookeeper_servers != '') {
          $zookeeper_ensemble=$zookeeper_servers
        } else {
          $nodes = puppetdb_query("https://${settings::certname}:8081","resources/Zookeeper::Ensemble::Component::Node","[\"~\", \"title\", \"${cluster}\"]")
          $n_result=inline_template('<%= @nodes.size %>')
          if $n_result == '0' {
            fail('no zookeeper ensemble found!')
          }
          $zookeepers=inline_template('<% @nodes.each do |node| %><%= node["parameters"]["address"] %>:<%= node["parameters"]["client_port"] %>,<% end %>')
          # se un nodo zookeeper è chrootato lo sono tutti. Controllo solo il primo risultato nell'array
          $chroot=inline_template('<%= @nodes[0]["parameters"]["chroot"] %>')
          if $chroot == 'true' {
            $zookeeper_ensemble=regsubst($zookeepers,',$',"/${cluster}")
          } else {
            $zookeeper_ensemble=regsubst($zookeepers,',$','')
          }
        }
      }


      solr::instance::jetty::config {$in:
        cloud               => $cloud,
        solr_root           => $solr_root,
        solr_version        => $solr_version,
        zookeeper_ensemble  => $zookeeper_ensemble
      }

      solr::instance::jetty::service {$in:
        listen  => $listen,
        port    => $port
      }

      #if ($cloud) {
      #  Solr::Exported_cloud_index <<| cluster == $cluster |>> {
      #    address             => $listen,
      #    port                => $port,
      #    zookeeper_ensemble  => $zookeeper_ensemble,
      #    solr_root           => $solr_root,
      #    solr_version        => $solr_version,
      #    require             => Solr::Instance::Jetty::Config[$in]
      #  }
      #}

    }
  }
}
