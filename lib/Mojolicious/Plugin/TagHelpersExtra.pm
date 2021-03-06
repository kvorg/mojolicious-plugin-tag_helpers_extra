package Mojolicious::Plugin::TagHelpersExtra;

use strict;
use warnings;

use base 'Mojolicious::Plugin';

our $VERSION = '0.0001';

use Mojo::ByteStream;

# Clean up cb syntax for tables.
# Improve twisetd cb tests for tables.
# Add nested table example using blocks.

# QUOTE HERE
sub register {
    my ($self, $app) = @_;

    # Add "link_to_here" helper (with query)
    $app->helper(
        link_to_here => sub {
            my $c  = shift;
            my $pp = $c->req->params;

            # replace
            if (defined $_[0] and ref $_[0] eq 'HASH') {
                while (my ($param, $value) = each %{$_[0]}) {
                    $pp->remove($param);
                    $pp->append($param => $value);
                }
                shift;
            }

            # add
            elsif (defined $_[0] and ref $_[0] eq 'ARRAY') {
                $pp->append(shift @{$_[0]} => shift @{$_[0]}) while @{$_[0]};
                shift;
            }

            # default link text
            unless (@_ and ref $_[-1] eq 'CODE') {
                my $cb = sub { return 'link' };
                push @_, $cb;
            }
            $self->_tag('a', href => $c->req->url->query($pp), @_);
        }
    );

    # Add "check_box_x" helper
    # (with multi support and checked attribute for default)
    $app->helper(
        check_box_x => sub {
            $self->_input_x(
                shift, shift,
                value => shift,
                type  => 'checkbox',
                @_
            );
        }
    );

    # Add "radio_button_x" helper
    # (with multi support and checked attribute for default)
    $app->helper(
        radio_button_x => sub {
            $self->_input_x(
                shift, shift,
                value => shift,
                type  => 'radio',
                @_
            );
        }
    );

    # Add "table" helper
    $app->helper(
        table => sub {
            my $c = shift;
            my $data = defined $_[0] && ref $_[0] eq 'ARRAY' ? shift : undef;

            # Callback (but not sub=> argument)
            my $cb =
                 defined $_[-1]
              && ref($_[-1]) eq 'CODE'
              && (defined $_[-2] and $_[-2] ne 'sub') ? pop @_ : undef;

            pop if @_ % 2;
            my %attr = @_;

            # special attributes
            my $caption_text;
            $caption_text = $attr{caption} and delete $attr{caption}
              if exists $attr{caption};
            my $head;
            $head = $attr{head} and delete $attr{head}
              if exists $attr{head};
            my $foot;
            $foot = $attr{foot} and delete $attr{foot}
              if exists $attr{foot};
            my $ch;
            $ch = $attr{ch} and delete $attr{ch}
              if exists $attr{ch};
            my $rh;
            $rh = $attr{rh} and delete $attr{rh}
              if exists $attr{rh};
            my $rcb;
            $rcb = $attr{rcb} and delete $attr{rcb}
              if exists $attr{rcb};
            my $ccb;
            $ccb = $attr{ccb} and delete $attr{ccb}
              if exists $attr{ccb};
            my $sub = sub { return undef; };
            $sub = $attr{sub} and delete $attr{sub}
              if exists $attr{sub};

            # Row callback
            my $colcb = sub {
                my $row_no = shift;
                my $data   = shift;
                my $tag    = shift || 'td';
                my $row    = '';

                for (my $col_no = 0; $col_no < @$data; $col_no++) {
                    my $attr;
                    next
                      if defined $data->[$col_no]
                          and ref $data->[$col_no] eq 'HASH';
                    $attr = $data->[$col_no + 1]
                      if defined $data->[$col_no + 1]
                          and ref $data->[$col_no + 1] eq 'HASH';
                    my $t;
                    $t = 'th'
                      if ( ($col_no == 0 and defined $rh)
                        or (defined $row_no and $row_no == 0 and defined $ch)
                      );
                    $t ||= $tag;

                    # Cell callbacks
                    if (defined $attr->{cb} and ref $attr->{cb} eq 'CODE') {
                        my $args = {
                            tag        => $t,
                            row_no     => $row_no,
                            col_no     => $col_no,
                            value      => $data->[$col_no],
                            attributes => $attr ? $attr : {},
                        };
                        $args = $attr->{cb}->($args);
                        if (defined $args) {
                            $t               = $args->{tag};
                            $data->[$col_no] = $args->{value};
                            $attr            = $args->{attributes};
                        }
                    }

                    # Cell cb
                    if (defined $ccb and ref $ccb eq 'CODE') {
                        my $args = {
                            tag        => $t,
                            row_no     => $row_no,
                            col_no     => $col_no,
                            value      => $data->[$col_no],
                            attributes => $attr ? $attr : {},
                        };
                        $args = $ccb->($args);
                        if (defined $args) {
                            $t               = $args->{tag};
                            $data->[$col_no] = $args->{value};
                            $attr            = $args->{attributes};
                        }
                    }

                    $row .= $self->_tag($t, %$attr,
                        sub { return $data->[$col_no] });
                }
                return "\n$row\n";
            };

            my $extras = '';
            if ($caption_text or $cb) {
                $extras .= "\n";
                $extras .= $self->_tag(
                    'caption',
                    sub {
                        ($caption_text ? $caption_text : '')
                          . ($caption_text && $cb ? ' ' : '')
                          . ($cb ? $cb->() : '');
                    }
                );
            }
            $extras
              .= "\n"
              . $self->_tag('head', sub { $colcb->(undef, $head, 'th') })
              if $head;
            $extras
              .= "\n"
              . $self->_tag('foot', sub { $colcb->(undef, $foot, 'th') })
              if $foot;

            # Rows
            my $rows = $extras;
            my $subrow;

            for (
                my $row_no = 0;
                ($data ? ($row_no < @$data) : ($subrow = $sub->()));
                $row_no++
              )
            {
                my $attr;
                my $row;

                # Sub returns the whole data?
                if (    not $data
                    and $subrow
                    and ref $subrow eq 'ARRAY'
                    and defined $subrow->[0]
                    and ref $subrow->[0] eq 'ARRAY'
                    and
                    (scalar @$subrow > 1 or (ref $subrow->[0][1] ne 'HASH')))
                {
                    $sub = sub { undef; };
                    $data = $subrow;
                }

                # Static table data
                if (defined $data and defined $data->[$row_no]) {
                    next if ref $data->[$row_no] ne 'ARRAY';    # attributes
                    $attr = $data->[$row_no + 1]
                      if defined $data->[$row_no + 1]
                          and ref $data->[$row_no + 1] eq 'HASH';
                    $row = $data->[$row_no];
                }

                # Iterator callback
                else {
                    last unless $subrow and ref $subrow eq 'ARRAY';

                    # Single line with attributes
                    if ($subrow->[0] eq 'ARRAY') {
                        $row  = $subrow->[0];
                        $attr = $subrow->[1]
                          if defined $subrow->[1]
                              and ref $subrow->[1] eq 'HASH';
                    }

                    # No attrs
                    else {
                        $row = $subrow;
                    }
                }

                my $t = 'tr';

                # Direct cb
                if (defined $attr->{cb} and ref $attr->{cb} eq 'CODE') {
                    my $args = {
                        tag        => $t,
                        row_no     => $row_no,
                        col_no     => 0,
                        value      => $row,
                        attributes => $attr ? $attr : {},
                    };
                    $args = $attr->{cb}->($args);
                    if (defined $args) {
                        $t    = $args->{tag};
                        $row  = $args->{value};
                        $attr = $args->{attributes};
                    }
                }

                # Row cb
                if (defined $rcb and ref $rcb eq 'CODE') {
                    my $args = {
                        tag        => $t,
                        row_no     => $row_no,
                        col_no     => 0,
                        value      => $row,
                        attributes => $attr ? $attr : {},
                    };
                    $args = $rcb->($args);
                    if (defined $args) {
                        $t    = $args->{tag};
                        $row  = $args->{value};
                        $attr = $args->{attributes};
                    }
                }

                $rows .= "\n"
                  . $self->_tag(
                    $t,
                    $attr ? %$attr : (),
                    sub { $colcb->($row_no, $row) }
                  );
            }

            return $self->_tag(
                'table', %attr,
                sub {
                    return "$rows\n";
                }
            );
        }
    );
}

sub _input_x {
    my $self = shift;
    my $c    = shift;
    my $name = shift;

    # Callback
    my $cb = defined $_[-1] && ref($_[-1]) eq 'CODE' ? pop @_ : undef;
    pop if @_ % 2;

    my %attrs = @_;

    my $value = $attrs{value};
    my %v;
    if ($attrs{type} eq 'radio') {
        %v = (scalar $c->param($name) => 1) if $c->param($name);
    }

    # checkbox
    else {
        %v = map { $_, 1 } ($c->param($name));
    }
    if (exists $v{$value}) {
        $attrs{checked} = 'checked';
    }

    elsif (scalar $c->param($name)) {
        delete $attrs{checked};
    }
    return $self->_tag('input', name => $name, %attrs, $cb || ());
}

# Stolen from 'Mojolicious::Plugin::TagHelpers'
sub _tag {
    my $self = shift;
    my $name = shift;

    # Callback
    my $cb = defined $_[-1] && ref($_[-1]) eq 'CODE' ? pop @_ : undef;
    pop if @_ % 2;

    # Tag
    my $tag = "<$name";

    # Attributes
    my %attrs = @_;
    for my $key (sort keys %attrs) {
        my $value = $attrs{$key};
        $tag .= qq/ $key="$value"/;
    }

    # Block
    if ($cb) {
        $tag .= '>';
        $tag .= $cb->();
        $tag .= "<\/$name>";
    }

    # Empty element
    else { $tag .= ' />' }

    # Prevent escaping
    return Mojo::ByteStream->new($tag);
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::TagHelpersExtra - Extra Tag Helpers Plugin

=head1 SYNOPSIS

    # Mojolicious
    $self->plugin('tag_helpers_extra');

    # Mojolicious::Lite
    plugin 'tag_helpers_extra';

=head1 DESCRIPTION

L<Mojolicous::Plugin::TagHelpersExtra> is a collection of additional
HTML5 tag helpers for L<Mojolicious>.  Note that this module hopes to
be sublimated into L<Mojolicous::Plugin::TagHelpers> without warning!

=head2 Helpers

=over 4

=item link_to_here

    <%= link_to_here %>
    <%= link_to_here begin %>Reload<% end %>
    <%= link_to_here (class => 'link') => begin %>Reload<% end %>
    <%= link_to_here { page=>++$self->param('page') } => begin %>Next<% end %>
    <%= link_to_here [ colour=>'blue', colour=>'red'] => begin %>More colours<% end %>

Generate link to the current URL, including the query.

Hashref arguments replace, arrayref arguments append query values.

Remaining arguments are used as attribute name/value pairs for the tag.

=item check_box_x

    <%= check_box_x 'languages', value => 'perl', checked => 1 %>
    <%= check_box_x 'languages', value => 'php' %>
    <%= check_box_x 'languages', value => 'pyton' %>
    <%= check_box_x 'languages', value => 'ruby' %>

Generate a checkbox input element with value, and parse parameters
according to multiple choices.

You can use the attribute 'checked' to set a default value for the
form, to be overruled if a parameter of the same name is set.

=item radio_x

    <%= radio_x 'languages', value => 'perl', checked => 1 %>
    <%= radio_x 'languages', value => 'php' %>
    <%= radio_x 'languages', value => 'pyton' %>
    <%= radio_x 'languages', value => 'ruby' %>

Generate a radio button input element with value and parse parameters
accoring to multiple choices.

You can use the attribute 'checked' to set a default value for the
form, to be overruled if a parameter of the same name is set.

The syntax is exactly the same as for the C<check_box_x> helper.

=item table

    <%= table [
                [ qw/Name A B C/ ],
                [ 'John', 3, 5, 6 ],
                [ 'Mary', 1, 3, 8 ]
              ],
               ch =>1,  rh => 1 %>
    <%= table [ [ 3, 5, 6 ], [ 1, 3, 8 ] ],
         class => 'numbers'
         caption => 'Some numbers'%>
    <%= table [ [ 3, 5, 6 ], [ 1, 3, 8 ] ]
         => begin %>Some <i>numbers</i>!<% end%>
    <%= table [ [ 'John', 3, 5, 6 ], [ 'Mary', 1, 3, 8 ] ],
         head => [ qw/Name A B C/ ] %>
    <%= table [ [ 'John', 3, , 5 => {class=>'win'}, 6 ],
                [ 'Mary', 1, 'N/A' => {colspan=>2} ] => {class=>'incomplete'} ] %>
    <%= table head => [ qw/Name A B C/ ] sub => sub { $query->next_line() } %>
    <%= table $query->all_lines() class=>'Direct from sub.' %>

Generate a table from a reference to an array of array rows, or,
alternatively, an array ref generating subroutine reference specified
in the C<sub> attribute. The subroutine reference must either return
the whole table, or return one line at a time, returning undef when
done. Note that a direct subroutine will not do, a reference is required.

Attributes are supported, and apply only to the table itself.

There are several special attributes: C<caption> sets the caption for
the table, and is exacly the same as specifying the caption in the
block following the helper. C<head> and C<foot> is used to pass the
header and footer row of the table, respectively. If C<ch>
or C<rh> is set, the first row or column is treated as row/column
header, respectively.

Attributes for the rows and cells are specified as a hash reference,
applying to the previous row or cell element.

There is no support for column groups, nested tables or attributes on
caption, header and footer.

It is possible, however, to modify the default behaviour and even
insert additional tags by declaring callback subroutines as
attributes. Use C<cb> on any row or cell. Use C<rcb> and C<ccb> on the
table to declare row and cell callbacks for every row and cell, to be
used even on caption, header and footer.  Every callback gets called
with a hash reference, and should return the same reference modified
or undef for no action:

  sub {
   my $arg = shift;
   my $tag = $arg->{tag};          # rows: tr, head, foot; cells: th, td
   my $value = $arg->{value};
   my $attrs = $arg->{attributes}; # hash reference
   my $attrs = $arg->{row_no};     # undef in head and foot
   my $attrs = $arg->{col_no};     # 0 in rows
  ... do work, modfiying %$arg
   return undef if $fail;
   return $arg;
  }

The generic call back and will get called in both ways, for every cell
and row. The order of execution is: cell attribute callback, cell
callback, row attribute callback, row callback.

Examples:

  # Stripes and red negative values with classes
  <%= table $data, rcb=> sub {my $x = shift; $x->{attributes}{class} = 'odd' unless $x->{row_no} % 2; return $x; }, ccb=> sub {my $x =shift; $x->{attributes}{class} = 'red' unless $x->{value} >= 0; return $x;} %>

=back

=head1 METHODS

L<Mojolicious::Plugin::TagHelpersExtra> inherits all methods from
L<Mojolicious::Plugin> and implements the following new one:

=head2 C<register>

    $plugin->register;

Register helpers in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious::Plugin::TagHelpers>, L<Mojolicious>,
L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
