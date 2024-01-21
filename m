From: Yang Xiwen <forbidden405@outlook.com>
Date: Mon, 22 Jan 2024 05:02:07 +0800
Subject: [PATCH v2 4/4] net: hifemac: implement `net stats` needed ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240122-net-v2-4-78a368896f62@outlook.com>
References: <20240122-net-v2-0-78a368896f62@outlook.com>
In-Reply-To: <20240122-net-v2-0-78a368896f62@outlook.com>
To: Joe Hershberger <joe.hershberger@ni.com>, 
 Ramon Fried <rfried.dev@gmail.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705870930; l=4411;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=PWSJQpQzzsBqIpI4NTZc2hndLbZlKCxXE42lOYMvhRk=;
 b=9ZU94XWeu/OfoIAS9JftzYbZKEfpuAbY9alI8b0MamDDf+lcfMnAJJzNXxBuhUvxknCnzG5dc
 uFEtQ+ms29gCe97DEvWmq6X8xgsdIWdyjqX8Rq3ZrZmd7nHsqkTT0ID
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

3 operations needed by `net stats` are implemented. New `net stats`
output some useful info.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/net/hifemac.c | 87 +++++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 87 insertions(+)

diff --git a/drivers/net/hifemac.c b/drivers/net/hifemac.c
index 39c0233b62..24108bee4b 100644
--- a/drivers/net/hifemac.c
+++ b/drivers/net/hifemac.c
@@ -16,6 +16,8 @@
 #include <asm/io.h>
 #include <dm/device_compat.h>
 #include <dm/lists.h>
+#include <linux/bitfield.h>
+#include <linux/ethtool.h>
 #include <linux/delay.h>
 #include <linux/kernel.h>
 
@@ -125,6 +127,57 @@ struct hisi_femac_priv {
 	u32 link_status;
 };
 
+struct hisi_femac_stat_entry {
+	const char *name;
+	u32 offset;
+	u32 mask;
+};
+
+/* please refer to the datasheet for the description of these entries */
+const struct hisi_femac_stat_entry hisi_femac_stats_table[] = {
+	{ "rxsof_cnt",		0x584,	GENMASK(31, 28) },
+	{ "rxeof_cnt",		0x584,	GENMASK(27, 24) },
+	{ "rxcrcok_cnt",	0x584,	GENMASK(23, 20) },
+	{ "rxcrcbad_cnt",	0x584,	GENMASK(19, 16) },
+	{ "txsof_cnt",		0x584,	GENMASK(15, 12) },
+	{ "txeof_cnt",		0x584,	GENMASK(11, 8) },
+	{ "txcrcok_cnt",	0x584,	GENMASK(7, 4) },
+	{ "txcrcbad_cnt",	0x584,	GENMASK(3, 0) },
+	{ "pkts_cpu",		0x5a0,	GENMASK(15, 0) },
+	{ "addr_cpu",		0x5a4,	GENMASK(15, 0) },
+	{ "pkts_port",		0x5a8,	GENMASK(15, 0) },
+	{ "pkts_cpu2tx",	0x5ac,	GENMASK(15, 0) },
+	{ "rxdvrise",		0x600,	GENMASK(31, 0) },
+	{ "ifinoctets",		0x604,	GENMASK(31, 0) },
+	{ "octets_rx",		0x608,	GENMASK(31, 0) },
+	{ "local_mac_match",	0x60c,	GENMASK(31, 0) },
+	{ "pkts",		0x610,	GENMASK(31, 0) },
+	{ "broadcastpkts",	0x614,	GENMASK(31, 0) },
+	{ "multicastpkts",	0x618,	GENMASK(31, 0) },
+	{ "ifinucastpkts",	0x61c,	GENMASK(31, 0) },
+	{ "ifinerrors",		0x620,	GENMASK(31, 0) },
+	{ "crcerr",		0x624,	GENMASK(31, 0) },
+	{ "abnormalsizepkts",	0x628,	GENMASK(31, 0) },
+	{ "dot3alignmenterr",	0x62c,	GENMASK(31, 0) },
+	{ "dot3pause",		0x630,	GENMASK(31, 0) },
+	{ "dropevents",		0x634,	GENMASK(31, 0) },
+	{ "flux_frame_cnt",	0x638,	GENMASK(31, 0) },
+	{ "flux_drop_cnt",	0x63c,	GENMASK(31, 0) },
+	{ "mac_not2cpu_pkts",	0x64c,	GENMASK(31, 0) },
+	{ "pkts_tx",		0x780,	GENMASK(31, 0) },
+	{ "broadcastpkts_tx",	0x784,	GENMASK(31, 0) },
+	{ "multicastpkts_tx",	0x788,	GENMASK(31, 0) },
+	{ "ifoutucastpkts_tx",	0x78c,	GENMASK(31, 0) },
+	{ "octets_tx",		0x790,	GENMASK(31, 0) },
+	{ "dot3pause",		0x794,	GENMASK(31, 0) },
+	{ "retry_times_tx",	0x798,	GENMASK(31, 0) },
+	{ "collisions",		0x79c,	GENMASK(31, 0) },
+	{ "dot3latecol",	0x7a0,	GENMASK(31, 0) },
+	{ "dot3colok",		0x7a4,	GENMASK(31, 0) },
+	{ "dot3excessivecol",	0x7a8,	GENMASK(31, 0) },
+	{ "dot3colcnt",		0x7ac,	GENMASK(31, 0) },
+};
+
 static void hisi_femac_irq_enable(struct hisi_femac_priv *priv, int irqs)
 {
 	u32 val;
@@ -334,6 +387,37 @@ static void hisi_femac_stop(struct udevice *dev)
 	writel(SOFT_RESET_ALL, priv->glb_base + GLB_SOFT_RESET);
 }
 
+static int hisi_femac_get_sset_count(struct udevice *dev)
+{
+	return ARRAY_SIZE(hisi_femac_stats_table);
+}
+
+static void hisi_femac_get_strings(struct udevice *dev, u8 *data)
+{
+	int i;
+
+	for (i = 0; i < ARRAY_SIZE(hisi_femac_stats_table); i++)
+		strcpy(data + i * ETH_GSTRING_LEN, hisi_femac_stats_table[i].name);
+}
+
+/* Non-constant mask variant of FIELD_GET/FIELD_PREP */
+#define field_get(_mask, _reg) (((_reg) & (_mask)) >> (ffs(_mask) - 1))
+
+static void hisi_femac_get_stats(struct udevice *dev, u64 *data)
+{
+	int i;
+	u32 mask, reg;
+	struct hisi_femac_priv *priv = dev_get_priv(dev);
+	void __iomem *port_base = priv->port_base;
+
+	for (i = 0; i < ARRAY_SIZE(hisi_femac_stats_table); i++) {
+		mask = hisi_femac_stats_table[i].mask;
+		reg = readl(port_base + hisi_femac_stats_table[i].offset);
+
+		data[i] = field_get(mask, reg);
+	}
+}
+
 int hisi_femac_of_to_plat(struct udevice *dev)
 {
 	int ret, i;
@@ -523,6 +607,9 @@ static const struct eth_ops hisi_femac_ops = {
 	.free_pkt	= hisi_femac_free_pkt,
 	.stop		= hisi_femac_stop,
 	.write_hwaddr	= hisi_femac_set_hw_mac_addr,
+	.get_sset_count	= hisi_femac_get_sset_count,
+	.get_strings	= hisi_femac_get_strings,
+	.get_stats	= hisi_femac_get_stats,
 };
 
 static const struct udevice_id hisi_femac_ids[] = {

-- 
2.43.0

