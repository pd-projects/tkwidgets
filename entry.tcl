#!/bin/sh
# This line continues for Tcl, but is a single line for 'sh' \
    exec /usr/bin/wish "$0" -- ${1+"$@"}

package require Tk

namespace eval ::tkwidgets-entry:: {
    #------------------------------
    # global variables for all instances

    #------------------------------
    # per-instance variables
    variable mynamespace
    variable receive_name
    variable canvas_id
    variable frame_id
    variable widget_id
    variable handle_id

    variable window_tag

    variable framex1
    variable framey1
    variable framex2
    variable framey2
    variable width
    variable font [font create -family Helvetica -size 24]
}

proc tkwidgets-entry::setrect {x1 y1 x2 y2} {
    variable font
    variable framex1 $x1
    variable framey1 $y1
    variable framex2 $x2
    variable framey2 $y2
    # we receive the width in pixels but need to convert it to chars
    variable width [expr int(($x2-$x1)/[font measure $font "n"])]
}

proc tkwidgets-entry::eraseme {tkcanvas} {
    $tkcanvas delete filtergraph
}

proc tkwidgets-entry::drawme {tkcanvas name} {
    variable receive_name $name
    variable framex1
    variable framey1
    variable framex2
    variable framey2
    variable width
    variable font
    
    frame $tkcanvas.frame
    entry $tkcanvas.frame.entry -width $width -font $font -relief sunken
    pack $tkcanvas.frame.entry -side left -fill both -expand 1
    pack $tkcanvas.frame -side bottom -fill both -expand 1
    $tkcanvas create window $framex1 $framey1 -anchor nw -window $tkcanvas.frame    \
        -width [expr $framex2-$framex1] -height [expr $framey2-$framey1] \
        -tags [list window_tag all_tag]
}

# sets up an instance of the class
proc tkwidgets-entry::new {} { 
}

# sets up the class
proc tkwidgets-entry::setup {} {
    bind PatchWindow <<EditMode>> {+tkwidgets-entry::set_for_editmode %W}    
    # check if we are Pd < 0.43, which has no 'pdsend', but a 'pd' coded in C
    if {[llength [info procs "pdsend"]] == 0} {
        proc pdsend {args} {pd "[join $args { }] ;"}
    }

    # if not loading within Pd, then create a window and canvas to work with
    if {[llength [info procs "pdtk_post"]] == 0} {
        puts stderr "setting up as standalone dev mode!"
        # this stuff creates a dev skeleton
        proc pdtk_post {args} {puts stderr "pdtk_post $args"}
        proc pdsend {args} {puts stderr "pdsend $args"}
        tk scaling 1
        tkwidgets-entry::setrect 30 30 330 90
        wm geometry . 400x400+500+40
        canvas .c
        pack .c -side left -expand 1 -fill both
        tkwidgets-entry::drawme .c #tkwidgets-entry
    }
}

tkwidgets-entry::setup
catch {console show}
