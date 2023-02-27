/* window.vala
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
    [GtkTemplate (ui = "/fr/oupson/FooTerm/window.ui")]
    public class Window : Adw.ApplicationWindow {
        [GtkChild]
        private unowned Adw.TabView view;

        public Window (Gtk.Application app) {
            Object (application: app);
        }

        construct {
            var action = new SimpleAction("new_tab", null);
            action.activate.connect (() => {
                var a = view.append (new Footerm.Pane());
                a.set_title ("New Pane");
                view.set_selected_page (a);
            });
            this.add_action (action);
            var a = view.append (new Footerm.Pane());
            a.set_title ("New Pane");
        }
    }
}
