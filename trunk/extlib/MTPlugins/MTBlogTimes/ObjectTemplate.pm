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

# ===========================================================================
#                          D I S C L A I M E R
# ===========================================================================
# This particular Perl module and the code contained within was taken from
# the book 'Advanced Perl Programmed', published by O'REILLY & Associates,
# Inc.
# ===========================================================================

package MTPlugins::MTBlogTimes::ObjectTemplate;

require Exporter;
@MTPlugins::MTBlogTimes::ObjectTemplate::ISA = qw(Exporter);
@MTPlugins::MTBlogTimes::ObjectTemplate::EXPORT = qw(attributes);

my $debugging = 0; # assign 1 to it to see code generated on the fly 

# Create accessor functions, and new()
sub attributes {
    my ($pkg) = caller;
    @{"${pkg}::_ATTRIBUTES_"} = @_;
    my $code = "";
    foreach my $attr (get_attribute_names($pkg)) {
        # If a field name is "color", create a global list in the
        # calling package called @color
        @{"${pkg}::_$attr"} = ();

        # Define accessor only if it is not already present
        unless ($pkg->can("$attr")) {
            $code .= _define_accessor ($pkg, $attr);
        } 
    }
    $code .= _define_constructor($pkg);
    eval $code;
    if ($@) {
       die  "ERROR defining constructor and attributes for '$pkg':" 
            . "\n\t$@\n" 
            . "-----------------------------------------------------"
            . $code;
    }
}

# $obj->set_attributes (name => 'John', age => 23);     
# Or, $obj->set_attributes (['name', 'age'], ['John', 23]);
sub set_attributes {
    my $obj = shift;
    my $attr_name;
    if (ref($_[0])) {
       my ($attr_name_list, $attr_value_list) = @_;
       my $i = 0;
       foreach $attr_name (@$attr_name_list) {
            $obj->$attr_name($attr_value_list->[$i++]);
       }
    } else {
       my ($attr_name, $attr_value);
       while (@_) {
           $attr_name = shift;
           $attr_value = shift;
           $obj->$attr_name($attr_value);
       }
    }
}


# @attrs = $obj->get_attributes (qw(name age));
sub get_attributes {
    my $obj = shift;
    my (@retval);
    map $obj->${_}(), @_;
}


sub get_attribute_names {
    my $pkg = shift;
    $pkg = ref($pkg) if ref($pkg);
    my @result = @{"${pkg}::_ATTRIBUTES_"};
    if (defined (@{"${pkg}::ISA"})) {
        foreach my $base_pkg (@{"${pkg}::ISA"}) {
           push (@result, get_attribute_names($base_pkg));
        }
    }
    @result;
}

sub set_attribute {
    my ($obj, $attr_name, $attr_value) = @_;
    my ($pkg) = ref($obj);
    ${"${pkg}::_$attr_name"}[$$obj] = $attr_value;
}

sub get_attribute {
    my ($obj, $attr_name, $attr_value) = @_;
    my ($pkg) = ref($obj);
    return ${"${pkg}::_$attr_name"}[$$obj];
}


sub DESTROY {
    # release id back to free list
    my $obj = $_[0];
    my $pkg = ref($obj);
    local *_free = *{"${pkg}::_free"};
    my $inst_id = $$obj;
    # Release all the attributes in that row
    local(*attributes) = *{"${pkg}::_ATTRIBUTES_"};
    foreach my $attr (@attributes) {
        undef ${"${pkg}::_$attr"}[$inst_id];
    }
    $_free[$inst_id] = $_free;
    $_free = $inst_id;
}

sub initialize { }; # dummy method, if subclass doesnt define one.

#################################################################

sub _define_constructor {
    my $pkg = shift;
    my $code = qq {
        package $pkg;
        sub new {
            my \$class = shift;
            my \$inst_id;
            if (defined(\$_free[\$_free])) {
                \$inst_id = \$_free;
                \$_free = \$_free[\$_free];
                undef \$_free[\$inst_id];
            } else {
                \$inst_id = \$_free++;
            }
            my \$obj = bless \\\$inst_id, \$class;
            
            # DSH: The below code is some kind of a hack. I consider it
            # a hack because it eliminates the neutral nature of ObjectTemplates
            # because the class is tightly coupled to the Figure class.
            
            if (ref(\$obj) =~ m/GDFigure/) {
                my \%dimension = (height => 30, width => 400);
                my \%calendaric_values = (
                        day => '01',
                        month => '01',
                        year => '1900',
                        week => '01',
                        days_in_month => 31,
                        week_of_year => 1,
                        monday_of_week => '01011900',
                        date_start => '01011900',
                        date_end => '31011900');
                        
                \$obj->set_attribute("basename", "/tmp/");
                \$obj->set_attribute("bordercolor", "#4a4a4a");
                \$obj->set_attribute("dimension", \%dimension);
                \$obj->set_attribute("calendaric_values", \%calendaric_values);
                \$obj->set_attribute("extension", ".png");
                \$obj->set_attribute("fillcolor", "#4a4a4a");
                \$obj->set_attribute("linecolor", "#FFFFFF");
                \$obj->set_attribute("location", "/tmp/blogtimes.png");
                \$obj->set_attribute("name", "blogtimes");
                \$obj->set_attribute("padding", 5);
                \$obj->set_attribute("denominator", 1440);
                \$obj->set_attribute("text", "off");
                \$obj->set_attribute("textcolor", "#4a4a4a");
                \$obj->set_attribute("title", "B L O G T I M E S");
            }
            
            \$obj->set_attributes(\@_) if \@_;
            \$obj->initialize;
            \$obj;

        }
    };
    $code;
}

sub _define_accessor {
    my ($pkg, $attr) = @_;

    # This code creates an accessor method for a given
    # attribute name. This method  returns the attribute value 
    # if given no args, and modifies it if given one arg.
    # Either way, it returns the latest value of that attribute


    # qq makes this block behave like a double-quoted string
    my $code = qq{
        package $pkg;
        sub $attr {                                      # Accessor ...
            \@_ > 1 ? \$_${attr} \[\${\$_[0]}] = \$_[1]  # set
                    : \$_${attr} \[\${\$_[0]}];          # get
        }
        if (!defined \$_free) {
            # Alias the first attribute column to _free
            \*_free = \*_$attr;
            \$_free = 0;
        };

    };
    $code;
}

1;
