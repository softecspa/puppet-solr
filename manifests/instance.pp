# Define: ispconfig_solr::instance
#
# This define creates a solr instance.
#
# Parameters:
#
# [*instance_name*]
#   name of solr instance. Instance will be called solr-$instance_name. If not present <name> will be used
#
# [*app_server*]
#   Application server to use for deploy solr webapp. Actually only jetty is supported. Default: jetty
#
# [*jetty_version*]
#   If app_server is jetty, this parameter indicate which version of jetty must be used
#
# [*jetty_s3_bucket*]
#   If app_server is jetty, this parameter indicate the name of s3 where jetty install is stored
#
# [*jetty_download_url*]
#   If app_server is jetty, this parameter indicate the url where jetty can be downloaded
#
# [*jetty_root*]
#   If app_server is jetty, this parameter indicate the root path where jetty will be installed. Default: /opt
#
# [*jetty_user*]
#   If app_server is jetty, this parameter indicate user for jetty process. Default: jetty
#
# [*jetty_uid*]
#   If app_server is jetty, this parameter indicate uid for jetty user. Default: unset
#
# [*jetty_gid*]
#   If app_server is jetty, this parameter indicate gid for jetty user. Default: unset
#
# [*jetty_deploy_parameters*]
#   hash of init parameter to sei in solr deploy over jetty.
#   Hash must have form: {"unique_name" => {param_name => 'xxxxxxxxx', param_value => "yyyyyyyy"},}
#
# [*listen_address*]
#   IP address on which solr instance is listening
#
# [*listen_interface*]
#   Interface used by solr to listen to. ipaddress_${listen_interface} will be used as listen_address
#
# [*port*]
#   Port on which solr instance will listen. Mandatory
#
# [*solr_version*]
#   Solr version to install. Mandatory
#
# [*solr_root*]
#   Root path where solr will be installed. Default: /opt
#
# [*cloud*]
#   If true, solr will be configured with zookeeper utilization for a SolrCloud installation. Zookeeper nodes have to be defined first or defined used zookeeper_servers
#   parameter (See example). Default: true
#
# [*zookeeper_servers*]
#   String that can be used, in a SolrCloud installation, to specify zookeeper ensemble's nodes. String must be in form $zoohost1:$port1,$zoohost2:$port2,$zoohost3:$port3
#   eventually followed by /$cluster if zookeeper ensemble is chrooted (ex: a zookeeper ensembled used by more clusters). If not specified a query to the puppetdb will be done
#   to retrieve zookeeper's nodes
#
# [*java_options*]
#   Java options to pass to jetty
#
# [*monitored*]
#   It true, instance will ben monitored by nagios
#
# [*monitored_hostname*]
#   Hostname used by nagios to perform the checks. Default: $::hostname
#
# [*notifications_enabled*]
#   1 enable nagios notification, 0 otherwise. Default: undef
#
# [*notification_period*]
#   Notification period used in nagios service. Default: undef
#
# Sample Usage:
#  In a SolrCloud installation, ispconfig_solr and zookeeper module are used in conjuction.
#  Suppose to have a cluster named ZOO where a zookeeper ensemble will be installed, and a cluster named SOLRCLUSTER where we want to install a SolrCloud system.
#  First, we define the zookeeper ensemble's nodes in the cluster ZOO definition (suppose three instances on the same machine).
#  After this, we define ispconfig_solr::instance, the define will call the puppetDB to know the zookeeper's nodes.
#
#  ##### ZOOKEEPER SECTION ###########
#  node ZOO {
#    $cluster = 'zoo'
#
#    class {'zookeeper::ensemble::solr':
#      chroot  => true,
#      nodes   => {'zoohost:port1' => {id =>1, address => 'zoohost', client_port => 'port1', leader_port =>'l_port1', election_port => 'e_port1'},
#                  'zoohost:port2' => {id =>2, address => 'zoohost', client_port => 'port2', leader_port =>'l_port2', election_port => 'e_port2'},
#                  'zoohost:port3' => {id =>3, address => 'zoohost', client_port => 'port3', leader_port =>'l_port3', election_port => 'e_port3'}},
#      tags    => ['SOLRCLUSTER']
#    }
#  }
#  # NOTE: see zookeeper::ensemble::solr documentation for more information about used variables
#
#  node zoohost inherits ZOO {
#    Zookeeper::Instance {
#      listen_address  => 'x.x.x.x',
#    }
#    zookeeper::instance {'1':}
#    zookeeper::instance {'2':}
#    zookeeper::instance {'3':}
#  }
#  ####################################
#  ######## SOLR SECTION ##############
#
#  node SOLRCLUSTER {
#
#    $cluster = 'SOLRCLUSTER'
#
#    Ispconfig_solr::Instance {
#      jetty_version     => '9.1.3',
#      jetty_s3_bucket   => 'softec-jetty',
#      solr_version      => '4.7.0',
#    }
#  }
#
#  node solr1 inherits SOLRCLUSTER {
#    ispconfig_solr::instance {'solr1':
#      listen_address => 'x.x.x.x'
#      port  => '8983',
#    }
#  }
#
#  node solr2 inherits SOLRCLUSTER {
#    ispconfig_solr::instance {'solr2':
#      listen_address => 'x.x.x.x'
#      port  => '8984',
#    }
#  }
#
define solr::instance (
  $instance_name            = '',
  $app_server               = 'jetty',
  $jetty_version            = '',
  $jetty_s3_bucket          = '',
  $jetty_download_url       = '',
  $jetty_root               = '/opt',
  $jetty_user               = 'jetty',
  $jetty_uid                = undef,
  $jetty_gid                = undef,
  $jetty_deploy_parameters  = '',
  $listen_address           = '',
  $listen_interface         = '',
  $port,
  $solr_version,
  $solr_root                = '/opt',
  $cloud                    = true,
  $zookeeper_servers        = '',
  $java_options             = '',
  $monitored                = true,
  $monitored_hostname       = $::hostname,
  $notifications_enabled    = undef,
  $notification_period      = undef,
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
        jetty_version           => $jetty_version,
        jetty_s3_bucket         => $jetty_s3_bucket,
        jetty_download_url      => $jetty_download_url,
        jetty_root              => $jetty_root,
        jetty_user              => $jetty_user,
        jetty_uid               => $jetty_uid,
        jetty_gid               => $jetty_gid,
        jetty_deploy_parameters => $jetty_deploy_parameters,
        listen                  => $listen,
        port                    => $port,
        solr_version            => $solr_version,
        solr_root               => $solr_root,
        java_options            => $java_options,
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
      } else {
        $zookeeper_ensemble = ''
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

      if $monitored {
        solr::instance::jetty::monitoring { $in:
          monitored_hostname      => $monitored_hostname,
          notifications_enabled   => $notifications_enabled,
          notification_period     => $notification_period,
        }

        if !defined(Solr::Cloud_monitoring[$::hostname]) {
          solr::cloud_monitoring{$::hostname :
            zookeeper_ensemble      => $zookeeper_ensemble,
            notifications_enabled   => $notifications_enabled,
            notification_period     => $notification_period,
          }
        }
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
