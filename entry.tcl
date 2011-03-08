#!/bin/sh
# This line continues for Tcl, but is a single line for 'sh' \
    exec /usr/bin/wish "$0" -- ${1+"$@"}

package require Tk

# TODO should handle_id be tkwidgets-wide or per instance?

#------------------------------------------------------------------------------#
# tk widgets general purpose procs

set ::select_fill "#bdbddd"

namespace eval ::tkwidgets:: {
    variable handle_tag "tkwidgets-RESIZE"
    variable handle_size 15
}

proc ::tkwidgets::set_up_variables {instance tkcanvas} {
    set my ::$instance
    variable ${my}::receive_name "#$instance"
    variable ${my}::canvas_id "$tkcanvas"
    variable ${my}::frame_id "$tkcanvas.$instance-f"
    variable ${my}::widget_id "$frame_id.w"
    variable ${my}::handle_id "$canvas_id.handle"
    variable ${my}::window_tag "entrywindow$instance"
    variable ${my}::all_tag "entry$instance"
    variable ${my}::font [font create -family Helvetica -size 24]
}

proc ::tkwidgets::bind_mouse_events {my} {
    variable ${my}::canvas_id
    variable ${my}::widget_id
    bind $widget_id <ButtonPress> "pdtk_canvas_mouse $canvas_id \
                                       \[expr %X - \[winfo rootx $canvas_id]] \
                                       \[expr %Y - \[winfo rooty $canvas_id]] %b 0"
    bind $widget_id <ButtonRelease> "pdtk_canvas_mouseup $canvas_id \
                                         \[expr %X - \[winfo rootx $canvas_id]] \
                                         \[expr %Y - \[winfo rooty $canvas_id]] %b"
    bind $widget_id <Shift-Button> "pdtk_canvas_mouse $canvas_id \
                                        \[expr %X - \[winfo rootx $canvas_id]] \
                                        \[expr %Y - \[winfo rooty $canvas_id]] %b 1"
    bind $widget_id <Button-2> "pdtk_canvas_rightclick $canvas_id \
                                    \[expr %X - \[winfo rootx $canvas_id]] \
                                    \[expr %Y - \[winfo rooty $canvas_id]] %b"
    bind $widget_id <Button-3> "pdtk_canvas_rightclick $canvas_id \
                                    \[expr %X - \[winfo rootx $canvas_id]] \
                                    \[expr %Y - \[winfo rooty $canvas_id]] %b"
    bind $widget_id <Control-Button> "pdtk_canvas_rightclick $canvas_id \
                                          \[expr %X - \[winfo rootx $canvas_id]] \
                                          \[expr %Y - \[winfo rooty $canvas_id]] %b"
    # mouse motion
    bind $widget_id <Motion> "pdtk_canvas_motion $canvas_id \
                                  \[expr %X - \[winfo rootx $canvas_id]] \
                                  \[expr %Y - \[winfo rooty $canvas_id]] 0"
}

proc ::tkwidgets::erase_iolets {my} {
    variable ${my}::canvas_id
    variable ${my}::iolets_tag
    $canvas_id delete $iolets_tag
}

proc ::tkwidgets::resize_click {my receive_name state} {
    variable ${my}::handle_id
    if {$state} {
        bind $handle_id <Motion>  "::tkwidgets::resize_motion $my $receive_name %x %y"
    } else {
        bind $handle_id <Motion>  {}
    }
    pdsend "$receive_name resize_click $state"
}

proc ::tkwidgets::resize_motion {my receive_name x y} {
    variable handle_tag
    variable handle_size
    variable ${my}::canvas_id
    variable ${my}::window_tag
    variable ${my}::framex1
    variable ${my}::framex2
    variable ${my}::framey1
    variable ${my}::framey2

    set framex2 [expr $framex2 + $x]
    set width [expr $framex2 - $framex1]
    if [expr $width < 15] {
        set width 15
        set framex2 [expr $framex1 + 15]
    }
    set framey2 [expr $framey2 + $y]
    set height [expr $framey2 - $framey1]
    if [expr $height < 15] {
        set height 15
        set framey2 [expr $framey1 + 15]
    }
    $canvas_id itemconfigure $window_tag -width $width -height $height
    $canvas_id coords $handle_tag [expr $framex2 - $handle_size] \
        [expr $framey2 - $handle_size]
    pdsend "$receive_name resize_motion $x $y"
}

proc ::tkwidgets::make_resize_handle {my x y} {
    variable handle_tag
    variable handle_size
    variable ${my}::receive_name
    variable ${my}::canvas_id
    variable ${my}::handle_id
    variable ${my}::all_tag
    $canvas_id delete $handle_tag
    destroy $handle_id
    canvas $handle_id -width $handle_size -height $handle_size -bg #ddd -bd 0 \
        -highlightthickness 3 -highlightcolor #f00 -cursor bottom_right_corner
    $canvas_id create window [expr $x - $handle_size] [expr $y - $handle_size] -anchor nw \
        -width $handle_size -height $handle_size -window $handle_id -tags [list $handle_tag $all_tag]
    raise $handle_id
    bind $handle_id <ButtonPress>   "::tkwidgets::resize_click $my $receive_name 1"
    bind $handle_id <ButtonRelease> "::tkwidgets::resize_click $my $receive_name 0"
}

#------------------------------------------------------------------------------#

namespace eval ::tkwidgets::entry:: {
    # global variables for all instances
}

#------------------------------------------------------------------------------#
# support procs

proc ::tkwidgets::entry::save {my} {
}

proc ::tkwidgets::entry::eraseme {my} {
    variable ${my}::canvas_id 
    variable ${my}::all_tag
    $canvas_id delete $all_tag
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
    variable ${my}::font
    
    set canvas_id [tkcanvas_name $mytoplevel]
    frame $frame_id
    entry $widget_id -font $font -relief sunken
    pack $widget_id -side left -fill both -expand 1
    pack $frame_id -side bottom -fill both -expand 1
    $canvas_id create window $framex1 $framey1 -anchor nw -window $frame_id \
        -width [expr $framex2-$framex1] -height [expr $framey2-$framey1] \
        -tags [list $window_tag $all_tag]
    ::tkwidgets::bind_mouse_events $my
}

#------------------------------------------------------------------------------#
# widgetbehavior procs

proc ::tkwidgets::entry::setrect {my x1 y1 x2 y2} {
    variable ${my}::framex1 $x1
    variable ${my}::framey1 $y1
    variable ${my}::framex2 $x2
    variable ${my}::framey2 $y2
}

proc ::tkwidgets::entry::displace {my mytoplevel dx dy} {
    variable ${my}::all_tag
    variable ${my}::framex1
    variable ${my}::framey1
    variable ${my}::framex2
    variable ${my}::framey2
    set tkcanvas [tkcanvas_name $mytoplevel]
    $tkcanvas move $all_tag $dx $dy
    set framex1 [expr $framex1 + $dx]
    set framey1 [expr $framey1 + $dy]
    set framex2 [expr $framex2 + $dx]
    set framey2 [expr $framey2 + $dy]
}

proc ::tkwidgets::entry::select {my mytoplevel state} {
    variable ${my}::canvas_id
    variable ${my}::widget_id
    variable ${my}::handle_id
    variable ${my}::background
    
    if {$state} {
        set $background [$widget_id cget -background]
        $widget_id configure -background $::select_fill -state disabled \
            -cursor $::cursor_editmode_nothing
    } else {
        $widget_id configure -background $background -state normal -cursor xterm
        # activatefn never gets called with 0, so destroy handle here
        $canvas_id delete $handle_id
    }
}

proc ::tkwidgets::entry::activate {my mytoplevel state} {
    if {$state} {
        variable ${my}::framex2
        variable ${my}::framey2
        ::tkwidgets::make_resize_handle $my $framex2 $framey2
    }
}

proc ::tkwidgets::entry::delete {my mytoplevel} {
}

proc ::tkwidgets::entry::vis {my mytoplevel vis} {
    if {$vis} {
        drawme $my $mytoplevel
    } else {
        eraseme $my
    }
}

proc ::tkwidgets::entry::click {my mytoplevel xpix ypix shift alt dbl doit} {
}

#------------------------------------------------------------------------------#

# sets up an instance of the class
proc ::tkwidgets::entry::new {instance tkcanvas} {
    # build object instance using namespace hack
    set my ::$instance
    namespace eval $my {
        # declare all per-instance variables
        variable receive_name
        variable canvas_id
        variable frame_id
        variable widget_id
        variable handle_id
        variable window_tag
        variable iolets_tag
        variable all_tag

        variable framex1
        variable framey1
        variable framex2
        variable framey2
        variable font

        variable cursor
        variable background
    }
    ::tkwidgets::set_up_variables $instance $tkcanvas
    set ${my}::cursor "xterm"
    set ${my}::background "white"
    #bind PatchWindow <<EditMode>> {+tkwidgets::entry::set_for_editmode %W}    
}

# sets up the class
proc tkwidgets::entry::setup {} {


    # if loading in standalone mode without Pd, then create a window
    # and canvas to work with.
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
        set my ::123456
        ::tkwidgets::entry::new $my .c
        ::tkwidgets::entry::setrect $my 30 30 330 90
        ::tkwidgets::entry::vis $my "" 1
    }
}

tkwidgets::entry::setup
