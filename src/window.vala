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
            this.view.close_page.connect (this.close_page);
            var action = new SimpleAction ("new_tab", null);
            action.activate.connect (() => {
                this.create_new_pane ();
            });
            this.add_action (action);
            this.create_new_pane ();
        }

        private void create_new_pane () {
            var pane = new Footerm.Pane ();
            var tab_page = this.view.append (pane);
            tab_page.set_title ("New Pane");
            pane.title_changed.connect (on_page_title_changed);
        }

        private void on_page_title_changed (Footerm.Pane pane, string title) {
            var tab_page = this.view.get_page (pane);
            tab_page.set_title (title);
        }

        private bool close_page (Adw.TabView tab_view, Adw.TabPage page) {
            if (!page.get_pinned ()) {
                var child = (Footerm.Pane) page.get_child ();
                child.close.begin ((obj, res) => {
                    child.close.end (res);
                    tab_view.close_page_finish (page, true);
                });
            } else {
                tab_view.close_page_finish (page, false);
            }

            return Gdk.EVENT_STOP;
        }
    }
}
