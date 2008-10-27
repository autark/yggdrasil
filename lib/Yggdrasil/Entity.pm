package Yggdrasil::Entity;

use strict;
use warnings;

use base qw(Yggdrasil::MetaEntity Yggdrasil::MetaInheritance);

sub _define {
    my $self  = shift;
    my $name  = shift;
    my %params = @_;

    my $package = join '::', $self->{namespace}, $name;

    # --- Add to MetaEntity, noop if it exists.
    $self->_meta_add($name);

    # --- Update MetaInheritance
    if( defined $params{inherit} ) {
	my $parent = Yggdrasil::_extract_entity($params{inherit});
	$self->_add_inheritance( $name, $parent );
    } else {
	$self->_expire_inheritance( $name );
    }

    # --- Create namespace, redefined if it exists.
    $self->_register_namespace( $package );
    
    return $package;
}

sub _admin_dump {
    my $self   = shift;
    my $entity = shift;

    return $self->{storage}->raw_fetch(MetaEntity => { where => [ entity => $entity ]},
				       Entities   => { where => [ entity => \qq{MetaEntity.id} ] } );
}

sub _admin_restore {
    my $self   = shift;
    my $entity = shift;
    my $ids    = shift;

    my %map;
    foreach my $id ( @$ids ) {
	$self->{storage}->raw_store( "Entities", fields => { 
	    entity    => $entity,
	    visual_id => $id } );

	my $idfetch = $self->{storage}->fetch( Entities =>
					       { return => "id", 
						 where => [ 
						     visual_id => $id,
						     entity    => $entity ] } );
	my $idnum = $idfetch->[0]->{id};
	$map{$id} = $idnum;
    }

    return \%map;
}

1;
