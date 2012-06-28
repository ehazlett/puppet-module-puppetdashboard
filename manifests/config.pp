class puppetdashboard::config inherits puppetdashboard::params {
  Exec {
    path      => "${::path}",
    logoutput => on_failure,
  }

  exec { "puppetdashboard::config::puppetlabs_apt_repo_config":
    cwd     => "/tmp"
    command => "wget wget http://apt.puppetlabs.com/puppetlabs-release_1.0-3_all.deb -O puppetlabs.deb; dpkg -i puppetlabs.deb"
    notify  => Exec["puppetdashboard::config::update_apt"],
  }
  exec { "puppetdashboard::config::update_apt":
    command     => "apt-get -y update",
    user        => root,
    require     => Exec["puppetdashboard::config::import_puppetlabs_apt_key"],
    refreshonly => true,
  }
  file { "puppetdashboard::config::dashboard_default":
    path    => "/etc/default/puppet-dashboard",
    content => template("puppetdashboard/dashboard_default.erb"),
    owner   => "root",
    group   => "root",
    mode    => 0644,
  }
  file { "puppetdashboard::config::dashboard-workers_default":
    path    => "/etc/default/puppet-dashboard-workers",
    content => template("puppetdashboard/dashboard-workers_default.erb"),
    owner   => "root",
    group   => "root",
    mode    => 0644,
  }
}
