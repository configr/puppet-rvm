class rvm::system($version=undef) {

  $actual_version = $version ? {
    undef     => 'latest',
    'present' => 'latest',
    default   => $version,
  }

  exec { 'rvm-gpg-add':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => 'gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3',
    require => [
      Class['rvm::dependencies'],
    ],
  }

  exec { 'system-rvm':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "bash -c '/usr/bin/curl -sL https://get.rvm.io -o /tmp/rvm-installer && \
                chmod +x /tmp/rvm-installer && \
                rvm_bin_path=/usr/local/rvm/bin rvm_man_path=/usr/local/rvm/man /tmp/rvm-installer --version ${actual_version} && \
                rm /tmp/rvm-installer'",
    creates => '/usr/local/rvm/bin/rvm',
    require => [
      Class['rvm::dependencies'],
      Exec['rvm-gpg-add'],
    ],
  }

  # the fact won't work until rvm is installed before puppet starts
  if "${::rvm_version}" != "" {
    if ($version != undef) and ($version != present) and ($version != $::rvm_version) {
      # Update the rvm installation to the version specified
      notify { 'rvm-get_version':
        message => "RVM updating to version ${version}",
      } ->
      exec { 'system-rvm-get':
        path    => '/usr/local/rvm/bin:/usr/bin:/usr/sbin:/bin',
        command => "rvm get ${version}",
        before  => Exec['system-rvm'], # so it doesn't run after being installed the first time
      }
    }
  }

}
