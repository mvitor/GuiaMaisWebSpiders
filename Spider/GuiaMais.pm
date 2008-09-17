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
sub get_arquivos_palavras	{
	my ($self,$arquivo) = @_;
	$self->check_files;
	use File::Slurp qw/slurp/;
	my $cont = slurp($arquivo);
	$cont =~ s/ /+/g;
	my @palavras = split('\n',$cont);
	$self->{palavras} = \@palavras;
}
sub get_dados_ent_pag	{		
	my ($self,$str_cat) = @_;
	my $tree_page = HTML::TreeBuilder->new_from_content($str_cat);
	my @ents = $tree_page->look_down(_tag => 'div',sub {$_[0]->attr('class') =~ m/stI|spI/});
	foreach my $ent_html (@ents)	{
		my $html = $ent_html->as_HTML;
		next if $html =~ /N&atilde;o foram encontrados registros/is;
		my $tree_ent = HTML::TreeBuilder->new_from_content($html);
		my $entidade = Entidades::Guiamais->new();
		$entidade->categoria($self->{cat});
		my ($name,$end);
		# Nome e url
		# Diferenciacao pois alguns clientes tem sites, outros nao. A forma de exibicao é difrente.
		if ((my $ahref = $tree_ent->look_down(_tag=>'a',sub {$_[0]->attr('class') =~ m/^txtT/})))	{
			$entidade->nome($ahref->as_text); # Define atributo nome
			my ($url) = $ahref->as_HTML =~ /href="(.*?)"/;
			$url =~ s/amp;//g;
			$url =~ /&web=(.*?)/g;
			$entidade->url($1); # Define atributo url
			$ahref = $ahref->delete;
		}
		else	{
			$name = $tree_ent->look_down(_tag=>'span',sub {$_[0]->attr('class') =~ m/^txtT/i});
			#Define atributo nome
			if (ref($name))	{
				$entidade->nome($name->as_text);
			}
			else{$entidade->nome($name);} 
		}
		# Descricao
		if ((my $desc = $tree_ent->look_down(_tag=>'div',class=>'CmpInf')))	{
			$entidade->categoria($desc->as_text);
		}
		if ((my $desc = $tree_ent->look_down(_tag=>'span',class=>'CmpInf')))	{
			$entidade->categoria($desc->as_text);
		}
		if ((my $tel = $tree_ent->look_down(_tag=>'div',sub {$_[0]->attr('class') =~ m/divPhoneTxt|divContact/})))	{
			my $tels = $tel->as_text;
			$tels =~ s/[A-Za-z]+//g; # Retira caracteres inuteis
			$entidade->telefone($tels);
			$tel = $tel->delete;
		}
		# Endereço
		if (my $address = $tree_ent->look_down(_tag=>'span',class=>'divAddress'))	{
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
		my $newstring = $self->obter_post("http://restaurantes.guiamais.com.br/".$form_url,
							__EVENTTARGET => $param,
							__EVENTARGUMENT => $self->{page},
							__VIEWSTATE => $state,
							__LASTFOCUS => 'ddsds'
						);
		$self->get_dados_ent_pag($newstring);
	}
	else{$self->{page} = 0;}
}
sub get_palavra_chave	{
	my ($self) = @_;
	foreach my $expr (@{$self->{palavras}})	{
		my $estados = {
			'AC'=>579,'AL'=>580,'AP'=>581,'AM'=>325,'BA'=>326,'CE'=>582,'DF'=>327,'ES'=>328,
			'GO'=>329,'MA'=>584,'MT'=>587,'MS'=>586,'MG'=>585,'PA'=>330,'PB'=>588,'PI'=>590,
			'PR'=>331,'MS'=>586,'RJ'=>333,'RN'=>591,'RS'=>334,'RO'=>592,'RR'=>593,'SC'=>335,
			'SP'=>336,'SE'=>594,'TO'=>595
			};
		foreach my $estado ( sort keys %$estados)	{
			$self->{cat} = 	'Estado '.$estado;
			my $url = "http://www.guiamais.com.br/Results.aspx?&ipa=16&npa=TodoslosPaises&nes=$estado&idi=3&txb=$expr&shr=0&ies=".$estados->{$estado};
			print $url.$/;
			my $nstring = $self->obter($url);
			$self->get_dados_ent_pag($nstring);
		}
	}
}
1;
