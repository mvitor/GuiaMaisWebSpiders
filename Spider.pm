package Spider;

use strict;
use warnings;
use LWP;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Request::Common;
use URI::file;
use HTML::Entities;
use Log::Log4perl;
use Spider::Config;

sub new {
	my ($class,%attr) = @_;
	my $self = {};
	bless($self, $class);
	foreach (keys %attr)	{
		$self->$_($attr{$_});
	}
	$self->{config} = Spider::Config->new($self->nome);
	# Define CONTADORES
	$self->{num_ok} = 0;        
	$self->{num_erro} = 0;      
	$self->{num_timeout} = 0;
	$self->{page} = 0;
	# Define BANCO
	$self->log('info',"Iniciando processo de captura para ".$self->nome);
	return $self;
}

sub obter {
	my $self = shift;
	my $url = shift;
	my $attr = shift;
	my ($req, $resposta, $cont, $req_inicio, $req_fim);
	my $browser = LWP::UserAgent->new();
	$browser->agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)");
	$browser->cookie_jar(HTTP::Cookies->new(file => ".cookies.txt", autosave => 1));
	if ($attr)	{
		$req = HTTP::Request->new("POST",$url,[%$attr]);
	}
	else	{
		$req = HTTP::Request->new("GET",$url);
	
	}
	$req->headers->header(Referer => $self->{historico});
	$self->log('info',"Iniciando requisição a url $url");
	for ($cont = 5; $cont > 0; $cont--) {
		$resposta = $browser->request($req);
		last if ($resposta->is_success());
		$self->log('info',"Falha Http: ".$resposta->status_line." Restam ".$cont."tentivas"); 
		sleep(10);
	}

	if ($resposta->is_success()) {
		$self->{historico} = $url; # Target da resquicao
		$self->{base_uri} = $resposta->base; # Base uri, caso haja redirecionamento
		$self->log('info',"Requisição realizada com sucesso");
	} 
	else {
		$self->{num_timeout}++;
		$self->log('error',"Timeout de numero ".$self->{num_timeout}."com url $url - ERR:".$resposta->message);
		return 0;
	}
	return $resposta->content;
}
sub obter_post	{
	my $self = shift;
	my $url = shift;
	my %attr = @_;
	$self->{_browser} = new LWP::UserAgent;
	$self->{_browser}->agent($self->{agent});
	$self->{_browser}->cookie_jar(HTTP::Cookies->new(file => ".cookies.txt", autosave => 1));
	$self->log('info',"Iniciando requisição a url $url");
	my ($resposta,$cont);
	for ($cont = 5; $cont > 0; $cont--) {
		$resposta = $self->{_browser}->request(POST $url, [%attr]);
		last if ($resposta->is_success());
		$self->log('info',"Falha Http: ".$resposta->status_line." Restam ".$cont."tentivas"); 
		sleep(10);
	}
	if ($resposta->is_success()) {
		$self->{historico} = $url; # Target da resquicao
		$self->{base_uri} = $resposta->base; # Base uri, caso haja redirecionamento
		$self->log('info',"Requisição realizada com sucesso");
	} 
	else {
		$self->{num_timeout}++;
		$self->log('error',"Timeout de numero ".$self->{num_timeout}."com url $url - ERR:".$resposta->message);
		return 0;
	}
	return $resposta->content;

}

sub check_files	{
	my ($self) = @_;
	if (-e $self->{config}->DataDir.$self->{config}->DataFile)	{
		rename($self->{config}->DataDir.$self->{config}->DataFile,$self->{config}->DataDir.$self->{config}->DataFile.'_old') || die "Falha ao renomear arquivo para 'old'";
		$self->log('info','Arquivo '.$self->{config}->DataDir.$self->{config}->DataFile.' renomeado');
	}
}

=head2 log

Metodo responsável por tratamento e gerenciamento do log.
Utiliza a classe Log::Log4perl, instacia esta classe se objeto não estiver instaciado no objeto spider.

Os levels(níveis) são divididos na seguinte maneira:

	$self->log('error',$message); # Loga uma mensagem de erro

=cut

sub log		{
	my $self = shift;
	my $level = shift;
	my $message = shift;
	unless($self->{log})	{
		$self->{log} = Log::Log4perl->get_logger();
		my $appender = Log::Log4perl::Appender->new(
			      "Log::Dispatch::File",
	    		  filename => $self->{config}->LogDir.$self->nome.".log",
		    	   mode     => "append",
	    );
		my $layout = Log::Log4perl::Layout::PatternLayout->new("%d - %F %c %p - %m%n");
		$appender->layout($layout);
		$self->{log}->add_appender($appender);
	}
	$self->{log}->$level($message);
}
sub encerrar	{
	my $self = shift;
	$self->log('info','Spider finalizado com sucesso, '.$self->{num_ok}.' entidades inseridas');
}

=head2 ACESSORS

=cut
sub num_ok	{
	my ($self) = @_;
	$self->{num_ok}++;
}
sub cats	{
	my ($self) = @_;
	return @{$self->{categorias}};
}
sub set_cats	{
	my ($self,$cat_name,$cat_href)	= @_;
	push(@{$self->{categorias}}, {name=>$cat_name,href=>$cat_href});
}
sub nome {
	my ($self,$name) = @_;
	$self->{nome} = $name if $name;
	return $self->{nome};
}
1;
