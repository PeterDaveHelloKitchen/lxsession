/* 
    Copyright 2012 Julien Lavergne <gilir@ubuntu.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Posix;

namespace LDefaultApps
{

    public static int main(string[] args)
    {
        /* Init GTK */
        Gtk.init (ref args);

        /* Load the .ui file */
        var builder = new Builder ();

        try
        {
            // If the UI contains custom widgets, their types must've been instantiated once
            // Type type = typeof(Foo.BarEntry);
            // assert(type != 0);

            var builder_file_path = Path.build_filename("data","ui","lxsession-default-apps.ui");
            var builder_file = File.new_for_path(builder_file_path);

            if (builder_file.query_exists())
            {
                builder.add_from_file (builder_file_path);
            }
            else
            {
                /* TODO Make it smart with prefix */
                builder_file_path = Path.build_filename("usr","share","lxsession","ui","lxsession-default-apps.ui");
                builder.add_from_file (builder_file_path);
            }
        } 
        catch (GLib.Error e)
        {
            critical ("Could not load UI: %s\n", e.message);
            return 1;
        } 

        /* Log on .log file */
        string log_directory = Path.build_filename(Environment.get_user_cache_dir(), "lxsession-default-apps");
        var dir_log = File.new_for_path (log_directory);

        string log_path = Path.build_filename(log_directory, "run.log");

        message ("log directory: %s",log_directory);
        message ("log path: %s",log_path);

        if (!dir_log.query_exists ())
        {
            try
            {
                dir_log.make_directory_with_parents();
            }
            catch (GLib.Error e)
            {
                GLib.stderr.printf ("Could not write log: %s\n", e.message);
            }
        }

        int fint;
        fint = open (log_path, O_WRONLY | O_CREAT | O_TRUNC, 0600);
        dup2 (fint, STDOUT_FILENO);
        dup2 (fint, STDERR_FILENO);
        close(fint);

        /* Build the UI */
        builder.connect_signals (null);
        var window = builder.get_object ("main-win") as Window;
        window.destroy.connect (Gtk.main_quit);

        var dbus_backend = new DbusBackend();

        /* Panel init */
        var panel_command_combobox = new Gtk.ComboBox();
        var panel_command_entry = builder.get_object ("panel_command_entry") as Entry;
        string[] panel_commands = { "", "lxpanel"};
        string panel_command_default = dbus_backend.PanelCommandGet();
        panel_command_combobox = ui_combobox_init(  builder,
                                                    "panel_command_combobox",
                                                    panel_commands,
                                                    "panel_command_entry",
                                                    panel_command_default);


        var panel_session_combobox = new Gtk.ComboBox();
        var panel_session_entry = builder.get_object ("panel_session_entry") as Entry;
        string[] panel_sessions = { "", "Lubuntu", "LXDE"};
        string panel_session_default = dbus_backend.PanelSessionGet();
        panel_session_combobox = ui_combobox_init(  builder,
                                                    "panel_session_combobox",
                                                    panel_sessions,
                                                    "panel_session_entry",
                                                    panel_session_default);

        var panel_apply_button = builder.get_object("panel_apply") as Gtk.Button;
        panel_apply_button.clicked.connect (() => {
            message ("Click !");

            if (return_combobox_position(panel_command_combobox) == 99)
            {
                dbus_backend.PanelCommandSet(panel_command_entry.get_text());
            }
            else
            {
                dbus_backend.PanelCommandSet(return_combobox_text(panel_command_combobox));
            }


            if (return_combobox_position(panel_session_combobox) == 99)
            {
                dbus_backend.PanelSessionSet(panel_session_entry.get_text());
            }
            else
            {
                dbus_backend.PanelSessionSet(return_combobox_text(panel_session_combobox));
            }

        });


        var panel_reload_button = builder.get_object("panel_reload") as Gtk.Button;
        panel_reload_button.clicked.connect (() => {
            dbus_backend.PanelReload();
        });

        /* Show all */
        window.show_all ();

        /* Panel hide */
        if (return_combobox_position(panel_command_combobox) != 99)
        {
            panel_command_entry.hide_all();
        }

        if (return_combobox_position(panel_session_combobox) != 99)
        {
            panel_session_entry.hide_all();
        }

        /* start main loop */
        Gtk.main ();
        new MainLoop().run();


        return 0;
    }
}