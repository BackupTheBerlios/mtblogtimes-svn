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

package MTPlugins::MTBlogTimes::BlogTimes;

# Perl Module Usages
use strict;
use warnings;

use vars qw(@ISA $GOTPATH $VERSION $DEBUG);
use MT::Template::Context;
use MT::Util qw(days_in offset_time);
use MT::App::CMS;
use MT::PluginData;
use MT::Request;
use Date::Calc qw(:all);
use GD;

use MTPlugins::MTBlogTimes::ObjectTemplate;
use MTPlugins::MTBlogTimes::FigureFactory;
use MTPlugins::MTBlogTimes::MapFactory;

@MTPlugins::MTBlogTimes::BlogTimes::ISA = qw( MT::App::CMS );
$DEBUG = 0;
$VERSION = "0.10";

#
# daily -> Shows the most active hour within a period of 24 hours
# weekly -> Shows the most active day within a period of 7 days
# monthly -> Shows the most active day within a period of four weeks
# yearly -> Shows the most active week within a period of 12 months 
#
my @arg_mode = qw(classic daily weekly monthly yearly);
my @arg_type = qw(bar);
my @arg_archive_type = qw(Individual Daily Weekly Monthly Category);
my $current_date = ((((gmtime)[5]+1900)*10000)+((gmtime)[4]+1)*100+(gmtime)[3]);

# overridden methods
sub build_page {
    my ($self, $templateName, $params) = @_;
    my ($mode, $ctype, $withmap, $map_type, $linkto, $apitype, $cscale, $print_nth);
    my ($pdata_obj, $data_holder);
    
    $params->{btimes_version} = $VERSION;
    $params->{btimes_script_location} = $self->plugin_uri();

    $pdata_obj = MT::PluginData->load({plugin => 'MT-BlogTimes',
                                       key => 'configuration'});
                                       
    # this expression evaluates to false, if the user will access the
    # plugins config web site the very first time.
    $data_holder = $pdata_obj->data if $pdata_obj;

    if ($data_holder) {
        $mode = $data_holder->{'btimes_mode'};
        $ctype = $data_holder->{'btimes_ctype'};
        $apitype = $data_holder->{'btimes_apitype'};
        $withmap = $data_holder->{'btimes_withmap'};
        $map_type = $data_holder->{'btimes_maptype'};
        $linkto = $data_holder->{'btimes_linkto'};
        $cscale = $data_holder->{'btimes_cscale'};
        $print_nth = $data_holder->{'btimes_printnth'};
        
        # Set Mode
        if ($mode eq 'classic') {
            $params->{btimes_mode_classic} = $mode;
        } elsif ($mode eq 'daily') {
            $params->{btimes_mode_daily} = $mode;
        } elsif ($mode eq 'weekly') {
            $params->{btimes_mode_weekly} = $mode;
        } elsif ($mode eq 'monthly') {
            $params->{btimes_mode_monthly} = $mode;
        } elsif ($mode eq 'yearly') {
            $params->{btimes_mode_yearly} = $mode;
        } elsif ($mode eq 'yearly_exone') {
            $params->{btimes_mode_yearly_exone} = $mode;
        } elsif ($mode eq 'yearly_extwo') {
            $params->{btimes_mode_yearly_extwo} = $mode;
        } else {
            $params->{btimes_mode_classic} = "classic";
        }
        
        # Set Image API Type
        if ($apitype eq 'gd') {
            $params->{btimes_apitype_gd} = 'gd';
        } elsif ($apitype eq 'im') {
            $params->{btimes_apitype_im} = 'im';
        } elsif ($apitype eq 'svg') {
            $params->{btimes_apitype_svg} = 'svg';
        } elsif ($apitype eq 'swf') {
            $params->{btimes_apitype_swf} = 'swf';
        }

        # Set Chart Type (currently 'classic, lines lines3d bars bars3d')
        if ($ctype eq 'bars') {
            $params->{btimes_ctype_bars} = 'bars';
        } elsif ($ctype eq 'bars3d') {
            $params->{btimes_ctype_bars3d} = 'bars3d';
        } elsif ($ctype eq 'lines') {
            $params->{btimes_ctype_lines} = 'lines';
        } elsif ($ctype eq 'lines3d') {
            $params->{btimes_ctype_lines3d} = 'lines3d';
        } elsif ($ctype eq 'classic') {
            $params->{btimes_ctype_classic} = 'classic';
        }
        
        # Set dir which holds our blogtimes images
        $params->{btimes_sdir} = $data_holder->{'btimes_sdir'} || 'images';        
        
        # Set how many labels should be printed on the abscissa scale
        SWITCH: {
            if ($print_nth eq 1) {
                $params->{btimes_print_everynth_any} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 2) {
                $params->{btimes_print_everynth_2nd} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 4) {
                $params->{btimes_print_everynth_4th} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 6) {
                $params->{btimes_print_everynth_6th} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 8) {
                $params->{btimes_print_everynth_8th} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 10) {
                $params->{btimes_print_everynth_10th} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 20) {
                $params->{btimes_print_everynth_20th} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 30) {
                $params->{btimes_print_everynth_30th} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 40) {
                $params->{btimes_print_everynth_40th} = $print_nth;
                last SWITCH;
            } elsif ($print_nth eq 50) {
                $params->{btimes_print_everynth_50th} = $print_nth;
                last SWITCH;
            }       
        }
        
        # Set whether to generate an image map
        if ($withmap > 0) {
            $params->{btimes_map_enabled} = '1';

            if ($map_type eq 'client') {
                $params->{btimes_map_type_client} = $map_type;
            } elsif ($map_type eq 'server') {
                $params->{btimes_map_type_server} = $map_type;
            } else {
                $params->{btimes_map_type_client} = 'client'; # fallback
            }
            
            SWITCH: {
                if ($linkto eq 'Individual') {
                    $params->{btimes_linkto_archive_individual} = $linkto;
                    last SWITCH;
                } elsif ($linkto eq 'Daily') {
                    $params->{btimes_linkto_archive_daily} = $linkto;
                    last SWITCH;
                } elsif ($linkto eq 'Weekly') {
                    $params->{btimes_linkto_archive_weekly} = $linkto;
                    last SWITCH;
                } elsif ($linkto eq 'Monthly') {
                    $params->{btimes_linkto_archive_monthly} = $linkto;
                    last SWITCH;
                } elsif ($linkto eq 'Category') {
                    $params->{btimes_linkto_archive_category} = $linkto;
                    last SWITCH;
                } else {
                    $params->{btimes_linkto_archive_monthly} = 'Monthly';
                    last SWITCH;
                }
            }
        }
        
        # Set whether to convert the labels on the abscissa scale
        if ($cscale > 0) {
            $params->{btimes_convert_scale_enabled} = '1';
        }
    } else {
        # No data from DB retrieved, setting defaults.
        # Note: We won't set the template BTIMES_MAP_ENABLED,
        # to disable the corresponding checkbox by default.
        # The same applies to BTIMES_CONVERT_SCALE_ENABLED.
        $params->{btimes_mode_classic} = 'classic';
        $params->{btimes_ctype_classic} = 'classic';
        $params->{btimes_apitype_gd} = 'gd';
        $params->{btimes_sdir} = 'images';
        $params->{btimes_print_everynth_2nd} = 2;
    }

    $self->SUPER::build_page($templateName, $params);
}

sub plugin_uri
{
    my $self = shift;
    
    # HACK, but at least one that won't break if the problem is fixed; the
    #  downside is we won't be flexible to our plugin being moved.  curses.
    # More specifically:
    # - fixed, moved deeper in plugins => okay
    # - fixed, moved out of plugins => breakage
    # - not fixed, moved anywhere => breakage
    if($self->path =~ m!plugins/! or $self->script =~ m!plugins/!)
    {
        return $self->path . $self->script;
    }
    else
    {
        return $self->path . $self->script;
    }
}

sub uri {
    my $self = shift;
    
    if($self->{author})
    {
        return $self->path . MT::ConfigMgr->instance->AdminScript;
    }
    else
    {
        return $self->plugin_uri;
    }
}

# Authorize user.  The user must have template editing permissions on some blog
#  in able to use our functionality.  The rationale is that we allow arbitrary
#  queries to be run against the entire database, so the user had better be able
#  to already get at all this information; also, it only makes sense to be able
#  to use this interface if the user can actually modify templates to use our
#  functionality in production.  The template editing permission meets both of
#  these requirements.  If the user can change templates, the user can have
#  any information in the database spit out into an html file (from any blog),
#  as I do not  believe there are any protections against this in the system.
#  Likewise, BTimes is only useful to those who can invoke its mechanisms in
#  templates.
sub is_authorized
{
    my $self = shift;
    require MT::Permission;
    
    if( $self->{author} )
    {
        my @perms  = MT::Permission->load({author_id => $self->{author}->id });
            
        for my $perm (@perms)
        {
            if($perm->can_edit_templates)
            {
                $self->{AUTH_BLOG_ID} = $perm->blog_id;
                return 1;
            }
        }
        
        $self->error(
            $self->translate("You are not authorized to use this tool."));
    }
    else # is this even possible?  better redundant than rooted!
    {
        $self->error($self->translate("You need to log in!"));
    }
}

# ui methods
sub init {
    my $self = shift;
    $self->SUPER::init(@_) or return;
    
    # Register our processing methods.
    $self->add_methods(
        'save' => \&saveMode,
    );
    
    # start at the main menu
    $self->{default_mode} = 'save';
    
    # Only people with an account can login.  We will further restrict this
    #  so that they must have template editing permissions can use us.
    $self->{requires_login} = 1;
    
    # Use the standard MT user authentication mechanism; author!
    $self->{user_class} = 'MT::Author';
    
    # Overwrite the default breadcrumb
    $self->{breadcrumbs} = [ { bc_name => $self->translate('MT-BlogTimes'),
                               bc_uri => $self->plugin_uri() } ];
    
    $self;
}

sub _procSave
{
    my $self = shift;
    my ($query, $params, $displayResults) = @_;    
    my ($pdata_obj, $data_holder);

    my $req = MT::Request->instance();
    my $mode = $query->param('btimes_mode');
    my $ctype = $query->param('btimes_ctype');
    my $apitype = $query->param('btimes_apitype');
    my $print_nth = $query->param('btimes_print_everynth');
    my $linkto = $query->param('btimes_linkto_archive') || 'Individual';
    
    $pdata_obj = $req->cache('blogtimes_cfg_pdataobj');
    unless ($pdata_obj) {
        $pdata_obj = MT::PluginData->load({plugin => 'MT-BlogTimes',
                                           key => 'configuration'});
    }
    
    if (!$pdata_obj) {
        $pdata_obj = MT::PluginData->new;
        $pdata_obj->plugin('MT-BlogTimes');
        $pdata_obj->key('configuration');
    }
    
    # Save data to plugindata
    $data_holder = $pdata_obj->data;    
    $data_holder->{'btimes_mode'} = $mode || 'classic';
    $data_holder->{'btimes_ctype'} = $ctype || 'classic';
    $data_holder->{'btimes_apitype'} = $apitype || 'gd';
    $data_holder->{'btimes_sdir'} = $query->param('btimes_sdir') || 'images';
    $data_holder->{'btimes_withmap'} = $query->param('btimes_withmap') || '0';
    $data_holder->{'btimes_maptype'} = $query->param('btimes_map_type') || 'client';
    $data_holder->{'btimes_linkto'} = $linkto || 'Monthly';
    $data_holder->{'btimes_cscale'} = $query->param('btimes_cscale') || '0';
    
    if ($print_nth eq 'any') {
        $data_holder->{'btimes_printnth'} = 1 || 2;
    } else {
        $print_nth =~ m/th$/ ? $print_nth =~ s/th$// : $print_nth =~ s/nd$//;
        $data_holder->{'btimes_printnth'} = $print_nth || 2;
    }

    $pdata_obj->data($data_holder);
    $pdata_obj->save or die $pdata_obj->errstr;
    
    $params->{btimes_saved} = 'Plugin data was successfully saved.';
    
    # set template parameters
    if ($mode eq 'classic') {
        $params->{btimes_mode_classic} = $mode;
    } elsif ($mode eq 'daily') {
        $params->{btimes_mode_daily} = $mode;
    } elsif ($mode eq 'weekly') {
        $params->{btimes_mode_weekly} = $mode;
    } elsif ($mode eq 'monthly') {
        $params->{btimes_mode_monthly} = $mode;
    } elsif ($mode eq 'yearly') {
        $params->{btimes_mode_yearly} = $mode;
    } elsif ($mode eq 'yearly_exone') {
        $params->{btimes_mode_yearly_exone} = $mode;
    } elsif ($mode eq 'yearly_extwo') {
        $params->{btimes_mode_yearly_extwo} = $mode;
    }
    
    if ($ctype eq 'bars') {
        $params->{btimes_ctype_bars} = $ctype;
    } elsif ($ctype eq 'bars3d') {
        $params->{btimes_ctype_bars3d} = $ctype;
    } elsif ($ctype eq 'lines') {
        $params->{btimes_ctype_lines} = $ctype;
    } elsif ($ctype eq 'lines3d') {
        $params->{btimes_ctype_lines3d} = $ctype;
    } elsif ($ctype eq 'classic') {
        $params->{btimes_ctype_classic} = $ctype;
    }
    
    if ($apitype eq 'gd') {
        $params->{btimes_apitype_gd} = $apitype;
    } elsif ($apitype eq 'im') {
        $params->{btimes_apitype_im} = $apitype;
    } elsif ($apitype eq 'svg') {
        $params->{btimes_apitype_svg} = $apitype;
    } elsif ($apitype eq 'swf') {
        $params->{btimes_apitype_swf} = $apitype;
    }
    
    # Set how many labels should be printed on the abscissa scale
    SWITCH: {
        if ($print_nth eq 1) {
            $params->{btimes_print_everynth_any} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 2) {
            $params->{btimes_print_everynth_2nd} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 4) {
            $params->{btimes_print_everynth_4th} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 6) {
            $params->{btimes_print_everynth_6th} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 8) {
            $params->{btimes_print_everynth_8th} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 10) {
            $params->{btimes_print_everynth_10th} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 20) {
            $params->{btimes_print_everynth_20th} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 30) {
            $params->{btimes_print_everynth_30th} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 40) {
            $params->{btimes_print_everynth_40th} = $print_nth;
            last SWITCH;
        } elsif ($print_nth eq 50) {
            $params->{btimes_print_everynth_50th} = $print_nth;
            last SWITCH;
        }
    }
    
    SWITCH: {
        if ($linkto eq 'Individual') {
            $params->{btimes_linkto_archive_individual} = $linkto;
            last SWITCH;
        } elsif ($linkto eq 'Daily') {
            $params->{btimes_linkto_archive_daily} = $linkto;
            last SWITCH;
        } elsif ($linkto eq 'Weekly') {
            $params->{btimes_linkto_archive_weekly} = $linkto;
            last SWITCH;
        } elsif ($linkto eq 'Monthly') {
            $params->{btimes_linkto_archive_monthly} = $linkto;
            last SWITCH;
        } elsif ($linkto eq 'Category') {
            $params->{btimes_linkto_archive_category} = $linkto;
            last SWITCH;
        }
    }
    
    $params->{btimes_sdir} = $data_holder->{'btimes_sdir'};
    $params->{btimes_map_enabled} = 'enabled' if $query->param('btimes_withmap');
    $params->{btimes_map_type_client} = 'client' if ($query->param('btimes_map_type_client'));
    $params->{btimes_map_type_server} = 'server' if ($query->param('btimes_map_type_server'));
    $params->{btimes_convert_scale_enabled} = 'enabled' if $query->param('btimes_cscale');
    
    # Cache plugindata in MT::Request
    $req->cache('blogtimes_cfg_pdataobj', $pdata_obj);
}

sub saveMode {
    my $self = shift;
    my $query = $self->{query};
    
    my %params = ();

    # btimes_dir is a textfield which can be
    # empty, thus this field will be used to
    # check whether the response contains
    # valid data.    
    if($query->param('btimes_sdir'))
    {
        $self->_procSave($query, \%params, 1);    
    }
    
    $self->build_page('blogtimes.tmpl', \%params);
}

# tag methods
sub BlogTimes {
    my($ctx, $args) = @_;
    my($mode, $chart_type, $image_api_type, $with_map, $map_type, $convert_scale, $width, $height, $linkto, $name, $print_every_nth, $save_dir, $linecolor, $textcolor, $fillcolor, $bordercolor, $padding, $show_text, $period);
    my($day, $week, $month, $year);

    if (exists $args->{debug}) {
        $DEBUG = 1;
    }

    # Blog related stuff
    my $blog = $ctx->stash('blog');
    my $archive_types = $blog->archive_type;
    my $site_path = $blog->site_path . '/';
    $site_path =~ s|(/)+$|/|g;
    my $site_url = $blog->site_url . '/';
    $site_url =~ s|(/)+$|/|g;

    my $tokens = $ctx->stash('tokens');
    my $builder = $ctx->stash('builder');
    
    $args = handle_expressions($ctx, $args);
    
    my $pdata_obj = MT::PluginData->load({plugin => 'MT-BlogTimes', key => 'configuration'});
    my $data_holder = $pdata_obj->data;

    # Mode
    #if ($args->{mode}) {
    #	grep {/$args->{mode}/} @arg_mode
    #	    or return $ctx->error("MTBlogTimes: " . $args->{mode} . " isn't a valid value for the mode attribute. Try one of these vaules: " . join(', ', @arg_mode));
    #}
    $mode = lc ($args->{mode}) || $data_holder->{'btimes_mode'} || 'classic';
    
    # should we print every label on the abscissa scale?
    $print_every_nth = ($args->{pevery_nth}) || $data_holder->{'btimes_printnth'} || 2;
    
    # should we convert the numerical abscissa scale into text values?
    if (($args->{cscale}) && lc ($args->{cscale}) eq 'on') {
        $convert_scale = 1;
    } else {
        $convert_scale = $data_holder->{'btimes_cscale'} || 0;;
    }

    # Chart Style
    #if ($args->{style}) {
    #	grep {/$args->{mode}/} @arg_type
    #	    or return $ctx->error("MTBlogTimes: " . $args->{style} . " isn't a valid chart type for the style attribute. Try one of these vaules: " . join(', ', @arg_type));
    #}
    $chart_type = lc ($args->{style}) || $data_holder->{'btimes_ctype'} || 'classic';
    
    # Image API which should be used to create the actual image.
    # Could be either GD, IM, SVG org SWF
    $image_api_type = lc ($args->{api}) || $data_holder->{'btimes_apitype'} || 'gd';
    
    # Test whether to generate an image map
    if (($args->{map}) && lc ($args->{map}) eq 'on') {
        $with_map = 1;
    } else {
        $with_map = $data_holder->{'btimes_withmap'} || 0;
    }
    
    # if applicable, what kind of an image map should be generated?    
    $map_type = lc ($args->{map_type}) || $data_holder->{'btimes_maptype'}  || 'client';
    
    # to what kinda archive should we link a particular map area?
    $linkto = ucfirst ($args->{linkto}) || $data_holder->{'btimes_linkto'}  || 'Individual';

    # Image Width
    $width = ($args->{width}) || $data_holder->{'btimes_apitype'} || 400;

    # Image Height
    $height = ($args->{height}) || 30;

    # Image File Name
    $name = ($args->{name}) || 'blogtimes';

    # Subdir used to store the image. Ideally the variable
    # should be specified once in the MT configuration console.
    $save_dir = ($args->{save_dir}) || $data_holder->{'btimes_sdir'} . '/' || 'images/';
    $save_dir =~ s|(/)+$|/|g;
    
    # Line Color
    $linecolor = ($args->{linecolor}) || '#FFFFFF';

    # Text Color
    $textcolor = ($args->{textcolor}) || '#4a4a4a';

    # Bar Background Color
    $fillcolor = ($args->{fillcolor}) || '#4a4a4a';

    # Border Color
    $bordercolor = ($args->{bordercolor}) || '#4a4a4a';

    # Padding
    $padding = ($args->{padding}) || 5;

    # Show Text?
    $show_text = lc ($args->{show_text}) || "on";

    # The period which should be ploted.
    SWITCH: {
	    if ($mode eq 'classic' || $mode eq 'daily' ||
	        $mode eq 'monthly' || $mode eq 'yearly' ||
	        $mode eq 'yearly_exone' || $mode eq 'yearly_extwo') {
		    $day = substr(($args->{period}),6,2) || substr($current_date,6,2);
		    $month = substr(($args->{period}),4,2) || substr($current_date,4,2);
		    $year = substr(($args->{period}),0,4) || substr($current_date,0,4);
            $week = substr(($args->{period}),8,2) || Week_Number($year, $month, $day);
            $week < 53 or return $ctx->error("Inpropper week format.");
		    last SWITCH;
	    }
        if ($mode eq 'weekly') {
            $day = substr(($args->{period}),6,2) || substr($current_date,6,2);
            $month = substr(($args->{period}),4,2) || substr($current_date,4,2);
            $year = substr(($args->{period}),0,4) || substr($current_date,0,4);
            $week = substr(($args->{period}),8,2) || Week_Number($year, $month, $day);
            $week < 53 or return $ctx->error("Inpropper week format.");
            
            # wee need the week without the leading zero
  	        $week =~ s/^0// if ($week =~ m/^0/);
            last SWITCH;
        }
    }


    # Get entries for specified month
    # date_start and date_end are formated as YYYYMMDDHHMMSS.
    # See MT::Entry for details.
    my ($date_start, $date_end);

    SWITCH: {
    	if ($mode eq 'classic') {
    	    $date_start = sprintf("%04d%02d%02d%06d",$year,$month,'01','000000');
    	    $date_end = sprintf("%04d%02d%02d%06d",$year,$month,
    			   Days_in_Month($year,$month),'235959');
    	    last SWITCH;
    	}
    	if ($mode eq 'daily') {
    	    $date_start = sprintf("%04d%02d%02d%06d",$year,$month,$day,'000000');
    	    $date_end = sprintf("%04d%02d%02d%06d",$year,$month,$day,'235959');
    	    last SWITCH;
    	}
    	if ($mode eq 'monthly') {
    	    $date_start = sprintf("%04d%02d%02d%06d",$year,$month,'01','000000');
    	    $date_end = sprintf("%04d%02d%02d%06d",$year,$month,
    				Days_in_Month($year,$month),'235959');
    	    last SWITCH;
    	}
    	if ($mode eq 'yearly' || $mode eq 'yearly_exone' || $mode eq 'yearly_extwo') {
    	    $date_start = sprintf("%04d%02d%02d%06d",$year,'01','01','000000');
    	    $date_end = sprintf("%04d%02d%02d%06d",$year,'12','31','235959');
    	    last SWITCH;
    	}
    	if ($mode eq 'weekly') {
    	    # Get the date of the actuall week
    	    my @datea_start = Monday_of_Week($week,$year);
    	    my @datea_end = Add_Delta_Days(Monday_of_Week(Week_of_Year(@datea_start)),6);
     
    	    $date_start = sprintf("%04d%02d%02d%06d",
                $datea_start[0],$datea_start[1],$datea_start[2],'000000');
    	    $date_end = sprintf("%04d%02d%02d%06d",
                $datea_end[0],$datea_end[1],$datea_end[2],'235959');
    	    last SWITCH;
    	}
    }

    if (! defined($date_start) || ! defined($date_end) ||
	   length($date_start) == 0 || length($date_end) == 0) {
	       return $ctx->error("Missing start or end of period.")
    }

    my (@entry_times, @entries, @entries_sorted, $entry, $denominator, $figure, $map);

    # get entries from the blog within the
    # range of start/end date.
    @entries = MT::Entry->load({ blog_id => $ctx->stash('blog_id'),
				 created_on => [ $date_start, $date_end ] ,
				 status => MT::Entry::RELEASE() },
			     { range => { created_on => 1 }});
			     
	@entries_sorted = sort { $a->created_on <=> $b->created_on } @entries;
			     
    # create a map object if such an object is required.
    my $mfactory = MTPlugins::MTBlogTimes::MapFactory->mfinstance();
    $map = $mfactory->map($map_type) if $mfactory or die "Can't retrieve map factory instance.";

    # no put the appropriate entry into the entry_times array
    SWITCH: {
        if ($mode eq 'classic') {
            $denominator = 1440;
            # create the hotspots array etc.
            my (@hotspots_array);
            
            if ($chart_type eq 'classic') {
                # puts HHMMSS into the array
                foreach $entry (@entries_sorted) {
                  push @entry_times, substr($entry->created_on, 8, 4);
                  
                  # initialize the map object if applicable
                  if ($with_map > 0) {
                    my %hotspot_hash = ( type => 'rect',
                                         coords => undef,
                                         title => $entry->title,
                                         created => $entry->created_on,
                                         uri => $entry->archive_url($linkto)
                    );
                    
                    push @hotspots_array, \%hotspot_hash;
                  }
                }
            } else {                
                # initialize the array with default values
                for (my $i = 0; $i < 24; $i++) {
                    push @entry_times, 0;
                }
                # puts HHMMSS into the array
                foreach $entry (@entries_sorted) {
                    my $hour = substr($entry->created_on, 8, 2);
                    
                    # initialize the map object if applicable
                    if ($with_map > 0 && $entry_times[$hour] == 0) {
                        my %hotspot_hash = ( type => 'rect',
                                             coords => undef,
                                             title => $entry->title,
                                             created => $entry->created_on,
                                             uri => $entry->archive_url($linkto)
                        );
                    
                        push @hotspots_array, \%hotspot_hash;
                    }
                    
                    $entry_times[$hour] += 1;
                }
            }
            
            $map->hotspots(\@hotspots_array) if $with_map > 0;
            last SWITCH;
        }
    	if ($mode eq 'daily') {
            $denominator = 1440;
            # create the hotspots array etc.
            my (@hotspots_array);
                
            if ($chart_type eq 'classic') {
        	    # puts HHMMSS into the array
        	    foreach $entry (@entries_sorted) {
        		  push @entry_times, substr($entry->created_on, 8, 4);
        		  
                  # initialize the map object if applicable
                  if ($with_map > 0) {
                    my %hotspot_hash = ( type => 'rect',
                                         coords => undef,
                                         title => $entry->title,
                                         created => $entry->created_on,
                                         uri => $entry->archive_url($linkto)
                    );
                    
                    push @hotspots_array, \%hotspot_hash;
                  }
        	    }
            } else {
                # initialize the array with default values
                for (my $i = 0; $i < 24; $i++) {
                    push @entry_times, 0;
                }
                # puts HHMMSS into the array
                foreach $entry (@entries_sorted) {
                    my $hour = substr($entry->created_on, 8, 2);
                    
                    # initialize the map object if applicable
                    if ($with_map > 0 && $entry_times[$hour] == 0) {
                        my %hotspot_hash = ( type => 'rect',
                                             coords => undef,
                                             title => $entry->title,
                                             created => $entry->created_on,
                                             uri => $entry->archive_url($linkto)
                        );
                    
                        push @hotspots_array, \%hotspot_hash;
                    }
                    
                    $entry_times[$hour] += 1;
                }
            }
    
            $map->hotspots(\@hotspots_array) if $with_map > 0;
    	    last SWITCH;
    	}
    	if ($mode eq 'weekly') {
            $denominator = 7;
            # create the hotspots array etc.
            my (@hotspots_array);
                
            if ($chart_type eq 'classic') {
        	    # 1 - 7 into the array where 1 eq Monday and 7 eq Sunday
        	    foreach $entry (@entries_sorted) {
        		  push @entry_times, Day_of_Week(substr($entry->created_on, 0, 4),
        					       substr($entry->created_on, 4, 2),
        					       substr($entry->created_on, 6, 2));
        					       
                  # initialize the map object if applicable
                  if ($with_map > 0) {
                    my %hotspot_hash = ( type => 'rect',
                                         coords => undef,
                                         title => $entry->title,
                                         created => $entry->created_on,
                                         uri => $entry->archive_url($linkto)
                    );
                    
                    push @hotspots_array, \%hotspot_hash;
                  }
        	    }
            } else {
                # initialize the array with default values
                for (my $i = 0; $i < 7; $i++) {
                    push @entry_times, 0;
                }
                # put the week day into the array
                foreach $entry (@entries_sorted) {
                    my $dow = Day_of_Week(substr($entry->created_on, 0, 4),
            					          substr($entry->created_on, 4, 2),
            					          substr($entry->created_on, 6, 2));
            					          
                    # initialize the map object if applicable
                    if ($with_map > 0 && $entry_times[$dow - 1] == 0) {
                        my %hotspot_hash = ( type => 'rect',
                                             coords => undef,
                                             title => $entry->title,
                                             created => $entry->created_on,
                                             uri => $entry->archive_url($linkto)
                        );
                    
                        push @hotspots_array, \%hotspot_hash;
                    }
            					          
                    $entry_times[$dow - 1] += 1;
                }
            }
    
            $map->hotspots(\@hotspots_array) if $with_map > 0;
    	    last SWITCH;	    
    	}
    	if ($mode eq 'monthly') {
    	    $denominator = Days_in_Month($year,$month);
            # create the hotspots array etc.
            my (@hotspots_array);
                
            if ($chart_type eq 'classic') {
        	    # puts 1 - Days_in_Month into the array
        	    foreach $entry (@entries_sorted) {
        		    push @entry_times, substr($entry->created_on, 6, 2);
        		  
                    # initialize the map object if applicable
                    if ($with_map > 0) {
                      my %hotspot_hash = ( type => 'rect',
                                           coords => undef,
                                           title => $entry->title,
                                           created => $entry->created_on,
                                           uri => $entry->archive_url($blog->archive_type_preffered)
                      );
                      
                      push @hotspots_array, \%hotspot_hash;
                    }
        	    }
            } else {
                # initialize the array with default values
                for (my $i = 0; $i < Days_in_Month($year,$month); $i++) {
                    push @entry_times, 0;
                }
                # now put the corresponding day into the array
                foreach $entry (@entries_sorted) {
                    my $day = substr($entry->created_on, 6, 2);
                    
                    # initialize the map object if applicable
                    if ($with_map > 0 && $entry_times[$day - 1] == 0) {
                      my %hotspot_hash = ( "type" => 'rect',
                                           "coords" => undef,
                                           "title" => $entry->title,
                                           "created" => $entry->created_on,
                                           "uri" => $entry->archive_url("Daily")
                      );
                      
                      push @hotspots_array, \%hotspot_hash;
                    }
                    
                    $entry_times[$day - 1] += 1;
                }
            }
            
            $map->hotspots(\@hotspots_array) if $with_map > 0;    
    	    last SWITCH;
    	}
    	if ($mode eq 'yearly') {
            $denominator = 12;
            # create the hotspots array etc.
            my (@hotspots_array);
            
            if ($chart_type eq 'classic') {
        	    # puts 1 - 12 into the array
        	    foreach $entry (@entries_sorted) {
        		  push @entry_times, substr($entry->created_on, 0, 8);
        		  
                  # initialize the map object if applicable
                  if ($with_map > 0) {
                    my %hotspot_hash = ( type => 'rect',
                                         coords => undef,
                                         title => $entry->title,
                                         created => $entry->created_on,
                                         uri => $entry->archive_url($linkto)
                    );
                  
                    push @hotspots_array, \%hotspot_hash;
                  }
        	    }
        	   
            } else {
                # initialize the array with default values
                for (my $i = 0; $i < 12; $i++) {
                    push @entry_times, 0;
                }
                # now put the corresponding month into the array
                foreach $entry (@entries_sorted) {
                    my $month = substr($entry->created_on, 4, 2);
                    
                    # initialize the map object if applicable
                    if ($with_map > 0 && $entry_times[$month - 1] == 0) {
                      my %hotspot_hash = ( "type" => 'rect',
                                           "coords" => "undefined",
                                           "title" => $entry->title,
                                           "created" => $entry->created_on,
                                           "uri" => $entry->archive_url($linkto)
                      );
                      
                      push @hotspots_array, \%hotspot_hash;
                    }
                    
                    $entry_times[$month - 1] += 1;
                }
            }

            $map->hotspots(\@hotspots_array) if $with_map > 0;    
    	    last SWITCH;
    	}
    	if ($mode eq 'yearly_exone') {
            $denominator = 53;
            # create the hotspots array etc.
            my (@hotspots_array);
            
            if ($chart_type eq 'classic') {
        	    # puts 1 - 53 into the array
        	    foreach $entry (@entries_sorted) {
        	      my $_day = substr($entry->created_on, 6, 2);
        	      my $_month = substr($entry->created_on, 4, 2);
        	      my $_year = substr($entry->created_on, 0, 4);
        	      my @woy = Week_of_Year($_year,$_month,$_day);
        	      
        	      if ($woy[1] == $_year - 1) {
        	          # NOP - The given entry belongs to the last year. 
        	      } else {
            		  push @entry_times, $woy[0];
            		  
                      # initialize the map object if applicable
                      if ($with_map > 0) {
                        my %hotspot_hash = ( type => 'rect',
                                             coords => undef,
                                             title => $entry->title,
                                             created => $entry->created_on,
                                             uri => $entry->archive_url($linkto)
                        );
                        
                        push @hotspots_array, \%hotspot_hash;
                      }
        	      }
        	    }
            } else {
                # initialize the array with default values
                for (my $i = 0; $i < 53; $i++) {
                    push @entry_times, 0;
                }
                # now put the corresponding month into the array
                foreach $entry (@entries_sorted) {
        	        my $_day = substr($entry->created_on, 6, 2);
        	        my $_month = substr($entry->created_on, 4, 2);
        	        my $_year = substr($entry->created_on, 0, 4);
        	        my @woy = Week_of_Year($_year,$_month,$_day);
        	        
            	    if ($woy[1] == $_year - 1) {
            	        # NOP - The given entry belongs to the last year. 
            	    } else {
                        # initialize the map object if applicable
                        if ($with_map > 0 && $entry_times[$woy[0] - 1] == 0) {
                          my %hotspot_hash = ( "type" => 'rect',
                                               "coords" => "undefined",
                                               "title" => $entry->title,
                                               "created" => $entry->created_on,
                                               "uri" => $entry->archive_url($linkto)
                          );
                          
                          push @hotspots_array, \%hotspot_hash;
                        }
                        
                	    $entry_times[$woy[0] - 1] += 1;;
            	    }
                }
            }

            $map->hotspots(\@hotspots_array) if $with_map > 0;        
    	    last SWITCH;
    	}
    	if ($mode eq 'yearly_extwo') {
            $denominator = 365;
            # create the hotspots array etc.
            my (@hotspots_array);
            
            if ($chart_type eq 'classic') {
        	    # puts 1 - 365 into the array
        	    foreach $entry (@entries_sorted) {
        		  push @entry_times, substr($entry->created_on, 6, 2);
        		  
                  # initialize the map object if applicable
                  if ($with_map > 0) {
                    my %hotspot_hash = ( type => 'rect',
                                         coords => undef,
                                         title => $entry->title,
                                         created => $entry->created_on,
                                         uri => $entry->archive_url($linkto)
                    );
                  
                    push @hotspots_array, \%hotspot_hash;
                  }
        	    }
            } else {
                # initialize the array with default values
                for (my $i = 0; $i < 365; $i++) {
                    push @entry_times, 0;
                }
                # now put the corresponding month into the array
                foreach $entry (@entries_sorted) {
                    my $doy = Day_of_Year(substr($entry->created_on, 0, 4),
                                          substr($entry->created_on, 4, 2),
                                          substr($entry->created_on, 6, 2));
                                          
                    # initialize the map object if applicable
                    if ($with_map > 0 && $entry_times[$doy - 1] == 0) {
                      my %hotspot_hash = ( "type" => 'rect',
                                           "coords" => "undefined",
                                           "title" => $entry->title,
                                           "created" => $entry->created_on,
                                           "uri" => $entry->archive_url($linkto)
                      );
                      
                      push @hotspots_array, \%hotspot_hash;
                    }
                                          
                    $entry_times[$doy - 1] += 1;
                }
            }

            $map->hotspots(\@hotspots_array) if $with_map > 0;            
    	    last SWITCH;
    	}
    }
    
    eval {
        # create a figure according to the image api type
        my $ffactory = MTPlugins::MTBlogTimes::FigureFactory->ffinstance();
        $figure = $ffactory->figure($image_api_type) if $ffactory or die "Can't retrieve figure factory instance.";
    
        # initialize basic map properties
        $map->name($name) if $with_map > 0;
        $map->basename("$site_path$save_dir") if $with_map > 0 && $map_type eq "server";
        $map->uri($site_url . $save_dir . $name . ".map") if $with_map > 0 && $map_type eq "server";
    
        # initialize the figure
        $figure->basename("$site_path$save_dir");
        $figure->bordercolor($bordercolor);
        $figure->fillcolor($fillcolor);
        $figure->linecolor($linecolor);
        $figure->textcolor($textcolor);
        my %dimension = (height => $height, width => $width);
        $figure->dimension(\%dimension);
        my %calendaric_values = (day => $day,
                                 month => $month,
                                 week => $week,
                                 year => $year,
                                 days_in_month => Days_in_Month($year,$month),
                                 week_of_year => 1,
                                 monday_of_week => ($week > 0 ? Monday_of_Week($week, $year) :
                                    Monday_of_Week(Weeks_in_Year($year), $year)),
                                 date_start => $date_start,
                                 date_end => $date_end);
        $figure->calendaric_values(\%calendaric_values);
        $figure->denominator($denominator);
        $figure->ctype($chart_type);
        $figure->mode($mode);
        $figure->name($name);
        $figure->padding($padding);
        $figure->text($show_text);
        $figure->title('B L O G T I M E S');
        $figure->printnth($print_every_nth);
        $figure->cscale($convert_scale);
        $figure->debug($DEBUG);
        
        #
        # Generate the label - Required for GD::Graph
        #
        my (@labels, $i);
        
        if ($mode eq 'classic') {
            for ($i = 0; $i < 24; $i++) {
                push @labels, $i;
            }
        } elsif ($mode eq 'daily') {
            for ($i = 0; $i < 24; $i++) {
                push @labels, $i;
            }
        } elsif ($mode eq 'weekly') {
            if ($convert_scale > 0) {
                for ($i = 0; $i <= 6; $i += $print_every_nth) {
                    push @labels, $figure->dateToText(date => $i + 1);
                }
            } else {
                for ($i = 0; $i <= 6; $i += $print_every_nth) {
                    push @labels, $i + 1;
                }
            }
        } elsif ($mode eq 'monthly') {
            if ($convert_scale > 0) {
                for ($i = 0; $i <= Days_in_Month($year,$month) - 1; $i += $print_every_nth) {
                    push @labels, $figure->dateToText(date => $i + 1);
                }
            } else {
                for ($i = 0; $i <= Days_in_Month($year,$month) - 1; $i += $print_every_nth) {
                    push @labels, $i + 1;
                }
            }
        } elsif ($mode eq 'yearly') {
            if ($convert_scale > 0) {
                for ($i = 0; $i <= 11; $i += $print_every_nth) {
                    push @labels, $figure->dateToText(date => $i + 1);
                }
            } else {
                for ($i = 0; $i <= 11; $i += $print_every_nth) {
                    push @labels, $i + 1;
                }
            }
        } elsif ($mode eq 'yearly_exone') {
            for ($i = 0; $i <= 51; $i += $print_every_nth) {
                push @labels, $i + 1;
            }
        } elsif ($mode eq 'yearly_extwo') {
            for ($i = 0; $i <= 364; $i += $print_every_nth) {
                push @labels, $i + 1;
            }
        }
        
        $figure->labels(\@labels);
        $figure->values(\@entry_times);
        $figure->map(\$map) if $with_map > 0;
    
        SWITCH: {
            if ($image_api_type eq 'gd') {
                $figure->extension('.png');
                last SWITCH;
            }
            if ($image_api_type eq 'im') {
                $figure->extension('.png');
                last SWITCH;
            }
            if ($image_api_type eq 'svg') {
                $figure->extension('.svg');
                last SWITCH;
            }
            if ($image_api_type eq 'swf') {
                $figure->extension('.swf');
                last SWITCH;
            }
        }
        
        # finally set the uri to the image we want to generate
        $figure->uri($site_url . $save_dir . $name . $figure->extension());
        
        # now draw/safe the figure
        $figure->draw();
        $figure->save();
    };
    
    if ($@) {
        $ctx->error("Error while creating figure: $@");
    }

    local $ctx->{__stash}{BlogTimesWidth} = $figure->swidth() if $chart_type eq 'classic';
    local $ctx->{__stash}{BlogTimesWidth} = $width if $chart_type ne 'classic';
    local $ctx->{__stash}{BlogTimesHeight} = $figure->sheight() if $chart_type eq 'classic';
    local $ctx->{__stash}{BlogTimesHeight} = $height if $chart_type ne 'classic';
    local $ctx->{__stash}{BlogTimesFilename} = $figure->name() . $figure->extension();
    local $ctx->{__stash}{BlogTimesFullFilename} = $figure->basename() . $figure->name() . $figure->extension();
    local $ctx->{__stash}{BlogTimesFileURL} = $figure->uri();
    local $ctx->{__stash}{BlogTimesMapname} = $map->name() if $with_map > 0;
    local $ctx->{__stash}{BlogTimesMapURL} = $map->uri() if $with_map > 0 && $map_type eq "server";

    defined(my $out = $builder->build($ctx, $tokens))
	   or return $ctx->error($builder->errstr);
	
	if ($with_map > 0) {
	   my $out_wmap = $map->map() . $out;
	   $map_type eq 'client' ? return $out_wmap : return $out;
	} else {
	   return $out;
	}
}

# Process MT tags in all arguments. Returns an argument reference
# with all tags processed (Borrowed from the MTAmazon plugin).
sub handle_expressions {
    my($ctx, $args) = @_;
    
    use MT::Util qw(decode_html);
    
    my %new_args;
    my $builder = $ctx->stash('builder');
    
    for my $arg (keys %$args) {
        my $expr = decode_html($args->{$arg});
        
        # TODO: It seems that the first RE is wrong,
        # at least it does not match the following string:
        # <MTBlogTimes period="<$MTDate format="%Y%m%d"$>">
        # old: $expr =~ m/\<MT.*?\>/g
        # new: $expr =~ m/<\$(.*?)\$>/g
        # alt: $expr =~ s/\[(MT(.*?))\]/<$1>/g)
        if ( $expr =~ m/<MT(.*?)>/g ||
             $expr =~ s/\[(MT(.*?))\]/<$1>/g) {
            my $tok = $builder->compile($ctx, $expr);
            my $out = $builder->build($ctx, $tok);
            
            return $ctx->error("Error in argument expression: ".$builder->errstr) unless defined $out;
            $new_args{$arg} = $out;
        } else {
            $new_args{$arg} = $expr;
        }
    }
    
    \%new_args;
}

sub _sort_by_date {
    my ($ahash_ref, $bhash_ref) = @_;
    my %ahash = %$ahash_ref;
    my %bhash = %$bhash_ref;
    
    return 1 if $ahash{created} > $bhash{created};
    return 0 if $ahash{created} == $bhash{created};
    return -1 if $ahash{created} < $bhash{created};
}

sub BlogTimesWidth        { $_[0]->stash('BlogTimesWidth')        || ''; }
sub BlogTimesHeight       { $_[0]->stash('BlogTimesHeight')       || ''; }
sub BlogTimesFilename     { $_[0]->stash('BlogTimesFilename')     || ''; }
sub BlogTimesMapname      { $_[0]->stash('BlogTimesMapname')      || ''; }
sub BlogTimesFullFilename { $_[0]->stash('BlogTimesFullFilename') || ''; }
sub BlogTimesFileURL      { $_[0]->stash('BlogTimesFileURL')      || ''; }
sub BlogTimesMapURL       { $_[0]->stash('BlogTimesMapURL')       || ''; }

1;
