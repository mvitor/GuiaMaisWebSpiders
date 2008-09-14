package Entidade;

use HTML::Entities;
use base qw(Class::Accessor);

my @atrr = qw(nome end telefone descricao categoria url url_logo);

Entidade->mk_accessors(@atrr);
sub dump	{
	my $self = shift;
	print "Nome: ".$self->nome.$/;
	print "EndereÃo: ".$self->end.$/;
	print "Telefone: ".$self->telefone.$/;
	print "Descricao: ".$self->descricao.$/;
	print "Categoria: ".$self->categoria.$/;
	print "URL: ".$self->url.$/;
	print "URL Logotipo: ".$self->url_logo.$/x2;
}
sub save_csv	{
	my $self = shift;
	my $config = shift;
	$self->treat_data;
	open my $fh,'>>',$config->DataDir.$config->DataFile || die 'Erro '.$!;
	print $fh join ', ', @{$self}{@atrr};print $fh $/;
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

