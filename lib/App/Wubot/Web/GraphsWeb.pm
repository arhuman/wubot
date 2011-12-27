package App::Wubot::Web::GraphsWeb;
use strict;
use warnings;

# VERSION

use Mojo::Base 'Mojolicious::Controller';

use YAML::XS;

my $config_file = join( "/", $ENV{HOME}, "wubot", "config", "webui.yaml" );

my $graphs = YAML::XS::LoadFile( $config_file )->{graphs};

sub graphs {
    my $self = shift;

    my $search_key = $self->param( 'key' ) || "sensors";

    my @nav;
    my @png;
    for my $graph ( @{ $graphs } ) {
        my ( $key ) = keys %{ $graph };
        push @nav, $key;

        if ( $search_key && $search_key eq $key ) {
            for my $png ( @{ $graph->{$key} } ) {
                push @png, $png;
            }
        }
    }

    $self->stash( 'nav', \@nav );
    $self->stash( 'images', \@png );

    $self->render( template => 'graphs' );

};

1;

__END__

=head1 NAME

App::Wubot::Web::GraphsWeb - web interface for wubot graphs

=head1 CONFIGURATION

    ~/wubot/config/webui.yaml

    ---
    plugins:
      graphs:
        '/graphs': graphs

    graphs:
      - sensors:
          - http://wubot/wubot/graphs/Coopduino.now.png
          - http://wubot/wubot/graphs/Coopduino.png
          - http://wubot/wubot/graphs/Coopduino-week.png
          - http://wubot/wubot/graphs/Growbot.png
      - sensor-monthly:
          - http://wubot/wubot/graphs/outside-temp/outside-temp-monthly.png
          - http://wubot/wubot/graphs/lab-temp/lab-temp-monthly.png
          - http://wubot/wubot/graphs/coop-temp/coop-temp-monthly.png
          - http://wubot/wubot/graphs/growbot-temp/growbot-temp-monthly.png
          - http://wubot/wubot/graphs/growbot-moisture/growbot-moisture-monthly.png
          - http://wubot/wubot/graphs/growbot-humidity/growbot-humidity-monthly.png
      - external:
          - http://wubot/wubot/graphs/WebFetch-qwest/WebFetch-qwest-daily.png
          - http://wubot/wubot/graphs/Ping-google/Ping-google-daily.png
          - http://wubot/wubot/graphs/Ping.png
          - http://wubot/wubot/graphs/Ping-router/Ping-router-daily.png



=head1 DESCRIPTION

This plugin allows you to display graphs generated by the wubot
reactor in the web interface.

The wubot web interface is still under construction.  There will be
more information here in the future.

TODO: finish docs

=head1 SUBROUTINES/METHODS

=over 8

=item graphs

Reads the graphs from the wubot web interface config file.  See the
example above.

For each key in the 'graphs' config, a link will be generated at the
top of the page on the navigation bar.

Clicking on one of the keys will display a page with all the links for
that page displayed in image tags.

=cut