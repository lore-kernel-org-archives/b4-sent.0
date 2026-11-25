From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 23:50:34 +0300
Subject: [PATCH RFC net-next 6/7] net: cortina: connect wired IPv4 NAT to
 nftables hardware flowtables
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-almondplus-offload-rfc-v1-6-703175c6340c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=40398;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=uK/W5wie0gmqlE/OvDRgRKRqHnoQeN4gCogMc4fbRF4=;
 b=zd6PLDnd0pdnN6IClNO6M9CUMXfUJ38DiqCH2gSUWLfOuNqgrvFqwwE+f+CROFl1dMZ94HTQR
 O/3hlV1IPYNCH87fO+lR0rP6bUAXIkutCGLGQu/32o8YrE7A1xw04S8
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Translate established IPv4 TCP and UDP flowtable requests into checked
CS7542 leases. Derive original Ethernet addresses and QCA metadata from
actual CPU-routed packets, then validate route neighbors, bridge FDB and
the persistent switch-format generation.

Requests outside the supported physical DSA path, namespace, rewrite
policy or MTU are rejected to software. SYN, FIN, IP options, fragments
and low-TTL exceptions remain in the CPU path. Module configuration is
explicit; enabling this driver does not enable a firewall
hardware-offload flag.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/net/ethernet/cortina/Kconfig               |  11 +
 drivers/net/ethernet/cortina/Makefile              |   1 +
 drivers/net/ethernet/cortina/flowtable/Makefile    |   2 +
 .../cortina/flowtable/codec/cs_ft_rewrite.c        | 234 +++++++++++
 .../cortina/flowtable/codec/cs_ft_rewrite.h        |  42 ++
 .../net/ethernet/cortina/flowtable/cs7542_fw4.c    | 437 +++++++++++++++++++++
 .../ethernet/cortina/flowtable/cs7542_rx_path.c    | 225 +++++++++++
 .../ethernet/cortina/flowtable/cs7542_rx_path.h    |  35 ++
 drivers/net/ethernet/cortina/flowtable/nf_native.c |  90 +++++
 drivers/net/ethernet/cortina/flowtable/nf_native.h |  31 ++
 10 files changed, 1108 insertions(+)

diff --git a/drivers/net/ethernet/cortina/Kconfig b/drivers/net/ethernet/cortina/Kconfig
index 13df28071..50e627ce3 100644
--- a/drivers/net/ethernet/cortina/Kconfig
+++ b/drivers/net/ethernet/cortina/Kconfig
@@ -88,3 +88,14 @@ config CS7542_FE_WIRED
 	  IPv6, Wi-Fi and unsupported policies continue through the CPU.
 	  TCP requires an established connection; SYN and FIN stay in software.
 	  Route, neighbor, MTU and tag state are checked before admission.
+
+config CS7542_FLOWTABLE
+	tristate "Cortina CS7542 nftables hardware flowtable"
+	depends on CS7542_FE_WIRED && NF_FLOW_TABLE && m
+	depends on NET_DSA_QCA8K_4B_MODE
+	default n
+	help
+	  Wired IPv4 TCP/UDP NAT offload through the CS7542 forwarding engine.
+	  This RFC frontend is loadable; the Ethernet owner remains built in.
+	  Users must explicitly request hardware flowtable offload in nftables.
+	  Selecting the driver alone does not change the firewall configuration.
diff --git a/drivers/net/ethernet/cortina/Makefile b/drivers/net/ethernet/cortina/Makefile
index 2bd0572d0..3d6614765 100644
--- a/drivers/net/ethernet/cortina/Makefile
+++ b/drivers/net/ethernet/cortina/Makefile
@@ -16,3 +16,4 @@ endif
 obj-$(CONFIG_CS7542_FE_BACKEND) += cs7542_fe_backend.o
 cs7542_fe_backend-y := cs_fe_backend_module.o cs_fe_backend_algorithm.o cs_fe_hot_codec.o
 
+obj-$(CONFIG_CS7542_FLOWTABLE) += flowtable/
diff --git a/drivers/net/ethernet/cortina/flowtable/Makefile b/drivers/net/ethernet/cortina/flowtable/Makefile
new file mode 100644
index 000000000..00bbbc108
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/Makefile
@@ -0,0 +1,2 @@
+obj-$(CONFIG_CS7542_FLOWTABLE) += cs7542_flowtable.o
+cs7542_flowtable-y := cs7542_fw4.o cs7542_rx_path.o nf_native.o codec/cs_ft_rewrite.o
diff --git a/drivers/net/ethernet/cortina/flowtable/codec/cs_ft_rewrite.c b/drivers/net/ethernet/cortina/flowtable/codec/cs_ft_rewrite.c
new file mode 100644
index 000000000..cd5e4e924
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/codec/cs_ft_rewrite.c
@@ -0,0 +1,234 @@
+// SPDX-License-Identifier: GPL-2.0
+#ifdef CS_FT_HOST_TEST
+#include "host_shim.h"
+#else
+#include <linux/etherdevice.h>
+#include <linux/ip.h>
+#include <linux/pkt_cls.h>
+#include <linux/tc_act/tc_csum.h>
+#include <net/flow_offload.h>
+#endif
+#include "cs_ft_rewrite.h"
+
+/*
+ * Native u32 mask/value storage is intentional: nf_flow_table_offload copies
+ * network-byte arrays into these scalars. Do not ntohl() them a second time.
+ */
+static int cs_ft_patch(u8 *bytes, u8 *written, unsigned int size,
+		       unsigned int offset, u32 mask, u32 value)
+{
+	u8 m[4], v[4];
+	unsigned int i;
+
+	if (offset > size || size - offset < 4)
+		return -EOPNOTSUPP;
+	memcpy(m, &mask, 4);
+	memcpy(v, &value, 4);
+	for (i = 0; i < 4; i++) {
+		if (m[i] != 0 && m[i] != 255)
+			return -EOPNOTSUPP;
+		if (!m[i] && written[offset + i])
+			return -EOPNOTSUPP;
+		if (m[i] && v[i])
+			return -EOPNOTSUPP;
+	}
+	for (i = 0; i < 4; i++)
+		if (!m[i]) {
+			bytes[offset + i] = v[i];
+			written[offset + i] = 1;
+		}
+	return 0;
+}
+
+static int cs_ft_extract_actions(const struct flow_rule *rule, u8 proto,
+				 const struct cs_ft_tuple *before,
+				 struct cs_ft_rewrite *out)
+{
+	struct cs_ft_rewrite r = { 0 };
+	const struct flow_action_entry *a;
+	u8 eth[12] = { 0 }, eth_written[12] = { 0 };
+	u8 addresses[8], address_written[8] = { 0 }, ports[4],
+			 ports_written[4] = { 0 };
+	const u32 csum_flags = TCA_CSUM_UPDATE_FLAG_IPV4HDR |
+			       (proto == IPPROTO_TCP ?
+					TCA_CSUM_UPDATE_FLAG_TCP :
+					TCA_CSUM_UPDATE_FLAG_UDP);
+	const enum flow_action_mangle_base port_header =
+		proto == IPPROTO_TCP ? FLOW_ACT_MANGLE_HDR_TYPE_TCP :
+				       FLOW_ACT_MANGLE_HDR_TYPE_UDP;
+	unsigned int i, csum = 0, nat = 0;
+	struct net_device *egress = NULL;
+
+	if (!rule || !before || !out || !rule->action.num_entries ||
+	    rule->action.num_entries > 16)
+		return -EOPNOTSUPP;
+	memcpy(addresses, &before->src, 4);
+	memcpy(addresses + 4, &before->dst, 4);
+	memcpy(ports, &before->sport, 2);
+	memcpy(ports + 2, &before->dport, 2);
+	flow_action_for_each(i, a, &rule->action) {
+		if (egress)
+			return -EOPNOTSUPP; /* redirect must be last */
+		switch (a->id) {
+		case FLOW_ACTION_MANGLE:
+			if (csum)
+				return -EOPNOTSUPP;
+			switch (a->mangle.htype) {
+			case FLOW_ACT_MANGLE_HDR_TYPE_ETH:
+				if ((a->mangle.offset != 0 &&
+				     a->mangle.offset != 4 &&
+				     a->mangle.offset != 8) ||
+				    cs_ft_patch(eth, eth_written, 12,
+						a->mangle.offset,
+						a->mangle.mask, a->mangle.val))
+					return -EOPNOTSUPP;
+				break;
+			case FLOW_ACT_MANGLE_HDR_TYPE_IP4:
+				if ((a->mangle.offset != 12 &&
+				     a->mangle.offset != 16) ||
+				    a->mangle.mask ||
+				    cs_ft_patch(addresses, address_written, 8,
+						a->mangle.offset - 12,
+						a->mangle.mask, a->mangle.val))
+					return -EOPNOTSUPP;
+				nat = 1;
+				break;
+			case FLOW_ACT_MANGLE_HDR_TYPE_UDP:
+			case FLOW_ACT_MANGLE_HDR_TYPE_TCP:
+				if (a->mangle.htype != port_header ||
+				    a->mangle.offset ||
+				    cs_ft_patch(ports, ports_written, 4, 0,
+						a->mangle.mask, a->mangle.val))
+					return -EOPNOTSUPP;
+				nat = 1;
+				break;
+			default:
+				return -EOPNOTSUPP;
+			}
+			break;
+		case FLOW_ACTION_CSUM:
+			if (csum++ || !nat || a->csum_flags != csum_flags)
+				return -EOPNOTSUPP;
+			break;
+		case FLOW_ACTION_REDIRECT:
+			if (!a->dev)
+				return -EOPNOTSUPP;
+			egress = a->dev;
+			break;
+		default:
+			return -EOPNOTSUPP;
+		}
+	}
+	if (!egress || (nat && !csum))
+		return -EOPNOTSUPP;
+	for (i = 0; i < 12; i++)
+		if (!eth_written[i])
+			return -EOPNOTSUPP;
+	if (!is_valid_ether_addr(eth) || !is_valid_ether_addr(eth + 6))
+		return -EOPNOTSUPP;
+	r.before = *before;
+	memcpy(r.dmac, eth, 6);
+	memcpy(r.smac, eth + 6, 6);
+	memcpy(&r.after.src, addresses, 4);
+	memcpy(&r.after.dst, addresses + 4, 4);
+	memcpy(&r.after.sport, ports, 2);
+	memcpy(&r.after.dport, ports + 2, 2);
+	r.redirect = egress;
+	r.action_count = rule->action.num_entries;
+	r.nat_action = !!nat;
+	r.csum_action = !!csum;
+	r.csum_flags = csum ? csum_flags : 0;
+	*out = r;
+	return 0;
+}
+
+static int cs_ft_extract_match(const struct flow_rule *rule,
+			       struct cs_ft_tuple *tuple, int *ingress,
+			       u8 *proto)
+{
+	const u64 required = BIT_ULL(FLOW_DISSECTOR_KEY_META) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_CONTROL) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_BASIC) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_IPV4_ADDRS) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_PORTS);
+	struct flow_match_meta meta;
+	struct flow_match_control control;
+	struct flow_match_basic basic;
+	struct flow_match_ipv4_addrs ip;
+	struct flow_match_ports ports;
+
+	if (!rule || !tuple || !ingress || !rule->match.dissector ||
+	    (rule->match.dissector->used_keys & required) != required)
+		return -EOPNOTSUPP;
+	flow_rule_match_meta(rule, &meta);
+	flow_rule_match_control(rule, &control);
+	flow_rule_match_basic(rule, &basic);
+	flow_rule_match_ipv4_addrs(rule, &ip);
+	flow_rule_match_ports(rule, &ports);
+	if (meta.mask->ingress_ifindex != -1 || meta.mask->ingress_iftype ||
+	    meta.mask->l2_miss ||
+	    control.key->addr_type != FLOW_DISSECTOR_KEY_IPV4_ADDRS ||
+	    control.mask->addr_type != 0xffff || control.mask->flags ||
+	    control.mask->thoff || basic.key->n_proto != htons(ETH_P_IP) ||
+	    basic.mask->n_proto != htons(0xffff) ||
+	    basic.mask->ip_proto != 255 || ip.mask->src != htonl(~0U) ||
+	    ip.mask->dst != htonl(~0U) || ports.mask->src != htons(0xffff) ||
+	    ports.mask->dst != htons(0xffff))
+		return -EOPNOTSUPP;
+	if (basic.key->ip_proto == IPPROTO_TCP) {
+		struct flow_match_tcp tcp;
+
+		if (!(rule->match.dissector->used_keys &
+		      BIT_ULL(FLOW_DISSECTOR_KEY_TCP)))
+			return -EOPNOTSUPP;
+		flow_rule_match_tcp(rule, &tcp);
+		if (tcp.key->flags || tcp.mask->flags != htons(0x05))
+			return -EOPNOTSUPP;
+	} else if (basic.key->ip_proto != IPPROTO_UDP) {
+		return -EOPNOTSUPP;
+	}
+	*proto = basic.key->ip_proto;
+	*tuple = (struct cs_ft_tuple){ ip.key->src, ip.key->dst, ports.key->src,
+				       ports.key->dst };
+	*ingress = meta.key->ingress_ifindex;
+	return 0;
+}
+
+int cs_ft_nf_extract(const struct flow_cls_offload *cls, bool routed_nf_context,
+		     struct cs_ft_nf_facts *out)
+{
+	struct cs_ft_nf_facts f = { 0 };
+	struct cs_ft_tuple tuple;
+	const struct flow_rule *rule;
+	const u64 required = BIT_ULL(FLOW_DISSECTOR_KEY_META) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_CONTROL) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_BASIC) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_IPV4_ADDRS) |
+			     BIT_ULL(FLOW_DISSECTOR_KEY_PORTS);
+	if (!cls || !out || cls->command != FLOW_CLS_REPLACE ||
+	    cls->common.chain_index)
+		return -EOPNOTSUPP;
+	rule = flow_cls_offload_flow_rule(cls);
+	if (cs_ft_extract_match(rule, &tuple, &f.ingress_ifindex,
+				&f.ip_proto) ||
+	    cs_ft_extract_actions(rule, f.ip_proto, &tuple, &f.rewrite))
+		return -EOPNOTSUPP;
+	f.egress_ifindex = f.rewrite.redirect->ifindex;
+	f.rewrite.redirect =
+		NULL; /* No borrowed netdev pointer escapes diagnostic API. */
+	f.match_used_keys = rule->match.dissector->used_keys;
+	f.extra_match_keys =
+		f.match_used_keys !=
+		(required |
+		 (f.ip_proto == IPPROTO_TCP ? BIT_ULL(FLOW_DISSECTOR_KEY_TCP) :
+					      0));
+	f.vlan_offset =
+		!!rule->match.dissector->offset[FLOW_DISSECTOR_KEY_VLAN];
+	f.cvlan_offset =
+		!!rule->match.dissector->offset[FLOW_DISSECTOR_KEY_CVLAN];
+	f.routed_nf_context = routed_nf_context;
+	f.ttl_decrement_from_context = routed_nf_context;
+	/* Unknown ingress encapsulation stays unknown even without VLAN actions. */
+	*out = f;
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/flowtable/codec/cs_ft_rewrite.h b/drivers/net/ethernet/cortina/flowtable/codec/cs_ft_rewrite.h
new file mode 100644
index 000000000..9f96b1ea6
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/codec/cs_ft_rewrite.h
@@ -0,0 +1,42 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FT_REWRITE_H
+#define CS_FT_REWRITE_H
+#ifndef CS_FT_HOST_TEST
+#include <linux/types.h>
+#include <net/flow_offload.h>
+#endif
+struct cs_ft_tuple {
+	__be32 src, dst;
+	__be16 sport, dport;
+};
+
+struct cs_ft_rewrite {
+	struct cs_ft_tuple before, after;
+	u8 smac[6],
+		dmac[6]; /* Requested OUTPUT MACs; original MACs not in these NF matches. */
+	struct net_device
+		*redirect; /* Borrowed only during the synchronous call. */
+	unsigned int action_count, csum_flags;
+	bool nat_action, csum_action;
+};
+
+/*
+ * Decode facts only: no topology, domain, QCA or hardware admission. Native
+ *
+ * mask/value bytes follow the actual NF generator; no second ntohl().
+ */
+struct cs_ft_nf_facts {
+	struct cs_ft_rewrite rewrite;
+	u8 ip_proto;
+	int ingress_ifindex, egress_ifindex;
+	u64 match_used_keys;
+	bool extra_match_keys, vlan_offset, cvlan_offset;
+	bool routed_nf_context, ttl_decrement_from_context;
+	bool ttl_action_observed; /* false: this supported NF action set has none. */
+	bool customer_encap_proven_plain; /* always false; absence isn't provenance. */
+	bool hardware_admitted; /* always false: diagnostic result only. */
+};
+
+int cs_ft_nf_extract(const struct flow_cls_offload *cls, bool routed_nf_context,
+		     struct cs_ft_nf_facts *facts);
+#endif
diff --git a/drivers/net/ethernet/cortina/flowtable/cs7542_fw4.c b/drivers/net/ethernet/cortina/flowtable/cs7542_fw4.c
new file mode 100644
index 000000000..d5a132e87
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/cs7542_fw4.c
@@ -0,0 +1,437 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Standard nftables flowtable frontend for the CS7542/QCA8337 wired path. */
+#include <linux/bitfield.h>
+#include <linux/cs7542_ft_live.h>
+#include <linux/dsa/qca8k_persistent.h>
+#include <linux/etherdevice.h>
+#include <linux/if_bridge.h>
+#include <linux/list.h>
+#include <linux/module.h>
+#include <linux/netdevice.h>
+#include <linux/of.h>
+#include <linux/rtnetlink.h>
+#include <linux/slab.h>
+#include <net/dsa.h>
+#include <net/flow_offload.h>
+#include <net/net_namespace.h>
+#include <net/arp.h>
+#include <net/ip.h>
+#include <net/route.h>
+#include "nf_native.h"
+
+struct native_binding {
+	struct list_head list;
+	struct cs7542_fe_live *owner;
+	struct net_device *conduit;
+	u64 id, handle, version;
+};
+
+/*
+ * cs7542_ft_live serializes every binding callback and retires them all
+ * before dropping the registration pin. The counters are read from sysfs.
+ */
+static LIST_HEAD(bindings);
+static atomic64_t counts[NATIVE_REASONS];
+static typeof(cs7542_fe_live_replace_native) *replace_native;
+static typeof(cs7542_fe_live_replace_native_tcp) *replace_native_tcp;
+static typeof(qca8k_persistent_status) *persistent_status;
+static typeof(cs7542_fe_live_native_lastused) *native_lastused;
+/*
+ * The private nf_flow_table module supplies the PMTU of this direction.
+ * This frontend can load before the flowtable module.
+ */
+
+static struct native_binding *find_binding(u64 id)
+{
+	struct native_binding *b;
+
+	list_for_each_entry(b, &bindings, list)
+		if (b->id == id)
+			return b;
+	return NULL;
+}
+
+static int native_open(void *ctx, u64 id, struct net_device *conduit)
+{
+	struct native_binding *b;
+	int err;
+
+	b = find_binding(id);
+	if (b)
+		return b->conduit ? -EEXIST : -ESHUTDOWN;
+	b = kzalloc_obj(*b);
+	if (!b)
+		return -ENOMEM;
+	b->owner = cs7542_fe_live_get(conduit);
+	if (IS_ERR(b->owner)) {
+		err = PTR_ERR(b->owner);
+		goto free;
+	}
+	err = cs7542_fe_live_open(b->owner, &b->handle);
+	if (err) {
+		cs7542_fe_live_put(b->owner);
+		goto free;
+	}
+	b->id = id;
+	dev_hold(conduit);
+	b->conduit = conduit;
+	list_add_tail(&b->list, &bindings);
+	return 0;
+free:
+	kfree(b);
+	return err;
+}
+
+static struct dsa_port *get_endpoint(struct net_device *conduit, int ifindex,
+				     struct native_endpoint *endpoint)
+{
+	struct net_device *dev = __dev_get_by_index(dev_net(conduit), ifindex);
+	struct net_device *bridge;
+	struct dsa_port *port;
+
+	ASSERT_RTNL();
+	port = dsa_port_from_netdev(dev);
+	if (IS_ERR(port) || !port->ds || !port->ds->dev || !port->cpu_dp ||
+	    port->cpu_dp->conduit != conduit || port->cpu_dp->index != 0 ||
+	    !of_device_is_compatible(port->ds->dev->of_node, "qca,qca8337") ||
+	    port->index < 1 || port->index > 5 || port->lag || port->hsr_dev ||
+	    !netif_running(dev) || !netif_carrier_ok(dev) ||
+	    dsa_port_is_vlan_filtering(port))
+		return ERR_PTR(-EOPNOTSUPP);
+	bridge = netdev_master_upper_dev_get(dev);
+	if (bridge &&
+	    (!netif_is_bridge_master(bridge) || !netif_running(bridge) ||
+	     br_vlan_enabled(bridge) ||
+	     br_port_get_stp_state(dev) != BR_STATE_FORWARDING ||
+	     br_port_flag_is_set(dev, BR_PORT_LOCKED | BR_PORT_MAB |
+					      BR_ISOLATED | BR_VLAN_TUNNEL)))
+		return ERR_PTR(-EOPNOTSUPP);
+	endpoint->ifindex = ifindex;
+	endpoint->port = port->index;
+	ether_addr_copy(endpoint->mac,
+			bridge ? bridge->dev_addr : dev->dev_addr);
+	return port;
+}
+
+static bool fdb_matches(const struct dsa_port *port, const u8 addr[ETH_ALEN])
+{
+	struct net_device *bridge = netdev_master_upper_dev_get(port->user);
+
+	return !bridge || br_fdb_find_port(bridge, addr, 0) == port->user;
+}
+
+/*
+ * Re-resolve the unicast next hop on the same Linux L3 device. The nft
+ * action remains authoritative. The lookup may only corroborate it or
+ * reject it, including routes that require unsupported neighbour types.
+ */
+static int native_check_neighbour(const struct cs7542_fe_native_request *r)
+{
+	struct net_device *dev =
+		__dev_get_by_index(&init_net, r->egress_ifindex);
+	struct flowi4 fl = {
+		.daddr = htonl(r->rule.translated.dst),
+		.saddr = htonl(r->rule.original.src),
+		.fl4_sport = htons(r->rule.original.sport),
+		.fl4_dport = htons(r->rule.translated.dport),
+		.flowi4_proto = r->rule.native_l4proto,
+		.flowi4_flags = FLOWI_FLAG_ANYSRC,
+	};
+	struct net_device *l3;
+	struct neighbour *neigh;
+	struct rtable *rt;
+	__be32 next;
+	int err = -ESTALE;
+
+	ASSERT_RTNL();
+	if (!dev)
+		return -ENODEV;
+	l3 = netdev_master_upper_dev_get(dev);
+	if (!l3)
+		l3 = dev;
+	fl.flowi4_oif = l3->ifindex;
+	rt = ip_route_output_key(&init_net, &fl);
+	if (IS_ERR(rt))
+		return PTR_ERR(rt);
+	if (rt->rt_type != RTN_UNICAST || dst_dev(&rt->dst) != l3 ||
+	    dst_xfrm(&rt->dst) || rt->dst.lwtstate ||
+	    (rt->rt_gw_family && rt->rt_gw_family != AF_INET) ||
+	    ip_dst_mtu_maybe_forward(&rt->dst, true) < r->route_mtu)
+		goto put;
+	next = rt_nexthop(rt, fl.daddr);
+	/*
+	 * Read an existing entry only. Hardware admission never creates one or
+	 * triggers an ARP solicitation to manufacture its own evidence.
+	 */
+	neigh = neigh_lookup(arp_table(dev_net(l3)), &next, l3);
+	if (neigh) {
+		read_lock_bh(&neigh->lock);
+		if ((neigh->nud_state & NUD_VALID) &&
+		    ether_addr_equal(neigh->ha, r->rule.dmac))
+			err = 0;
+		read_unlock_bh(&neigh->lock);
+		neigh_release(neigh);
+	}
+put:
+	ip_rt_put(rt);
+	return err;
+}
+
+static enum native_reason
+prepare_request(struct native_binding *b, struct flow_cls_offload *cls,
+		struct cs7542_fe_native_request *request)
+{
+	struct qca8k_persistent_status format = {
+		.size = sizeof(format),
+		.version = QCA8K_PERSISTENT_STATUS_VERSION,
+	};
+	struct cs_ft_nf_facts facts;
+	struct native_endpoint in, out;
+	struct cs7542_l4_tuple tuple;
+	struct dsa_port *ip, *op;
+	struct cs7542_rx_path wire;
+	enum native_reason reason;
+	typeof(nf_flow_offload_route_mtu) *route_mtu;
+
+	ASSERT_RTNL();
+	if (cs_ft_nf_extract(cls, true, &facts) || facts.extra_match_keys ||
+	    facts.vlan_offset || facts.cvlan_offset ||
+	    !facts.rewrite.nat_action)
+		return NATIVE_MATCH;
+	if (facts.ip_proto == IPPROTO_TCP &&
+	    (!replace_native_tcp || !cls->nf_tcp_established))
+		return NATIVE_MATCH;
+	if (!net_eq(dev_net(b->conduit), &init_net) ||
+	    !netif_running(b->conduit) || !netif_carrier_ok(b->conduit))
+		return NATIVE_PATH;
+	ip = get_endpoint(b->conduit, facts.ingress_ifindex, &in);
+	op = get_endpoint(b->conduit, facts.egress_ifindex, &out);
+	if (IS_ERR(ip) || IS_ERR(op) || ip->ds != op->ds)
+		return NATIVE_PATH;
+	tuple = (struct cs7542_l4_tuple){
+		.src = facts.rewrite.before.src,
+		.dst = facts.rewrite.before.dst,
+		.sport = facts.rewrite.before.sport,
+		.dport = facts.rewrite.before.dport,
+		.ip_proto = htonl(facts.ip_proto),
+	};
+	if (cs7542_rx_path_lookup(b->conduit, in.port, &tuple, &wire))
+		return NATIVE_WIRE;
+	if (!fdb_matches(ip, wire.source) ||
+	    !fdb_matches(op, facts.rewrite.dmac))
+		return NATIVE_PATH;
+	reason = native_rule_build(&facts, &in, &out, &wire, request);
+	if (reason != NATIVE_OWNER)
+		return reason;
+	if (!persistent_status || persistent_status(b->conduit, &format) ||
+	    format.size != sizeof(format) ||
+	    format.version != QCA8K_PERSISTENT_STATUS_VERSION ||
+	    !format.epoch || format.requested != 1 || format.known != 1 ||
+	    format.coherent != 1 || format.ready != 1 ||
+	    format.restore_debt != 1 || format.closing || format.uncertain ||
+	    format.first_error || format.held_fault || format.reserved ||
+	    format.selected != DSA_TAG_PROTO_QCA4 ||
+	    format.tree_protocol != DSA_TAG_PROTO_QCA4)
+		return NATIVE_TAG;
+	request->format_epoch = format.epoch;
+	route_mtu = symbol_get(nf_flow_offload_route_mtu);
+	if (route_mtu) {
+		request->route_mtu = route_mtu(cls);
+		symbol_put(nf_flow_offload_route_mtu);
+	}
+	return NATIVE_OWNER;
+}
+
+static int
+native_replace_checked(struct native_binding *b, struct flow_cls_offload *cls,
+		       const struct cs7542_fe_native_request *request,
+		       enum native_reason *reason)
+{
+	int err;
+
+	err = native_check_neighbour(request);
+	if (err) {
+		*reason = NATIVE_PATH;
+		return cs7542_fe_live_reject(b->owner, b->handle, cls->cookie,
+					     b->version, err);
+	}
+	if (request->rule.native_l4proto == IPPROTO_TCP)
+		err = replace_native_tcp(b->owner, b->handle, cls->cookie,
+					 b->version, request, cls);
+	else
+		err = replace_native(b->owner, b->handle, cls->cookie,
+				     b->version, request);
+	if (err)
+		return err;
+	/*
+	 * Updates during publication are covered by the built-in watcher.
+	 * Recheck the gap between the initial validation and publication.
+	 */
+	err = native_check_neighbour(request);
+	if (err) {
+		*reason = NATIVE_PATH;
+		return cs7542_fe_live_destroy(b->owner, b->handle, cls->cookie, b->version) ?:
+			       err;
+	}
+	*reason = NATIVE_INSTALLED;
+	return 0;
+}
+
+static int native_rule(void *ctx, u64 id, struct flow_cls_offload *cls)
+{
+	struct native_binding *b = find_binding(id);
+	struct cs7542_fe_native_request request;
+	enum native_reason reason;
+	int result;
+
+	if (!b)
+		return -ENOENT;
+	if (!b->conduit)
+		return -ESHUTDOWN;
+	if (cls->command == FLOW_CLS_STATS) {
+		unsigned long lastused;
+
+		if (!native_lastused)
+			return -EOPNOTSUPP;
+		result = native_lastused(b->owner, b->handle, cls->cookie,
+					 &lastused);
+		if (!result)
+			flow_stats_update(&cls->stats, 0, 0, 0, lastused,
+					  FLOW_ACTION_HW_STATS_DELAYED);
+		return result;
+	}
+	if (b->version == U64_MAX)
+		return -EOVERFLOW;
+	b->version++;
+	if (cls->command == FLOW_CLS_DESTROY)
+		return cs7542_fe_live_destroy(b->owner, b->handle, cls->cookie,
+					      b->version);
+	if (cls->command != FLOW_CLS_REPLACE)
+		return -EOPNOTSUPP;
+	/*
+	 * flow-block callbacks can race RTNL-held teardown. Never wait on RTNL
+	 * while holding the live bridge mutex. Every rejection withdraws an
+	 * earlier version of this cookie before returning it to software.
+	 */
+	if (!rtnl_trylock()) {
+		reason = NATIVE_PATH;
+		result = cs7542_fe_live_reject(b->owner, b->handle, cls->cookie,
+					       b->version, -EBUSY);
+	} else {
+		reason = prepare_request(b, cls, &request);
+		if (reason == NATIVE_OWNER && request.route_mtu &&
+		    replace_native) {
+			result = native_replace_checked(b, cls, &request,
+							&reason);
+		} else {
+			result = cs7542_fe_live_reject(b->owner, b->handle,
+						       cls->cookie, b->version,
+						       -EOPNOTSUPP);
+		}
+		rtnl_unlock();
+	}
+	atomic64_inc(&counts[reason]);
+	return result;
+}
+
+static int native_close(void *ctx, u64 id)
+{
+	struct native_binding *b = find_binding(id);
+	int err;
+
+	if (!b)
+		return 0;
+	/*
+	 * A failed hardware cut keeps the block handle and owner reference for
+	 * retry. It must never hold unregister_netdevice() hostage.
+	 */
+	if (b->conduit) {
+		dev_put(b->conduit);
+		b->conduit = NULL;
+	}
+	err = cs7542_fe_live_close(b->owner, b->handle);
+	if (err)
+		return err;
+	list_del(&b->list);
+	cs7542_fe_live_put(b->owner);
+	kfree(b);
+	return 0;
+}
+
+static int native_detach(void *ctx)
+{
+	/* The bridge calls close() for every open binding before detach(). */
+	return list_empty(&bindings) ? 0 : -EBUSY;
+}
+
+static const struct cs7542_ft_live_ops native_ops = {
+	.api_version = CS7542_FT_LIVE_API_VERSION,
+	.size = sizeof(native_ops),
+	.owner = THIS_MODULE,
+	.name = "cs7542-fw4",
+	.open = native_open,
+	.rule = native_rule,
+	.close = native_close,
+	.detach = native_detach,
+};
+
+static int status_get(char *buf, const struct kernel_param *kp)
+{
+	return sysfs_emit(buf,
+		"owner_api=%u rule=%lld topology=%lld wire=%lld mac=%lld format=%lld owner=%lld installed=%lld tcp_native=%u\n",
+		!!replace_native, atomic64_read(&counts[NATIVE_MATCH]),
+		atomic64_read(&counts[NATIVE_PATH]),
+		atomic64_read(&counts[NATIVE_WIRE]),
+		atomic64_read(&counts[NATIVE_MAC]),
+		atomic64_read(&counts[NATIVE_TAG]),
+		atomic64_read(&counts[NATIVE_OWNER]),
+		atomic64_read(&counts[NATIVE_INSTALLED]), !!replace_native_tcp);
+}
+
+static const struct kernel_param_ops status_ops = { .get = status_get };
+module_param_cb(status, &status_ops, NULL, 0444);
+
+static int __init native_init(void)
+{
+	int err = cs7542_rx_path_init();
+
+	if (err)
+		return err;
+	replace_native = symbol_get(cs7542_fe_live_replace_native);
+	replace_native_tcp = symbol_get(cs7542_fe_live_replace_native_tcp);
+	persistent_status = symbol_get(qca8k_persistent_status);
+	native_lastused = symbol_get(cs7542_fe_live_native_lastused);
+	err = cs7542_ft_live_register(&native_ops, NULL);
+	if (err) {
+		if (native_lastused)
+			symbol_put(cs7542_fe_live_native_lastused);
+		if (persistent_status)
+			symbol_put(qca8k_persistent_status);
+		if (replace_native_tcp)
+			symbol_put(cs7542_fe_live_replace_native_tcp);
+		if (replace_native)
+			symbol_put(cs7542_fe_live_replace_native);
+		cs7542_rx_path_exit();
+	}
+	return err;
+}
+
+static void __exit native_exit(void)
+{
+	/* The bridge's reference pins this module until its callbacks quiesce. */
+	cs7542_rx_path_exit();
+	if (native_lastused)
+		symbol_put(cs7542_fe_live_native_lastused);
+	if (persistent_status)
+		symbol_put(qca8k_persistent_status);
+	if (replace_native_tcp)
+		symbol_put(cs7542_fe_live_replace_native_tcp);
+	if (replace_native)
+		symbol_put(cs7542_fe_live_replace_native);
+}
+
+module_init(native_init);
+module_exit(native_exit);
+MODULE_LICENSE("GPL");
+MODULE_INFO(description,
+	"Cortina CS7542 IPv4 TCP and UDP nftables hardware flowtable frontend");
diff --git a/drivers/net/ethernet/cortina/flowtable/cs7542_rx_path.c b/drivers/net/ethernet/cortina/flowtable/cs7542_rx_path.c
new file mode 100644
index 000000000..20a132852
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/cs7542_rx_path.c
@@ -0,0 +1,225 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Recover the original Ethernet addresses and switch tag of a CPU-routed flow. */
+#include <linux/bitfield.h>
+#include <linux/dsa/tag_qca.h>
+#include <linux/etherdevice.h>
+#include <linux/if_vlan.h>
+#include <linux/ip.h>
+#include <linux/jhash.h>
+#include <linux/jiffies.h>
+#include <linux/module.h>
+#include <linux/netdevice.h>
+#include <linux/of.h>
+#include <linux/udp.h>
+#include <linux/tcp.h>
+#include <linux/unaligned.h>
+#include <net/ip.h>
+#include <net/net_namespace.h>
+#include "cs7542_rx_path.h"
+
+#define PATH_SLOTS 128
+#define PATH_AGE (2 * HZ)
+
+/*
+ * skb->dev is the DSA conduit. Its WAN user port can have a different
+ * unicast MAC. Resolve the addressed L3 device when nftables supplies the
+ * real source port of the route. Observing a frame never installs a rule.
+ */
+struct path_entry {
+	struct cs7542_l4_tuple tuple;
+	struct cs7542_rx_path path;
+	int ifindex;
+	unsigned long expires;
+	bool ambiguous;
+};
+
+static DEFINE_SPINLOCK(paths_lock);
+static struct path_entry paths[PATH_SLOTS];
+static unsigned int index_of(const struct cs7542_l4_tuple *tuple, int ifindex)
+{
+	static_assert(sizeof(*tuple) == 16);
+	return jhash(tuple, sizeof(*tuple), ifindex) % PATH_SLOTS;
+}
+
+static bool fresh(const struct path_entry *entry)
+{
+	return entry->ifindex && time_before(jiffies, entry->expires);
+}
+
+static void remember(int ifindex, const struct cs7542_l4_tuple *tuple,
+		     const struct cs7542_rx_path *path)
+{
+	struct path_entry *entry = &paths[index_of(tuple, ifindex)];
+
+	spin_lock_bh(&paths_lock);
+	if (!fresh(entry)) {
+		entry->ifindex = ifindex;
+		entry->tuple = *tuple;
+		entry->path = *path;
+		entry->ambiguous = false;
+	} else if (entry->ifindex != ifindex ||
+		   memcmp(&entry->tuple, tuple, sizeof(*tuple))) {
+		/* Keep a live owner's observation across hash collisions. */
+		goto out;
+	} else if (entry->path.tag != path->tag ||
+		   entry->path.tag_len != path->tag_len ||
+		   !ether_addr_equal(entry->path.source, path->source) ||
+		   !ether_addr_equal(entry->path.destination,
+				     path->destination)) {
+		entry->ambiguous = true;
+	}
+	entry->expires = jiffies + PATH_AGE;
+out:
+	spin_unlock_bh(&paths_lock);
+}
+
+int cs7542_rx_path_lookup(struct net_device *conduit, unsigned int port,
+			  const struct cs7542_l4_tuple *tuple,
+			  struct cs7542_rx_path *out)
+{
+	struct path_entry *entry;
+	int error = -ENOENT;
+
+	if (!conduit || !tuple || !out || !net_eq(dev_net(conduit), &init_net))
+		return -EINVAL;
+	entry = &paths[index_of(tuple, conduit->ifindex)];
+	spin_lock_bh(&paths_lock);
+	if (fresh(entry) && entry->ifindex == conduit->ifindex &&
+	    !memcmp(&entry->tuple, tuple, sizeof(*tuple)) &&
+	    !entry->ambiguous &&
+	    FIELD_GET(QCA_HDR_RECV_SOURCE_PORT, entry->path.tag) == port) {
+		*out = entry->path;
+		error = 0;
+	}
+	spin_unlock_bh(&paths_lock);
+	return error;
+}
+
+static void observe(struct sk_buff *skb, struct net_device *dev)
+{
+	u8 ether[ETH_HLEN + 4] __aligned(4);
+	struct iphdr ip;
+	union {
+		struct udphdr udp;
+		struct tcphdr tcp;
+	} transport;
+	unsigned int l4_length;
+	struct cs7542_l4_tuple tuple;
+	struct cs7542_rx_path path;
+	unsigned int reason;
+	int offset;
+
+	if ((skb->pkt_type != PACKET_HOST &&
+	     skb->pkt_type != PACKET_OTHERHOST) ||
+	    !net_eq(dev_net(dev), &init_net) || !skb_mac_header_was_set(skb) ||
+	    skb_vlan_tag_present(skb) || skb_is_gso(skb))
+		return;
+	offset = skb_mac_header(skb) - skb->data;
+	if (offset != -ETH_HLEN ||
+	    skb_copy_bits(skb, offset, ether, sizeof(ether)))
+		return;
+	path.tag_len = get_unaligned_be16(ether + 12) == ETH_P_8021Q ? 4 : 2;
+	path.tag = get_unaligned_be16(ether + 10 + path.tag_len);
+	reason = FIELD_GET(QCA_HDR_RECV_TYPE, path.tag);
+	/*
+	 * Ordinary frames sent to the CPU also carry forwarding reason codes.
+	 * Both QCA taggers consume register replies and MIB packets themselves.
+	 */
+	if (FIELD_GET(QCA_HDR_RECV_VERSION, path.tag) != QCA_HDR_VERSION ||
+	    reason == QCA_HDR_RECV_TYPE_MIB ||
+	    reason == QCA_HDR_RECV_TYPE_RW_REG_ACK ||
+	    (path.tag & QCA_HDR_RECV_FRAME_IS_TAGGED) ||
+	    !FIELD_GET(QCA_HDR_RECV_SOURCE_PORT, path.tag) ||
+	    get_unaligned_be16(ether + 12 + path.tag_len) != ETH_P_IP ||
+	    !is_valid_ether_addr(ether) ||
+	    !is_valid_ether_addr(ether + ETH_ALEN))
+		return;
+	if (skb_copy_bits(skb, path.tag_len, &ip, sizeof(ip)) ||
+	    ip.version != 4 || ip.ihl != 5 || ip_is_fragment(&ip) ||
+	    ip_fast_csum(&ip, 5) || ntohs(ip.tot_len) < sizeof(ip) ||
+	    skb->len < path.tag_len + ntohs(ip.tot_len))
+		return;
+	l4_length = ntohs(ip.tot_len) - sizeof(ip);
+	if (ip.protocol == IPPROTO_UDP) {
+		if (l4_length < sizeof(transport.udp) ||
+		    skb_copy_bits(skb, path.tag_len + sizeof(ip),
+				  &transport.udp, sizeof(transport.udp)) ||
+		    ntohs(transport.udp.len) != l4_length)
+			return;
+		tuple.sport = transport.udp.source;
+		tuple.dport = transport.udp.dest;
+	} else if (ip.protocol == IPPROTO_TCP) {
+		/*
+		 * Even a handshake can identify a switch peer. Only netfilter can
+		 * authorize established data offload via its typed request.
+		 */
+		if (l4_length < sizeof(transport.tcp) ||
+		    skb_copy_bits(skb, path.tag_len + sizeof(ip),
+				  &transport.tcp, sizeof(transport.tcp)) ||
+		    transport.tcp.doff < 5 ||
+		    transport.tcp.doff * 4 > l4_length)
+			return;
+		tuple.sport = transport.tcp.source;
+		tuple.dport = transport.tcp.dest;
+	} else {
+		return;
+	}
+	tuple.src = ip.saddr;
+	tuple.dst = ip.daddr;
+	tuple.ip_proto = htonl(ip.protocol);
+	ether_addr_copy(path.source, ether + ETH_ALEN);
+	ether_addr_copy(path.destination, ether);
+	remember(dev->ifindex, &tuple, &path);
+}
+
+static int receive(struct sk_buff *skb, struct net_device *dev,
+		   struct packet_type *ptype, struct net_device *original)
+{
+	observe(skb, dev);
+	consume_skb(skb);
+	return NET_RX_SUCCESS;
+}
+
+static struct packet_type observer = {
+	.type = cpu_to_be16(ETH_P_XDSA),
+	.func = receive,
+};
+
+static int link_event(struct notifier_block *nb, unsigned long event,
+		      void *data)
+{
+	struct net_device *dev = netdev_notifier_info_to_dev(data);
+	unsigned int i;
+
+	if (!net_eq(dev_net(dev), &init_net) ||
+	    (event != NETDEV_DOWN && event != NETDEV_CHANGEADDR &&
+	     event != NETDEV_UNREGISTER))
+		return NOTIFY_DONE;
+	spin_lock_bh(&paths_lock);
+	for (i = 0; i < ARRAY_SIZE(paths); i++)
+		if (paths[i].ifindex == dev->ifindex)
+			paths[i].ifindex = 0;
+	spin_unlock_bh(&paths_lock);
+	return NOTIFY_DONE;
+}
+
+static struct notifier_block netdev_events = { .notifier_call = link_event };
+
+int cs7542_rx_path_init(void)
+{
+	int error;
+
+	if (!of_machine_is_compatible("securifi,almondplus"))
+		return -ENODEV;
+	error = register_netdevice_notifier(&netdev_events);
+	if (error)
+		return error;
+	dev_add_pack(&observer);
+	return 0;
+}
+
+void cs7542_rx_path_exit(void)
+{
+	dev_remove_pack(&observer);
+	unregister_netdevice_notifier(&netdev_events);
+}
diff --git a/drivers/net/ethernet/cortina/flowtable/cs7542_rx_path.h b/drivers/net/ethernet/cortina/flowtable/cs7542_rx_path.h
new file mode 100644
index 000000000..20f6b4c7c
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/cs7542_rx_path.h
@@ -0,0 +1,35 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS7542_RX_PATH_H
+#define CS7542_RX_PATH_H
+
+#include <linux/if_ether.h>
+#include <linux/types.h>
+
+struct net_device;
+
+struct cs7542_l4_tuple {
+	__be32 src, dst;
+	__be16 sport, dport;
+	/* Network order keeps all 16 hash/key bytes defined on every architecture. */
+	__be32 ip_proto;
+};
+
+struct cs7542_rx_path {
+	u8 source[ETH_ALEN];
+	u8 destination[ETH_ALEN];
+	u16 tag;
+	u8 tag_len;
+};
+
+/*
+ * The caller supplies the flow's live ingress conduit and DSA port.
+ * An observation is input to the classifier, not permission to install a rule.
+ */
+int cs7542_rx_path_lookup(struct net_device *conduit, unsigned int port,
+			  const struct cs7542_l4_tuple *tuple,
+			  struct cs7542_rx_path *out);
+
+int cs7542_rx_path_init(void);
+void cs7542_rx_path_exit(void);
+
+#endif
diff --git a/drivers/net/ethernet/cortina/flowtable/nf_native.c b/drivers/net/ethernet/cortina/flowtable/nf_native.c
new file mode 100644
index 000000000..7363e8f4c
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/nf_native.c
@@ -0,0 +1,90 @@
+// SPDX-License-Identifier: GPL-2.0
+#ifdef CS_FT_HOST_TEST
+#include "host_shim.h"
+#define be32_to_cpu(v) ntohl(v)
+#define be16_to_cpu(v) ntohs(v)
+#define ether_addr_equal(a, b) (!memcmp(a, b, 6))
+#define ether_addr_copy(d, s) memcpy(d, s, 6)
+#else
+#include <linux/etherdevice.h>
+#endif
+#include "nf_native.h"
+
+static struct cs_fe_tuple to_tuple(const struct cs_ft_tuple *bytes)
+{
+	return (struct cs_fe_tuple){
+		.src = be32_to_cpu(bytes->src),
+		.dst = be32_to_cpu(bytes->dst),
+		.sport = be16_to_cpu(bytes->sport),
+		.dport = be16_to_cpu(bytes->dport),
+	};
+}
+
+static struct cs_fe_link to_link(const struct native_endpoint *endpoint)
+{
+	struct cs_fe_link link = {
+		.gmac = 1,
+		.cpu_port = 0,
+		.switch_port = endpoint->port,
+		.base_voq = 8,
+		.tag_mode = 4,
+	};
+
+	ether_addr_copy(link.base_mac, endpoint->mac);
+	return link;
+}
+
+enum native_reason native_rule_build(const struct cs_ft_nf_facts *facts,
+				     const struct native_endpoint *ingress,
+				     const struct native_endpoint *egress,
+				     const struct cs7542_rx_path *wire,
+				     struct cs7542_fe_native_request *request)
+{
+	const struct cs_ft_rewrite *rw = &facts->rewrite;
+	struct cs7542_fe_native_request next = {
+		.abi = facts->ip_proto == CS_FE_L4_TCP ? CS7542_FE_NATIVE_ABI :
+							 1,
+		.size = sizeof(next),
+	};
+	unsigned int reason;
+
+	if ((facts->ip_proto != CS_FE_L4_UDP &&
+	     facts->ip_proto != CS_FE_L4_TCP) ||
+	    !facts->routed_nf_context || !facts->ttl_decrement_from_context ||
+	    facts->extra_match_keys || facts->vlan_offset ||
+	    facts->cvlan_offset || !rw->nat_action || !rw->csum_action)
+		return NATIVE_MATCH;
+	if (facts->ingress_ifindex <= 0 || facts->egress_ifindex <= 0 ||
+	    ingress->ifindex != (unsigned int)facts->ingress_ifindex ||
+	    egress->ifindex != (unsigned int)facts->egress_ifindex ||
+	    ingress->port < 1 || ingress->port > 5 || egress->port < 1 ||
+	    egress->port > 5)
+		return NATIVE_PATH;
+	if (!wire || !is_valid_ether_addr(wire->source) ||
+	    !is_valid_ether_addr(wire->destination))
+		return NATIVE_WIRE;
+	if (!ether_addr_equal(wire->destination, ingress->mac) ||
+	    !ether_addr_equal(rw->smac, egress->mac))
+		return NATIVE_MAC;
+	reason = (wire->tag >> 6) & 31;
+	if (wire->tag_len != 4 || (wire->tag >> 14) != 2 ||
+	    (wire->tag & 7) != ingress->port || (wire->tag & 8) ||
+	    reason == 1 || reason == 2)
+		return NATIVE_TAG;
+
+	next.ingress_ifindex = ingress->ifindex;
+	next.egress_ifindex = egress->ifindex;
+	ether_addr_copy(next.ingress_smac, wire->source);
+	next.rule.native_l4proto = facts->ip_proto;
+	next.rule.original = to_tuple(&rw->before);
+	next.rule.translated = to_tuple(&rw->after);
+	next.rule.ingress = to_link(ingress);
+	next.rule.ingress.rx_qca_meta = wire->tag;
+	next.rule.egress = to_link(egress);
+	ether_addr_copy(next.rule.smac, rw->smac);
+	ether_addr_copy(next.rule.dmac, rw->dmac);
+	next.rule.decrement_ttl = true;
+	*request = next;
+	/* Owner confirmation is the next step. There is no installed entry yet. */
+	return NATIVE_OWNER;
+}
diff --git a/drivers/net/ethernet/cortina/flowtable/nf_native.h b/drivers/net/ethernet/cortina/flowtable/nf_native.h
new file mode 100644
index 000000000..cedd89727
--- /dev/null
+++ b/drivers/net/ethernet/cortina/flowtable/nf_native.h
@@ -0,0 +1,31 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS7542_NF_NATIVE_H
+#define CS7542_NF_NATIVE_H
+
+#include <linux/cs7542_fe_native.h>
+#include "cs7542_rx_path.h"
+#include "codec/cs_ft_rewrite.h"
+
+enum native_reason {
+	NATIVE_MATCH,
+	NATIVE_PATH,
+	NATIVE_WIRE,
+	NATIVE_MAC,
+	NATIVE_TAG,
+	NATIVE_OWNER,
+	NATIVE_INSTALLED,
+	NATIVE_REASONS
+};
+
+struct native_endpoint {
+	unsigned int ifindex, port;
+	u8 mac[6];
+};
+
+enum native_reason native_rule_build(const struct cs_ft_nf_facts *facts,
+				     const struct native_endpoint *ingress,
+				     const struct native_endpoint *egress,
+				     const struct cs7542_rx_path *wire,
+				     struct cs7542_fe_native_request *request);
+
+#endif

-- 
2.53.0

