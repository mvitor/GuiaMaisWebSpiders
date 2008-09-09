#!/usr/bin/perl

use strict;
use warnings;
use Spider;
use HTML::TreeBuilder;
use Data::Dumper;
use constant URL => 'http://www.guiamais.com.br/';

my $spider = Spider->new(name=>'guiamais');

my $string = $spider->obter(URL,1);

my $tree = HTML::TreeBuilder->new_from_content($string);
my @cats = $tree->look_down(_tag => 'a',class=>'lnk1L');

foreach (@cats)	{
	my ($cat_href) = $_->as_HTML =~ /href="(.*?)"/;
	my $cat_name = $_->as_text;
	$spider->set_cats($cat_name,URL.$cat_href);
}

$spider->get_dados();

sub get_dados 	{
	my ($self) = @_;
	foreach my $cat ($spider->cats)	{
		my $str_cat = $self->obter($cat->{href},1);
		my $tree_page = HTML::TreeBuilder->new_from_content($str_cat);
		my @ents = $tree_page->look_down(_tag => 'div',class=>'spI');
		foreach my $entidade (@ents)	{
			my $html = $entidade->as_HTML;
			my $tree_ent = HTML::TreeBuilder->new_from_content($html);
			my ($name,$link,$end);
			
			# Diferenciacao pois alguns clientes tem sites, outros nao. A forma de exibicao Ã© difrente.
			if (($link = $tree_ent->look_down(_tag=>'a',class=>'txtT')))	{
				$name = $link->as_text;
				$link->as_HTML =~ /href="(.*?)"/;
				$link = $1;
			}
			else	{
				$name = $tree_ent->look_down(_tag=>'span',class=>'txtT');
				$name = $name->as_text;
			}

			# Campos que vou capturar:
			# Empresa,endereÃ§(rua e bairro),telefone,url,url_logotipo,categoria.
			print "$cat->{name}".$/;
			print "NAME: ".$name.$/;	
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
			print "$cat->{name} $name, $end, $link".$/x3;
		}
	}
}	
sub cats	{
	my ($self) = @_;
	return @{$spider->{categorias}};
}
sub set_cats	{
	my ($self,$cat_name,$cat_href)	= @_;
	push(@{$spider->{categorias}}, {name=>$cat_name,href=>$cat_href});
}

