package Wubot::Plugin::FileTail;
use Moose;

use Fcntl qw( SEEK_END SEEK_CUR SEEK_SET O_NONBLOCK O_RDONLY );
use Log::Log4perl;

has 'path'      => ( is      => 'rw',
                     isa     => 'Str',
                 );

has 'tail_fh'   => ( is      => 'rw',
                     lazy    => 1,
                     default => sub {
                         return $_[0]->get_fh( 1 );
                     },
                 );

has 'lastread'  => ( is      => 'rw',
                     isa     => 'Num',
                 );

has 'logger'    => ( is      => 'ro',
                     isa     => 'Log::Log4perl::Logger',
                     lazy    => 1,
                     default => sub {
                         return Log::Log4perl::get_logger( __PACKAGE__ );
                     },
                 );

has 'refresh'   => ( is      => 'ro',
                     isa     => 'Num',
                     default => sub {
                         # default behavior is to recheck if file was
                         # renamed or truncated every time we go to
                         # check and don't find any new lines.
                         return 1;
                     }
                 );

has 'count'     => ( is      => 'rw',
                     isa     => 'Num',
                     default => 0,
                 );

my %nonblockGetLines_last;

with 'Wubot::Plugin::Roles::Cache';
with 'Wubot::Plugin::Roles::Plugin';

sub check {
    my ( $self, $inputs ) = @_;

    $self->count( $self->count + 1 );

    my $config = $inputs->{config};

    my $path = $config->{path};
    $self->path( $path );

    unless ( -r $path ) {
        return { react => [ { subject => "path not readable: $path" } ] };
    }

    my $fh = $self->tail_fh;

    my $mtime = ( stat $path )[9];
    my ( $eof, @lines ) = nonblockGetLines( $fh );

    my @react = $self->get_react( @lines );

    my $refresh = $config->{refresh} || $self->refresh;

    if ( $self->count % $refresh == 0 ) {

        unless ( scalar @react ) {

            # no lines read, check if file was truncated/renamed
            my $cur_pos = sysseek( $fh, 0, SEEK_CUR);
            my $end_pos = sysseek( $fh, 0, SEEK_END);

            my $was_truncated = $end_pos < $cur_pos ? 1 : 0;
            my $was_renamed   = $self->lastread && $mtime > $self->lastread ? 1 : 0;

            if (  $was_truncated || $was_renamed ) {

                if    ( $was_truncated ) { push @react, { subject => "file was truncated: $path" } }
                elsif ( $was_renamed   ) { push @react, { subject => "file was renamed: $path"   } };

                $self->tail_fh( $self->get_fh( undef ) );
                $fh = $self->tail_fh;

                ( $eof, @lines ) = nonblockGetLines( $fh );

                push @react, $self->get_react( @lines );

            } else {
                # file was not truncated, seek back to same spot
                sysseek( $fh, $cur_pos, SEEK_SET);
            }
        }
    }

    if ( scalar @react ) {
        return { react => \@react };
    }

    return;
}

sub get_react {
    my ( $self, @lines ) = @_;

    my @react;
  LINE:
    for my $line ( @lines ) {
        chomp $line;
        next LINE unless $line;

        push @react, { subject => $line };
    }

    if ( scalar @react ) {
        # we got some data, update the 'lastread' time
        $self->lastread( time );
    }

    return @react;
}

sub get_fh {
    my ( $self, $seek_end ) = @_;

    my $path = $self->path;

    if ( $seek_end ) {
        $self->logger->debug( "opening path: $path" );
    }
    else {
        $self->logger->debug( "re-opening path: $path" );
    }

    sysopen( my $fh, $path, O_NONBLOCK|O_RDONLY )
        or die "can't open $path: $!";

    if ( $seek_end ) {
        sysseek( $fh, 0, SEEK_END );
    }

    return $fh;
}

# taken from: http://www.perlmonks.org/?node_id=55241
# An non-blocking filehandle read that returns an array of lines read
# Returns:  ($eof,@lines)
sub nonblockGetLines {
  my ( $fh ) = @_;

  my $timeout = 0;
  my $rfd = '';
  $nonblockGetLines_last{$fh} = ''
        unless defined $nonblockGetLines_last{$fh};

  vec($rfd,fileno($fh),1) = 1;
  return unless select($rfd, undef, undef, $timeout)>=0;
    # I'm not sure the following is necessary?
  return unless vec($rfd,fileno($fh),1);
  my $buf = '';
  my $n = sysread($fh,$buf,1024*1024);
  # If we're done, make sure to send the last unfinished line
  return (1,$nonblockGetLines_last{$fh}) unless $n;
    # Prepend the last unfinished line
  $buf = $nonblockGetLines_last{$fh}.$buf;
    # And save any newly unfinished lines
  $nonblockGetLines_last{$fh} =
        (substr($buf,-1) !~ /[\r\n]/ && $buf =~ s/([^\r\n]*)$//)
            ? $1 : '';
  $buf ? (0,split(/\n/,$buf)) : (0);
}

1;
