package Spider::GuiaMais;

use base 'Spider';
use Spider::Entidade;

=head2 get_dados

=cut

sub get_dados 	{
	my ($self) = @_;
	my $c=0;
	my $i=0;
	foreach my $cat ($self->cats)	{
		$c++;
		my $str_cat = $self->obter($cat->{href},1);
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
	}
	print "Categorias $c Produtos Geral $i".$/;
}
sub get_paginacao {
    my $self = shift;
    my $link = shift;
    my $string = shift;
    my $str_aux = $string;
    my ($state) = $str_aux =~ m{<input type="hidden" name="__VIEWSTATE" id="__VIEWSTATE" value="(.+?)"}ig;
	if ($string =~ m{a class="next" href="javascript:__doPostBack\('(.+?)','(\d+)'\)">></a><a}io) {
        my $param = $1;
        my $param2 = $2;
        $param =~ s/\$/:/sgio;
		#my $categ_url = $link;
		### URL de Paginacao : $categ_url
	    print "paginando...".$/;
		my $newstring = $self->obter($link,
			{__EVENTTARGET   => $param,
									__EVENTARGUMENT => $param2,
									__VIEWSTATE => $state}
        							);						
	}
    print "paginei...".$/ if $newstring;
	return ($newstring);
}


1;
