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

namespace Footerm {
    [GtkTemplate(ui = "/fr/oupson/FooTerm/newpane.ui")]
    public class NewPane : Gtk.Box {
        [GtkChild]
        private unowned Adw.PreferencesGroup server_list;

        [GtkChild]
        private unowned Footerm.NewServer new_server;

        [GtkChild]
        private unowned Gtk.Stack newpane_stack;

        [GtkChild]
        private unowned Gtk.Button newpane_add_button;

        public signal void on_server_selected(Footerm.Model.Server server);

        public signal void title_changed(string new_title);

        private Footerm.Services.Config config;

        construct {
            this.new_server.on_new_server.connect((server) => {
                this.newpane_stack.set_visible_child(server_list.get_parent());
                server_list.add(this.build_action_row(server));
                this.title_changed("New Pane");
            });

            this.newpane_add_button.clicked.connect(() => {
                this.newpane_stack.set_visible_child(new_server.get_parent());
                this.title_changed("Create a new server");
            });

            try {
                this.config = Footerm.Services.Config.get_instance();

                var stored_server_list = this.config.get_server_list();
                foreach (var server in stored_server_list) {
                    this.server_list.add(this.build_action_row(server));
                }
            } catch (Error e) {
                GLib.warning("Failed to read server list : %s", e.message);
            }
        }

        private Adw.ActionRow build_action_row(Footerm.Model.Server server) {
            var action_row = new Adw.ActionRow();
            action_row.set_title(server.name);
            action_row.set_activatable(true);
            action_row.activated.connect(() => {
                this.on_server_selected(server);
            });
            var delete_button = new Gtk.Button();
            delete_button.set_icon_name("edit-delete-symbolic");
            delete_button.set_valign(Gtk.Align.CENTER);
            delete_button.add_css_class("edit-icon");
            delete_button.add_css_class("flat");
            delete_button.clicked.connect(() => {
                this.config.delete_server.begin(server, (obj, res) => {
                    try {
                        this.config.delete_server.end(res);
                        this.server_list.remove(action_row);
                    } catch (Error e) {
                        // TODO WARN USER
                        warning("Failed to delete : %s", e.message);
                    }
                });
            });
            action_row.add_suffix(delete_button);
            return action_row;
        }
    }
}
