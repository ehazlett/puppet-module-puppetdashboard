class puppetdashboard::config inherits puppetdashboard::params {
  Exec {
    path      => "${::path}",
    logoutput => on_failure,
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
