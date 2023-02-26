/* newpane.vala
 *
 * Copyright 2023 oupson
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

namespace FooTerm {
    [GtkTemplate (ui = "/fr/oupson/FooTerm/newpane.ui")]
    public class NewPane : Gtk.Box {
        [GtkChild]
        private unowned Adw.PreferencesGroup server_list;

        [GtkChild]
        private unowned FooTerm.NewServer new_server;

        [GtkChild]
        private unowned Gtk.Stack newpane_stack;

        [GtkChild]
        private unowned Gtk.Button newpane_add_button;

        public signal void on_server_selected(FooTerm.Model.Server server);

        construct {
            this.new_server.on_new_server.connect((s) => {
                this.newpane_stack.set_visible_child(server_list.get_parent());
                var action_row = new Adw.ActionRow();
                action_row.set_title(s.hostname);
                action_row.set_activatable(true);
                action_row.activated.connect(() => {
                    this.on_server_selected(s);
                });
                server_list.add(action_row);
            });
            this.newpane_add_button.clicked.connect (() => {
                this.newpane_stack.set_visible_child(new_server.get_parent());
            });

            try {
                var config_dir = GLib.File.new_for_path(GLib.Environment.get_user_config_dir());
                var server_files = config_dir.get_child("servers.json");

                if (server_files.query_exists()) {
                    var parser = new Json.Parser();

                    parser.load_from_file(server_files.get_path());

                    // TODO
                } else {
                    GLib.debug("Server file does not exist");
                }
            } catch (Error e) {
                GLib.warning("Failed to read server list : %s", e.message);
            }
        }
    }
}