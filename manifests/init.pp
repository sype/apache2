class apache2($modules = "php geoip") {

    $ensure	= "running"
    $pkg_name   = "apache2"
    $svc_name   = "apache2"

    package { $pkg_name:
      name	=> $pkg_name,
      ensure	=> "installed",
    }

    $subscribes = [ Package[$pkg_name] ]
    if 'php' in $modules {
      package { "libapache2-mod-php5": ensure => "installed" }
      concat($subscribes, Package["libapache2-mod-php5"])
    }
    if 'geoip' in $modules {
      package { "libapache2-mod-geoip": ensure => "installed" }
      concat($subscribes, Package["libapache2-mod-geoip"])
    }

    file {
      "/var/www/favicon.ico":
        mode => "0644", owner => 0, group => 0,
        source => "puppet:///modules/apache2/favicon.ico";
      "/etc/apache2/mods-available/alias.conf":
        mode => "0644", owner => 0, group => 0,
        source => "puppet:///modules/apache2/alias.conf",
        require => Package[$pkg_name],
        notify => Service[$svc_name];
      "/etc/apache2/mods-available/status.conf":
        mode => "0644", owner => 0, group => 0,
        source => "puppet:///modules/apache2/status.conf",
        require => Package[$pkg_name],
        notify => Service[$svc_name];
    }

    service { $svc_name:
      name       => $svc_name,
      ensure     => $ensure,
      enable	 => true,
      hasstatus  => true,
      hasrestart => true,
      require   => [ Package[$pkg_name] ],
      subscribe  => $subscribes,

    }
###############################################
define site( $sitedomain = "", $documentroot = "" ) {
include apache2
if $sitedomain == "" {
$vhost_domain = $name
} else {
$vhost_domain = $sitedomain
}
if $documentroot == "" {
$vhost_root = "/var/www/${name}"
} else {
$vhost_root = $documentroot
}
file { $vhost_root : ensure => "directory",
                     }
file { "/var/log/apache2/${name}-error_log":
        mode => "0644", owner => 33, group => 0,
        ensure => "present",
}

file { "/var/log/apache2/${name}-access_log":
        mode => "0644", owner => 33, group => 0,
        ensure => "present",
}
file { "/etc/apache2/sites-available/${vhost_domain}.conf":
content => template("apache2/vhost.erb"),
#require => File["/etc/apache2/conf.d/name-based-vhosts.conf" ],
notify => Exec["enable-${vhost_domain}-vhost"],
}
exec { "enable-${vhost_domain}-vhost":
command => "/usr/sbin/a2ensite ${vhost_domain}.conf",
require => [ File["/etc/apache2/sites-available/${vhost_domain}.conf"] ],
refreshonly => true,
notify => Service["apache2"],}
}

###############################################
}

