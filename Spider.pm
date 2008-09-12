package Spider;

use strict;
use Tk;
use LWP;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Request::Common;
use URI::file;
use HTML::Entities;
use Log::Log4perl;

sub new {
	my $class = shift;
	my %attr = @_;
	my $self = {};
	my ($sql, $sth, $spider_arquivo);
	my (@sites, @dados);
	bless($self, $class);
	foreach (keys %attr)	{
		$self->{$_} = $attr{$_};
	}
	$self->{page} = 0;
	$self->janela_tk;
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
	sleep(5);
	for ($cont = 5; $cont > 0; $cont--) {
		$resposta = $browser->request($req);
		last if ($resposta->is_success());
		$self->{stat2}->configure(-text => "URL: tentativa " . $cont);
		$self->{janela}->update;
		$self->log('info',"Falha Http: ".$resposta->status_line." Restam ".$cont."tentivas"); 
		sleep(10);
	}
	$self->{stat2}->configure(-text => "Capturando entidades...");
	$self->{janela}->update;

	if ($resposta->is_success()) {
		$self->{historico} = $url; # Target da resquicao
		$self->{base_uri} = $resposta->base; # Base uri, caso haja redirecionamento
		$self->log('info',"Requisição realizada com sucesso");
	} 
	else {
		$self->{num_timeout}++;
		$self->{tout2}->configure(-text => $self->{num_timeout});
		$self->{janela}->update;
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
		$self->{stat2}->configure(-text => "Falha Http Restam ".$cont."tentivas"); #".$self->status_line."
		$self->{janela}->update;
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
		$self->{tout2}->configure(-text => $self->{num_timeout});
		$self->{janela}->update;
		$self->log('error',"Timeout de numero ".$self->{num_timeout}."com url $url - ERR:".$resposta->message);
		return 0;
	}
	return $resposta->content;

}
sub spider_dump {

	my $self = shift;

	my $string = "\n\nDESC: ".$self->{descricao}."\nVALOR: ".$self->{valor}."\nURL: ".$self->{url}."\nIMAGEM: ".$self->{imagem}."\nNUM_PARCELA: ".$self->{num_parcela}."\nVALOR_PARCELA: ".$self->{valor_parcela}."\nCODIGO: ".$self->{id}."\nCATEGORIA: ".$self->{categoria}."\nSUBCATEGORIA: ".$self->{subcategoria}."\n";

	return $string;
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
	my $log_dir = 'log/';
	unless($self->{log})	{
		$self->{log} = Log::Log4perl->get_logger();
		my $appender = Log::Log4perl::Appender->new(
			      "Log::Dispatch::File",
	    		  filename => $log_dir.$self->{name}.".log",
		    	   mode     => "append",
	    );
		my $layout = Log::Log4perl::Layout::PatternLayout->new("%d - %F %c %p - %m%n");
		$appender->layout($layout);
		$self->{log}->add_appender($appender);
	}
	$self->{log}->$level($message);
}

=head2 

Inicia Janela Tk e contadores

=cut

sub janela_tk	{
	my $self = shift;

	# Variáveis do Tk (janela, frames e labels)
	$self->{janela} = MainWindow->new(-title => ucfirst($self->{name}) . " - Spider");
	$self->{icone} = $self->{janela}->Photo(-file => "spider.bmp");
	$self->{janela}->Icon(-image => $self->{icone});
	$self->{janela}->minsize(qw(200 115));
	$self->{frame1} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame2} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame3} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame4} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame5} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame6} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{prod1} = $self->{frame2}->Label(-text => "Entidades ->")->pack(-side => "left");
	$self->{erro1} = $self->{frame3}->Label(-text => "Erros...... ->")->pack(-side => "left");
	$self->{tout1} = $self->{frame4}->Label(-text => "Time out ->")->pack(-side => "left");
	$self->{stat1} = $self->{frame5}->Label(-text => "Status.... ->")->pack(-side => "left");
	$self->{prod2} = $self->{frame2}->Label(-text => "0")->pack(-side => "right");
	$self->{erro2} = $self->{frame3}->Label(-text => "0")->pack(-side => "right");
	$self->{tout2} = $self->{frame4}->Label(-text => "0")->pack(-side => "right");
	$self->{stat2} = $self->{frame5}->Label(-text => "Iniciando spider...")->pack(-side => "right");
	$self->{botao} = $self->{frame6}->Button(-text => "Cancelar", -command => sub{$self->{janela}->exit})->pack();
	$self->{janela}->update;
	#	MainLoop;
	# Define CONTADORES
	$self->{num_ok} = 0;        
	$self->{num_erro} = 0;      
	$self->{num_timeout} = 0;
	# Define BANCO
	$self->log('info',"Iniciando processo de captura para ".$self->{name});
	$self->{stat2}->configure(-text => "Iniciando captura...");
	$self->{janela}->update;
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
	$self->{prod2}->configure(-text=>$self->{num_ok});
	$self->{janela}->update;		
}
sub cats	{
	my ($self) = @_;
	return @{$self->{categorias}};
}
sub set_cats	{
	my ($self,$cat_name,$cat_href)	= @_;
	push(@{$self->{categorias}}, {name=>$cat_name,href=>$cat_href});
}

1;
