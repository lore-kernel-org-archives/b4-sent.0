From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:29 +0000
Subject: [PATCH BlueZ 04/20] monitor: const annotate misc arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-4-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=3310;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=sDFz/h5HNC2kVyVsavc6FYhQwHcER0nnd3cc13qPQdk=;
 b=p+E599P8FUnPy1mWk/ocsd4lxhjB07GHNOyenW456WJYuZdwCMm8xAzwmuhjJTh7zyfaPDT8w
 zPuFMJDhn5fDgurnm4qC1eUio9V67HyWPRFrqNM4kOp0co5Uv6KauTA
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 monitor/att.c    | 8 ++++----
 monitor/avctp.c  | 2 +-
 monitor/intel.c  | 2 +-
 monitor/l2cap.c  | 2 +-
 monitor/rfcomm.c | 2 +-
 monitor/sdp.c    | 4 ++--
 6 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/monitor/att.c b/monitor/att.c
index d016e58df..ac0d881fd 100644
--- a/monitor/att.c
+++ b/monitor/att.c
@@ -2581,7 +2581,7 @@ static void media_state_notify(const struct l2cap_frame *frame)
 	print_media_state(frame);
 }
 
-struct media_cp_opcode {
+static const struct media_cp_opcode {
 	uint8_t opcode;
 	const char *opcode_str;
 } media_cp_opcode_table[] = {
@@ -2739,7 +2739,7 @@ static void content_control_id_read(const struct l2cap_frame *frame)
 
 static const struct pa_sync_state_decoder {
 	uint8_t code;
-	char *value;
+	const char *value;
 } pa_sync_state_decoders[] = {
 	{ 0x00, "Not synchronized to PA" },
 	{ 0x01, "SyncInfo Request" },
@@ -2750,7 +2750,7 @@ static const struct pa_sync_state_decoder {
 
 static const struct cp_pa_sync_state_decoder {
 	uint8_t code;
-	char *value;
+	const char *value;
 } cp_pa_sync_state_decoders[] = {
 	{ 0x00, "Do not synchronize to PA" },
 	{ 0x01, "Synchronize to PA - PAST available" },
@@ -2759,7 +2759,7 @@ static const struct cp_pa_sync_state_decoder {
 
 static const struct big_enc_decoder {
 	uint8_t code;
-	char *value;
+	const char *value;
 } big_enc_decoders[] = {
 	{ 0x00, "Not encrypted" },
 	{ 0x01, "Broadcast_Code required" },
diff --git a/monitor/avctp.c b/monitor/avctp.c
index fb2628282..c59e93b20 100644
--- a/monitor/avctp.c
+++ b/monitor/avctp.c
@@ -1802,7 +1802,7 @@ response:
 }
 
 
-static struct {
+static const struct {
 	const char *str;
 	bool reserved;
 } features_table[] = {
diff --git a/monitor/intel.c b/monitor/intel.c
index 0191987d4..1b2414290 100644
--- a/monitor/intel.c
+++ b/monitor/intel.c
@@ -1798,7 +1798,7 @@ static const struct vendor_evt vendor_prefix_evt_table[] = {
 	{ }
 };
 
-const uint8_t intel_vendor_prefix[] = {0x87, 0x80};
+static const uint8_t intel_vendor_prefix[] = {0x87, 0x80};
 #define INTEL_VENDOR_PREFIX_SIZE sizeof(intel_vendor_prefix)
 
 /*
diff --git a/monitor/l2cap.c b/monitor/l2cap.c
index 8f3d8e65b..dff183bd0 100644
--- a/monitor/l2cap.c
+++ b/monitor/l2cap.c
@@ -718,7 +718,7 @@ static void print_config_result(uint16_t result)
 	print_field("Result: %s (0x%4.4x)", str, le16_to_cpu(result));
 }
 
-static struct {
+static const struct {
 	uint8_t type;
 	uint8_t len;
 	const char *str;
diff --git a/monitor/rfcomm.c b/monitor/rfcomm.c
index 02300a8b5..a855152c6 100644
--- a/monitor/rfcomm.c
+++ b/monitor/rfcomm.c
@@ -32,7 +32,7 @@
 #include "sdp.h"
 #include "rfcomm.h"
 
-static char *cr_str[] = {
+static const char *cr_str[] = {
 	"RSP",
 	"CMD"
 };
diff --git a/monitor/sdp.c b/monitor/sdp.c
index daf9a9da8..2c69dc83b 100644
--- a/monitor/sdp.c
+++ b/monitor/sdp.c
@@ -167,7 +167,7 @@ static struct {
 	{ }
 };
 
-static struct {
+static const struct {
 	uint8_t index;
 	uint8_t bits;
 	uint8_t size;
@@ -322,7 +322,7 @@ static uint32_t get_bytes(const uint8_t *data, uint32_t size)
 	return 0;
 }
 
-static struct {
+static const struct {
 	uint16_t id;
 	const char *str;
 } attribute_table[] = {

-- 
2.43.0

