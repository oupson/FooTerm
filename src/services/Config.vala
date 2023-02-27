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

        private Sqlite.Database db;

        public Config() throws Footerm.Services.ConfigError {
            var config_dir = GLib.File.new_for_path(GLib.Environment.get_user_config_dir());
            var config_db_file = config_dir.get_child("config.db");

            debug("Database path is %s", config_db_file.get_path());
            int ec = Sqlite.Database.open (config_db_file.get_path(), out this.db);
            if (ec != Sqlite.OK) {
                throw new ConfigError.DATABASE(@"Can't open database: $(db.errcode ()): $(db.errmsg ())");
            }

            debug("Opened database");
        }
    }
}
