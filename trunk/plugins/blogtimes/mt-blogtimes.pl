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

package MT::Plugin::MTBlogTimes;

use strict;
use vars qw($VERSION);
$VERSION = '0.1.0';

use MT;

return 1 unless $MT::VERSION =~ m(^3\.1);

use MT::Template::Context;

my $plugin;
use MT::Plugin;
$plugin = new MT::Plugin();
$plugin->name('MT-BlogTimes, v' . $VERSION);
$plugin->config_link('../../../mt-blogtimes.cgi');
$plugin->description('Renders your blog frequency as an image.');
$plugin->doc_link('http://www.daniel.stefan.haischt.name/');
MT->add_plugin($plugin);

MT->add_callback('CommentThrottleFilter', 2, $plugin, \&BlogTimes);

MT::Template::Context->add_container_tag(BlogTimes => sub { require MTPlugins::MTBlogTimes::BlogTimes; &MTPlugins::MTBlogTimes::BlogTimes::BlogTimes; });
MT::Template::Context->add_tag(BlogTimesWidth => sub { require MTPlugins::MTBlogTimes::BlogTimes; &MTPlugins::MTBlogTimes::BlogTimes::BlogTimesWidth; });
MT::Template::Context->add_tag(BlogTimesHeight => sub { require MTPlugins::MTBlogTimes::BlogTimes; &MTPlugins::MTBlogTimes::BlogTimes::BlogTimesHeight; });
MT::Template::Context->add_tag(BlogTimesFilename => sub { require MTPlugins::MTBlogTimes::BlogTimes; &MTPlugins::MTBlogTimes::BlogTimes::BlogTimesFilename; });
MT::Template::Context->add_tag(BlogTimesMapname => sub { require MTPlugins::MTBlogTimes::BlogTimes; &MTPlugins::MTBlogTimes::BlogTimes::BlogTimesMapname; });
MT::Template::Context->add_tag(BlogTimesFullFilename => sub { require MTPlugins::MTBlogTimes::BlogTimes; &MTPlugins::MTBlogimes::BlogTimes::BlogTimesFullFilename; });
MT::Template::Context->add_tag(BlogTimesFileURL => sub { require MTPlugins::MTBlogTimes::BlogTimes; &MTPlugins::MTBlogTimes::BlogTimes::BlogTimesFileURL; });
