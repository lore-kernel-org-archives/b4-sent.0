From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:28 +0000
Subject: [PATCH BlueZ 03/20] monitor: const annotate cmd/handler tables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-3-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=5458;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=G1oEfndUXIx9ZaeJOw7f2lTR5gMal19DcxjjtpnQtrs=;
 b=R7vMkF9cbteTavwtxRP9dxHoEc0n4CB2WuzcnwQx4JRJffUWOWPULHeMofmlzGEjadiCn6Uld
 +g0KVozorfOBYoSyJXe1jvS18Tw4pUcOaVtQDjfKbFjqZZW2QXYoKNY
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 monitor/att.c | 34 +++++++++++++++++-----------------
 1 file changed, 17 insertions(+), 17 deletions(-)

diff --git a/monitor/att.c b/monitor/att.c
index 51a5a759c..d016e58df 100644
--- a/monitor/att.c
+++ b/monitor/att.c
@@ -1710,7 +1710,7 @@ static bool ase_release_cmd(const struct l2cap_frame *frame)
 	.func = _func, \
 }
 
-struct ase_cmd {
+static const struct ase_cmd {
 	const char *desc;
 	bool (*func)(const struct l2cap_frame *frame);
 } ase_cmd_table[] = {
@@ -1732,7 +1732,7 @@ struct ase_cmd {
 	ASE_CMD(0x08, "Release", ase_release_cmd),
 };
 
-static struct ase_cmd *ase_get_cmd(uint8_t op)
+static const struct ase_cmd *ase_get_cmd(uint8_t op)
 {
 	if (op > ARRAY_SIZE(ase_cmd_table))
 		return NULL;
@@ -1743,7 +1743,7 @@ static struct ase_cmd *ase_get_cmd(uint8_t op)
 static void print_ase_cmd(const struct l2cap_frame *frame)
 {
 	uint8_t op, num, i;
-	struct ase_cmd *cmd;
+	const struct ase_cmd *cmd;
 
 	if (!l2cap_frame_get_u8((void *)frame, &op)) {
 		print_text(COLOR_ERROR, "opcode: invalid size");
@@ -1911,7 +1911,7 @@ static bool print_ase_cp_rsp_reason(const struct l2cap_frame *frame)
 static void print_ase_cp_rsp(const struct l2cap_frame *frame)
 {
 	uint8_t op, num, i;
-	struct ase_cmd *cmd;
+	const struct ase_cmd *cmd;
 
 	if (!l2cap_frame_get_u8((void *)frame, &op)) {
 		print_text(COLOR_ERROR, "    opcode: invalid size");
@@ -2161,7 +2161,7 @@ static bool vcs_absolute_cmd(const struct l2cap_frame *frame)
 	.func = _func, \
 }
 
-struct vcs_cmd {
+static const struct vcs_cmd {
 	const char *desc;
 	bool (*func)(const struct l2cap_frame *frame);
 } vcs_cmd_table[] = {
@@ -2181,7 +2181,7 @@ struct vcs_cmd {
 	VCS_CMD(0x06, "Mute", vcs_config_cmd),
 };
 
-static struct vcs_cmd *vcs_get_cmd(uint8_t op)
+static const struct vcs_cmd *vcs_get_cmd(uint8_t op)
 {
 	if (op > ARRAY_SIZE(vcs_cmd_table))
 		return NULL;
@@ -2192,7 +2192,7 @@ static struct vcs_cmd *vcs_get_cmd(uint8_t op)
 static void print_vcs_cmd(const struct l2cap_frame *frame)
 {
 	uint8_t op;
-	struct vcs_cmd *cmd;
+	const struct vcs_cmd *cmd;
 
 	if (!l2cap_frame_get_u8((void *)frame, &op)) {
 		print_text(COLOR_ERROR, "opcode: invalid size");
@@ -3135,7 +3135,7 @@ static void bcast_audio_scan_cp_remove_src_cmd(const struct l2cap_frame *frame)
 	print_field("    Source_ID: %u", id);
 }
 
-struct bcast_audio_scan_cp_cmd {
+static const struct bcast_audio_scan_cp_cmd {
 	const char *desc;
 	void (*func)(const struct l2cap_frame *frame);
 } bcast_audio_scan_cp_cmd_table[] = {
@@ -3157,7 +3157,7 @@ struct bcast_audio_scan_cp_cmd {
 					bcast_audio_scan_cp_remove_src_cmd),
 };
 
-static struct bcast_audio_scan_cp_cmd *bcast_audio_scan_cp_get_cmd(uint8_t op)
+static const struct bcast_audio_scan_cp_cmd *bcast_audio_scan_cp_get_cmd(uint8_t op)
 {
 	if (op > ARRAY_SIZE(bcast_audio_scan_cp_cmd_table))
 		return NULL;
@@ -3168,7 +3168,7 @@ static struct bcast_audio_scan_cp_cmd *bcast_audio_scan_cp_get_cmd(uint8_t op)
 static void print_bcast_audio_scan_cp_cmd(const struct l2cap_frame *frame)
 {
 	uint8_t op;
-	struct bcast_audio_scan_cp_cmd *cmd;
+	const struct bcast_audio_scan_cp_cmd *cmd;
 
 	if (!l2cap_frame_get_u8((void *)frame, &op)) {
 		print_text(COLOR_ERROR, "Opcode: invalid size");
@@ -3340,7 +3340,7 @@ static void bgr_features_read(const struct l2cap_frame *frame)
 	.notify = _notify \
 }
 
-struct gatt_handler {
+static const struct gatt_handler {
 	bt_uuid_t uuid;
 	void (*read)(const struct l2cap_frame *frame);
 	void (*write)(const struct l2cap_frame *frame);
@@ -3392,7 +3392,7 @@ struct gatt_handler {
 	GMAS
 };
 
-static struct gatt_handler *get_handler_uuid(const bt_uuid_t *uuid)
+static const struct gatt_handler *get_handler_uuid(const bt_uuid_t *uuid)
 {
 	size_t i;
 
@@ -3400,7 +3400,7 @@ static struct gatt_handler *get_handler_uuid(const bt_uuid_t *uuid)
 		return NULL;
 
 	for (i = 0; i < ARRAY_SIZE(gatt_handlers); i++) {
-		struct gatt_handler *handler = &gatt_handlers[i];
+		const struct gatt_handler *handler = &gatt_handlers[i];
 
 		if (!bt_uuid_cmp(&handler->uuid, uuid))
 			return handler;
@@ -3409,7 +3409,7 @@ static struct gatt_handler *get_handler_uuid(const bt_uuid_t *uuid)
 	return NULL;
 }
 
-static struct gatt_handler *get_handler(struct gatt_db_attribute *attr)
+static const struct gatt_handler *get_handler(struct gatt_db_attribute *attr)
 {
 	return get_handler_uuid(gatt_db_attribute_get_type(attr));
 }
@@ -3580,7 +3580,7 @@ static void queue_read(const struct l2cap_frame *frame, bt_uuid_t *uuid,
 	struct att_conn_data *data;
 	struct att_read *read;
 	struct gatt_db_attribute *attr = NULL;
-	struct gatt_handler *handler;
+	const struct gatt_handler *handler;
 
 	if (handle) {
 		attr = get_attribute(frame, handle, false);
@@ -3761,7 +3761,7 @@ static void print_write(const struct l2cap_frame *frame, uint16_t handle,
 							size_t len)
 {
 	struct gatt_db_attribute *attr;
-	struct gatt_handler *handler;
+	const struct gatt_handler *handler;
 
 	print_handle(frame, handle, false);
 
@@ -3837,7 +3837,7 @@ static void print_notify(const struct l2cap_frame *frame, uint16_t handle,
 								size_t len)
 {
 	struct gatt_db_attribute *attr;
-	struct gatt_handler *handler;
+	const struct gatt_handler *handler;
 	struct l2cap_frame clone;
 
 	print_handle(frame, handle, true);

-- 
2.43.0

