#!/perl
use strict;

use File::Temp qw/ tempdir /;
use Log::Log4perl qw(:easy);
use Test::More 'no_plan';
use Test::Differences;
use YAML;

Log::Log4perl->easy_init($ERROR);
my $logger = get_logger( 'default' );

use Wubot::Plugin::Ping;

my $tempdir = tempdir( "/tmp/tmpdir-XXXXXXXXXX", CLEANUP => 1 );


{
    ok( my $check = Wubot::Plugin::Ping->new( { class      => 'Wubot::Plugin::OsxIdle',
                                                   cache_file => '/dev/null',
                                                   key        => 'OsxIdle-testcase',
                                               } ),
        "Creating a new Ping check instance"
    );

    my $config = { host => 'localhost',
                   num_packets => 2,
               };

    ok( my $results = $check->check( { config => $config } ),
        "Calling check() method"
    );

    is( $results->{react}->{count},
        2,
        "Checking that 2 packets sent"
    );

    is( $results->{react}->{host},
        "localhost",
        "Checking that pings sent to localhost"
    );

    print YAML::Dump $results;
}
