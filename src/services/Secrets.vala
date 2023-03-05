/* Secrets.vala
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

namespace Footerm.Services {
    public errordomain SecretError {
        FAILED_TO_STORE
    }

    public class Secrets {
        private static Secrets instance = null;

        public static Secrets get_instance() {
            if (Secrets.instance == null) {
                Secrets.instance = new Secrets();
            }
            return Secrets.instance;
        }

        private Secret.Schema password_schema;

        private Secrets() {
            this.password_schema = new Secret.Schema("fr.oupson.FooTerm.Password", Secret.SchemaFlags.NONE,
                                                     "hostname", Secret.SchemaAttributeType.STRING,
                                                     "port", Secret.SchemaAttributeType.INTEGER,
                                                     "username", Secret.SchemaAttributeType.STRING);
        }

        public async void store_password(Footerm.Model.Server server, string password) throws SecretError, Error {
            var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
            attributes["hostname"] = server.hostname;
            attributes["port"] = server.port.to_string();
            attributes["username"] = server.username;

            var res = yield Secret.password_storev(this.password_schema, attributes, Secret.COLLECTION_DEFAULT, @"$(server.username)@$(server.hostname):$(server.port)", password, null);

            if (!res) {
                throw new SecretError.FAILED_TO_STORE("Failed to store the password");
            }
            debug("Password is stored");
        }

        public async string get_password(Footerm.Model.Server server) throws Error {
            var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
            attributes["hostname"] = server.hostname;
            attributes["port"] = server.port.to_string();
            attributes["username"] = server.username;

            return yield Secret.password_lookupv(this.password_schema, attributes, null);
        }

        public async void delete_password(Footerm.Model.Server server) throws Error {
            var attributes = new GLib.HashTable<string, string> (str_hash, str_equal);
            attributes["hostname"] = server.hostname;
            attributes["port"] = server.port.to_string();
            attributes["username"] = server.username;
            yield Secret.password_clearv(this.password_schema, attributes, null);
        }
    }
}
