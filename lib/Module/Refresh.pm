use warnings;
use strict;

package Module::Refresh;

our $VERSION = '0.01';

our %CACHE;

=head1 DESCRIPTION

This module is a generalization of the functionality provided by Apache::StatINC. It's designed to make it easy to do simple iterative development when working in a persistent environment.  To that end

=head1 EXAMPLE


my $refresher = Inc::Refresh->new();

$refresher->refresh_updated();

# each night at midnight, you automatically download the latest
# Acme::Current from CPAN. Use this snippet to make your running
# program pick it up off disk:

$refresher->refresh_module('Apache::Current');

=cut

=head2 new

Initialize the module refresher;

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = {};
    bless $self, $class;

    $self->_initialize_cache();
    return ($self);
}

=head2 _initialize_cache

When we start up, set the mtime of each module to I<now>, so we don't go about refreshing
   and refreshing everything.

=cut

sub _initialize_cache {
    my $self = shift;
    my $time = time();

    $CACHE{$_} = $time for ( keys %INC );

    return ($self);
}

=head2 refresh_updated

refresh all modules that have mtimes on disk newer than the newest ones we've got.

=cut

sub refresh_updated {
    my $self = shift;
    while ( my ( $mod, $path ) = each %INC ) {
        if ( !$CACHE{$mod} || $self->mtime($path) > $CACHE{$mod} ) {
            $self->refresh_module($mod);
        }
    }
    return ($self);
}

=head2 refresh_module $mod

refresh module $mod. It doesn't matter if it's already up to date. Just do it.

=cut

sub refresh_module {
    my $self = shift;
    my $mod  = shift;

    $self->unload_module($mod);

        eval { 
            require $mod 
         };
        warn $@ if ($@);
    $self->cache_mtime( $mod => $self->mtime( $INC{$mod} ) );

    return ($self);
}

sub unload_module {
    my $self = shift;
    my $mod  = shift;
    delete $INC{$mod};
    $self->cache_mtime( $mod => 0 );

}

sub cache_mtime {
    my $self  = shift;
    my $mod   = shift;
    my $mtime = shift;

    $CACHE{$mod} = $mtime;

    return ($self);
}

=head2 mtime $file

Get the last modified time of $file in seconds since the epoch;

=cut

sub mtime {
    my $self     = shift;
    my $filename = shift;
    return ( stat($filename) )[9];
}

=head1 BUGS

The module warns for each reloaded subroutine.  We _could_ 
(and probably _should_) walk the symbol table and whack 
the old versions of the symbols


=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>

8 November, 2004, Hua Lien, Taiwan


=head1 SEE ALSO

L<Module::Refresh>, which does much the same thing, with a little less efficiency 
up front. (And doesn't have the API for manual expiry.

=cut

1;
