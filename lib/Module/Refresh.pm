package Module::Refresh;

use strict;
use vars qw( $VERSION %CACHE );

$VERSION = "0.03";

# Turn on the debugger's symbol source tracing
BEGIN { $^P |= 0x10 };

=head1 NAME

Module::Refresh - Refresh %INC files when updated on disk

=head1 SYNOPSIS

    # During each request, call this once to refresh changed modules:

    Module::Refresh->refresh;

    # Each night at midnight, you automatically download the latest
    # Acme::Current from CPAN.  Use this snippet to make your running
    # program pick it up off disk:

    $refresher->refresh_module('Acme::Current');

=head1 DESCRIPTION

This module is a generalization of the functionality provided by
B<Apache::StatINC>.  It's designed to make it easy to do simple iterative
development when working in a persistent environment.

=cut

=head2 new

Initialize the module refresher.

=cut

sub new {
    my $proto = shift;
    my $self = ref($proto) || $proto;
    $CACHE{$_} = $self->mtime($INC{$_}) for ( keys %INC );
    return ($self);
};

=head2 refresh

Refresh all modules that have mtimes on disk newer than the newest ones we've got.
Calls C<new> to initialize the cache if it had not yet been called.

=cut

sub refresh {
    my $self = shift;

    return $self->new if !%CACHE;

    foreach my $mod (sort keys %INC) {
        if ( !$CACHE{$mod} or ( $self->mtime($INC{$mod}) ne $CACHE{$mod} ) ) {
            $self->refresh_module($mod);
        }
    }
    return ($self);
};

=head2 refresh_module $module

Refresh a module.  It doesn't matter if it's already up to date.  Just do it.

Note that it only accepts module names like C<Foo/Bar.pm>, not C<Foo::Bar>.

=cut

sub refresh_module {
    my $self = shift;
    my $mod  = shift;

    $self->unload_module($mod);

    local $@;
    eval { require $mod; 1 } or warn $@;

    $CACHE{$mod} = $self->mtime( $INC{$mod} );

    return ($self);
};

=head2 unload_module $module

Remove a module from C<%INC>, and remove all subroutines defined in it.

=cut

sub unload_module {
    my $self = shift;
    my $mod  = shift;
    my $file = $INC{$mod};

    delete $INC{$mod};
    delete $CACHE{$mod};
    $self->unload_subs($file);

    return ($self);
};

=head2 mtime $file

Get the last modified time of $file in seconds since the epoch;

=cut

sub mtime {
    return join ' ', ( stat($_[1]) )[1, 7, 9];
};

=head2 unload_subs $file

Wipe out subs defined in $file.

=cut

sub unload_subs {
    my $self = shift;
    my $file = shift;

    foreach my $sym (
        grep { index( $DB::sub{$_}, "$file:" ) == 0 } keys %DB::sub
    ) {
        undef &$sym;
        delete $DB::sub{$sym};
    }

    return $self;
};

# "Anonymize" all our subroutines into unnamed closures; so we can safely
# refresh this very package.
BEGIN {
    no strict 'refs';
    foreach my $sym (sort keys %{__PACKAGE__.'::'}) {
        my $code = __PACKAGE__->can($sym) or next;
        delete ${__PACKAGE__.'::'}{$sym};
        *$sym = sub { goto &$code };
    }
}

1;

=head1 BUGS

When we walk the symbol table to whack reloaded subroutines, we don't have a good way
to invalidate the symbol table.

=head1 SEE ALSO

L<Apache::StatINC>, L<Module::Reload>

=head1 COPYRIGHT

Copyright 2004 by Jesse Vincent E<lt>jesse@bestpractical.comE<gt>,
Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
