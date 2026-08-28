From: Tim Sweetman <agenttimblog@gmail.com>
Date: Fri, 28 Aug 2026 15:52:10 -0500
Subject: [PATCH BlueZ] client: Handle system bus setup failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260828-master-v1-1-4810753bb693@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBQFr0Le2ia1IdJ6FeOiwEO/UTT9QAiEu
 1tlOZPJrFAmoeJcrEicROXdZzgeCjT32N9opM0MZ93JeufNK+rAZOgrGwJjWbqAHH8SO5n/owv
 q58gF113rWD/YDL8Jtu0LnhRwPHEAAAA=
X-Change-ID: 20260828-master-e87099ea4429
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787950335; l=1695;
 i=agenttimblog@gmail.com; s=20260828; h=from:subject:message-id;
 bh=7y4abkrz48lLqW5SQLAirvn4+UMow52d5O4nL718atw=;
 b=aqp96l0FFhoUb32dl2O8Y1xZXdABV3B9TBk+ZAx+Cwfk8/WQku141/+tCPtUhg1cvchsnzJWU
 lix23FzYzTXCO4AUTi6PwagVuczrXT27GTG1Nk2aUqF1NucC46WeuBI
X-Developer-Key: i=agenttimblog@gmail.com; a=ed25519;
 pk=NS/gYW7o9HkuX4A52JuRee/RWJwzgk9mNfy2J4gZag4=
X-Endpoint-Received: by B4 Relay for agenttimblog@gmail.com/20260828 with auth_id=985
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

g_dbus_setup_bus() returns NULL when it cannot connect to the system
bus. bluetoothctl currently passes that NULL connection to
g_dbus_attach_object_manager(), causing libdbus to abort on its
connection assertion.

Initialize a DBusError, report the connection failure, and exit cleanly
before using the connection.

Fixes: https://github.com/bluez/bluez/issues/2446
---
Tested with make check (34 tests).
---
 client/main.c | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/client/main.c b/client/main.c
index 069e20485..d7cecb118 100644
--- a/client/main.c
+++ b/client/main.c
@@ -4017,6 +4017,7 @@ static bool timeout_quit(void *user_data)
 int main(int argc, char *argv[])
 {
 	GDBusClient *client;
+	DBusError error;
 	int status;
 	int timeout;
 	unsigned int timeout_id;
@@ -4048,7 +4049,21 @@ int main(int argc, char *argv[])
 	else
 		auto_register_agent = g_strdup("");
 
-	dbus_conn = g_dbus_setup_bus(DBUS_BUS_SYSTEM, NULL, NULL);
+	dbus_error_init(&error);
+	dbus_conn = g_dbus_setup_bus(DBUS_BUS_SYSTEM, NULL, &error);
+	if (dbus_conn == NULL) {
+		if (dbus_error_is_set(&error)) {
+			fprintf(stderr, "Failed to connect to system bus: %s\n",
+							error.message);
+			dbus_error_free(&error);
+		} else {
+			fprintf(stderr, "Failed to connect to system bus\n");
+		}
+
+		g_free(auto_register_agent);
+		return EXIT_FAILURE;
+	}
+
 	g_dbus_attach_object_manager(dbus_conn);
 
 	bt_shell_set_env("DBUS_CONNECTION", dbus_conn);

---
base-commit: e8141342284be2a52e16565b96b513ebe1297d84
change-id: 20260828-master-e87099ea4429

Best regards,
--  
Tim Sweetman <agenttimblog@gmail.com>

