#
class ibm_installation_manager (
  $deploy_source = false,
  $source        = undef,
  $target        = '/opt/IBM/InstallationManager',
  $source_dir    = '/opt/IBM/tmp/InstallationManager',
  $user          = 'root',
  $group         = 'root',
  $options       = undef,
  $timeout       = '900',
) {

  validate_bool($deploy_source)
  validate_string($options, $user, $group)
  validate_integer($timeout)

  if $deploy_source and ! $source {
    fail("${module_name} requires a source parameter to be set.")
  }

  $timestamp  = chomp(generate('/bin/date', '+%Y%d%m_%H%M%S'))

  if $options {
    $_options = $options
  } else {
    $_options = "-acceptLicense -s -log /tmp/IM_install.${timestamp}.log.xml -installationDirectory ${target}"
  }

  if $deploy_source {
    exec { "mkdir -p ${source_dir}":
      creates => $source_dir,
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
      user    => "$user",
      group   => "$group"
    }

    package { 'unzip':
      ensure => present,
      before => Archive["${source_dir}/ibm-agent_installer.zip"],
    }

    file { $source_dir:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
    }

    archive { "${source_dir}/ibm-agent_installer.zip":
      extract      => true,
      extract_path => $source_dir,
      source       => $source,
      creates      => "${source_dir}/tools/imcl",
      require      => File[$source_dir],
      before       => Exec['Install IBM Installation Manager'],
      user 	   => $user,
      group        => $group
    } ~>
     exec {"chown ${source_dir}":
         command  => "chown -R $user:$group ${source_dir}",
         path     => ['/bin','/usr/bin','/usr/sbin'] 
     }
  }
   
  exec { 'Install IBM Installation Manager':
    command => "${source_dir}/userinstc ${_options}",
    creates => "${target}/eclipse/tools/imcl",
    cwd     => $source_dir,
    user    => $user,
    timeout => $timeout,
  } ~>
  exec {'Installation Manager Permission':
     command  => "chown -R $user:$group ${target}",
     path     => ['/bin','/usr/bin/','/usr/sbin/']
  }
}
