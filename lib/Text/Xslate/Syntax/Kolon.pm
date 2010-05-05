package Text::Xslate::Syntax::Kolon;
use 5.010;
use Mouse;

extends qw(Text::Xslate::Parser);

no Mouse;
__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Text::Xslate::Syntax::Kolon - The default template syntax

=head1 SYNOPSIS

    use Text::Xslate;
    my $tx = Text::Xslate->new(
        syntax => 'Kolon', # optional
    );

    print $tx->render_string(
        'Hello, <: $dialect :> world!',
        { dialect => 'Kolon' }
    );

=head1 DESCRIPTION

Kolon is the default syntax, using C<< <: ... :> >> tags and C<< : ... >> line code.

=head1 SYNTAX

=head2 Variable access

    <: $var :>
    <: $var.0 :>
    <: $var.field :>
    <: $var.accessor :>

    <: $var["field"] :>
    <: $var[0] :>

Variables may be HASH references, ARRAY references, or objects.
Because C<$var.field> and C<$var["field"]> are the same semantics,
C<< $obj["accessor"] >> syntax may be call object methods.

If I<$var> is an object instance, you can call its methods.

    <: $var.foo() :>
    <: $var.foo(1, 2, 3) :>

=head2 Loops

There are C<for> and C<while> loops.

    : # $data must be an ARRAY reference
    : for $data -> $item {
        [<: $item.field :>]
    : }

    : # $obj must be an iteratable object
    : while $obj.fetch -> $item {
        [<: $item.field :>]
    : }

=head2 Conditional statements

if-then-else statement:

    : if $var == nil {
        $var is nil.
    : }
    : else if $var != "foo" {
        $var is not nil nor "foo".
    : }
    : else {
        $var is "foo".
    : }

    : if( $var >= 1 && $var <= 10 ) {
        $var is 1 .. 10
    : }

    : $var.value == nil ? "nil" : $var.value

Note that C<elsif> for C<else if> is also okey.

switch statement (B<not yet implemented>):

    : given $var -> $it {
    :   when "foo" {
            it is foo.
    :   }
    :   when $it == "bar" or $it == "baz" {
            it is bar or baz.
    :   }
    :   default {
            it is not foo nor bar.
        }
    :

=head2 Expressions

Relational operators (C<< == != < <= > >= >>):

    : $var == 10 ? "10"     : "not 10"
    : $var != 10 ? "not 10" : "10"

Note that C<==> and C<!=> are similar to Perl's C<eq> and C<ne> except that
C<$var == nil> is true B<iff> I<$var> is uninitialized, while other
relational operators are numerical operators.

Arithmetic operators (C<< + - * / % min max >>):

    : $var * 10_000
    : ($var % 10) == 0
    : 10 min 20 min 30 # 10
    : 10 max 20 max 30 # 30

Logical operators (C<< ! && || // not and or >>)

    : $var >= 0 && $var <= 10 ? "ok" : "too smaller or too larger"
    : $var // "foo" # as a default value

String operators (C<< ~ >>)

    : "[" ~ $var ~ "]" # concatination

Operator precedence is the same as Perl's:

    . () []
    * / %
    + - ~
    < <= > >=
    == !=
    |
    &&
    || // min max
    ?:
    not
    and
    or

=head2 Functions and filters

Once you have registered functions, you can call them with C<()> or C<|>.

    : f()        # without args
    : f(1, 2, 3) # with args
    : 42 | f     # the same as f(42)

Dynamic functions/filters:

    # code
    sub mk_indent {
        my($prefix) = @_;
        return sub {
            my($str) = @_;
            $str =~ s/^/$prefix/xmsg;
            return $str;
        }
    }
    my $tx = Text::Xslate->new(
        function => {
            indent => \&mk_indent,
        },
    );

    :# template
    : $value | indent("> ")
    : indent("> ")($value)

=head2 Template inclusion

Template inclusion is a traditional way to extend templates.

    : include "foo.tx"

Xslate templates may be recursively included, but including depth is
limited to 100.

=head2 Template cascading

Template cascading is another way to extend templates other than C<include>.

    : cascade myapp::base
    : cascade myapp::base with myapp::role1, myapp::role2
    : cascade with myapp::role1, myapp::role2

You can extend templates with block modifiers.

Base templates F<myapp/base.tx>:

    : block title -> { # with default
        [My Template!]
    : }

    : block body -> {;} # without default

Another derived template F<myapp/foo.tx>:

    : # cascade "myapp/base.tx" is also okey
    : cascade myapp::base
    : # use default title
    : around body -> {
        My template body!
    : }

Yet another derived template F<myapp/bar.tx>:

    : cascade myapp::foo
    : around title -> {
        --------------
        : super
        --------------
    : }
    : before body -> {
        Before body!
    : }
    : after body -> {
        After body!
    : }

Then, Perl code:

    my $tx = Text::Xslate->new( file => 'myapp/bar.tx' );
    $tx->render({});

Output:

        --------------
        [My Template!]
        --------------

        Before body!
        My template tody!
        After body!

You can also cascade templates just like Moose's roles:

    : cascade myapp::base with myapp::role1, myapp::role2

You can omit the base template.

Given a file F<myapp/hello.tx>:

    : around hello -> {
        --------------
        : super
        --------------
    : }

Then the main template:

    : cascade with myapp::hello

    : block hello -> {
        Hello, world!
    : }

Output:

        --------------
        Hello, world!
        --------------

=head2 Macro blocks

    : macro add ->($x, $y) {
    :   $x + $y;
    : }
    : add(10, 20)

    : macro signeture -> {
        This is foo version <: $VERSION :>
    : }
    : signeture()

    : macro factorial -> $x {
    :   $x == 0 ? 1 : $x * factorial($x-1)
    : }

Note that return values of macros are values that their routines renders.
That is, macros themselves output nothing.

=head1 SEE ALSO

L<Text::Xslate>

=cut
