/* terminalpane.vala
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
    [GtkTemplate(ui = "/fr/oupson/FooTerm/terminalpane.ui")]
    public class TerminalPane : Gtk.Box {
        [GtkChild]
        private unowned Vte.Terminal terminal;

        private SSH2.Session<bool>? session;
        private SSH2.Channel? channel;
        private SocketConnection socket;
        private IOChannel slave_channel;

        private Footerm.Model.Server? server;

        construct {
            this.configure_terminal();
        }

        public void connect_to_server_async(Footerm.Model.Server server) {
            this.server = server;

            this.connect_to_server.begin((obj, res) => {
                try {
                    this.connect_to_server.end(res);
                } catch (Error e) {
                    warning("Failed to connect to the server : %s", e.message);
                }
            });
        }

        private void configure_terminal() {
            this.terminal.set_enable_sixel(true);
            this.terminal.char_size_changed.connect(() => {
                var pty = this.terminal.get_pty();
                if (pty != null && this.channel != null) {
                    int rows = 0;
                    int columns = 0;
                    pty.get_size(out rows, out columns);
                    this.channel.request_pty_size(columns, rows);
                }
            });
        }

        private void create_pty() throws GLib.IOError {
            var master_pty = Posix.posix_openpt(Posix.O_RDWR);
            if (master_pty == -1) {
                throw GLib.IOError.from_errno(Posix.errno);
            }

            var settings = Posix.termios();
            Posix.cfmakeraw(ref settings);

            if (Posix.tcsetattr(master_pty, Posix.TCSANOW, settings) == -1) {
                throw GLib.IOError.from_errno(Posix.errno);
            }

            if (Posix.grantpt(master_pty) == -1) {
                throw GLib.IOError.from_errno(Posix.errno);
            }

            if (Posix.unlockpt(master_pty) == -1) {
                throw GLib.IOError.from_errno(Posix.errno);
            }

            var pts_name = Posix.ptsname(master_pty);
            if (pts_name == null) {
                throw GLib.IOError.from_errno(Posix.errno);
            }

            var slave_pty = Posix.open(pts_name, Posix.O_RDWR);
            if (slave_pty < 0) {
                throw GLib.IOError.from_errno(Posix.errno);
            }


            var vte_pty = new Vte.Pty.foreign_sync(master_pty, null);
            this.terminal.set_pty(vte_pty);

            this.slave_channel = new GLib.IOChannel.unix_new(slave_pty);
            slave_channel.set_encoding(null);
            slave_channel.set_buffered(false);
        }

        private async void connect_to_server() throws GLib.IOError, GLib.Error {
            var addrs = new NetworkAddress(this.server.hostname, this.server.port);
            var addr = addrs.enumerate().next();
            var client = new SocketClient();
            this.socket = client.connect(addr);

            this.session = SSH2.Session.create<bool> ();
            if (session.handshake(this.socket.get_socket().get_fd()) != SSH2.Error.NONE) {
                stderr.printf("Failure establishing SSH session\n");
                return;
            }

            var fingerprint = session.get_host_key_hash(SSH2.HashType.SHA1);
            stdout.printf("Fingerprint: ");
            for (var i = 0; i < 20; i++) {
                stdout.printf("%02X ", fingerprint[i]);
            }
            stdout.printf("\n");

            var secrets = Footerm.Services.Secrets.get_instance();
            var password = yield secrets.get_password(this.server);

            if (session.auth_password(this.server.username, password) != SSH2.Error.NONE) {
                stdout.printf("\tAuthentication by password failed!\n");
                session.disconnect("Normal Shutdown, Thank you for playing");
                session = null;
                this.socket.close();
                return;
            } else {
                stdout.printf("\tAuthentication by password succeeded.\n");
            }

            this.channel = null;
            if (session.authenticated && (channel = session.open_channel()) == null) {
                stderr.printf("Unable to open a session\n");
            } else {
                if (channel.request_pty("xterm-256color".data) != SSH2.Error.NONE) {
                    stderr.printf("Failed requesting pty\n");
                    session.disconnect("Normal Shutdown, Thank you for playing");
                    session = null;
                    this.socket.close();
                }

                channel.set_env("TERM", "xterm-256color");

                if (channel.start_shell() != SSH2.Error.NONE) {
                    stderr.printf("Unable to request shell on allocated pty\n");
                    session.disconnect("Normal Shutdown, Thank you for playing");
                    session = null;
                    this.socket.close();
                }

                session.blocking = false;

                this.create_pty();

                var inner_socket = socket.get_socket();
                var source = inner_socket.create_source(GLib.IOCondition.IN, null);
                source.set_callback(this.on_ssh_event);
                source.attach(null);

                slave_channel.add_watch(GLib.IOCondition.IN, this.on_slave_event);
            }
        }

        private bool on_ssh_event(Socket source, GLib.IOCondition condition) {
            if (condition == IOCondition.HUP) {
                print("The connection has been broken.\n");
                return false;
            }

            try {
                ssize_t size = 0;
                var buffer = new uint8[1024];
                do {
                    size = this.channel.read(buffer);
                    if (size > 0) {
                        debug("Got %zd bytes from ssh", size);
                        size_t written_size = 0;
                        this.slave_channel.write_chars((char[]) (buffer[0 : size]), out written_size);
                    } else if ((size == 0 && channel.eof() != 0) || (size < 0 && size != SSH2.Error.AGAIN)) {
                        warning("Channel is closed");
                        return false;
                    }
                } while (size != SSH2.Error.AGAIN);

                return true;
            } catch (Error e) {
                GLib.warning("Failed to read from ssh : %s", e.message);
                return false;
            }
        }

        private bool on_slave_event(GLib.IOChannel source, GLib.IOCondition condition) {
            if (condition == IOCondition.HUP) {
                print("The connection has been broken.\n");
                return false;
            }

            try {
                var buffer = new char[1024];
                size_t size = 0;
                source.read_chars(buffer, out size);

                var res = this.channel.write((uint8[]) buffer[0 : size]);
                if (res < 0) {
                    warning("Channel write failed with %zu", res);
                }
                return true;
            } catch (Error e) {
                GLib.warning("Failed to read from terminal : %s", e.message);
                return false;
            }
        }
    }
}
