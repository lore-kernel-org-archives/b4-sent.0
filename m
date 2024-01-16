From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:34 +0000
Subject: [PATCH BlueZ 09/20] client: annotate struct option instances as
 const
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-9-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=6759;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=sm/sfgP6dAU9AbC/N7qkwROmrCzswI0+Dh2WodmZU+Q=;
 b=LY+e8oNSg0qw+uyxpfMnP8rqtceevobSufhTdWwfpjETR7I23ZGLcadAe+aDVXWsL/Mub4Q7u
 N4XswtaZ7I+BZiIsVU8F3nhuLXnbNnTebP1hLhvzg4EbmKM5k1nL7wX
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 client/mgmt.c | 40 ++++++++++++++++++++--------------------
 1 file changed, 20 insertions(+), 20 deletions(-)

diff --git a/client/mgmt.c b/client/mgmt.c
index e9ebb3d93..6fd43887d 100644
--- a/client/mgmt.c
+++ b/client/mgmt.c
@@ -2203,7 +2203,7 @@ static void get_flags_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option get_flags_options[] = {
+static const struct option get_flags_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "type",	1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -2272,7 +2272,7 @@ static void set_flags_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option set_flags_options[] = {
+static const struct option set_flags_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "type",	1, 0, 't' },
 	{ "flags",	1, 0, 'f' },
@@ -2678,7 +2678,7 @@ static void disconnect_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option disconnect_options[] = {
+static const struct option disconnect_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "type",	1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -2783,7 +2783,7 @@ static void find_service_rsp(uint8_t status, uint16_t len, const void *param,
 	discovery = true;
 }
 
-static struct option find_service_options[] = {
+static const struct option find_service_options[] = {
 	{ "help",	no_argument, 0, 'h' },
 	{ "le-only",	no_argument, 0, 'l' },
 	{ "bredr-only",	no_argument, 0, 'b' },
@@ -2880,7 +2880,7 @@ static void find_rsp(uint8_t status, uint16_t len, const void *param,
 	discovery = true;
 }
 
-static struct option find_options[] = {
+static const struct option find_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "le-only",	1, 0, 'l' },
 	{ "bredr-only",	1, 0, 'b' },
@@ -2952,7 +2952,7 @@ static void stop_find_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option stop_find_options[] = {
+static const struct option stop_find_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "le-only",	1, 0, 'l' },
 	{ "bredr-only",	1, 0, 'b' },
@@ -3074,7 +3074,7 @@ static void register_pair_callbacks(struct mgmt *mgmt, uint16_t index)
 						passkey_notify, mgmt, NULL);
 }
 
-static struct option pair_options[] = {
+static const struct option pair_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "capability",	1, 0, 'c' },
 	{ "type",	1, 0, 't' },
@@ -3169,7 +3169,7 @@ static void cancel_pair_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option cancel_pair_options[] = {
+static const struct option cancel_pair_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "type",	1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -3251,7 +3251,7 @@ static void unpair_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option unpair_options[] = {
+static const struct option unpair_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "type",	1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -3378,7 +3378,7 @@ static void irks_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option irks_options[] = {
+static const struct option irks_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "local",	1, 0, 'l' },
 	{ "file",	1, 0, 'f' },
@@ -3492,7 +3492,7 @@ static void block_rsp(uint16_t op, uint16_t id, uint8_t status, uint16_t len,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option block_options[] = {
+static const struct option block_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "type",	1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -3736,7 +3736,7 @@ static void remote_oob_rsp(uint8_t status, uint16_t len, const void *param,
 	print("Remote OOB data added for %s (%u)", addr, rp->type);
 }
 
-static struct option remote_oob_opt[] = {
+static const struct option remote_oob_opt[] = {
 	{ "help",	0, 0, '?' },
 	{ "type",	1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -3979,7 +3979,7 @@ static void conn_info_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option conn_info_options[] = {
+static const struct option conn_info_options[] = {
 	{ "help",       0, 0, 'h' },
 	{ "type",       1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -4150,7 +4150,7 @@ static void add_device_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option add_device_options[] = {
+static const struct option add_device_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "action",	1, 0, 'a' },
 	{ "type",	1, 0, 't' },
@@ -4223,7 +4223,7 @@ static void remove_device_rsp(uint8_t status, uint16_t len, const void *param,
 	bt_shell_noninteractive_quit(EXIT_SUCCESS);
 }
 
-static struct option del_device_options[] = {
+static const struct option del_device_options[] = {
 	{ "help",	0, 0, 'h' },
 	{ "type",	1, 0, 't' },
 	{ 0, 0, 0, 0 }
@@ -4477,7 +4477,7 @@ static void advsize_usage(void)
 		"\t -n, --local-name          \"local-name\" flag");
 }
 
-static struct option advsize_options[] = {
+static const struct option advsize_options[] = {
 	{ "help",		0, 0, 'h' },
 	{ "connectable",	0, 0, 'c' },
 	{ "general-discov",	0, 0, 'g' },
@@ -4597,7 +4597,7 @@ static void add_adv_usage(void)
 		"\tadd-adv -u 180d -u 180f -d 080954657374204C45 1");
 }
 
-static struct option add_adv_options[] = {
+static const struct option add_adv_options[] = {
 	{ "help",		0, 0, 'h' },
 	{ "uuid",		1, 0, 'u' },
 	{ "adv-data",		1, 0, 'd' },
@@ -4935,7 +4935,7 @@ static void add_ext_adv_params_usage(void)
 		"\tadd-ext-adv-params -r 0x801 -x 0x802 -P 2M -g 1");
 }
 
-static struct option add_ext_adv_params_options[] = {
+static const struct option add_ext_adv_params_options[] = {
 	{ "help",		0, 0, 'h' },
 	{ "duration",		1, 0, 'd' },
 	{ "timeout",		1, 0, 't' },
@@ -5113,7 +5113,7 @@ static void add_ext_adv_data_usage(void)
 		"\tadd-ext-adv-data -u 180d -u 180f -d 080954657374204C45 1");
 }
 
-static struct option add_ext_adv_data_options[] = {
+static const struct option add_ext_adv_data_options[] = {
 	{ "help",		0, 0, 'h' },
 	{ "uuid",		1, 0, 'u' },
 	{ "adv-data",		1, 0, 'd' },
@@ -5557,7 +5557,7 @@ static bool str2pattern(struct mgmt_adv_pattern *pattern, const char *str)
 	return true;
 }
 
-static struct option add_monitor_rssi_options[] = {
+static const struct option add_monitor_rssi_options[] = {
 	{ "help",		0, 0, 'h' },
 	{ "high-threshold",	1, 0, 'R' },
 	{ "low-threshold",	1, 0, 'r' },

-- 
2.43.0

