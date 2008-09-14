#!/usr/bin/perl

use strict;
use warnings;
use HTML::TreeBuilder;
use Spider::Apontador;
use Data::Dumper;
use constant URL =>  "http://www.apontador.com.br/";

# Recebe home
my $spider = Spider::Apontador->new(nome=>'apontador');
my $string = $spider->obter(URL."home/categorias.html"); #Recebe home de categorias

################# get_cats
#################

# Captura Categorias e respectivos links
my $tree = HTML::TreeBuilder->new_from_content($string);
my $cat_list = $tree->look_down(_tag => 'div',class=>'categoriasApontador list');
my $tree_cat = HTML::TreeBuilder->new_from_content($cat_list->as_HTML);
my @cats = $tree_cat->look_down(_tag => 'a');


$spider->log('info',@cats.' categorias localizados'); 

# Grava categorias no objeto
foreach (@cats)	{
	my ($cat_href) = $_->as_HTML =~ /href="(.*?)"/;
	my $cat_name = $_->as_text;
	print "$cat_name-$cat_href".$/; 
#	$spider->set_cats($cat_name,URL.$cat_href);
}
################# get_cats
#################

# Faz captura de dados das categorias gravadas 
$spider->get_dados();

	


