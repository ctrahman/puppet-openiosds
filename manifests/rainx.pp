define openiosds::rainx (
  $action    = 'create',
  $type      = 'rainx',
  $num       = '0',
  $ns        = undef,
  $ipaddress = $::ipaddress,
  $port      = '6009',
) {

  if ! defined(Class['openiosds']) {
    include openiosds
  }

  # Validation
  $actions = ['create','remove']
  validate_re($action,$actions,"${action} is invalid.")
  validate_string($type)
  if type($num) != 'integer' { fail("${num} is not an integer.") }

  if ! has_interface_with('ipaddress',$ipaddress) { fail("${ipaddress} is invalid.") }
  if type($port) != 'integer' { fail("${port} is not an integer.") }


  # Namespace
  if $action == 'create' {
    if ! defined(Openiosds::Namespace[$ns]) {
      fail('You must include the namespace class before using OpenIO defined types.')
    }
  }

  # Packages
  package { 'openio-sds-mod-httpd':
    ensure => installed,
  } ->
  # Service
  openiosds::service {"${ns}-${type}-${num}":
    action => $action,
    type   => $type,
    num    => $num,
    ns     => $ns,
  } ->
  # Configuration files
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-httpd.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}-httpd.conf.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.conf":
    ensure  => $openiosds::file_ensure,
    content => template("openiosds/${type}-monitor.conf.erb"),
    owner   => $openiosds::user,
    group   => $openiosds::group,
  } ->
  file { "${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.log4crc":
    ensure  => $openiosds::file_ensure,
    content => template('openiosds/log4crc.erb'),
    owner   => $openiosds::user,
    group   => $openiosds::group,
  } ->
  # Init
  gridinit::program { "${ns}-${type}-${num}":
    action  => $action,
    command => "${openiosds::bindir}/${type}-monitor.py ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.conf ${openiosds::sysconfdir}/${ns}/${type}-${num}/${type}-${num}-monitor.log4crc",
    group   => "${ns},${type},${type}-${num}",
    uid     => $openiosds::user,
    gid     => $openiosds::group,
  }

}
