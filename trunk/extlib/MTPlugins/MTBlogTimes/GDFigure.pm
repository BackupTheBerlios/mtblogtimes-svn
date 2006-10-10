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

package MTPlugins::MTBlogTimes::GDFigure;

# Perl Module Usages
use strict;
use warnings;

use MTPlugins::MTBlogTimes::ObjectTemplate;
use MTPlugins::MTBlogTimes::Figure;

use GD;
use GD::Text;
use GD::Graph::colour qw(:convert :colours);
use GD::Graph::bars;
use GD::Graph::bars3d;
use GD::Graph::lines;
use GD::Graph::lines3d;
use Date::Calc qw(:all);

# Inheritance Declarations
@MTPlugins::MTBlogTimes::GDFigure::ISA = qw (MTPlugins::MTBlogTimes::Figure);

# Attribute Storage Object
attributes qw (ctype);

# ---------------------------------------------------------------------------
# Custom extension accessor which always sets the extension to '.png'.
# ---------------------------------------------------------------------------

sub extension {
    my $obj = shift;
    my $extension = $obj->SUPER::get_attribute("extension");
    
    # simply set the extension to '.gd'
    if ($extension) {
        # NOP
        # die "File type extension already assigned, no need to do it twice! Extension is currently set to: $extension";
        $obj->SUPER::set_attribute("extension", ".png");
    } else {
        $obj->SUPER::set_attribute("extension", ".png");
    }
    
    $extension;
}

# ---------------------------------------------------------------------------
# private helper method which tries to complete the map object.
# ---------------------------------------------------------------------------

sub _completeMap {
    my %args = (
        graph => 0,
        points => undef,
        @_,
    );
    
    my $obj = shift;
    
    my $values_ref = $obj->SUPER::values();
    my @values = @$values_ref;
    my ($i, $j) = (0, 0);

    if ($obj->SUPER::map()) {
        if (&ctype() eq "classic")
        {
            my $map_ref = $obj->SUPER::map();
            my $map = $$map_ref;
            my $map_hotspots_ref = $map->hotspots();
            my @map_hotspots = @$map_hotspots_ref;
            my $points_ref = $args{points};
            my @points = @$points_ref;

            foreach my $value (@values) {
                my $arearef = $points[$i];
                my @area = @$arearef;
                my $hotspot_hash_ref = @$map_hotspots_ref[$i];
                my %hotspot_hash = %$hotspot_hash_ref;
                
                $hotspot_hash{"coords"} = \@area;
                @$map_hotspots_ref[$i] = \%hotspot_hash;
                
                $i++;
            }
        } elsif (&ctype() eq "lines" ||
            &ctype() eq "bars") {
            # there is only one dataset we did plot!
            my @hotspots = $args{graph}->get_hotspot(1);
            my $map_ref = $obj->SUPER::map();
            my $map = $$map_ref;
            my $map_hotspots_ref = $map->hotspots();
            my @map_hotspots = @$map_hotspots_ref;

            foreach my $value (@values) {            
                if ($value > 0) {
                    my $hotspot_hash_ref = @$map_hotspots_ref[$i];
                    my %hotspot_hash = %$hotspot_hash_ref;
                    
                    my @current_hotspots =  @{$hotspots[$j]};
    
                    # first element contains the shape type -> not needed
                    # note: even if GD::Graph returns a line, I will stick
                    # with rect because it seems to produce better results.
                    my @FRONT = splice(@{$hotspots[$j]}, 1, 4);
                    
                    $hotspot_hash{"coords"} = \@FRONT;
                    
                    @$map_hotspots_ref[$i] = \%hotspot_hash;
                    
                    $i++;
                }
                
                $j++;
            }
        } else {
            if (&ctype() =~ m/3d$/) {
                my $map_ref = $obj->SUPER::map();
                my $map = $$map_ref;
                my $map_hotspots_ref = $map->hotspots();
                my @map_hotspots = @$map_hotspots_ref;
        
                foreach my $value (@values) {            
                    if ($value > 0) {
                        my $hotspot_hash_ref = @$map_hotspots_ref[$i];
                        my %hotspot_hash = %$hotspot_hash_ref;
                        my (@coords, @p1, @p2);
                        
                        if (&ctype() =~ m/^lines/) {
                            @p1 = $args{graph}->val_to_pixel($j, 0, 1);
                            @p2 = $args{graph}->val_to_pixel($j + 2, $value, 1);
                        } else {
                            # TODO: Area shap placement gets the more imprecise the higher $value.
                            warn "At the time generating image maps for GD::Graph::bars3d charts is still a bit experimental. Any help would be appreciated.";
                        
                            # I did program this algorithm because it seems
                            # that it is not possible to use val_to_pixel()
                            # in conjunction with bars3d.
                            #
                            # 0.92, 0.56, 0.714 and 0.286 are empirical values!
                            my $graph_width = $args{graph}->{width} * 0.922;
                            my $graph_height = $args{graph}->{height} * 0.56;
                            my $padding = ($args{graph}->{height} - $graph_height);
                            my $top_padding = $padding * 0.286;
                            my $bottom_padding = $padding * 0.714;
                            my $lr_padding = 5 + (($args{graph}->{width} - ($graph_width) / 2));
                            my $bottom = $top_padding + $graph_height;
                            my $bar_width = $graph_width / scalar(@values);
                            my $bar_height = ($graph_height / $args{graph}->{y_tick_number}) * $value;
                            
                            my $x1 = $lr_padding + (($bar_width * ($j + 1)) - ($bar_width / 2));
                            my $y1 = $bottom;
                            my $x2 = $x1 + $bar_width;
                            my $y2 = $bottom - $bar_height;
                            
                            @p1 = ($x1, $y1);
                            @p2 = ($x2, $y2);
                        }
                        
                        push @coords, $p1[0];
                        push @coords, $p1[1];
                        push @coords, $p2[0];
                        push @coords, $p2[1];
                        
                        $hotspot_hash{"coords"} = \@coords;
                        
                        @$map_hotspots_ref[$i] = \%hotspot_hash;
                        
                        $i++;
                    }
                    
                    $j++;
                }
            } else {
                my $mode = $obj->SUPER::mode();
                die "Current mode => $mode does not support image maps.";
            }
        }
    }
}

# ---------------------------------------------------------------------------
# private helper method which sets various chart colors.
# ---------------------------------------------------------------------------

sub _addCustomColors {
    my %args = (
        graph => 0,
        @_,
    );
    
    my $obj = shift;
    
    $args{graph}->set(bgclr =>        add_colour('#FFFFFF'),
                      fgclr =>        add_colour($obj->SUPER::linecolor()),
                      boxclr =>       add_colour($obj->SUPER::fillcolor()),
                      labelclr =>     add_colour($obj->SUPER::textcolor()),
                      axislabelclr => add_colour($obj->SUPER::textcolor()),
                      legendclr =>    add_colour($obj->SUPER::textcolor()),
                      valuesclr =>    add_colour($obj->SUPER::textcolor()),
                      textclr =>      add_colour($obj->SUPER::textcolor()),
                      dclrs =>        [add_colour($obj->SUPER::fillcolor())],
                      borderclrs =>   [add_colour($obj->SUPER::bordercolor())])
                      if $args{graph};
}

# ---------------------------------------------------------------------------
# private helper method which plots the text values on the abscissa.
# ---------------------------------------------------------------------------

sub _plotAbscissaScale {
    my %args = (
        divisor     => 24,
        incrementer => 2,
        ruler_y     => 0,
        img         => 0,
        @_,
    );
    
    die "Wrong value for ruler_y" if $args{ruler_y} == 0;
    die "Wrong value for img" if $args{img} == 0;
    
    my ($i, $ruler_x, $offset);
    my $obj = shift;
    my $dimension_ref = $obj->SUPER::dimension();
    my %dimension = %$dimension_ref;
    my $textcolor = $args{img}->colorAllocate(
        &hex2rgb($obj->SUPER::textcolor()));
    
    for ($i = 0; $i <= $args{divisor} - 1; $i += $args{incrementer}) {
        $ruler_x = $obj->SUPER::padding() +
            $obj->SUPER::round($i * $dimension{width} / $args{divisor});
        if ($obj->SUPER::cscale() && $obj->SUPER::cscale() > 0 &&
            ($obj->SUPER::mode() eq 'weekly' ||
             $obj->SUPER::mode() eq 'monthly' ||
             $obj->SUPER::mode() eq 'yearly')) {
            
    	    $args{img}->string(gdTinyFont, $ruler_x, $args{ruler_y},
    	       $obj->SUPER::dateToText(date => $i + 1), $textcolor);
        } else {
    	    $args{img}->string(gdTinyFont, $ruler_x, $args{ruler_y}, "$i", $textcolor) if (
    	       $obj->SUPER::mode() eq 'classic' ||
    	       $obj->SUPER::mode() eq 'daily');
    	    # we want to start days/weeks/months with 1 instead of zero.
    	    $args{img}->string(gdTinyFont, $ruler_x, $args{ruler_y}, $i + 1, $textcolor) if (
    	       $obj->SUPER::mode() ne 'classic' &&
    	       $obj->SUPER::mode() ne 'daily');
        }
    }
}

# ---------------------------------------------------------------------------
# private helper method which plots the title of the chart.
# ---------------------------------------------------------------------------

sub _plotTitleText {    
    my %args = (
        object => 0,
        @_,
    );
    
    # TODO: Was not able to use my $obj = shift. Why?
    
    my $obj = $args{object};
    
    my $dimension_ref = $obj->SUPER::dimension();
    my %dimension = %$dimension_ref;
    my $denominator = $obj->SUPER::denominator();
    my $_cal_values_ref = $obj->SUPER::calendaric_values();
    my %_cal_values = %$_cal_values_ref;
    my $day = $_cal_values{day};
    my $week = $_cal_values{week};
    my $month = $_cal_values{month};
    my $year = $_cal_values{year};
    my $dim = $_cal_values{days_in_month};
    my $caption;
    
    if ($dimension{width} >= 100) {
	    $caption = "B L O G T I M E S   ";
    } else {
        $caption ="";
    }
    
    if ($denominator eq 1440 && $obj->SUPER::mode() eq "classic") {
        # plot the blogtime badge and label (if applicable)
        $caption .= $obj->SUPER::month2str($month) . " $year" ;
        $caption .= " (mode: " . $obj->SUPER::mode() . ")" if ($obj->SUPER::debug() == 1);
    } elsif ($denominator eq 1440 && $obj->SUPER::mode() eq "daily") {
   	    # plot the blogtime badge and label (if applicable)        	        
	    $caption .= Date_to_Text($year,$month,$day);
	    $caption .= " (mode: " . $obj->SUPER::mode() . ")" if ($obj->SUPER::debug() == 1);
    } elsif ($denominator eq 7 && $obj->SUPER::mode() eq "weekly") {
   	    # plot the blogtime badge and label (if applicable)
	    $caption .= "WEEK #$week $year";
	    $caption .= " (mode: " . $obj->SUPER::mode() . ")" if ($obj->SUPER::debug() == 1);
    } elsif ($denominator eq  $dim && $obj->SUPER::mode() eq "monthly") {
	    my $month_to_text = Month_to_Text($month);
	    # UPPERCASE convertion
	    $month_to_text =~ tr/a-z/A-Z/;
        
   	    # plot the blogtime badge and label (if applicable)
        $caption .= "$month_to_text $year";
	    $caption .= " (mode: " . $obj->SUPER::mode() . ")" if ($obj->SUPER::debug() == 1);
    } elsif ($denominator eq 12 && $obj->SUPER::mode() eq "yearly") {
   	    # plot the blogtime badge and label (if applicable)
        $caption .= "$year";
	    $caption .= " (mode: " . $obj->SUPER::mode() . ")" if ($obj->SUPER::debug() == 1);
    } elsif ($denominator eq 53 && $obj->SUPER::mode() eq "yearly_exone") {
   	    # plot the blogtime badge and label (if applicable)
        $caption .= "$year";
	    $caption .= " (mode: " . $obj->SUPER::mode() . ")" if ($obj->SUPER::debug() == 1);
    } elsif ($denominator eq 365 && $obj->SUPER::mode() eq "yearly_extwo") {
   	    # plot the blogtime badge and label (if applicable)
        $caption .= "$year";
	    $caption .= " (mode: " . $obj->SUPER::mode() . ")" if ($obj->SUPER::debug() == 1);
    }
    
    $caption;
}

# ---------------------------------------------------------------------------
# Overridden Figure::draw method.
# ---------------------------------------------------------------------------

sub draw {
    my $obj = shift;
    my $labels_ref = $obj->SUPER::labels();
    my @labels = @$labels_ref;
    my $values_ref = $obj->SUPER::values();
    my @values = @$values_ref;
    my @data = ( \@labels, \@values );
    my $ref_dimension = $obj->SUPER::dimension();
    my %dimension = %$ref_dimension;
    my $denominator = $obj->SUPER::denominator();
    my ($graph, $gd);
    
    SWITCH: {
        if ($obj->ctype() eq 'lines') {
            $graph = GD::Graph::lines->new(
                                          $dimension{width},
                                          $dimension{height});

            $graph->set(title => $obj->SUPER::title()) if $obj->SUPER::title();
            $graph->set(title => &_plotTitleText(object => $obj));                      
            $graph->set_title_font(gdTinyFont);
            $graph->set(y_label => "Entries");
            $graph->set_y_axis_font(gdTinyFont);            
            $graph->set(x_label => "Hours") if ($obj->SUPER::mode() eq 'classic' || $obj->SUPER::mode() eq 'daily');
            $graph->set(x_label => "Day(s)")
                if ($obj->SUPER::mode() eq 'weekly' ||
                    $obj->SUPER::mode() eq 'monthly' ||
                    $obj->SUPER::mode() eq 'yearly_extwo');
            $graph->set(x_label => "Months") if ($obj->SUPER::mode() eq 'yearly');
            $graph->set(x_label => "Weeks") if ($obj->SUPER::mode() eq 'yearly_exone');
            $graph->set_x_axis_font(gdTinyFont);
            $graph->set(x_label_position => 0.5);
            
            # add custom colors
#            _addCustomColors(graph => $graph);
            
            $gd = $graph->plot(\@data) or die $graph->error;
            
            if ($obj->SUPER::map()) {
                _completeMap(graph => $graph);
            }
            
            $obj->SUPER::figure($gd);
            last SWITCH;
        }
        if ($obj->ctype() eq 'bars') {
            $graph = GD::Graph::bars->new(
                                         $dimension{width},
                                         $dimension{height});
                                  
            $graph->set(title => $obj->SUPER::title()) if $obj->SUPER::title();
            $graph->set(title => &_plotTitleText(object => $obj));                      
            $graph->set_title_font(gdTinyFont);
            $graph->set(y_label => "Entries");
            $graph->set_y_axis_font(gdTinyFont);            
            $graph->set(x_label => "Hours") if ($obj->SUPER::mode() eq 'classic' || $obj->SUPER::mode() eq 'daily');
            $graph->set(x_label => "Day(s)")
                if ($obj->SUPER::mode() eq 'weekly' ||
                    $obj->SUPER::mode() eq 'monthly' ||
                    $obj->SUPER::mode() eq 'yearly_extwo');
            $graph->set(x_label => "Months") if ($obj->SUPER::mode() eq 'yearly');
            $graph->set(x_label => "Weeks") if ($obj->SUPER::mode() eq 'yearly_exone');
            $graph->set_x_axis_font(gdTinyFont);
            $graph->set(x_label_position => 0.5);
            
            # add custom colors
            _addCustomColors(graph => $graph);
            
            $gd = $graph->plot(\@data) or die $graph->error;
            
            if ($obj->SUPER::map()) {
                _completeMap(graph => $graph);
            }
            
            $obj->SUPER::figure($gd);
            last SWITCH;
        }
        if ($obj->ctype() eq 'lines3d') {
            $graph = GD::Graph::lines3d->new(
                                            $dimension{width},
                                            $dimension{height});
                                            
            $graph->set(title => $obj->SUPER::title()) if $obj->SUPER::title();
            $graph->set(title => &_plotTitleText(object => $obj));                      
            $graph->set_title_font(gdTinyFont);
            $graph->set(y_label => "Entries");
            $graph->set_y_axis_font(gdTinyFont);            
            $graph->set(x_label => "Hours") if ($obj->SUPER::mode() eq 'classic' || $obj->SUPER::mode() eq 'daily');
            $graph->set(x_label => "Day(s)")
                if ($obj->SUPER::mode() eq 'weekly' ||
                    $obj->SUPER::mode() eq 'monthly' ||
                    $obj->SUPER::mode() eq 'yearly_extwo');
            $graph->set(x_label => "Months") if ($obj->SUPER::mode() eq 'yearly');
            $graph->set(x_label => "Weeks") if ($obj->SUPER::mode() eq 'yearly_exone');
            $graph->set_x_axis_font(gdTinyFont);
            $graph->set(x_label_position => 0.5);
            
            # add custom colors
            _addCustomColors(graph => $graph);
            
            $gd = $graph->plot(\@data) or die $graph->error;
            
            if ($obj->SUPER::map()) {
                _completeMap(graph => $graph);
            }
            
            $obj->SUPER::figure($gd);
            last SWITCH;
        }
        if ($obj->ctype() eq 'bars3d') {
            $graph = GD::Graph::bars3d->new(
                                           $dimension{width},
                                           $dimension{height});
                     
            $graph->set(title => $obj->SUPER::title()) if $obj->SUPER::title();
            $graph->set(title => &_plotTitleText(object => $obj));                      
            $graph->set_title_font(gdTinyFont);
            $graph->set(y_label => "Entries");
            $graph->set_y_axis_font(gdTinyFont);            
            $graph->set(x_label => "Hours") if ($obj->SUPER::mode() eq 'classic' || $obj->SUPER::mode() eq 'daily');
            $graph->set(x_label => "Day(s)")
                if ($obj->SUPER::mode() eq 'weekly' ||
                    $obj->SUPER::mode() eq 'monthly' ||
                    $obj->SUPER::mode() eq 'yearly_extwo');
            $graph->set(x_label => "Months") if ($obj->SUPER::mode() eq 'yearly');
            $graph->set(x_label => "Weeks") if ($obj->SUPER::mode() eq 'yearly_exone');
            $graph->set_x_axis_font(gdTinyFont);
            $graph->set(x_label_position => 0.5);

            
            # add custom colors
            _addCustomColors(graph => $graph);
            
            if ($obj->SUPER::map()) {
                _completeMap(graph => $graph);
            }
            
            $gd = $graph->plot(\@data) or die $graph->error;
            
            $obj->SUPER::figure($gd);
            last SWITCH;
        }
        if ($obj->ctype() eq 'classic') {
            my $txtpad = ($obj->SUPER::text() eq 'off') ? 0
                : gdTinyFont->height;
            my $scale_width = $dimension{width} + ($obj->SUPER::padding() * 2);
            my $scale_height = $dimension{height} + ($obj->SUPER::padding() * 2)
                + ($txtpad * 2);
                
            $obj->SUPER::swidth($scale_width);
            $obj->SUPER::sheight($scale_height);
                
            my $img = GD::Image->new($scale_width, $scale_height);
            
            # initialize the various colors using GD::colours::convert
            my $white = $img->colorAllocate(255,255,255);            
            my $_linecolor = $img->colorAllocate(&hex2rgb($obj->SUPER::linecolor()));
            my $_textcolor = $img->colorAllocate(&hex2rgb($obj->SUPER::textcolor()));
            my $_fillcolor = $img->colorAllocate(&hex2rgb($obj->SUPER::fillcolor()));
            my $_bordercolor = $img->colorAllocate(&hex2rgb($obj->SUPER::bordercolor()));
            
            $img->transparent($white);
            
            my $line_y1 = $obj->SUPER::padding() + $txtpad;
            my $line_y2 = $obj->SUPER::padding() + $txtpad + $dimension{height};
            
            # paint outher frame
            $img->rectangle(0, 0, $scale_width - 1,
                $scale_height - 1, $_bordercolor);
                
            # paint inner frame and fill it
            $img->filledRectangle($obj->SUPER::padding(), $line_y1,
                $obj->SUPER::padding() + $dimension{width} ,$line_y2,
                $_fillcolor);
                
            # paint vertical (white lines) per blog entry
            my ($line_x,$i);
            my $_cal_values_ref = $obj->SUPER::calendaric_values();
            my %_cal_values = %$_cal_values_ref;
            my $_entry_items_ref = $obj->SUPER::values();
            my @_entry_items = @$_entry_items_ref;
            my $day = $_cal_values{day};
            my $week = $_cal_values{week};
            my $month = $_cal_values{month};
            my $year = $_cal_values{year};
            my $dim = $_cal_values{days_in_month};
                        
            #
            # what means the number value of the denominator variable?
            #
            # 1440 == classic/daily mode (1440 minutes = 24 hours)
            # 7 == weekly mode
            # days_of_month == monthly mode
            # 12 == yearly mode
            # 53 == yearly_exone mode
            # 365 == yearly_extwo mode
            #
            # Note: I am trying to compensate the width of the numbers
            # which are printed on the abscissa scale. If you don't take
            # care of the font width, each thick is ploted at the begining
            # of a number. Example:
            # 
            # |   |   |   |
            # 100 200 300 400
            #
            # But I want it this way:
            #
            #  |   |   |   |
            # 100 200 300 400
            #
            my $gd_text = GD::Text->new();
            $gd_text->set_font(gdTinyFont);
            
            my @map_points; # -> contains each image map point
            
    	    foreach $i (@_entry_items) {
    	        # remove leading zero characters and calculate
    	        # the length/width that the string occupies
    	        my $expr;
    	        
    	        if ($obj->SUPER::mode() eq "yearly") {
    	           # just the month is needed
    	           $expr = substr($i, 4, 2);
    	           $expr = _dateToText(date => substr($i, 4, 2)) if $obj->SUPER::cscale() > 0;
    	        } else {
    	           $expr = "$i";
    	           $expr = _dateToText(date => $i) if $obj->SUPER::cscale() > 0;
    	        }
    	        
    	        $expr =~ s/^0// if ($expr =~ m/^0/);
    	        my $gd_text_width = $gd_text->width($expr);
    	        
    	        if ($obj->SUPER::mode() eq "classic" || $obj->SUPER::mode() eq "daily") {
                    $line_x = $obj->SUPER::padding() +
        		      ($obj->SUPER::round(($obj->SUPER::to_minutes($i) / $denominator) * $dimension{width}));
    	        } elsif ($obj->SUPER::mode() eq "yearly") {
    	           if (length($expr) > 1) {
                    $line_x = $obj->SUPER::padding() +
        		      ($obj->SUPER::round(($obj->SUPER::to_month($i) / $denominator) * $dimension{width}
        		      + ($gd_text_width / 2)));
    	           } else {
                    $line_x = $obj->SUPER::padding() +
        		      ($obj->SUPER::round(($obj->SUPER::to_month($i) / $denominator) * $dimension{width}));
    	           }
    	        } else {
    	           if (length($expr) > 1) {
                    $line_x = $obj->SUPER::padding() +
        		      ($obj->SUPER::round((($i - 1) / $denominator) * $dimension{width}
        		      + ($gd_text_width / 2)));
    	           } else {
                    $line_x = $obj->SUPER::padding() +
        		      ($obj->SUPER::round((($i - 1) / $denominator) * $dimension{width}));
    	           }
    	        }
    		      
                $img->line($line_x, $line_y1, $line_x, $line_y2, $_linecolor);
                
                # needed to create an image map.
                # Each line gets mapped to a rect area shape.
                # Note: The current implementation renders a
                # rect shape that has a width of one pixel!
                my @map_area;
                push @map_area, $line_x;
                push @map_area, $line_y1;
                push @map_area, $line_x;
                push @map_area, $line_y2;
                
                push @map_points, \@map_area;
    	    }
    	    
            _completeMap(graph => $graph, points => \@map_points);
    	    
    	    # The below code only plots the scale of the abscissa (if applicable).
            # Shut off text if width is too less.
            if ($obj->SUPER::text() eq 'on') {
        	    my $ruler_y = $obj->SUPER::padding() + $txtpad + $dimension{height} + 2;
        	    my ($ruler_x, $inc);
        	    my ($caption_x, $caption_y);
        	    
    		    $caption_x = $obj->SUPER::padding();
    		    $caption_y = $obj->SUPER::padding() - 1;
        	    
        	    if ($dimension{width} >= 100) {
        	        # plots only half of the abscissa scale (e.g. if you are plotting
        	        # a month, only every 2nd day will be diplayed as a marker on the
        	        # abscissa scale.)
                    $inc = $obj->SUPER::printnth() || 2;
        	    } else {
                    $inc = $obj->SUPER::printnth() || 6;
        	    }
        	    
        	    if ($denominator eq 1440 && $obj->SUPER::mode() eq "classic") {
                    _plotAbscissaScale(incrementer => $inc,
                                       divisor => 24,
                                       ruler_y => $ruler_y,
                                       img => $img);
        	       
        		    $img->string(gdTinyFont, $caption_x, $caption_y, &_plotTitleText(object => $obj), $_textcolor);
        	    } elsif ($denominator eq 1440 && $obj->SUPER::mode() eq "daily") {
        	        _plotAbscissaScale(incrementer => $inc,
        	                           divisor => 24,
        	                           ruler_y => $ruler_y,
        	                           img => $img);

        		    $img->string(gdTinyFont,$caption_x,$caption_y,&_plotTitleText(object => $obj), $_textcolor);
        	    } elsif ($denominator eq 7 && $obj->SUPER::mode() eq "weekly") {
        	        _plotAbscissaScale(incrementer => $inc,
        	                           divisor => 7,
        	                           ruler_y => $ruler_y,
        	                           img => $img);
        	        
                    $img->string(gdTinyFont,$caption_x,$caption_y,&_plotTitleText(object => $obj), $_textcolor);
        	    } elsif ($denominator eq $dim && $obj->SUPER::mode() eq "monthly") {
        	        _plotAbscissaScale(incrementer => $inc,
        	                           divisor => $dim,
        	                           ruler_y => $ruler_y,
        	                           img => $img);
        	        
                    $img->string(gdTinyFont,$caption_x,$caption_y,&_plotTitleText(object => $obj),$_textcolor);
        	    } elsif ($denominator eq 12 && $obj->SUPER::mode() eq "yearly") {
        	        _plotAbscissaScale(incrementer => $inc,
        	                           divisor => 12,
        	                           ruler_y => $ruler_y,
        	                           img => $img);
        	        
                    $img->string(gdTinyFont,$caption_x,$caption_y,&_plotTitleText(object => $obj),$_textcolor);
        	    } elsif ($denominator eq 53 && $obj->SUPER::mode() eq "yearly_exone") {
        	        _plotAbscissaScale(incrementer => $inc,
        	                           divisor => 53,
        	                           ruler_y => $ruler_y,
        	                           img => $img);
        	        
                    $img->string(gdTinyFont,$caption_x,$caption_y,&_plotTitleText(object => $obj),$_textcolor);
        	    } elsif ($denominator eq 365 && $obj->SUPER::mode() eq "yearly_extwo") {
        	        _plotAbscissaScale(incrementer => $inc,
        	                           divisor => 365,
        	                           ruler_y => $ruler_y,
        	                           img => $img);
        	        
                    $img->string(gdTinyFont,$caption_x,$caption_y,&_plotTitleText(object => $obj),$_textcolor);
        	    }
            }
                
            $obj->SUPER::figure($img);
            last SWITCH;
        }
    }
}

# ---------------------------------------------------------------------------
# Overridden Figure::save method.
# ---------------------------------------------------------------------------

sub save {
    my $obj = shift;
    my $figure = $obj->SUPER::figure();
    my $image_file = $obj->SUPER::basename() . $obj->SUPER::name() . $obj->extension();
    
    open(IMG, ">$image_file") or die $!;
    binmode IMG;
    print IMG $figure->png if $figure or die "Couldn't fetch image object to save it to the file system.";
}

1;