package Spider::Entidade;

use Class::CSV;
use HTML::Entities;
use base qw(Class::Accessor);

my @atrr = qw(nome end telefone descricao categoria url url_logo);

Spider::Entidade->mk_accessors(@atrr);

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
	open my $fh,'>>','entidades.csv';
	print $fh join ', ', @{$self}{@atrr};print $fh $/;
	close $fh;
}
sub nome	{
	my $self = shift;
	@_ = HTML::Entities::decode_entities(@_);
	return $self->_nome_accessor(@_);
}
sub end	{
	my $self = shift;
	@_ = HTML::Entities::decode_entities(@_);
	return $self->_end_accessor(@_);
}
sub descricao	{
	my $self = shift;
	@_ = HTML::Entities::decode_entities(@_);
	return $self->_descricao_accessor(@_);
}
sub categoria	{
	my $self = shift;
	@_ = HTML::Entities::decode_entities(@_);
	return $self->_categoria_accessor(@_);
}
sub url	{
	my $self = shift;
	@_ = HTML::Entities::decode_entities(@_);
	return $self->_url_accessor(@_);
}
sub url_logo	{
	my $self = shift;
	@_ = HTML::Entities::decode_entities(@_);
	return $self->_url_logo_accessor(@_);
}

1;

