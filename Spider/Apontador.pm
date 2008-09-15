package Spider::Apontador;

use Entidades::Apontador;
use base 'Spider';

=head2 get_cats

Recebe a home do site e captura as categorias.

=cut

sub get_cats	{
	my ($self,$string) = @_;
	my $tree = HTML::TreeBuilder->new_from_content($string);
	my $cat_list = $tree->look_down(_tag => 'div',class=>'categoriasApontador list');
	my $tree_cat = HTML::TreeBuilder->new_from_content($cat_list->as_HTML);
	my @cats = $tree_cat->look_down(_tag => 'a');
	$self->log('info',@cats.' categorias localizados'); 
	# Grava categorias no objeto
	foreach (@cats)	{
		my ($cat_href) = $_->as_HTML =~ /href="(.*?)"/;
		my $cat_name = $_->as_text;
		$self->set_cats($cat_name,$cat_href);
	}
}

=head2 get_dados

Responsavel por percorrer categorias e invocar métodos necessários para captura das entidades

=cut

sub get_dados	{
	my ($self) = @_;
	$self->check_files;
	foreach my $cat ($self->cats)	{
		my $str_cat = $self->obter($cat->{href});
		$self->{cat} = $cat->{name};
		$self->get_ents($str_cat);
	}
	$self->encerrar;
}
=head2 get_ents

Captura entidades e as percorre

=cut

sub get_ents	{		
	my ($self,$str_cat) = @_;
	my $tree_page = HTML::TreeBuilder->new_from_content($str_cat,);
	my @ents = $tree_page->look_down(_tag => 'div',class=>'results');
	foreach my $ent_html (@ents)	{
		my $html = $ent_html->as_HTML;
		my $tree_ent = HTML::TreeBuilder->new_from_content($html);
		my $ents_html = $tree_page->look_down(_tag => 'a',style=>'font-size:15px');
		my ($url) = $ent_html->as_HTML =~ /href="(.*?)"/sigo;
		$tree_ent = $tree_ent->delete;
		$self->get_ent_details($url);
	}
	$tree_page = $tree_page->delete;
}

=head get_ent_details

Recebe url com entidade faz o parse e insere os detalhes

=cut

sub get_ent_details	{
	my ($self,$url) = @_;
	# Inicia objeto que vai armazenar os dados
	my $entidade = Entidades::Apontador->new();
	$entidade->categoria($self->{cat});
	my $string = $self->obter($url);
	# Separa bloco html com os detalhes
	my $tree = HTML::TreeBuilder->new_from_content($string);
	my $details = $tree->look_down(_tag => 'div',style=>'clear:both;');
	my $def_cont;
	eval  {$det_cont = $details->as_HTML;};
	if ($@) {
		$self->log('error','falha no conteúdo html da descricao do html, arquivo amostra.html salvo p/ amostra');
		open my $fh,'>',$self->{config}->DataDir.'amostra.html';
		print $fh 'URL '.$string;
		next;
	}
	my $telefone;
	while ($det_cont =~ m{<h3>(.*?)</h3>}sig)	{ # Telefone
		$telefone .= ' ' if $telefone;
		$telefone .= $1;
	}
	$entidade->telefone($telefone);
	if($det_cont =~ m{href="(.*)" target="_blank"> http://}si)	{ # Url
		my $url = $1;
		$entidade->url($url);
	}
	if($det_cont =~ m{<h1>(.*?)</h1>}si)	{ # Nome
		my $nome = $1;
		$entidade->nome($nome);
	}
	my $end;
	if ($det_cont =~ m{><br /><b>(.*?)<a}si)	{ # Endereço
		$end = $1;
		$ent_html =~ s/<.*>|\s+//g;
	}
	if($det_cont =~ m{<u>(.*?)</u>}sig)	{ # Cidade, Estado
		$end .= " ".$1;
	}
	$entidade->end($end);
	if($det_cont =~ m{<b class="bold">Tag\(s\): </b>(.*?)<br />}sig)	{ # Tags
		my $tags = $1;
		$entidade->tags($tags);
	}
	$entidade->dump;
	$entidade->save_csv($self->{config});
	$self->SUPER::num_ok();
}
1;
