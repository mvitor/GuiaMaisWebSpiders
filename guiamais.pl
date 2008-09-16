#!/usr/bin/perl

use strict;
use warnings;
use HTML::TreeBuilder;
use Spider::GuiaMais;
use Data::Dumper;
use constant URL =>  "http://www.guiamais.com.br/";
# Recebe home
my $spider = Spider::GuiaMais->new(nome=>'guiamais');
my $string = $spider->obter(URL); #Recebe home

# Captura categoria
#$spider->get_cats($string);

# Faz captura de dados das categorias gravadas 
#$spider->get_dados();

$spider->get_palavra_chave($string);


	


