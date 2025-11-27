From: Ye He <ye.he@amlogic.com>
Date: Thu, 27 Nov 2025 17:54:23 +0800
Subject: [PATCH bluez v7 3/3] client: Add shell cmd for bearer
 connect/disconnect
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251127-bearer-impl-v7-3-9a5b06468992@amlogic.com>
References: <20251127-bearer-impl-v7-0-9a5b06468992@amlogic.com>
In-Reply-To: <20251127-bearer-impl-v7-0-9a5b06468992@amlogic.com>
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
Cc: Ye He <ye.he@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764237268; l=6967;
 i=ye.he@amlogic.com; s=20250225; h=from:subject:message-id;
 bh=wERB3OtXjFIDHkdAcnTGog2nanJSV3d+Lb7jcSyAgqY=;
 b=kXo3tF/537M3sbTxsOjbNTwTIMyDZImQ59JzJpu/YG5elpqP3vV+Ozh9ejqMxaoBcCiw80O8X
 LLO5QRpxuNwAPNfE7iXL+7i+90VZBAER7hzsQwXn6Zx2bKCFy9vEuzh
X-Developer-Key: i=ye.he@amlogic.com; a=ed25519;
 pk=hiK/p0mkXYSkX8Ooa496DfgjnbtdcyXSPFwK2LN49CE=
X-Endpoint-Received: by B4 Relay for ye.he@amlogic.com/20250225 with auth_id=348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch adds shell command for bearer connect/disconnect.

Signed-off-by: Ye He <ye.he@amlogic.com>
---
 client/bluetoothctl.rst |  49 ++++++++++++++++
 client/main.c           | 152 ++++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 201 insertions(+)

diff --git a/client/bluetoothctl.rst b/client/bluetoothctl.rst
index 0187e877d60b28eb1e735181b3203e60da821e6f..87aae8995a29749ffa09bbfefbd74c41f242fedc 100644
--- a/client/bluetoothctl.rst
+++ b/client/bluetoothctl.rst
@@ -296,6 +296,55 @@ needed.
 
 :Usage: **> disconnect <dev> [uuid]**
 
+le-connect
+----------
+
+Connect device over le.
+
+This command initiates a le connection to a remote device.
+
+An active scan report is required before the connection can be
+established. If no advertising report is received before the timeout,
+a le-connection-abort-by-local error will be issued.
+
+:Usage: > le-connect <dev>
+:Example: > le-connect 1C:48:F9:9D:81:5C
+
+le-disconnect
+-------------
+
+Disconnect device over le.
+
+By default this command disconnects all profiles/services associated with the le
+connection, and then terminates the le link.
+
+:Usage: > le-disconnect <dev>
+:Example: > le-disconnect 1C:48:F9:9D:81:5C
+
+bredr-connect
+-------------
+
+Connect device over bredr.
+
+This command initiates a bredr connection to a remote device.
+
+By default, it establishes the bredr connection and then connects all profiles
+that marked as auto-connectable.
+
+:Usage: > bredr-connect <dev>
+:Example: > bredr-connect 1C:48:F9:9D:81:5C
+
+bredr-disconnect
+----------------
+
+Disconnect device over bredr.
+
+By default this command disconnects all profiles associated with the bredr
+connection, and then terminates the bredr link.
+
+:Usage: > bredr-disconnect <dev>
+:Example: > bredr-disconnect 1C:48:F9:9D:81:5C
+
 info
 ----
 
diff --git a/client/main.c b/client/main.c
index 0a928efaa9bb0d2a806895ff8f8c0c7c0d2493bd..45ebea44f9eda80f939b9f8324fb60064f28eb50 100644
--- a/client/main.c
+++ b/client/main.c
@@ -2303,6 +2303,106 @@ static void cmd_disconn(int argc, char *argv[])
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
+	bt_shell_printf("Attempting to %s %s on %s\n",
+					method,
+					argv[1],
+					iface);
+}
+
+static void cmd_le_connect(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.LE1",
+								"Connect");
+}
+
+static void cmd_le_disconnect(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.LE1",
+								"Disconnect");
+}
+
+static void cmd_bredr_connect(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.BREDR1",
+								"Connect");
+}
+
+static void cmd_bredr_disconnect(int argc, char *argv[])
+{
+	cmd_bearer_method_handler(argc, argv, "org.bluez.Bearer.BREDR1",
+								"Disconnect");
+}
+
 static void cmd_wake(int argc, char *argv[])
 {
 	GDBusProxy *proxy;
@@ -2789,6 +2889,47 @@ static char *dev_set_generator(const char *text, int state)
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
@@ -3528,6 +3669,17 @@ static const struct bt_shell_menu main_menu = {
 	{ "disconnect",   "[dev] [uuid]", cmd_disconn,
 				"Disconnect a device or optionally disconnect "
 				"a single profile only", dev_generator },
+	{ "le-connect", "<dev>", cmd_le_connect,
+				"Connect le on a device", le_dev_generator },
+	{ "le-disconnect", "<dev>", cmd_le_disconnect,
+				"Disconnect le on a device",
+							le_dev_generator },
+	{ "bredr-connect", "<dev>", cmd_bredr_connect,
+				"Connect bredr on a device",
+							bredr_dev_generator },
+	{ "bredr-disconnect", "<dev>", cmd_bredr_disconnect,
+				"Disconnect bredr on a device",
+							bredr_dev_generator },
 	{ "wake",         "[dev] [on/off]",    cmd_wake, "Get/Set wake support",
 							dev_generator },
 	{ "bearer",       "<dev> [last-seen/bredr/le]", cmd_bearer,

-- 
2.42.0

