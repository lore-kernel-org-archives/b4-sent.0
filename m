From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 23:50:30 +0300
Subject: [PATCH RFC net-next 2/7] net: dsa: add a QCA four-byte CPU tagger
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-almondplus-offload-rfc-v1-2-703175c6340c@gmail.com>
References: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
In-Reply-To: <20261125-almondplus-offload-rfc-v1-0-703175c6340c@gmail.com>
To: Andrew Lunn <andrew@lunn.ch>, Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Simon Horman <horms@kernel.org>, Pablo Neira Ayuso <pablo@netfilter.org>, 
 Florian Westphal <fw@strlen.de>, Phil Sutter <phil@nwl.cc>, 
 Hans Ulli Kroll <ulli.kroll@googlemail.com>, 
 Linus Walleij <linusw@kernel.org>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Russell King <linux@armlinux.org.uk>, 
 Christian Marangi <ansuelsmth@gmail.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, netfilter-devel@vger.kernel.org, 
 coreteam@netfilter.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, Fil Dunsky <filipp.dunsky@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=28282;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=3Kun9cJTdqUY3onf9waOp+3LOppqDQ9OpaQL0Li2Yxc=;
 b=e0DNu40C2Lo12rfQmiJJIKOV01NdPOEvgNcIWjsAy3vA9moPhrxn7m1WDCAw87HTc4ts8Aumu
 QgzaAFgh9qtAqXzAokMwS8/biaIv4wCjghl8w+hTYxI/uOCCs4P2tuc
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Insert the 0x8100 identifier and the ordinary QCA metadata ahead of the
inner EtherType. Preserve checksum/header offsets, materialize VLAN
metadata inside the CPU tag and validate nonlinear receive headers
before dispatch.

Keep the two-byte format as the default. Add KUnit coverage for tagging,
VLAN and checksum metadata, source-port dispatch, clones and
truncated/nonlinear packets. Seven tests passed under UML.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 include/net/dsa.h        |  21 +--
 net/dsa/Kconfig          |  30 +++
 net/dsa/Makefile         |   2 +
 net/dsa/tag_qca4.c       | 165 +++++++++++++++++
 net/dsa/tag_qca4_kunit.h | 469 +++++++++++++++++++++++++++++++++++++++++++++++
 5 files changed, 671 insertions(+), 16 deletions(-)

diff --git a/include/net/dsa.h b/include/net/dsa.h
index 5d12191b6..7d3c836c2 100644
--- a/include/net/dsa.h
+++ b/include/net/dsa.h
@@ -36,6 +36,7 @@ struct tc_action;
 #define DSA_TAG_PROTO_LAN9303_VALUE		8
 #define DSA_TAG_PROTO_MTK_VALUE			9
 #define DSA_TAG_PROTO_QCA_VALUE			10
+#define DSA_TAG_PROTO_QCA4_VALUE 37
 #define DSA_TAG_PROTO_TRAILER_VALUE		11
 #define DSA_TAG_PROTO_8021Q_VALUE		12
 #define DSA_TAG_PROTO_SJA1105_VALUE		13
@@ -77,6 +78,7 @@ enum dsa_tag_protocol {
 	DSA_TAG_PROTO_LAN9303		= DSA_TAG_PROTO_LAN9303_VALUE,
 	DSA_TAG_PROTO_MTK		= DSA_TAG_PROTO_MTK_VALUE,
 	DSA_TAG_PROTO_QCA		= DSA_TAG_PROTO_QCA_VALUE,
+	DSA_TAG_PROTO_QCA4		= DSA_TAG_PROTO_QCA4_VALUE,
 	DSA_TAG_PROTO_TRAILER		= DSA_TAG_PROTO_TRAILER_VALUE,
 	DSA_TAG_PROTO_8021Q		= DSA_TAG_PROTO_8021Q_VALUE,
 	DSA_TAG_PROTO_SJA1105		= DSA_TAG_PROTO_SJA1105_VALUE,
@@ -183,15 +185,12 @@ struct dsa_switch_tree {
 #define dsa_lags_foreach_id(_id, _dst)				\
 	for ((_id) = 1; (_id) <= (_dst)->lags_len; (_id)++)	\
 		if ((_dst)->lags[(_id) - 1])
-
 #define dsa_lag_foreach_port(_dp, _dst, _lag)			\
 	list_for_each_entry((_dp), &(_dst)->ports, list)	\
 		if (dsa_port_offloads_lag((_dp), (_lag)))
-
 #define dsa_hsr_foreach_port(_dp, _ds, _hsr)			\
 	list_for_each_entry((_dp), &(_ds)->dst->ports, list)	\
 		if ((_dp)->ds == (_ds) && (_dp)->hsr_dev == (_hsr))
-
 static inline struct dsa_lag *dsa_lag_by_id(struct dsa_switch_tree *dst,
 					    unsigned int id)
 {
@@ -579,47 +578,36 @@ static inline bool dsa_is_user_port(struct dsa_switch *ds, int p)
 #define dsa_tree_for_each_user_port(_dp, _dst) \
 	list_for_each_entry((_dp), &(_dst)->ports, list) \
 		if (dsa_port_is_user((_dp)))
-
 #define dsa_tree_for_each_user_port_continue_reverse(_dp, _dst) \
 	list_for_each_entry_continue_reverse((_dp), &(_dst)->ports, list) \
 		if (dsa_port_is_user((_dp)))
-
 #define dsa_tree_for_each_cpu_port(_dp, _dst) \
 	list_for_each_entry((_dp), &(_dst)->ports, list) \
 		if (dsa_port_is_cpu((_dp)))
-
 #define dsa_switch_for_each_port(_dp, _ds) \
 	list_for_each_entry((_dp), &(_ds)->dst->ports, list) \
 		if ((_dp)->ds == (_ds))
-
 #define dsa_switch_for_each_port_safe(_dp, _next, _ds) \
 	list_for_each_entry_safe((_dp), (_next), &(_ds)->dst->ports, list) \
 		if ((_dp)->ds == (_ds))
-
 #define dsa_switch_for_each_port_continue_reverse(_dp, _ds) \
 	list_for_each_entry_continue_reverse((_dp), &(_ds)->dst->ports, list) \
 		if ((_dp)->ds == (_ds))
-
 #define dsa_switch_for_each_available_port(_dp, _ds) \
 	dsa_switch_for_each_port((_dp), (_ds)) \
 		if (!dsa_port_is_unused((_dp)))
-
 #define dsa_switch_for_each_user_port(_dp, _ds) \
 	dsa_switch_for_each_port((_dp), (_ds)) \
 		if (dsa_port_is_user((_dp)))
-
 #define dsa_switch_for_each_user_port_continue_reverse(_dp, _ds) \
 	dsa_switch_for_each_port_continue_reverse((_dp), (_ds)) \
 		if (dsa_port_is_user((_dp)))
-
 #define dsa_switch_for_each_cpu_port(_dp, _ds) \
 	dsa_switch_for_each_port((_dp), (_ds)) \
 		if (dsa_port_is_cpu((_dp)))
-
 #define dsa_switch_for_each_cpu_port_continue_reverse(_dp, _ds) \
 	dsa_switch_for_each_port_continue_reverse((_dp), (_ds)) \
 		if (dsa_port_is_cpu((_dp)))
-
 static inline u32 dsa_user_ports(struct dsa_switch *ds)
 {
 	struct dsa_port *dp;
@@ -842,7 +830,6 @@ dsa_tree_offloads_bridge_dev(struct dsa_switch_tree *dst,
 #define dsa_switch_for_each_bridge_member(_dp, _ds, _bdev) \
 	dsa_switch_for_each_user_port(_dp, _ds) \
 		if (dsa_port_offloads_bridge_dev(_dp, _bdev))
-
 static inline u32
 dsa_bridge_ports(struct dsa_switch *ds, const struct net_device *bdev)
 {
@@ -996,7 +983,6 @@ struct dsa_switch_ops {
 			       struct phy_device *phy);
 	void	(*port_disable)(struct dsa_switch *ds, int port);
 
-
 	/*
 	 * Notification for MAC address changes on user ports. Drivers can
 	 * currently only veto operations. They should not use the method to
@@ -1401,10 +1387,12 @@ static inline int dsa_switch_suspend(struct dsa_switch *ds)
 {
 	return 0;
 }
+
 static inline int dsa_switch_resume(struct dsa_switch *ds)
 {
 	return 0;
 }
+
 #endif /* CONFIG_PM_SLEEP */
 
 #if IS_ENABLED(CONFIG_NET_DSA)
@@ -1414,6 +1402,7 @@ static inline bool dsa_user_dev_check(const struct net_device *dev)
 {
 	return false;
 }
+
 #endif
 
 netdev_tx_t dsa_enqueue_skb(struct sk_buff *skb, struct net_device *dev);
diff --git a/net/dsa/Kconfig b/net/dsa/Kconfig
index 4f44bf3ed..99933b270 100644
--- a/net/dsa/Kconfig
+++ b/net/dsa/Kconfig
@@ -174,6 +174,36 @@ config NET_DSA_TAG_QCA
 	  Say Y or M if you want to enable support for tagging frames for
 	  the Qualcomm Atheros QCA8K switches.
 
+config NET_DSA_TAG_QCA4
+	tristate "Tag driver for QCA four-byte tags"
+	default n
+	help
+	  QCA switch CPU framing with identifier 0x8100 and two-byte metadata.
+	  Does not enable hardware checksum, GSO, VLAN or NAT offload features.
+	  The ordinary QCA two-byte tagger remains the default.
+	  Select qca4 on the CPU ports only when the switch driver supports it.
+
+config NET_DSA_TAG_QCA4_KUNIT_TEST
+	bool "KUnit tests for QCA four-byte sk_buff operations"
+	depends on KUNIT=y && NET_DSA_TAG_QCA4=y
+	default n
+	help
+	  Exercise real sk_buff allocation, copy-on-write, nonlinear headers,
+	  checksum metadata and source-port dispatch for the four-byte tagger.
+	  These are software tests and do not require a physical QCA switch.
+	  They can run with the standard KUnit test framework.
+
+config NET_DSA_QCA8K_4B_MODE
+	bool "QCA8K four-byte boot format for CS7542 offload"
+	depends on NET_DSA_QCA8K=y && NET_DSA_TAG_QCA4=y
+	depends on !PM && CS7542_FT_LIVE_BRIDGE && MDIO_CS75XX=y
+	default n
+	help
+	  Support the four-byte CPU tag requested through dsa-tag-protocol.
+	  The current implementation supports the CS7542 dual-conduit topology.
+	  Ethernet register access uses MDIO while the four-byte format is active.
+	  Both CPU ports must request the same format before the switch starts.
+
 config NET_DSA_TAG_RTL4_A
 	tristate "Tag driver for Realtek 4 byte protocol A tags"
 	help
diff --git a/net/dsa/Makefile b/net/dsa/Makefile
index 1f9cc30e9..3d5949e50 100644
--- a/net/dsa/Makefile
+++ b/net/dsa/Makefile
@@ -48,3 +48,5 @@ obj-$(CONFIG_NET_DSA_TAG_YT921X) += tag_yt921x.o
 
 # for tracing framework to find trace.h
 CFLAGS_trace.o := -I$(src)
+
+obj-$(CONFIG_NET_DSA_TAG_QCA4) += tag_qca4.o
diff --git a/net/dsa/tag_qca4.c b/net/dsa/tag_qca4.c
new file mode 100644
index 000000000..413756679
--- /dev/null
+++ b/net/dsa/tag_qca4.c
@@ -0,0 +1,165 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Private source-review prototype. No offload feature advertisement. */
+#include <linux/bitfield.h>
+#include <linux/etherdevice.h>
+#include <linux/if_vlan.h>
+#include <linux/unaligned.h>
+#include <linux/dsa/tag_qca.h>
+#include <net/dsa.h>
+#include "tag.h"
+
+#define QCA4_PRIVATE_LEN 4
+#define QCA4_PRIVATE_IDENTIFIER 0x8100
+#define QCA4_PRIVATE_NAME "qca4"
+
+/*
+ * Offsets are absolute from skb head. Pushing the outer tag leaves the real
+ * L3/L4 and CHECKSUM_PARTIAL start at their original bytes; their offsets from
+ * skb->data grow by four. Standard core/conduit features own segmentation and
+ * software checksum fallback. GSO/checksum metadata is not rejected or changed.
+ */
+static int qca4_private_insert(struct sk_buff *skb, unsigned long ports)
+{
+	u16 hdr;
+	u8 *tag;
+
+	if (!ports || ports & ~FIELD_MAX(QCA_HDR_XMIT_DP_BIT))
+		return -EINVAL;
+	if (!pskb_may_pull(skb, ETH_HLEN))
+		return -EINVAL;
+	if (skb_cow_head(skb, QCA4_PRIVATE_LEN))
+		return -ENOMEM;
+	skb_push(skb, QCA4_PRIVATE_LEN);
+	dsa_alloc_etype_header(skb, QCA4_PRIVATE_LEN);
+	tag = dsa_etype_header_pos_tx(skb);
+	hdr = FIELD_PREP(QCA_HDR_XMIT_VERSION, QCA_HDR_VERSION) |
+	      QCA_HDR_XMIT_FROM_CPU | FIELD_PREP(QCA_HDR_XMIT_DP_BIT, ports);
+	/* Same metadata policy as legacy QCA: no new skb-priority mapping. */
+	put_unaligned_be16(QCA4_PRIVATE_IDENTIFIER, tag);
+	put_unaligned_be16(hdr, tag + 2);
+	skb_reset_mac_header(skb);
+	return 0;
+}
+
+static struct sk_buff *qca4_private_xmit(struct sk_buff *skb,
+					 struct net_device *dev)
+{
+	/*
+	 * A pending hardware VLAN tag must be inside QCA metadata, never inserted
+	 * outside it later by the conduit. This standard helper also handles COW and
+	 * header/checksum offsets. No HW VLAN feature is advertised by this tagger.
+	 */
+
+	if (skb_vlan_tag_present(skb)) {
+		skb = __vlan_hwaccel_push_inside(skb);
+		if (!skb)
+			return NULL; /* VLAN helper already freed the original. */
+	}
+	if (qca4_private_insert(skb, dsa_xmit_port_mask(skb, dev))) {
+		kfree_skb(skb);
+		return NULL;
+	}
+
+	return skb;
+}
+
+/*
+ * Conduit eth_type_trans pulled fourteen bytes: identifier is data[-2],
+ * metadata is data[0..1], and inner EtherType is data[2..3]. Do not read a
+ * possibly nonlinear metadata/inner EtherType before the full pull check.
+ */
+static int qca4_private_parse(struct sk_buff *skb, u16 *metadata)
+{
+	unsigned int reason;
+	u8 *tag;
+	u16 hdr;
+
+	if (skb_headroom(skb) < ETH_HLEN ||
+	    !pskb_may_pull(skb, QCA4_PRIVATE_LEN)) {
+		return -EINVAL;
+	}
+	if (skb_cow_head(skb, 0))
+		return -ENOMEM;
+	tag = dsa_etype_header_pos_rx(skb);
+	if (get_unaligned_be16(tag) != QCA4_PRIVATE_IDENTIFIER)
+		return -EPROTO;
+	hdr = get_unaligned_be16(tag + 2);
+	if (FIELD_GET(QCA_HDR_RECV_VERSION, hdr) != QCA_HDR_VERSION)
+		return -EPROTO;
+	reason = FIELD_GET(QCA_HDR_RECV_TYPE, hdr);
+	/*
+	 * These fixed14-byte pseudo-Ethernet formats are disabled in private4 mode.
+	 * Never dispatch them into legacy MDIO/MIB callbacks with the wrong layout.
+	 * Other normal/trap reasons remain valid, including observed flooding0x19.
+	 */
+	if (reason == QCA_HDR_RECV_TYPE_MIB ||
+	    reason == QCA_HDR_RECV_TYPE_RW_REG_ACK) {
+		return -EOPNOTSUPP;
+	}
+	*metadata = hdr;
+	return 0;
+}
+
+static struct sk_buff *qca4_private_rcv(struct sk_buff *skb,
+					struct net_device *conduit)
+{
+	struct net_device *user;
+	u16 metadata;
+	int port;
+
+	if (qca4_private_parse(skb, &metadata))
+		goto drop;
+	port = FIELD_GET(QCA_HDR_RECV_SOURCE_PORT, metadata);
+	user = dsa_conduit_find_user(conduit, 0, port);
+	if (!user)
+		goto drop;
+
+	skb->dev = user;
+	skb_pull_rcsum(skb, QCA4_PRIVATE_LEN);
+	dsa_strip_etype_header(skb, QCA4_PRIVATE_LEN);
+
+	/*
+	 * DSA core pushes ETH_HLEN and invokes user eth_type_trans, exposing only
+	 * the real inner EtherType/VLAN after the complete four-byte tag is gone.
+	 */
+	return skb;
+drop:
+	kfree_skb(skb);
+	return NULL;
+}
+
+/*
+ * Called before rcv(): do not assume the metadata or inner EtherType is
+ * linear or even present. Keep the const skb and its layout unchanged.
+ */
+static void qca4_private_flow_dissect(const struct sk_buff *skb, __be16 *proto,
+				      int *offset)
+{
+	__be16 temporary;
+	const void *inner;
+
+	*offset = QCA4_PRIVATE_LEN;
+	*proto = 0;
+	inner = skb_header_pointer(skb, 2, sizeof(temporary), &temporary);
+	if (inner)
+		*proto = get_unaligned((const __be16 *)inner);
+}
+
+static const struct dsa_device_ops qca4_private_ops = {
+	.name = QCA4_PRIVATE_NAME,
+	.proto = DSA_TAG_PROTO_QCA4,
+	.xmit = qca4_private_xmit,
+	.rcv = qca4_private_rcv,
+	.flow_dissect = qca4_private_flow_dissect,
+	.needed_headroom = QCA4_PRIVATE_LEN,
+	.promisc_on_conduit = true,
+};
+
+MODULE_DESCRIPTION("Private source-review QCA four-byte tag prototype");
+MODULE_LICENSE("GPL");
+MODULE_ALIAS_DSA_TAG_DRIVER(DSA_TAG_PROTO_QCA4, QCA4_PRIVATE_NAME);
+module_dsa_tag_driver(qca4_private_ops);
+
+#if IS_ENABLED(CONFIG_NET_DSA_TAG_QCA4_KUNIT_TEST)
+#include "tag_qca4_kunit.h"
+#endif
diff --git a/net/dsa/tag_qca4_kunit.h b/net/dsa/tag_qca4_kunit.h
new file mode 100644
index 000000000..cc520b7fb
--- /dev/null
+++ b/net/dsa/tag_qca4_kunit.h
@@ -0,0 +1,469 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/* Real kernel sk_buff tests; offline QEMU execution only. */
+#include <kunit/test.h>
+#include <linux/highmem.h>
+#include <linux/mm.h>
+#include <net/checksum.h>
+
+struct qca4_test_context {
+	struct dsa_switch ds;
+	struct dsa_switch_tree dst;
+	struct dsa_port cpu, user;
+	struct net_device *conduit, *netdev;
+};
+
+static int qca4_test_init(struct kunit *test)
+{
+	struct qca4_test_context *c =
+		kunit_kzalloc(test, sizeof(*c), GFP_KERNEL);
+	struct dsa_user_priv *p;
+
+	if (!c)
+		return -ENOMEM;
+	c->conduit = alloc_etherdev(0);
+	c->netdev = alloc_etherdev(sizeof(*p));
+	if (!c->conduit || !c->netdev) {
+		if (c->conduit)
+			free_netdev(c->conduit);
+		if (c->netdev)
+			free_netdev(c->netdev);
+		return -ENOMEM;
+	}
+	INIT_LIST_HEAD(&c->dst.ports);
+	c->ds.index = 0;
+	c->ds.dst = &c->dst;
+	c->cpu.ds = &c->ds;
+	c->cpu.dst = &c->dst;
+	c->cpu.type = DSA_PORT_TYPE_CPU;
+	c->cpu.index = 0;
+	c->cpu.conduit = c->conduit;
+	c->cpu.rcv = qca4_private_rcv;
+	c->cpu.tag_ops = &qca4_private_ops;
+	c->conduit->dsa_ptr = &c->cpu;
+	c->user.ds = &c->ds;
+	c->user.dst = &c->dst;
+	c->user.type = DSA_PORT_TYPE_USER;
+	c->user.index = 5;
+	c->user.user = c->netdev;
+	c->user.cpu_dp = &c->cpu;
+	list_add_tail(&c->cpu.list, &c->dst.ports);
+	list_add_tail(&c->user.list, &c->dst.ports);
+	p = netdev_priv(c->netdev);
+	p->dp = &c->user;
+	test->priv = c;
+	return 0;
+}
+
+static void qca4_test_exit(struct kunit *test)
+{
+	struct qca4_test_context *c = test->priv;
+
+	free_netdev(c->netdev);
+	free_netdev(c->conduit);
+}
+
+static struct sk_buff *qca4_test_frame(unsigned int headroom,
+				       unsigned int vlans)
+{
+	struct sk_buff *skb = alloc_skb(headroom + 128, GFP_KERNEL);
+	unsigned int len = 96 + 4 * vlans, network = ETH_HLEN + 4 * vlans;
+	u8 *data;
+
+	if (!skb)
+		return NULL;
+	skb_reserve(skb, headroom);
+	data = skb_put_zero(skb, len);
+	eth_broadcast_addr(data);
+	data[6] = 2;
+	data[11] = 1;
+	put_unaligned_be16(vlans == 2 ? ETH_P_8021AD :
+			   vlans == 1 ? ETH_P_8021Q :
+					ETH_P_IP,
+			   data + 12);
+	if (vlans) {
+		put_unaligned_be16(0xa123, data + 14);
+		put_unaligned_be16(vlans == 2 ? ETH_P_8021Q : ETH_P_IP,
+				   data + 16);
+	}
+	if (vlans == 2) {
+		put_unaligned_be16(0x6000, data + 18); /* Priority tag, VID0. */
+		put_unaligned_be16(ETH_P_IP, data + 20);
+	}
+	data[network] = 0x45;
+	data[network + 9] = IPPROTO_TCP;
+	skb_reset_mac_header(skb);
+	skb_set_network_header(skb, network);
+	skb_set_transport_header(skb, network + 20);
+	skb->protocol = htons(vlans == 2 ? ETH_P_8021AD :
+			      vlans == 1 ? ETH_P_8021Q :
+					   ETH_P_IP);
+	return skb;
+}
+
+static void qca4_test_tx_metadata(struct kunit *test)
+{
+	struct qca4_test_context *c = test->priv;
+	unsigned int vlans, n;
+	static const unsigned int reserves[] = { 0, 2, 16, 32 };
+
+	for (vlans = 0; vlans <= 2; vlans++) {
+		for (n = 0; n < ARRAY_SIZE(reserves); n++) {
+			struct sk_buff *skb = qca4_test_frame(reserves[n],
+							      vlans),
+				       *original;
+			unsigned int net, trans, start, len;
+			u8 bytes[128];
+
+			KUNIT_ASSERT_NOT_NULL(test, skb);
+			skb->ip_summed = CHECKSUM_PARTIAL;
+			skb->csum_start = skb_transport_header(skb) - skb->head;
+			skb->csum_offset = 16;
+			skb->priority = 7;
+			skb_shinfo(skb)->gso_size = 1460;
+			skb_shinfo(skb)->gso_type = SKB_GSO_TCPV4;
+			net = skb_network_offset(skb);
+			trans = skb_transport_offset(skb);
+			start = skb_checksum_start_offset(skb);
+			len = skb->len;
+			memcpy(bytes, skb->data, len);
+			original = skb_clone(skb, GFP_KERNEL);
+			KUNIT_ASSERT_NOT_NULL(test, original);
+			skb = qca4_private_xmit(skb, c->netdev);
+			KUNIT_ASSERT_NOT_NULL(test, skb);
+			KUNIT_EXPECT_EQ(test, skb->len, len + 4);
+			KUNIT_EXPECT_EQ(test, skb_network_offset(skb), net + 4);
+			KUNIT_EXPECT_EQ(test, skb_transport_offset(skb),
+					trans + 4);
+			KUNIT_EXPECT_EQ(test, skb_checksum_start_offset(skb),
+					start + 4);
+			KUNIT_EXPECT_EQ(test, skb->csum_offset, (u16)16);
+			KUNIT_EXPECT_EQ(test, (unsigned int)skb->ip_summed,
+					(unsigned int)CHECKSUM_PARTIAL);
+			KUNIT_EXPECT_EQ(test, skb->priority, 7U);
+			KUNIT_EXPECT_EQ(test, skb_shinfo(skb)->gso_size,
+					(u16)1460);
+			KUNIT_EXPECT_EQ(test, skb_shinfo(skb)->gso_type,
+					SKB_GSO_TCPV4);
+			KUNIT_EXPECT_PTR_EQ(test, skb_mac_header(skb),
+					    skb->data);
+			KUNIT_EXPECT_MEMEQ(test, skb->data, bytes, 12);
+			KUNIT_EXPECT_MEMEQ(test, skb->data + 16, bytes + 12,
+					   len - 12);
+			KUNIT_EXPECT_MEMEQ(test, original->data, bytes, len);
+			KUNIT_EXPECT_EQ(test,
+					get_unaligned_be16(skb->data + 12),
+					0x8100);
+			KUNIT_EXPECT_EQ(test,
+					get_unaligned_be16(skb->data + 14),
+					0x80a0);
+			kfree_skb(original);
+			kfree_skb(skb);
+		}
+	}
+}
+
+static void qca4_test_vlan_metadata(struct kunit *test)
+{
+	struct qca4_test_context *c = test->priv;
+	struct sk_buff *skb = qca4_test_frame(0, 0);
+	unsigned int net, trans, start;
+
+	KUNIT_ASSERT_NOT_NULL(test, skb);
+	skb->ip_summed = CHECKSUM_PARTIAL;
+	skb->csum_start = skb_transport_header(skb) - skb->head;
+	skb->csum_offset = 16;
+	skb_shinfo(skb)->gso_size = 1460;
+	skb_shinfo(skb)->gso_type = SKB_GSO_TCPV4;
+	net = skb_network_offset(skb);
+	trans = skb_transport_offset(skb);
+	start = skb_checksum_start_offset(skb);
+	__vlan_hwaccel_put_tag(skb, htons(ETH_P_8021Q),
+			       0xe000); /* PCP7, VID0 */
+	skb = qca4_private_xmit(skb, c->netdev);
+	KUNIT_ASSERT_NOT_NULL(test, skb);
+	KUNIT_EXPECT_FALSE(test, skb_vlan_tag_present(skb));
+	KUNIT_EXPECT_EQ(test, skb_network_offset(skb), net + 8);
+	KUNIT_EXPECT_EQ(test, skb_transport_offset(skb), trans + 8);
+	KUNIT_EXPECT_EQ(test, skb_checksum_start_offset(skb), start + 8);
+	KUNIT_EXPECT_EQ(test, (unsigned int)skb->ip_summed,
+			(unsigned int)CHECKSUM_PARTIAL);
+	KUNIT_EXPECT_EQ(test, skb->csum_offset, (u16)16);
+	KUNIT_EXPECT_EQ(test, skb_shinfo(skb)->gso_size, (u16)1460);
+	KUNIT_EXPECT_EQ(test, skb_shinfo(skb)->gso_type, SKB_GSO_TCPV4);
+	KUNIT_EXPECT_EQ(test, get_unaligned_be16(skb->data + 12), 0x8100);
+	KUNIT_EXPECT_EQ(test, get_unaligned_be16(skb->data + 14), 0x80a0);
+	KUNIT_EXPECT_EQ(test, get_unaligned_be16(skb->data + 16), ETH_P_8021Q);
+	KUNIT_EXPECT_EQ(test, get_unaligned_be16(skb->data + 18), 0xe000);
+	KUNIT_EXPECT_EQ(test, get_unaligned_be16(skb->data + 20), ETH_P_IP);
+	kfree_skb(skb);
+}
+
+static struct sk_buff *qca4_test_fragment(struct sk_buff *old,
+					  unsigned int linear)
+{
+	struct sk_buff *skb = alloc_skb(32 + linear, GFP_KERNEL);
+	struct page *page;
+	void *mapped;
+	unsigned int bytes = old->len - linear;
+
+	if (!skb)
+		return NULL;
+	page = alloc_page(GFP_KERNEL);
+	if (!page) {
+		kfree_skb(skb);
+		return NULL;
+	}
+	skb_reserve(skb, 16);
+	skb_put_data(skb, old->data, linear);
+	mapped = kmap_local_page(page);
+	memcpy(mapped, old->data + linear, bytes);
+	kunmap_local(mapped);
+	skb_add_rx_frag(skb, 0, page, 0, bytes, PAGE_SIZE);
+	skb_reset_mac_header(skb);
+	return skb;
+}
+
+static void qca4_test_rx_dispatch(struct kunit *test)
+{
+	struct qca4_test_context *c = test->priv;
+	unsigned int vlans, reason, priority, port;
+
+	for (vlans = 0; vlans <= 2; vlans++) {
+		for (reason = 0; reason < 32; reason++) {
+			for (priority = 0; priority < 8; priority++) {
+				for (port = 0; port < 8; port++) {
+					struct sk_buff *skb = qca4_test_frame(16, vlans),
+						       *result;
+					u16 hdr =
+						FIELD_PREP(QCA_HDR_RECV_VERSION,
+							   QCA_HDR_VERSION) |
+						FIELD_PREP(QCA_HDR_RECV_PRIORITY,
+							priority) |
+						FIELD_PREP(QCA_HDR_RECV_TYPE,
+							   reason) |
+						port;
+					bool accept =
+						port == 5 &&
+						reason !=
+							QCA_HDR_RECV_TYPE_MIB &&
+						reason !=
+							QCA_HDR_RECV_TYPE_RW_REG_ACK;
+
+					KUNIT_ASSERT_NOT_NULL(test, skb);
+					KUNIT_ASSERT_EQ(test,
+							qca4_private_insert(skb, BIT(5)),
+							0);
+					put_unaligned_be16(hdr, skb->data + 14);
+					skb->protocol =
+						eth_type_trans(skb, c->conduit);
+					KUNIT_EXPECT_EQ(test, skb->protocol,
+							htons(ETH_P_XDSA));
+					skb->priority = 42;
+					skb->ip_summed = CHECKSUM_COMPLETE;
+					skb->csum = skb_checksum(skb, 0,
+								 skb->len, 0);
+					result = qca4_private_rcv(skb,
+								  c->conduit);
+					if (!accept) {
+						KUNIT_EXPECT_PTR_EQ(test, result, NULL);
+						continue;
+					}
+					KUNIT_ASSERT_NOT_NULL(test, result);
+					KUNIT_EXPECT_PTR_EQ(test, result->dev,
+							    c->netdev);
+					KUNIT_EXPECT_EQ(test, result->priority,
+							42U);
+					KUNIT_EXPECT_EQ(test, csum_fold(result->csum),
+						csum_fold(skb_checksum(result, 0, result->len,
+							0)));
+					KUNIT_EXPECT_EQ(test,
+						(unsigned int)result->ip_summed,
+						(unsigned int)CHECKSUM_COMPLETE);
+					skb_push(result, ETH_HLEN);
+					result->protocol = eth_type_trans(result, c->netdev);
+					KUNIT_EXPECT_EQ(test, result->protocol,
+						htons(vlans == 2 ?
+							      ETH_P_8021AD :
+						      vlans == 1 ? ETH_P_8021Q :
+								   ETH_P_IP));
+					kfree_skb(result);
+				}
+			}
+		}
+	}
+}
+
+static void qca4_test_nonlinear_and_truncated(struct kunit *test)
+{
+	struct qca4_test_context *c = test->priv;
+	struct sk_buff *full, *skb, *result;
+	unsigned int n;
+
+	full = qca4_test_frame(16, 2);
+	KUNIT_ASSERT_NOT_NULL(test, full);
+	skb = qca4_test_fragment(full,
+				 10); /* TX Ethernet header crosses fragment. */
+	KUNIT_ASSERT_NOT_NULL(test, skb);
+	KUNIT_EXPECT_TRUE(test, skb_is_nonlinear(skb));
+	skb = qca4_private_xmit(skb, c->netdev);
+	KUNIT_ASSERT_NOT_NULL(test, skb);
+	KUNIT_EXPECT_EQ(test, get_unaligned_be16(skb->data + 12), 0x8100);
+	kfree_skb(skb);
+	KUNIT_ASSERT_EQ(test, qca4_private_insert(full, BIT(5)), 0);
+	put_unaligned_be16(0xbe45, full->data + 14); /* Actual observed flood metadata. */
+	skb = qca4_test_fragment(full, ETH_HLEN); /* RX metadata+inner EType nonlinear. */
+	KUNIT_ASSERT_NOT_NULL(test, skb);
+	skb->protocol = eth_type_trans(skb, c->conduit);
+	result = qca4_private_rcv(skb, c->conduit);
+	KUNIT_ASSERT_NOT_NULL(test, result);
+	KUNIT_EXPECT_PTR_EQ(test, result->dev, c->netdev);
+	kfree_skb(result);
+	/* Wrong identifier. */
+	put_unaligned_be16(0x0081, full->data + 12);
+	full->protocol = eth_type_trans(full, c->conduit);
+	KUNIT_EXPECT_PTR_EQ(test, qca4_private_rcv(full, c->conduit), NULL);
+	for (n = 0; n < 4; n++) {
+		skb = alloc_skb(ETH_HLEN + n, GFP_KERNEL);
+		KUNIT_ASSERT_NOT_NULL(test, skb);
+		skb_put_zero(skb, ETH_HLEN + n);
+		put_unaligned_be16(0x8100, skb->data + 12);
+		skb_reset_mac_header(skb);
+		skb_pull(skb, ETH_HLEN);
+		KUNIT_EXPECT_PTR_EQ(test, qca4_private_rcv(skb, c->conduit),
+				    NULL);
+	}
+	for (n = 0; n < ETH_HLEN; n++) {
+		skb = alloc_skb(n, GFP_KERNEL);
+		KUNIT_ASSERT_NOT_NULL(test, skb);
+		skb_put_zero(skb, n);
+		KUNIT_EXPECT_PTR_EQ(test, qca4_private_xmit(skb, c->netdev),
+				    NULL);
+	}
+}
+
+static void qca4_test_rx_clone_complete(struct kunit *test)
+{
+	struct qca4_test_context *c = test->priv;
+	struct sk_buff *skb = qca4_test_frame(16, 0), *copy, *result;
+	unsigned int wire_len;
+	u8 before[128];
+
+	KUNIT_ASSERT_NOT_NULL(test, skb);
+	KUNIT_ASSERT_EQ(test, qca4_private_insert(skb, BIT(5)), 0);
+	put_unaligned_be16(0xbe45, skb->data + 14);
+	wire_len = skb->len;
+	memcpy(before, skb->data, wire_len);
+	skb->protocol = eth_type_trans(skb, c->conduit);
+	skb->ip_summed = CHECKSUM_COMPLETE;
+	skb->csum = skb_checksum(skb, 0, skb->len, 0);
+	copy = skb_clone(skb, GFP_KERNEL);
+	KUNIT_ASSERT_NOT_NULL(test, copy);
+	result = qca4_private_rcv(copy, c->conduit);
+	KUNIT_ASSERT_NOT_NULL(test, result);
+	KUNIT_EXPECT_MEMEQ(test, skb_mac_header(skb), before, wire_len);
+	KUNIT_EXPECT_EQ(test, csum_fold(result->csum),
+			csum_fold(skb_checksum(result, 0, result->len, 0)));
+	KUNIT_EXPECT_EQ(test, (unsigned int)result->ip_summed,
+			(unsigned int)CHECKSUM_COMPLETE);
+	kfree_skb(result);
+	kfree_skb(skb);
+}
+
+static void qca4_test_masks_and_bad_versions(struct kunit *test)
+{
+	struct qca4_test_context *c = test->priv;
+	struct sk_buff *skb;
+	unsigned int mask, version;
+	int ret;
+
+	for (mask = 0; mask <= 255; mask++) {
+		skb = qca4_test_frame(0, 0);
+		KUNIT_ASSERT_NOT_NULL(test, skb);
+		ret = qca4_private_insert(skb, mask);
+		if (!mask || mask > 127) {
+			KUNIT_EXPECT_EQ(test, ret, -EINVAL);
+		} else {
+			KUNIT_EXPECT_EQ(test, ret, 0);
+			KUNIT_EXPECT_EQ(test,
+					get_unaligned_be16(skb->data + 14),
+					0x8080 | mask);
+		}
+		kfree_skb(skb);
+	}
+	for (version = 0; version < 4; version++) {
+		if (version == QCA_HDR_VERSION)
+			continue;
+		skb = qca4_test_frame(16, 0);
+		KUNIT_ASSERT_NOT_NULL(test, skb);
+		KUNIT_ASSERT_EQ(test, qca4_private_insert(skb, BIT(5)), 0);
+		put_unaligned_be16((version << 14) | 5, skb->data + 14);
+		skb->protocol = eth_type_trans(skb, c->conduit);
+		KUNIT_EXPECT_PTR_EQ(test, qca4_private_rcv(skb, c->conduit),
+				    NULL);
+	}
+}
+
+static void qca4_test_flow_dissect(struct kunit *test)
+{
+	static const u8 bytes[] = { 0xbe, 0x45, 0x08, 0x00 };
+	unsigned int length, linear;
+
+	/*
+	 * Every truncated length and every possible split across a page fragment.
+	 * A one-byte reserve also exercises unaligned linear EtherType access.
+	 */
+	for (length = 0; length <= sizeof(bytes); length++) {
+		for (linear = 0; linear <= length; linear++) {
+			struct sk_buff *skb, *full, *clone;
+			unsigned char *data;
+			unsigned int headlen;
+			__be16 proto = htons(0xffff);
+			int offset = -1;
+
+			full = alloc_skb(16, GFP_KERNEL);
+			KUNIT_ASSERT_NOT_NULL(test, full);
+			skb_reserve(full, 1);
+			skb_put_data(full, bytes, length);
+			skb = full;
+			if (linear < length) {
+				skb = qca4_test_fragment(full, linear);
+				kfree_skb(full);
+				KUNIT_ASSERT_NOT_NULL(test, skb);
+			}
+			clone = skb_clone(skb, GFP_KERNEL);
+			KUNIT_ASSERT_NOT_NULL(test, clone);
+			data = clone->data;
+			headlen = skb_headlen(clone);
+			qca4_private_ops.flow_dissect(clone, &proto, &offset);
+			KUNIT_EXPECT_EQ(test, offset, QCA4_PRIVATE_LEN);
+			KUNIT_EXPECT_EQ(test, proto,
+				length == sizeof(bytes) ? htons(ETH_P_IP) : 0);
+			KUNIT_EXPECT_PTR_EQ(test, clone->data, data);
+			KUNIT_EXPECT_EQ(test, clone->len, length);
+			KUNIT_EXPECT_EQ(test, skb_headlen(clone), headlen);
+			KUNIT_EXPECT_MEMEQ(test, skb->data, bytes, headlen);
+			kfree_skb(clone);
+			kfree_skb(skb);
+		}
+	}
+}
+
+static struct kunit_case qca4_private_cases[] = {
+	KUNIT_CASE(qca4_test_flow_dissect),
+	KUNIT_CASE(qca4_test_tx_metadata),
+	KUNIT_CASE(qca4_test_vlan_metadata),
+	KUNIT_CASE(qca4_test_rx_clone_complete),
+	KUNIT_CASE(qca4_test_masks_and_bad_versions),
+	KUNIT_CASE(qca4_test_rx_dispatch),
+	KUNIT_CASE(qca4_test_nonlinear_and_truncated),
+	{}
+};
+
+static struct kunit_suite qca4_private_suite = {
+	.name = "qca4-skb",
+	.init = qca4_test_init,
+	.exit = qca4_test_exit,
+	.test_cases = qca4_private_cases,
+};
+
+kunit_test_suite(qca4_private_suite);

-- 
2.53.0

