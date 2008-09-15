package Entidades;

use HTML::Entities;
use base qw(Class::Accessor);


Entidades->mk_accessors(qw/attr/);

sub save_csv	{
	my $self = shift;
	my $config = shift;
	my $attr = $self->attr; # Recebe atributos da classe filha
	$self->treat_data;
	open my $fh,'>>',$config->DataDir.$config->DataFile || die 'Erro '.$!;
	print $fh join ', ', @{$self}{@$attr};print $fh $/;
	close $fh;
}
sub treat_data	{
	my ($self) = @_;
	foreach (keys %$self)	{
		$self->$_(HTML::Entities::decode_entities($self->$_));
		$self->$_($self->dicionario($self->$_));
		$self->$_('"'.$self->$_.'"');
	}
}
sub dicionario	{
	my ($self,$string) = @_;
	$string =~ s/"/'/g;
	return $string;
}
1;

