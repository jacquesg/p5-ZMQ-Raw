package inc::MakeMaker;

use Moose;
use Config;

extends 'Dist::Zilla::Plugin::MakeMaker::Awesome';

override _build_MakeFile_PL_template => sub {
	my ($self) = @_;

	my $template = <<'TEMPLATE';
use strict;
use warnings;
use Config;

# compiler detection
my $is_gcc = length($Config{gccversion});
my $is_msvc = $Config{cc} eq 'cl' ? 1 : 0;
my $legacy_gcc = index ($Config{gccversion}, '4.2.1') != -1 ? 1 : 0;

# os detection
my $is_solaris = ($^O =~ /(sun|solaris)/i) ? 1 : 0;
my $is_windows = ($^O =~ /MSWin32/i) ? 1 : 0;
my $is_linux = ($^O =~ /linux/i) ? 1 : 0;
my $is_osx = ($^O =~ /darwin/i) ? 1 : 0;
my $is_bsd = ($^O =~ /bsd/i) ? 1 : 0;
my $is_openbsd = ($^O =~ /openbsd/i) ? 1 : 0;
my $is_gkfreebsd = ($^O =~ /gnukfreebsd/i) ? 1 : 0;

my $def = '-DZMQ_CUSTOM_PLATFORM_HPP -DZMQ_STATIC -DZMQ_BUILD_DRAFT_API -D_THREAD_SAFE';

my $lib = '';
my $otherldflags = '';
my $inc = '';
my $ccflags = '';
my $ld = $Config{ld};

if ($is_gcc)
{
	if ($ld eq 'cc')
	{
		$ld = 'c++';
	}
	elsif ($ld eq 'clang')
	{
		$ld = 'clang++';
	}
	elsif ($ld =~ /gcc/)
	{
		$ld =~ s/gcc/g++/;
	}

	if (!$is_windows)
	{
		$ccflags .= ' -pthread';
	}
	$lib .= ' -lpthread';

	if ($is_linux || $is_solaris)
	{
		$lib .= ' -lrt';
	}
}

if ($is_windows)
{
	$def .= ' -D_WINSOCK_DEPRECATED_NO_WARNINGS -D_CRT_SECURE_NO_WARNINGS -DFD_SETSIZE=16384';
	$def .= ' -D_WIN32_WINNT=0x0600';

	$lib .= ' -lws2_32 -lrpcrt4 -liphlpapi msvcprt.lib';

	if ($is_msvc)
	{
		$ccflags .= ' -EHsc';
	}
}

# generate the platform.hpp file
my @opts = (
	'ZMQ_HAVE_SO_KEEPALIVE',
	'ZMQ_HAVE_CURVE',
	'ZMQ_USE_TWEETNACL',
	'ZMQ_POLL_BASED_ON_POLL',
);

if ($is_osx || $is_bsd)
{
	push @opts,
		'ZMQ_USE_CV_IMPL_PTHREADS',
		'ZMQ_IOTHREAD_POLLER_USE_KQUEUE',
		'ZMQ_USE_KQUEUE';
}
elsif ($is_linux)
{
	push @opts,
		'ZMQ_USE_CV_IMPL_PTHREADS',
		'ZMQ_IOTHREAD_POLLER_USE_EPOLL',
		'ZMQ_IOTHREAD_POLLER_USE_EPOLL_CLOEXEC',
		'ZMQ_USE_EPOLL',
		'ZMQ_USE_EPOLL_CLOEXEC',
		'ZMQ_HAVE_EVENTFD',
		'ZMQ_HAVE_EVENTFD_CLOEXEC',
		'ZMQ_HAVE_SOCK_CLOEXEC';
}
elsif ($is_solaris)
{
	push @opts,
		'ZMQ_USE_CV_IMPL_PTHREADS',
		'ZMQ_IOTHREAD_POLLER_USE_DEVPOLL',
		'ZMQ_USE_DEVPOLL';
}
elsif ($is_windows)
{
	push @opts,
		'ZMQ_IOTHREAD_POLLER_USE_EPOLL',
		'ZMQ_USE_EPOLL',
		'ZMQ_USE_CV_IMPL_WIN32API';
}
else
{
	push @opts,
		'ZMQ_USE_CV_IMPL_STL11',
		'ZMQ_IOTHREAD_POLLER_USE_POLL',
		'ZMQ_USE_POLL 1';
}


if ($is_linux || $is_osx)
{
	push @opts,
		'ZMQ_HAVE_STRLCPY',
		'ZMQ_HAVE_TCP_KEEPCNT',
		'ZMQ_HAVE_TCP_KEEPINTVL',
		'ZMQ_HAVE_TCP_KEEPALIVE';
}

if ($is_linux)
{
	push @opts,
		'ZMQ_HAVE_TCP_KEEPIDLE',
}

if (!$is_windows)
{
	push @opts,
		'HAVE_FORK',
		'HAVE_MKDTEMP',
		'ZMQ_HAVE_IPC',
		'ZMQ_HAVE_UIO',
		'ZMQ_HAVE_IFADDRS';
}
else
{
	push @opts,
		'ZMQ_HAVE_WINDOWS';
}

if (!$is_solaris || (int ((split ('.', $Config{osvers}))[1]) > 10))
{
	# Solaris 10 doesn't have strnlen
	push @opts,
		'HAVE_STRNLEN';
}

if ($is_solaris)
{
	push @opts,
		'HAVE_GETHRTIME';
}
elsif (!$is_windows)
{
	push @opts,
		'HAVE_CLOCK_GETTIME';
}

open my $fh, '>', 'platform.hpp' or
	die "Could not open 'platform.hpp': $!";
print $fh q{
#ifndef __ZMQ_PLATFORM_HPP_INCLUDED__
#define __ZMQ_PLATFORM_HPP_INCLUDED__

};

foreach my $opt (@opts)
{
	print $fh "#define $opt\n";
}

print $fh q{

#if defined ANDROID
  #define ZMQ_HAVE_ANDROID
#endif

#if defined __CYGWIN__
  #define ZMQ_HAVE_CYGWIN
#endif

#if defined __MINGW32__
  #define ZMQ_HAVE_MINGW32
#endif

#if defined(__FreeBSD__) || defined(__DragonFly__) || defined(__FreeBSD_kernel__)
  #define ZMQ_HAVE_FREEBSD
#endif

#if defined __hpux
  #define ZMQ_HAVE_HPUX
#endif

#if defined __linux__
  #define ZMQ_HAVE_LINUX
#endif

#if defined __NetBSD__
  #define ZMQ_HAVE_NETBSD
#endif

#if defined __OpenBSD__
  #define ZMQ_HAVE_OPENBSD
#endif

#if defined __APPLE__
  #define ZMQ_HAVE_OSX
#endif

#if defined(sun) || defined(__sun)
  #define ZMQ_HAVE_SOLARIS
#endif

#endif
};

close $fh;

my @cc_srcs = (glob ('deps/libzmqraw/*.cc'));
my @cc_objs = map { substr ($_, 0, -2) . 'o' } (@cc_srcs);

my @cpp_srcs = grep { $_ !~ /(ws_|wss_)/ } (glob ('deps/libzmq/src/*.cpp'));
my @cpp_objs = map { substr ($_, 0, -3) . 'o' } (@cpp_srcs);

my @c_srcs = (glob ('deps/libzmq/src/*.c'), glob ('deps/libzmqraw/*.c'), glob ('deps/libzmq/external/sha1/*.c'));
if ($is_windows)
{
	push @c_srcs, glob ('deps/libzmq/external/wepoll/*.c');
}

my @c_objs = map { substr ($_, 0, -1) . 'o' } (@c_srcs);

sub MY::c_o {
	my $out_switch = '-o ';

	if ($is_msvc) {
		$out_switch = '/Fo';
	}

	my $std_switch = '';
	if ($is_gcc && !$legacy_gcc) {
		$std_switch = '-std=c++0x'
	}

	my $line = qq{
.c\$(OBJ_EXT):
	\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.c $out_switch\$@

.cc\$(OBJ_EXT):
	\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.cc $std_switch $out_switch\$@

.cpp\$(OBJ_EXT):
	\$(CCCMD) \$(CCCDLFLAGS) "-I\$(PERL_INC)" \$(PASTHRU_DEFINE) \$(DEFINE) \$*.cpp $std_switch $out_switch\$@
};

	if ($is_gcc) {
		# disable parallel builds
		$line .= qq{

.NOTPARALLEL:
};
	}
	return $line;
}

# This Makefile.PL for {{ $distname }} was generated by Dist::Zilla.
# Don't edit it but the dist.ini used to construct it.
{{ $perl_prereq ? qq[BEGIN { require $perl_prereq; }] : ''; }}
use strict;
use warnings;
use ExtUtils::MakeMaker {{ $eumm_version }};
use ExtUtils::Constant qw (WriteConstants);

{{ $share_dir_block[0] }}
my {{ $WriteMakefileArgs }}

$WriteMakefileArgs{DEFINE}  .= $def;
$WriteMakefileArgs{LIBS}    .= $lib;
$WriteMakefileArgs{INC}     .= $inc;
$WriteMakefileArgs{LD}      .= $ld;
$WriteMakefileArgs{CCFLAGS} .= $Config{ccflags} . ' '. $ccflags;
$WriteMakefileArgs{OBJECT}  .= ' ' . join ' ', (@cpp_objs, @cc_objs, @c_objs);
$WriteMakefileArgs{dynamic_lib} = {
	OTHERLDFLAGS => $otherldflags
};

my @constants = (qw(
	ZMQ_PAIR
	ZMQ_PUB
	ZMQ_SUB
	ZMQ_REQ
	ZMQ_REP
	ZMQ_DEALER
	ZMQ_ROUTER
	ZMQ_PULL
	ZMQ_PUSH
	ZMQ_XPUB
	ZMQ_XSUB
	ZMQ_STREAM
	ZMQ_SERVER
	ZMQ_CLIENT
	ZMQ_RADIO
	ZMQ_DISH
	ZMQ_GATHER
	ZMQ_SCATTER
	ZMQ_DGRAM

	ZMQ_DONTWAIT
	ZMQ_SNDMORE

	ZMQ_POLLIN
	ZMQ_POLLOUT
	ZMQ_POLLERR
	ZMQ_POLLPRI

	ZMQ_IO_THREADS
	ZMQ_MAX_SOCKETS
	ZMQ_SOCKET_LIMIT
	ZMQ_THREAD_PRIORITY
	ZMQ_THREAD_SCHED_POLICY
	ZMQ_MAX_MSGSZ
	ZMQ_MSG_T_SIZE
	ZMQ_THREAD_AFFINITY
	ZMQ_THREAD_NAME_PREFIX

	ZMQ_EVENT_CONNECTED
	ZMQ_EVENT_CONNECT_DELAYED
	ZMQ_EVENT_CONNECT_RETRIED
	ZMQ_EVENT_LISTENING
	ZMQ_EVENT_BIND_FAILED
	ZMQ_EVENT_ACCEPTED
	ZMQ_EVENT_ACCEPT_FAILED
	ZMQ_EVENT_CLOSED
	ZMQ_EVENT_CLOSE_FAILED
	ZMQ_EVENT_DISCONNECTED
	ZMQ_EVENT_MONITOR_STOPPED
	ZMQ_EVENT_ALL

	ZMQ_EVENT_HANDSHAKE_FAILED_NO_DETAIL
	ZMQ_EVENT_HANDSHAKE_SUCCEEDED
	ZMQ_EVENT_HANDSHAKE_FAILED_PROTOCOL
	ZMQ_EVENT_HANDSHAKE_FAILED_AUTH

	ZMQ_NOTIFY_CONNECT
	ZMQ_NOTIFY_DISCONNECT

	FEATURE_IPC
	FEATURE_PGM
	FEATURE_TIPC
	FEATURE_NORM
	FEATURE_CURVE
	FEATURE_GSSAPI
	FEATURE_DRAFT
));

my @errors = (qw(
	ENOTSUP
	EPROTONOSUPPORT
	ENOBUFS
	ENETDOWN
	EADDRINUSE
	EADDRNOTAVAIL
	ECONNREFUSED
	EINPROGRESS
	ENOTSOCK
	EMSGSIZE
	EAFNOSUPPORT
	ENETUNREACH
	ECONNABORTED
	ECONNRESET
	ENOTCONN
	ETIMEDOUT
	EHOSTUNREACH
	ENETRESET
	EFSM
	ENOCOMPATPROTO
	ETERM
	EMTHREAD
));

my @socket_options = (qw(
	ZMQ_AFFINITY
	ZMQ_IDENTITY
	ZMQ_ROUTING_ID
	ZMQ_SUBSCRIBE
	ZMQ_UNSUBSCRIBE
	ZMQ_RATE
	ZMQ_RECOVERY_IVL
	ZMQ_SNDBUF
	ZMQ_RCVBUF
	ZMQ_RCVMORE
	ZMQ_FD
	ZMQ_EVENTS
	ZMQ_TYPE
	ZMQ_LINGER
	ZMQ_RECONNECT_IVL
	ZMQ_BACKLOG
	ZMQ_RECONNECT_IVL_MAX
	ZMQ_MAXMSGSIZE
	ZMQ_SNDHWM
	ZMQ_RCVHWM
	ZMQ_MULTICAST_HOPS
	ZMQ_RCVTIMEO
	ZMQ_SNDTIMEO
	ZMQ_LAST_ENDPOINT
	ZMQ_ROUTER_MANDATORY
	ZMQ_TCP_KEEPALIVE
	ZMQ_TCP_KEEPALIVE_CNT
	ZMQ_TCP_KEEPALIVE_IDLE
	ZMQ_TCP_KEEPALIVE_INTVL
	ZMQ_IMMEDIATE
	ZMQ_XPUB_VERBOSE
	ZMQ_ROUTER_RAW
	ZMQ_IPV6
	ZMQ_MECHANISM
	ZMQ_PLAIN_SERVER
	ZMQ_PLAIN_USERNAME
	ZMQ_PLAIN_PASSWORD
	ZMQ_CURVE_SERVER
	ZMQ_CURVE_PUBLICKEY
	ZMQ_CURVE_SECRETKEY
	ZMQ_CURVE_SERVERKEY
	ZMQ_PROBE_ROUTER
	ZMQ_REQ_CORRELATE
	ZMQ_REQ_RELAXED
	ZMQ_CONFLATE
	ZMQ_ZAP_DOMAIN
	ZMQ_ROUTER_HANDOVER
	ZMQ_ROUTER_NOTIFY
	ZMQ_TOS
	ZMQ_CONNECT_RID
	ZMQ_GSSAPI_SERVER
	ZMQ_GSSAPI_PRINCIPAL
	ZMQ_GSSAPI_SERVICE_PRINCIPAL
	ZMQ_GSSAPI_PLAINTEXT
	ZMQ_HANDSHAKE_IVL
	ZMQ_SOCKS_PROXY
	ZMQ_XPUB_NODROP
	ZMQ_BLOCKY
	ZMQ_XPUB_MANUAL
	ZMQ_XPUB_WELCOME_MSG
	ZMQ_STREAM_NOTIFY
	ZMQ_INVERT_MATCHING
	ZMQ_HEARTBEAT_IVL
	ZMQ_HEARTBEAT_TTL
	ZMQ_HEARTBEAT_TIMEOUT
	ZMQ_XPUB_VERBOSER
	ZMQ_CONNECT_TIMEOUT
	ZMQ_TCP_MAXRT
	ZMQ_THREAD_SAFE
	ZMQ_MULTICAST_MAXTPDU
	ZMQ_VMCI_BUFFER_SIZE
	ZMQ_VMCI_BUFFER_MIN_SIZE
	ZMQ_VMCI_BUFFER_MAX_SIZE
	ZMQ_VMCI_CONNECT_TIMEOUT
	ZMQ_USE_FD
));

my @message_options = (qw(
	ZMQ_MORE
	ZMQ_SHARED
));

my @message_properties = (qw(
	ZMQ_MSG_PROPERTY_ROUTING_ID
	ZMQ_MSG_PROPERTY_SOCKET_TYPE
	ZMQ_MSG_PROPERTY_USER_ID
	ZMQ_MSG_PROPERTY_PEER_ADDRESS
));


ExtUtils::Constant::WriteConstants
(
	NAME         => 'ZMQ::Raw',
	NAMES        => [@constants],
	DEFAULT_TYPE => 'IV',
	C_FILE       => 'const-c-constant.inc',
	XS_FILE      => 'const-xs-constant.inc',
	XS_SUBNAME   => '_constant',
	C_SUBNAME    => '_c_constant',
);

ExtUtils::Constant::WriteConstants
(
	NAME         => 'ZMQ::Raw::Error',
	NAMES        => [@errors],
	DEFAULT_TYPE => 'IV',
	C_FILE       => 'const-c-error.inc',
	XS_FILE      => 'const-xs-error.inc',
	XS_SUBNAME   => '_constant',
	C_SUBNAME    => '_error_constant',
);

ExtUtils::Constant::WriteConstants
(
	NAME         => 'ZMQ::Raw::Socket',
	NAMES        => [@socket_options],
	DEFAULT_TYPE => 'IV',
	C_FILE       => 'const-c-socket_options.inc',
	XS_FILE      => 'const-xs-socket_options.inc',
	XS_SUBNAME   => '_constant',
	C_SUBNAME    => '_socket_option',
);

ExtUtils::Constant::WriteConstants
(
	NAME         => 'ZMQ::Raw::Message',
	NAMES        => [@message_options],
	DEFAULT_TYPE => 'IV',
	C_FILE       => 'const-c-message_options.inc',
	XS_FILE      => 'const-xs-message_options.inc',
	XS_SUBNAME   => '_o_constant',
	C_SUBNAME    => '_message_option',
);

ExtUtils::Constant::WriteConstants
(
	NAME         => 'ZMQ::Raw::Message',
	NAMES        => [@message_properties],
	DEFAULT_TYPE => 'PV',
	C_FILE       => 'const-c-message_properties.inc',
	XS_FILE      => 'const-xs-message_properties.inc',
	XS_SUBNAME   => '_p_constant',
	C_SUBNAME    => '_message_property',
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.56) }) {
	my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
	my $pp = $WriteMakefileArgs{PREREQ_PM};

	for my $mod (keys %$br) {
		if (exists $pp -> {$mod}) {
			$pp -> {$mod} = $br -> {$mod}
				if $br -> {$mod} > $pp -> {$mod};
		} else {
			$pp -> {$mod} = $br -> {$mod};
		}
	}
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker -> VERSION(6.52) };

WriteMakefile (%WriteMakefileArgs);
exit (0);

{{ $share_dir_block[1] }}
TEMPLATE

	return $template;
};

override _build_WriteMakefile_args => sub {
	return +{
		%{ super() },
		INC	    => '-I. -Ideps -Ideps/libzmq/include',
		OBJECT	=> '$(O_FILES)',
	}
};

__PACKAGE__ -> meta -> make_immutable;

