# author: joe.zheng

package Joez::Base;

use Mojo::Base -base;
use Joez::Log;

has log => sub { Joez::Log->new };

sub stash { shift->_dict(stash => @_) }

sub reset_stash { shift->_dict(stash => {}) }

sub _dict {
  my ($self, $name) = (shift, shift);

  # Hash
  $self->{$name} ||= {};
  return $self->{$name} unless @_;

  # Get
  return $self->{$name}->{$_[0]} unless @_ > 1 || ref $_[0];

  # Set
  my $values = ref $_[0] ? $_[0] : {@_};
  $self->{$name} = {%{$self->{$name}}, %$values};

  return $self;
}

1;
__END__
