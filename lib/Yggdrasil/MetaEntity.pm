package Yggdrasil::MetaEntity;

use strict;
use warnings;

use base qw(Yggdrasil::Object);

sub define {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    my $storage = $self->{yggdrasil}->{storage};
    
    # --- Tell Storage to create SCHEMA, noop if it exists.
    $storage->define( "MetaEntity",
		      fields     => {
				     id     => { type => 'SERIAL' },
				     parent => { type => 'INTEGER' },
				     entity => { type => "VARCHAR(255)", null => 0 },
				    },
		      temporal   => 1,
		      nomap      => 1,
		      hints      => {
				     parent => { foreign => 'MetaEntity' },
				    },
		      auth       => {
				     # Write access to parent required.
				     create => [
						':Auth' => {
							    where => [
								      id    => \qq<MetaEntity.parent>,
								      w     => 1,
								     ],
							   },
					       ],
				     # get an entity.  Read self to access.
				     fetch  => [
						':Auth' => {
							    where => [
								      id   => \qq<MetaEntity.id>,
								      r    => 1,
								     ],
							   },
					       ],
				     # rename entity.  Modify self required.
				     update => [
						':Auth' => { 
							    where => [
								      id     => \qq<MetaEntity.id>,
								      'm'    => 1,
								     ],
							   },
					       ],
				     # expire / delete entity.  Write to parent, modify self.
				     expire => [
						':Auth' => {
							    where => [
								      id => \qq<MetaEntity.parent>,
								      w  => 1,
								     ],
							   },
						':Auth' => {
							    where => [
								      id  => \qq<MetaEntity.id>,
								      'm' => 1,
								     ],
							   },
					       ],
					    },
		    );
    
    $storage->define( "Instances",
		      fields   => { 
				   entity    => { type => "INTEGER" },
				   visual_id => { type => "TEXT" },
				   id        => { type => "SERIAL" } },
		      temporal => 1,
		      nomap    => 1,
		      hints    => {
				   entity => { foreign => 'MetaEntity' },
				  },
		      auth => {
			       # Create instance, require write access to entity.
			       create => [
					  'MetaEntity:Auth' => { 
								where => [
									  id    => \qq<Instances.entity>,
									  w     => 1,
									 ],
							       },
					 ],
			       # No need to check readability of the entity, as you can
			       # only access the fetch call from that entity object.  If you
			       # have been given that entity object, odds are you can read it.
			       # (Hopefully).
			       fetch  => [
					  ':Auth' => {
						      where => [
								id   => \qq<Instances.id>,
								r    => 1,
							       ],
						     },
					 ],
			       # expire / delete instance.
			       expire => [
					  ':Auth' => { 
						      where => [
								id     => \qq<Instances.id>,
								'm'    => 1,
							       ],
						     },
					  'MetaEntity:Auth' => {
								where => [
									  id    => \qq<Instances.entity>,
									  w     => 1,
									 ],
							       },
					 ],
			       # Rename, edit visual ID.  Modify self, write to entity.
			       update => [
					  ':Auth' => {
						      where => [
								id     => \qq<Instances.id>,
								'm'    => 1,
							       ],
						     },
					 ],
			      },
		      
		    );
}    

sub add {
    my $class  = shift;
    my $self   = $class->SUPER::new(@_);
    my %params = @_;

    my $name = $params{entity};
    
    my $id = $self->{yggdrasil}->{storage}->store( "MetaEntity", key => "entity", fields => { entity => $name } );

    my $user = $self->storage()->user();
    for my $role ( $user->member_of() ) {
	$role->grant( 'MetaEntity' => 'm', id => $id );
    }
}

sub _admin_dump {
    my $self = shift;

    return $self->{storage}->raw_fetch( "MetaEntity" );
}

sub _admin_restore {
    my $self = shift;
    my $data = shift;

    $self->{storage}->raw_store( "MetaEntity", fields => $data );

    my $id = $self->{storage}->raw_fetch( MetaEntity => 
					  { return => "id",
					    where  => [ %$data ] } );

    return $id->[0]->{id};
}

1;
