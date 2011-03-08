
#include "m_pd.h"
#include "tkwidgets.h"

#define DEBUG(x) x

static t_class *entry_class;
static t_widgetbehavior entry_widgetbehavior;

typedef struct _entry
{
    t_object    x_obj;
    t_canvas*   x_canvas;      /* canvas this widget is currently drawn in */
    t_glist*    x_glist;       /* glist that owns this widget */
    t_binbuf*   options_binbuf;/* binbuf to save options state in */

    int         width;         /* only stores setting before vis happens */
    int         height;        /* only stores setting before vis happens */
    int         resizing;
    
    /* IDs for Tk widgets */
	t_symbol*   my; /* per-instance namespace for localizing Tcl vars */
    t_symbol*   receive_name;  /* name to bind to to receive callbacks */
    
    t_outlet*   x_data_outlet;
    t_outlet*   x_status_outlet;
} t_entry;

/* ------------------------------------------------------------------------ */
/* support functions */

/* ------------------------------------------------------------------------ */
/* callback functions */

static void entry_set_position(t_entry* x, t_float x1, t_float y1) 
{
    x->x_obj.te_xpix = (int)x1;
    x->x_obj.te_ypix = (int)y1;
}

static void entry_resize_click_callback(t_entry *x, t_floatarg f)
{
    t_canvas *canvas = (glist_isvisible(x->x_glist) ? x->x_canvas : 0);
    int button_state = (int)f;
    if(x->resizing && !button_state && canvas)
        canvas_fixlinesfor(x->x_glist, (t_text *)x);  // 2nd inlet
    x->resizing = button_state;
}

static void entry_resize_motion_callback(t_entry *x, t_floatarg f1, t_floatarg f2)
{
    if (x->resizing)
    {
        int dx = (int)f1, dy = (int)f2;
        if (glist_isvisible(x->x_glist))
        {
            x->width += dx;
            x->height += dy;
            canvas_fixlinesfor(x->x_glist, (t_text *)x);
        }
    }
}

/* ------------------------------------------------------------------------ */
/* methods for messages */

static void entry_position(t_entry* x, t_float width, t_float height) 
{
    // TODO
}

static void entry_size(t_entry* x, t_float width, t_float height) 
{
    // TODO
}

/* ------------------------------------------------------------------------ */
/* t_widgetbehavior functions */
static void entry_getrect(t_gobj *z, t_glist *glist,
                          int *xp1, int *yp1, int *xp2, int *yp2)
{
    t_entry *x = (t_entry *)z;

    *xp1 = text_xpix(&x->x_obj, glist);
    *yp1 = text_ypix(&x->x_obj, glist);
    *xp2 = text_xpix(&x->x_obj, glist) + x->width;
    *yp2 = text_ypix(&x->x_obj, glist) + x->height;
}

static void entry_displace(t_gobj *z, t_glist *glist, int dx, int dy)
{
    t_entry *x = (t_entry *)z;
    x->x_obj.te_xpix += dx;
    x->x_obj.te_ypix += dy;
    if (glist_isvisible(glist))
    {
        sys_vgui("::tkwidgets::entry::displace ::%lx .x%lx %d %d\n", z, glist, dx, dy);
        canvas_fixlinesfor(glist_getcanvas(glist), (t_entry*) x);
    }
}

static void entry_select(t_gobj *z, t_glist *glist, int state)
{
    sys_vgui("::tkwidgets::entry::select ::%lx .x%lx %d\n", z, glist, state);
}

static void entry_activate(t_gobj *z, t_glist *glist, int state)
{
    sys_vgui("::tkwidgets::entry::activate ::%lx .x%lx %d\n", z, glist, state);
}

static void entry_delete(t_gobj *z, t_glist *glist)
{
    sys_vgui("::tkwidgets::entry::delete ::%lx .x%lx\n", z, glist);
}

static void entry_vis(t_gobj *z, t_glist *glist, int vis)
{
    t_entry *x = (t_entry *)z;
    if (vis)
    {
        sys_vgui("::tkwidgets::entry::setrect ::%lx %d %d %d %d\n", 
                 x,
                 text_xpix(&x->x_obj, glist),
                 text_ypix(&x->x_obj, glist),
                 text_xpix(&x->x_obj, glist) + x->width,
                 text_ypix(&x->x_obj, glist) + x->height);
    }
    sys_vgui("::tkwidgets::entry::vis ::%lx .x%lx %d\n", x, glist, vis);
}

static int entry_click(t_gobj *z, t_glist *glist,
    int xpix, int ypix, int shift, int alt, int dbl, int doit)
{
    sys_vgui("::tkwidgets::entry::click ::%lx .x%lx %d %d %d %d %d %d\n", 
             z, glist, xpix, ypix, shift, alt, dbl, doit);
    // TODO this should return based on whether the widget received the click
    return 0;
}

/* ------------------------------------------------------------------------ */
/* pd-side functions */

static void entry_save(t_gobj *z, t_binbuf *b)
{
    sys_vgui("::tkwidgets::entry::save ::%lx\n", z);
}

static void* entry_new(t_symbol* s, int argc, t_atom *argv)
{
    t_entry* x = (t_entry*)pd_new(entry_class);

    x->options_binbuf = binbuf_new();

    /* default size 200x20 */
    x->width = 200;
    x->height = 20;

    if(argc > 0) x->width = atom_getint(argv);
    if(argc > 1) x->height = atom_getint(argv + 1);
    if(argc > 2) binbuf_add(x->options_binbuf, argc - 2, argv + 2);

// TODO
//    x->receive_name = tkwidgets_gen_callback_name(x->tcl_namespace);
    char* buf[MAXPDSTRING];
    snprintf(buf, MAXPDSTRING, "#%lx", x);
    x->receive_name = gensym(buf);
    pd_bind(&x->x_obj.ob_pd, x->receive_name);

    t_glist* glist = canvas_getcurrent();
    x->x_glist = glist;

    x->x_data_outlet = outlet_new(&x->x_obj, &s_float);
    x->x_status_outlet = outlet_new(&x->x_obj, &s_anything);

    /* send the instance ID without the "::" so we can build widget names */
    sys_vgui("::tkwidgets::entry::new %lx .x%lx\n", x, glist);

    return (x);
}

static void entry_free(t_entry *x)
{
    pd_unbind(&x->x_obj.ob_pd, x->receive_name);
}

void entry_setup(void)
{
    entry_class = class_new(gensym("entry"), 
                            (t_newmethod)entry_new, 
                            (t_method)entry_free, 
                            sizeof(t_entry), 0, A_GIMME,0);

/* widget behavior */
    entry_widgetbehavior.w_getrectfn  = entry_getrect;
    entry_widgetbehavior.w_displacefn = entry_displace;
    entry_widgetbehavior.w_selectfn   = entry_select;
    entry_widgetbehavior.w_activatefn = entry_activate;
    entry_widgetbehavior.w_deletefn   = entry_delete;
    entry_widgetbehavior.w_visfn      = entry_vis;
    entry_widgetbehavior.w_clickfn    = entry_click;
    class_setwidget(entry_class, &entry_widgetbehavior);
    class_setsavefn(entry_class, &entry_save);

/* callbacks */
    class_addmethod(entry_class, (t_method)entry_set_position,
                    gensym("set_position"), A_DEFFLOAT, A_DEFFLOAT, 0);
    class_addmethod(entry_class, (t_method)entry_resize_click_callback,
                    gensym("resize_click"), A_FLOAT, 0);
    class_addmethod(entry_class, (t_method)entry_resize_motion_callback,
                    gensym("resize_motion"), A_FLOAT, A_FLOAT, 0);

/* methods for messages in pd space */
    class_addmethod(entry_class, (t_method)entry_position,
                    gensym("position"), A_DEFFLOAT, A_DEFFLOAT, 0);
    class_addmethod(entry_class, (t_method)entry_size,
                    gensym("size"), A_DEFFLOAT, A_DEFFLOAT, 0);

    /* TODO should this use t_class->c_name? */
    sys_vgui("eval [read [open %s/entry.tcl]]\n",
             entry_class->c_externdir->s_name);
}
