package Spider::GuiaMais;

use base 'Spider';
use Spider::Entidade;

sub get_dados_cat 	{
	my ($self) = @_;
	foreach my $cat ($self->cats)	{
		my $str_cat = $self->obter($cat->{href});
		$self->{cat} = $cat->{name};
		$self->get_dados_ent($str_cat);
	}
	$self->encerra;
}
sub get_dados_ent	{		
	my ($self,$str_cat) = @_;
	my $tree_page = HTML::TreeBuilder->new_from_content($str_cat);
	my @ents = $tree_page->look_down(_tag => 'div',class=>'spI');
	foreach my $ent_html (@ents)	{
		my $html = $ent_html->as_HTML;
		my $tree_ent = HTML::TreeBuilder->new_from_content($html);
		my $entidade = Spider::Entidade->new();
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
		#	$entidade->dump();
		$entidade->save_csv();
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
		my $control = $1;
		print "Page ".$self->{page}.$/;
		$self->log('info','Capturando pagina '.$self->{page}.' Categoria '.$self->{cat});
		#if(length($self->{page}) == 1){$self->{page} = '0'.$self->{page};}
		#my $param = 'ctl00$C1$pag1$ctl'.$self->{page};
		#print $param.$/;
		if ($self->{page}==1)	{$param = 'ctl00$C1$pag1$ctl01';}
		else{$param = 'ctl00$C1$pag1$ctl02';}
		my $newstring = $self->obter_post("http://www.guiamais.com.br/".$form_url,
							__EVENTTARGET => $param,
							__EVENTARGUMENT => $self->{page},
							__VIEWSTATE => $state,
							__LASTFOCUS => 'ddsds'
						);
		use File::Slurp qw/write_file/;
#		$newstring = $agent->getContent();
		write_file('saida.html',$newstring);
		$self->get_dados_ent($newstring);
	}
	$self->{page} = 0
}
1;
