package Spider::Config;

use base qw(Config::ApacheFormat);
#use base qw(Class::Accessor);

#my @atrr = qw(nome);
#Spider::Config->mk_accessors(@atrr);

sub new	{
	my ($class,$nome) = @_;
	my $self = {};
	$self->{nome} = $nome;
	bless $self, $class;
	$self->config;
}
sub config	{
	my ($self) = @_;
	my $config = Config::ApacheFormat->new();
	$config->read('config/'.$self->{nome}.'.conf');
	$config->autoload_support(1);
	return $config; 
}


1;

