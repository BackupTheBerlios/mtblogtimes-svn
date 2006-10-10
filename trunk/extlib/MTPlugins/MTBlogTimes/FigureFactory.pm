# ===========================================================================
# MT-Blogtimes: Shows your blog frequency as an image.
# A Plugin for Movable Type
#
# Release '0.1.0'
# February 03, 2005
#
#
# If you find the software useful or even like it, then a simple 'thank you'
# is always appreciated.  A reference back to me is even nicer.  If you find
# a way to make money from the software, do what you feel is right.
#
# Please have a look at the file 'AUTHORS' if you want to reach one of the
# authors by mail or if you want to make a donation.
#
# ===========================================================================
#
# Copyright (c) 2005, Nilesh Chaudhari and Daniel S. Haischt
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
#    * Redistributions of source code must retain the above copyright notice, this
#      list of conditions and the following disclaimer.
#    * Redistributions in binary form must reproduce the above copyright notice,
#      this list of conditions and the following disclaimer in the documentation
#      and/or other materials provided with the distribution.
#    * The names of its contributors may not be used to endorse or promote products
#      derived from this software without specific prior written permission.
#
#    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
#    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
#    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
#    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
#    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
#    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
#    POSSIBILITY OF SUCH DAMAGE.
#
#
# ===========================================================================

package MTPlugins::MTBlogTimes::FigureFactory;

# Perl Module Usages
use strict;
use warnings;

use MTPlugins::MTBlogTimes::ObjectTemplate;
use MTPlugins::MTBlogTimes::Figure;
use MTPlugins::MTBlogTimes::GDFigure;
use MTPlugins::MTBlogTimes::IMFigure;
use MTPlugins::MTBlogTimes::SVGFigure;
use MTPlugins::MTBlogTimes::SWFFigure;

# Inheritance Declarations
@MTPlugins::MTBlogTimes::FigureFactory::ISA = qw (MTPlugins::MTBlogTimes::ObjectTemplate);

# Attribute Storage Object
attributes qw (ffinstance);

# ---------------------------------------------------------------------------
# Does the below code implement a Singleton pattern???
# ---------------------------------------------------------------------------

sub new {
    my $obj = shift;
    return $obj->instance;
}

# ---------------------------------------------------------------------------
# Singleton, required to retrieve an instanve of this factory.
# ---------------------------------------------------------------------------

sub ffinstance {
    my $obj = shift;
    my $instance = $obj->get_attribute("ffinstance");

    if ($instance) {
        # NOP
    } else {
        $instance = MTPlugins::MTBlogTimes::FigureFactory->new();
        $obj->set_attribute("ffinstance", $instance);
    }
    
    return $instance;
}

# ---------------------------------------------------------------------------
# Instantiates a specific figure according to the provided figure type.
# ---------------------------------------------------------------------------

sub figure {
    # TODO: why the heck do I have to use $_[1] instead of $_[0]
    # to retrieve the image type???
    @_ ? my $type = $_[1] : die "No figure type provided!";
    
    my @arg_type = qw(gd im svg swf);
    my $figure;
    
    grep {/$type/} @arg_type
        or die "Invalid figure type provided: $type!";
    
    SWITCH: {
        if ($type eq 'gd') {
            $figure = MTPlugins::MTBlogTimes::GDFigure->new();
            last SWITCH;
        }
        if ($type eq 'im') {
            $figure = MTPlugins::MTBlogTimes::IMFigure->new();        
            last SWITCH;
        }
        if ($type eq 'svg') {
            $figure = MTPlugins::MTBlogTimes::SVGFigure->new();        
            last SWITCH;
        }
        if ($type eq 'swf') {
            $figure = MTPlugins::MTBlogTimes::SWFFigure->new();        
            last SWITCH;
        }
    }
    
    return $figure;
}

1;

__END__

=head1 NAME

MTPlugins::MTBlogTimes::FigureFactory - A class to instantiate different BlogTimes
graphics objects.

=head1 SYNOPSIS

    use MTPlugins::MTBlogTimes::FigureFactory;
    $fig = FigureFactory->instance->figure($type);
    
=head1 DESCRIPTION

The C<MTPlugins::MTBlogTimes::FigureFactory> object should be instantiated
only once per thread. To accomplish this, the I<Singleton> pattern is used, which
in turn requires one to use the C<< $obj->instance() >> method to retrieve a
class instance of C<MTPlugins::MTBlogTimes::FigureFactory>. After having recieved
an appropriate class instance, it would be possible to create a specific figure
type (e.g. a GD graphics object).
