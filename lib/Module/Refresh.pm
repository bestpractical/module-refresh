package Module::Refresh;

use strict;
use vars qw( $VERSION %CACHE );

$VERSION = 0.01;

# Turn on the debugger's symbol source tracing
BEGIN {$^P |= 0x10};

=head1 SYNOPSIS

    my $refresher = Module::Refresh->new();

    $refresher->refresh_updated();

    # each night at midnight, you automatically download the latest
    # Acme::Current from CPAN. Use this snippet to make your running
    # program pick it up off disk:

    $refresher->refresh_module('Apache::Current');

=head1 DESCRIPTION

This module is a generalization of the functionality provided by Apache::StatINC. It's designed to make it easy to do simple iterative development when working in a persistent environment.  To that end

=cut

=head2 new

Initialize the module refresher;

=cut

sub new {
    my $proto = shift;
    my $self = ref($proto) || $proto;
    $self->initialize;
    return $self;
}

=head2 initialize

When we start up, set the mtime of each module to I<now>, so we don't go about
refreshing and refreshing everything.

=cut

sub initialize {
    my $self = shift;
    $CACHE{$_} = $self->mtime($INC{$_}) for ( keys %INC );
    return ($self);
}

=head2 refresh_updated

refresh all modules that have mtimes on disk newer than the newest ones we've got.

=cut

sub refresh_updated {
    my $self = shift;
    foreach my $mod (sort keys %INC) {
        if ( !$CACHE{$mod} or ( $self->mtime($INC{$mod}) ne $CACHE{$mod} ) ) {
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

    local $@;
    eval { require $mod; 1 } or warn $@;

    $self->cache_mtime( $mod => $self->mtime( $INC{$mod} ) );

    return ($self);
}

sub unload_module {
    my $self = shift;
    my $file = shift;
    my $path =  $INC{$file};
    delete $INC{$file};
    delete $CACHE{$file};
    $self->cleanup_subs($path);
    return ($self);
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
    return join ' ', ( stat($_[1]) )[1, 7, 9];
}


=head2 cleanup_subs filename

Wipe out  subs defined in $file.

=cut


sub cleanup_subs {
    my $self = shift;
    my $file = shift;

    # Find all the entries in %DB::sub whose keys match "$file:" and wack em
    foreach my $sym ( grep { $DB::sub{$_} =~ qr{^\Q$file:\E} } keys %DB::sub ) {
       warn $sym;
        undef &{$sym};
    }
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
