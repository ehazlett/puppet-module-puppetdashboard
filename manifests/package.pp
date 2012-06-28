class puppetdashboard::package {
  require "puppetdashboard::config"

  Exec { 
    path      => "${::path}", 
    logoutput => on_failure,
  }

  if ! defined(Package["build-essential"]) { package { "build-essential": ensure => installed, } }
  if ! defined(Package["libmysql-ruby"]) { package { "libmysql-ruby": ensure => installed, } }
  if ! defined(Package["libmysqlclient-dev"]) { package { "libmysqlclient-dev": ensure => installed, } }
  if ! defined(Package["libopenssl-ruby"]) { package { "libopenssl-ruby": ensure => installed, } }
  if ! defined(Package["libreadline-ruby"]) { package { "libreadline-ruby": ensure => installed, } }
  if ! defined(Package["mysql-server"]) { package { "mysql-server": ensure => installed, } }
  if ! defined(Package["rake"]) { package { "rake": ensure => installed, } }
  if ! defined(Package["rdoc"]) { package { "rdoc": ensure => installed, } }
  if ! defined(Package["ri"]) { package { "ri": ensure => installed, } }
  if ! defined(Package["ruby"]) { package { "ruby": ensure => installed, } }
  if ! defined(Package["ruby-dev"]) { package { "ruby-dev": ensure => installed, } }

  exec { "puppetdashboard::package::wget_rubygems":
    cwd       => "/tmp",
    command   => "wget ${puppetdashboard::params::rubygems_url} -O rubygems.tar.gz",
    creates   => "/usr/bin/gem1.8",
    notify    => Exec["puppetdashboard::package::install_rubygems"],
    require   => [ Package["build-essential"], Package["libmysql-ruby"], Package["libmysqlclient-dev"], 
      Package["libopenssl-ruby"], Package["rake"], Package["rdoc"], Package["ri"], Package["ruby"], Package["ruby-dev"] ]
  }
  exec { "puppetdashboard::package::install_rubygems":
    cwd         => "/tmp",
    command     => "tar zxf rubygems.tar.gz ; cd rubygems* ; ruby setup.rb ; cd /tmp ; rm -rf rubygems*",
    refreshonly => true,
    require     => Exec["puppetdashboard::package::wget_rubygems"],
    notify      => Exec["puppetdashboard::package::update_alternatives"],
  }
  exec { "puppetdashboard::package::update_alternatives":
    command     => "update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.8 1",
    refreshonly => true,
    require     => Exec["puppetdashboard::package::install_rubygems"],
  }
  package { "puppet-dashboard":
    ensure    => installed,
    require   => File["puppetdashboard::config::puppetlabs_apt_repo_config"],
  }
  # mysql config
  exec { "puppetdashboard::package::create_db":
    command     => "echo 'CREATE DATABASE ${puppetdashboard::params::dashboard_db_name} CHARACTER SET utf8;' | mysql -u root",
    require     => [ Package["mysql-server"], Package["puppet-dashboard"] ],
    notify      => Exec["puppetdashboard::package::create_db_user"],
    unless      => "echo 'show databases;' | mysql -u root | grep ${puppetdashboard::params::dashboard_db_name}",
  }
  exec {"puppetdashboard::package::create_db_user":
    command     => "echo \"CREATE USER '${puppetdashboard::params::dashboard_db_username}'@'localhost' IDENTIFIED BY '${puppetdashboard::params::dashboard_db_password}';\" | mysql -u root",
    require     => Exec["puppetdashboard::package::create_db"],
    notify      => Exec["puppetdashboard::package::grant_db_privs"],
    refreshonly => true,
  }
  exec {"puppetdashboard::package::grant_db_privs":
    command     => "echo 'GRANT ALL PRIVILEGES ON ${puppetdashboard::params::dashboard_db_name}.* TO \'${puppetdashboard::params::dashboard_db_username}\'@\'localhost\';' | mysql -u root",
    require     => Exec["puppetdashboard::package::create_db"],
    refreshonly => true,
    notify      => Exec["puppetdashboard::package::dashboard_configure"],
  }
  file { "puppetdashboard::package::dashboard_database_config":
    path    => "/etc/puppet-dashboard/database.yml",
    content => template("puppetdashboard/database.yml.erb"),
    owner   => "root",
    group   => "www-data",
    mode    => 0640,
    require => Package["puppet-dashboard"],
    notify  => Exec["puppetdashboard::package::dashboard_configure"],
  }
  exec { "puppetdashboard::package::dashboard_configure":
    cwd         => "/usr/share/puppet-dashboard/",
    command     => "rake RAILS_ENV=production db:migrate",
    require     => File["puppetdashboard::package::dashboard_database_config"],
    refreshonly => true,
  }
}
