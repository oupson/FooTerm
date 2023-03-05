/* Config.vala
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
    public errordomain ConfigError {
        DATABASE
    }

    public class Config {
        private static Config instance = null;

        public static Config get_instance() throws Footerm.Services.ConfigError {
            if (Config.instance == null) {
                Config.instance = new Config();
            }
            return Config.instance;
        }

        private const int DATABASE_VERSION = 1;

        private Sqlite.Database db;

        private Sqlite.Statement user_version_stm;

        public Config() throws Footerm.Services.ConfigError {
            var config_dir = GLib.File.new_for_path(GLib.Environment.get_user_config_dir());
            var config_db_file = config_dir.get_child("config.db");

            debug("Database path is %s", config_db_file.get_path());
            int ec = Sqlite.Database.open(config_db_file.get_path(), out this.db);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't open database: $(db.errcode ()): $(db.errmsg ())");
            }

            debug("Opened database");
            var stm = "PRAGMA user_version;";
            ec = this.db.prepare_v2(stm, stm.length, out this.user_version_stm);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Failed to prepare user_version statement: $(db.errcode ()): $(db.errmsg ())");
            }

            while (this.upgrade_database()) {
            }
        }

        private bool upgrade_database() throws ConfigError {
            string errmsg;
            var ec = this.user_version_stm.reset();
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Failed to reset user_version statement: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = this.user_version_stm.step();
            if (ec != Sqlite.ROW) {
                throw new ConfigError.DATABASE(@"Failed to execute user_version statement: $(db.errcode ()): $(db.errmsg ())");
            }

            var version = this.user_version_stm.column_int(0);

            if (version == DATABASE_VERSION) {
                return false;
            }

            string query;
            switch (version) {
            case 0:
                debug("Upgrading from 0 to 1");
                query = """
                CREATE TABLE SERVER(
                    serverId INTEGER NOT NULL PRIMARY KEY,
                    serverName TEXT NOT NULL,
                    serverHostName TEXT NOT NULL,
                    serverPort INTEGER NOT NULL,
                    serverUsername TEXT NOT NULL,
                    serverAuthentificationType TEXT NOT NULL
                );

                PRAGMA user_version = 1;
                """;
                break;
            default:
                error("Unknown database version %d", version);
            }


            ec = this.db.exec(query, null, null);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't exec migration: $(db.errcode ()): $(db.errmsg ())");
            }

            return true;
        }

        public List<Footerm.Model.Server> get_server_list() throws ConfigError {
            List<Footerm.Model.Server> list = new List<Footerm.Model.Server> ();

            var stm_str = "SELECT serverId, serverName, serverHostName, serverPort, serverUsername FROM SERVER;";
            Sqlite.Statement stm;
            var ec = this.db.prepare_v2(stm_str, stm_str.length, out stm);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't fetch server list: $(db.errcode ()): $(db.errmsg ())");
            }

            while (stm.step() == Sqlite.ROW) {
                list.append(new Footerm.Model.Server(stm.column_int(0), stm.column_text(1), stm.column_text(2), (ushort) stm.column_int(3), stm.column_text(4)));
            }

            return list;
        }

        public async void save_server(Footerm.Model.Server server, string password) throws ConfigError, SecretError, Error {
            var secrets = Secrets.get_instance();
            yield secrets.store_password(server, password);

            var stm_str = "INSERT INTO SERVER (serverName, serverHostName, serverPort, serverUsername, serverAuthentificationType) VALUES(?, ?, ?, ?, 'password')";
            Sqlite.Statement stm;
            var ec = this.db.prepare_v2(stm_str, stm_str.length, out stm);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't insert server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.bind_text(1, server.name);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't insert server: $(db.errcode ()): $(db.errmsg ())");
            }
            ec = stm.bind_text(2, server.hostname);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't insert server: $(db.errcode ()): $(db.errmsg ())");
            }
            ec = stm.bind_int(3, server.port);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't insert server: $(db.errcode ()): $(db.errmsg ())");
            }
            ec = stm.bind_text(4, server.username);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't insert server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.step();
            stm.reset();

            if (ec != Sqlite.DONE) {
                throw new ConfigError.DATABASE(@"Can't insert server: $(db.errcode ()): $(db.errmsg ())");
            }

            server.id = (int) this.db.last_insert_rowid();
        }

        public async void delete_server(Footerm.Model.Server server) throws ConfigError, SecretError, Error {
            var stm_str = "SELECT COUNT(serverId) FROM SERVER WHERE serverHostName = ? AND serverPort = ? AND serverUsername = ? AND serverAuthentificationType = 'password'";
            Sqlite.Statement stm;

            var ec = this.db.prepare_v2(stm_str, stm_str.length, out stm);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.bind_text(1, server.hostname);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.bind_int(2, server.port);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.bind_text(3, server.username);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.step();
            if (ec != Sqlite.ROW) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }

            var delete_from_secret = stm.column_int(0) == 1;
            stm.reset();

            stm_str = "DELETE FROM SERVER WHERE serverId = ?";

            ec = this.db.prepare_v2(stm_str, stm_str.length, out stm);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.bind_int(1, server.id);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }

            ec = stm.step();
            if (ec != Sqlite.DONE) {
                throw new ConfigError.DATABASE(@"Can't delete server: $(db.errcode ()): $(db.errmsg ())");
            }
            stm.reset();

            if (delete_from_secret) {
                var secrets = Secrets.get_instance();
                yield secrets.delete_password(server);
            }
        }
    }
}
