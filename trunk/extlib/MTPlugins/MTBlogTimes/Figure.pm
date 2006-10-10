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

package MTPlugins::MTBlogTimes::Figure;

# Perl Module Usages
use strict;
use warnings;

use Date::Calc qw(:all);

use MTPlugins::MTBlogTimes::ObjectTemplate;

# Inheritance Declarations
@MTPlugins::MTBlogTimes::Figure::ISA = qw ( MTPlugins::MTBlogTimes::ObjectTemplate );

# Attribute Storage Object
attributes qw (basename bordercolor calendaric_values cscale debug denominator dimension extension figure fillcolor linecolor location map mode name padding printnth swidth sheight text textcolor title uri labels values);

# possible text attribute values
my @arg_text = qw(on off);
my @arg_cvalues = qw(day week month year days_in_month week_of_year monday_of_week date_start date_end);
my @arg_dimension = qw(height width);

# ---------------------------------------------------------------------------
# Custom method to add calendaric values
# ---------------------------------------------------------------------------

sub addToCalendaricValues {
    my $obj = shift;
    my %calendaric_values = $obj->SUPER::get_attribute("calendaric_values");
    
    if (@_) {
        my $key = $_[0];
        my $value = $_[1];
        
        grep {/$key/} @arg_cvalues
            or die "Invalid key! The key that you just did provide is not a valid key for the calendaric_values hash.";        
        
        if (exists($calendaric_values{$key})) {
            die "The provided key already exists in the hash!";
        } else {
            $calendaric_values{$key} = $value;
        }
    } else {
        die "Neither a hash key nor a hash value was provided!"
    }
}

# ---------------------------------------------------------------------------
# Custom method to remove calendaric values
# ---------------------------------------------------------------------------

sub deleteFromCalendaricValues {
    my $obj = shift;
    my %calendaric_values = $obj->SUPER::get_attribute("calendaric_values");
    
    if (@_) {
        my $key = $_[0];
        
        grep {/$key/} @arg_cvalues
            or die "Invalid key! The key that you just did provide is not a valid key for the calendaric_values hash.";        
            
        if (exists($calendaric_values{$key})) {
            delete($calendaric_values{$key})
        } else {
            die "The provided key could not be found in the hash!";
        }
    } else {
        die "Neither a hash key nor a hash value was provided!"
    }
}

# ---------------------------------------------------------------------------
# Custom method to set a specific a calendaric value
# ---------------------------------------------------------------------------

sub setCalendaricValue {
    my $obj = shift;
    my %calendaric_values = $obj->SUPER::get_attribute("calendaric_values");
    
    if (@_) {
        my $key = $_[0];
        my $value = $_[1];
        
        grep {/$key/} @arg_cvalues
            or die "Invalid key! The key that you just did provide is not a valid key for the calendaric_values hash.";        
            
        if (exists($calendaric_values{$key})) {
            $calendaric_values{$key} = $value;
        } else {
            die "The provided key could not be found in the hash!";
        }
    } else {
        die "Neither a hash key nor a hash value was provided!"
    }
}

# ---------------------------------------------------------------------------
# Custom method to retrieve a specific a dimension value
# ---------------------------------------------------------------------------

sub getCalendaricValue {
    my $obj = shift;
    my %calendaric_values = $obj->SUPER::get_attribute("calendaric_values");
    
    if (@_) {
        my $key = $_[0];
        
        grep {/$key/} @arg_cvalues
            or die "Invalid key! The key that you just did provide is not a valid key for the calendaric_avlues hash.";        
            
        if (exists($calendaric_values{$key})) {
            return $calendaric_values{$key};
        } else {
            die "The provided key could not be found in the hash!";
        }
    } else {
        die "You did not provide an appropriate hash key!"
    }
}

# ---------------------------------------------------------------------------
# Custom method to add a dimension value
# ---------------------------------------------------------------------------

sub addToDimension {
    my $obj = shift;
    my %dimension = $obj->SUPER::get_attribute("dimension");
    
    if (@_) {
        my $key = $_[0];
        my $value = $_[1];
        
        grep {/$key/} @arg_dimension
            or die "Invalid key! The key that you just did provide is not a valid key for the dimension hash.";        
        
        if (exists($dimension{$key})) {
            die "The provided key already exists in the hash!";
        } else {
            $dimension{$key} = $value;
        }
    } else {
        die "Neither a hash key nor a hash value was provided!"
    }
}

# ---------------------------------------------------------------------------
# Custom method to remove a dimension value
# ---------------------------------------------------------------------------

sub deleteFromDimension {
    my $obj = shift;
    my %dimension = $obj->SUPER::get_attribute("dimension");
    
    if (@_) {
        my $key = $_[0];
        
        grep {/$key/} @arg_dimension
            or die "Invalid key! The key that you just did provide is not a valid key for the dimension hash.";        
            
        if (exists($dimension{$key})) {
            delete($dimension{$key})
        } else {
            die "The provided key could not be found in the hash!";
        }
    } else {
        die "Neither a hash key nor a hash value was provided!"
    }
}

# ---------------------------------------------------------------------------
# Custom method to set a specific a dimension value
# ---------------------------------------------------------------------------

sub setDimension {
    my $obj = shift;
    my %dimension = $obj->SUPER::get_attribute("dimension");
    
    if (@_) {
        my $key = $_[0];
        my $value = $_[1];
        
        grep {/$key/} @arg_dimension
            or die "Invalid key! The key that you just did provide is not a valid key for the dimension hash.";        
            
        if (exists($dimension{$key})) {
            $dimension{$key} = $value;
        } else {
            die "The provided key could not be found in the hash!";
        }
    } else {
        die "Neither a hash key nor a hash value was provided!"
    }
}

# ---------------------------------------------------------------------------
# Custom method to retrieve a specific a dimension value
# ---------------------------------------------------------------------------

sub getDimension {
    my $obj = shift;
    my %dimension = $obj->SUPER::get_attribute("dimension");
    
    if (@_) {
        my $key = $_[0];
        
        grep {/$key/} @arg_dimension
            or die "Invalid key! The key that you just did provide is not a valid key for the dimension hash.";        
            
        if (exists($dimension{$key})) {
            return $dimension{$key};
        } else {
            die "The provided key could not be found in the hash!";
        }
    } else {
        die "You did not provide an appropriate hash key!"
    }
}

# ---------------------------------------------------------------------------
# Custom text method to ensure that the text attribute is only set to on/off
# ---------------------------------------------------------------------------

sub text {
    my $obj = shift;
    my $text = $obj->SUPER::get_attribute("text");
    
    if (@_) {
        grep {/$_[0]/} @arg_text
            or die "Invalid value! Text could only be set to either on or off.";
        
        if ($text) {
            $obj->set_attribute("text", $_[0]);
            #die "Text attribute already set! No need to set it twice. Current text: $text";
        } else {
            $obj->set_attribute("text", $_[0]);
        }
    }
    
    $text;
}

# ---------------------------------------------------------------------------
# DRAW METHOD (needs to be implemented by any figure object)
# ---------------------------------------------------------------------------

sub draw {
    # NOP
}

# ---------------------------------------------------------------------------
# SAVE METHOD: Saves the figure to a file.
# ---------------------------------------------------------------------------

sub save {
    # NOP
}

# ---------------------------------------------------------------------------
# public helper method which converts a number to the name of a month/day.
# ---------------------------------------------------------------------------

sub dateToText {
    my %args = (
        date => 0,
        @_,
    );
    
    my $obj = shift;    
    my $string;
    my $_cal_values_ref = $obj->SUPER::calendaric_values();
    my %_cal_values = %$_cal_values_ref;
    my $month = $_cal_values{month};
    my $year = $_cal_values{year};
    
    $string = Day_of_Week_Abbreviation($args{date}) if ($obj->SUPER::mode() eq 'weekly' && $args{date} > 0);
    $string = Day_of_Week_Abbreviation(Day_of_Week($year, $month, $args{date})) if ($obj->SUPER::mode() eq 'monthly' && $args{date} > 0);
    $string = Month_to_text($args{date}) if ($obj->SUPER::mode() eq 'yearly' && $args{date} > 0);
    
    $string = $args{date} if !$string;
    $string;
}

# ---------------------------------------------------------------------------
# Adds a label string to the label array.
# ---------------------------------------------------------------------------

sub addLabel {
    my $obj = shift;
    my @labels = $obj->SUPER::get_attribute("labels");
    
    if (@_) {
        $#labels++;
        $labels[$#labels] = $_[0];
    } else {
        die "Can't add a NULL value to an arry!";
    }
}

# ---------------------------------------------------------------------------
# Removes a label indicated by a specific value from the label arry.
# ---------------------------------------------------------------------------

sub removeLabel {
    my $obj = shift;
    my @labels = $obj->SUPER::get_attribute("labels");
    my @new_labels;

    if (@_) {
        grep {/$_[0]/} @labels
            or die "You did specify an array element to be removed that is not contained within the labels array!!";
        
        foreach my $label (@labels) {
            if ($label eq $_[0]) {
                # NOP
            } else {
                $new_labels[$#new_labels] = $_[0];
                $#new_labels++;
            }
        }
        
        $obj->SUPER::set_attribute("labels", @new_labels);
    }
    else {
        die "You did not provide any value to be removed!";
    }
}

# ---------------------------------------------------------------------------
# Some helper methods ...
# ---------------------------------------------------------------------------

sub round      { return sprintf("%.0f",$_[1]); }
sub to_minutes { return (((substr($_[1],0,2))*60)+(substr($_[1],2,2))); }
sub to_month   {
    my $obj = shift;
    my $year = substr($_[0],0,4);
    my $month = substr($_[0],4,2);
    my $dim = Days_in_Month($year, $month);
    my $day = substr($_[0],6,2);

    $month -= 1 if ($obj->mode() eq 'yearly');
    
    return ($month + ($day / $dim));
}
sub month2str  { return ('JANUARY','FEBRUARY','MARCH','APRIL','MAY','JUNE',
			 'JULY','AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER')[$_[1]-1]; }
sub day2str    { return ('MONDAY','THUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY')[$_[1]-1]; }

1;

__END__

=head1 NAME

MTPlugins::MTBlogTimes::Figure - A class to visualize your blog frequency as an image.

=head1 SYNOPSIS

    use MTPlugins::MTBlogTimes::Figure;
    use MTPlugins::MTBlogTimes::FigureFactory;
    $fig = FigureFactory->instance->figure($type);

B<Note:> Do not instantiate a figure object manually! You
should always use the C<MTPlugins::MTBlogTimes::FigureFactory> class to
instantiate a figure object by providing an appropriate figure type. The
following figure types are currently valid:

=over

=item *

'gd' (a GD graphics object)

=item *

'im' (an ImageMagick graphics object)

=item *

'svg' (a SVG vector graphics object)

=item *

'swf' (a macromedia flash compliant graphics object)

=back

=head1 DESCRIPTION

The figure class should be considered as an abstract class. Concrete
implementations are:

=over

=item *

C<MTPlugins::MTBlogTimes::GDFigure>

=item *

C<MTPlugins::MTBlogTimes::IMFigure>

=item *

C<MTPlugins::MTBlogTimes::SVGFigure>

=item *

C<MTPlugins::MTBlogTimes::SWFFigure>

=back 

=head2 Object Attributes

=over

=item basename()

The complete path to the folder which holds the file that represents this image object
(e.g. /path/to/mt/images).

=item bordercolor()

The color of the border which will surround the actual graph object. By default if
no value is supplied, the attribute's value is set to C<#4a4a4a>.

=item dimension()

An array that holds the dimension of the actual graph object (heigth x width). By
default if no value is supplied, the attribute's value is set to C<30> (height) and
C<400> (width).

=item extension()

The file extension of the actual graph object.

=item figure()

The actual graph object.

=item fillcolor()

The color which should be used to fill bars. By default if no value is supplied,
the attribute's value is set to C<#4a4a4a>.

=item linecolor()

The color which should be used to draw vertical lines. By default if no value is
supplied, the attribute's value is set to C<#FFFFFF> (i.e. white).

=item location()

The location to the file that represents the actual graph object. Usually this
is equal to C<basename> + C<name> + C<extension>.

=item name()

The file name of the actual graph object (without the file extension).

=item padding()

This allows one to controll the padding between the timeline bar and the surrounding
border. By default if no value is supplied, the attribute's value is set to C<5px>.

=item text()

Indicates whether illustrative text will be drawn on the graph object or not. By
default if no value is supplied, the attribute's value is set to C<on>.

=item textcolor()

The color which should be used to draw the actual text onto the graph object. By
default if no value is supplied, the attribute's value is set to C<#4a4a4a>.

=item title()

The title of the actual graph object. Usually the title will be rendered as
I<B L O G T I M E S> + I<period to be graphed>.

=item uri()

The uniform resource identifier which can be used to retrieve the graph object
using the I<HTTP> protocol.

=item labels()

An array that holds string objects, each representing a label of the abscissa.

=item values()

An array that holds 1-n blog entries. Those entries will be ploted as lines
onto the abscissa.

=back

=cut