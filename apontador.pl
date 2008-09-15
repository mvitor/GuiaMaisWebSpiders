#!/usr/bin/perl

use strict;
use warnings;
use HTML::TreeBuilder;
use Spider::Apontador;
use Data::Dumper;
use constant URL =>  "http://www.apontador.com.br/";

# Recebe home
my $spider = Spider::Apontador->new(nome=>'apontador');
my $string = $spider->obter(URL."home/categorias.html"); # home c/ as categorias

# Captura categorias
$spider->get_cats($string);

# Faz captura de dados das categorias gravadas 
$spider->get_dados();

	


