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
        private unowned Vte.Terminal terminal;

        public Window (Gtk.Application app) {
            Object (application: app);
        }

        construct {
            this.terminal.set_enable_sixel (true);
            this.terminal.spawn_async (Vte.PtyFlags.NO_CTTY, null, {"flatpak-spawn", "--host", "bash"}, null, 0, null, -1, null, this.on_spawn_finished);
        }


        private void on_spawn_finished (Vte.Terminal t, Pid _pid, GLib.Error? error) {
            if (error != null) {
                warning ("%s", error.message);
            }
        }
    }
}
