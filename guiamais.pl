#!/usr/bin/perl

use strict;
use warnings;
#use Spider;
#use Spider;
use HTML::TreeBuilder;
use Spider::GuiaMais;
use Spider::Entidade;
use Data::Dumper;
use constant URL => 'http://www.guiamais.com.br/';

my $spider = Spider::GuiaMais->new(name=>'guiamais');
my $string = $spider->obter(URL,1);

my $tree = HTML::TreeBuilder->new_from_content($string);
my @cats = $tree->look_down(_tag => 'a',class=>'lnk1L');
foreach (@cats)	{
	my ($cat_href) = $_->as_HTML =~ /href="(.*?)"/;
	my $cat_name = $_->as_text;
	$spider->set_cats($cat_name,URL.$cat_href);
}
sub	get_paginacao	{
#	my = @_;


}
$spider->get_dados();

	


