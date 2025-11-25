From: Ye He <ye.he@amlogic.com>
Date: Tue, 25 Nov 2025 15:01:16 +0800
Subject: [PATCH bluez v5 3/3] client: Add shell cmd for bearer
 connect/disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251125-bearer-impl-v5-3-ce1ce5ad19d9@amlogic.com>
References: <20251125-bearer-impl-v5-0-ce1ce5ad19d9@amlogic.com>
In-Reply-To: <20251125-bearer-impl-v5-0-ce1ce5ad19d9@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764054092; l=6942;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=KpEi9/04/MX2wi3Rs4MiaEEYpqg4yvHQbi0Cs5dMeSs=;
 b=vdLeCLjQW13m1rwVNR8K4DdE5ufpwxZVVZN2NsViauwXj5Erqab+5sbWfTgjA+vZZZ/DdKjUG
 yNAUH9cd9wYCEV3rRrw65L2D+ddi7OsdQC/qgWNwcDS5Mk6yuhoel+h
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds shell command for bearer connect/disconnect.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 client/bluetoothctl.rst |  34 ++++++++++++
 client/main.c           | 141 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 175 insertions(+)

diff --git a/client/bluetoothctl.rst b/client/bluetoothctl.rst
index 0187e877d60b28eb1e735181b3203e60da821e6f..e10933eb90e9d1ab830ebba6d210d940b2d91d35 100644
--- a/client/bluetoothctl.rst
+++ b/client/bluetoothctl.rst
@@ -296,6 +296,40 @@ needed.
 
 :Usage: **> disconnect <dev> [uuid]**
 
+connect-bearer
+--------------
+
+Connect device with specified bearer.
+
+This command initiates a bearer-level connection to a remote device.
+
+By default this command connects the specified bearer (LE or BREDR)
+and all profiles that are associated with that bearer and marked as
+auto-connectable. Only the profiles bound to the selected bearer
+will be considered, profiles on the other bearer are not affected.
+
+For LE connections an active scan report is required before the connection
+can be established. If no advertising report is received before the timeout,
+a le-connection-abort-by-local error will be issued.
+
+:Usage: > connect-bearer <dev> <le/bredr>
+:Example: > connect-bearer 1C:48:F9:9D:81:5C le
+:Example: > connect-bearer 1C:48:F9:9D:81:5C bredr
+
+disconnect-bearer
+-----------------
+
+Disconnect device with specified bearer.
+
+By default this command disconnects all profiles associated with the specified
+bearer (LE or BREDR) and then terminates that bearer's link. Only profiles
+bound to the selected bearer are affected, profiles on the other bearer remain
+connected.
+
+:Usage: > disconnect-bearer <dev> <le/bredr>
+:Example: > disconnect-bearer 1C:48:F9:9D:81:5C le
+:Example: > disconnect-bearer 1C:48:F9:9D:81:5C bredr
+
 info
 ----
 
diff --git a/client/main.c b/client/main.c
index 0a928efaa9bb0d2a806895ff8f8c0c7c0d2493bd..5a0862a1bc1eb5104c78aeba9722375ef526e756 100644
--- a/client/main.c
+++ b/client/main.c
@@ -2303,6 +2303,141 @@ static void cmd_disconn(int argc, char *argv[])
 						proxy_address(proxy));
 }
 
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
+static void cmd_connect_bearer(int argc, char *argv[])
+{
+	const char *type;
+	GDBusProxy *device;
+	GDBusProxy *bearer;
+
+	if (argc < 3) {
+		bt_shell_printf("Usage: connect-bearer <dev> <le/bredr>\n");
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	device = find_device(argc, argv);
+	if (!device) {
+		bt_shell_printf("Device %s not available\n", argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	type = argv[2];
+
+	if (strcmp(type, "le") != 0 && strcmp(type, "bredr") != 0) {
+		bt_shell_printf("Invalid bearer type: %s, "
+			"Usage: connect-bearer <dev> <le/bredr>\n", type);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	if (!strcmp(type, "bredr"))
+		bearer = find_proxies_by_iface(default_ctrl->bearers,
+					g_dbus_proxy_get_path(device),
+					"org.bluez.Bearer.BREDR1");
+	else if (!strcmp(type, "le"))
+		bearer = find_proxies_by_iface(default_ctrl->bearers,
+					g_dbus_proxy_get_path(device),
+					"org.bluez.Bearer.LE1");
+
+	if (!bearer) {
+		bt_shell_printf("No bearer(%s) on device %s\n", type, argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	if (g_dbus_proxy_method_call(bearer, "Connect", NULL,
+				bearer_connect_reply, NULL, NULL) == FALSE) {
+		bt_shell_printf("Failed to call bearer Connect\n");
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bt_shell_printf("Attempting to connect bearer(%s) to %s\n",
+			type, argv[1]);
+}
+
+static void cmd_disconnect_bearer(int argc, char *argv[])
+{
+	const char *type;
+	GDBusProxy *device;
+	GDBusProxy *bearer;
+
+	if (argc < 3) {
+		bt_shell_printf("Usage: disconnect-bearer <dev> <le/bredr>\n");
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	device = find_device(argc, argv);
+	if (!device) {
+		bt_shell_printf("Device %s not available\n", argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	type = argv[2];
+
+	if (strcmp(type, "le") != 0 && strcmp(type, "bredr") != 0) {
+		bt_shell_printf("Invalid bearer type: %s, "
+			"Usage: disconnect-bearer <dev> <le/bredr>\n", type);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	if (!strcmp(type, "bredr"))
+		bearer = find_proxies_by_iface(default_ctrl->bearers,
+					g_dbus_proxy_get_path(device),
+					"org.bluez.Bearer.BREDR1");
+	else if (!strcmp(type, "le"))
+		bearer = find_proxies_by_iface(default_ctrl->bearers,
+					g_dbus_proxy_get_path(device),
+					"org.bluez.Bearer.LE1");
+
+	if (!bearer) {
+		bt_shell_printf("No bearer(%s) on device %s\n", type, argv[1]);
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	if (g_dbus_proxy_method_call(bearer, "Disconnect",NULL,
+				bearer_disconn_reply, NULL, NULL) == FALSE) {
+		bt_shell_printf("Failed to call bearer Disconnect\n");
+		return bt_shell_noninteractive_quit(EXIT_FAILURE);
+	}
+
+	bt_shell_printf("Attempting to disconnect bearer(%s) from %s\n",
+			type,
+			argv[1]);
+}
+
 static void cmd_wake(int argc, char *argv[])
 {
 	GDBusProxy *proxy;
@@ -3528,6 +3663,12 @@ static const struct bt_shell_menu main_menu = {
 	{ "disconnect",   "[dev] [uuid]", cmd_disconn,
 				"Disconnect a device or optionally disconnect "
 				"a single profile only", dev_generator },
+	{ "connect-bearer", "<dev> <le/bredr>", cmd_connect_bearer,
+				"Connect a specific bearer on a device",
+							dev_generator },
+	{ "disconnect-bearer", "<dev> <le/bredr>", cmd_disconnect_bearer,
+				"Disconnect a specific bearer on a device",
+							dev_generator },
 	{ "wake",         "[dev] [on/off]",    cmd_wake, "Get/Set wake support",
 							dev_generator },
 	{ "bearer",       "<dev> [last-seen/bredr/le]", cmd_bearer,

-- 
2.42.0

