From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:30 +0000
Subject: [PATCH BlueZ 05/20] monitor: const annotate
 intel_version_tlv_desc::type_str and API
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-5-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=3446;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=wahNKDM8iDeiZs6EV1R7VsClaT+QYMSeKeI21SRP6Aw=;
 b=Gdy8Fb4gEVdZRo4gvD5rfT/5wHjL+tFQXVs8a5soi0m05zIDj/c71TZAkIjwMmFZzSZ4VmXld
 Llp1vuZnqopC+ulU8e/VkD5vQ8moTkPyDVbGG+TXmDB+C6J9ZRrucwB
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 monitor/intel.c | 26 +++++++++++++-------------
 1 file changed, 13 insertions(+), 13 deletions(-)

diff --git a/monitor/intel.c b/monitor/intel.c
index 1b2414290..0de864d8a 100644
--- a/monitor/intel.c
+++ b/monitor/intel.c
@@ -171,25 +171,25 @@ struct intel_version_tlv {
 };
 
 static void print_version_tlv_u32(const struct intel_version_tlv *tlv,
-				  char *type_str)
+				  const char *type_str)
 {
 	print_field("%s(%u): 0x%8.8x", type_str, tlv->type, get_le32(tlv->val));
 }
 
 static void print_version_tlv_u16(const struct intel_version_tlv *tlv,
-				  char *type_str)
+				  const char *type_str)
 {
 	print_field("%s(%u): 0x%4.4x", type_str, tlv->type, get_le16(tlv->val));
 }
 
 static void print_version_tlv_u8(const struct intel_version_tlv *tlv,
-				 char *type_str)
+				 const char *type_str)
 {
 	print_field("%s(%u): 0x%2.2x", type_str, tlv->type, get_u8(tlv->val));
 }
 
 static void print_version_tlv_enabled(const struct intel_version_tlv *tlv,
-				      char *type_str)
+				      const char *type_str)
 {
 	print_field("%s(%u): %s(%u)", type_str, tlv->type,
 					tlv->val[0] ? "Enabled" : "Disabled",
@@ -197,7 +197,7 @@ static void print_version_tlv_enabled(const struct intel_version_tlv *tlv,
 }
 
 static void print_version_tlv_img_type(const struct intel_version_tlv *tlv,
-				       char *type_str)
+				       const char *type_str)
 {
 	const char *str;
 
@@ -217,34 +217,34 @@ static void print_version_tlv_img_type(const struct intel_version_tlv *tlv,
 }
 
 static void print_version_tlv_timestamp(const struct intel_version_tlv *tlv,
-					char *type_str)
+					const char *type_str)
 {
 	print_field("%s(%u): %u-%u", type_str, tlv->type,
 				tlv->val[1], tlv->val[0]);
 }
 
 static void print_version_tlv_min_fw(const struct intel_version_tlv *tlv,
-				     char *type_str)
+				     const char *type_str)
 {
 	print_field("%s(%u): %u-%u.%u", type_str, tlv->type,
 				tlv->val[0], tlv->val[1], 2000 + tlv->val[2]);
 }
 
 static void print_version_tlv_otp_bdaddr(const struct intel_version_tlv *tlv,
-					 char *type_str)
+					 const char *type_str)
 {
 	packet_print_addr(type_str, tlv->val, 0x00);
 }
 
 static void print_version_tlv_unknown(const struct intel_version_tlv *tlv,
-				      char *type_str)
+				      const char *type_str)
 {
 	print_field("%s(%u): ", type_str, tlv->type);
 	packet_hexdump(tlv->val, tlv->len);
 }
 
 static void print_version_tlv_mfg(const struct intel_version_tlv *tlv,
-					 char *type_str)
+					 const char *type_str)
 {
 	uint16_t mfg_id = get_le16(tlv->val);
 
@@ -254,8 +254,8 @@ static void print_version_tlv_mfg(const struct intel_version_tlv *tlv,
 
 static const struct intel_version_tlv_desc {
 	uint8_t type;
-	char *type_str;
-	void (*func)(const struct intel_version_tlv *tlv, char *type_str);
+	const char *type_str;
+	void (*func)(const struct intel_version_tlv *tlv, const char *type_str);
 } intel_version_tlv_table[] = {
 	{ 16, "CNVi TOP", print_version_tlv_u32 },
 	{ 17, "CNVr TOP", print_version_tlv_u32 },
@@ -365,7 +365,7 @@ static void read_version_rsp(uint16_t index, const void *data, uint8_t size)
 
 static void read_version_cmd(uint16_t index, const void *data, uint8_t size)
 {
-	char *str;
+	const char *str;
 	uint8_t type;
 
 	/* This is the legacy read version command format and no further action

-- 
2.43.0

