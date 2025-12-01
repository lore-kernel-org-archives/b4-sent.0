From: Ye He <ye.he@amlogic.com>
Date: Mon, 01 Dec 2025 16:28:49 +0800
Subject: [PATCH bluez v8 3/3] client: Add shell cmd for bearer
 connect/disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251201-bearer-impl-v8-3-f944b6f9f201@amlogic.com>
References: <20251201-bearer-impl-v8-0-f944b6f9f201@amlogic.com>
In-Reply-To: <20251201-bearer-impl-v8-0-f944b6f9f201@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764577755; l=13978;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=ElnmBmM/d+yq+MpQNoG5UWBo4+Rutw95XfhnO7MS+pQ=;
 b=2594WoOdsVbCHBs34F/xrer74/+MN0X+wxbPi9zK0ulT8QvZR+ymwbTOsChXTShB1y7lQZTZj
 MzC52yhEJ1NADmjIU2YHCziqK9oOrEtvZQegdhWcttq6oql4qxnMekv
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds shell command for bearer connect/disconnect.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 client/bluetoothctl-bredr.rst |  70 +++++++++
 client/bluetoothctl-le.rst    |  71 +++++++++
 client/bluetoothctl.rst       |  10 ++
 client/main.c                 | 324 ++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 475 insertions(+)

diff --git a/client/bluetoothctl-bredr.rst b/client/bluetoothctl-bredr.rst
new file mode 100644
index 0000000000000000000000000000000000000000..3ec702a59ff35261f6eb71cf77b3267229bbad8b
--- /dev/null
+++ b/client/bluetoothctl-bredr.rst
@@ -0,0 +1,70 @@
+==================
+bluetoothctl-bredr
+==================
+
+-------------
+BREDR Submenu
+-------------
+
+:Version: BlueZ
+:Copyright: Free use of this software is granted under the terms of the GNU
+            Lesser General Public Licenses (LGPL).
+:Date: December 2025
+:Manual section: 1
+:Manual group: Linux System Administration
+
+SYNOPSIS
+========
+
+**bluetoothctl** [--options] [bredr.commands]
+
+BREDR Commands
+==============
+
+list
+----
+
+List available bredr devices.
+
+:Usage: **> list**
+
+show
+----
+
+Show bredr bearer information on a device.
+
+:Usage: **> show [dev]**
+
+connect
+-------
+
+Connect device over bredr.
+
+This command initiates a bredr connection to a remote device.
+
+By default, it establishes the bredr connection and then connects all profiles
+that marked as auto-connectable.
+
+:Usage: > connect <dev>
+:Example: > connect 1C:48:F9:9D:81:5C
+
+disconnect
+----------
+
+Disconnect device over bredr.
+
+By default this command disconnects all profiles associated with the bredr
+connection, and then terminates the bredr link.
+
+:Usage: > disconnect <dev>
+:Example: > disconnect 1C:48:F9:9D:81:5C
+
+RESOURCES
+=========
+
+http://www.bluez.org
+
+REPORTING BUGS
+==============
+
+linux-bluetooth@vger.kernel.org
diff --git a/client/bluetoothctl-le.rst b/client/bluetoothctl-le.rst
new file mode 100644
index 0000000000000000000000000000000000000000..808d5786ee805a61228a5195cc731a5f46de9201
--- /dev/null
+++ b/client/bluetoothctl-le.rst
@@ -0,0 +1,71 @@
+===============
+bluetoothctl-le
+===============
+
+----------
+LE Submenu
+----------
+
+:Version: BlueZ
+:Copyright: Free use of this software is granted under the terms of the GNU
+            Lesser General Public Licenses (LGPL).
+:Date: December 2025
+:Manual section: 1
+:Manual group: Linux System Administration
+
+SYNOPSIS
+========
+
+**bluetoothctl** [--options] [le.commands]
+
+LE Commands
+===========
+
+list
+----
+
+List available le devices.
+
+:Usage: **> list**
+
+show
+----
+
+Show le bearer information on a device.
+
+:Usage: **> show [dev]**
+
+connect
+-------
+
+Connect device over le.
+
+This command initiates a le connection to a remote device.
+
+An active scan report is required before the connection can be
+established. If no advertising report is received before the timeout,
+a le-connection-abort-by-local error will be issued.
+
+:Usage: > connect <dev>
+:Example: > connect 1C:48:F9:9D:81:5C
+
+disconnect
+----------
+
+Disconnect device over le.
+
+By default this command disconnects all profiles/services associated with the le
+connection, and then terminates the le link.
+
+:Usage: > disconnect <dev>
+:Example: > disconnect 1C:48:F9:9D:81:5C
+
+RESOURCES
+=========
+
+http://www.bluez.org
+
+REPORTING BUGS
+==============
+
+linux-bluetooth@vger.kernel.org
diff --git a/client/bluetoothctl.rst b/client/bluetoothctl.rst
index 0187e877d60b28eb1e735181b3203e60da821e6f..f8d6c345797722aeb1550d903a268c7d756545f9 100644
--- a/client/bluetoothctl.rst
+++ b/client/bluetoothctl.rst
@@ -371,6 +371,16 @@ Assistant Submenu
 
 See **bluetoothctl-assistant(1)**
 
+LE Submenu
+==================
+
+See **bluetoothctl-le(1)**
+
+BREDR Submenu
+==================
+
+See **bluetoothctl-bredr(1)**
+
 AUTOMATION
 ==========
 Two common ways to automate the tool are to use Here Docs or the program expect.
diff --git a/client/main.c b/client/main.c
index 0a928efaa9bb0d2a806895ff8f8c0c7c0d2493bd..464243ea3b7247f4ae2be479643c44380af82917 100644
--- a/client/main.c
+++ b/client/main.c
@@ -2789,6 +2789,47 @@ static char *dev_set_generator(const char *text, int state)
 	return set_generator(text, state);
 }
 
+static char *bearer_dev_generator(const char *text, int state,
+					const char *iface)
+{
+	char *addr;
+	GDBusProxy *device;
+	GDBusProxy *bearer;
+
+	if (!iface)
+		return NULL;
+
+	addr = dev_generator(text, state);
+	if (!addr)
+		return NULL;
+
+	device = find_proxy_by_address(default_ctrl->devices, addr);
+	if (!device)
+		goto failed;
+
+	bearer = find_proxies_by_iface(default_ctrl->bearers,
+					g_dbus_proxy_get_path(device),
+					iface);
+	if (!bearer)
+		goto failed;
+
+	return addr;
+
+failed:
+	g_free(addr);
+	return NULL;
+}
+
+static char *le_dev_generator(const char *text, int state)
+{
+	return bearer_dev_generator(text, state, "org.bluez.Bearer.LE1");
+}
+
+static char *bredr_dev_generator(const char *text, int state)
+{
+	return bearer_dev_generator(text, state, "org.bluez.Bearer.BREDR1");
+}
+
 static char *attribute_generator(const char *text, int state)
 {
 	return gatt_attribute_generator(text, state);
@@ -3296,6 +3337,253 @@ static void cmd_adv_monitor_get_supported_info(int argc, char *argv[])
 	adv_monitor_get_supported_info();
 }
 
+static void print_le_properties(GDBusProxy *proxy)
+{
+	GDBusProxy *device;
+
+	device = find_proxies_by_path(default_ctrl->devices,
+					g_dbus_proxy_get_path(proxy));
+
+	if (!device)
+		return;
+
+	bt_shell_printf("Device %s\n", proxy_address(device));
+
+	/* New properties may add to org.bluez.Bearer.LE1. */
+	print_property(proxy, "Paired");
+	print_property(proxy, "Bonded");
+	print_property(proxy, "Connected");
+}
+
+static void print_le_bearers(void *data, void *user_data)
+{
+	GDBusProxy *proxy = data;
+
+	if (!strcmp(g_dbus_proxy_get_interface(proxy),
+				      "org.bluez.Bearer.LE1"))
+		print_le_properties(data);
+}
+
+static void print_bredr_properties(GDBusProxy *proxy)
+{
+	GDBusProxy *device;
+
+	device = find_proxies_by_path(default_ctrl->devices,
+					g_dbus_proxy_get_path(proxy));
+
+	if (!device)
+		return;
+
+	bt_shell_printf("Device %s\n", proxy_address(device));
+
+	/* New properties may add to org.bluez.Bearer.BREDR1. */
+	print_property(proxy, "Paired");
+	print_property(proxy, "Bonded");
+	print_property(proxy, "Connected");
+}
+
+static void print_bredr_bearers(void *data, void *user_data)
+{
+	GDBusProxy *proxy = data;
+
+	if (!strcmp(g_dbus_proxy_get_interface(proxy),
+				      "org.bluez.Bearer.BREDR1"))
+		print_bredr_properties(data);
+}
+
+static void cmd_list_le(int argc, char *argv[])
+{
+	GList *l;
+	GDBusProxy *device;
+
+	for (l = default_ctrl->devices; l; l = g_list_next(l)) {
+		device = l->data;
+		if (find_proxies_by_iface(default_ctrl->bearers,
+				      g_dbus_proxy_get_path(device),
+				      "org.bluez.Bearer.LE1"))
+			print_device(device, NULL);
+	}
+
+	return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+}
+
+static void cmd_list_bredr(int argc, char *argv[])
+{
+	GList *l;
+	GDBusProxy *device;
+
+	for (l = default_ctrl->devices; l; l = g_list_next(l)) {
+		device = l->data;
+		if (find_proxies_by_iface(default_ctrl->bearers,
+				      g_dbus_proxy_get_path(device),
+				      "org.bluez.Bearer.BREDR1"))
+			print_device(device, NULL);
+	}
+
+	return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+}
+
+static void cmd_show_le(int argc, char *argv[])
+{
+	GDBusProxy *device;
+	GDBusProxy *bearer;
+
+	/* Show all le bearers if no argument is given */
+	if (argc != 2) {
+		g_list_foreach(default_ctrl->bearers, print_le_bearers, NULL);
+		return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+	}
+
+	device = find_proxy_by_address(default_ctrl->devices, argv[1]);
+	if (!device) {
+		bt_shell_printf("Device %s not found\n", argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bearer = find_proxies_by_iface(default_ctrl->bearers,
+				      g_dbus_proxy_get_path(device),
+				      "org.bluez.Bearer.LE1");
+	if (!bearer) {
+		bt_shell_printf("LE bearer not found on %s\n", argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	print_le_properties(bearer);
+
+	return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+}
+
+static void cmd_show_bredr(int argc, char *argv[])
+{
+	GDBusProxy *device;
+	GDBusProxy *bearer;
+
+	/* Show all bredr bearers if no argument is given */
+	if (argc != 2) {
+		g_list_foreach(default_ctrl->bearers, print_bredr_bearers,
+									NULL);
+		return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+	}
+
+	device = find_proxy_by_address(default_ctrl->devices, argv[1]);
+	if (!device) {
+		bt_shell_printf("Device %s not found\n", argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bearer = find_proxies_by_iface(default_ctrl->bearers,
+				      g_dbus_proxy_get_path(device),
+				      "org.bluez.Bearer.BREDR1");
+	if (!bearer) {
+		bt_shell_printf("BREDR bearer not found on %s\n", argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	print_bredr_properties(bearer);
+
+	return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+}
+
+static void bearer_connect_reply(DBusMessage *message, void *user_data)
+{
+	DBusError error;
+
+	dbus_error_init(&error);
+
+	if (dbus_set_error_from_message(&error, message) == TRUE) {
+		bt_shell_printf("Failed to connect: %s %s\n", error.name,
+				error.message);
+		dbus_error_free(&error);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bt_shell_printf("Connection successful\n");
+
+	return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+}
+
+static void bearer_disconn_reply(DBusMessage *message, void *user_data)
+{
+	DBusError error;
+
+	dbus_error_init(&error);
+
+	if (dbus_set_error_from_message(&error, message) == TRUE) {
+		bt_shell_printf("Failed to disconnect: %s %s\n", error.name,
+				error.message);
+		dbus_error_free(&error);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bt_shell_printf("Disconnection successful\n");
+
+	return bt_shell_noninteractive_quit(EXIT_SUCCESS);
+}
+
+static void cmd_bearer_method_handler(int argc, char *argv[],
+					const char *iface,
+					const char *method)
+{
+	GDBusProxy *device;
+	GDBusProxy *bearer;
+
+	if (!check_default_ctrl())
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+
+	device = find_proxy_by_address(default_ctrl->devices, argv[1]);
+	if (!device) {
+		bt_shell_printf("Device %s not available\n", argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bearer = find_proxies_by_iface(default_ctrl->bearers,
+					g_dbus_proxy_get_path(device),
+					iface);
+	if (!bearer) {
+		bt_shell_printf("%s is not available on %s\n",
+				iface, argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	if (!g_dbus_proxy_method_call(bearer, method, NULL,
+				      strcmp(method, "Connect") == 0 ?
+					bearer_connect_reply :
+					bearer_disconn_reply,
+				      NULL, NULL)) {
+		bt_shell_printf("Failed to call %s\n", method);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bt_shell_printf("Attempting to %s %s with %s\n",
+					method,
+					argv[1],
+					iface);
+}
+
+static void cmd_connect_le(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.LE1",
+								"Connect");
+}
+
+static void cmd_disconnect_le(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.LE1",
+								"Disconnect");
+}
+
+static void cmd_connect_bredr(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.BREDR1",
+								"Connect");
+}
+
+static void cmd_disconnect_bredr(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.BREDR1",
+								"Disconnect");
+}
+
 static const struct bt_shell_menu advertise_menu = {
 	.name = "advertise",
 	.desc = "Advertise Options Submenu",
@@ -3469,6 +3757,40 @@ static const struct bt_shell_menu gatt_menu = {
 	{ } },
 };
 
+static const struct bt_shell_menu le_menu = {
+	.name = "le",
+	.desc = "LE Bearer Submenu",
+	.entries = {
+	{ "list", NULL, cmd_list_le, "List available le devices" },
+	{ "show", "[dev]", cmd_show_le,
+					"LE bearer information",
+					le_dev_generator },
+	{ "connect", "<dev>", cmd_connect_le,
+					"Connect le on a device",
+					le_dev_generator },
+	{ "disconnect", "<dev>", cmd_disconnect_le,
+					"Disconnect le on a device",
+					le_dev_generator },
+	{} },
+};
+
+static const struct bt_shell_menu bredr_menu = {
+	.name = "bredr",
+	.desc = "BREDR Bearer Submenu",
+	.entries = {
+	{ "list", NULL, cmd_list_bredr, "List available bredr devices" },
+	{ "show", "[dev]", cmd_show_bredr,
+					"BREDR bearer information",
+					bredr_dev_generator },
+	{ "connect", "<dev>", cmd_connect_bredr,
+					"Connect bredr on a device",
+					bredr_dev_generator },
+	{ "disconnect", "<dev>", cmd_disconnect_bredr,
+					"Disconnect bredr on a device",
+					bredr_dev_generator },
+	{} },
+};
+
 static const struct bt_shell_menu main_menu = {
 	.name = "main",
 	.entries = {
@@ -3593,6 +3915,8 @@ int main(int argc, char *argv[])
 	bt_shell_add_submenu(&advertise_monitor_menu);
 	bt_shell_add_submenu(&scan_menu);
 	bt_shell_add_submenu(&gatt_menu);
+	bt_shell_add_submenu(&le_menu);
+	bt_shell_add_submenu(&bredr_menu);
 	admin_add_submenu();
 	player_add_submenu();
 	mgmt_add_submenu();

-- 
2.42.0

