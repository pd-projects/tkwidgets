#!/bin/sh
# This line continues for Tcl, but is a single line for 'sh' \
    exec /usr/bin/wish "$0" -- ${1+"$@"}

package require Tk

namespace eval ::tkwidgets::entry:: {
    # global variables for all instances
}

#------------------------------------------------------------------------------#
# tk widgets general purpose procs

namespace eval ::tkwidgets:: {
}

proc ::tkwidgets::resize_click {receive_name state} {
    pdsend "$receive_name resize_click $state"
}

proc ::tkwidgets::resize_motion {receive_name state} {
    pdsend "$receive_name resize_motion $"
}

proc ::tkwidgets::make_handle {my x y} {
    variable ${my}::receive_name
    variable ${my}::canvas_id
    variable ${my}::handle_id
    variable ${my}::framex2
    variable ${my}::framey2
    set size 10
    canvas $handle_id -width $size -height $size -bg #ddd -bd 0 \
        -highlightthickness 3 -highlightcolor #f00 -cursor bottom_right_corner
    $canvas_id create window [expr $framex2 - $size] [expr $framey2 - $size] -anchor nw \
        -width $size -height $size -window $handle_id -tags RESIZE
    raise $handle_id
    bind $handle_id <ButtonPress>   "::tkwidgets::resize_click $receive_name 1"
    bind $handle_id <ButtonRelease> "::tkwidgets::resize_click $receive_name 0"
    bind $handle_id <Motion>        "::tkwidgets::resize_motion $receive_name %x %y"
}

#------------------------------------------------------------------------------#
# widgetbehavior procs

proc ::tkwidgets::entry::setrect {my x1 y1 x2 y2} {
    variable ${my}::font
    variable ${my}::framex1 $x1
    variable ${my}::framey1 $y1
    variable ${my}::framex2 $x2
    variable ${my}::framey2 $y2
    # we receive the width in pixels but need to convert it to chars
    variable ${my}::width [expr int(($x2-$x1)/[font measure $font "n"])]
}

proc ::tkwidgets::entry::displace {my mytoplevel dx dy} {
    variable ${my}::all_tag
    set tkcanvas [tkcanvas_name $mytoplevel]
    $tkcanvas move $all_tag $dx $dy
}

proc ::tkwidgets::entry::select {my mytoplevel state} {
    variable ${my}::widget_id
    if {$state} {
        $widget_id configure -background #88f
    } else {
        $widget_id configure -background white
    }
}

proc ::tkwidgets::entry::activate {my mytoplevel state} {
    if {$state} {
    }
}

proc ::tkwidgets::entry::delete {my mytoplevel} {
}

proc ::tkwidgets::entry::vis {my mytoplevel vis} {
}

proc ::tkwidgets::entry::click {my mytoplevel xpix ypix shift alt dbl doit} {
}

proc tkwidgets::entry::save {} {
}


#------------------------------------------------------------------------------#

proc ::tkwidgets::entry::eraseme {my} {
    variable ${my}::all_tag
    ${my}::canvas_id delete $all_tag
}

proc ::tkwidgets::entry::drawme {my mytoplevel} {
    variable ${my}::canvas_id
    variable ${my}::frame_id
    variable ${my}::widget_id
    variable ${my}::window_tag
    variable ${my}::all_tag
    variable ${my}::framex1
    variable ${my}::framey1
    variable ${my}::framex2
    variable ${my}::framey2
    variable ${my}::width
    variable ${my}::font
    
    set canvas_id [tkcanvas_name $mytoplevel]
    frame $frame_id
    entry $widget_id -width $width -font $font -relief sunken
    pack $widget_id -side left -fill both -expand 1
    pack $frame_id -side bottom -fill both -expand 1
    $canvas_id create window $framex1 $framey1 -anchor nw -window $frame_id \
        -width [expr $framex2-$framex1] -height [expr $framey2-$framey1] \
        -tags [list $window_tag $all_tag]
}

# sets up an instance of the class
proc ::tkwidgets::entry::new {my tkcanvas} {
    # build object instance using namespace hack
    namespace eval $my {
        # declare all per-instance variables
        variable receive_name
        variable canvas_id
        variable frame_id
        variable widget_id
        variable handle_id
        variable window_tag
        variable all_tag

        variable framex1
        variable framey1
        variable framex2
        variable framey2
        variable width
        variable font
    }
    set ${my}::canvas_id $tkcanvas
    set ${my}::receive_name "#$my"
    set ${my}::frame_id $tkcanvas.$my-f
    set ${my}::widget_id $tkcanvas.$my-f.w 
    set ${my}::handle_id "handle"
    set ${my}::window_tag "entrywindow$my"
    set ${my}::all_tag "entry$my"
    set ${my}::font [font create -family Helvetica -size 24]
}

# sets up the class
proc tkwidgets::entry::setup {} {
    #bind PatchWindow <<EditMode>> {+tkwidgets::entry::set_for_editmode %W}    
    # check if we are Pd < 0.43, which has no 'pdsend', but a 'pd' coded in C
    if {[llength [info procs "::pdsend"]] == 0} {
        proc ::pdsend {args} {pd "[join $args { }] ;"}
    }

    # if not loading within Pd, then create a window and canvas to work with
    if {[llength [info procs "::pdtk_post"]] == 0} {
        catch {console show}
        puts stderr "setting up as standalone dev mode!"
        # this stuff creates a dev skeleton
        proc ::pdtk_post {args} {puts stderr "pdtk_post $args"}
        proc ::pdsend {args} {puts stderr "pdsend $args"}
        proc ::tkcanvas_name {mytoplevel} {return "$mytoplevel.c"}
        tk scaling 1
        wm geometry . 400x400+500+40
        canvas .c
        pack .c -side left -expand 1 -fill both
        set my 123456
        ::tkwidgets::entry::new $my .c
        ::tkwidgets::entry::setrect $my 30 30 330 90
        ::tkwidgets::entry::drawme $my ""
    }
}

tkwidgets::entry::setup
