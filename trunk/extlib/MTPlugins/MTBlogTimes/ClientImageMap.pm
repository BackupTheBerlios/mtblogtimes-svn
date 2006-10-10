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

package MTPlugins::MTBlogTimes::ClientImageMap;

# Perl Module Usages
use strict;
use warnings;

use MTPlugins::MTBlogTimes::ObjectTemplate;
use MTPlugins::MTBlogTimes::ImageMap;

# Inheritance Declarations
@MTPlugins::MTBlogTimes::ClientImageMap::ISA = qw (MTPlugins::MTBlogTimes::ImageMap);

# Attribute Storage Object
# -- NONE --

sub map {
    my $obj = shift;
    
    # copyright etc.
    my $mapstr = "<!-- Imagemap created by MT-BlogTimes -->\n";
       $mapstr .= "<!-- (C) 2005, Daniel S. Haischt      -->\n";
       $mapstr .= "<map name=\"" . $obj->name() . "\">";
    
    foreach my $hotspot (@{$obj->hotspots()}) {
        my $hotspot_hash_ref = $hotspot;
        my %hotspot_hash = %$hotspot_hash_ref;
        
        $mapstr .= "<area shape=\"" . $hotspot_hash{type} . "\" coords=\"";
        
        my $current_hotspots_ref = $hotspot_hash{coords};        
        my @current_hotspots = @$current_hotspots_ref;
        my $coords = join ",", @current_hotspots;

        $mapstr .= $coords;
        
        $mapstr .= "\" href=\"" . $hotspot_hash{uri} . "\" alt=\""
            . $hotspot_hash{title} . "\" title=\""
            . $hotspot_hash{title} . "\" />\n";
    }
    
    $mapstr .= "<area shape=\"default\" nohref>\n</map>\n";
    $mapstr;
}

1;
