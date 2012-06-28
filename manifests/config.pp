class puppetdashboard::config inherits puppetdashboard::params {
  Exec {
    path      => "${::path}",
    logoutput => on_failure,
  }

  file { "puppetdashboard::config::puppetlabs_apt_repo_config":
    path    => "/etc/apt/sources.list.d/puppetlabs.list",
    content => template("puppetdashboard/apt_puppetlabs.list.erb"),
    owner   => "root",
    group   => "root",
    mode    => 0644,
    notify  => Exec["puppetdashboard::config::get_puppetlabs_apt_key"],
  }
  exec { "puppetdashboard::config::get_puppetlabs_apt_key":
    command     => "gpg --keyserver keys.gnupg.net --recv-key 4BD6EC30",
    user        => root,
    timeout     => 600,
    refreshonly => true,
    notify      => Exec["puppetdashboard::config::import_puppetlabs_apt_key"],
  }
  exec { "puppetdashboard::config::import_puppetlabs_apt_key":
    command     => "gpg -a --export 4BD6EC30 | apt-key add -",
    user        => root,
    timeout     => 600,
    refreshonly => true,
    require     => Exec["puppetdashboard::config::get_puppetlabs_apt_key"],
    notify      => Exec["puppetdashboard::config::update_apt"],
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
