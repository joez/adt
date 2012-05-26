# author: joe.zheng

package Adt::Reporter;
use Joez::Base 'Joez::Log';

use Carp 'croak';
use Fcntl ':flock';
use IO::File;
use Digest::MD5;

use Adt::Output;

has 'path';
has _output_pool => sub { [] };
has _output_seen => sub { +{} };

sub new {
  my $self = shift->SUPER::new(@_);
  $self->on(
    report => sub {
      my $self = shift;
      return unless my $handle = $self->handle;

      flock $handle, LOCK_EX;
      $handle->syswrite($_) foreach @_;
      flock $handle, LOCK_UN;
    }
  );
  return $self;
}

sub prepare { shift->reset_stash }

sub _hash { Digest::MD5::md5(@_) }

sub feed {
  my ($self, $parser, $rule) = @_;
  my ($pool, $seen) = ($self->_output_pool, $self->_output_seen);

  my ($before, $after) = $rule->fetch_context($parser);
  my $line = $parser->current_line;
  my $info = $parser->current_info;
  my $hash = _hash(@{$before}, $line, @{$after});

  unless ($seen->{$hash}) {
    $seen->{$hash}++;

    my $output = Adt::Output->new(
      {
        rule         => $rule,
        file         => $parser->file,
        hash         => $hash,
        time         => $parser->file_time,
        lineno       => $parser->curno,
        line         => $line,
        lines_before => $before,
        lines_after  => $after,
      }
    );

    push @{$pool}, $output;
  }

  return $self;
}

sub report {
  my $self = shift;

  foreach my $output (sort { $a->compare($b) } @{$self->_output_pool}) {
    $self->emit(report => $output);
  }

  return $self;
}

sub done {
  shift->report->_output_pool(undef)->_output_seen(undef);
}

1;
__END__
