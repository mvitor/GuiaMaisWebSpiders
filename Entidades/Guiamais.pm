package Entidades::Guiamais;
use base qw/Entidades/;
use base qw(Class::Accessor);

my @atrr = qw(nome end telefone descricao categoria url url_logo);

Entidades::Guiamais->mk_accessors(@atrr);

sub new   {
	my $class = shift;
	my $self = bless {}, $class;
	$self->init;
	return $self;
}
sub init	{
	my ($self) = @_;
	$self->SUPER::attr(qw(nome end telefone descricao categoria url url_logo));
}
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
1
