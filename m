From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Tue, 16 Jan 2024 14:00:32 +0000
Subject: [PATCH BlueZ 07/20] profiles: annotate immutable data as const
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240116-const-v1-7-17c87978f40b@gmail.com>
References: <20240116-const-v1-0-17c87978f40b@gmail.com>
In-Reply-To: <20240116-const-v1-0-17c87978f40b@gmail.com>
To: linux-bluetooth@vger.kernel.org
Cc: Emil Velikov <emil.velikov@collabora.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705413636; l=8753;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=g6wwF3j8HEcST+PrUgGInINZna2D5QT+NY4sabsh4b4=;
 b=7YGywLiv4ShsvjHgFg4rhMRUlQLvUNf8W6lcdDhyUURWdq2JTenya+Ow4zsx7454vDPr7UsQP
 b0u+sd0uIFjALbY+m0NKNcNpVpdnSnvgPWC7UKbXBnmLnIDDy4Zuol8
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Emil Velikov <emil.velikov@collabora.com>

---
 profiles/audio/avctp.c     |  2 +-
 profiles/audio/avrcp.c     |  8 ++++----
 profiles/audio/media.c     |  6 +++---
 profiles/audio/sink.c      |  2 +-
 profiles/audio/source.c    |  2 +-
 profiles/audio/transport.c | 12 ++++++------
 profiles/health/hdp_util.c | 15 +++++++--------
 profiles/iap/main.c        |  2 +-
 8 files changed, 24 insertions(+), 25 deletions(-)

diff --git a/profiles/audio/avctp.c b/profiles/audio/avctp.c
index 6f64f162b..8ad146df1 100644
--- a/profiles/audio/avctp.c
+++ b/profiles/audio/avctp.c
@@ -228,7 +228,7 @@ struct avctp_browsing_pdu_handler {
 	GDestroyNotify destroy;
 };
 
-static struct {
+static const struct {
 	const char *name;
 	uint8_t avc;
 	uint16_t uinput;
diff --git a/profiles/audio/avrcp.c b/profiles/audio/avrcp.c
index dda9a303f..439fa27a9 100644
--- a/profiles/audio/avrcp.c
+++ b/profiles/audio/avrcp.c
@@ -290,7 +290,7 @@ struct control_pdu_handler {
 							uint8_t transaction);
 };
 
-static struct {
+static const struct {
 	uint8_t feature_bit;
 	uint8_t avc;
 } passthrough_map[] = {
@@ -361,7 +361,7 @@ static unsigned int avctp_id = 0;
 static uint8_t default_features[16];
 
 /* Company IDs supported by this device */
-static uint32_t company_ids[] = {
+static const uint32_t company_ids[] = {
 	IEEEID_BTSIG,
 };
 
@@ -2118,7 +2118,7 @@ failed:
 	pdu->param_len = cpu_to_be16(1);
 }
 
-static struct browsing_pdu_handler {
+static const struct browsing_pdu_handler {
 	uint8_t pdu_id;
 	void (*func) (struct avrcp *session, struct avrcp_browsing_header *pdu,
 							uint8_t transaction);
@@ -2147,7 +2147,7 @@ static size_t handle_browsing_pdu(struct avctp *conn,
 					size_t operand_count, void *user_data)
 {
 	struct avrcp *session = user_data;
-	struct browsing_pdu_handler *handler;
+	const struct browsing_pdu_handler *handler;
 	struct avrcp_browsing_header *pdu = (void *) operands;
 
 	DBG("AVRCP Browsing PDU 0x%02X, len 0x%04X", pdu->pdu_id,
diff --git a/profiles/audio/media.c b/profiles/audio/media.c
index 1faa1c289..edaff7867 100644
--- a/profiles/audio/media.c
+++ b/profiles/audio/media.c
@@ -1420,7 +1420,7 @@ static bool experimental_bcast_sink_ep_supported(struct btd_adapter *adapter)
 	return g_dbus_get_flags() & G_DBUS_FLAG_ENABLE_EXPERIMENTAL;
 }
 
-static struct media_endpoint_init {
+static const struct media_endpoint_init {
 	const char *uuid;
 	bool (*func)(struct media_endpoint *endpoint, int *err);
 	bool (*supported)(struct btd_adapter *adapter);
@@ -1456,7 +1456,7 @@ media_endpoint_create(struct media_adapter *adapter,
 						int *err)
 {
 	struct media_endpoint *endpoint;
-	struct media_endpoint_init *init;
+	const struct media_endpoint_init *init;
 	size_t i;
 	bool succeeded = false;
 
@@ -3244,7 +3244,7 @@ static gboolean supported_uuids(const GDBusPropertyTable *property,
 				DBUS_TYPE_STRING_AS_STRING, &entry);
 
 	for (i = 0; i < ARRAY_SIZE(init_table); i++) {
-		struct media_endpoint_init *init = &init_table[i];
+		const struct media_endpoint_init *init = &init_table[i];
 
 		if (init->supported(adapter->btd_adapter))
 			dbus_message_iter_append_basic(&entry, DBUS_TYPE_STRING,
diff --git a/profiles/audio/sink.c b/profiles/audio/sink.c
index 56c491778..a547dcb41 100644
--- a/profiles/audio/sink.c
+++ b/profiles/audio/sink.c
@@ -62,7 +62,7 @@ struct sink_state_callback {
 
 static GSList *sink_callbacks = NULL;
 
-static char *str_state[] = {
+static const char *str_state[] = {
 	"SINK_STATE_DISCONNECTED",
 	"SINK_STATE_CONNECTING",
 	"SINK_STATE_CONNECTED",
diff --git a/profiles/audio/source.c b/profiles/audio/source.c
index c6009d0ea..9fac352c8 100644
--- a/profiles/audio/source.c
+++ b/profiles/audio/source.c
@@ -61,7 +61,7 @@ struct source_state_callback {
 
 static GSList *source_callbacks = NULL;
 
-static char *str_state[] = {
+static const char *str_state[] = {
 	"SOURCE_STATE_DISCONNECTED",
 	"SOURCE_STATE_CONNECTING",
 	"SOURCE_STATE_CONNECTED",
diff --git a/profiles/audio/transport.c b/profiles/audio/transport.c
index a4696154a..dd7d0e0a2 100644
--- a/profiles/audio/transport.c
+++ b/profiles/audio/transport.c
@@ -55,7 +55,7 @@ typedef enum {
 	TRANSPORT_STATE_SUSPENDING,     /* Release in progress */
 } transport_state_t;
 
-static char *str_state[] = {
+static const char *str_state[] = {
 	"TRANSPORT_STATE_IDLE",
 	"TRANSPORT_STATE_PENDING",
 	"TRANSPORT_STATE_REQUESTING",
@@ -124,7 +124,7 @@ struct media_transport {
 	uint16_t		imtu;		/* Transport input mtu */
 	uint16_t		omtu;		/* Transport output mtu */
 	transport_state_t	state;
-	struct media_transport_ops *ops;
+	const struct media_transport_ops *ops;
 	void			*data;
 };
 
@@ -1749,7 +1749,7 @@ static void *transport_bap_init(struct media_transport *transport, void *stream)
 #define BAP_BC_OPS(_uuid) \
 	BAP_OPS(_uuid, transport_bap_bc_properties, NULL, NULL)
 
-static struct media_transport_ops transport_ops[] = {
+static const struct media_transport_ops transport_ops[] = {
 	A2DP_OPS(A2DP_SOURCE_UUID, transport_a2dp_src_init,
 			transport_a2dp_src_set_volume,
 			transport_a2dp_src_destroy),
@@ -1762,12 +1762,12 @@ static struct media_transport_ops transport_ops[] = {
 	BAP_BC_OPS(BAA_SERVICE_UUID),
 };
 
-static struct media_transport_ops *media_transport_find_ops(const char *uuid)
+static const struct media_transport_ops *media_transport_find_ops(const char *uuid)
 {
 	size_t i;
 
 	for (i = 0; i < ARRAY_SIZE(transport_ops); i++) {
-		struct media_transport_ops *ops = &transport_ops[i];
+		const struct media_transport_ops *ops = &transport_ops[i];
 
 		if (!strcasecmp(uuid, ops->uuid))
 			return ops;
@@ -1784,7 +1784,7 @@ struct media_transport *media_transport_create(struct btd_device *device,
 {
 	struct media_endpoint *endpoint = data;
 	struct media_transport *transport;
-	struct media_transport_ops *ops;
+	const struct media_transport_ops *ops;
 	static int fd = 0;
 
 	transport = g_new0(struct media_transport, 1);
diff --git a/profiles/health/hdp_util.c b/profiles/health/hdp_util.c
index ab3b78f6a..ad3702f01 100644
--- a/profiles/health/hdp_util.c
+++ b/profiles/health/hdp_util.c
@@ -42,7 +42,7 @@ typedef gboolean (*parse_item_f)(DBusMessageIter *iter, gpointer user_data,
 								GError **err);
 
 struct dict_entry_func {
-	char		*key;
+	const char	*key;
 	parse_item_f	func;
 };
 
@@ -67,7 +67,7 @@ struct get_dcpsm_data {
 	GDestroyNotify		destroy;
 };
 
-static gboolean parse_dict_entry(struct dict_entry_func dict_context[],
+static gboolean parse_dict_entry(const struct dict_entry_func dict_context[],
 							DBusMessageIter *iter,
 							GError **err,
 							gpointer user_data)
@@ -75,7 +75,6 @@ static gboolean parse_dict_entry(struct dict_entry_func dict_context[],
 	DBusMessageIter entry;
 	char *key;
 	int ctype, i;
-	struct dict_entry_func df;
 
 	dbus_message_iter_recurse(iter, &entry);
 	ctype = dbus_message_iter_get_arg_type(&entry);
@@ -88,9 +87,9 @@ static gboolean parse_dict_entry(struct dict_entry_func dict_context[],
 	dbus_message_iter_get_basic(&entry, &key);
 	dbus_message_iter_next(&entry);
 	/* Find function and call it */
-	for (i = 0, df = dict_context[0]; df.key; i++, df = dict_context[i]) {
-		if (g_ascii_strcasecmp(df.key, key) == 0)
-			return df.func(&entry, user_data, err);
+	for (i = 0; dict_context[i].key; i++) {
+		if (g_ascii_strcasecmp(dict_context[i].key, key) == 0)
+			return dict_context[i].func(&entry, user_data, err);
 	}
 
 	g_set_error(err, HDP_ERROR, HDP_DIC_ENTRY_PARSE_ERROR,
@@ -98,7 +97,7 @@ static gboolean parse_dict_entry(struct dict_entry_func dict_context[],
 	return FALSE;
 }
 
-static gboolean parse_dict(struct dict_entry_func dict_context[],
+static gboolean parse_dict(const struct dict_entry_func dict_context[],
 							DBusMessageIter *iter,
 							GError **err,
 							gpointer user_data)
@@ -273,7 +272,7 @@ static gboolean parse_chan_type(DBusMessageIter *iter, gpointer data,
 	return TRUE;
 }
 
-static struct dict_entry_func dict_parser[] = {
+static const struct dict_entry_func dict_parser[] = {
 	{"DataType",		parse_data_type},
 	{"Role",		parse_role},
 	{"Description",		parse_desc},
diff --git a/profiles/iap/main.c b/profiles/iap/main.c
index 9a04f5cc0..054ff600e 100644
--- a/profiles/iap/main.c
+++ b/profiles/iap/main.c
@@ -398,7 +398,7 @@ static guint setup_signalfd(void)
 
 static gboolean option_version = FALSE;
 
-static GOptionEntry options[] = {
+static const GOptionEntry options[] = {
 	{ "version", 'v', 0, G_OPTION_ARG_NONE, &option_version,
 				"Show version information and exit" },
 	{ NULL },

-- 
2.43.0

