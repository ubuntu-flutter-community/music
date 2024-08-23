#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <handy.h>

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);

  GList* windows = gtk_application_get_windows(GTK_APPLICATION(application));
  if (windows) {
    gtk_window_present(GTK_WINDOW(windows->data));
    return;
  }
  GtkWindow* window = GTK_WINDOW(hdy_application_window_new());
  gtk_window_set_application(window, GTK_APPLICATION(application));

  GtkBox* box = GTK_BOX(gtk_box_new(GTK_ORIENTATION_VERTICAL, 0));
  gtk_widget_show(GTK_WIDGET(box));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(box));

  GdkGeometry geometry_min;
  geometry_min.min_width = 500;
  geometry_min.min_height = 700;
  gtk_window_set_geometry_hints(window, nullptr, &geometry_min, GDK_HINT_MIN_SIZE);
  gtk_window_set_default_size(window, 950, 820);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_box_pack_end(GTK_BOX(box), GTK_WIDGET(view), true, true, 0);

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_show(GTK_WIDGET(window));
  gtk_widget_show(GTK_WIDGET(view));
  gtk_widget_grab_focus(GTK_WIDGET(view));
}

static gint my_application_command_line(GApplication *application, GApplicationCommandLine *command_line) {
  MyApplication *self = MY_APPLICATION(application);
  gchar **arguments = g_application_command_line_get_arguments(command_line, nullptr);
  self->dart_entrypoint_arguments = g_strdupv(arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    return 1;
  }
  g_application_activate(application);
  return 0;
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->command_line = my_application_command_line;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  return MY_APPLICATION(g_object_new(
      my_application_get_type(), "application-id", APPLICATION_ID, "flags",
      G_APPLICATION_HANDLES_COMMAND_LINE | G_APPLICATION_HANDLES_OPEN,
      nullptr));
}