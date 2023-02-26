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

namespace FooTerm {
    [GtkTemplate (ui = "/fr/oupson/FooTerm/terminalpane.ui")]
    public class TerminalPane : Gtk.Box {
        [GtkChild]
        private unowned Vte.Terminal terminal;

        private SSH2.Session<bool>? session;
        private SSH2.Channel? channel;
        private Socket socket;
        private int slave_pty;

        private FooTerm.Model.Server server;

        public TerminalPane(FooTerm.Model.Server server) {
            this.server = server;
            this.terminal.set_enable_sixel (true);
            this.connect_to_server();
            this.terminal.char_size_changed.connect(() => {
                int rows = 0;
                int columns = 0;
                this.terminal.get_pty().get_size(out rows, out columns);
                this.channel.request_pty_size(columns, rows);
            });
        }

        ~TerminalPane() {
            // TODO DESTRUCT
            // session.disconnect( "Normal Shutdown, Thank you for playing");
            // session = null;
            // Posix.close(sock);
            // stdout.printf("all done!\n");)
        }

        private void connect_to_server() throws GLib.IOError, GLib.Error {
	        this.socket = new Socket (SocketFamily.IPV4, SocketType.STREAM, SocketProtocol.TCP);
	        var addrs = new NetworkAddress(this.server.hostname, this.server.port);
	        socket.connect(addrs.enumerate().next(), null);

            var sock = socket.get_fd(); // TODO

            this.session = SSH2.Session.create<bool>();
            if (session.handshake(sock) != SSH2.Error.NONE) {
                stderr.printf("Failure establishing SSH session\n");
                return;
            }

            var fingerprint = session.get_host_key_hash(SSH2.HashType.SHA1);
            stdout.printf("Fingerprint: ");
            for(var i = 0; i < 20; i++) {
                stdout.printf("%02X ", fingerprint[i]);
            }
            stdout.printf("\n");

            if (session.auth_password(this.server.username, this.server.password) != SSH2.Error.NONE) {
                stdout.printf("\tAuthentication by password failed!\n");
                session.disconnect( "Normal Shutdown, Thank you for playing");
                session = null;
                Posix.close(sock);
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
                   session.disconnect( "Normal Shutdown, Thank you for playing");
                   session = null;
                   Posix.close(sock);
                }

                channel.set_env ("TERM", "xterm-256color");

                 if (channel.start_shell() != SSH2.Error.NONE) {
                   stderr.printf("Unable to request shell on allocated pty\n");
                   session.disconnect( "Normal Shutdown, Thank you for playing");
                   session = null;
                   Posix.close(sock);
                }

                var master_pty = Posix.posix_openpt(Posix.O_RDWR);
                if (master_pty == -1) {
                    throw GLib.IOError.from_errno (Posix.errno);
                }

                var settings = Posix.termios();
                Posix.cfmakeraw (ref settings);

                if (Posix.tcsetattr (master_pty, Posix.TCSANOW, settings)  == -1) {
                    throw GLib.IOError.from_errno (Posix.errno);
                }

                if (Posix.grantpt(master_pty) == -1) {
                    throw GLib.IOError.from_errno (Posix.errno);
                }

                if (Posix.unlockpt(master_pty) == -1) {
                    throw GLib.IOError.from_errno (Posix.errno);
                }

                var pts_name = Posix.ptsname(master_pty);
                if (pts_name == null) {
                    throw GLib.IOError.from_errno (Posix.errno);
                }

                this.slave_pty = Posix.open(pts_name, Posix.O_RDWR);
                if (this.slave_pty < 0) {
                    throw GLib.IOError.from_errno (Posix.errno);
                }

                var vte_pty = new Vte.Pty.foreign_sync(master_pty, null);
                this.terminal.set_pty(vte_pty);

                session.blocking = false;

                var sock_channel = new GLib.IOChannel.unix_new(sock);
                sock_channel.set_encoding (null);
                sock_channel.set_buffered (false);
                sock_channel.set_close_on_unref (false);

                var slave_channel = new GLib.IOChannel.unix_new(slave_pty);
                slave_channel.set_encoding (null);
                slave_channel.set_buffered (false);

                sock_channel.add_watch (GLib.IOCondition.IN, this.on_ssh_event);
                slave_channel.add_watch (GLib.IOCondition.IN, this.on_slave_event);
            }
        }

        private bool on_ssh_event(GLib.IOChannel source, GLib.IOCondition condition) {
            if (condition == IOCondition.HUP) {
                print ("The connection has been broken.\n");
                return false;
            }

            try {
                var buffer = new uint8[1024];
                var size = this.channel.read(buffer);
                debug("Got %zu from ssh", size);

                if (Posix.write(this.slave_pty, buffer, size) < 0) {
                    throw GLib.IOError.from_errno(Posix.errno);
                }

                return true;
            } catch(Error e) {
                GLib.warning("Failed to read from ssh : %s", e.message);
                return false;
            }
        }

        private bool on_slave_event(GLib.IOChannel source, GLib.IOCondition condition) {
            if (condition == IOCondition.HUP) {
                print ("The connection has been broken.\n");
                return false;
            }

            try {
                var buffer = new char[1024];
                size_t size = 0;
                source.read_chars(buffer, out size);

                var res = this.channel.write ((uint8[])buffer[0:size]);
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
