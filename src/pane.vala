/* pane.vala
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
    [GtkTemplate (ui = "/fr/oupson/FooTerm/pane.ui")]
    public class Pane : Gtk.Box {
        [GtkChild]
        private unowned Adw.ViewStack footerm_pane_stack;

        [GtkChild]
        private unowned Footerm.NewPane new_pane;

        [GtkChild]
        private unowned Footerm.TerminalPane terminal_pane;

        construct {
            this.new_pane.on_server_selected.connect ((s) => {
                this.footerm_pane_stack.set_visible_child (this.terminal_pane);
                this.terminal_pane.connect (s);
            });
        }

        async void close () {
        }
    }
}
