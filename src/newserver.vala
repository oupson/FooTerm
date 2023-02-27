/* newserver.vala
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
    [GtkTemplate(ui = "/fr/oupson/FooTerm/newserver.ui")]
    public class NewServer : Gtk.Box {
        public signal void on_new_server(Footerm.Model.Server server);

        [GtkChild]
        private unowned Adw.EntryRow hostname_entry;

        [GtkChild]
        private unowned Adw.EntryRow port_entry;

        [GtkChild]
        private unowned Adw.EntryRow username_entry;

        [GtkChild]
        private unowned Adw.PasswordEntryRow password_entry;

        [GtkChild]
        private unowned Gtk.Button add_server_button;

        construct {
            add_server_button.clicked.connect(this.on_add_button_clicked);
        }

        private void on_add_button_clicked() {
            var hostname = this.hostname_entry.get_text();
            var port = int.parse(this.port_entry.get_text());
            var username = this.username_entry.get_text();
            var password = this.password_entry.get_text();

            if (port > 65545 || port < 0) {
                // Port is invalid
            }

            // this.on_new_server(new Footerm.Model.Server(hostname, (ushort)port, username, password));
        }
    }
}
