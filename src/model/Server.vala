/* Server.vala
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

namespace Footerm.Model {
    public class Server {
        public int? id;
        public string name;
        public string hostname;
        public ushort port;
        public string username;

        public Server(int? id, string name, string hostname, ushort port, string username) {
            this.id = id;
            this.name = name;
            this.hostname = hostname;
            this.port = port;
            this.username = username;
        }
    }
}
