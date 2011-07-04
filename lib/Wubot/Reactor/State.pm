package Wubot::Reactor::State;
use Moose;

# VERSION

use YAML;

has 'cache'   => ( is => 'ro',
                   isa => 'HashRef',
                   default => sub {
                       return {};
                   },
               );

has 'logger'  => ( is => 'ro',
                   isa => 'Log::Log4perl::Logger',
                   lazy => 1,
                   default => sub {
                       return Log::Log4perl::get_logger( __PACKAGE__ );
                   },
               );

sub react {
    my ( $self, $message, $config ) = @_;

    my $key        = $message->{key};
    my $field      = $config->{field};
    my $field_data = $message->{ $field } || 0;

    my $cache_data;
    if ( exists $self->cache->{ $key }->{ $field } ) {
        $cache_data = $self->cache->{ $key }->{ $field } || 0;
    }
    else {
        $cache_data = 0;
        $message->{state_init} = 1;
    }

    my $update_cache = 0;

    unless ( $field_data == $cache_data ) {

        $message->{state_change} = $field_data - $cache_data;

        if ( $config->{increase} ) {
            if ( $message->{state_change} >= $config->{increase} ) {
                $message->{subject} = "$key: $field increased: $cache_data => $field_data";
                $message->{state_changed} = 1;
                $update_cache = 1;
            }
            elsif ( $message->{state_change} < 0 ) {
                # if we're looking for an increase, and the data
                # actually decreased, update the cache with the higher
                # value
                $update_cache = 1;
            }
        }
        elsif ( $config->{decrease} ) {
            if ( $message->{state_change} <= -$config->{decrease} ) {
                $message->{subject} = "$key: $field decreased: $cache_data => $field_data";
                $message->{state_changed} = 1;
                $update_cache = 1;
            }
            elsif ( $message->{state_change} > 0 ) {
                # if we're looking for a decrease, and the data
                # actually increased, update the cache with the higher
                # value
                $update_cache = 1;
            }
        }
        else {
            $message->{subject} = "$key: $field changed: $cache_data => $field_data";
            $message->{state_changed} = 1;
            $update_cache = 1;
        }
    }

    if ( $update_cache ) {
        $self->cache->{ $key }->{ $field } = $field_data;
    }

    return $message;
}

1;