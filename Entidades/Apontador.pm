package Entidades::Apontador;
use base qw/Entidades/;
use base qw(Class::Accessor);

my @atrr = qw(nome end telefone tags categoria url);

Entidades::Apontador->mk_accessors(@atrr);

sub new   {
	my $class = shift;
	my $self = bless {}, $class;
	$self->init;
	return $self;
}

sub init	{
	my ($self) = @_;
	$self->SUPER::attr(qw(nome end telefone tags categoria url));
}

sub dump	{
	my $self = shift;
	print "Nome: ".$self->nome.$/;
	print "EndereÃo: ".$self->end.$/;
	print "Telefone: ".$self->telefone.$/;
	print "Tags: ".$self->tags.$/;
	print "Categoria: ".$self->categoria.$/;
	print "URL: ".$self->url.$/x2;
}
1;
