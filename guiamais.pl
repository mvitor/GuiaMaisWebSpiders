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
foreach (@cats)	{
	my ($cat_href) = $_->as_HTML =~ /href="(.*?)"/;
	my $cat_name = $_->as_text;
	$spider->set_cats($cat_name,URL.$cat_href);
	last;
}

# Faz captura de dados através de método get_dados
$spider->get_dados_cat();

	


