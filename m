From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:27 +0000
Subject: [PATCH BlueZ 02/20] monitor: const annotate util_ltv_debugger
 instances and API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-2-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=2252;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=SWETOT2uVy6nUDBhnJWLVd9iTSKcoM2gRJYy59LqmtQ=;
 b=LSW+gQOehX9oFttXX2MOvyPWVh81sCxYC31oTPd+wg3hT0QDevNUgrrtgAbIOlLsZDVSm6NCK
 7BsgwcMBXFCDTKXIR0rHHqGyN5vHq0yCvUV1y9dLjxmFQARNa4QH/Yn
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 monitor/att.c | 12 ++++++------
 1 file changed, 6 insertions(+), 6 deletions(-)

diff --git a/monitor/att.c b/monitor/att.c
index 9db273223..51a5a759c 100644
--- a/monitor/att.c
+++ b/monitor/att.c
@@ -683,7 +683,7 @@ static void print_ltv(const char *str, void *user_data)
 }
 
 static bool print_ase_lv(const struct l2cap_frame *frame, const char *label,
-			struct util_ltv_debugger *decoder, size_t decoder_len)
+			const struct util_ltv_debugger *decoder, size_t decoder_len)
 {
 	struct bt_hci_lv_data *lv;
 
@@ -705,7 +705,7 @@ static bool print_ase_lv(const struct l2cap_frame *frame, const char *label,
 }
 
 static bool print_ase_cc(const struct l2cap_frame *frame, const char *label,
-			struct util_ltv_debugger *decoder, size_t decoder_len)
+			const struct util_ltv_debugger *decoder, size_t decoder_len)
 {
 	return print_ase_lv(frame, label, decoder, decoder_len);
 }
@@ -813,7 +813,7 @@ done:
 		print_hex_field("    Data", frame.data, frame.size);
 }
 
-struct util_ltv_debugger ase_metadata_table[] = {
+static const struct util_ltv_debugger ase_metadata_table[] = {
 	UTIL_LTV_DEBUG(0x01, ase_debug_preferred_context),
 	UTIL_LTV_DEBUG(0x02, ase_debug_context),
 	UTIL_LTV_DEBUG(0x03, ase_debug_program_info),
@@ -994,7 +994,7 @@ done:
 		print_hex_field("    Data", frame.data, frame.size);
 }
 
-struct util_ltv_debugger pac_cap_table[] = {
+static const struct util_ltv_debugger pac_cap_table[] = {
 	UTIL_LTV_DEBUG(0x01, pac_decode_freq),
 	UTIL_LTV_DEBUG(0x02, pac_decode_duration),
 	UTIL_LTV_DEBUG(0x03, pac_decode_channels),
@@ -1336,7 +1336,7 @@ done:
 		print_hex_field("    Data", frame.data, frame.size);
 }
 
-struct util_ltv_debugger ase_cc_table[] = {
+static const struct util_ltv_debugger ase_cc_table[] = {
 	UTIL_LTV_DEBUG(0x01, ase_debug_freq),
 	UTIL_LTV_DEBUG(0x02, ase_debug_duration),
 	UTIL_LTV_DEBUG(0x03, ase_debug_location),
@@ -2769,7 +2769,7 @@ static const struct big_enc_decoder {
 
 static bool print_subgroup_lv(const struct l2cap_frame *frame,
 				const char *label,
-				struct util_ltv_debugger *debugger,
+				const struct util_ltv_debugger *debugger,
 				size_t debugger_len)
 {
 	struct bt_hci_lv_data *lv;

-- 
2.43.0

