package EnsEMBL::REST::Role::GeneTree;
use Moose::Role;
use namespace::autoclean;
use Bio::EnsEMBL::Compara::Graph::PhyloXMLWriter;
use IO::String;

sub encode_phyloxml {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $string_handle = IO::String->new();
  my $w = Bio::EnsEMBL::Compara::Graph::PhyloXMLWriter->new(
    -SOURCE => 'Ensembl', -HANDLE => $string_handle
  );
  $w->aligned(1) if $c->request()->param('aligned') || $c->request()->param('phyloxml_aligned');
  my $sequence = $c->request->param('sequence') || $c->request()->param('phyloxml_sequence') || 'protein';
  $w->cdna(1) if $sequence eq 'cdna';
  $w->no_sequences(1) if $sequence eq 'none';
  my $gt = $c->stash->{$stash_key};
  $gt->preload();
  my $root = $gt->root();
  $w->write_trees($root);
  $w->finish();
  $root->release_tree();
  return $string_handle->string_ref();
}

sub encode_nh {
  my ($self, $c, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $gt = $c->stash->{$stash_key};
  my $nh_format = $c->request->param('nh_format') || 'simple';
  $gt->preload();
  my $root = $gt->root();
  my $str = $root->newick_format($nh_format);
  $root->release_tree();
  return \$str;
}

around 'set_content_disposition' => sub {
  my ($orig, $self, $c, $ext, $stash_key) = @_;
  $stash_key ||= 'rest';
  my $gt = $c->stash->{$stash_key};
  my $name = $gt->stable_id();
  return $self->$orig($c, $name, $ext);
};

with 'EnsEMBL::REST::Role::Content';

1;
