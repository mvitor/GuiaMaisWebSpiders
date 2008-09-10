package Spider::GuiaMais;

use base 'Spider';
use Spider::Entidade;

=head2 get_dados

=cut
my $c=0;
my $i=0;

sub get_dados_cat 	{
	my ($self) = @_;
	foreach my $cat ($self->cats)	{
		$c++;
		my $str_cat = $self->obter($cat->{href});
		$self->get_dados_ent($str_cat);
	}
}
		
sub get_dados_ent	{		
	my ($self,$str_cat) = @_;
	my $tree_page = HTML::TreeBuilder->new_from_content($str_cat);
	my @ents = $tree_page->look_down(_tag => 'div',class=>'spI');
	foreach my $ent_html (@ents)	{
		$i++;
		my $html = $ent_html->as_HTML;
		my $tree_ent = HTML::TreeBuilder->new_from_content($html);
		my $entidade = Spider::Entidade->new();
		#my ($name,$ahref,$end);
		my ($name,$end);
		
		# Nome e url
		# Diferenciacao pois alguns clientes tem sites, outros nao. A forma de exibicao é difrente.
		if ((my $ahref = $tree_ent->look_down(_tag=>'a',class=>'txtT')))	{
			$entidade->nome($ahref->as_text); # Define atributo nome
			$ahref->as_HTML =~ /href="(.*?)"/;
			$entidade->url($1); # Define atributo url
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
		if(my $img = $tree_ent->look_down(_tag=>'img',style=>'border-width:0px;'))	{
			$img->as_HTML =~ /src="(.*?)"/i;
			$entidade->url_logo($url_logo);
		}
		$entidade->dump();
		$entidade->save_csv();
	}
	$self->get_paginacao($str_cat);
	print "Categorias $c Produtos Geral $i".$/;
}
sub get_paginacao {
    my $self = shift;
    my $string = shift;
	my ($form_url) = $string =~ /<form name="aspnetForm" method="post" action="(.*?)"/ig;
	$form_url =~ s/amp;//g;
	$self->{page}++; # Diferente na primeira pagina
	use WWW::Mechanize;
	my $mech = WWW::Mechanize->new();
	$mech->get("http://www.guiamais.com.br/".$form_url);
	$mech->form_number(1);
	if ($self->{page}>0)	{
		$mech->click('ctl00$C1$pag1$ctl01');
	}
	else	{
		$mech->click('ctl00$C1$pag1$ctl02');
	}
	$self->get_dados_ent($mech->content);
}


1;
