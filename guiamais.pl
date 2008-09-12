#!/usr/bin/perl

use strict;
use warnings;
use HTML::TreeBuilder;
use Spider::GuiaMais;
use Data::Dumper;
use constant URL => 'http://www.guiamais.com.br/';

# Recebe home
my $spider = Spider::GuiaMais->new(name=>'guiamais');
my $string = $spider->obter(URL);

# Captura Categorias e respectivos links
my $tree = HTML::TreeBuilder->new_from_content($string);
my @cats = $tree->look_down(_tag => 'a',class=>'lnk1L');

$spider->log('info',@cats.' categorias localizados'); 

# Grava categorias no objeto
foreach (@cats)	{
	my ($cat_href) = $_->as_HTML =~ /href="(.*?)"/;
	my $cat_name = $_->as_text;
	$spider->set_cats($cat_name,URL.$cat_href);
}

# Faz captura de dados das categorias gravadas 
$spider->get_dados_cat();

	


