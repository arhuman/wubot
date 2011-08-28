package Wubot::Plugin::OsxActiveApp;
use Moose;

# VERSION

use Wubot::Logger;

has 'logger'  => ( is => 'ro',
                   isa => 'Log::Log4perl::Logger',
                   lazy => 1,
                   default => sub {
                       return Log::Log4perl::get_logger( __PACKAGE__ );
                   },
               );


with 'Wubot::Plugin::Roles::Cache';
with 'Wubot::Plugin::Roles::Plugin';

my $command =<<EOF;

/usr/bin/python -c "
from AppKit import NSWorkspace
activeAppName = NSWorkspace.sharedWorkspace().activeApplication()['NSApplicationName']
print activeAppName
"

EOF

sub check {
    my ( $self, $inputs ) = @_;

    my $config = $inputs->{config};
    my $cache  = $inputs->{cache};

    my $output = `$command`;

    chomp $output;

    return { react => { application => $output } };
}
