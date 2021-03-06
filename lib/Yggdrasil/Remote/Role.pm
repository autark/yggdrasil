package Yggdrasil::Remote::Role;

use strict;
use warnings;

use base qw/Yggdrasil::Role/;

sub define {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    my %params = @_;
    
    return Yggdrasil::Object::objectify(
					$self->yggdrasil(),
					__PACKAGE__,
					$self->storage()->{protocol}->define_role( $params{role} ),  
				       );
}

sub get {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);
    my %params = @_;

    return Yggdrasil::Object::objectify(
					$self->yggdrasil(),
					__PACKAGE__,
					$self->storage()->{protocol}->get_role( $params{role} ),
				       );
}

sub get_all {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );
    my %params = @_;

    return Yggdrasil::Object::objectify(
					$self->yggdrasil(),
					__PACKAGE__,
					$self->storage()->{protocol}->get_all_roles(),
				       );
}

sub _setter_getter {
    my $self = shift;
    my $key  = shift;

    if( @_ ) {
	print "CALLING SET? (@_), ", scalar @_, "\n";
	$self->storage()->{protocol}->set_role_value( $self->id(), $key, $_[0] );
	return $_[0];
    }

    return $self->storage()->{protocol}->get_role_value( $self->id(), $key );
}

sub rolename {
    my $self = shift;
    return $self->id();
}

sub name {
    my $self = shift;
    return $self->id();    
}

sub id {
    my $self = shift;
    return $self->{name};
}

sub description {
    my $self = shift;
    return $self->_setter_getter( description => @_ );
}

sub members {
    my $self = shift;
    my @r = $self->storage()->{protocol}->get_members( $self->id() );
    return Yggdrasil::Object::objectify(
					$self->yggdrasil(),
					'Yggdrasil::Remote::User',
					@r
					);
}

sub grant {
   my $self   = shift;
   my $schema = shift;

   # Take either the name, or an object as a parameter.
   $schema = $schema->name() if ref $schema;
   $self->storage()->{protocol}->role_grant( $self->id(), $schema, @_ );
}

sub revoke {
    my $self   = shift;
    my $schema = shift;
    
    # Take either the name, or an object as a parameter.
    $schema = $schema->name() if ref $schema;
    $self->storage()->{protocol}->role_revoke( $self->id(), $schema, @_ );
}

sub add {
    my $self = shift;
    my $user = shift;

    $user = $self->_check_user($user);
    return unless $user;

    return $self->storage()->{protocol}->role_add_user( $self->id(), $user->id() );
}

sub remove {
    my $self = shift;
    my $user = shift;

    $user = $self->_check_user($user);
    return unless $user;

    return $self->storage()->{protocol}->role_remove_user( $self->id(), $user->id() );
}

1;
