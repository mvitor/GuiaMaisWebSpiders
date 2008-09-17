package Spider::GuiaMais;

use base 'Spider';
use Entidades::Guiamais;

sub get_cats	{
	my ($self,$string) = @_;
	# Captura Categorias e respectivos links
	my $tree = HTML::TreeBuilder->new_from_content($string);
	my @cats = $tree->look_down(_tag => 'a',class=>'lnk1L');
	$self->log('info',@cats.' categorias localizados'); 

	# Grava categorias no objeto
	foreach (@cats)	{
		my ($cat_href) = $_->as_HTML =~ /href="(.*?)"/;
		my $cat_name = $_->as_text;
		$self->set_cats($cat_name,'http://www.guiamais.com.br/'.$cat_href);
	}
}
sub get_dados	{
	my ($self) = @_;
	$self->check_files;
	$self->get_dados_cat;
	$self->encerrar;
}
sub get_dados_cat 	{
	my ($self) = @_;
	foreach my $cat ($self->cats)	{
		my $str_cat = $self->obter($cat->{href});
		$self->{cat} = $cat->{name};
		$self->get_dados_ent($str_cat);
	}
}

sub get_dados_ent	{		
	my ($self,$str_cat) = @_;
	my $tree_page = HTML::TreeBuilder->new_from_content($str_cat);
	my @ents = $tree_page->look_down(_tag => 'div',class=>'spI');
	foreach my $ent_html (@ents)	{
		my $html = $ent_html->as_HTML;
		my $tree_ent = HTML::TreeBuilder->new_from_content($html);
		my $entidade = Entidades::Guiamais->new();
		$entidade->categoria($self->{cat});
		my ($name,$end);
		# Nome e url
		# Diferenciacao pois alguns clientes tem sites, outros nao. A forma de exibicao é difrente.
		if ((my $ahref = $tree_ent->look_down(_tag=>'a',class=>'txtT')))	{
			$entidade->nome($ahref->as_text); # Define atributo nome
			$ahref->as_HTML =~ /href="(.*?)"/;
			$entidade->url($1); # Define atributo url
			$ahref = $ahref->delete;
		}
		else	{
			$name = $tree_ent->look_down(_tag=>'span',class=>'txtT');
			$name = $name->as_text;
			#Define atributo nome
			if (ref($name))	{
				$entidade->nome($name->as_text);
			}
			else{$entidade->nome($name);} 
		}
		# Descrição
		if ((my $desc = $tree_ent->look_down(_tag=>'div',class=>'divInfoBox')))	{
			$entidade->descricao($desc->as_text);
		}
		if ((my $tel = $tree_ent->look_down(_tag=>'div',class=>'divPhoneTxt')))	{
			$entidade->telefone($tel->as_text);
			$tel = $tel->delete;
		}
		# Endereço
		if (my $address = $tree_ent->look_down(_tag=>'div',class=>'divAddress'))	{
			my ($rua) = $address->as_HTML =~ /<span class="CmpInf">(.*?)<\/span>/i;
			$address = $address->delete;
			$end .= $rua;
		}
		if(my $neighborhood = $tree_ent->look_down(_tag=>'div',class=>'divNeighborHood'))	{
			my ($bairro) = $neighborhood->as_HTML =~ /<span class="CmpInf">(.*?)<\/span>/i;
			$neighborhood = $neighborhood->delete;
			$end .= ' '.$bairro;
		}
		if (my $city = $tree_ent->look_down(_tag=>'div',class=>'divCity'))	{
			my ($cidade) = $city->as_HTML =~ /<span>(.*?)<\/span>/i;
			$city = $city->delete;
			$end .= ' '.$cidade;
		}
		$entidade->end($end);
		#Link Url
		if(my $img = $tree_ent->look_down(_tag=>'img',sub{$_[0]->as_HTML =~ /images.guiamais.com.br/}))	{
			$img->as_HTML =~ /src="(.*?)"/i;
			$entidade->url_logo($1);
			$img = $img->delete;
		}
		$tree_ent = $tree_ent->delete;
		$entidade->dump();
		$entidade->save_csv($self->{config});
		$self->SUPER::num_ok();
	}
	$self->get_paginacao($str_cat);
	$tree_page = $tree_page->delete;
}
sub get_paginacao {
    my $self = shift;
    my $string = shift;
	my ($form_url) = $string =~ /<form name="aspnetForm" method="post" action="(.*?)"/sig;
	$form_url =~ s/amp;//g;
    my ($state) = $string =~ m{<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="(.+?)"}ig;
	if ($string =~ m{(ctl00\$C1\$pag1\$ctl02)}si || !$self->{page} || ($self->{page} && m{(ctl00\$C1\$pag1\$ctl01)}si))	{
		$self->{page}++; # Conta número de paginações
		$self->log('info','Capturando pagina '.$self->{page}.' Categoria '.$self->{cat});
		if ($self->{page}==1)	{$param = 'ctl00$C1$pag1$ctl01';}
		else{$param = 'ctl00$C1$pag1$ctl02';}
		my $newstring = $self->obter_post("http://www.guiamais.com.br/".$form_url,
							__EVENTTARGET => $param,
							__EVENTARGUMENT => $self->{page},
							__VIEWSTATE => $state,
							__LASTFOCUS => 'ddsds'
						);
		use File::Slurp qw/write_file/;
		write_file("pagina".$self->{page}.".html",$newstring);

		$self->get_dados_ent($newstring);
	}
	else{$self->{page} = 0;}
}
sub get_palavra_chave	{
	my ($self,$string) = @_;
	undef $string;
=cut
	my ($form_url) = $string =~ /<form name="aspnetForm" method="post" action="(.*?)"/sig;
	$form_url =~ s/amp;//g;
    my ($state) = $string =~ m{<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="(.+?)"}ig;
	if ($string =~ m{(ctl00\$C1\$pag1\$ctl02)}si || !$self->{page} || ($self->{page} && m{(ctl00\$C1\$pag1\$ctl01)}si))	{
		$self->{page}++; # Conta número de paginações
		$self->log('info','Capturando pagina '.$self->{page}.' Categoria '.$self->{cat});
		if ($self->{page}==1)	{$param = 'ctl00$C1$pag1$ctl01';}
		else{$param = 'ctl00$C1$pag1$ctl02';}
		print "http://www.guiamais.com.br/".$form_url.$/;
		#		'AP','AM','BA','CE','DF','ES','GO','MA','muito','MS','MG','PA','PB','PR','PE','PI','RJ','RN','RS','RO','RR','SC','SP','SE','TO');
=cut
		my $estados = {
			'AC'=>579,'AL'=>580,'AP'=>581,'AM'=>582,'BA'=>583,'CE'=>584,'DF'=>585,'ES'=>586,
			'GO'=>587,'MA'=>588,'MS'=>589,'MG'=>560,'PA'=>561,'PB'=>562,'PE'=>562,'PI'=>562,
			'PR'=>563,'PE'=>581,'RJ'=>562,'RN'=>562,'RS'=>581,'RO'=>562,'RR'=>562,'SC'=>581,
			'SP'=>562,'SE'=>562,'TO'=>562
			};

		foreach my $estado ( keys %$estados)	{
			$self->{cat} = 	'Estado '.$estado;
			my $url = "http://www.guiamais.com.br/Results.aspx?&ipa=16&npa=TodoslosPaises&nes=$estado&idi=3&txb=restaurante&shr=0&ies=".$estados->{$estado};
			print $url.$/;
			my $nstring = $self->obter($url);
			use File::Slurp qw/write_file/;
			write_file("saida$estado.html",$nstring);
			$self->get_dados_ent($nstring);
		}
	}
#http://restaurantes.guiamais.com.br/Results.aspx?ica=4834&ipa=16&npa=TodoslosPaises&ies=*&nes=Todos+os+estados&idi=3&txb=restaurante&shr=0
=cut
#							__EVENTTARGET => $param,
#							__EVENTARGUMENT => 1,
#							__VIEWSTATE => $state,
#							__LASTFOCUS => 'ddsds',
#							ctl00_C1_SBCtr_TextBoxWhat => 'restaurante+japones',
							ica => 34031,
							npa => 'TodoslosPaises',
							#ies => '*',
							ipa => 16,
#							nes => 'Todos+os+estados',
							nes => 'SP',
							idi => 3,
							txb => 'japones',
							#			shr => 0
						);
=cut						
	
#http://www.guiamais.com.br/Handlers/AjaxHandler.ashx?OP=findWordRelate&search=restaurantes&where=&state=SP&country=&lng=&query=sinuca
=cut
	
	use WWW::Mechanize;
	my $mech = WWW::Mechanize->new();
	$mech->get('http://www.guiamais.com.br/');
#http://www.guiamais.com.br/Results.aspx?ica=34031&ipa=16&npa=TodoslosPaises&ies=336&nes=SP&idi=3&txb=japones&shr=0
#	http://restaurantes.guiamais.com.br/Results.aspx?ica=15544&ipa=16&npa=TodoslosPaises&ies=336&nes=SP&idi=3&txb=restaurante+japones&shr=0
	my $newstring = $self->obter_post("http://www.guiamais.com.br/Results.aspx?ipa=16",
					ica => 34031
					nes => 'SP',
					idi => 3,
					txb => 'restaurante+japones'
				);
	
				use File::Slurp qw/write_file/;
	write_file('saida.html',$newstring);
	die;
#	&nes=AC&idi=3&txb=restaurante+japones&shr=0
=cut
#	http://restaurantes.guiamais.com.br/Results.aspx?ica=15544&ipa=16&npa=TodoslosPaises&ies=333&nes=RJ&idi=3&txb=restaurante+japones&shr=0
1;
