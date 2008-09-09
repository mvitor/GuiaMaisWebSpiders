package Spider;

use strict;
use warnings;
use Tk;
use LWP;
use HTTP::Cookies;
use HTTP::Request;
use HTTP::Request::Common;
use URI::file;
use HTML::Entities;
use Log::Log4perl;

=head1 NAME

spiders.pm

=cut

=head1 SYNOPSIS

my $spider = compaq->new(); 

=head1 DESCRIPTION

Classe principal do sistema Robots

=head1 METHODS

=cut

=head2 new

Método construtor

=cut


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
	# Variáveis do Tk (janela, frames e labels)
	$self->{janela} = MainWindow->new(-title => ucfirst($self->{nome}) . " - Spider");
	$self->{icone} = $self->{janela}->Photo(-file => "spider.bmp");
	$self->{janela}->Icon(-image => $self->{icone});
	$self->{janela}->minsize(qw(200 115));
	$self->{frame1} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame2} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame3} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame4} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame5} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{frame6} = $self->{janela}->Frame(-relief => "groove", -borderwidth => 1)->pack(-fill => "x");
	$self->{loja1} = $self->{frame1}->Label(-text => "Loja........->")->pack(-side => "left");
	$self->{prod1} = $self->{frame2}->Label(-text => "Produtos ->")->pack(-side => "left");
	$self->{erro1} = $self->{frame3}->Label(-text => "Erros...... ->")->pack(-side => "left");
	$self->{tout1} = $self->{frame4}->Label(-text => "Time out ->")->pack(-side => "left");
	$self->{stat1} = $self->{frame5}->Label(-text => "Status.... ->")->pack(-side => "left");
	$self->{loja2} = $self->{frame1}->Label(-text => ucfirst($self->{nome}))->pack(-side => "right");
	$self->{prod2} = $self->{frame2}->Label(-text => "0")->pack(-side => "right");
	$self->{erro2} = $self->{frame3}->Label(-text => "0")->pack(-side => "right");
	$self->{tout2} = $self->{frame4}->Label(-text => "0")->pack(-side => "right");
	$self->{stat2} = $self->{frame5}->Label(-text => "Iniciando spider...")->pack(-side => "right");
	$self->{botao} = $self->{frame6}->Button(-text => "Cancelar", -command => sub{$self->{janela}->exit})->pack();
	$self->{janela}->update;
	#	MainLoop;
	# Define CONTADORES
	$self->{num_ok} = 0;        # produtos incluidos
	$self->{num_erro} = 0;      # produtos com erro
	$self->{num_repet} = 0;     # produtos duplicados
	$self->{num_novos} = 0;     # produtos com status de novo
	$self->{num_novos_tab} = 0; # produtos realmente novos(captados pela 1ª vez)
	$self->{num_ver_id1} = 0;   # produtos que seriam associados por código($self->{ver_id} = 0)
	$self->{num_ver_id2} = 0;   # produtos realmennte associados por código($self->{ver_id} = 1)
	$self->{num_descart} = 0;   # produtos descartados
	$self->{num_linhas} = 0;    # linhas do arquivo .CFG
	$self->{num_timeout} = 0;   # timeout
	# Define BANCO
	$self->log('info',"Iniciando processo de captura para ".$self->{name});
	$self->{stat2}->configure(-text => "Iniciando captura...");
	$self->{janela}->update;
	return $self;
}


################################################################################
################################################################################
# Recebe uma url como parametro, faz uma requisição p/ ela. Salva o conteúdo da
# página num arquivo e pode retornar o conteudo da página.
# flag_retorno -> 1 p/ retornar a pagina; 0 não retorna nada
# arquivo -> caso queira definir o arquivo onde o conteúdo será gravado.
#            quando omitido, grava no arquivo padrão $file_html
#
# Sintaxe: $string = $self->obter(url, flag_retorna, arquivo, tipo);

sub obter {
	my ($self,$url) = @_;
	my ($req, $resposta, $cont, $req_inicio, $req_fim);
	my $browser = LWP::UserAgent->new();
	$browser->agent("Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0)");
	$browser->cookie_jar(HTTP::Cookies->new(file => "../data/cookies.txt", autosave => 1));
	# Configura a requisi¿¿o
	$req = HTTP::Request->new("GET", $url);
	$req->headers->header(Referer => $self->{historico});
	for ($cont = 5; $cont > 0; $cont--) {
		$resposta = $browser->request($req);
		last if ($resposta->is_success());
		$self->{stat2}->configure(-text => "URL: tentativa " . $cont);
		$self->{janela}->update;
		sleep(10);
	}
	$self->{stat2}->configure(-text => "Capturando entidades...");
	$self->{janela}->update;

	if ($resposta->is_success()) {
		$self->{historico} = $url; # Target da resquicao
		$self->{base_uri} = $resposta->base; # Base uri, caso haja redirecionamento
		$self->log('info',"Requisicao ao endereÃo $url realizada com sucesso");
	} 
	else {
		$self->{num_timeout}++;
		$self->{tout2}->configure(-text => $self->{num_timeout});
		$self->{janela}->update;
		$self->log('error',"Timeout de numero ".$self->{num_timeout}."com url $url - ERR:".$resposta->message);
		return 0;
	}
}
################################################################################
################################################################################
# Retira os códigos HTML de qualquer string. Substitui tudo o que estiver
# dentro dos simbolos "<" e ">" por um espaço em branco.
#
# Sintaxe: $string = $self->retira_html($string_com_html);
sub retira_html {
	my $self = shift;
	my $str = $_[0];

	$str =~ s/<(.*?)>/ /ig;
	$str =~ s/^\s+|\s*$//ig;
	return $str;
}


################################################################################
################################################################################
# Usado p/ retirar ou substituir determinados caracteres de strings
#
# Sintaxe: $string = $self->dicionario($string_nao_formatada);
sub dicionario {
	my $self = shift;
	my $str = $_[0];

	$str =~ s/&amp;/&/ig;
	$str =~ s/&#34;/´´/g;
	$str =~ s/&#39;/´/g;
	$str =~ s/&#45;/\-/g;
	$str =~ s/&#186;/o/g;
	$str =~ s/&#224;/à/g;
	$str =~ s/&#225;/á/g;
	$str =~ s/&#226;/â/g;
	$str =~ s/&#227;/ã/g;
	$str =~ s/&#233;/é/g;
	$str =~ s/&#234;/ê/g;
	$str =~ s/&#237;/í/g;
	$str =~ s/&#231;/ç/g;
	$str =~ s/&#199;/Ç/g;
	$str =~ s/&#193;/Á/g;
	$str =~ s/&#194;/Â/g;
	$str =~ s/&#195;/Ã/g;
	$str =~ s/&#200;/É/g;
	$str =~ s/&#201;/É/g;
	$str =~ s/&#202;/Ê/g;
	$str =~ s/&#205;/Í/g;
	$str =~ s/&#211;/Ó/g;
	$str =~ s/&#212;/Ô/g;
	$str =~ s/&#213;/Õ/g;
	#$str =~ s/&#218;/+/g;
	$str =~ s/&#243;/ó/g;
	$str =~ s/&#244;/ô/g;
	$str =~ s/&#245;/õ/g;
	$str =~ s/&#249;/ù/g;
	$str =~ s/&#250;/ú/g;
	$str =~ s/&#252;/ü/g;
	$str =~ s/&#8211;/-/g;
	$str =~ s/\&quot;/´´/g;
	$str =~ s/\&quot/´´/g;
	$str =~ s/\&acute;/´/g;
	$str =~ s/ˆ/ê/g;
	$str =~ s/‡/ç/g;
	$str =~ s/Ý/ã/g;
	$str =~ s/‚/é/g;
	$str =~ s/¢/ó/g;
	$str =~ s/Æ/ã/g;
	$str =~ s/“/ô/g;
	$str =~ s/¡/í/g;
	$str =~ s/ú/ú/g;
	$str =~ s/£/ú/g;
	$str =~ s/&eacute;/é/g;
	$str =~ s/&ocirc;/ô/g;
	$str =~ s/&aacute;/á/g;
	$str =~ s/&uacute;/ú/g;
	$str =~ s/&ccedil;/ç/ig;
	$str =~ s/&atilde;/ã/ig;
	$str =~ s/&otilde;/õ/ig;
	$str =~ s/&aacute;/á/ig;
	$str =~ s/&eacute;/é/ig;
	$str =~ s/&iacute;/í/ig;
	$str =~ s/&oacute;/ó/ig;
	$str =~ s/&uacute;/ú/ig;
	$str =~ s/&acirc;/â/ig;
	$str =~ s/&ecirc;/ê/ig;
	$str =~ s/&ocirc;/ô/ig;
	$str =~ s/&nbsp;/ /ig;
	$str =~ s/"/´´/g;
	$str =~ s/”/´´/g;
	$str =~ s/`/´/g;
	$str =~ s/’/´/g;
	$str =~ s/'/´/g;
	$str =~ s/‘/´/g;
	$str =~ s/\*//g;
	$str =~ s/\(//g;
	$str =~ s/\)//g;
	$str =~ s/™/ /g;
	$str =~ s/–/-/g;
	$str =~ s/^\s+|\s*$//g;
	$str =~ s/  / /g while ($str =~ /  /);
	$str =~ s/&#946;/ß/g;
	# Decodifica expressões em HTML
	$str = HTML::Entities::decode_entities($str);

	return $str;
}


sub spider_dump {

	my $self = shift;

	my $string = "\n\nDESC: ".$self->{descricao}."\nVALOR: ".$self->{valor}."\nURL: ".$self->{url}."\nIMAGEM: ".$self->{imagem}."\nNUM_PARCELA: ".$self->{num_parcela}."\nVALOR_PARCELA: ".$self->{valor_parcela}."\nCODIGO: ".$self->{id}."\nCATEGORIA: ".$self->{categoria}."\nSUBCATEGORIA: ".$self->{subcategoria}."\n";

	return $string;
}
	

=head2 log

Metodo responsável por tratamento e gerenciamento do log.
Utiliza a classe Log::Log4perl, instacia esta classe se objeto não estiver instaciado no objeto spider.

Grava o log do diretório '/log/' usando como nome do arquivo o atributo 'nome' definido no objeto spider:

Exemplo de nome do arquivo: 

	$self->{nome} = 'Americanas'; # Nome do spider
	Nome do arquivo gerado: /log/Americanas.log

Exemplo de formato do arquivo: 

	2008/08/01 14:34:32 - spiders.pm icarros INFO - Requisicao ao endereço http://www.icarros.com.br/icarros/out/shoppingjacotei/ofertas.jsp?pagina=44&ft=1 realizada com sucesso

Sintaxe: $self->log($level,$message);

Os levels(níveis) são divididos na seguinte maneira:

	$self->log('trace',$message); # Loga uma mensagem de trace

	$self->log('debug',$message); # Loga uma mensagem de debug

	$self->log('info',$message); # Loga uma mensagem de info

	$self->log('warn',$message); # Loga uma mensagem de aviso

	$self->log('error',$message); # Loga uma mensagem de erro

	$self->log('fatal',$message); # Loga uma mensagem de erro fatal

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
1;
