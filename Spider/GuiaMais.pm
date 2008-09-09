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
			my ($name,$url,$end);
			# Diferenciacao pois alguns clientes tem sites, outros nao. A forma de exibicao é difrente.
			if (($url = $tree_ent->look_down(_tag=>'a',class=>'txtT')))	{
				$entidade->nome($url->as_text);
				$url->as_HTML =~ /href="(.*?)"/;
				$entidade->url($1);
			}
			else	{
				$name = $tree_ent->look_down(_tag=>'span',class=>'txtT');
				$name = $name->as_text;
				if (ref($name))	{
					$entidade->nome($name->as_text);
				}
				else{$entidade->nome($name);}
			}

			# Campos que vou capturar:
			# Empresa,endereç(rua e bairro),telefone,url,url_logotipo,categoria.
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
			HTML::Entities::decode_entities($end);
			$entidade->end($end);
			$entidade->dump();
			$entidade->save_csv();
		}
	}
	print "Categorias $c Produtos Geral $i".$/;
}
1;
