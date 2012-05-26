# author: joe.zheng

package Joez::Log;
use Joez::Base 'Mojo::Log';

use Carp 'croak';
use Data::Dumper;

has dumper => sub { Data::Dumper->new([])->Terse(1)->Indent(0)->Pair(':') };

has handle => sub {
  my $self = shift;

  # File
  if (my $path = $self->path) {
    croak qq{Can't open log file "$path": $!}
      unless open my $file, '>>', $path;
    return $file;
  }

  # STDERR
  return \*STDERR;
};

sub format {
  my ($self, $level, @msgs) = @_;

  my $msg = @msgs < 1 ? '' : @msgs == 1
    && !ref $msgs[0] ? $msgs[0] : $self->_dump(@msgs);

  return '[' . localtime() . "] [$level] " . $msg . "\n";
}

sub _dump { join ', ', shift->dumper->Values(\@_)->Dump }

1;
__END__
