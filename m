From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:33 +0000
Subject: [PATCH BlueZ 08/20] attrib: annotate immutable data as const
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-8-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=2060;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=r4UogXNZcqpBuo7KQeXLw6rUdfC5zty52k+yB4yl1Y0=;
 b=mcb7UxZAS4sKzhr8clOsa8yzBMZk2BwF27jvxTI5K8j3tC/6Wgv1EI5UQnd75d/catNnLTzad
 FKDbyDo5gtyB8i22pOqv89O7cIbPK4PnN/t01btFwkVOaq8KqxZTUeY
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 attrib/gatttool.c    | 8 ++++----
 attrib/interactive.c | 2 +-
 2 files changed, 5 insertions(+), 5 deletions(-)

diff --git a/attrib/gatttool.c b/attrib/gatttool.c
index 2d03875b0..4309d20b1 100644
--- a/attrib/gatttool.c
+++ b/attrib/gatttool.c
@@ -454,7 +454,7 @@ static gboolean parse_uuid(const char *key, const char *value,
 	return TRUE;
 }
 
-static GOptionEntry primary_char_options[] = {
+static const GOptionEntry primary_char_options[] = {
 	{ "start", 's' , 0, G_OPTION_ARG_INT, &opt_start,
 		"Starting handle (optional)", "0x0001" },
 	{ "end", 'e' , 0, G_OPTION_ARG_INT, &opt_end,
@@ -464,7 +464,7 @@ static GOptionEntry primary_char_options[] = {
 	{ NULL },
 };
 
-static GOptionEntry char_rw_options[] = {
+static const GOptionEntry char_rw_options[] = {
 	{ "handle", 'a' , 0, G_OPTION_ARG_INT, &opt_handle,
 		"Read/Write characteristic by handle (required)", "0x0001" },
 	{ "value", 'n' , 0, G_OPTION_ARG_STRING, &opt_value,
@@ -473,7 +473,7 @@ static GOptionEntry char_rw_options[] = {
 	{NULL},
 };
 
-static GOptionEntry gatt_options[] = {
+static const GOptionEntry gatt_options[] = {
 	{ "primary", 0, 0, G_OPTION_ARG_NONE, &opt_primary,
 		"Primary Service Discovery", NULL },
 	{ "characteristics", 0, 0, G_OPTION_ARG_NONE, &opt_characteristics,
@@ -494,7 +494,7 @@ static GOptionEntry gatt_options[] = {
 	{ NULL },
 };
 
-static GOptionEntry options[] = {
+static const GOptionEntry options[] = {
 	{ "adapter", 'i', 0, G_OPTION_ARG_STRING, &opt_src,
 		"Specify local adapter interface", "hciX" },
 	{ "device", 'b', 0, G_OPTION_ARG_STRING, &opt_dst,
diff --git a/attrib/interactive.c b/attrib/interactive.c
index 171b95738..c0262e87c 100644
--- a/attrib/interactive.c
+++ b/attrib/interactive.c
@@ -760,7 +760,7 @@ static void cmd_mtu(int argcp, char **argvp)
 	gatt_exchange_mtu(attrib, opt_mtu, exchange_mtu_cb, NULL);
 }
 
-static struct {
+static const struct {
 	const char *cmd;
 	void (*func)(int argcp, char **argvp);
 	const char *params;

-- 
2.43.0

