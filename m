From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 23:50:32 +0300
Subject: [PATCH RFC net-next 4/7] net: cortina: add a serialized CS7542
 forwarding engine owner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-almondplus-offload-rfc-v1-4-703175c6340c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=274883;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=QtpXdEv+Zq1Vm4NNDYQqtN3+5f43yrXnfw9yK7qh3V0=;
 b=f8V3KjRkwjgMs4+Ws3IEE4z9bwCW2LL24H8224uVNU46FEawoQs/ZYgy60ulDSpL+GgqD3U5/
 iSLwyVbDngeAVRy3RV9Mxi4xu5KiX7ZqU+Sh5d3y51RdAz1ew5ZtEQp
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Attach hardware flowtable requests through the indirect conduit block
API. Retain DMA and register ownership in the Ethernet driver, with
bounded typed operations for a replaceable placement algorithm.

Verify the complete table image and exception guards before exposing a
lookup. Retain immutable results across lookup withdrawal: identical
actions can be shared and rebound, while incompatible actions fall back
when the eight-result pool is exhausted. Never treat invalidation as
proof of pipeline drain.

Only zero-to-one sticky HIT observations advance lastused. Active flows
can therefore refresh through the CPU on the normal Linux timeout. The
RFC keeps the development module attachment and checked-detach
interface; consolidation into the Ethernet driver remains open.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/net/ethernet/cortina/Kconfig               |  53 ++
 drivers/net/ethernet/cortina/Makefile              |  13 +-
 drivers/net/ethernet/cortina/cs752x_ne.c           | 120 +++
 drivers/net/ethernet/cortina/cs7542_fe_live.c      | 735 ++++++++++++++++
 drivers/net/ethernet/cortina/cs7542_ft_live.c      | 415 +++++++++
 drivers/net/ethernet/cortina/cs_fe_acl_encode.c    | 124 +++
 drivers/net/ethernet/cortina/cs_fe_acl_guard.c     | 324 +++++++
 drivers/net/ethernet/cortina/cs_fe_acl_guard.h     |  47 +
 drivers/net/ethernet/cortina/cs_fe_backend.h       | 228 +++++
 .../net/ethernet/cortina/cs_fe_backend_algorithm.c | 976 +++++++++++++++++++++
 .../net/ethernet/cortina/cs_fe_backend_dispatch.c  | 433 +++++++++
 .../net/ethernet/cortina/cs_fe_backend_module.c    | 164 ++++
 drivers/net/ethernet/cortina/cs_fe_encode.c        | 562 ++++++++++++
 drivers/net/ethernet/cortina/cs_fe_encode.h        |   5 +
 drivers/net/ethernet/cortina/cs_fe_fields.h        | 339 +++++++
 drivers/net/ethernet/cortina/cs_fe_format.h        |  23 +
 drivers/net/ethernet/cortina/cs_fe_hot.c           |  84 ++
 drivers/net/ethernet/cortina/cs_fe_hot.h           |  15 +
 drivers/net/ethernet/cortina/cs_fe_hot_access.c    | 276 ++++++
 drivers/net/ethernet/cortina/cs_fe_hot_access.h    |  55 ++
 drivers/net/ethernet/cortina/cs_fe_hot_codec.c     |   2 +
 drivers/net/ethernet/cortina/cs_fe_hot_compare.h   |  47 +
 drivers/net/ethernet/cortina/cs_fe_hot_internal.h  |  44 +
 drivers/net/ethernet/cortina/cs_fe_hot_lineage.c   | 138 +++
 drivers/net/ethernet/cortina/cs_fe_hot_lineage.h   |  70 ++
 drivers/net/ethernet/cortina/cs_fe_hot_tables.c    | 920 +++++++++++++++++++
 drivers/net/ethernet/cortina/cs_fe_native.inc      | 668 ++++++++++++++
 .../net/ethernet/cortina/cs_fe_native_activity.inc | 237 +++++
 drivers/net/ethernet/cortina/cs_fe_native_mtu.h    |  43 +
 drivers/net/ethernet/cortina/cs_fe_native_mtu.inc  | 128 +++
 drivers/net/ethernet/cortina/cs_fe_native_state.h  |  24 +
 include/linux/cs7542_fe_backend.h                  |  65 ++
 include/linux/cs7542_fe_codec.h                    | 145 +++
 include/linux/cs7542_fe_live.h                     |  58 ++
 include/linux/cs7542_fe_native.h                   |  34 +
 include/linux/cs7542_ft_live.h                     |  70 ++
 include/linux/dsa/qca8k_persistent.h               |  45 +
 37 files changed, 7728 insertions(+), 1 deletion(-)

diff --git a/drivers/net/ethernet/cortina/Kconfig b/drivers/net/ethernet/cortina/Kconfig
index 52c0683be..13df28071 100644
--- a/drivers/net/ethernet/cortina/Kconfig
+++ b/drivers/net/ethernet/cortina/Kconfig
@@ -35,3 +35,56 @@ config CS7542_ETHERNET
 	  cs7542-eth.
 
 endif # NET_VENDOR_CORTINA
+
+config CS7542_FT_LIVE_BRIDGE
+	bool "CS7542 hardware flowtable attachment"
+	depends on CS7542_ETHERNET=y && NET_DSA && MODULES && MODULE_UNLOAD
+	depends on !MODULE_FORCE_UNLOAD
+	default n
+	help
+	  Attach a flowtable frontend through the standard indirect block API.
+	  Packet DMA remains owned by the network engine driver.
+	  Only TC_SETUP_FT bindings are accepted. Ordinary traffic-control
+	  flower blocks cannot use this attachment to program the engine.
+
+config CS7542_FE_LIVE_OWNER
+	bool "CS7542 forwarding engine owner"
+	depends on CS7542_FT_LIVE_BRIDGE && !PM
+	depends on BRIDGE=y && INET && NETFILTER=y && NET_SWITCHDEV
+	default n
+	help
+	  Serialize forwarding-engine transactions with network-engine reset.
+	  Uncertain hardware state is retained until a verified reset.
+	  Rules use numeric leases under the same mutex as table access.
+	  Immutable action records remain allocated after lookup withdrawal.
+
+config CS7542_FE_HOT_BACKEND
+	bool "CS7542 replaceable forwarding backend"
+	depends on CS7542_FE_LIVE_OWNER && CS7542_ETHERNET=y
+	depends on MODULES && !MODULE_FORCE_UNLOAD
+	default n
+	help
+	  Keep table ownership in the built-in driver while a module supplies
+	  the placement algorithm. This RFC retains the replaceable backend
+	  used for hardware development; the module interface is not stable.
+	  MMIO and guard ownership never move into the replaceable module.
+
+config CS7542_FE_BACKEND
+	tristate "CS7542 forwarding placement backend"
+	depends on CS7542_FE_HOT_BACKEND && m
+	default n
+	help
+	  Install supported forwarding rules and retire their lookup selectors.
+	  Hardware uncertainty retains the module until checked detachment.
+	  The backend receives typed, bounded table operations from the owner.
+	  Retained actions can be shared or rebound only with identical contents.
+
+config CS7542_FE_WIRED
+	bool "CS7542 wired IPv4 TCP and UDP NAT"
+	depends on CS7542_FE_HOT_BACKEND
+	default n
+	help
+	  Accept hardware flowtable requests on the CS7542 wired DSA path.
+	  IPv6, Wi-Fi and unsupported policies continue through the CPU.
+	  TCP requires an established connection; SYN and FIN stay in software.
+	  Route, neighbor, MTU and tag state are checked before admission.
diff --git a/drivers/net/ethernet/cortina/Makefile b/drivers/net/ethernet/cortina/Makefile
index e998ffcc8..2bd0572d0 100644
--- a/drivers/net/ethernet/cortina/Makefile
+++ b/drivers/net/ethernet/cortina/Makefile
@@ -2,6 +2,17 @@
 # Makefile for the Cortina Gemini network device drivers.
 
 obj-$(CONFIG_GEMINI_ETHERNET) += gemini.o
-
 obj-$(CONFIG_CS7542_ETHERNET) += cs7542-eth.o
 cs7542-eth-y := cs752x_ne.o cs752x_fe.o cs752x_sch_tm.o
+
+obj-$(CONFIG_CS7542_FT_LIVE_BRIDGE) += cs7542_ft_live.o
+cs7542-eth-$(CONFIG_CS7542_FE_LIVE_OWNER) += cs7542_fe_live.o cs_fe_encode.o cs_fe_acl_guard.o cs_fe_acl_encode.o cs_fe_hot.o
+
+ifeq ($(CONFIG_CS7542_FE_HOT_BACKEND),y)
+cs7542-eth-y += cs_fe_backend_dispatch.o cs_fe_hot_tables.o cs_fe_hot_access.o cs_fe_hot_lineage.o
+else
+cs7542-eth-$(CONFIG_CS7542_FE_LIVE_OWNER) += cs_fe_backend.o
+endif
+obj-$(CONFIG_CS7542_FE_BACKEND) += cs7542_fe_backend.o
+cs7542_fe_backend-y := cs_fe_backend_module.o cs_fe_backend_algorithm.o cs_fe_hot_codec.o
+
diff --git a/drivers/net/ethernet/cortina/cs752x_ne.c b/drivers/net/ethernet/cortina/cs752x_ne.c
index 081b42079..d6933fc1b 100644
--- a/drivers/net/ethernet/cortina/cs752x_ne.c
+++ b/drivers/net/ethernet/cortina/cs752x_ne.c
@@ -27,6 +27,13 @@
 #include <linux/xarray.h>
 
 #include "cs752x_ne.h"
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+#include <linux/cs7542_ft_live.h>
+#endif
+
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+#include <linux/cs7542_fe_live.h>
+#endif
 
 #define CS_NE_PORTS			3
 #define CS_NE_RX_INSTANCES		9
@@ -249,6 +256,10 @@ struct cs_ne_txq {
 };
 
 struct cs_ne_port {
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+	struct cs7542_ft_live *live;
+#endif
+
 	struct cs_ne *ne;
 	struct net_device *ndev;
 	struct device_node *np;
@@ -273,6 +284,9 @@ static const char * const cs_ne_reset_names[CS_NE_NUM_RESETS] = {
 };
 
 struct cs_ne {
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	struct cs7542_fe_live *fe_live;
+#endif
 	struct device *dev;
 	/* Shared NI registers contain fields belonging to several MACs. */
 	spinlock_t ni_lock;
@@ -1458,7 +1472,33 @@ static const struct ethtool_ops cs_ne_ethtool_ops = {
 	.set_link_ksettings = cs_ne_set_link_ksettings,
 };
 
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+static int cs_ne_live_setup_tc(struct net_device *dev, enum tc_setup_type type,
+			       void *data)
+{
+	struct cs_ne_port *port = netdev_priv(dev);
+
+	return cs7542_ft_live_setup(port->live, type, data);
+}
+
+static ssize_t private_ft_live_show(struct device *dev,
+				    struct device_attribute *attr, char *buffer)
+{
+	struct cs_ne_port *port = netdev_priv(to_net_dev(dev));
+
+	return cs7542_ft_live_format(port->live, buffer);
+}
+
+static DEVICE_ATTR_RO(private_ft_live);
+static struct attribute *cs_live_attrs[] = { &dev_attr_private_ft_live.attr,
+					     NULL };
+static const struct attribute_group cs_live_group = { .attrs = cs_live_attrs };
+#endif
+
 static const struct net_device_ops cs_ne_netdev_ops = {
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+	.ndo_setup_tc = cs_ne_live_setup_tc,
+#endif
 	.ndo_open = cs_ne_open,
 	.ndo_stop = cs_ne_stop,
 	.ndo_start_xmit = cs_ne_start_xmit,
@@ -1471,8 +1511,24 @@ static void cs_ne_port_cleanup(void *data)
 {
 	struct cs_ne_port *port = data;
 
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	cs7542_fe_live_unbind(port->ne->fe_live, port->ndev, port->id);
+#endif
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+	/*
+	 * Drain callbacks before unregister stops the port and owner.
+	 * The FE API rejects later MMIO after terminal/reset.
+	 */
+	if (cs7542_ft_live_quiesce(port->live))
+		dev_err(port->ne->dev,
+			"live provider withdrawal uncertain; retained module pin\n");
+#endif
 	if (port->registered)
 		unregister_netdev(port->ndev);
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+	cs7542_ft_live_put(port->live);
+	port->live = NULL;
+#endif
 	phylink_destroy(port->phylink);
 	netif_napi_del(&port->napi);
 	/* The shared completion poll can outlive a closed port. */
@@ -1547,6 +1603,17 @@ static int cs_ne_probe_port(struct cs_ne *ne, struct device_node *np)
 	ret = devm_add_action_or_reset(dev, cs_ne_port_cleanup, port);
 	if (ret)
 		return ret;
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+	if (id == 1) {
+		port->live = cs7542_ft_live_create(ndev, id);
+		if (IS_ERR(port->live)) {
+			ret = PTR_ERR(port->live);
+			port->live = NULL;
+			return ret;
+		}
+		ndev->sysfs_groups[0] = &cs_live_group;
+	}
+#endif
 
 	cs_ne_port_hw_init(port);
 	cs_ne_set_hw_addr(port);
@@ -1612,6 +1679,18 @@ static void cs_ne_context_release(void *data)
 	kfree(ne);
 }
 
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+static void cs_ne_live_release(void *data)
+{
+	struct cs_ne *ne = data;
+
+	cs7542_fe_live_stop(ne->fe_live);
+	cs7542_fe_live_put(ne->fe_live);
+	ne->fe_live = NULL;
+}
+
+#endif
+
 /* All ports/IRQs/NAPI have been removed before this action runs. */
 static void cs_ne_hw_cleanup(void *data)
 {
@@ -1623,6 +1702,10 @@ static void cs_ne_hw_cleanup(void *data)
 	if (ne->hw_cleanup_done)
 		return;
 	ne->hw_cleanup_done = true;
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	/* Port cleanup drained the bridge before the owner becomes terminal. */
+	cs7542_fe_live_stop(ne->fe_live);
+#endif
 	cs_ne_rx_cancel_retry(ne);
 	cs_ne_tx_cancel_timer(txq);
 	if (ne->hw_accessible) {
@@ -1635,6 +1718,10 @@ static void cs_ne_hw_cleanup(void *data)
 
 	/* The entire owned NE + LSO/SSP domain stays reset through release. */
 	ret = cs_ne_assert_resets(ne);
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	if (!ret)
+		cs7542_fe_live_reset_done(ne->fe_live);
+#endif
 	if (ret && ne->hw_active) {
 		ne->dma_pinned = true;
 		return;
@@ -1770,6 +1857,18 @@ static int cs_ne_probe(struct platform_device *pdev)
 		}
 	}
 
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	ne->fe_live = cs7542_fe_live_create(dev, ne->fe,
+		min_t(resource_size_t,
+		      resource_size(platform_get_resource_byname(pdev, IORESOURCE_MEM, "fe")),
+		      UINT_MAX));
+	if (IS_ERR(ne->fe_live))
+		return PTR_ERR(ne->fe_live);
+	ret = devm_add_action_or_reset(dev, cs_ne_live_release, ne);
+	if (ret)
+		return ret;
+#endif
+
 	/* No hardware state needs unwinding until the first reset attempt. */
 	ret = devm_add_action(dev, cs_ne_hw_cleanup, ne);
 	if (ret)
@@ -1800,7 +1899,11 @@ static int cs_ne_probe(struct platform_device *pdev)
 	ret = cs752x_tm_init(dev, ne->tm);
 	if (ret)
 		return dev_err_probe(dev, ret, "TM init failed\n");
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	ret = cs7542_fe_live_init(ne->fe_live, cs752x_fe_init);
+#else
 	ret = cs752x_fe_init(dev, ne->fe);
+#endif
 	if (ret)
 		return dev_err_probe(dev, ret, "FE init failed\n");
 	writel(readl(ne->fe + FETOP_FE_PRSR_CFG_0) & ~FE_L4_CHKSUM_CHK_DISABLE,
@@ -1821,6 +1924,15 @@ static int cs_ne_probe(struct platform_device *pdev)
 	if (!nports)
 		return -ENODEV;
 
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	for (i = 0; i < CS_NE_PORTS; i++) {
+		if (!ne->ports[i])
+			continue;
+		ret = cs7542_fe_live_bind(ne->fe_live, ne->ports[i]->ndev, i);
+		if (ret)
+			return ret;
+	}
+#endif
 	/* No netdev may open while the shared pools are only partly prepared. */
 	rtnl_lock();
 	for (i = 0; i < CS_NE_PORTS; i++) {
@@ -1834,6 +1946,9 @@ static int cs_ne_probe(struct platform_device *pdev)
 
 	/* Cleanup must revoke hardware references before releasing any mappings. */
 	ne->hw_active = true;
+#ifdef CONFIG_CS7542_FE_LIVE_OWNER
+	cs7542_fe_live_activate(ne->fe_live);
+#endif
 	/* There are no fallible probe operations after publishing DMA addresses. */
 	spin_lock_irq(&ne->rx_lock);
 	ne->rx_stopping = false;
@@ -1852,6 +1967,7 @@ static const struct of_device_id cs_ne_of_match[] = {
 	{ .compatible = "cortina,cs7542-ethernet" },
 	{ }
 };
+
 MODULE_DEVICE_TABLE(of, cs_ne_of_match);
 
 static struct platform_driver cs_ne_driver = {
@@ -1860,9 +1976,13 @@ static struct platform_driver cs_ne_driver = {
 	.shutdown = cs_ne_shutdown,
 	.driver = {
 		.name = "cs7542-ethernet",
+#ifdef CONFIG_CS7542_FT_LIVE_BRIDGE
+		.suppress_bind_attrs = true,
+#endif
 		.of_match_table = cs_ne_of_match,
 	},
 };
+
 module_platform_driver(cs_ne_driver);
 
 MODULE_DESCRIPTION("Cortina CS7542 network engine driver");
diff --git a/drivers/net/ethernet/cortina/cs7542_fe_live.c b/drivers/net/ethernet/cortina/cs7542_fe_live.c
new file mode 100644
index 000000000..a2de22061
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs7542_fe_live.c
@@ -0,0 +1,735 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Built-in sole FE owner. Only typed numeric requests cross the module ABI. */
+#include <linux/device.h>
+#include <linux/etherdevice.h>
+#include <linux/err.h>
+#include <linux/export.h>
+#include <linux/io.h>
+#include <linux/kref.h>
+#include <linux/ktime.h>
+#include <linux/list.h>
+#include <linux/math64.h>
+#include <linux/mutex.h>
+#include <linux/netdevice.h>
+#include <linux/slab.h>
+#include <linux/rtnetlink.h>
+#include <linux/skbuff.h>
+#include <linux/spinlock.h>
+#include <linux/workqueue.h>
+#include <linux/cs7542_fe_live.h>
+#include <linux/dsa/qca8k_persistent.h>
+#include <linux/of.h>
+#include <net/dsa.h>
+#include <net/route.h>
+#include <net/arp.h>
+#include <linux/capability.h>
+#include "cs_fe_hot.h"
+#include "cs_fe_backend.h"
+#define CS_FE_NATIVE_AVAILABLE                                            \
+	(IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND) &&                      \
+	 IS_BUILTIN(CONFIG_BRIDGE) && IS_ENABLED(CONFIG_NET_SWITCHDEV) && \
+	 IS_BUILTIN(CONFIG_INET) && IS_BUILTIN(CONFIG_NETFILTER))
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+#include "cs_fe_hot_internal.h"
+#endif
+#if CS_FE_NATIVE_AVAILABLE
+#include "cs_fe_native_state.h"
+#endif
+#include "cs_fe_acl_guard.h"
+
+#define CS_FE_LIVE_PORTS 3
+struct cs7542_fe_live {
+	struct list_head node;
+	struct kref refs;
+	struct mutex lock;
+	struct device *dev;
+	struct net_device *ports[CS_FE_LIVE_PORTS];
+	void __iomem *base;
+	unsigned int extent;
+	bool initialized, online, closing, reset_verified, quarantine_ref;
+	u64 epoch;
+	struct cs7542_fe_hot_sample hot_before[CS_FE_BACKEND_LEASES];
+	struct cs7542_fe_hot_sample hot_after[CS_FE_BACKEND_LEASES];
+	struct cs_fe_backend backend;
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+	struct cs_fe_hot_state hot_state;
+#endif
+#if CS_FE_NATIVE_AVAILABLE
+	struct cs_fe_native_state native;
+#endif
+	struct cs_fe_acl_guard guard[CS_FE_BACKEND_LEASES];
+};
+
+static int cs_fe_live_guard_prepare(void *context,
+				    const struct cs_fe_backend_io *io,
+				    unsigned int lease,
+				    const struct cs_fe_rows *rows,
+				    const struct cs_fe_plan *plan,
+				    unsigned long long end_us);
+static int cs_fe_live_guard_rearm(void *context,
+				  const struct cs_fe_backend_io *io,
+				  unsigned int lease,
+				  const struct cs_fe_rows *rows,
+				  const struct cs_fe_plan *plan,
+				  unsigned long long end_us);
+static int cs_fe_live_guard_withdraw(void *context,
+				     const struct cs_fe_backend_io *io,
+				     unsigned int lease,
+				     const struct cs_fe_rows *rows,
+				     const struct cs_fe_plan *plan,
+				     unsigned long long end_us);
+static void cs_fe_live_before_withdraw(void *context,
+				       const struct cs_fe_backend_io *io,
+				       unsigned int lease,
+				       const struct cs_fe_plan *plan,
+				       unsigned long long end_us);
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+static bool cs_fe_live_hot_guards_ready(void *context, unsigned int slot);
+#endif
+#if CS_FE_NATIVE_AVAILABLE
+static int cs_fe_native_range(void *context, bool prepare, u8 range_bit,
+			      unsigned long long end);
+static void cs_fe_native_prune(struct cs7542_fe_live *owner);
+#else
+static inline void cs_fe_native_prune(struct cs7542_fe_live *owner)
+{
+}
+
+#endif
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+static int cs_fe_live_hot_guards_rebind(void *context, unsigned int slot,
+					const u32 *old_invalid,
+					const u32 *new_invalid,
+					unsigned long long end, bool commit);
+#endif
+static LIST_HEAD(cs_fe_live_owners);
+static DEFINE_MUTEX(cs_fe_live_owners_lock);
+
+static void cs_fe_live_release(struct kref *ref)
+{
+	struct cs7542_fe_live *owner =
+		container_of(ref, struct cs7542_fe_live, refs);
+
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+	mutex_lock(&cs_fe_live_owners_lock);
+	list_del_init(&owner->node);
+	mutex_unlock(&cs_fe_live_owners_lock);
+#else
+	WARN_ON(!list_empty(&owner->node));
+#endif
+	WARN_ON(owner->quarantine_ref);
+	put_device(owner->dev);
+	kvfree(owner);
+}
+
+void cs7542_fe_live_put(struct cs7542_fe_live *owner)
+{
+	if (owner)
+		kref_put(&owner->refs, cs_fe_live_release);
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_put);
+
+struct cs7542_fe_live *cs7542_fe_live_create(struct device *dev,
+					     void __iomem *base,
+					     unsigned int extent)
+{
+	struct cs7542_fe_live *owner;
+
+	if (!dev || !base || extent < 0x2080)
+		return ERR_PTR(-EINVAL);
+	owner = kvzalloc_obj(*owner);
+	if (!owner)
+		return ERR_PTR(-ENOMEM);
+	INIT_LIST_HEAD(&owner->node);
+	kref_init(&owner->refs);
+	mutex_init(&owner->lock);
+	owner->dev = get_device(dev);
+	owner->base = base;
+	owner->extent = extent;
+	owner->epoch = 1;
+	/* Routing hardware admission is closed, including in this live lab. */
+	cs_fe_backend_init(&owner->backend, 0);
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+	owner->backend.hot_state = &owner->hot_state;
+	owner->hot_state.guards_ready = cs_fe_live_hot_guards_ready;
+#if CS_FE_NATIVE_AVAILABLE
+	owner->hot_state.native_range = cs_fe_native_range;
+#endif
+	owner->hot_state.guards_rebind = cs_fe_live_hot_guards_rebind;
+	owner->hot_state.guard_context = owner;
+#endif
+	owner->backend.guard_prepare = cs_fe_live_guard_prepare;
+	owner->backend.guard_withdraw = cs_fe_live_guard_withdraw;
+	owner->backend.guard_rearm = cs_fe_live_guard_rearm;
+	owner->backend.guard_context = owner;
+	owner->backend.before_withdraw = cs_fe_live_before_withdraw;
+	mutex_lock(&cs_fe_live_owners_lock);
+	list_add_tail(&owner->node, &cs_fe_live_owners);
+	mutex_unlock(&cs_fe_live_owners_lock);
+	return owner;
+}
+
+int cs7542_fe_live_init(struct cs7542_fe_live *owner,
+			int (*initialize)(struct device *, void __iomem *))
+{
+	int error;
+
+	if (!owner || !initialize)
+		return -EINVAL;
+	mutex_lock(&owner->lock);
+	if (owner->closing || owner->initialized || !owner->base)
+		error = -EBUSY;
+	else {
+		error = initialize(owner->dev, owner->base);
+		if (!error)
+			owner->initialized = true;
+		else
+			owner->backend.poisoned = true;
+	}
+	mutex_unlock(&owner->lock);
+	return error;
+}
+
+void cs7542_fe_live_activate(struct cs7542_fe_live *owner)
+{
+	mutex_lock(&owner->lock);
+	if (owner->initialized && !owner->closing && !owner->backend.poisoned)
+		owner->online = true;
+	mutex_unlock(&owner->lock);
+}
+
+int cs7542_fe_live_bind(struct cs7542_fe_live *owner,
+			struct net_device *conduit, unsigned int gmac)
+{
+	int error = 0;
+
+	if (!owner || !conduit || gmac >= CS_FE_LIVE_PORTS)
+		return -EINVAL;
+	mutex_lock(&cs_fe_live_owners_lock);
+	mutex_lock(&owner->lock);
+	if (owner->closing || owner->ports[gmac])
+		error = -EBUSY;
+	else {
+		dev_hold(conduit);
+		owner->ports[gmac] = conduit;
+	}
+	mutex_unlock(&owner->lock);
+	mutex_unlock(&cs_fe_live_owners_lock);
+	return error;
+}
+
+/*
+ * Drop the engine's conduit ref BEFORE unregister_netdev waits for refs.
+ *
+ * Existing holders may still withdraw under the owner lock; new arms cannot
+ * acquire this port or commit after it has been detached from the registry.
+ */
+void cs7542_fe_live_unbind(struct cs7542_fe_live *owner,
+			   struct net_device *conduit, unsigned int gmac)
+{
+	struct net_device *held = NULL;
+
+	if (!owner || gmac >= CS_FE_LIVE_PORTS)
+		return;
+	mutex_lock(&cs_fe_live_owners_lock);
+	mutex_lock(&owner->lock);
+	if (owner->ports[gmac] == conduit) {
+		held = owner->ports[gmac];
+		owner->ports[gmac] = NULL;
+	}
+	mutex_unlock(&owner->lock);
+	mutex_unlock(&cs_fe_live_owners_lock);
+	if (held)
+		dev_put(held);
+}
+
+struct cs7542_fe_live *cs7542_fe_live_get(struct net_device *conduit)
+{
+	struct cs7542_fe_live *owner, *found = ERR_PTR(-ENODEV);
+
+	if (!conduit)
+		return ERR_PTR(-EINVAL);
+	mutex_lock(&cs_fe_live_owners_lock);
+	list_for_each_entry(owner, &cs_fe_live_owners, node) {
+		/* Only the physically studied GMAC1 is a current candidate. */
+		if (owner->ports[1] != conduit)
+			continue;
+		if (!READ_ONCE(owner->online) || READ_ONCE(owner->closing))
+			found = ERR_PTR(-ESHUTDOWN);
+		else {
+			kref_get(&owner->refs);
+			found = owner;
+		}
+		break;
+	}
+	mutex_unlock(&cs_fe_live_owners_lock);
+	return found;
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_get);
+
+static unsigned long long cs_fe_live_now(void *context)
+{
+	return div_u64(ktime_get_ns(), 1000);
+}
+
+static int cs_fe_live_read(void *context, unsigned int offset, u32 *value)
+{
+	struct cs7542_fe_live *owner = context;
+
+	if (!owner->base || owner->closing)
+		return -ESHUTDOWN;
+	if ((offset & 3) || offset > owner->extent - 4)
+		return -ERANGE;
+	*value = readl(owner->base + offset);
+	return 0;
+}
+
+static int cs_fe_live_write(void *context, unsigned int offset, u32 value)
+{
+	struct cs7542_fe_live *owner = context;
+
+	if (!owner->base || owner->closing)
+		return -ESHUTDOWN;
+	if ((offset & 3) || offset > owner->extent - 4)
+		return -ERANGE;
+	writel(value, owner->base + offset);
+	return 0;
+}
+
+static struct cs_fe_backend_io cs_fe_live_io(struct cs7542_fe_live *owner)
+{
+	struct cs_fe_backend_io io = {
+		.context = owner,
+		.extent = owner->extent,
+		.now_us = cs_fe_live_now,
+		.read32 = cs_fe_live_read,
+		.write32 = cs_fe_live_write,
+	};
+	return io;
+}
+
+/*
+ * These callbacks run inside the SAME backend owner transaction/mutex.
+ *
+ * No RTNL acquisition, second scratch owner, new budget or user selector.
+ */
+static int cs_fe_live_guard_prepare(void *context,
+				    const struct cs_fe_backend_io *io,
+				    unsigned int lease,
+				    const struct cs_fe_rows *rows,
+				    const struct cs_fe_plan *plan,
+				    unsigned long long end_us)
+{
+	struct cs7542_fe_live *owner = context;
+	struct cs_fe_backend_io bounded = cs_fe_live_io(owner);
+
+	if (lease >= CS_FE_BACKEND_LEASES || rows->class_row != 5 + lease ||
+	    rows->sdb_row != rows->class_row ||
+	    (plan->sdb.expected[6] & (1U << 13)) ||
+	    (plan->hit.expected[2] & (1U << 29)) ||
+	    ((plan->sdb.expected[0] >> 7) & 15) >= 7)
+		return -EOPNOTSUPP;
+	bounded.limit_us =
+		io->limit_us && io->limit_us < end_us ? io->limit_us : end_us;
+	{
+		int error = cs_fe_acl_prepare(&owner->guard[lease], &bounded,
+					      lease, rows->class_row,
+					      plan->class_invalid.expected);
+
+		if (!error)
+			(void)cs_fe_hot_read(&bounded, plan->key.bucket,
+					     &owner->hot_before[lease]);
+		return error;
+	}
+}
+
+static int cs_fe_live_guard_withdraw(void *context,
+				     const struct cs_fe_backend_io *io,
+				     unsigned int lease,
+				     const struct cs_fe_rows *rows,
+				     const struct cs_fe_plan *plan,
+				     unsigned long long end_us)
+{
+	struct cs7542_fe_live *owner = context;
+	struct cs_fe_backend_io bounded = cs_fe_live_io(owner);
+
+	if (lease >= CS_FE_BACKEND_LEASES ||
+	    owner->guard[lease].class_id != rows->class_row ||
+	    memcmp(owner->guard[lease].class_invalid,
+		   plan->class_invalid.expected,
+		   sizeof(owner->guard[lease].class_invalid)))
+		return -EUCLEAN;
+	bounded.limit_us =
+		io->limit_us && io->limit_us < end_us ? io->limit_us : end_us;
+	{
+		int error;
+
+		if (owner->backend.lease[lease].scoped) {
+			/*
+			 * Keep traps valid even after CLASS invalidation: in-flight old packets
+			 * must not lose exceptions, and identical rearm never changes them.
+			 */
+			error = cs_fe_acl_verify_retained(&owner->guard[lease], &bounded, lease,
+				rows->class_row, plan->class_invalid.expected);
+		} else {
+			error = cs_fe_acl_disarm(&owner->guard[lease],
+						 &bounded);
+		}
+
+		return error;
+	}
+}
+
+static int
+
+cs_fe_live_guard_rearm(void *context, const struct cs_fe_backend_io *io,
+		       unsigned int lease, const struct cs_fe_rows *rows,
+		       const struct cs_fe_plan *plan, unsigned long long end_us)
+{
+	struct cs7542_fe_live *owner = context;
+	struct cs_fe_backend_io bounded = cs_fe_live_io(owner);
+	int error;
+
+	if (lease >= CS_FE_BACKEND_LEASES ||
+	    !owner->backend.lease[lease].scoped ||
+	    owner->backend.lease[lease].marker)
+		return -EOPNOTSUPP;
+	bounded.limit_us =
+		io->limit_us && io->limit_us < end_us ? io->limit_us : end_us;
+	error = cs_fe_acl_verify_retained(&owner->guard[lease], &bounded, lease,
+					  rows->class_row,
+					  plan->class_invalid.expected);
+	if (!error) {
+		memset(&owner->hot_after[lease], 0,
+		       sizeof(owner->hot_after[lease]));
+		(void)cs_fe_hot_read(&bounded, plan->key.bucket,
+				     &owner->hot_before[lease]);
+	}
+	return error;
+}
+
+/*
+ * Main-table allocator ONLY publishes way0/slot0; no overflow lease exists.
+ * Snapshot activity BEFORE any HASH/CLASS invalidation, no bitmap clear.
+ */
+static void cs_fe_live_before_withdraw(void *context,
+				       const struct cs_fe_backend_io *io,
+				       unsigned int lease,
+				       const struct cs_fe_plan *plan,
+				       unsigned long long end_us)
+{
+	struct cs7542_fe_live *owner = context;
+	struct cs_fe_backend_io bounded = cs_fe_live_io(owner);
+
+	bounded.limit_us =
+		io->limit_us && io->limit_us < end_us ? io->limit_us : end_us;
+	if (lease < CS_FE_BACKEND_LEASES)
+		(void)cs_fe_hot_read(&bounded, plan->key.bucket,
+				     &owner->hot_after[lease]);
+}
+
+static int cs_fe_live_ready(struct cs7542_fe_live *owner)
+{
+	if (!owner->online || owner->closing || !owner->base)
+		return -ENODEV;
+	return owner->backend.poisoned ? -EIO : 0;
+}
+
+static void cs_fe_live_pin(struct cs7542_fe_live *owner)
+{
+	/*
+	 * Caller and engine refs cover the complete transaction before this point.
+	 * Pin persistent numeric leases before releasing the sole owner mutex.
+	 */
+	bool guard_written = false;
+	unsigned int i;
+
+	for (i = 0; i < CS_FE_BACKEND_LEASES; i++)
+		guard_written |= owner->guard[i].written;
+#if CS_FE_NATIVE_AVAILABLE
+	for (i = 0; i < ARRAY_SIZE(owner->native.range); i++)
+		guard_written |= owner->native.range[i].touched;
+#endif
+	if ((owner->backend.next_lease || guard_written) &&
+	    !owner->quarantine_ref) {
+		kref_get(&owner->refs);
+		owner->quarantine_ref = true;
+	}
+}
+
+int cs7542_fe_live_open(struct cs7542_fe_live *owner, u64 *block)
+{
+	unsigned long long handle = 0;
+	int error;
+
+	if (!owner || !block)
+		return -EINVAL;
+	mutex_lock(&owner->lock);
+	error = cs_fe_live_ready(owner);
+	if (!error)
+		error = owner->ports[1] ?
+				cs_fe_backend_block_open(&owner->backend,
+							 &handle) :
+				-ESHUTDOWN;
+	if (!error)
+		*block = handle;
+	mutex_unlock(&owner->lock);
+	return error;
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_open);
+
+static int cs_fe_live_end(struct cs7542_fe_live *owner, u64 block,
+			  unsigned long cookie, u64 version, int reason,
+			  bool rejection)
+{
+	struct cs_fe_backend_io io;
+	int error;
+
+	if (!owner)
+		return -EINVAL;
+	mutex_lock(&owner->lock);
+	error = cs_fe_live_ready(owner);
+	if (!error) {
+		io = cs_fe_live_io(owner);
+		if (rejection)
+			error = cs_fe_backend_reject(&owner->backend, &io,
+						     block, cookie, version,
+						     reason);
+		else
+			error = cs_fe_backend_destroy(&owner->backend, &io,
+						      block, cookie, version);
+		cs_fe_live_pin(owner);
+	}
+	cs_fe_native_prune(owner);
+	mutex_unlock(&owner->lock);
+	return error;
+}
+
+int cs7542_fe_live_reject(struct cs7542_fe_live *owner, u64 block,
+			  unsigned long cookie, u64 version, int reason)
+{
+	return cs_fe_live_end(owner, block, cookie, version, reason, true);
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_reject);
+
+int cs7542_fe_live_destroy(struct cs7542_fe_live *owner, u64 block,
+			   unsigned long cookie, u64 version)
+{
+	return cs_fe_live_end(owner, block, cookie, version, 0, false);
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_destroy);
+
+int cs7542_fe_live_close(struct cs7542_fe_live *owner, u64 block)
+{
+	struct cs_fe_backend_io io;
+	int error;
+
+	if (!owner)
+		return -EINVAL;
+	mutex_lock(&owner->lock);
+	if (owner->reset_verified)
+		error = 0; /* Complete reset proof, never an I/O attempt on dead mappings. */
+	else {
+		error = cs_fe_live_ready(owner);
+		if (!error) {
+			io = cs_fe_live_io(owner);
+			error = cs_fe_backend_unbind(&owner->backend, &io,
+						     block);
+			if (!error)
+				error = cs_fe_backend_forget(&owner->backend,
+							     block);
+		}
+	}
+	cs_fe_native_prune(owner);
+	mutex_unlock(&owner->lock);
+	return error;
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_close);
+
+int cs7542_fe_live_status(struct cs7542_fe_live *owner,
+			  struct cs7542_fe_live_status *status)
+{
+	unsigned int index;
+
+	if (!owner || !status)
+		return -EINVAL;
+	mutex_lock(&owner->lock);
+	memset(status, 0, sizeof(*status));
+	status->epoch = owner->epoch;
+	status->online = owner->online;
+	status->closing = owner->closing;
+	status->reset_verified = owner->reset_verified;
+	status->poisoned = owner->backend.poisoned;
+	status->pending = owner->backend.pending;
+	status->first_error = owner->backend.first_error;
+	status->leases = owner->backend.next_lease;
+	status->capacity = CS_FE_BACKEND_LEASES;
+	status->admitted_requirements = owner->backend.admitted_requirements;
+	for (index = 0; index < CS_FE_BACKEND_BLOCKS; index++)
+		status->blocks += !!owner->backend.block[index].identity;
+	mutex_unlock(&owner->lock);
+	return 0;
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_status);
+
+void cs7542_fe_live_stop(struct cs7542_fe_live *owner)
+{
+	struct net_device *ports[CS_FE_LIVE_PORTS];
+	unsigned int index;
+
+	if (!owner)
+		return;
+	mutex_lock(&owner->lock);
+	owner->closing = true;
+	owner->online = false;
+	mutex_unlock(&owner->lock);
+	mutex_lock(&cs_fe_live_owners_lock);
+	mutex_lock(&owner->lock);
+#if !IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+	list_del_init(&owner->node);
+#endif
+	owner->online = false;
+	owner->closing = true;
+	owner->base = NULL;
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+	owner->hot_state.ledger.blocked = true;
+#endif
+	memcpy(ports, owner->ports, sizeof(ports));
+	memset(owner->ports, 0, sizeof(owner->ports));
+	mutex_unlock(&owner->lock);
+	mutex_unlock(&cs_fe_live_owners_lock);
+	for (index = 0; index < CS_FE_LIVE_PORTS; index++)
+		if (ports[index])
+			dev_put(ports[index]);
+}
+
+void cs7542_fe_live_reset_done(struct cs7542_fe_live *owner)
+{
+	bool drop = false;
+
+	if (!owner)
+		return;
+	mutex_lock(&owner->lock);
+	if (WARN_ON(!owner->closing))
+		goto unlock;
+	owner->reset_verified = true;
+	cs_fe_native_prune(owner);
+	owner->epoch++;
+	if (owner->quarantine_ref) {
+		owner->quarantine_ref = false;
+		drop = true;
+	}
+unlock:
+	mutex_unlock(&owner->lock);
+	if (drop)
+		cs7542_fe_live_put(owner);
+}
+
+#if CS_FE_NATIVE_AVAILABLE
+#include "cs_fe_native.inc"
+#endif
+
+#if IS_ENABLED(CONFIG_CS7542_FE_HOT_BACKEND)
+static bool cs_fe_live_hot_guards_ready(void *context, unsigned int slot)
+{
+	struct cs7542_fe_live *owner = context;
+	struct cs_fe_acl_guard *guard;
+
+	lockdep_assert_held(&owner->lock);
+	if (slot >= CS_FE_BACKEND_LEASES || owner->closing || !owner->base)
+		return false;
+	guard = &owner->guard[slot];
+	return guard->ready && guard->exposed && !guard->pending &&
+	       !guard->poisoned;
+}
+
+/* Same owner lock and original absolute deadline; no ACL writes/reallocation. */
+static int cs_fe_live_hot_guards_rebind(void *context, unsigned int slot,
+					const u32 *old_invalid,
+					const u32 *new_invalid,
+					unsigned long long end, bool commit)
+{
+	struct cs7542_fe_live *owner = context;
+	struct cs_fe_acl_guard *guard;
+	struct cs_fe_backend_io bounded;
+
+	lockdep_assert_held(&owner->lock);
+	if (!cs_fe_live_hot_guards_ready(context, slot))
+		return -EUCLEAN;
+	guard = &owner->guard[slot];
+	if (memcmp(guard->class_invalid, old_invalid,
+		   sizeof(guard->class_invalid)))
+		return -ESTALE;
+	bounded = cs_fe_live_io(owner);
+	bounded.limit_us = end;
+	if (!commit)
+		return cs_fe_acl_verify_retained(guard, &bounded, slot,
+						 5 + slot, old_invalid);
+	/*
+	 * Tables executor has just verified the complete new CLASS-invalid image.
+	 * Preserve every trap record and all error/history fields.
+	 */
+	if (guard->retained_records != 1 + 2 * CS_ACL_KINDS ||
+	    guard->retained[0].table != CS_ACL_CLASS ||
+	    guard->retained[0].row != 5 + slot ||
+	    guard->retained[0].complete != 20 || guard->retained[0].error ||
+	    memcmp(guard->retained[0].raw, old_invalid,
+		   sizeof(guard->class_invalid)))
+		return -EUCLEAN;
+	memcpy(guard->class_invalid, new_invalid, sizeof(guard->class_invalid));
+	memcpy(guard->retained[0].raw, new_invalid,
+	       sizeof(guard->class_invalid));
+	return 0;
+}
+
+int cs_fe_live_hot_idle(unsigned int *contexts, unsigned int *leases,
+			bool verify)
+{
+	struct cs7542_fe_live *owner;
+	int first = 0;
+
+	*contexts = *leases = 0;
+	mutex_lock(&cs_fe_live_owners_lock);
+	list_for_each_entry(owner, &cs_fe_live_owners, node) {
+		struct cs_fe_backend_io io;
+		unsigned int index;
+		int error = 0;
+
+		mutex_lock(&owner->lock);
+		(*contexts)++;
+		*leases += owner->backend.next_lease;
+		if (owner->reset_verified)
+			goto next; /* Actual full NE reset, not a module-reset fiction. */
+		if (owner->backend.pending || owner->backend.poisoned ||
+		    owner->hot_state.ledger.pending)
+			error = -EBUSY;
+		for (index = 0; !error && index < CS_FE_BACKEND_BLOCKS; index++)
+			if (owner->backend.block[index].identity)
+				error = -EBUSY;
+		for (index = 0; !error && index < CS_FE_BACKEND_ENTRIES;
+		     index++)
+			if (owner->backend.entry[index].active)
+				error = -EBUSY;
+		for (index = 0; !error && index < CS_FE_HOT_SLOTS; index++) {
+			if (owner->backend.lease[index].active ||
+			    owner->hot_state.binding[index].visible ||
+			    owner->hot_state.binding[index].hash_present)
+				error = -EBUSY;
+			if (owner->hot_state.ledger.slots[index].claimed &&
+			    (owner->closing || !owner->base || !owner->online))
+				error = -ESHUTDOWN;
+		}
+		if (!error && verify && owner->base && owner->online) {
+			io = cs_fe_live_io(owner);
+			error = cs_fe_hot_verify_idle(&owner->backend, &io);
+		}
+next:
+		mutex_unlock(&owner->lock);
+		if (error && !first)
+			first = error;
+	}
+	mutex_unlock(&cs_fe_live_owners_lock);
+	return first;
+}
+
+#endif
diff --git a/drivers/net/ethernet/cortina/cs7542_ft_live.c b/drivers/net/ethernet/cortina/cs7542_ft_live.c
new file mode 100644
index 000000000..d93b9198f
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs7542_ft_live.c
@@ -0,0 +1,415 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Private built-in attachment: standard DSA/conduit FT, no MMIO. */
+#include <linux/cs7542_ft_live.h>
+#include <linux/capability.h>
+#include <linux/err.h>
+#include <linux/kref.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/netdevice.h>
+#include <linux/slab.h>
+#include <net/flow_offload.h>
+#include <net/net_namespace.h>
+#include <net/pkt_cls.h>
+#define CS_LIVE_MAX_BINDINGS 32
+struct cs7542_ft_live {
+	struct kref refs;
+	struct net_device *conduit;
+	u32 gmac;
+	bool closing;
+	u64 replace, destroy, stats;
+};
+
+struct cs_live_binding {
+	struct list_head list;
+	struct cs7542_ft_live *live;
+
+	u64 identity;
+	u32 users;
+	bool opened, retired;
+};
+
+/*
+ * flow-block/RTNL -> live_lock -> provider FE owner. Module callbacks must
+ *
+ * resolve topology with rtnl_trylock only, never block on RTNL.
+ */
+static DEFINE_MUTEX(live_lock);
+static LIST_HEAD(live_callbacks);
+static LIST_HEAD(live_bindings);
+static const struct cs7542_ft_live_ops *provider_ops;
+static void *provider_context;
+static bool provider_closed;
+static bool format_blocked;
+static bool detach_available;
+static u64 next_identity;
+static u32 binding_count;
+static void live_free(struct kref *ref)
+{
+	struct cs7542_ft_live *live =
+		container_of(ref, struct cs7542_ft_live, refs);
+	WARN_ON(live->conduit);
+	kfree(live);
+}
+
+void cs7542_ft_live_put(struct cs7542_ft_live *live)
+{
+	if (live)
+		kref_put(&live->refs, live_free);
+}
+
+static void binding_free(struct cs_live_binding *binding)
+{
+	list_del(&binding->list);
+	binding_count--;
+	cs7542_ft_live_put(binding->live);
+	kfree(binding);
+}
+
+static int binding_close(struct cs_live_binding *binding)
+{
+	int error;
+
+	if (!binding->opened)
+		return 0;
+	if (WARN_ON(!provider_ops))
+		return -EUCLEAN;
+	error = provider_ops->close(provider_context, binding->identity);
+	if (!error)
+		binding->opened = false;
+	return error;
+}
+
+static void binding_release(void *private)
+{
+	struct cs_live_binding *binding = private;
+
+	mutex_lock(&live_lock);
+
+	binding->retired = true;
+	if (!binding_close(binding))
+		binding_free(binding);
+	else
+		provider_closed = true;
+	mutex_unlock(&live_lock);
+}
+
+static int live_rule(enum tc_setup_type type, void *data, void *private)
+{
+	struct cs_live_binding *binding = private;
+
+	struct flow_cls_offload *cls = data;
+	int error = -EOPNOTSUPP;
+
+	if (type != TC_SETUP_CLSFLOWER || !cls)
+		return -EOPNOTSUPP;
+	mutex_lock(&live_lock);
+	if (binding->retired || binding->live->closing || !provider_ops ||
+	    provider_closed || format_blocked)
+		goto out;
+	switch (cls->command) {
+	case FLOW_CLS_REPLACE:
+		binding->live->replace++;
+		break;
+	case FLOW_CLS_DESTROY:
+		binding->live->destroy++;
+		break;
+	case FLOW_CLS_STATS:
+		binding->live->stats++;
+		break;
+	default:
+		goto out;
+	}
+	if (!binding->opened) {
+		if (cls->command != FLOW_CLS_REPLACE) {
+			error = cls->command == FLOW_CLS_DESTROY ? -ENOENT :
+								   -EOPNOTSUPP;
+			goto out;
+		}
+		error = provider_ops->open(provider_context, binding->identity,
+					   binding->live->conduit);
+		if (error)
+			goto out;
+		binding->opened = true;
+	}
+	error = provider_ops->rule(provider_context, binding->identity, cls);
+out:
+	mutex_unlock(&live_lock);
+	return error;
+}
+
+int cs7542_ft_live_register(const struct cs7542_ft_live_ops *ops, void *context)
+{
+	int error = 0;
+
+	if (!ops || !ops->owner || !ops->name || !ops->open || !ops->rule ||
+	    !ops->close || !ops->detach ||
+	    ops->api_version != CS7542_FT_LIVE_API_VERSION ||
+	    ops->size != sizeof(*ops) || strnlen(ops->name, 32) == 32)
+		return -EINVAL;
+	mutex_lock(&live_lock);
+	if (!detach_available)
+		error = -ENODEV;
+	else if (provider_ops || format_blocked)
+		error = -EBUSY;
+	else if (!try_module_get(ops->owner))
+		error = -ENODEV;
+	else {
+		provider_context = context;
+		provider_ops = ops;
+		provider_closed = false;
+	}
+	mutex_unlock(&live_lock);
+	return error;
+}
+EXPORT_SYMBOL_GPL(cs7542_ft_live_register);
+
+static int detach_locked(void)
+{
+	struct cs_live_binding *binding, *next;
+	const struct cs7542_ft_live_ops *ops = provider_ops;
+	int first = 0, error;
+
+	if (!ops)
+		return 0;
+	provider_closed = true;
+	list_for_each_entry_safe(binding, next, &live_bindings, list) {
+		error = binding_close(binding);
+		if (error && !first)
+			first = error;
+		if (!error && binding->retired)
+			binding_free(binding);
+	}
+	error = ops->detach(provider_context);
+	if (error && !first)
+		first = error;
+	if (first)
+		return first; /* Uncertain remains closed and pinned. */
+	provider_ops = NULL;
+	provider_context = NULL;
+	module_put(ops->owner);
+	return 0;
+}
+
+int cs7542_ft_live_format_hold(void)
+{
+	int error;
+
+	mutex_lock(&live_lock);
+
+	format_blocked = true;
+	error = detach_locked();
+	mutex_unlock(&live_lock);
+	return error;
+}
+
+int cs7542_ft_live_format_release(void)
+{
+	int error = 0;
+
+	mutex_lock(&live_lock);
+
+	if (provider_ops)
+		error = -EBUSY;
+	else
+		format_blocked = false;
+	mutex_unlock(&live_lock);
+	return error;
+}
+
+bool cs7542_ft_live_format_held(void)
+{
+	bool held;
+
+	mutex_lock(&live_lock);
+
+	held = format_blocked && !provider_ops;
+	mutex_unlock(&live_lock);
+	return held;
+}
+
+int cs7542_ft_live_unregister(const struct cs7542_ft_live_ops *ops,
+			      void *context)
+{
+	int error;
+
+	if (!ops || !ops->owner)
+		return -EINVAL;
+	mutex_lock(&live_lock);
+	if (provider_ops != ops || provider_context != context)
+		error = -ENOENT;
+	else if (READ_ONCE(ops->owner->state) != MODULE_STATE_COMING)
+		error = -EPERM;
+	else
+		error = detach_locked();
+	mutex_unlock(&live_lock);
+	return error;
+}
+EXPORT_SYMBOL_GPL(cs7542_ft_live_unregister);
+
+struct cs7542_ft_live *cs7542_ft_live_create(struct net_device *conduit,
+					     u32 gmac)
+{
+	struct cs7542_ft_live *live;
+
+	if (!conduit || gmac != 1)
+		return ERR_PTR(-EOPNOTSUPP);
+	live = kzalloc_obj(*live);
+	if (!live)
+		return ERR_PTR(-ENOMEM);
+	kref_init(&live->refs);
+	dev_hold(conduit);
+	live->conduit = conduit;
+	live->gmac = gmac;
+	return live;
+}
+
+int cs7542_ft_live_setup(struct cs7542_ft_live *live, int type, void *data)
+{
+	struct flow_block_offload *block = data;
+	struct flow_block_cb *callback;
+	struct cs_live_binding *binding;
+	int error = 0;
+
+	if (!live || type != TC_SETUP_FT || !block ||
+	    block->binder_type != FLOW_BLOCK_BINDER_TYPE_CLSACT_INGRESS)
+		return -EOPNOTSUPP;
+	mutex_lock(&live_lock);
+	block->driver_block_list = &live_callbacks;
+	switch (block->command) {
+	case FLOW_BLOCK_BIND:
+		if (live->closing || !block->net ||
+		    !net_eq(block->net, dev_net(live->conduit))) {
+			error = -ENODEV;
+			break;
+		}
+		callback = flow_block_cb_lookup(block->block, live_rule, live);
+		if (callback) {
+			binding = callback->cb_priv;
+			if (binding->users == U32_MAX) {
+				error = -EOVERFLOW;
+				break;
+			}
+			binding->users++;
+			break;
+		}
+		if (binding_count == CS_LIVE_MAX_BINDINGS ||
+		    next_identity == U64_MAX) {
+			error = -ENOSPC;
+			break;
+		}
+		binding = kzalloc(sizeof(*binding), GFP_KERNEL);
+		if (!binding) {
+			error = -ENOMEM;
+			break;
+		}
+		callback = flow_block_cb_alloc(live_rule, live, binding,
+					       binding_release);
+		if (IS_ERR(callback)) {
+			error = PTR_ERR(callback);
+			kfree(binding);
+			break;
+		}
+		binding->live = live;
+		binding->identity = ++next_identity;
+		binding->users = 1;
+		kref_get(&live->refs);
+		list_add_tail(&binding->list, &live_bindings);
+		binding_count++;
+		flow_block_cb_add(callback, block);
+		list_add_tail(&callback->driver_list, &live_callbacks);
+		break;
+	case FLOW_BLOCK_UNBIND:
+		callback = flow_block_cb_lookup(block->block, live_rule, live);
+		if (!callback) {
+			error = -ENOENT;
+			break;
+		}
+		binding = callback->cb_priv;
+		if (--binding->users)
+			break;
+		flow_block_cb_remove(callback, block);
+		list_del(&callback->driver_list);
+		break;
+	default:
+		error = -EOPNOTSUPP;
+	}
+	mutex_unlock(&live_lock);
+	return error;
+}
+
+int cs7542_ft_live_quiesce(struct cs7542_ft_live *live)
+{
+	struct cs_live_binding *binding;
+	struct net_device *conduit;
+	int first = 0, error;
+
+	if (!live)
+		return 0;
+	mutex_lock(&live_lock);
+	live->closing = true;
+	list_for_each_entry(binding, &live_bindings, list) {
+		if (binding->live != live)
+			continue;
+		error = binding_close(binding);
+		if (error && !first)
+			first = error;
+	}
+	if (first)
+		provider_closed = true;
+	conduit = live->conduit;
+	live->conduit = NULL;
+	mutex_unlock(&live_lock);
+	if (conduit)
+		dev_put(conduit);
+	return first;
+}
+
+ssize_t cs7542_ft_live_format(struct cs7542_ft_live *live, char *buffer)
+{
+	ssize_t length;
+
+	mutex_lock(&live_lock);
+
+	length =
+		live ? sysfs_emit(buffer,
+			       "CS_FT_LIVE_V1 gmac=%u closing=%u provider=%s closed=%u format_blocked=%u bindings=%u replace=%llu destroy=%llu stats=%llu\n",
+			       live->gmac, live->closing,
+			       provider_ops ? provider_ops->name : "none",
+			       provider_closed, format_blocked, binding_count,
+			       live->replace, live->destroy, live->stats) :
+		       -ENODEV;
+	mutex_unlock(&live_lock);
+	return length;
+}
+
+/* Built-in text survives dropping the provider's final reference. */
+
+static ssize_t detach_store(struct kobject *kobj, struct kobj_attribute *attr,
+			    const char *buffer, size_t count)
+{
+	int error;
+
+	if (!capable(CAP_NET_ADMIN))
+		return -EPERM;
+	if (!sysfs_streq(buffer, "detach"))
+		return -EINVAL;
+	mutex_lock(&live_lock);
+	error = detach_locked();
+	mutex_unlock(&live_lock);
+	return error ? error : count;
+}
+
+static struct kobj_attribute detach_attribute =
+
+	__ATTR(cs7542_ft_provider_detach, 0200, NULL, detach_store);
+static int __init live_init(void)
+{
+	int error = sysfs_create_file(kernel_kobj, &detach_attribute.attr);
+
+	if (!error)
+		detach_available = true;
+	return error;
+}
+
+subsys_initcall(live_init);
diff --git a/drivers/net/ethernet/cortina/cs_fe_acl_encode.c b/drivers/net/ethernet/cortina/cs_fe_acl_encode.c
new file mode 100644
index 000000000..09746fa5d
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_acl_encode.c
@@ -0,0 +1,124 @@
+// SPDX-License-Identifier: GPL-2.0
+#ifdef __KERNEL__
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#include <errno.h>
+#include <string.h>
+#endif
+#include "cs_fe_acl_guard.h"
+/* Primary SDK descriptor offsets, DATA0 first; not ascending MMIO words. */
+static void field(u32 *out, unsigned int bit, unsigned int width, u32 value)
+{
+	unsigned int i;
+
+	for (i = 0; i < width; i++) {
+		unsigned int n = bit + i;
+		u32 mask = 1U << (n % 32);
+
+		out[n / 32] = (out[n / 32] & ~mask) |
+
+			      (((value >> i) & 1U) ? mask : 0);
+	}
+}
+
+static void parity(u32 *out, unsigned int words, unsigned int bit)
+{
+	unsigned int i, j, value = 0;
+
+	field(out, bit, 1, 0);
+
+	for (i = 0; i < words; i++)
+		for (j = 0; j < 32; j++)
+			value ^= (out[i] >> j) & 1U;
+	field(out, bit, 1, value);
+}
+
+int cs_fe_acl_encode(enum cs_fe_acl_kind kind, bool valid,
+		     unsigned int class_id, u32 rule[CS_ACL_RULE_WORDS],
+		     u32 action[CS_ACL_ACTION_WORDS])
+{
+	unsigned int i;
+
+	if ((unsigned int)kind >= CS_ACL_KINDS || class_id < 5 ||
+	    class_id >= 5 + CS_FE_BACKEND_LEASES || !rule || !action)
+		return -EINVAL;
+	/*
+	 * Preserve the actual SDK ff-initialized wildcard constructor, including
+	 * its named reserved_879_878 field. The serializer only fills bits0..881.
+	 * No general reserved/parity readback mask is accepted.
+	 */
+	for (i = 0; i < CS_ACL_RULE_WORDS; i++)
+		rule[i] = ~0U;
+	rule[27] = 0x0003ffffU;
+	field(rule, 23 * 32 + 27, 16, 0); /* NE_VEC */
+	field(rule, 19 * 32 + 31, 9, 0); /* IP_DA_MASK wildcard */
+	field(rule, 20 * 32 + 8, 9, 0); /* IP_SA_MASK wildcard */
+	if (kind == CS_ACL_TTL1 || kind == CS_ACL_TTL0) {
+		field(rule, 13 * 32 + 31, 8,
+		      kind == CS_ACL_TTL1 ? 1 : 0); /* TTL_HOPLMT */
+		field(rule, 20 * 32 + 29, 1, 0); /* TTL_HOPLMT_MASK */
+	} else {
+		field(rule, 13 * 32 + 10, 1, 1); /* IP_OPTIONS */
+		field(rule, 20 * 32 + 27, 1, 0); /* IP_OPTIONS_MASK */
+	}
+	/*
+	 * Experimental narrowing beyond the broad vendor exception: current
+	 * IPv4/class5/physical ingress1 only. Existing CLASS5 checks UDP tuple,
+	 * tag, DSCP0 and fragmentation; a CLASS result is NOT payload matching.
+	 * SDK DA_MAC_NO_MATCH callers establish class-hit/index selectors.
+	 */
+	field(rule, 4 * 32 + 23, 1, 1); /* IP_VLD */
+	field(rule, 19 * 32 + 29, 1, 0); /* IP_VLD_MASK */
+	field(rule, 4 * 32 + 24, 1, 0); /* IP_VER: IPv4 */
+	field(rule, 19 * 32 + 30, 1, 0); /* IP_VER_MASK */
+	field(rule, 16 * 32 + 8, 4, 1); /* LSPID */
+	field(rule, 21 * 32 + 3, 1, 0); /* LSPID_MASK */
+	field(rule, 17 * 32 + 4, 1, 1); /* CLASS_HIT */
+	field(rule, 21 * 32 + 25, 1, 0); /* CLASS_HIT_MASK */
+	field(rule, 17 * 32 + 5, 6, class_id); /* CLASS_SVIDX */
+	field(rule, 21 * 32 + 26, 1, 0); /* CLASS_SVIDX_MASK */
+	field(rule, 27 * 32 + 16, 1, valid); /* RULE_VLD, valid LAST */
+	parity(rule, CS_ACL_RULE_WORDS, 881);
+	memset(action, 0, CS_ACL_ACTION_WORDS * sizeof(*action));
+	/*
+	 * CPU56 is the current serviced destination, not vendor VOQ104.
+	 * Priority7 zero-valued overrides request cancellation, NOT a copy after
+	 * edits. Whether silicon applies them before modification is the test.
+	 */
+	field(action, 0, 1, 1); /* VOQ_VLD */
+	field(action, 1, 4, 7); /* VOQ_PRI */
+	field(action, 5, 8, 56); /* VOQ */
+	field(action, 13, 4, 3); /* LDPID */
+	field(action, 69, 1, 1); /* DROP_PERMIT_VLD */
+	field(action, 71, 1, 1); /* PERMIT */
+	field(action, 72, 4, 7); /* DROP_PERMIT_PRI */
+	field(action, 76, 1, 1); /* 8021P_1_VLD */
+	field(action, 80, 4, 7); /* 8021P_1_PRI */
+	field(action, 84, 1, 1); /* DEI_1_VLD */
+	field(action, 86, 4, 7); /* DEI_1_PRI */
+	field(action, 90, 1, 1); /* 8021P_2_VLD */
+	field(action, 95, 4, 7); /* 8021P_2_PRI */
+	field(action, 99, 1, 1); /* DEI_2_VLD */
+	field(action, 101, 4, 7); /* DEI_2_PRI */
+	field(action, 105, 1, 1); /* DSCP_VLD */
+	field(action, 112, 4, 7); /* DSCP_PRI */
+	field(action, 139, 1, 1); /* FIRST_VLAN_CMD_VLD */
+	field(action, 159, 4, 7); /* FIRST_VLAN_CMD_PRI */
+	field(action, 163, 1, 1); /* SECOND_VLAN_CMD_VLD */
+	field(action, 183, 4, 7); /* SECOND_VLAN_CMD_PRI */
+	field(action, 192, 1, 1); /* IP_SA_REPLACE_EN_VLD */
+	field(action, 194, 4, 7); /* IP_SA_REPLACE_EN_PRI */
+	field(action, 198, 1, 1); /* IP_DA_REPLACE_EN_VLD */
+	field(action, 200, 4, 7); /* IP_DA_REPLACE_EN_PRI */
+	field(action, 204, 1, 1); /* L4_SP_REPLACE_EN_VLD */
+	field(action, 222, 4, 7); /* L4_SP_REPLACE_EN_PRI */
+	field(action, 226, 1, 1); /* L4_DP_REPLACE_EN_VLD */
+	field(action, 244, 4, 7); /* L4_DP_REPLACE_EN_PRI */
+	field(action, 272, 1, 1); /* MAC_DA_SA_REPLACE_EN_VLD */
+	field(action, 275, 4, 7); /* MAC_DA_SA_REPLACE_EN_PRI */
+	field(action, 289, 1, 1); /* DECR_TTL_HOPLIMIT_VLD */
+	field(action, 291, 4, 7); /* DECR_TTL_HOPLIMIT_PRI */
+	parity(action, CS_ACL_ACTION_WORDS, 305);
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_acl_guard.c b/drivers/net/ethernet/cortina/cs_fe_acl_guard.c
new file mode 100644
index 000000000..72be89368
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_acl_guard.c
@@ -0,0 +1,324 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "cs_fe_acl_guard.h"
+#ifdef __KERNEL__
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#include <errno.h>
+#include <string.h>
+#endif
+#define ACL_START (1U << 31)
+#define ACL_WRITE (1U << 30)
+#define ACL_BUSY_US 1000U
+struct acl_table {
+	unsigned int access, words, parity;
+};
+
+static const struct acl_table tables[] = {
+	[CS_ACL_RULE] = { 0x138, 28, 881 },
+	[CS_ACL_ACTION] = { 0x1ac, 10, 305 },
+	[CS_ACL_CLASS] = { 0x54, 20, 629 },
+};
+
+static int before(const struct cs_fe_backend_io *io)
+{
+	return io->now_us(io->context) >= io->limit_us ? -ETIMEDOUT : 0;
+}
+
+static int idle(const struct cs_fe_backend_io *io, unsigned int access)
+{
+	unsigned long long start = io->now_us(io->context);
+	u32 value;
+	int error;
+
+	for (;;) {
+		error = before(io);
+		if (error)
+			return error;
+		error = io->read32(io->context, access, &value);
+		if (error)
+			return error;
+		if (!(value & ACL_START))
+			return before(io);
+		if (io->now_us(io->context) - start >= ACL_BUSY_US)
+			return -ETIMEDOUT;
+	}
+}
+
+static int read_record(const struct cs_fe_backend_io *io, unsigned int table,
+		       unsigned int row, struct cs_fe_acl_record *record)
+{
+	const struct acl_table *t;
+	unsigned int i;
+	int error;
+
+	if (table > CS_ACL_CLASS || row >= 64)
+		return -ERANGE;
+	t = &tables[table];
+	if (t->access + (t->words + 1) * 4 > io->extent)
+		return -ERANGE;
+	memset(record, 0, sizeof(*record));
+	record->table = table;
+	record->row = row;
+	record->words = t->words;
+	record->error = -EINPROGRESS;
+	error = idle(io, t->access);
+	if (error)
+		goto done;
+	error = before(io);
+	if (error)
+		goto done;
+	/* READ has bit30 clear; row bit6 is ALWAYS clear. */
+	error = io->write32(io->context, t->access, ACL_START | row);
+	if (error)
+		goto done;
+	error = idle(io, t->access);
+	if (error)
+		goto done;
+	for (i = 0; i < t->words; i++) {
+		error = before(io);
+		if (error)
+			goto done;
+		error = io->read32(io->context, t->access + (t->words - i) * 4,
+				   &record->raw[i]);
+		if (error)
+			goto done;
+		record->complete++;
+	}
+	error = before(io);
+done:
+	record->error = error;
+	return error;
+}
+
+static int read_entry(struct cs_fe_acl_guard *guard,
+		      const struct cs_fe_backend_io *io, unsigned int table,
+		      unsigned int row, struct cs_fe_acl_record **out)
+{
+	if (table > CS_ACL_CLASS || row >= 64 ||
+	    guard->records >= CS_ACL_RECORDS)
+		return -ERANGE;
+	*out = &guard->record[guard->records++];
+	return read_record(io, table, row, *out);
+}
+
+static int write_entry(struct cs_fe_acl_guard *guard,
+		       const struct cs_fe_backend_io *io, unsigned int table,
+		       unsigned int row, const u32 *expected, bool valid)
+{
+	const struct acl_table *t;
+	struct cs_fe_acl_record *record;
+	unsigned int i;
+	int error;
+
+	if (table > CS_ACL_ACTION || row >= 64)
+		return -EINVAL;
+	t = &tables[table];
+	guard->written = guard->pending =
+		true; /* BEFORE uncertain scratch data. */
+	error = idle(io, t->access);
+	if (error)
+		return error;
+	for (i = 0; i < t->words; i++) {
+		u32 word = expected[i];
+
+		error = before(io);
+		if (error)
+			return error;
+		/* Primary named parity only; strict full expected readback retained. */
+		if (i == t->parity / 32)
+			word &= ~(1U << (t->parity % 32));
+		error = io->write32(io->context, t->access + (t->words - i) * 4,
+				    word);
+		if (error)
+			return error;
+	}
+	error = before(io);
+	if (error)
+		return error;
+	if (valid)
+		guard->exposed = true; /* BEFORE uncertain valid command. */
+	error = io->write32(io->context, t->access,
+			    ACL_START | ACL_WRITE | row);
+	if (error)
+		return error;
+	error = idle(io, t->access);
+	if (error)
+		return error;
+	error = read_entry(guard, io, table, row, &record);
+	if (error)
+		return error;
+	if (memcmp(record->raw, expected, t->words * sizeof(u32))) {
+		record->error = -EBADMSG;
+		return -EBADMSG;
+	}
+	return 0;
+}
+
+static int fail(struct cs_fe_acl_guard *guard, int error)
+{
+	if (!guard->first_error)
+		guard->first_error = error;
+	guard->poisoned = true;
+	return error;
+}
+
+int cs_fe_acl_prepare(struct cs_fe_acl_guard *guard,
+		      const struct cs_fe_backend_io *io, unsigned int lease,
+		      unsigned int class_id, const u32 class_invalid[20])
+{
+	struct cs_fe_acl_record *record;
+	u32 rule[CS_ACL_RULE_WORDS], action[CS_ACL_ACTION_WORDS];
+	unsigned int table, kind, i;
+	int error;
+
+	if (!guard || !io || !io->now_us || !io->read32 || !io->write32 ||
+	    !io->limit_us || !class_invalid || lease >= CS_FE_BACKEND_LEASES ||
+	    class_id != 5 + lease || io->extent < 0x1d8)
+		return -EINVAL;
+	if (guard->attempted || guard->pending)
+		return -EBUSY;
+	guard->attempted = true;
+	guard->lease = lease;
+	guard->class_id = class_id;
+	memcpy(guard->class_invalid, class_invalid,
+	       sizeof(guard->class_invalid));
+	guard->first_row =
+		5 + lease * 3; /* 5..52, below the disputed address bit 6. */
+	/*
+	 * The scoped CLASS must be fresh/inactive before ANY ACL entry DATA write.
+	 * Sole owner mutex prevents it being published by another transaction.
+	 */
+	error = read_entry(guard, io, CS_ACL_CLASS, class_id, &record);
+	if (error)
+		return fail(guard, error);
+	if (memcmp(record->raw, class_invalid, sizeof(guard->class_invalid)) ||
+	    (record->raw[19] & (1U << 20)))
+		return fail(guard, -EEXIST);
+	for (table = CS_ACL_RULE; table <= CS_ACL_ACTION; table++)
+		for (kind = 0; kind < CS_ACL_KINDS; kind++) {
+			error = read_entry(guard, io, table,
+					   guard->first_row + kind, &record);
+			if (error)
+				return fail(guard, error);
+			for (i = 0; i < record->complete; i++)
+				if (record->raw[i])
+					return fail(guard, -EEXIST);
+		}
+	/*
+	 * Both actions first, then invalid rules, then valid rules. CLASS is still
+	 * inactive; its owner can publish it only after this full transaction.
+	 */
+	for (table = 0; table < 3; table++)
+		for (kind = 0; kind < CS_ACL_KINDS; kind++) {
+			error = cs_fe_acl_encode(kind, table == 2, class_id,
+						 rule, action);
+			if (error)
+				return fail(guard, error);
+			error = write_entry(guard, io,
+				table == 0 ? CS_ACL_ACTION : CS_ACL_RULE,
+				guard->first_row + kind,
+				table == 0 ? action : rule, table == 2);
+			if (error)
+				return fail(guard, error);
+		}
+	error = before(io);
+	if (error)
+		return fail(guard, error);
+	guard->pending = false;
+	guard->ready = true;
+	return 0;
+}
+
+int cs_fe_acl_verify_retained(struct cs_fe_acl_guard *guard,
+			      const struct cs_fe_backend_io *io,
+			      unsigned int lease, unsigned int class_id,
+			      const u32 class_invalid[20])
+{
+	struct cs_fe_acl_record *record;
+	u32 rule[CS_ACL_RULE_WORDS], action[CS_ACL_ACTION_WORDS];
+	unsigned int kind, table;
+	int error;
+
+	if (!guard || !io || !io->now_us || !io->read32 || !io->write32 ||
+	    !io->limit_us || !class_invalid || lease >= CS_FE_BACKEND_LEASES ||
+	    class_id != 5 + lease)
+		return -EINVAL;
+	if (!guard->attempted || !guard->written || !guard->ready ||
+	    guard->pending || guard->disarmed || guard->poisoned ||
+	    guard->lease != lease || guard->class_id != class_id ||
+	    guard->first_row != 5 + 3 * lease ||
+	    memcmp(guard->class_invalid, class_invalid,
+		   sizeof(guard->class_invalid)))
+		return fail(guard, -EUCLEAN);
+	guard->retained_records = 0;
+	record = &guard->retained[guard->retained_records++];
+	error = read_record(io, CS_ACL_CLASS, class_id, record);
+	if (!error && ((record->raw[19] & (1U << 20)) ||
+		       memcmp(record->raw, class_invalid,
+			      sizeof(guard->class_invalid)))) {
+		record->error = error = -EUCLEAN;
+	}
+	if (error)
+		return fail(guard, error);
+	for (kind = 0; kind < CS_ACL_KINDS; kind++) {
+		error = cs_fe_acl_encode(kind, true, class_id, rule, action);
+		if (error)
+			return fail(guard, error);
+		for (table = CS_ACL_RULE; table <= CS_ACL_ACTION; table++) {
+			record = &guard->retained[guard->retained_records++];
+			error = read_record(io, table, guard->first_row + kind,
+					    record);
+			if (!error &&
+			    memcmp(record->raw,
+				   table == CS_ACL_RULE ? rule : action,
+				   tables[table].words * sizeof(u32)))
+				record->error = error = -EUCLEAN;
+			if (error)
+				return fail(guard, error);
+		}
+	}
+	if (guard->retained_checks != ~0U)
+		guard->retained_checks++;
+	return 0;
+}
+
+int cs_fe_acl_disarm(struct cs_fe_acl_guard *guard,
+		     const struct cs_fe_backend_io *io)
+{
+	struct cs_fe_acl_record *record;
+	u32 rule[CS_ACL_RULE_WORDS], action[CS_ACL_ACTION_WORDS];
+	unsigned int kind;
+	int first = 0, error;
+
+	if (!guard || !io || !io->limit_us || !guard->attempted)
+		return -EINVAL;
+	if (!guard->written || guard->disarmed)
+		return 0;
+	error = read_entry(guard, io, CS_ACL_CLASS, guard->class_id, &record);
+	if (error)
+		return fail(guard, error);
+	if (memcmp(record->raw, guard->class_invalid,
+		   sizeof(guard->class_invalid)) ||
+	    (record->raw[19] & (1U << 20)))
+		return fail(guard,
+			-EBUSY); /* Guard never removed under active CLASS. */
+	guard->pending = true;
+	for (kind = 0; kind < CS_ACL_KINDS; kind++) {
+		error = cs_fe_acl_encode(kind, false, guard->class_id, rule,
+					 action);
+		if (!error)
+			error = write_entry(guard, io, CS_ACL_RULE,
+					    guard->first_row + kind, rule,
+					    false);
+		if (error && !first)
+			first = error; /* Attempt BOTH rules; never delete/reuse ACTION. */
+	}
+	if (first)
+		return fail(guard, first);
+	guard->pending = guard->ready = false;
+	guard->disarmed = true;
+	return 0;
+}
+
+#include "cs_fe_native_mtu.inc"
diff --git a/drivers/net/ethernet/cortina/cs_fe_acl_guard.h b/drivers/net/ethernet/cortina/cs_fe_acl_guard.h
new file mode 100644
index 000000000..09fab9e3b
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_acl_guard.h
@@ -0,0 +1,47 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_ACL_GUARD_H
+#define CS_FE_ACL_GUARD_H
+#include "cs_fe_backend.h"
+#define CS_ACL_RULE_WORDS 28U
+#define CS_ACL_ACTION_WORDS 10U
+#define CS_ACL_RECORDS 32U
+/* Address0..63 is common to BOTH primary layouts; no table-depth claim. */
+enum cs_fe_acl_kind { CS_ACL_TTL1, CS_ACL_OPTIONS, CS_ACL_TTL0, CS_ACL_KINDS };
+enum cs_fe_acl_table { CS_ACL_RULE, CS_ACL_ACTION, CS_ACL_CLASS };
+struct cs_fe_acl_record {
+	u32 table, row, words, complete;
+	int error;
+	u32 raw[CS_ACL_RULE_WORDS];
+};
+
+struct cs_fe_acl_guard {
+	bool attempted, written, exposed, pending, ready, disarmed, poisoned;
+	int first_error;
+	u32 lease, class_id, first_row, records;
+	u32 class_invalid[20];
+	struct cs_fe_acl_record record[CS_ACL_RECORDS];
+	u32 retained_records, retained_checks;
+	struct cs_fe_acl_record retained[1 + 2 * CS_ACL_KINDS];
+};
+
+int cs_fe_acl_encode(enum cs_fe_acl_kind kind, bool valid,
+		     unsigned int class_id, u32 rule[CS_ACL_RULE_WORDS],
+		     u32 action[CS_ACL_ACTION_WORDS]);
+/*
+ * Internal only. Caller owns the SAME FE mutex throughout. lease0..7 maps
+ * only to own CLASS5..12 and ACL5..28. No arbitrary selector crosses ABI.
+ */
+int cs_fe_acl_prepare(struct cs_fe_acl_guard *guard,
+		      const struct cs_fe_backend_io *io, unsigned int lease,
+		      unsigned int class_id, const u32 class_invalid[20]);
+/*
+ * READ ONLY: scoped traps stay installed permanently under inactive CLASS.
+ * Finite latest verification journal does not exhaust the prepare journal.
+ */
+int cs_fe_acl_verify_retained(struct cs_fe_acl_guard *guard,
+			      const struct cs_fe_backend_io *io,
+			      unsigned int lease, unsigned int class_id,
+			      const u32 class_invalid[20]);
+int cs_fe_acl_disarm(struct cs_fe_acl_guard *guard,
+		     const struct cs_fe_backend_io *io);
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_backend.h b/drivers/net/ethernet/cortina/cs_fe_backend.h
new file mode 100644
index 000000000..5fd3cf101
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_backend.h
@@ -0,0 +1,228 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_BACKEND_H
+#define CS_FE_BACKEND_H
+#include "cs_fe_encode.h"
+
+#define CS_FE_BACKEND_BLOCKS 4
+#define CS_FE_BACKEND_ACTIONS 8
+#define CS_FE_BACKEND_LEASES 16
+#define CS_FE_BACKEND_ENTRIES CS_FE_BACKEND_LEASES
+#define CS_FE_BACKEND_WORDS 20
+#define CS_FE_BACKEND_US 1000000ULL
+
+enum cs_fe_backend_table_id {
+	CS_BE_CLASS,
+	CS_BE_SDB,
+	CS_BE_FWD,
+	CS_BE_VOQ,
+	CS_BE_MASK,
+	CS_BE_HASH,
+	CS_BE_OVERFLOW,
+	CS_BE_L2,
+	CS_BE_L3,
+	CS_BE_FVLAN,
+	CS_BE_TABLES,
+};
+
+struct cs_fe_backend_table {
+	unsigned int access, rows, words;
+	int parity;
+};
+
+extern const struct cs_fe_backend_table cs_fe_backend_tables[CS_BE_TABLES];
+
+/*
+ * The actual sole FE owner mutex covers EACH entire operation. The host model
+ * supplies the same caller serialization. No caller may access FE scratch in
+ * parallel, or free/reinitialize this context while block callbacks exist.
+ */
+#ifndef CS_FE_HOT_SELECTOR_DEFINED
+#define CS_FE_HOT_SELECTOR_DEFINED
+struct cs_fe_hot_selector {
+	u8 source[6], destination[6];
+	bool valid;
+};
+
+#endif
+struct cs_fe_hot_state;
+struct cs_fe_rule;
+struct cs_fe_key_policy;
+struct cs_fe_rows;
+struct cs_fe_plan;
+#define CS_FE_BACKEND_IO_ABI 3U
+struct cs_fe_backend_io {
+	unsigned int abi, size;
+	struct cs_fe_hot_selector selector;
+	void *context;
+	unsigned int extent;
+	unsigned long long (*now_us)(void *context);
+	int (*read32)(void *context, unsigned int offset, u32 *value);
+	int (*write32)(void *context, unsigned int offset, u32 value);
+	unsigned long long limit_us; /* Absolute programming limit;0 permits cleanup. */
+	/* Hot backend receives only these typed hooks; raw read32/write32 are NULL. */
+	int (*table_read)(void *context, unsigned int table, unsigned int row,
+			  unsigned long long end);
+	int (*table_write)(void *context, unsigned int table, unsigned int row, const u32 *input,
+			   const u32 *expected, unsigned long long end);
+	int (*claim)(void *context, unsigned int lease, const struct cs_fe_rule *rule,
+		     const struct cs_fe_key_policy *policy, const struct cs_fe_rows *rows,
+		     const struct cs_fe_plan *plan);
+	int (*engine_status)(void *context, u32 *status, u32 *mask, unsigned long long end);
+	int (*rebind)(void *context, unsigned int lease, const struct cs_fe_rule *rule,
+		      const struct cs_fe_key_policy *policy,
+		      const struct cs_fe_plan *plan, unsigned long long end);
+	int (*receipt)(void *context, unsigned int lease, struct cs_fe_plan *plan);
+	/* Owner selects both physical row sets from its own validated request. */
+	int (*placement)(void *context, unsigned int selector, struct cs_fe_rows *rows,
+			 bool *shared);
+	/* Cuts only a failed member of a shared result. Success is verified in FE. */
+	int (*isolate)(void *context, unsigned int selector);
+};
+
+struct cs_fe_backend_diag {
+	unsigned int table, row, words, complete;
+	int error;
+	u32 raw[CS_FE_BACKEND_WORDS];
+};
+
+struct cs_fe_backend_entry {
+	unsigned long long block, version;
+	unsigned long cookie;
+	unsigned int lease;
+	bool occupied, active;
+};
+
+struct cs_fe_backend_encoding {
+	struct cs_fe_key key;
+	u32 mask[5], action[4];
+	bool guarded; /* Internal validated manual request, not module bytes. */
+	bool exact_class, negative_class;
+	unsigned int class_match;
+};
+
+struct cs_fe_backend_lease {
+	bool reserved, submitted, active, marker, guarded, scoped, scope_exact;
+	bool rearmable, shared_result;
+	unsigned int scope_grant;
+	struct cs_fe_rule rule;
+	struct cs_fe_key_policy policy;
+	struct cs_fe_rows rows;
+	struct cs_fe_plan plan;
+};
+
+struct cs_fe_backend_block {
+	unsigned long long identity, rejected_through;
+	bool closed;
+};
+
+struct cs_fe_backend {
+	struct cs_fe_hot_state *hot_state;
+	int (*guard_prepare)(void *context, const struct cs_fe_backend_io *io,
+			     unsigned int lease, const struct cs_fe_rows *rows,
+			     const struct cs_fe_plan *plan,
+			     unsigned long long end_us);
+	int (*guard_withdraw)(void *context, const struct cs_fe_backend_io *io,
+			      unsigned int lease, const struct cs_fe_rows *rows,
+			      const struct cs_fe_plan *plan,
+			      unsigned long long end_us);
+	int (*guard_rearm)(void *context, const struct cs_fe_backend_io *io,
+			   unsigned int lease, const struct cs_fe_rows *rows,
+			   const struct cs_fe_plan *plan,
+			   unsigned long long end_us);
+	void (*before_withdraw)(void *context,
+				const struct cs_fe_backend_io *io,
+				unsigned int lease,
+				const struct cs_fe_plan *plan,
+				unsigned long long end_us);
+	void *guard_context;
+	void (*observe)(void *context, const struct cs_fe_backend_diag *record);
+	void *observe_context;
+	bool initialized, poisoned, pending;
+	int first_error;
+	u32 status, init;
+	unsigned int admitted_requirements, next_lease, immutable_rearms;
+	unsigned long long next_block;
+	struct cs_fe_backend_block block[CS_FE_BACKEND_BLOCKS];
+	struct cs_fe_backend_entry entry[CS_FE_BACKEND_ENTRIES];
+	struct cs_fe_backend_lease lease[CS_FE_BACKEND_LEASES];
+	struct cs_fe_backend_diag last;
+};
+
+/*
+ * No live reset/reinit/free API: leases, including withdrawn/failed ones, stay
+ *
+ * owned until actual full NE reset and callback drain. These APIs do not prove
+ * a pipeline retirement fence. Serial is a PRIVATE desired-version guard,
+ * never a generation supplied by upstream FLOW_CLS_DESTROY. The provider
+ * allocates versions from ONE monotonic counter before validating any cookie.
+ * Unknown rejections advance a conservative block-wide fence for pending
+ * older versions without allocating cookie tombstones or hardware leases.
+ */
+int cs_fe_backend_init(struct cs_fe_backend *backend,
+		       unsigned int requirements);
+int cs_fe_backend_replace_native(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy);
+int cs_fe_backend_block_open(struct cs_fe_backend *backend,
+			     unsigned long long *handle);
+int cs_fe_backend_marker_encoded(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy,
+				 const struct cs_fe_backend_encoding *encoding);
+int cs_fe_backend_marker(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block, unsigned long cookie,
+			 unsigned long long version,
+			 const struct cs_fe_rule *rule,
+			 const struct cs_fe_key_policy *policy);
+/*
+ * Internal sole-owner entrypoint; caller must validate scoped policy.
+ * Still checks backend requirements; this is not a policy bypass.
+ */
+/* Internal verified-scope call only; not exported to loadable providers. */
+int cs_fe_backend_replace_scoped(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy,
+				 bool exact_ingress);
+int cs_fe_backend_replace_guarded(struct cs_fe_backend *backend,
+				  const struct cs_fe_backend_io *io,
+				  unsigned long long block,
+				  unsigned long cookie,
+				  unsigned long long version,
+				  const struct cs_fe_rule *rule,
+				  const struct cs_fe_key_policy *policy);
+int cs_fe_backend_replace(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *io,
+			  unsigned long long block, unsigned long cookie,
+			  unsigned long long version,
+			  const struct cs_fe_rule *rule,
+			  const struct cs_fe_key_policy *policy);
+int cs_fe_backend_reject(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block, unsigned long cookie,
+			 unsigned long long version, int reason);
+/*
+ * DESTROY accepts the registry-snapshotted current version or newer, not an
+ * invented upstream generation. Repeat of a retired current version is0.
+ */
+int cs_fe_backend_destroy(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *io,
+			  unsigned long long block, unsigned long cookie,
+			  unsigned long long version);
+int cs_fe_backend_next_rows(const struct cs_fe_backend *backend,
+			    struct cs_fe_rows *rows);
+int cs_fe_backend_forget(struct cs_fe_backend *backend,
+			 unsigned long long block);
+int cs_fe_backend_unbind(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block);
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_backend_algorithm.c b/drivers/net/ethernet/cortina/cs_fe_backend_algorithm.c
new file mode 100644
index 000000000..5df711540
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_backend_algorithm.c
@@ -0,0 +1,976 @@
+// SPDX-License-Identifier: GPL-2.0
+#ifndef CS_FE_HOT_REARM
+#define CS_FE_HOT_REARM 1
+#endif
+/* Private direction backend. No callback registration/capability/statistics. */
+#ifdef __KERNEL__
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#include <errno.h>
+#include <string.h>
+#endif
+#define cs_fe_backend_init hot_cs_fe_backend_init
+#define cs_fe_backend_block_open hot_cs_fe_backend_block_open
+#define cs_fe_backend_next_rows hot_cs_fe_backend_next_rows
+#define cs_fe_backend_replace hot_cs_fe_backend_replace
+#define cs_fe_backend_replace_scoped hot_cs_fe_backend_replace_scoped
+#define cs_fe_backend_replace_guarded hot_cs_fe_backend_replace_guarded
+#define cs_fe_backend_marker hot_cs_fe_backend_marker
+#define cs_fe_backend_marker_encoded hot_cs_fe_backend_marker_encoded
+#define cs_fe_backend_destroy hot_cs_fe_backend_destroy
+#define cs_fe_backend_reject hot_cs_fe_backend_reject
+#define cs_fe_backend_unbind hot_cs_fe_backend_unbind
+#define cs_fe_backend_forget hot_cs_fe_backend_forget
+#define cs_fe_backend_tables hot_algorithm_tables
+#include "cs_fe_backend.h"
+#include "cs_fe_hot_compare.h"
+
+/* Exact proven indirect layout; DATA0 is the highest DATA address. */
+const struct cs_fe_backend_table cs_fe_backend_tables[CS_BE_TABLES] = {
+	[CS_BE_CLASS] = { 0x0054, 64, 20, 629 },
+	[CS_BE_SDB] = { 0x00a8, 64, 7, 206 },
+	[CS_BE_FWD] = { 0x00d4, 8192, 4, 113 },
+	[CS_BE_VOQ] = { 0x00f4, 512, 2, 40 },
+	[CS_BE_MASK] = { 0x2068, 64, 5, 149 },
+	[CS_BE_HASH] = { 0x201c, 12288, 4, -1 },
+	[CS_BE_OVERFLOW] = { 0x203c, 64, 2, -1 },
+	[CS_BE_L2] = { 0x0124, 512, 4, 96 },
+	[CS_BE_L3] = { 0x010c, 1024, 5, 128 },
+	[CS_BE_FVLAN] = { 0x0100, 512, 2, 38 },
+};
+
+#define CS_BE_START (1U << 31)
+#define CS_BE_WRITE (1U << 30)
+
+static unsigned int cs_be_parity(u32 value)
+{
+	unsigned int parity = 0;
+
+	while (value) {
+		parity ^= value & 1;
+		value >>= 1;
+	}
+	return parity;
+}
+
+static int cs_be_read(struct cs_fe_backend *backend,
+		      const struct cs_fe_backend_io *io, unsigned int table,
+		      unsigned int row, unsigned long long end)
+{
+	(void)backend;
+	return io->table_read(io->context, table, row, end);
+}
+
+static int cs_be_compare(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io, unsigned int id,
+			 unsigned int row, const u32 *expected,
+			 unsigned long long end)
+{
+	int error = cs_be_read(backend, io, id, row, end);
+
+	if (!error && memcmp(backend->last.raw, expected,
+			     cs_fe_backend_tables[id].words * sizeof(u32))) {
+		backend->last.error = -EUCLEAN;
+		error = -EUCLEAN;
+	}
+	return error;
+}
+
+static int cs_be_write(struct cs_fe_backend *backend,
+		       const struct cs_fe_backend_io *io, unsigned int table,
+		       unsigned int row, const u32 *input, const u32 *expected,
+		       unsigned long long end)
+{
+	(void)backend;
+	return io->table_write(io->context, table, row, input, expected, end);
+}
+
+static int cs_be_fail(struct cs_fe_backend *backend, int error)
+{
+	if (!backend->first_error)
+		backend->first_error = error;
+	backend->poisoned = true;
+	return error;
+}
+
+static int cs_be_io(const struct cs_fe_backend_io *io)
+{
+	return !io || io->abi != CS_FE_BACKEND_IO_ABI ||
+			       io->size != sizeof(*io) || !io->now_us ||
+			       !io->table_read || !io->table_write ||
+			       !io->claim || !io->engine_status ||
+			       io->extent < 0x2080 ?
+		       -EINVAL :
+		       0;
+}
+
+static int cs_be_block(struct cs_fe_backend *backend, unsigned long long handle)
+{
+	unsigned int index;
+
+	if (!backend->initialized || !handle)
+		return -ENODEV;
+	for (index = 0; index < CS_FE_BACKEND_BLOCKS; index++)
+		if (backend->block[index].identity == handle)
+			return backend->block[index].closed ? -ESHUTDOWN :
+							      (int)index;
+	return -ENOENT;
+}
+
+static struct cs_fe_backend_entry *cs_be_entry(struct cs_fe_backend *backend,
+					       unsigned long long block,
+					       unsigned long cookie,
+					       bool allocate)
+{
+	struct cs_fe_backend_entry *free = NULL;
+	unsigned int index;
+
+	for (index = 0; index < CS_FE_BACKEND_ENTRIES; index++) {
+		struct cs_fe_backend_entry *entry = &backend->entry[index];
+
+		if (entry->occupied && entry->block == block &&
+		    entry->cookie == cookie)
+			return entry;
+		if (!entry->occupied && !free)
+			free = entry;
+	}
+	if (!allocate || !free)
+		return NULL;
+	*free = (struct cs_fe_backend_entry){ .occupied = true,
+					      .block = block,
+					      .cookie = cookie };
+	return free;
+}
+
+static bool cs_be_tuple_equal(const struct cs_fe_tuple *a,
+			      const struct cs_fe_tuple *b)
+{
+	return a->src == b->src && a->dst == b->dst && a->sport == b->sport &&
+	       a->dport == b->dport;
+}
+
+static bool cs_be_link_equal(const struct cs_fe_link *a,
+			     const struct cs_fe_link *b)
+{
+	return a->gmac == b->gmac && a->tag_mode == b->tag_mode &&
+	       a->switch_port == b->switch_port && a->cpu_port == b->cpu_port &&
+	       a->base_voq == b->base_voq && a->rx_qca_meta == b->rx_qca_meta &&
+	       !memcmp(a->base_mac, b->base_mac, 6);
+}
+
+static bool cs_be_equal(const struct cs_fe_backend_lease *lease,
+			const struct cs_fe_rule *rule,
+			const struct cs_fe_key_policy *policy)
+{
+	return cs_fe_l4proto(&lease->rule, &lease->policy) ==
+		       cs_fe_l4proto(rule, policy) &&
+	       cs_be_tuple_equal(&lease->rule.original, &rule->original) &&
+	       cs_be_tuple_equal(&lease->rule.translated, &rule->translated) &&
+	       cs_be_link_equal(&lease->rule.ingress, &rule->ingress) &&
+	       cs_be_link_equal(&lease->rule.egress, &rule->egress) &&
+	       lease->rule.decrement_ttl == rule->decrement_ttl &&
+	       !memcmp(lease->rule.smac, rule->smac, 6) &&
+	       !memcmp(lease->rule.dmac, rule->dmac, 6) &&
+	       lease->policy.exact_dscp == policy->exact_dscp &&
+	       lease->policy.dscp == policy->dscp &&
+	       lease->policy.require_mtu_range == policy->require_mtu_range;
+}
+
+static bool cs_be_overlap(const struct cs_fe_rule *a,
+			  const struct cs_fe_rule *b)
+{
+	/* Codec CLASS is coarse: distinct IPs do NOT make these selectors disjoint. */
+	return a->ingress.gmac == b->ingress.gmac &&
+	       a->ingress.tag_mode == b->ingress.tag_mode &&
+	       (a->ingress.rx_qca_meta & 0xefff) ==
+		       (b->ingress.rx_qca_meta & 0xefff) &&
+	       a->original.sport == b->original.sport &&
+	       a->original.dport == b->original.dport;
+}
+
+static int cs_be_withdraw(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *io,
+			  struct cs_fe_backend_entry *entry,
+			  unsigned long long end)
+{
+	struct cs_fe_backend_lease *lease;
+	u32 zero[20] = { 0 };
+	int error;
+
+	if (!entry->active)
+		return 0;
+	lease = &backend->lease[entry->lease];
+	if (backend->before_withdraw)
+		backend->before_withdraw(backend->guard_context, io,
+					 entry->lease, &lease->plan, end);
+	error = cs_be_compare(backend, io, CS_BE_HASH, lease->plan.key.bucket,
+			      lease->plan.hash, end);
+	if (!error)
+		error = cs_be_compare(backend, io, CS_BE_CLASS,
+				      lease->rows.class_row,
+				      lease->plan.class_valid.expected, end);
+	if (!error)
+		error = cs_be_write(backend, io, CS_BE_HASH,
+				    lease->plan.key.bucket, zero, zero, end);
+	if (!error)
+		error = cs_be_write(backend, io, CS_BE_CLASS,
+				    lease->rows.class_row,
+				    lease->plan.class_invalid.input,
+				    lease->plan.class_invalid.expected, end);
+	if (!error && lease->guarded) {
+		if (!backend->guard_withdraw)
+			error = -EOPNOTSUPP;
+		else
+			error = backend->guard_withdraw(backend->guard_context,
+							io, entry->lease,
+							&lease->rows,
+							&lease->plan, end);
+	}
+	if (error) {
+		if (!io->isolate || io->isolate(io->context, entry->lease))
+			return cs_be_fail(backend, error);
+		entry->active = false;
+		lease->active = false;
+		lease->rearmable = false;
+		return 0;
+	}
+	entry->active = false;
+	lease->active = false;
+	lease->rearmable = lease->scoped && lease->guarded && !lease->marker &&
+			   backend->guard_rearm;
+	/* No dependency, bucket or reservation is freed/reused, even after success. */
+	return 0;
+}
+
+static int cs_be_program(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 struct cs_fe_backend_lease *lease,
+			 unsigned long long end)
+{
+	const struct cs_fe_rows *rows = &lease->rows;
+	const struct cs_fe_plan *plan = &lease->plan;
+	u32 zero[20] = { 0 }, cpu_voq[2] = { 56, 1U << 8 };
+	unsigned int index;
+	int error;
+
+	/* Exact closed-profile prestate; never repair or enable another owner. */
+	error = io->engine_status(io->context, &backend->status, &backend->init,
+				  end);
+	if (!error && (backend->status != 2 || backend->init))
+		error = -EUCLEAN;
+	/* Freshly verify the physically proven CPU fallback reference. */
+	if (!error)
+		error = cs_be_compare(backend, io, CS_BE_VOQ, 2, cpu_voq, end);
+#define CS_BE_FRESH(table, row)                                              \
+	do {                                                                 \
+		if (!error)                                                  \
+			error = cs_be_compare(backend, io, table, row, zero, \
+					      end);                          \
+	} while (0)
+	CS_BE_FRESH(CS_BE_CLASS, rows->class_row);
+	CS_BE_FRESH(CS_BE_SDB, rows->sdb_row);
+	CS_BE_FRESH(CS_BE_MASK, rows->mask_row);
+	CS_BE_FRESH(CS_BE_FWD, rows->miss_fwd);
+	if (!lease->shared_result) {
+		CS_BE_FRESH(CS_BE_FWD, rows->hit_fwd);
+		CS_BE_FRESH(CS_BE_VOQ, rows->voq);
+		CS_BE_FRESH(CS_BE_L2, rows->l2);
+		CS_BE_FRESH(CS_BE_L3, rows->l3);
+		CS_BE_FRESH(CS_BE_FVLAN, rows->fvlan);
+	}
+	for (index = 0; index < 3; index++)
+		CS_BE_FRESH(CS_BE_HASH, plan->key.bucket + index * 4096);
+	for (index = 0; index < 64; index++)
+		CS_BE_FRESH(CS_BE_OVERFLOW, index);
+#undef CS_BE_FRESH
+	if (error)
+		return error;
+	lease->submitted = true;
+#define CS_BE_PROGRAM_IMAGE(table, row, image)                          \
+	do {                                                            \
+		if (!error)                                             \
+			error = cs_be_write(backend, io, table, row,    \
+					    plan->image.input,          \
+					    plan->image.expected, end); \
+	} while (0)
+	if (!lease->shared_result) {
+		CS_BE_PROGRAM_IMAGE(CS_BE_VOQ, rows->voq, voq);
+		CS_BE_PROGRAM_IMAGE(CS_BE_L2, rows->l2, l2);
+		if (plan->write_l3)
+			CS_BE_PROGRAM_IMAGE(CS_BE_L3, rows->l3, l3);
+		if (plan->write_fvlan)
+			CS_BE_PROGRAM_IMAGE(CS_BE_FVLAN, rows->fvlan, fvlan);
+		CS_BE_PROGRAM_IMAGE(CS_BE_FWD, rows->hit_fwd, hit);
+	}
+	CS_BE_PROGRAM_IMAGE(CS_BE_FWD, rows->miss_fwd, miss);
+	CS_BE_PROGRAM_IMAGE(CS_BE_MASK, rows->mask_row, mask);
+	CS_BE_PROGRAM_IMAGE(CS_BE_SDB, rows->sdb_row, sdb);
+	CS_BE_PROGRAM_IMAGE(CS_BE_CLASS, rows->class_row, class_invalid);
+	if (!error && lease->guarded) {
+		if (!backend->guard_prepare)
+			error = -EOPNOTSUPP;
+		else
+			error = backend->guard_prepare(backend->guard_context,
+						       io,
+						       lease - backend->lease,
+						       rows, plan, end);
+	}
+	if (!error)
+		error = cs_be_write(backend, io, CS_BE_HASH, plan->key.bucket,
+				    plan->hash, plan->hash, end);
+	CS_BE_PROGRAM_IMAGE(CS_BE_CLASS, rows->class_row, class_valid);
+#undef CS_BE_PROGRAM_IMAGE
+	return error;
+}
+
+/*
+ * Unknown rejected cookies use one conservative block-wide version fence,
+ * not a metadata/physical lease. Older pending finishes may lose admission,
+ * but must not preserve an obsolete active version of that same cookie.
+ */
+static int cs_be_rejected(struct cs_fe_backend *backend, unsigned int block,
+			  unsigned long long version, int error)
+{
+	if (backend->block[block].rejected_through < version)
+		backend->block[block].rejected_through = version;
+	return error;
+}
+
+/*
+ * Retired cookie metadata is not a physical resource. Keep a block-wide
+ * monotonic floor so evicting it cannot let an older pending finish reappear.
+ * Known independent active DESTROY is still checked against its own version.
+ */
+static void cs_be_retire_cookie(struct cs_fe_backend *backend,
+				struct cs_fe_backend_entry *entry,
+				unsigned int block_index)
+{
+	if (backend->block[block_index].rejected_through < entry->version)
+		backend->block[block_index].rejected_through = entry->version;
+	memset(entry, 0, sizeof(*entry));
+}
+
+static bool cs_be_rows_equal(const struct cs_fe_rows *a,
+			     const struct cs_fe_rows *b)
+{
+	return a->class_row == b->class_row && a->sdb_row == b->sdb_row &&
+	       a->mask_row == b->mask_row && a->miss_fwd == b->miss_fwd &&
+	       a->hit_fwd == b->hit_fwd && a->voq == b->voq && a->l2 == b->l2 &&
+	       a->l3 == b->l3 && a->fvlan == b->fvlan &&
+	       a->priority == b->priority && a->miss_marker == b->miss_marker;
+}
+
+static bool cs_be_plan_equal(const struct cs_fe_plan *a,
+			     const struct cs_fe_plan *b)
+{
+	if (memcmp(a->key.bytes, b->key.bytes, sizeof(a->key.bytes)) ||
+	    a->key.crc32 != b->key.crc32 || a->key.crc16 != b->key.crc16 ||
+	    a->key.bucket != b->key.bucket ||
+	    memcmp(a->hash, b->hash, sizeof(a->hash)) ||
+	    !cs_fe_hot_action_equal(a, b))
+		return false;
+#define CS_BE_SAME_IMAGE(name) \
+	(a->name.words == b->name.words && \
+	 !memcmp(a->name.input, b->name.input, sizeof(a->name.input)) && \
+	 !memcmp(a->name.expected, b->name.expected, sizeof(a->name.expected)))
+	return CS_BE_SAME_IMAGE(class_invalid) && CS_BE_SAME_IMAGE(class_valid);
+#undef CS_BE_SAME_IMAGE
+}
+
+/*
+ * No dependency or ACL write here. Old in-flight references see EXACTLY the
+ * same immutable data. This is reactivation, never reclamation or ABA reuse.
+ */
+static int cs_be_rearm_graph(struct cs_fe_backend *backend,
+			     const struct cs_fe_backend_io *io,
+			     unsigned int index, unsigned long long end)
+{
+	struct cs_fe_backend_lease *lease = &backend->lease[index];
+	const struct cs_fe_rows *rows = &lease->rows;
+	const struct cs_fe_plan *plan = &lease->plan;
+	u32 zero[20] = { 0 }, cpu_voq[2] = { 56, 1U << 8 };
+	unsigned int way;
+	int error;
+
+	error = io->engine_status(io->context, &backend->status, &backend->init,
+				  end);
+	if (!error && (backend->status != 2 || backend->init))
+		error = -EUCLEAN;
+#define CS_BE_RETAINED(table, row, expected)                           \
+	do {                                                           \
+		if (!error)                                            \
+			error = cs_be_compare(backend, io, table, row, \
+					      expected, end);          \
+	} while (0)
+	CS_BE_RETAINED(CS_BE_CLASS, rows->class_row,
+		       plan->class_invalid.expected);
+	CS_BE_RETAINED(CS_BE_VOQ, 2, cpu_voq);
+	CS_BE_RETAINED(CS_BE_SDB, rows->sdb_row, plan->sdb.expected);
+	CS_BE_RETAINED(CS_BE_MASK, rows->mask_row, plan->mask.expected);
+	CS_BE_RETAINED(CS_BE_FWD, rows->miss_fwd, plan->miss.expected);
+	CS_BE_RETAINED(CS_BE_FWD, rows->hit_fwd, plan->hit.expected);
+	CS_BE_RETAINED(CS_BE_VOQ, rows->voq, plan->voq.expected);
+	CS_BE_RETAINED(CS_BE_L2, rows->l2, plan->l2.expected);
+	CS_BE_RETAINED(CS_BE_L3, rows->l3,
+		       plan->write_l3 ? plan->l3.expected : zero);
+	CS_BE_RETAINED(CS_BE_FVLAN, rows->fvlan,
+		       plan->write_fvlan ? plan->fvlan.expected : zero);
+	for (way = 0; way < 3; way++)
+		CS_BE_RETAINED(CS_BE_HASH, plan->key.bucket + way * 4096, zero);
+	for (way = 0; way < 64; way++)
+		CS_BE_RETAINED(CS_BE_OVERFLOW, way, zero);
+#undef CS_BE_RETAINED
+	if (!error)
+		error = backend->guard_rearm(backend->guard_context, io, index,
+					     rows, plan, end);
+	if (error)
+		return error;
+	lease->rearmable = false; /* BEFORE uncertain publication. */
+	error = cs_be_write(backend, io, CS_BE_HASH, plan->key.bucket,
+			    plan->hash, plan->hash, end);
+	if (!error)
+		error = cs_be_write(backend, io, CS_BE_CLASS, rows->class_row,
+				    plan->class_valid.input,
+				    plan->class_valid.expected, end);
+	return error;
+}
+
+/* 1=reactivated, 0=no identical retained scoped graph, negative=closed error. */
+static int cs_be_try_rearm(struct cs_fe_backend *backend,
+			   const struct cs_fe_backend_io *io,
+			   unsigned long long block, unsigned long cookie,
+			   unsigned long long version,
+			   const struct cs_fe_rule *rule,
+			   const struct cs_fe_key_policy *policy,
+			   unsigned int scope_grant, bool scope_exact,
+			   unsigned long long end, struct cs_fe_plan *expected)
+{
+	struct cs_fe_backend_entry *entry;
+	struct cs_fe_backend_lease *lease;
+	struct cs_fe_rows rows;
+	unsigned int index, other;
+	int error;
+
+	if (!scope_grant || !backend->guard_rearm)
+		return 0;
+	for (index = 0; index < backend->next_lease; index++) {
+		lease = &backend->lease[index];
+		if (!lease->reserved || !lease->submitted ||
+		    !lease->rearmable || lease->active || lease->marker ||
+		    !lease->scoped || !lease->guarded ||
+		    lease->scope_exact != scope_exact ||
+		    lease->scope_grant != scope_grant ||
+		    !cs_be_equal(lease, rule, policy))
+			continue;
+		if (!io->placement)
+			return -EPROTO;
+		{
+			bool shared;
+
+			error = io->placement(io->context, index, &rows,
+					      &shared);
+			if (error || shared != lease->shared_result)
+				return cs_be_fail(backend,
+						  error ? error : -EUCLEAN);
+		}
+		if (!cs_be_rows_equal(&rows, &lease->rows))
+			return cs_be_fail(backend, -EUCLEAN);
+		error = cs_fe_encode(rule, &rows, policy, expected);
+		if (!error && scope_exact)
+			cs_fe_exact_class_ipv4(expected, &rule->original,
+					       io->selector.source,
+					       io->selector.destination);
+		if (error)
+			return cs_be_fail(backend, error);
+		if (!cs_be_plan_equal(expected, &lease->plan)) {
+			/* A different Ethernet header requires a checked CLASS rebind. */
+			if (scope_exact &&
+			    cs_fe_hot_action_equal(expected, &lease->plan))
+				continue;
+			return cs_be_fail(backend, -EUCLEAN);
+		}
+		if (expected->requirements &
+		    ~(backend->admitted_requirements | scope_grant))
+			return -EOPNOTSUPP;
+		for (other = 0; other < CS_FE_BACKEND_ENTRIES; other++)
+			if (backend->entry[other].occupied &&
+			    backend->entry[other].active &&
+			    backend->entry[other].lease == index)
+				return cs_be_fail(backend, -EUCLEAN);
+		for (other = 0; other < backend->next_lease; other++)
+			if (backend->lease[other].active &&
+			    cs_be_overlap(&backend->lease[other].rule, rule))
+				return -EOPNOTSUPP;
+		entry = cs_be_entry(backend, block, cookie, true);
+		if (!entry)
+			return -ENOSPC;
+		entry->version = version;
+		entry->lease = index;
+		error = cs_be_rearm_graph(backend, io, index, end);
+		if (error)
+			return cs_be_fail(backend, error);
+		lease->active = entry->active = true;
+		backend->immutable_rearms++;
+		return 1;
+	}
+	return 0;
+}
+
+/*
+ * Mutable placement policy: choose an inactive immutable action, never reuse
+ * a different action's bucket or child rows. Owner independently verifies the
+ * canonical request and all real retained state before authorizing a rebind.
+ */
+static int cs_be_try_rekey(struct cs_fe_backend *backend,
+			   const struct cs_fe_backend_io *io,
+			   unsigned long long block, unsigned long cookie,
+			   unsigned long long version,
+			   const struct cs_fe_rule *rule,
+			   const struct cs_fe_key_policy *policy,
+			   unsigned int scope_grant, bool scope_exact,
+			   unsigned long long end, struct cs_fe_plan *candidate)
+{
+	struct cs_fe_backend_entry *entry;
+	struct cs_fe_backend_lease *lease;
+	unsigned int index, other;
+	int error;
+
+	if (!scope_grant || !scope_exact || !backend->guard_rearm ||
+	    !io->rebind || !io->receipt)
+		return 0;
+	for (index = 0; index < backend->next_lease; index++) {
+		lease = &backend->lease[index];
+		if (!lease->reserved || !lease->submitted ||
+		    !lease->rearmable || lease->active || lease->marker ||
+		    !lease->scoped || !lease->guarded ||
+		    lease->scope_exact != scope_exact ||
+		    lease->scope_grant != scope_grant ||
+		    lease->policy.exact_dscp != policy->exact_dscp ||
+		    lease->policy.dscp != policy->dscp ||
+		    lease->policy.require_mtu_range !=
+			    policy->require_mtu_range ||
+		    cs_fe_l4proto(&lease->rule, &lease->policy) !=
+			    cs_fe_l4proto(rule, policy))
+			continue;
+		error = io->receipt(io->context, index, candidate);
+		if (error || !cs_be_plan_equal(candidate, &lease->plan))
+			return cs_be_fail(backend, error ? error : -EUCLEAN);
+		error = cs_fe_encode(rule, &lease->rows, policy, candidate);
+		if (error)
+			return error;
+		cs_fe_exact_class_ipv4(candidate, &rule->original,
+				       io->selector.source,
+				       io->selector.destination);
+		if (!cs_fe_hot_action_equal(&lease->plan, candidate))
+			continue;
+		if (candidate->requirements &
+		    ~(backend->admitted_requirements | scope_grant))
+			return -EOPNOTSUPP;
+		for (other = 0; other < backend->next_lease; other++)
+			if (backend->lease[other].active &&
+			    cs_be_overlap(&backend->lease[other].rule, rule))
+				return -EOPNOTSUPP;
+		entry = cs_be_entry(backend, block, cookie, true);
+		if (!entry)
+			return -ENOSPC;
+		entry->version = version;
+		entry->lease = index;
+		error = io->rebind(io->context, index, rule, policy, candidate,
+				   end);
+		if (error == -EADDRINUSE) {
+			/*
+			 * Each slot has a different mask index in the lookup key.
+			 * The owner declined this bucket without reserving a transition.
+			 */
+			memset(entry, 0, sizeof(*entry));
+			continue;
+		}
+		if (error)
+			return cs_be_fail(backend, error);
+		lease->rearmable = false;
+		lease->rule = *rule;
+		lease->policy = *policy;
+		lease->plan = *candidate;
+		error = cs_be_write(backend, io, CS_BE_CLASS,
+				    lease->rows.class_row,
+				    candidate->class_invalid.input,
+				    candidate->class_invalid.expected, end);
+		if (!error)
+			error = backend->guard_rearm(backend->guard_context, io,
+						     index, &lease->rows,
+						     candidate, end);
+		if (!error)
+			error = cs_be_write(backend, io, CS_BE_HASH,
+					    candidate->key.bucket,
+					    candidate->hash, candidate->hash,
+					    end);
+		if (!error)
+			error = cs_be_write(backend, io, CS_BE_CLASS,
+					    lease->rows.class_row,
+					    candidate->class_valid.input,
+					    candidate->class_valid.expected,
+					    end);
+		if (error)
+			return cs_be_fail(backend, error);
+		lease->active = entry->active = true;
+		backend->immutable_rearms++;
+		return 1;
+	}
+	return 0;
+}
+
+static int
+cs_be_replace(struct cs_fe_backend *backend, const struct cs_fe_backend_io *io,
+	      unsigned long long block, unsigned long cookie,
+	      unsigned long long version, const struct cs_fe_rule *rule,
+	      const struct cs_fe_key_policy *policy, bool marker,
+	      const struct cs_fe_backend_encoding *encoding, bool guarded,
+	      unsigned int scope_grant, bool scope_exact)
+{
+	struct cs_fe_backend_entry *entry;
+	struct cs_fe_backend_lease *lease;
+	struct cs_fe_rows rows;
+	struct cs_fe_plan plan;
+	bool shared_result = false;
+	unsigned long long end;
+	unsigned int index, block_index;
+	int error;
+
+	if (!backend || cs_be_io(io) || !version)
+		return -EINVAL;
+	error = cs_be_block(backend, block);
+	if (error < 0)
+		return error;
+	block_index = error;
+	if (backend->poisoned)
+		return -EIO;
+	entry = cs_be_entry(backend, block, cookie, false);
+	if (entry && version <= entry->version)
+		return -ESTALE;
+	end = io->now_us(io->context) + CS_FE_BACKEND_US;
+	if (version <= backend->block[block_index].rejected_through) {
+		if (entry) {
+			entry->version = version;
+			error = cs_be_withdraw(backend, io, entry, end);
+			if (error)
+				return error;
+			cs_be_retire_cookie(backend, entry, block_index);
+		}
+		return -ESTALE;
+	}
+	if (entry) {
+		entry->version = version;
+		if (entry->active && rule && policy && !encoding &&
+		    backend->lease[entry->lease].marker == marker &&
+		    backend->lease[entry->lease].guarded == guarded &&
+		    backend->lease[entry->lease].scoped == !!scope_grant &&
+		    backend->lease[entry->lease].scope_exact == scope_exact &&
+		    backend->lease[entry->lease].scope_grant == scope_grant &&
+		    cs_be_equal(&backend->lease[entry->lease], rule, policy))
+			return 0;
+		error = cs_be_withdraw(backend, io, entry, end);
+		if (error)
+			return error;
+		cs_be_retire_cookie(backend, entry, block_index);
+		entry = NULL;
+	}
+	if (CS_FE_HOT_REARM && rule && policy && !marker && !encoding &&
+	    guarded && scope_grant) {
+		error = cs_be_try_rearm(backend, io, block, cookie, version,
+					rule, policy, scope_grant, scope_exact,
+					end, &plan);
+		if (error)
+			return error > 0 ? 0 :
+					   cs_be_rejected(backend, block_index,
+							  version, error);
+		error = cs_be_try_rekey(backend, io, block, cookie, version,
+					rule, policy, scope_grant, scope_exact,
+					end, &plan);
+		if (error)
+			return error > 0 ? 0 :
+					   cs_be_rejected(backend, block_index,
+							  version, error);
+	}
+	if (!rule || !policy)
+		error = -EINVAL;
+	else if (guarded &&
+		 (!backend->guard_prepare || !backend->guard_withdraw))
+		error = -EOPNOTSUPP;
+	else if (backend->next_lease == CS_FE_BACKEND_LEASES)
+		error = -ENOSPC;
+	else {
+		error = io->placement ?
+				io->placement(io->context, backend->next_lease,
+					      &rows, &shared_result) :
+				-EPROTO;
+		if (!error)
+			error = cs_fe_encode(rule, &rows, policy, &plan);
+		if (!error && marker) {
+			/*
+			 * Fixed CPU-preserving proof action, physically measured5a125.
+			 * Both IP replacements and every MAC/port/TTL edit are disabled.
+			 * This is never a successful NF hardware flow installation.
+			 */
+			memset(&plan.hit, 0, sizeof(plan.hit));
+			plan.hit.words = 4;
+			plan.hit.input[0] = 0x6824a011;
+			plan.hit.input[1] = 1;
+			memcpy(plan.hit.expected, plan.hit.input,
+			       sizeof(plan.hit.input));
+			plan.write_l3 = false;
+			plan.write_fvlan = false;
+			plan.requirements = 0;
+		}
+		if (!error && scope_grant && scope_exact)
+			cs_fe_exact_class_ipv4(&plan, &rule->original,
+					       io->selector.source,
+					       io->selector.destination);
+		if (!error && marker && encoding && encoding->exact_class) {
+			struct cs_fe_tuple classifier = rule->original;
+
+			/* The fixed probes vary only CLASS; keep the HASH unchanged. */
+			if (encoding->negative_class)
+				classifier.dst ^= 1;
+			if (encoding->class_match)
+				cs_fe_class_addresses(&plan, &classifier,
+						      rule->dmac,
+						      rule->ingress.base_mac,
+						      encoding->class_match);
+			else
+				cs_fe_exact_class_ipv4(&plan, &classifier,
+						       rule->dmac,
+						       rule->ingress.base_mac);
+		}
+		if (!error && encoding) {
+			unsigned int word, parity = 0;
+
+			/*
+			 * Actual module bytes are submitted, after the built-in semantic
+			 * verifier. No hidden regeneration of the old built-in key.
+			 */
+			plan.key = encoding->key;
+			memcpy(plan.mask.input, encoding->mask,
+			       sizeof(plan.mask.input));
+			memcpy(plan.mask.expected, encoding->mask,
+			       sizeof(plan.mask.expected));
+			for (word = 0; word < 5; word++)
+				parity ^= cs_be_parity(plan.mask.input[word]);
+			plan.mask.expected[4] |= parity << 21;
+			memcpy(plan.hit.input, encoding->action,
+			       sizeof(plan.hit.input));
+			memcpy(plan.hit.expected, encoding->action,
+			       sizeof(plan.hit.expected));
+			parity = 0;
+			for (word = 0; word < 4; word++)
+				parity ^= cs_be_parity(plan.hit.input[word]);
+			plan.hit.expected[3] |= parity << 17;
+			memset(plan.hash, 0, sizeof(plan.hash));
+			plan.hash[0] = plan.key.crc32;
+			plan.hash[1] = rows.hit_fwd |
+				       ((u32)rows.mask_row << 13);
+		}
+		if (!error && (plan.requirements &
+			       ~(backend->admitted_requirements | scope_grant)))
+			error = -EOPNOTSUPP;
+	}
+	if (error)
+		return entry ? error :
+			       cs_be_rejected(backend, block_index, version,
+					      error);
+	for (index = 0; index < backend->next_lease; index++) {
+		if (backend->lease[index].plan.key.bucket == plan.key.bucket) {
+			error = -ENOSPC;
+			break;
+		}
+		if (backend->lease[index].active &&
+		    cs_be_overlap(&backend->lease[index].rule, rule)) {
+			error = -EOPNOTSUPP;
+			break;
+		}
+	}
+	if (error)
+		return entry ? error :
+			       cs_be_rejected(backend, block_index, version,
+					      error);
+	if (!entry)
+		entry = cs_be_entry(backend, block, cookie, true);
+	if (!entry)
+		return cs_be_rejected(backend, block_index, version, -ENOSPC);
+	entry->version = version;
+	/* Claim is all-or-nothing. Rejections have no hardware or ledger effect. */
+	error = io->claim(io->context, backend->next_lease, rule, policy, &rows,
+			  &plan);
+	if (error) {
+		cs_be_retire_cookie(backend, entry, block_index);
+		return error;
+	}
+	entry->lease = backend->next_lease++;
+	lease = &backend->lease[entry->lease];
+	lease->reserved = true;
+	lease->shared_result = shared_result;
+	lease->marker = marker;
+	lease->guarded = guarded;
+	lease->scoped = !!scope_grant;
+	lease->scope_exact = scope_exact;
+	lease->scope_grant = scope_grant;
+	lease->rule = *rule;
+	lease->policy = *policy;
+	lease->rows = rows;
+	lease->plan = plan;
+	error = cs_be_program(backend, io, lease, end);
+	if (error && lease->shared_result && io->isolate &&
+	    !io->isolate(io->context, entry->lease)) {
+		cs_be_retire_cookie(backend, entry, block_index);
+		return error;
+	}
+	if (error)
+		return cs_be_fail(backend, error);
+	lease->active = true;
+	entry->active = true;
+	return 0;
+}
+
+int cs_fe_backend_replace(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *io,
+			  unsigned long long block, unsigned long cookie,
+			  unsigned long long version,
+			  const struct cs_fe_rule *rule,
+			  const struct cs_fe_key_policy *policy)
+{
+	return cs_be_replace(backend, io, block, cookie, version, rule, policy,
+			     false, NULL, false, 0, false);
+}
+
+int cs_fe_backend_replace_scoped(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy,
+				 bool exact_ingress)
+{
+	return cs_be_replace(backend, io, block, cookie, version, rule, policy,
+			     false, NULL, true,
+			     CS_FE_REQ_PACKET_EXCEPTIONS |
+				     CS_FE_REQ_COLLISION_CHECK |
+				     CS_FE_REQ_OWNER_LIFETIME,
+			     exact_ingress);
+}
+
+int cs_fe_backend_replace_guarded(struct cs_fe_backend *backend,
+				  const struct cs_fe_backend_io *io,
+				  unsigned long long block,
+				  unsigned long cookie,
+				  unsigned long long version,
+				  const struct cs_fe_rule *rule,
+				  const struct cs_fe_key_policy *policy)
+{
+	return cs_be_replace(backend, io, block, cookie, version, rule, policy,
+			     false, NULL, true, 0, false);
+}
+
+int cs_fe_backend_marker(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block, unsigned long cookie,
+			 unsigned long long version,
+			 const struct cs_fe_rule *rule,
+			 const struct cs_fe_key_policy *policy)
+{
+	return cs_be_replace(backend, io, block, cookie, version, rule, policy,
+			     true, NULL, false, 0, false);
+}
+
+int cs_fe_backend_marker_encoded(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy,
+				 const struct cs_fe_backend_encoding *encoding)
+{
+	if (!encoding)
+		return -EINVAL;
+	return cs_be_replace(backend, io, block, cookie, version, rule, policy,
+			     true, encoding, encoding->guarded, 0, false);
+}
+
+static int cs_be_end(struct cs_fe_backend *backend,
+		     const struct cs_fe_backend_io *io,
+		     unsigned long long block, unsigned long cookie,
+		     unsigned long long version, bool require_new)
+{
+	struct cs_fe_backend_entry *entry;
+	int error, block_index;
+
+	if (!backend || cs_be_io(io) || !version)
+		return -EINVAL;
+	error = cs_be_block(backend, block);
+	if (error < 0)
+		return error;
+	block_index = error;
+	if (backend->poisoned)
+		return -EIO;
+	entry = cs_be_entry(backend, block, cookie, false);
+	if (!entry)
+		return cs_be_rejected(backend, block_index, version, 0);
+	if (version < entry->version ||
+	    (require_new && version == entry->version))
+		return -ESTALE;
+	entry->version = version;
+	error = cs_be_withdraw(backend, io, entry,
+			       io->now_us(io->context) + CS_FE_BACKEND_US);
+	if (!error)
+		cs_be_retire_cookie(backend, entry, block_index);
+	return error;
+}
+
+int cs_fe_backend_destroy(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *io,
+			  unsigned long long block, unsigned long cookie,
+			  unsigned long long version)
+{
+	return cs_be_end(backend, io, block, cookie, version, false);
+}
+
+int cs_fe_backend_reject(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block, unsigned long cookie,
+			 unsigned long long version, int reason)
+{
+	int error = cs_be_end(backend, io, block, cookie, version, true);
+
+	return error ? error : reason < 0 ? reason : -EOPNOTSUPP;
+}
+
+int cs_fe_backend_unbind(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block)
+{
+	unsigned long long end;
+	unsigned int index;
+	int error, slot;
+
+	if (!backend || cs_be_io(io))
+		return -EINVAL;
+	slot = cs_be_block(backend, block);
+	if (slot == -ESHUTDOWN)
+		return backend->poisoned ? -EIO : 0;
+	if (slot < 0)
+		return slot;
+	/* Close BEFORE any I/O; a failed withdrawal never reopens this block. */
+	backend->block[slot].closed = true;
+	if (backend->poisoned)
+		return -EIO;
+	end = io->now_us(io->context) + CS_FE_BACKEND_US;
+	for (index = 0; index < CS_FE_BACKEND_ENTRIES; index++) {
+		if (!backend->entry[index].occupied ||
+		    backend->entry[index].block != block)
+			continue;
+		error = cs_be_withdraw(backend, io, &backend->entry[index],
+				       end);
+		if (error)
+			return error;
+	}
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_backend_dispatch.c b/drivers/net/ethernet/cortina/cs_fe_backend_dispatch.c
new file mode 100644
index 000000000..4ffd929a9
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_backend_dispatch.c
@@ -0,0 +1,433 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Stable private owner attachment. NAPI never calls these module methods. */
+#include <linux/atomic.h>
+#include <linux/errno.h>
+#include <linux/init.h>
+#include <linux/kobject.h>
+#include <linux/module.h>
+#include <linux/mutex.h>
+#include <linux/rwsem.h>
+#include <linux/string.h>
+#include <linux/sysfs.h>
+#include "cs_fe_hot_internal.h"
+
+static DEFINE_MUTEX(provider_control);
+static DECLARE_RWSEM(provider_calls);
+static const struct cs7542_fe_backend_ops *provider;
+static bool provider_blocked;
+static u64 provider_epoch;
+static atomic_t provider_active = ATOMIC_INIT(0);
+static struct kobject *provider_kobject;
+
+int cs7542_fe_backend_register(const struct cs7542_fe_backend_ops *ops)
+{
+	int error = 0;
+
+	if (!ops || ops->abi != CS7542_FE_BACKEND_ABI ||
+	    ops->size != sizeof(*ops) ||
+	    ops->state_size != sizeof(struct cs_fe_backend) || !ops->owner ||
+	    !ops->run || !ops->name || !ops->revision)
+		return -EINVAL;
+	if (IS_ENABLED(CONFIG_MODULE_FORCE_UNLOAD))
+		return -EOPNOTSUPP;
+	mutex_lock(&provider_control);
+	down_write(&provider_calls);
+	if (!provider_kobject)
+		error = -ENODEV;
+	else if (provider)
+		error = provider == ops && !provider_blocked ? 0 : -EBUSY;
+	else if (provider_epoch == U64_MAX)
+		error = -EOVERFLOW;
+	else if (!try_module_get(ops->owner))
+		error = -ESHUTDOWN;
+	else {
+		provider = ops;
+		provider_blocked = false;
+		provider_epoch++;
+	}
+	up_write(&provider_calls);
+	mutex_unlock(&provider_control);
+	return error;
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_backend_register);
+
+bool cs7542_fe_backend_registered(const struct cs7542_fe_backend_ops *ops)
+{
+	bool registered;
+
+	down_read(&provider_calls);
+	registered = provider == ops;
+	up_read(&provider_calls);
+	return registered;
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_backend_registered);
+
+static int cs_hot_dispatch(enum cs_fe_hot_command command,
+			   struct cs_fe_backend *backend,
+			   const struct cs_fe_backend_io *native,
+			   struct cs_fe_hot_request request)
+{
+	struct cs_fe_hot_session session;
+	struct cs_fe_backend_io typed;
+	const struct cs7542_fe_backend_ops *ops;
+	u64 blocks;
+	unsigned int leases;
+	int error;
+
+	if (!backend || !native || !backend->hot_state || !native->now_us ||
+	    !native->read32 || !native->write32)
+		return -EINVAL;
+	down_read(&provider_calls);
+	ops = provider;
+	if (!ops || provider_blocked) {
+		error = -EOPNOTSUPP;
+		goto unlock;
+	}
+	if (!try_module_get(ops->owner)) {
+		error = -ESHUTDOWN;
+		goto unlock;
+	}
+	request.selector = native->selector;
+	session = (struct cs_fe_hot_session){
+		.backend = backend,
+		.native = *native,
+		.request = request,
+		.command = command,
+	};
+	cs_fe_hot_typed_io(&session, &typed);
+	blocks = backend->next_block;
+	leases = backend->next_lease;
+	atomic_inc(&provider_active);
+	error = ops->run(command, backend, &typed, &session.request);
+	atomic_dec(&provider_active);
+	/* Physical claims and opaque handles may never rewind across versions. */
+	if (backend->next_block != blocks || backend->next_lease < leases ||
+	    backend->next_lease > CS_FE_BACKEND_LEASES) {
+		backend->poisoned = true;
+		backend->hot_state->ledger.pending = true;
+		error = -EUCLEAN;
+	}
+	module_put(
+		ops->owner); /* Builtin code: never drop final pin in module text. */
+unlock:
+	up_read(&provider_calls);
+	return error;
+}
+
+/*
+ * Builtin status never holds provider_calls while acquiring an owner mutex:
+ * ordinary callbacks already hold owner->lock before entering dispatch.
+ */
+static ssize_t status_show(struct kobject *kobj, struct kobj_attribute *attr,
+			   char *buffer)
+{
+	unsigned int contexts = 0, leases = 0, revision = 0, refs = 0;
+	char name[64] = "none";
+	u64 before, after;
+	bool registered, blocked;
+	int error;
+
+	down_read(&provider_calls);
+	before = provider_epoch;
+	registered = !!provider;
+	blocked = provider_blocked;
+	if (provider) {
+		strscpy(name, provider->name, sizeof(name));
+		revision = provider->revision;
+		refs = module_refcount(provider->owner);
+	}
+	up_read(&provider_calls);
+	error = cs_fe_live_hot_idle(&contexts, &leases, false);
+	down_read(&provider_calls);
+	after = provider_epoch;
+	up_read(&provider_calls);
+	return sysfs_emit(buffer,
+		"api=1 epoch=%llu registered=%u blocked=%u active_calls=%d contexts=%u leases=%u idle_error=%d ready_to_release=%u revision=%u module_refs=%u name=%s\n",
+		after, registered, blocked, atomic_read(&provider_active),
+		contexts, leases, error,
+		registered && !blocked && !error && before == after &&
+			refs == 1,
+		revision, refs, name);
+}
+
+static ssize_t release_store(struct kobject *kobj, struct kobj_attribute *attr,
+			     const char *buffer, size_t count)
+{
+	const struct cs7542_fe_backend_ops *ops;
+	unsigned int contexts = 0, leases = 0;
+	int error;
+
+	if (!sysfs_streq(buffer, "release"))
+		return -EINVAL;
+	mutex_lock(&provider_control);
+	down_write(
+		&provider_calls); /* Drain every synchronous algorithm call. */
+	ops = provider;
+	if (!ops) {
+		up_write(&provider_calls);
+		mutex_unlock(&provider_control);
+		return count;
+	}
+	if (ops->owner->state != MODULE_STATE_LIVE ||
+	    module_refcount(ops->owner) != 1) {
+		up_write(&provider_calls);
+		mutex_unlock(&provider_control);
+		return -EBUSY;
+	}
+	provider_blocked = true;
+	up_write(&provider_calls);
+	/* No provider rwsem held while taking owner locks or reading table cuts. */
+	error = cs_fe_live_hot_idle(&contexts, &leases, true);
+	down_write(&provider_calls);
+	if (!error && module_refcount(ops->owner) != 1)
+		error = -EBUSY;
+	if (!error) {
+		provider = NULL;
+		if (provider_epoch != U64_MAX)
+			provider_epoch++;
+		module_put(
+			ops->owner); /* Safe builtin caller; data/text no longer reachable. */
+	}
+	provider_blocked =
+		false; /* On failure keep the provider usable for cleanup. */
+	up_write(&provider_calls);
+	mutex_unlock(&provider_control);
+	return error ? error : count;
+}
+
+static struct kobj_attribute status_attribute = __ATTR_RO(status);
+static struct kobj_attribute release_attribute = __ATTR_WO(release);
+static struct attribute *provider_attributes[] = {
+	&status_attribute.attr,
+	&release_attribute.attr,
+	NULL,
+};
+
+static const struct attribute_group provider_group = {
+	.attrs = provider_attributes
+};
+
+static int __init cs_hot_manager_init(void)
+{
+	int error;
+
+	provider_kobject =
+		kobject_create_and_add("cs7542_fe_backend", kernel_kobj);
+	if (!provider_kobject)
+		return -ENOMEM;
+	error = sysfs_create_group(provider_kobject, &provider_group);
+	if (error) {
+		kobject_put(provider_kobject);
+		provider_kobject = NULL;
+	}
+	return error;
+}
+
+subsys_initcall(cs_hot_manager_init);
+
+int cs_fe_backend_init(struct cs_fe_backend *backend, unsigned int requirements)
+{
+	if (!backend || backend->initialized)
+		return -EBUSY;
+	memset(backend, 0, sizeof(*backend));
+	backend->admitted_requirements = requirements;
+	backend->initialized = true;
+	return 0;
+}
+
+int cs_fe_backend_block_open(struct cs_fe_backend *backend,
+			     unsigned long long *handle)
+{
+	unsigned int index;
+
+	if (!backend || !handle || !backend->initialized || backend->poisoned)
+		return -ENODEV;
+	if (backend->next_block == ~0ULL)
+		return -EOVERFLOW;
+	for (index = 0; index < CS_FE_BACKEND_BLOCKS; index++) {
+		if (backend->block[index].identity)
+			continue;
+		*handle = ++backend->next_block;
+		backend->block[index].identity = *handle;
+		return 0;
+	}
+	return -ENOSPC;
+}
+
+int cs_fe_backend_next_rows(const struct cs_fe_backend *backend,
+			    struct cs_fe_rows *rows)
+{
+	if (!backend || !rows || backend->poisoned || backend->pending)
+		return -EIO;
+	if (backend->next_lease >= CS_FE_BACKEND_ACTIONS)
+		return -ENOSPC;
+	*rows = cs_fe_hot_rows(backend->next_lease);
+	return 0;
+}
+
+int cs_fe_backend_forget(struct cs_fe_backend *backend,
+			 unsigned long long block)
+{
+	unsigned int index, slot = CS_FE_BACKEND_BLOCKS;
+
+	if (!backend || !block || !backend->initialized)
+		return -EINVAL;
+	if (backend->poisoned || backend->pending)
+		return -EIO;
+	for (index = 0; index < CS_FE_BACKEND_BLOCKS; index++)
+		if (backend->block[index].identity == block)
+			slot = index;
+	if (slot == CS_FE_BACKEND_BLOCKS)
+		return 0; /* Already forgotten; a late finish still gets ENOENT. */
+	if (!backend->block[slot].closed)
+		return -EBUSY;
+	for (index = 0; index < CS_FE_BACKEND_ENTRIES; index++)
+		if (backend->entry[index].occupied &&
+		    backend->entry[index].block == block &&
+		    backend->entry[index].active)
+			return -EBUSY;
+	for (index = 0; index < CS_FE_BACKEND_ENTRIES; index++)
+		if (backend->entry[index].block == block)
+			memset(&backend->entry[index], 0,
+			       sizeof(backend->entry[index]));
+	memset(&backend->block[slot], 0, sizeof(backend->block[slot]));
+	return 0;
+}
+
+int cs_fe_backend_replace(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *io,
+			  unsigned long long block, unsigned long cookie,
+			  unsigned long long version,
+			  const struct cs_fe_rule *rule,
+			  const struct cs_fe_key_policy *policy)
+{
+	struct cs_fe_hot_request request = {
+		.block = block,
+		.cookie = cookie,
+		.version = version,
+		.rule = rule,
+		.policy = policy,
+	};
+	return cs_hot_dispatch(CS_HOT_REPLACE, backend, io, request);
+}
+
+int cs_fe_backend_replace_native(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy)
+{
+	struct cs_fe_hot_request request = {
+		.block = block,
+		.cookie = cookie,
+		.version = version,
+		.rule = rule,
+		.policy = policy,
+		.exact = true,
+	};
+	return cs_hot_dispatch(CS_HOT_NATIVE, backend, io, request);
+}
+
+int cs_fe_backend_replace_scoped(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy,
+				 bool exact_ingress)
+{
+	struct cs_fe_hot_request request = {
+		.block = block,
+		.cookie = cookie,
+		.version = version,
+		.rule = rule,
+		.policy = policy,
+		.exact = exact_ingress,
+	};
+	return cs_hot_dispatch(CS_HOT_SCOPED, backend, io, request);
+}
+
+int cs_fe_backend_replace_guarded(struct cs_fe_backend *backend,
+				  const struct cs_fe_backend_io *io,
+				  unsigned long long block,
+				  unsigned long cookie,
+				  unsigned long long version,
+				  const struct cs_fe_rule *rule,
+				  const struct cs_fe_key_policy *policy)
+{
+	struct cs_fe_hot_request request = {
+		.block = block,
+		.cookie = cookie,
+		.version = version,
+		.rule = rule,
+		.policy = policy,
+	};
+	return cs_hot_dispatch(CS_HOT_GUARDED, backend, io, request);
+}
+
+int cs_fe_backend_marker(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block, unsigned long cookie,
+			 unsigned long long version,
+			 const struct cs_fe_rule *rule,
+			 const struct cs_fe_key_policy *policy)
+{
+	struct cs_fe_hot_request request = {
+		.block = block,
+		.cookie = cookie,
+		.version = version,
+		.rule = rule,
+		.policy = policy,
+	};
+	return cs_hot_dispatch(CS_HOT_MARKER, backend, io, request);
+}
+
+int cs_fe_backend_marker_encoded(struct cs_fe_backend *backend,
+				 const struct cs_fe_backend_io *io,
+				 unsigned long long block, unsigned long cookie,
+				 unsigned long long version,
+				 const struct cs_fe_rule *rule,
+				 const struct cs_fe_key_policy *policy,
+				 const struct cs_fe_backend_encoding *encoding)
+{
+	struct cs_fe_hot_request request = { .block = block,
+					     .cookie = cookie,
+					     .version = version,
+					     .rule = rule,
+					     .policy = policy,
+					     .encoding = encoding };
+	return cs_hot_dispatch(CS_HOT_ENCODED, backend, io, request);
+}
+
+int cs_fe_backend_reject(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block, unsigned long cookie,
+			 unsigned long long version, int reason)
+{
+	struct cs_fe_hot_request request = { .block = block,
+					     .cookie = cookie,
+					     .version = version,
+					     .reason = reason };
+	return cs_hot_dispatch(CS_HOT_REJECT, backend, io, request);
+}
+
+int cs_fe_backend_destroy(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *io,
+			  unsigned long long block, unsigned long cookie,
+			  unsigned long long version)
+{
+	struct cs_fe_hot_request request = { .block = block,
+					     .cookie = cookie,
+					     .version = version };
+	return cs_hot_dispatch(CS_HOT_DESTROY, backend, io, request);
+}
+
+int cs_fe_backend_unbind(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 unsigned long long block)
+{
+	struct cs_fe_hot_request request = { .block = block };
+
+	return cs_hot_dispatch(CS_HOT_UNBIND, backend, io, request);
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_backend_module.c b/drivers/net/ethernet/cortina/cs_fe_backend_module.c
new file mode 100644
index 000000000..9082e055c
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_backend_module.c
@@ -0,0 +1,164 @@
+// SPDX-License-Identifier: GPL-2.0
+#ifndef CS_FE_HOT_REARM
+#define CS_FE_HOT_REARM 1
+#endif
+#include <linux/module.h>
+#include <linux/moduleparam.h>
+#include <linux/errno.h>
+#include <linux/sysfs.h>
+#include <linux/cs7542_fe_backend.h>
+#define cs_fe_backend_init hot_cs_fe_backend_init
+#define cs_fe_backend_block_open hot_cs_fe_backend_block_open
+#define cs_fe_backend_next_rows hot_cs_fe_backend_next_rows
+#define cs_fe_backend_replace hot_cs_fe_backend_replace
+#define cs_fe_backend_replace_scoped hot_cs_fe_backend_replace_scoped
+#define cs_fe_backend_replace_guarded hot_cs_fe_backend_replace_guarded
+#define cs_fe_backend_marker hot_cs_fe_backend_marker
+#define cs_fe_backend_marker_encoded hot_cs_fe_backend_marker_encoded
+#define cs_fe_backend_destroy hot_cs_fe_backend_destroy
+#define cs_fe_backend_reject hot_cs_fe_backend_reject
+#define cs_fe_backend_unbind hot_cs_fe_backend_unbind
+#define cs_fe_backend_forget hot_cs_fe_backend_forget
+#include "cs_fe_backend.h"
+#undef cs_fe_backend_init
+#undef cs_fe_backend_block_open
+#undef cs_fe_backend_next_rows
+#undef cs_fe_backend_replace
+#undef cs_fe_backend_replace_scoped
+#undef cs_fe_backend_replace_guarded
+#undef cs_fe_backend_marker
+#undef cs_fe_backend_marker_encoded
+#undef cs_fe_backend_destroy
+#undef cs_fe_backend_reject
+#undef cs_fe_backend_unbind
+#undef cs_fe_backend_forget
+
+/* Native TCP requests carry an established nftables flow and a checked tuple. */
+#ifndef CS_FE_WIRED_TCP
+#define CS_FE_WIRED_TCP 1
+#endif
+#if IS_ENABLED(CONFIG_CS7542_FE_WIRED) && CS_FE_WIRED_TCP
+#define CS_FE_REVISION 8
+#define CS_FE_VERSION "8"
+#define CS_FE_NAME "native-wired-tcp-udp"
+#elif IS_ENABLED(CONFIG_CS7542_FE_WIRED)
+#define CS_FE_REVISION 7
+#define CS_FE_VERSION "7"
+#define CS_FE_NAME "native-wired-udp"
+#elif CS_FE_HOT_REARM
+#define CS_FE_REVISION 3
+#define CS_FE_VERSION "3"
+#define CS_FE_NAME "sdk-identical-rebind"
+#else
+#define CS_FE_REVISION 1
+#define CS_FE_VERSION "1"
+#define CS_FE_NAME "fresh-only"
+#endif
+static int algorithm_run(enum cs_fe_hot_command command,
+			 struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io,
+			 const struct cs_fe_hot_request *request)
+{
+	switch (command) {
+	case CS_HOT_NATIVE:
+		/*
+		 * Run supported wired flows through the replaceable backend.
+		 * The owner supplies observed wire addresses, a route MTU and its strict
+		 * per-packet policy. Older revisions reject this operation.
+		 */
+#if IS_ENABLED(CONFIG_CS7542_FE_WIRED)
+		if (!request->rule || !request->policy || !request->exact ||
+		    !request->selector.valid ||
+		    (cs_fe_l4proto(request->rule, request->policy) !=
+			     CS_FE_L4_UDP &&
+		     (!CS_FE_WIRED_TCP ||
+		      cs_fe_l4proto(request->rule, request->policy) !=
+			      CS_FE_L4_TCP)) ||
+		    !request->policy->require_mtu_range ||
+		    request->policy->exact_dscp)
+			return -EOPNOTSUPP;
+		return hot_cs_fe_backend_replace_scoped(backend, io, request->block,
+			request->cookie,
+			request->version, request->rule, request->policy, true);
+#else
+		return -EOPNOTSUPP;
+#endif
+	case CS_HOT_REPLACE:
+		return hot_cs_fe_backend_replace(backend, io, request->block,
+			request->cookie,
+			request->version, request->rule, request->policy);
+	case CS_HOT_SCOPED:
+		return hot_cs_fe_backend_replace_scoped(backend, io, request->block,
+			request->cookie,
+			request->version, request->rule, request->policy,
+			request->exact);
+	case CS_HOT_GUARDED:
+		return hot_cs_fe_backend_replace_guarded(backend, io, request->block,
+			request->cookie,
+			request->version, request->rule, request->policy);
+	case CS_HOT_MARKER:
+		return hot_cs_fe_backend_marker(backend, io, request->block,
+						request->cookie,
+						request->version, request->rule,
+						request->policy);
+	case CS_HOT_ENCODED:
+		return hot_cs_fe_backend_marker_encoded(backend, io, request->block,
+			request->cookie,
+			request->version, request->rule, request->policy,
+			request->encoding);
+	case CS_HOT_REJECT:
+		return hot_cs_fe_backend_reject(backend, io, request->block,
+						request->cookie,
+						request->version,
+						request->reason);
+	case CS_HOT_DESTROY:
+		return hot_cs_fe_backend_destroy(backend, io, request->block,
+						 request->cookie,
+						 request->version);
+	case CS_HOT_UNBIND:
+		return hot_cs_fe_backend_unbind(backend, io, request->block);
+	}
+	return -EOPNOTSUPP;
+}
+
+static const struct cs7542_fe_backend_ops algorithm_ops = {
+	.abi = CS7542_FE_BACKEND_ABI,
+	.size = sizeof(algorithm_ops),
+	.state_size = sizeof(struct cs_fe_backend),
+	.revision = CS_FE_REVISION,
+	.owner = THIS_MODULE,
+	.name = CS_FE_NAME,
+	.run = algorithm_run,
+};
+
+static unsigned int revision = CS_FE_REVISION;
+
+module_param(revision, uint, 0444);
+static int attach_set(const char *value, const struct kernel_param *parameter)
+{
+	(void)parameter;
+	if (!sysfs_streq(value, "attach"))
+		return -EINVAL;
+	return cs7542_fe_backend_register(&algorithm_ops);
+}
+
+static const struct kernel_param_ops attach_ops = { .set = attach_set };
+
+module_param_cb(attach, &attach_ops, NULL, 0200);
+static int __init algorithm_init(void)
+{
+	/* Registration is last: no later failure can free accepted module text. */
+	return cs7542_fe_backend_register(&algorithm_ops);
+}
+
+static void __exit algorithm_exit(void)
+{
+	WARN_ON(cs7542_fe_backend_registered(&algorithm_ops));
+	/* Builtin release already drained calls and verified the visibility cut. */
+}
+
+module_init(algorithm_init);
+module_exit(algorithm_exit);
+MODULE_LICENSE("GPL");
+MODULE_INFO(version, CS_FE_VERSION);
+MODULE_INFO(description, "Private replaceable CS7542 FE placement backend");
diff --git a/drivers/net/ethernet/cortina/cs_fe_encode.c b/drivers/net/ethernet/cortina/cs_fe_encode.c
new file mode 100644
index 000000000..e968a5c6c
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_encode.c
@@ -0,0 +1,562 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "cs_fe_encode.h"
+#ifdef __KERNEL__
+#include <linux/array_size.h>
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))
+#include <errno.h>
+#include <string.h>
+#endif
+/* cs75xx_fe_core_table.h: declared HASH key bit offsets. */
+enum lookup_key_offset {
+	KEY_ETHERTYPE = 96,
+	KEY_OUTER_TPID = 116,
+	KEY_OUTER_PCP = 119,
+	KEY_OUTER_DEI = 122,
+	KEY_OUTER_VID = 123,
+	KEY_IPV4_DESTINATION = 155,
+	KEY_IPV4_SOURCE = 283,
+	KEY_PROTOCOL = 411,
+	KEY_DSCP = 419,
+	KEY_PKTLEN_RANGE_VECTOR = 427,
+	KEY_IP_VALID = 452,
+	KEY_DESTINATION_PORT = 453,
+	KEY_SOURCE_PORT = 469,
+	KEY_L4_VALID = 494,
+	KEY_LSPID = 501,
+	KEY_MASK_POINTER = 526,
+};
+
+/* Named fields from the pinned primary descriptors. */
+#include "cs_fe_fields.h"
+#define LOOKUP_FIELD(words, name, value) \
+	lookup_store_bits(words, name##_START, name##_WIDTH, value)
+
+static void lookup_store_bits(u32 *words, unsigned int start,
+			      unsigned int width, u32 value)
+{
+	unsigned int index, bit;
+
+	for (index = 0; index < width; index++) {
+		bit = start + index;
+		words[bit / 32] &= ~(1U << (bit % 32));
+		words[bit / 32] |= ((value >> index) & 1U) << (bit % 32);
+	}
+}
+
+static void lookup_key_bits(u8 key[84], unsigned int start, unsigned int width,
+			    u32 value)
+{
+	unsigned int index;
+
+	for (index = 0; index < width; index++)
+		key[(start + index) / 8] |= ((value >> index) & 1U)
+					    << ((start + index) % 8);
+}
+
+static u32 lookup_reverse(u32 value, unsigned int width)
+{
+	u32 reversed = 0;
+	unsigned int index;
+
+	for (index = 0; index < width; index++) {
+		reversed = (reversed << 1) | (value & 1U);
+		value >>= 1;
+	}
+	return reversed;
+}
+
+static void build_key(const struct cs_fe_rule *rule,
+		      const struct cs_fe_rows *rows,
+		      const struct cs_fe_key_policy *policy,
+		      struct cs_fe_key *key)
+{
+	const unsigned int mac_len = sizeof(rule->ingress.base_mac);
+	u32 crc32 = 0xffffffffU;
+	u32 crc16 = 0xffffU;
+	unsigned int index, bit, input;
+
+	/* FE_HASH_DA occupies the first 48 bits, least significant byte first. */
+	for (index = 0; index < mac_len; index++)
+		key->bytes[index] = rule->ingress.base_mac[mac_len - 1 - index];
+
+	if (rule->ingress.tag_mode == 4) {
+		lookup_key_bits(key->bytes, KEY_OUTER_TPID, 3, 4);
+		lookup_key_bits(key->bytes, KEY_OUTER_PCP, 3,
+				rule->ingress.rx_qca_meta >> 13);
+		lookup_key_bits(key->bytes, KEY_OUTER_DEI, 1,
+				(rule->ingress.rx_qca_meta >> 12) & 1);
+		lookup_key_bits(key->bytes, KEY_OUTER_VID, 12,
+				rule->ingress.rx_qca_meta & 4095);
+	} else {
+		lookup_key_bits(key->bytes, KEY_ETHERTYPE, 16, 0x0800);
+	}
+
+	lookup_key_bits(key->bytes, KEY_IPV4_DESTINATION, 32,
+			rule->original.dst);
+	lookup_key_bits(key->bytes, KEY_IPV4_SOURCE, 32, rule->original.src);
+	lookup_key_bits(key->bytes, KEY_PROTOCOL, 8,
+			cs_fe_l4proto(rule, policy));
+	lookup_key_bits(key->bytes, KEY_DSCP, 6,
+			policy->exact_dscp ? policy->dscp : 0);
+	if (policy->require_mtu_range)
+		lookup_key_bits(key->bytes, KEY_PKTLEN_RANGE_VECTOR, 4,
+				policy->require_mtu_range);
+	lookup_key_bits(key->bytes, KEY_IP_VALID, 1, 1);
+	lookup_key_bits(key->bytes, KEY_DESTINATION_PORT, 16,
+			rule->original.dport);
+	lookup_key_bits(key->bytes, KEY_SOURCE_PORT, 16, rule->original.sport);
+	lookup_key_bits(key->bytes, KEY_L4_VALID, 1, 1);
+	lookup_key_bits(key->bytes, KEY_LSPID, 4, rule->ingress.gmac);
+	lookup_key_bits(key->bytes, KEY_MASK_POINTER, 6, rows->mask_row);
+
+	for (index = 0; index < sizeof(key->bytes); index++) {
+		for (bit = 0; bit < 8; bit++) {
+			input = (key->bytes[index] >> bit) & 1U;
+			crc32 = (crc32 >> 1) ^
+				(((crc32 ^ input) & 1U) ? 0xedb88320U : 0);
+			crc16 = (crc16 >> 1) ^
+				(((crc16 ^ input) & 1U) ? 0x8408U : 0);
+		}
+	}
+
+	key->crc32 = lookup_reverse(crc32, 32);
+	key->crc16 = lookup_reverse(crc16, 16);
+	key->bucket = key->crc16 >> 4;
+}
+
+static void build_mask(const struct cs_fe_rule *rule,
+		       const struct cs_fe_key_policy *policy, u32 out[5])
+{
+	u32 payload[5] = { 0 };
+
+	unsigned int index;
+
+	for (index = 0;
+	     index < ARRAY_SIZE(cs_fe_mask_fields);
+	     index++) {
+		const struct cs_fe_mask_field *field =
+			&cs_fe_mask_fields[index];
+
+		lookup_store_bits(payload, field->start, field->width,
+				  (1U << field->width) - 1);
+	}
+#define INCLUDE_MASK(name, value) \
+	lookup_store_bits(payload, name##_START, name##_WIDTH, value)
+	/* Vendor scalar include0, full IP128 and CCITT polynomial0. */
+	INCLUDE_MASK(FE_HM_MAC_DA_MASK, 0);
+	INCLUDE_MASK(FE_HM_TPID_ENC_1_MSB_MASK, 0);
+	INCLUDE_MASK(FE_HM_TPID_ENC_1_LSB_MASK, 0);
+	INCLUDE_MASK(FE_HM_8021P_1_MASK, 0);
+	INCLUDE_MASK(FE_HM_DEI_1_MASK, 0);
+	INCLUDE_MASK(FE_HM_VID_1_MASK, 0);
+	INCLUDE_MASK(FE_HM_TPID_ENC_2_MSB_MASK, 0);
+	INCLUDE_MASK(FE_HM_PPPOE_SESSION_ID_VLD_MASK, 0);
+	INCLUDE_MASK(FE_HM_IP_DA_MASK, 128);
+	INCLUDE_MASK(FE_HM_IP_SA_MASK, 128);
+	INCLUDE_MASK(FE_HM_IP_PROT_MASK, 0);
+	/*
+	 * SDK TCP_CTRL_MASK ignores URG, ACK and PSH. The zero-initialized
+	 * TCP control key (bits 485..490) requires RST, SYN and FIN clear.
+	 * Otherwise this SDB returns the original frame to the CPU.
+	 */
+	if (cs_fe_l4proto(rule, policy) == CS_FE_L4_TCP)
+		INCLUDE_MASK(FE_HM_TCP_CTRL_MASK, 0x38);
+	INCLUDE_MASK(FE_HM_DSCP_MASK, policy->exact_dscp ? 0 : 1);
+	if (!rule->ingress.tag_mode)
+		INCLUDE_MASK(FE_HM_ETHERTYPE_MASK, 0);
+	INCLUDE_MASK(FE_HM_IP_FRAGMENT_MASK, 0);
+	if (policy->require_mtu_range) {
+		/*
+		 * Compare the positive range bit and require clear parser errors.
+		 * No new ACL action can override other firewall decisions.
+		 */
+		INCLUDE_MASK(FE_HM_PKTLEN_RNG_MATCH_VECTOR_MASK,
+			     0xfU ^ policy->require_mtu_range);
+		INCLUDE_MASK(FE_HM_L3_CHKSUM_ERR_MASK, 0);
+		INCLUDE_MASK(FE_HM_L4_CHKSUM_ERR_MASK, 0);
+		INCLUDE_MASK(FE_HM_NOT_HDR_A_FLAGS_STSVLD_MASK, 0);
+	}
+	INCLUDE_MASK(FE_HM_KEYGEN_POLY_SEL, 0);
+	INCLUDE_MASK(FE_HM_IP_VER_MASK, 0);
+	INCLUDE_MASK(FE_HM_IP_VLD_MASK, 0);
+	INCLUDE_MASK(FE_HM_L4_PORTS_RNGD, 0);
+	INCLUDE_MASK(FE_HM_L4_DP_MASK, 0);
+	INCLUDE_MASK(FE_HM_L4_SP_MASK, 0);
+	INCLUDE_MASK(FE_HM_L4_VLD_MASK, 0);
+	INCLUDE_MASK(FE_HM_LSPID_MASK, 0);
+	/* Preserve the observed reserved bit instead of copying legacy memsetff. */
+	INCLUDE_MASK(FE_HM_RSVD_109, 0);
+	INCLUDE_MASK(FE_HM_PARITY, 0);
+#undef INCLUDE_MASK
+	memcpy(out, payload, sizeof(payload));
+}
+
+static void build_sdb(const struct cs_fe_rows *rows, u32 out[7])
+{
+	u32 payload[7] = { 0 };
+
+	/* SDB tuple0 enable[0], mask[6:1], priority[10:7]. */
+	LOOKUP_FIELD(payload, FE_SDB_HTUPL_EN_0, 1);
+	LOOKUP_FIELD(payload, FE_SDB_HTUPL_MASK_PTR_0, rows->mask_row);
+	LOOKUP_FIELD(payload, FE_SDB_HTUPL_PRI_0, 0);
+	LOOKUP_FIELD(payload, FE_SDB_TTL_HOPLIMIT_ZERO_DISCARD_EN,
+		     1); /* inherited TTL-zero policy */
+	LOOKUP_FIELD(payload, FE_SDB_UU_FLOWIDX,
+		     rows->miss_fwd); /* unknown unicast */
+	LOOKUP_FIELD(payload, FE_SDB_BC_FLOWIDX,
+		     rows->miss_fwd); /* broadcast */
+	LOOKUP_FIELD(payload, FE_SDB_UM_FLOWIDX,
+		     rows->miss_fwd); /* unknown multicast */
+	/* KEYRULE0, LPM/other tuples/drop/rewrites/ACL override remain zero. */
+	memcpy(out, payload, sizeof(payload));
+}
+
+static void build_class(const struct cs_fe_rule *rule,
+			const struct cs_fe_rows *rows, u8 l4proto, bool valid,
+			u32 out[20])
+{
+	u32 payload[20];
+	unsigned int index;
+
+	for (index = 0; index < 20; index++)
+		payload[index] = 0xffffffffU;
+	/* A coarse typed protocol/port/domain selector; full tuple goes in HASH. */
+	LOOKUP_FIELD(payload, FE_CLASS_SVIDX, rows->sdb_row);
+	LOOKUP_FIELD(payload, FE_CLASS_LSPID, rule->ingress.gmac);
+	LOOKUP_FIELD(payload, FE_CLASS_LSPID_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_TPID_ENC_1,
+		     rule->ingress.tag_mode ? 4 : 0);
+	LOOKUP_FIELD(payload, FE_CLASS_8021P_1,
+		     rule->ingress.rx_qca_meta >> 13);
+	LOOKUP_FIELD(payload, FE_CLASS_VID_1, rule->ingress.rx_qca_meta & 4095);
+	LOOKUP_FIELD(payload, FE_CLASS_TPID_ENC_2, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_TPID_ENC_1_MSB_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_TPID_ENC_1_LSB_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_8021P_1_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_VID_1_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_TPID_ENC_2_MSB_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_DA_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_SA_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_MCGID, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_MCGID_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_RSVD_621_606, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_RULE_PRI, rows->priority);
+	LOOKUP_FIELD(payload, FE_CLASS_ENTRY_VLD, valid);
+	LOOKUP_FIELD(payload, FE_CLASS_MEM_PARITY, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_DATA19_RSRVD, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_PROT, l4proto);
+	LOOKUP_FIELD(payload, FE_CLASS_L4_SP, rule->original.sport);
+	LOOKUP_FIELD(payload, FE_CLASS_L4_DP, rule->original.dport);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_VLD, 1);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_VER, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_FRAGMENT, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_L4_VLD, 1);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_PROT_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_L4_PORT_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_VLD_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_VER_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_IP_FRAGMENT_MASK, 0);
+	LOOKUP_FIELD(payload, FE_CLASS_L4_VLD_MASK, 0);
+	memcpy(out, payload, sizeof(payload));
+}
+
+static void cs_fe_finish_image(u32 *input, u32 *expected, unsigned int words,
+			       int parity_bit)
+{
+	unsigned int index, bit, ones = 0;
+
+	if (parity_bit >= 0)
+		lookup_store_bits(input, parity_bit, 1, 0);
+	memcpy(expected, input, words * sizeof(*input));
+	if (parity_bit < 0)
+		return;
+
+	for (index = 0; index < words; index++) {
+		for (bit = 0; bit < 32; bit++)
+			ones += (input[index] >> bit) & 1;
+	}
+	lookup_store_bits(expected, parity_bit, 1, ones & 1);
+}
+
+#define CS_FE_FINISH_IMAGE(member, count, parity)                            \
+	do {                                                                 \
+		(member).words = count;                                      \
+		cs_fe_finish_image((member).input, (member).expected, count, \
+				   parity);                                  \
+	} while (0)
+/*
+ * CLASS address fields from cs_fe_class_fields in the vendor register map.
+ * IPv4 occupies the first of four words. The CLASS IP masks encode a prefix
+ * length, as in the vendor IPv4 multicast class (prefix 4).
+ */
+static void cs_fe_class_ip(u32 *words, unsigned int start, u32 address)
+{
+	unsigned int index;
+
+	lookup_store_bits(words, start, 32, address);
+	for (index = 1; index < 4; index++)
+		lookup_store_bits(words, start + 32 * index, 32, 0);
+}
+
+static void cs_fe_class_mac(u32 *words, unsigned int start, const u8 address[6],
+			    bool reverse)
+{
+	unsigned int index;
+
+	for (index = 0; index < 6; index++)
+		lookup_store_bits(words, start + 8 * index, 8,
+				  address[reverse ? 5 - index : index]);
+}
+
+static void cs_fe_class_address_inputs(u32 *words,
+				       const struct cs_fe_tuple *tuple,
+				       const u8 source[6],
+				       const u8 destination[6],
+				       unsigned int match)
+{
+	bool reverse = match & CS_FE_CLASS_MATCH_REVERSED_MAC;
+
+	if (match & CS_FE_CLASS_MATCH_DA) {
+		cs_fe_class_mac(words, FE_CLASS_DA_START, destination, reverse);
+		LOOKUP_FIELD(words, FE_CLASS_DA_MASK, 0);
+	}
+	if (match & CS_FE_CLASS_MATCH_SA) {
+		cs_fe_class_mac(words, FE_CLASS_SA_START, source, reverse);
+		LOOKUP_FIELD(words, FE_CLASS_SA_MASK, 0);
+	}
+	if (match & CS_FE_CLASS_MATCH_IP_DA) {
+		cs_fe_class_ip(words, FE_CLASS_IP_DA_START, tuple->dst);
+		LOOKUP_FIELD(words, FE_CLASS_IP_DA_MASK, 32);
+	}
+	if (match & CS_FE_CLASS_MATCH_IP_SA) {
+		cs_fe_class_ip(words, FE_CLASS_IP_SA_START, tuple->src);
+		LOOKUP_FIELD(words, FE_CLASS_IP_SA_MASK, 32);
+	}
+}
+
+void cs_fe_class_addresses(struct cs_fe_plan *plan,
+			   const struct cs_fe_tuple *tuple, const u8 source[6],
+			   const u8 destination[6], unsigned int match)
+{
+	cs_fe_class_address_inputs(plan->class_invalid.input, tuple, source,
+				   destination, match);
+	cs_fe_class_address_inputs(plan->class_valid.input, tuple, source,
+				   destination, match);
+	CS_FE_FINISH_IMAGE(plan->class_invalid, 20, 629);
+	CS_FE_FINISH_IMAGE(plan->class_valid, 20, 629);
+}
+
+/*
+ * The wire-order MAC pairs use the following ordering. The selected CS7542 CLASS
+ * MAC comparison consumes the octets starting with the least
+ * significant byte, independently of the IPv4 word order.
+ */
+void cs_fe_exact_class_ipv4(struct cs_fe_plan *plan,
+			    const struct cs_fe_tuple *tuple, const u8 source[6],
+			    const u8 destination[6])
+{
+	cs_fe_class_addresses(plan, tuple, source, destination,
+			      CS_FE_CLASS_MATCH_DA | CS_FE_CLASS_MATCH_SA |
+				      CS_FE_CLASS_MATCH_REVERSED_MAC |
+				      CS_FE_CLASS_MATCH_IP_DA |
+				      CS_FE_CLASS_MATCH_IP_SA);
+}
+
+static bool cs_fe_mac_valid(const u8 *mac)
+{
+	unsigned int index, nonzero = 0;
+
+	for (index = 0; index < 6; index++)
+		nonzero |= mac[index];
+	return nonzero && !(mac[0] & 1);
+}
+
+static bool cs_fe_ip_valid(u32 address)
+{
+	return address && (address >> 24) != 0 && (address >> 24) != 127 &&
+	       (address >> 24) < 224;
+}
+
+static int cs_fe_link_valid(const struct cs_fe_link *link)
+{
+	unsigned int reason = (link->rx_qca_meta >> 6) & 31;
+
+	if (link->gmac != 1 || link->base_voq != 8 || link->cpu_port)
+		return -EOPNOTSUPP;
+
+	if (link->tag_mode == 4) {
+		if (link->switch_port < 1 || link->switch_port > 5)
+			return -EOPNOTSUPP;
+		/* Egress metadata may be0: it is not used for the ingress key. */
+		if (link->rx_qca_meta &&
+		    ((link->rx_qca_meta >> 14) != 2 ||
+		     (link->rx_qca_meta & 7) != link->switch_port ||
+		     reason == 1 || reason == 2))
+			return -EOPNOTSUPP;
+	} else if (link->tag_mode || link->switch_port || link->rx_qca_meta) {
+		return -EOPNOTSUPP;
+	}
+
+	return 0;
+}
+
+static bool cs_fe_row_valid(u16 row, unsigned int limit)
+{
+	return row >= 5 && row < limit;
+}
+
+int cs_fe_encode(const struct cs_fe_rule *rule, const struct cs_fe_rows *rows,
+		 const struct cs_fe_key_policy *policy, struct cs_fe_plan *out)
+{
+	struct cs_fe_plan plan = { 0 };
+	unsigned long long source_mac = 0, destination_mac = 0;
+	bool source_ip_changed, destination_ip_changed;
+	bool source_port_changed, destination_port_changed;
+	u32 *fwd = plan.hit.input;
+	unsigned int index;
+
+	if (!rule || !rows || !policy || !out)
+		return -EINVAL;
+
+	if (cs_fe_link_valid(&rule->ingress) ||
+	    cs_fe_link_valid(&rule->egress) ||
+	    rule->ingress.tag_mode != rule->egress.tag_mode ||
+	    (rule->ingress.tag_mode == 4 && !rule->ingress.rx_qca_meta) ||
+	    !cs_fe_mac_valid(rule->smac) || !cs_fe_mac_valid(rule->dmac) ||
+	    !cs_fe_mac_valid(rule->ingress.base_mac) ||
+	    !cs_fe_mac_valid(rule->egress.base_mac) ||
+	    memcmp(rule->smac, rule->egress.base_mac, sizeof(rule->smac)) ||
+	    !rule->decrement_ttl)
+		return -EOPNOTSUPP;
+
+	if (cs_fe_l4proto(rule, policy) != CS_FE_L4_UDP &&
+	    (cs_fe_l4proto(rule, policy) != CS_FE_L4_TCP || policy->exact_dscp))
+		return -EOPNOTSUPP;
+
+	if (!cs_fe_ip_valid(rule->original.src) ||
+	    !cs_fe_ip_valid(rule->original.dst) ||
+	    !cs_fe_ip_valid(rule->translated.src) ||
+	    !cs_fe_ip_valid(rule->translated.dst) || !rule->original.sport ||
+	    !rule->original.dport || !rule->translated.sport ||
+	    !rule->translated.dport || policy->dscp > 63 ||
+	    (!policy->exact_dscp && policy->dscp) ||
+	    (policy->require_mtu_range != 0 &&
+	     policy->require_mtu_range != CS_FE_MTU_RANGE_SMALL &&
+	     policy->require_mtu_range != CS_FE_MTU_RANGE_1500))
+		return -EOPNOTSUPP;
+
+	if (!cs_fe_row_valid(rows->class_row, 64) ||
+	    !cs_fe_row_valid(rows->sdb_row, 64) ||
+	    !cs_fe_row_valid(rows->mask_row, 64) ||
+	    !cs_fe_row_valid(rows->miss_fwd, 8192) ||
+	    !cs_fe_row_valid(rows->hit_fwd, 8192) ||
+	    rows->miss_fwd == rows->hit_fwd ||
+	    !cs_fe_row_valid(rows->voq, 512) ||
+	    !cs_fe_row_valid(rows->l2, 512) || rows->priority > 63 ||
+	    rows->miss_marker > 0xfffffU)
+		return -ERANGE;
+
+	source_ip_changed = rule->original.src != rule->translated.src;
+	destination_ip_changed = rule->original.dst != rule->translated.dst;
+	source_port_changed = rule->original.sport != rule->translated.sport;
+	destination_port_changed = rule->original.dport !=
+				   rule->translated.dport;
+	plan.source_nat = source_ip_changed || source_port_changed;
+	plan.destination_nat = destination_ip_changed ||
+			       destination_port_changed;
+	plan.write_l3 = source_ip_changed || destination_ip_changed;
+	plan.write_fvlan = rule->egress.tag_mode == 4;
+
+	if ((plan.write_l3 && !cs_fe_row_valid(rows->l3, 1024)) ||
+	    (plan.write_fvlan && !cs_fe_row_valid(rows->fvlan, 512)))
+		return -ERANGE;
+
+	plan.requirements = CS_FE_REQ_PACKET_EXCEPTIONS |
+			    CS_FE_REQ_COLLISION_CHECK |
+			    CS_FE_REQ_OWNER_LIFETIME;
+	build_key(rule, rows, policy, &plan.key);
+	build_mask(rule, policy, plan.mask.input);
+	CS_FE_FINISH_IMAGE(plan.mask, 5, 149);
+	build_class(rule, rows, cs_fe_l4proto(rule, policy), false,
+		    plan.class_invalid.input);
+	CS_FE_FINISH_IMAGE(plan.class_invalid, 20, 629);
+	build_class(rule, rows, cs_fe_l4proto(rule, policy), true,
+		    plan.class_valid.input);
+	CS_FE_FINISH_IMAGE(plan.class_valid, 20, 629);
+	build_sdb(rows, plan.sdb.input);
+	CS_FE_FINISH_IMAGE(plan.sdb, 7, 206);
+
+	/*
+	 * Fallback uses only the physically read/verified reserved VOQ2.
+	 * Diagnostic IP-index markers are never replacement-enabled rows.
+	 */
+	LOOKUP_FIELD(plan.miss.input, FWD_VOQ_POLICY, 1);
+	LOOKUP_FIELD(plan.miss.input, FWD_VOQ_POL_TBL_IDX, 2);
+	LOOKUP_FIELD(plan.miss.input, FWD_IP_SA_IDX, rows->miss_marker & 4095);
+	LOOKUP_FIELD(plan.miss.input, FWD_IP_DA_IDX, rows->miss_marker >> 12);
+	CS_FE_FINISH_IMAGE(plan.miss, 4, 113);
+	plan.voq.input[0] = rule->egress.base_voq;
+	CS_FE_FINISH_IMAGE(plan.voq, 2, 40);
+
+	for (index = 0; index < 6; index++) {
+		source_mac = (source_mac << 8) | rule->smac[index];
+		destination_mac = (destination_mac << 8) | rule->dmac[index];
+	}
+	plan.l2.input[0] = (u32)source_mac;
+	plan.l2.input[1] = (u32)(source_mac >> 32) |
+			   ((u32)destination_mac << 16);
+	plan.l2.input[2] = (u32)(destination_mac >> 16);
+	CS_FE_FINISH_IMAGE(plan.l2, 4, 96);
+	if (plan.write_l3) {
+		/* Only the replacement indices enabled in FWDRSLT are referenced. */
+		if (source_ip_changed)
+			plan.l3.input[0] = rule->translated.src;
+		if (destination_ip_changed)
+			plan.l3.input[1] = rule->translated.dst;
+		CS_FE_FINISH_IMAGE(plan.l3, 5, 128);
+	}
+
+	LOOKUP_FIELD(fwd, FWD_VOQ_POLICY, 1);
+	LOOKUP_FIELD(fwd, FWD_VOQ_POL_TBL_IDX, rows->voq);
+	if (source_ip_changed) {
+		LOOKUP_FIELD(fwd, FWD_IP_SA_REPLACE_EN, 1);
+		LOOKUP_FIELD(fwd, FWD_IP_SA_IDX, rows->l3 * 4U);
+	}
+	if (destination_ip_changed) {
+		LOOKUP_FIELD(fwd, FWD_IP_DA_REPLACE_EN, 1);
+		LOOKUP_FIELD(fwd, FWD_IP_DA_IDX, rows->l3 * 4U + 1);
+	}
+	if (source_port_changed) {
+		LOOKUP_FIELD(fwd, FWD_L4_SP_REPLACE_EN, 1);
+		LOOKUP_FIELD(fwd, FWD_L4_SP, rule->translated.sport);
+	}
+	if (destination_port_changed) {
+		LOOKUP_FIELD(fwd, FWD_L4_DP_REPLACE_EN, 1);
+		LOOKUP_FIELD(fwd, FWD_L4_DP, rule->translated.dport);
+	}
+	LOOKUP_FIELD(fwd, FWD_MAC_SA_REPLACE_EN, 1);
+	LOOKUP_FIELD(fwd, FWD_MAC_DA_REPLACE_EN, 1);
+	LOOKUP_FIELD(fwd, FWD_L2_IDX, rows->l2);
+	LOOKUP_FIELD(fwd, FWD_DECR_TTL_HOPLIMIT, 1);
+	if (plan.write_fvlan) {
+		u16 vid = 0x80U | (1U << rule->egress.switch_port);
+
+		/* FIRST_CMD SWAP_B=2, TPID0=8100, no second operation. */
+		plan.fvlan.input[0] = 2U | ((u32)vid << 5);
+		CS_FE_FINISH_IMAGE(plan.fvlan, 2, 38);
+		LOOKUP_FIELD(fwd, FWD_FLOW_VLAN_OP_EN, 1);
+		LOOKUP_FIELD(fwd, FWD_FLOW_VLANTBL_IDX, rows->fvlan);
+		plan.predicted_tx_qca = (rule->ingress.rx_qca_meta & 0xf000U) |
+					vid;
+	}
+	CS_FE_FINISH_IMAGE(plan.hit, 4, 113);
+	lookup_store_bits(plan.hash, 0, 32, plan.key.crc32);
+	lookup_store_bits(plan.hash, 32, 13, rows->hit_fwd);
+	lookup_store_bits(plan.hash, 45, 6, rows->mask_row);
+
+	*out = plan;
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_encode.h b/drivers/net/ethernet/cortina/cs_fe_encode.h
new file mode 100644
index 000000000..56eca7a35
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_encode.h
@@ -0,0 +1,5 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_ENCODE_PRIVATE_SHIM_H
+#define CS_FE_ENCODE_PRIVATE_SHIM_H
+#include <linux/cs7542_fe_codec.h>
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_fields.h b/drivers/net/ethernet/cortina/cs_fe_fields.h
new file mode 100644
index 000000000..ce452b6d6
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_fields.h
@@ -0,0 +1,339 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/* Generated from pinned descriptor extracts; generate_fields.py checks it. */
+#ifndef CS_FE_FIELDS_H
+#define CS_FE_FIELDS_H
+
+enum cs_fe_field_offset {
+	FE_HM_MAC_DA_MASK_START = 0,
+	FE_HM_MAC_DA_MASK_WIDTH = 6,
+	FE_HM_MAC_SA_MASK_START = 6,
+	FE_HM_MAC_SA_MASK_WIDTH = 6,
+	FE_HM_ETHERTYPE_MASK_START = 12,
+	FE_HM_ETHERTYPE_MASK_WIDTH = 1,
+	FE_HM_LLC_TYPE_ENC_MSB_MASK_START = 13,
+	FE_HM_LLC_TYPE_ENC_MSB_MASK_WIDTH = 1,
+	FE_HM_LLC_TYPE_ENC_LSB_MASK_START = 14,
+	FE_HM_LLC_TYPE_ENC_LSB_MASK_WIDTH = 1,
+	FE_HM_TPID_ENC_1_MSB_MASK_START = 15,
+	FE_HM_TPID_ENC_1_MSB_MASK_WIDTH = 1,
+	FE_HM_TPID_ENC_1_LSB_MASK_START = 16,
+	FE_HM_TPID_ENC_1_LSB_MASK_WIDTH = 1,
+	FE_HM_8021P_1_MASK_START = 17,
+	FE_HM_8021P_1_MASK_WIDTH = 1,
+	FE_HM_DEI_1_MASK_START = 18,
+	FE_HM_DEI_1_MASK_WIDTH = 1,
+	FE_HM_VID_1_MASK_START = 19,
+	FE_HM_VID_1_MASK_WIDTH = 1,
+	FE_HM_TPID_ENC_2_MSB_MASK_START = 20,
+	FE_HM_TPID_ENC_2_MSB_MASK_WIDTH = 1,
+	FE_HM_TPID_ENC_2_LSB_MASK_START = 21,
+	FE_HM_TPID_ENC_2_LSB_MASK_WIDTH = 1,
+	FE_HM_8021P_2_MASK_START = 22,
+	FE_HM_8021P_2_MASK_WIDTH = 1,
+	FE_HM_DEI_2_MASK_START = 23,
+	FE_HM_DEI_2_MASK_WIDTH = 1,
+	FE_HM_VID_2_MASK_START = 24,
+	FE_HM_VID_2_MASK_WIDTH = 1,
+	FE_HM_IP_DA_MASK_START = 25,
+	FE_HM_IP_DA_MASK_WIDTH = 9,
+	FE_HM_IP_SA_MASK_START = 34,
+	FE_HM_IP_SA_MASK_WIDTH = 9,
+	FE_HM_IP_PROT_MASK_START = 43,
+	FE_HM_IP_PROT_MASK_WIDTH = 1,
+	FE_HM_DSCP_MASK_START = 44,
+	FE_HM_DSCP_MASK_WIDTH = 6,
+	FE_HM_ECN_MASK_START = 50,
+	FE_HM_ECN_MASK_WIDTH = 2,
+	FE_HM_IP_FRAGMENT_MASK_START = 52,
+	FE_HM_IP_FRAGMENT_MASK_WIDTH = 1,
+	FE_HM_KEYGEN_POLY_SEL_START = 53,
+	FE_HM_KEYGEN_POLY_SEL_WIDTH = 2,
+	FE_HM_IPV6_FLOW_LBL_MASK_START = 55,
+	FE_HM_IPV6_FLOW_LBL_MASK_WIDTH = 1,
+	FE_HM_IP_VER_MASK_START = 56,
+	FE_HM_IP_VER_MASK_WIDTH = 1,
+	FE_HM_IP_VLD_MASK_START = 57,
+	FE_HM_IP_VLD_MASK_WIDTH = 1,
+	FE_HM_L4_PORTS_RNGD_START = 58,
+	FE_HM_L4_PORTS_RNGD_WIDTH = 2,
+	FE_HM_L4_DP_MASK_START = 60,
+	FE_HM_L4_DP_MASK_WIDTH = 16,
+	FE_HM_L4_SP_MASK_START = 76,
+	FE_HM_L4_SP_MASK_WIDTH = 16,
+	FE_HM_TCP_CTRL_MASK_START = 92,
+	FE_HM_TCP_CTRL_MASK_WIDTH = 6,
+	FE_HM_TCP_ECN_MASK_START = 98,
+	FE_HM_TCP_ECN_MASK_WIDTH = 3,
+	FE_HM_L4_VLD_MASK_START = 101,
+	FE_HM_L4_VLD_MASK_WIDTH = 1,
+	FE_HM_LSPID_MASK_START = 102,
+	FE_HM_LSPID_MASK_WIDTH = 1,
+	FE_HM_FWDTYPE_MASK_START = 103,
+	FE_HM_FWDTYPE_MASK_WIDTH = 4,
+	FE_HM_PPPOE_SESSION_ID_VLD_MASK_START = 107,
+	FE_HM_PPPOE_SESSION_ID_VLD_MASK_WIDTH = 1,
+	FE_HM_PPPOE_SESSION_ID_MASK_START = 108,
+	FE_HM_PPPOE_SESSION_ID_MASK_WIDTH = 1,
+	FE_HM_RSVD_109_START = 109,
+	FE_HM_RSVD_109_WIDTH = 1,
+	FE_HM_RECIRC_IDX_MASK_START = 110,
+	FE_HM_RECIRC_IDX_MASK_WIDTH = 1,
+	FE_HM_MCIDX_MASK_START = 111,
+	FE_HM_MCIDX_MASK_WIDTH = 1,
+	FE_HM_MC_DA_MASK_START = 112,
+	FE_HM_MC_DA_MASK_WIDTH = 1,
+	FE_HM_BC_DA_MASK_START = 113,
+	FE_HM_BC_DA_MASK_WIDTH = 1,
+	FE_HM_DA_AN_MAC_SEL_MASK_START = 114,
+	FE_HM_DA_AN_MAC_SEL_MASK_WIDTH = 1,
+	FE_HM_DA_AN_MAC_HIT_MASK_START = 115,
+	FE_HM_DA_AN_MAC_HIT_MASK_WIDTH = 1,
+	FE_HM_ORIG_LSPID_MASK_START = 116,
+	FE_HM_ORIG_LSPID_MASK_WIDTH = 1,
+	FE_HM_L7_FIELD_MASK_START = 117,
+	FE_HM_L7_FIELD_MASK_WIDTH = 1,
+	FE_HM_L7_FIELD_VLD_MASK_START = 118,
+	FE_HM_L7_FIELD_VLD_MASK_WIDTH = 1,
+	FE_HM_HDR_A_FLAGS_CRCERR_MASK_START = 119,
+	FE_HM_HDR_A_FLAGS_CRCERR_MASK_WIDTH = 1,
+	FE_HM_L3_CHKSUM_ERR_MASK_START = 120,
+	FE_HM_L3_CHKSUM_ERR_MASK_WIDTH = 1,
+	FE_HM_L4_CHKSUM_ERR_MASK_START = 121,
+	FE_HM_L4_CHKSUM_ERR_MASK_WIDTH = 1,
+	FE_HM_NOT_HDR_A_FLAGS_STSVLD_MASK_START = 122,
+	FE_HM_NOT_HDR_A_FLAGS_STSVLD_MASK_WIDTH = 1,
+	FE_HM_HASH_FID_MASK_START = 123,
+	FE_HM_HASH_FID_MASK_WIDTH = 1,
+	FE_HM_L7_FIELD_SEL_START = 124,
+	FE_HM_L7_FIELD_SEL_WIDTH = 2,
+	FE_HM_SA_BNG_MAC_SEL_MASK_START = 126,
+	FE_HM_SA_BNG_MAC_SEL_MASK_WIDTH = 1,
+	FE_HM_SA_BNG_MAC_HIT_MASK_START = 127,
+	FE_HM_SA_BNG_MAC_HIT_MASK_WIDTH = 1,
+	FE_HM_SPI_VLD_MASK_START = 128,
+	FE_HM_SPI_VLD_MASK_WIDTH = 1,
+	FE_HM_SPI_MASK_START = 129,
+	FE_HM_SPI_MASK_WIDTH = 1,
+	FE_HM_IPV6_NDP_MASK_START = 130,
+	FE_HM_IPV6_NDP_MASK_WIDTH = 1,
+	FE_HM_IPV6_HBH_MASK_START = 131,
+	FE_HM_IPV6_HBH_MASK_WIDTH = 1,
+	FE_HM_IPV6_RH_MASK_START = 132,
+	FE_HM_IPV6_RH_MASK_WIDTH = 1,
+	FE_HM_IPV6_DOH_MASK_START = 133,
+	FE_HM_IPV6_DOH_MASK_WIDTH = 1,
+	FE_HM_PPP_PROTOCOL_VLD_MASK_START = 134,
+	FE_HM_PPP_PROTOCOL_VLD_MASK_WIDTH = 1,
+	FE_HM_PPP_PROTOCOL_MASK_START = 135,
+	FE_HM_PPP_PROTOCOL_MASK_WIDTH = 1,
+	FE_HM_PKTLEN_RNG_MATCH_VECTOR_MASK_START = 136,
+	FE_HM_PKTLEN_RNG_MATCH_VECTOR_MASK_WIDTH = 4,
+	FE_HM_MCGID_MASK_START = 140,
+	FE_HM_MCGID_MASK_WIDTH = 9,
+	FE_HM_PARITY_START = 149,
+	FE_HM_PARITY_WIDTH = 1,
+	FE_CLASS_SVIDX_START = 0,
+	FE_CLASS_SVIDX_WIDTH = 6,
+	FE_CLASS_LSPID_START = 6,
+	FE_CLASS_LSPID_WIDTH = 4,
+	FE_CLASS_TPID_ENC_1_START = 18,
+	FE_CLASS_TPID_ENC_1_WIDTH = 3,
+	FE_CLASS_VID_1_START = 21,
+	FE_CLASS_VID_1_WIDTH = 12,
+	FE_CLASS_8021P_1_START = 33,
+	FE_CLASS_8021P_1_WIDTH = 3,
+	FE_CLASS_TPID_ENC_2_START = 36,
+	FE_CLASS_TPID_ENC_2_WIDTH = 3,
+	FE_CLASS_DA_START = 118,
+	FE_CLASS_SA_START = 166,
+	FE_CLASS_IP_DA_START = 214,
+	FE_CLASS_IP_SA_START = 342,
+	FE_CLASS_DA_MASK_START = 512,
+	FE_CLASS_DA_MASK_WIDTH = 6,
+	FE_CLASS_SA_MASK_START = 518,
+	FE_CLASS_SA_MASK_WIDTH = 6,
+	FE_CLASS_LSPID_MASK_START = 481,
+	FE_CLASS_LSPID_MASK_WIDTH = 1,
+	FE_CLASS_TPID_ENC_1_MSB_MASK_START = 487,
+	FE_CLASS_TPID_ENC_1_MSB_MASK_WIDTH = 1,
+	FE_CLASS_TPID_ENC_1_LSB_MASK_START = 488,
+	FE_CLASS_TPID_ENC_1_LSB_MASK_WIDTH = 1,
+	FE_CLASS_VID_1_MASK_START = 489,
+	FE_CLASS_VID_1_MASK_WIDTH = 2,
+	FE_CLASS_8021P_1_MASK_START = 491,
+	FE_CLASS_8021P_1_MASK_WIDTH = 1,
+	FE_CLASS_TPID_ENC_2_MSB_MASK_START = 492,
+	FE_CLASS_TPID_ENC_2_MSB_MASK_WIDTH = 1,
+	FE_CLASS_IP_DA_MASK_START = 524,
+	FE_CLASS_IP_DA_MASK_WIDTH = 9,
+	FE_CLASS_IP_SA_MASK_START = 533,
+	FE_CLASS_IP_SA_MASK_WIDTH = 9,
+	FE_CLASS_MCGID_START = 588,
+	FE_CLASS_MCGID_WIDTH = 9,
+	FE_CLASS_MCGID_MASK_START = 597,
+	FE_CLASS_MCGID_MASK_WIDTH = 9,
+	FE_CLASS_RSVD_621_606_START = 606,
+	FE_CLASS_RSVD_621_606_WIDTH = 16,
+	FE_CLASS_RULE_PRI_START = 622,
+	FE_CLASS_RULE_PRI_WIDTH = 6,
+	FE_CLASS_ENTRY_VLD_START = 628,
+	FE_CLASS_ENTRY_VLD_WIDTH = 1,
+	FE_CLASS_MEM_PARITY_START = 629,
+	FE_CLASS_MEM_PARITY_WIDTH = 1,
+	FE_CLASS_DATA19_RSRVD_START = 630,
+	FE_CLASS_DATA19_RSRVD_WIDTH = 10,
+	FE_CLASS_IP_PROT_START = 78,
+	FE_CLASS_IP_PROT_WIDTH = 8,
+	FE_CLASS_L4_SP_START = 86,
+	FE_CLASS_L4_SP_WIDTH = 16,
+	FE_CLASS_L4_DP_START = 102,
+	FE_CLASS_L4_DP_WIDTH = 16,
+	FE_CLASS_IP_VLD_START = 470,
+	FE_CLASS_IP_VLD_WIDTH = 1,
+	FE_CLASS_IP_VER_START = 471,
+	FE_CLASS_IP_VER_WIDTH = 1,
+	FE_CLASS_IP_FRAGMENT_START = 472,
+	FE_CLASS_IP_FRAGMENT_WIDTH = 1,
+	FE_CLASS_L4_VLD_START = 473,
+	FE_CLASS_L4_VLD_WIDTH = 1,
+	FE_CLASS_IP_PROT_MASK_START = 509,
+	FE_CLASS_IP_PROT_MASK_WIDTH = 1,
+	FE_CLASS_L4_PORT_MASK_START = 510,
+	FE_CLASS_L4_PORT_MASK_WIDTH = 2,
+	FE_CLASS_IP_VLD_MASK_START = 542,
+	FE_CLASS_IP_VLD_MASK_WIDTH = 1,
+	FE_CLASS_IP_VER_MASK_START = 543,
+	FE_CLASS_IP_VER_MASK_WIDTH = 1,
+	FE_CLASS_IP_FRAGMENT_MASK_START = 544,
+	FE_CLASS_IP_FRAGMENT_MASK_WIDTH = 1,
+	FE_CLASS_L4_VLD_MASK_START = 545,
+	FE_CLASS_L4_VLD_MASK_WIDTH = 1,
+	FE_SDB_HTUPL_EN_0_START = 0,
+	FE_SDB_HTUPL_EN_0_WIDTH = 1,
+	FE_SDB_HTUPL_MASK_PTR_0_START = 1,
+	FE_SDB_HTUPL_MASK_PTR_0_WIDTH = 6,
+	FE_SDB_HTUPL_PRI_0_START = 7,
+	FE_SDB_HTUPL_PRI_0_WIDTH = 4,
+	FE_SDB_TTL_HOPLIMIT_ZERO_DISCARD_EN_START = 154,
+	FE_SDB_TTL_HOPLIMIT_ZERO_DISCARD_EN_WIDTH = 1,
+	FE_SDB_UU_FLOWIDX_START = 161,
+	FE_SDB_UU_FLOWIDX_WIDTH = 13,
+	FE_SDB_BC_FLOWIDX_START = 176,
+	FE_SDB_BC_FLOWIDX_WIDTH = 13,
+	FE_SDB_UM_FLOWIDX_START = 189,
+	FE_SDB_UM_FLOWIDX_WIDTH = 13,
+	FWD_VOQ_POLICY_START = 0,
+	FWD_VOQ_POLICY_WIDTH = 1,
+	FWD_VOQ_POL_TBL_IDX_START = 3,
+	FWD_VOQ_POL_TBL_IDX_WIDTH = 9,
+	FWD_IP_SA_IDX_START = 13,
+	FWD_IP_SA_IDX_WIDTH = 12,
+	FWD_IP_DA_IDX_START = 26,
+	FWD_IP_DA_IDX_WIDTH = 12,
+	FWD_IP_SA_REPLACE_EN_START = 12,
+	FWD_IP_SA_REPLACE_EN_WIDTH = 1,
+	FWD_IP_DA_REPLACE_EN_START = 25,
+	FWD_IP_DA_REPLACE_EN_WIDTH = 1,
+	FWD_L4_SP_REPLACE_EN_START = 38,
+	FWD_L4_SP_REPLACE_EN_WIDTH = 1,
+	FWD_L4_SP_START = 39,
+	FWD_L4_SP_WIDTH = 16,
+	FWD_L4_DP_REPLACE_EN_START = 55,
+	FWD_L4_DP_REPLACE_EN_WIDTH = 1,
+	FWD_L4_DP_START = 56,
+	FWD_L4_DP_WIDTH = 16,
+	FWD_MAC_SA_REPLACE_EN_START = 72,
+	FWD_MAC_SA_REPLACE_EN_WIDTH = 1,
+	FWD_MAC_DA_REPLACE_EN_START = 73,
+	FWD_MAC_DA_REPLACE_EN_WIDTH = 1,
+	FWD_L2_IDX_START = 74,
+	FWD_L2_IDX_WIDTH = 9,
+	FWD_DECR_TTL_HOPLIMIT_START = 99,
+	FWD_DECR_TTL_HOPLIMIT_WIDTH = 1,
+	FWD_FLOW_VLAN_OP_EN_START = 100,
+	FWD_FLOW_VLAN_OP_EN_WIDTH = 1,
+	FWD_FLOW_VLANTBL_IDX_START = 101,
+	FWD_FLOW_VLANTBL_IDX_WIDTH = 9,
+};
+
+struct cs_fe_mask_field {
+	unsigned int start;
+	unsigned int width;
+};
+
+static const struct cs_fe_mask_field cs_fe_mask_fields[] = {
+	{ FE_HM_MAC_DA_MASK_START, FE_HM_MAC_DA_MASK_WIDTH },
+	{ FE_HM_MAC_SA_MASK_START, FE_HM_MAC_SA_MASK_WIDTH },
+	{ FE_HM_ETHERTYPE_MASK_START, FE_HM_ETHERTYPE_MASK_WIDTH },
+	{ FE_HM_LLC_TYPE_ENC_MSB_MASK_START,
+	  FE_HM_LLC_TYPE_ENC_MSB_MASK_WIDTH },
+	{ FE_HM_LLC_TYPE_ENC_LSB_MASK_START,
+	  FE_HM_LLC_TYPE_ENC_LSB_MASK_WIDTH },
+	{ FE_HM_TPID_ENC_1_MSB_MASK_START, FE_HM_TPID_ENC_1_MSB_MASK_WIDTH },
+	{ FE_HM_TPID_ENC_1_LSB_MASK_START, FE_HM_TPID_ENC_1_LSB_MASK_WIDTH },
+	{ FE_HM_8021P_1_MASK_START, FE_HM_8021P_1_MASK_WIDTH },
+	{ FE_HM_DEI_1_MASK_START, FE_HM_DEI_1_MASK_WIDTH },
+	{ FE_HM_VID_1_MASK_START, FE_HM_VID_1_MASK_WIDTH },
+	{ FE_HM_TPID_ENC_2_MSB_MASK_START, FE_HM_TPID_ENC_2_MSB_MASK_WIDTH },
+	{ FE_HM_TPID_ENC_2_LSB_MASK_START, FE_HM_TPID_ENC_2_LSB_MASK_WIDTH },
+	{ FE_HM_8021P_2_MASK_START, FE_HM_8021P_2_MASK_WIDTH },
+	{ FE_HM_DEI_2_MASK_START, FE_HM_DEI_2_MASK_WIDTH },
+	{ FE_HM_VID_2_MASK_START, FE_HM_VID_2_MASK_WIDTH },
+	{ FE_HM_IP_DA_MASK_START, FE_HM_IP_DA_MASK_WIDTH },
+	{ FE_HM_IP_SA_MASK_START, FE_HM_IP_SA_MASK_WIDTH },
+	{ FE_HM_IP_PROT_MASK_START, FE_HM_IP_PROT_MASK_WIDTH },
+	{ FE_HM_DSCP_MASK_START, FE_HM_DSCP_MASK_WIDTH },
+	{ FE_HM_ECN_MASK_START, FE_HM_ECN_MASK_WIDTH },
+	{ FE_HM_IP_FRAGMENT_MASK_START, FE_HM_IP_FRAGMENT_MASK_WIDTH },
+	{ FE_HM_KEYGEN_POLY_SEL_START, FE_HM_KEYGEN_POLY_SEL_WIDTH },
+	{ FE_HM_IPV6_FLOW_LBL_MASK_START, FE_HM_IPV6_FLOW_LBL_MASK_WIDTH },
+	{ FE_HM_IP_VER_MASK_START, FE_HM_IP_VER_MASK_WIDTH },
+	{ FE_HM_IP_VLD_MASK_START, FE_HM_IP_VLD_MASK_WIDTH },
+	{ FE_HM_L4_PORTS_RNGD_START, FE_HM_L4_PORTS_RNGD_WIDTH },
+	{ FE_HM_L4_DP_MASK_START, FE_HM_L4_DP_MASK_WIDTH },
+	{ FE_HM_L4_SP_MASK_START, FE_HM_L4_SP_MASK_WIDTH },
+	{ FE_HM_TCP_CTRL_MASK_START, FE_HM_TCP_CTRL_MASK_WIDTH },
+	{ FE_HM_TCP_ECN_MASK_START, FE_HM_TCP_ECN_MASK_WIDTH },
+	{ FE_HM_L4_VLD_MASK_START, FE_HM_L4_VLD_MASK_WIDTH },
+	{ FE_HM_LSPID_MASK_START, FE_HM_LSPID_MASK_WIDTH },
+	{ FE_HM_FWDTYPE_MASK_START, FE_HM_FWDTYPE_MASK_WIDTH },
+	{ FE_HM_PPPOE_SESSION_ID_VLD_MASK_START,
+	  FE_HM_PPPOE_SESSION_ID_VLD_MASK_WIDTH },
+	{ FE_HM_PPPOE_SESSION_ID_MASK_START,
+	  FE_HM_PPPOE_SESSION_ID_MASK_WIDTH },
+	{ FE_HM_RSVD_109_START, FE_HM_RSVD_109_WIDTH },
+	{ FE_HM_RECIRC_IDX_MASK_START, FE_HM_RECIRC_IDX_MASK_WIDTH },
+	{ FE_HM_MCIDX_MASK_START, FE_HM_MCIDX_MASK_WIDTH },
+	{ FE_HM_MC_DA_MASK_START, FE_HM_MC_DA_MASK_WIDTH },
+	{ FE_HM_BC_DA_MASK_START, FE_HM_BC_DA_MASK_WIDTH },
+	{ FE_HM_DA_AN_MAC_SEL_MASK_START, FE_HM_DA_AN_MAC_SEL_MASK_WIDTH },
+	{ FE_HM_DA_AN_MAC_HIT_MASK_START, FE_HM_DA_AN_MAC_HIT_MASK_WIDTH },
+	{ FE_HM_ORIG_LSPID_MASK_START, FE_HM_ORIG_LSPID_MASK_WIDTH },
+	{ FE_HM_L7_FIELD_MASK_START, FE_HM_L7_FIELD_MASK_WIDTH },
+	{ FE_HM_L7_FIELD_VLD_MASK_START, FE_HM_L7_FIELD_VLD_MASK_WIDTH },
+	{ FE_HM_HDR_A_FLAGS_CRCERR_MASK_START,
+	  FE_HM_HDR_A_FLAGS_CRCERR_MASK_WIDTH },
+	{ FE_HM_L3_CHKSUM_ERR_MASK_START, FE_HM_L3_CHKSUM_ERR_MASK_WIDTH },
+	{ FE_HM_L4_CHKSUM_ERR_MASK_START, FE_HM_L4_CHKSUM_ERR_MASK_WIDTH },
+	{ FE_HM_NOT_HDR_A_FLAGS_STSVLD_MASK_START,
+	  FE_HM_NOT_HDR_A_FLAGS_STSVLD_MASK_WIDTH },
+	{ FE_HM_HASH_FID_MASK_START, FE_HM_HASH_FID_MASK_WIDTH },
+	{ FE_HM_L7_FIELD_SEL_START, FE_HM_L7_FIELD_SEL_WIDTH },
+	{ FE_HM_SA_BNG_MAC_SEL_MASK_START, FE_HM_SA_BNG_MAC_SEL_MASK_WIDTH },
+	{ FE_HM_SA_BNG_MAC_HIT_MASK_START, FE_HM_SA_BNG_MAC_HIT_MASK_WIDTH },
+	{ FE_HM_SPI_VLD_MASK_START, FE_HM_SPI_VLD_MASK_WIDTH },
+	{ FE_HM_SPI_MASK_START, FE_HM_SPI_MASK_WIDTH },
+	{ FE_HM_IPV6_NDP_MASK_START, FE_HM_IPV6_NDP_MASK_WIDTH },
+	{ FE_HM_IPV6_HBH_MASK_START, FE_HM_IPV6_HBH_MASK_WIDTH },
+	{ FE_HM_IPV6_RH_MASK_START, FE_HM_IPV6_RH_MASK_WIDTH },
+	{ FE_HM_IPV6_DOH_MASK_START, FE_HM_IPV6_DOH_MASK_WIDTH },
+	{ FE_HM_PPP_PROTOCOL_VLD_MASK_START,
+	  FE_HM_PPP_PROTOCOL_VLD_MASK_WIDTH },
+	{ FE_HM_PPP_PROTOCOL_MASK_START, FE_HM_PPP_PROTOCOL_MASK_WIDTH },
+	{ FE_HM_PKTLEN_RNG_MATCH_VECTOR_MASK_START,
+	  FE_HM_PKTLEN_RNG_MATCH_VECTOR_MASK_WIDTH },
+	{ FE_HM_MCGID_MASK_START, FE_HM_MCGID_MASK_WIDTH },
+	{ FE_HM_PARITY_START, FE_HM_PARITY_WIDTH },
+};
+
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_format.h b/drivers/net/ethernet/cortina/cs_fe_format.h
new file mode 100644
index 000000000..ff65f08e3
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_format.h
@@ -0,0 +1,23 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_FORMAT_H
+#define CS_FE_FORMAT_H
+
+/* Epochs from different format owners are separate domains. */
+enum cs_fe_format_kind {
+	CS_FE_FORMAT_NONE,
+	CS_FE_FORMAT_TIMED,
+	CS_FE_FORMAT_PERSISTENT,
+};
+
+struct cs_fe_format_cookie {
+	enum cs_fe_format_kind kind;
+	u64 epoch;
+};
+
+static inline bool cs_fe_format_equal(const struct cs_fe_format_cookie *left,
+				      const struct cs_fe_format_cookie *right)
+{
+	return left->kind == right->kind && left->epoch == right->epoch;
+}
+
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot.c b/drivers/net/ethernet/cortina/cs_fe_hot.c
new file mode 100644
index 000000000..3c227707f
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot.c
@@ -0,0 +1,84 @@
+// SPDX-License-Identifier: GPL-2.0
+#ifdef __KERNEL__
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#include <errno.h>
+#include <string.h>
+#endif
+#include "cs_fe_hot.h"
+#define HOT_ACCESS 0x2048U
+#define HOT_DATA0 0x2050U
+#define HOT_DATA1 0x204cU
+#define HOT_START (1U << 31)
+static int hot_wait(const struct cs_fe_backend_io *io,
+		    unsigned long long deadline)
+{
+	unsigned long long local = io->now_us(io->context) + 1000U;
+	u32 v;
+	int error;
+
+	for (;;) {
+		if (io->now_us(io->context) >= deadline)
+			return -ETIMEDOUT;
+		error = io->read32(io->context, HOT_ACCESS, &v);
+		if (error)
+			return error;
+		if (io->now_us(io->context) >= deadline)
+			return -ETIMEDOUT;
+		if (!(v & HOT_START))
+			return 0;
+		if (io->now_us(io->context) >= local)
+			return -ETIMEDOUT;
+	}
+}
+
+int cs_fe_hot_read(const struct cs_fe_backend_io *io, unsigned int bucket,
+		   struct cs7542_fe_hot_sample *out)
+{
+	unsigned int i;
+	unsigned long long deadline = io ? io->limit_us : 0;
+	int error;
+
+	if (!out || bucket >= 4096)
+		return -EINVAL;
+	memset(out, 0, sizeof(*out));
+	out->attempted = true;
+	out->error = -EINPROGRESS;
+	if (!io || !io->context || !io->now_us || !io->read32 || !io->write32 ||
+	    io->extent < HOT_DATA0 + 4) {
+		out->error = -EINVAL;
+		return -EINVAL;
+	}
+	error = hot_wait(io, deadline);
+	if (!error && io->now_us(io->context) >= deadline)
+		error = -ETIMEDOUT;
+	/* READ opcode only: never RBW30, DATA or bitmap clear writes. */
+	if (!error)
+		error = io->write32(io->context, HOT_ACCESS,
+				    HOT_START | ((bucket * 6U) >> 6));
+	if (!error)
+		error = hot_wait(io, deadline);
+	for (i = 0; !error && i < 2; i++) {
+		if (io->now_us(io->context) >= deadline) {
+			error = -ETIMEDOUT;
+			break;
+		}
+		error = io->read32(io->context, i ? HOT_DATA1 : HOT_DATA0,
+				   &out->data[i]);
+		if (!error)
+			out->valid_words++;
+	}
+	if (!error && io->now_us(io->context) >= deadline)
+		error = -ETIMEDOUT;
+	out->word = (bucket * 6U) >> 6;
+	out->bit = (bucket * 6U) & 63U;
+	out->timestamp_us = io->now_us(io->context);
+	out->error = error;
+	if (!error) {
+		out->selected =
+			!!(out->data[out->bit / 32] & (1U << (out->bit % 32)));
+		out->complete = true;
+	}
+	return error;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot.h b/drivers/net/ethernet/cortina/cs_fe_hot.h
new file mode 100644
index 000000000..4f30e0257
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot.h
@@ -0,0 +1,15 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_HOT_H
+#define CS_FE_HOT_H
+#include "cs_fe_backend.h"
+struct cs7542_fe_hot_sample {
+	u64 timestamp_us;
+	u32 attempted, complete, valid_words, data[2], selected, word, bit;
+	int error;
+};
+
+/* Internal numeric bucket from an ACTUAL own lease; no public row selector. */
+
+int cs_fe_hot_read(const struct cs_fe_backend_io *io, unsigned int bucket,
+		   struct cs7542_fe_hot_sample *out);
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_access.c b/drivers/net/ethernet/cortina/cs_fe_hot_access.c
new file mode 100644
index 000000000..6c37bd7ad
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_access.c
@@ -0,0 +1,276 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "cs_fe_hot_access.h"
+#include "cs_fe_hot_compare.h"
+#ifdef __KERNEL__
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#include <errno.h>
+#include <string.h>
+#endif
+static const unsigned int hot_words[CS_BE_TABLES] = {
+	[CS_BE_CLASS] = 20,   [CS_BE_SDB] = 7,	[CS_BE_FWD] = 4,
+	[CS_BE_VOQ] = 2,      [CS_BE_MASK] = 5, [CS_BE_HASH] = 4,
+	[CS_BE_OVERFLOW] = 2, [CS_BE_L2] = 4,	[CS_BE_L3] = 5,
+	[CS_BE_FVLAN] = 2,
+};
+
+static bool geometry(unsigned int slot, const struct cs_fe_rows *r)
+{
+	unsigned int g = r->voq - 5U;
+
+	return r->class_row == 5 + slot && r->sdb_row == 5 + slot &&
+	       r->mask_row == 5 + slot && r->miss_fwd == 5 + 2 * slot &&
+	       g < CS_FE_BACKEND_ACTIONS && r->hit_fwd == 6 + 2 * g &&
+	       r->l2 == r->voq && r->l3 == r->voq && r->fvlan == r->voq &&
+	       r->priority == 51 && r->miss_marker == 0x5a123;
+}
+
+_Static_assert(CS_FE_HOT_SLOTS <= 32, "selector member bits fit in u32");
+
+_Static_assert(5 + 3 * CS_FE_HOT_SLOTS <= 64,
+	       "private ACL guards fit the low bank");
+
+int cs_fe_hot_graph(const struct cs_fe_hot_ledger *ledger,
+		    unsigned int selector, const struct cs_fe_hot_slot **anchor)
+{
+	const struct cs_fe_hot_slot *member, *root;
+	const struct cs_fe_hot_action *graph;
+	unsigned int base;
+
+	if (!ledger || !anchor || selector >= CS_FE_HOT_SLOTS)
+		return -EINVAL;
+	member = &ledger->slots[selector];
+	if (!member->claimed || !geometry(selector, &member->rows))
+		return -EUCLEAN;
+	graph = &ledger->actions[member->rows.voq - 5U];
+	base = graph->anchor_plus_one - 1U;
+	if (base >= CS_FE_HOT_SLOTS || !(graph->members & (1U << selector)) ||
+	    !(graph->members & (1U << base)) ||
+	    (graph->visible & ~graph->members))
+		return -EUCLEAN;
+	root = &ledger->slots[base];
+	if (!root->claimed || !geometry(base, &root->rows) ||
+	    root->rows.voq != member->rows.voq ||
+	    (base != selector &&
+	     !cs_fe_hot_egress_equal(&root->plan, &member->plan)))
+		return -EUCLEAN;
+	*anchor = root;
+	return 0;
+}
+
+#define RESULT_BITS                                                 \
+	(CS_FE_HOT_DEP_HIT | CS_FE_HOT_DEP_VOQ | CS_FE_HOT_DEP_L2 | \
+	 CS_FE_HOT_DEP_L3 | CS_FE_HOT_DEP_FVLAN)
+static u32 required(const struct cs_fe_plan *p)
+{
+	return CS_FE_HOT_DEP_MASK | CS_FE_HOT_DEP_SDB | CS_FE_HOT_DEP_MISS |
+	       CS_FE_HOT_DEP_HIT | CS_FE_HOT_DEP_VOQ | CS_FE_HOT_DEP_L2 |
+	       (p->write_l3 ? CS_FE_HOT_DEP_L3 : 0) |
+	       (p->write_fvlan ? CS_FE_HOT_DEP_FVLAN : 0);
+}
+
+static bool same(const u32 *a, const u32 *b, unsigned int words)
+{
+	return !memcmp(a, b, words * sizeof(u32));
+}
+
+static bool zero(const u32 *a, unsigned int words)
+{
+	unsigned int i;
+
+	for (i = 0; i < words; i++)
+		if (a[i])
+			return false;
+	return true;
+}
+
+int cs_fe_hot_access(const struct cs_fe_hot_ledger *ledger, unsigned int table,
+		     unsigned int row, bool write, const u32 *input,
+		     const u32 *expected, unsigned int words,
+		     struct cs_fe_hot_access_result *out)
+{
+	const struct cs_fe_hot_slot *slot = NULL, *anchor;
+	const struct cs_fe_plan *plan;
+	const u32 *canonical_input = NULL, *canonical_expected = NULL;
+	unsigned int i, other, count = 0, canonical_words = words;
+	u32 role = 0;
+	bool publish = false;
+
+	if (!out)
+		return -EINVAL;
+	out->slot = ~0U;
+	out->dependency_bit = 0;
+	if (!ledger || table >= CS_BE_TABLES || words != hot_words[table] ||
+	    (write && (!input || !expected)))
+		return -EINVAL;
+	if (write && ledger->blocked)
+		return -ESHUTDOWN;
+	if (write && ledger->pending)
+		return -EBUSY;
+	for (i = 0; i < CS_FE_HOT_SLOTS; i++) {
+		const struct cs_fe_hot_slot *s = &ledger->slots[i];
+
+		if (!s->claimed)
+			continue;
+		if (cs_fe_hot_graph(ledger, i, &anchor) ||
+		    s->plan.key.bucket >= 4096 ||
+		    s->plan.key.bucket != (s->plan.key.crc16 >> 4))
+			return -EUCLEAN;
+		for (other = 0; other < i; other++)
+			if (ledger->slots[other].claimed &&
+			    ledger->slots[other].plan.key.bucket ==
+				    s->plan.key.bucket)
+				/* Permanent bucket-to-action ownership is exclusive. */
+				return -EUCLEAN;
+	}
+	if (table == CS_BE_OVERFLOW)
+		return !write && row < 64 ? 0 : -EACCES;
+	if (table == CS_BE_VOQ && row == 2)
+		return write ? -EACCES : 0;
+	for (i = 0; i < CS_FE_HOT_SLOTS; i++) {
+		const struct cs_fe_hot_slot *s = &ledger->slots[i];
+		const struct cs_fe_rows *r = &s->rows;
+		bool hit = false;
+
+		if (!s->claimed)
+			continue;
+		switch (table) {
+		case CS_BE_CLASS:
+			hit = row == r->class_row;
+			break;
+		case CS_BE_SDB:
+			hit = row == r->sdb_row;
+			role = CS_FE_HOT_DEP_SDB;
+			break;
+		case CS_BE_MASK:
+			hit = row == r->mask_row;
+			role = CS_FE_HOT_DEP_MASK;
+			break;
+		case CS_BE_FWD:
+			hit = row == r->miss_fwd || row == r->hit_fwd;
+			role = row == r->miss_fwd ? CS_FE_HOT_DEP_MISS :
+						    CS_FE_HOT_DEP_HIT;
+			break;
+		case CS_BE_VOQ:
+			hit = row == r->voq;
+			role = CS_FE_HOT_DEP_VOQ;
+			break;
+		case CS_BE_L2:
+			hit = row == r->l2;
+			role = CS_FE_HOT_DEP_L2;
+			break;
+		case CS_BE_L3:
+			hit = row == r->l3;
+			role = CS_FE_HOT_DEP_L3;
+			break;
+		case CS_BE_FVLAN:
+			hit = row == r->fvlan;
+			role = CS_FE_HOT_DEP_FVLAN;
+			break;
+		case CS_BE_HASH:
+			hit = row == s->plan.key.bucket ||
+			      (!write && (row == s->plan.key.bucket + 4096U ||
+					  row == s->plan.key.bucket + 8192U));
+			break;
+		default:
+			break;
+		}
+		/*
+		 * Resolve output writes to their single immutable anchor. CLASS/HASH,
+		 * SDB, MASK and the odd CPU miss FWD always belong to the selector.
+		 */
+		if (hit && (role & RESULT_BITS) &&
+		    ledger->actions[r->voq - 5U].anchor_plus_one != i + 1U)
+			continue;
+		if (hit) {
+			slot = s;
+			out->slot = i;
+			out->dependency_bit = role;
+			count++;
+			break;
+		}
+	}
+	if (!count)
+		return -EACCES;
+	if (!write)
+		return 0;
+	plan = &slot->plan;
+#define HOT_IMAGE(name) \
+	do { \
+		canonical_words = plan->name.words; \
+		canonical_input = plan->name.input; \
+		canonical_expected = plan->name.expected; \
+	} while (0)
+	switch (table) {
+	case CS_BE_CLASS:
+		if (plan->class_invalid.words != words ||
+		    plan->class_valid.words != words)
+			return -EUCLEAN;
+		if (same(input, plan->class_invalid.input, words) &&
+		    same(expected, plan->class_invalid.expected, words))
+			return 0; /* Cut is allowed even when dependency setup is incomplete. */
+		canonical_input = plan->class_valid.input;
+		canonical_expected = plan->class_valid.expected;
+		publish = true;
+		break;
+	case CS_BE_HASH:
+		if (zero(input, words) && zero(expected, words))
+			return 0;
+		canonical_input = canonical_expected = plan->hash;
+		publish = true;
+		break;
+	case CS_BE_SDB:
+		HOT_IMAGE(sdb);
+		break;
+	case CS_BE_MASK:
+		HOT_IMAGE(mask);
+		break;
+	case CS_BE_FWD:
+		if (out->dependency_bit == CS_FE_HOT_DEP_MISS)
+			HOT_IMAGE(miss);
+		else
+			HOT_IMAGE(hit);
+		break;
+	case CS_BE_VOQ:
+		HOT_IMAGE(voq);
+		break;
+	case CS_BE_L2:
+		HOT_IMAGE(l2);
+		break;
+	case CS_BE_L3:
+		if (!plan->write_l3)
+			return -EOPNOTSUPP;
+		HOT_IMAGE(l3);
+		break;
+	case CS_BE_FVLAN:
+		if (!plan->write_fvlan)
+			return -EOPNOTSUPP;
+		HOT_IMAGE(fvlan);
+		break;
+	default:
+		return -EACCES;
+	}
+#undef HOT_IMAGE
+	if (canonical_words != words)
+		return -EUCLEAN;
+	if (!same(input, canonical_input, words) ||
+	    !same(expected, canonical_expected, words))
+		return -EINVAL;
+	if (publish) {
+		u32 present;
+
+		if (slot->fenced)
+			return -ESHUTDOWN;
+		if (cs_fe_hot_graph(ledger, out->slot, &anchor))
+			return -EUCLEAN;
+		present = (slot->dependency_written & ~RESULT_BITS) |
+			  (anchor->dependency_written & RESULT_BITS);
+		if ((present & required(plan)) != required(plan))
+			return -EAGAIN;
+	}
+	if (out->dependency_bit &&
+	    (slot->dependency_written & out->dependency_bit))
+		return -EALREADY;
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_access.h b/drivers/net/ethernet/cortina/cs_fe_hot_access.h
new file mode 100644
index 000000000..fa0abdca5
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_access.h
@@ -0,0 +1,55 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_HOT_ACCESS_H
+#define CS_FE_HOT_ACCESS_H
+#include "cs_fe_backend.h"
+#define CS_FE_HOT_SLOTS CS_FE_BACKEND_LEASES
+#define CS_FE_HOT_DEP_MASK (1U << 0)
+#define CS_FE_HOT_DEP_SDB (1U << 1)
+#define CS_FE_HOT_DEP_MISS (1U << 2)
+#define CS_FE_HOT_DEP_HIT (1U << 3)
+#define CS_FE_HOT_DEP_VOQ (1U << 4)
+#define CS_FE_HOT_DEP_L2 (1U << 5)
+#define CS_FE_HOT_DEP_L3 (1U << 6)
+#define CS_FE_HOT_DEP_FVLAN (1U << 7)
+struct cs_fe_hot_slot {
+	bool claimed, fenced;
+	struct cs_fe_rows rows;
+	struct cs_fe_plan plan;
+	u32 dependency_written;
+};
+
+struct cs_fe_hot_ledger {
+	struct cs_fe_hot_slot slots[CS_FE_HOT_SLOTS];
+	/*
+	 * The first successful claim pins an output image for this owner's epoch.
+	 * A selector keeps its member bit after withdrawal (in-flight packets).
+	 * Visible tracks only CLASS writes that completed hardware readback.
+	 */
+	struct cs_fe_hot_action {
+		unsigned int anchor_plus_one, members, visible;
+		bool native;
+	} actions[CS_FE_BACKEND_ACTIONS];
+	unsigned int pending_selector_plus_one;
+	bool blocked, pending;
+};
+
+int cs_fe_hot_graph(const struct cs_fe_hot_ledger *ledger,
+		    unsigned int selector,
+		    const struct cs_fe_hot_slot **anchor);
+struct cs_fe_hot_access_result {
+	unsigned int slot;
+	u32 dependency_bit;
+};
+
+/*
+ * Pure validation only. Owner resolves epoch/incarnation before this call.
+ *
+ * -EALREADY means identical retained dependency: skip hardware entirely.
+ * Owner journals pending+role BEFORE DATA and clears pending only after full
+ * readback. This helper never changes ledger or proves CLASS/trap phase.
+ */
+int cs_fe_hot_access(const struct cs_fe_hot_ledger *ledger, unsigned int table,
+		     unsigned int row, bool write, const u32 *input,
+		     const u32 *expected, unsigned int words,
+		     struct cs_fe_hot_access_result *out);
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_codec.c b/drivers/net/ethernet/cortina/cs_fe_hot_codec.c
new file mode 100644
index 000000000..73c579326
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_codec.c
@@ -0,0 +1,2 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "cs_fe_encode.c"
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_compare.h b/drivers/net/ethernet/cortina/cs_fe_hot_compare.h
new file mode 100644
index 000000000..74093e6ba
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_compare.h
@@ -0,0 +1,47 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_HOT_COMPARE_H
+#define CS_FE_HOT_COMPARE_H
+#include "cs_fe_encode.h"
+#ifdef __KERNEL__
+#include <linux/string.h>
+#else
+#include <string.h>
+#endif
+
+/*
+ * At the same physical result indices, compare every word the FE can read
+ * from the shared forwarding result, including the write/readback form.
+ */
+static inline bool cs_fe_hot_egress_equal(const struct cs_fe_plan *a,
+					  const struct cs_fe_plan *b)
+{
+	if (!a || !b || a->requirements != b->requirements ||
+	    a->write_l3 != b->write_l3 || a->write_fvlan != b->write_fvlan ||
+	    a->source_nat != b->source_nat ||
+	    a->destination_nat != b->destination_nat ||
+	    a->predicted_tx_qca != b->predicted_tx_qca)
+		return false;
+#define SAME_IMAGE(name) \
+	(a->name.words == b->name.words && \
+	 !memcmp(a->name.input, b->name.input, sizeof(a->name.input)) && \
+	 !memcmp(a->name.expected, b->name.expected, sizeof(a->name.expected)))
+	return SAME_IMAGE(hit) && SAME_IMAGE(l2) && SAME_IMAGE(l3) &&
+	       SAME_IMAGE(voq) && SAME_IMAGE(fvlan);
+#undef SAME_IMAGE
+}
+
+static inline bool cs_fe_hot_action_equal(const struct cs_fe_plan *a,
+					  const struct cs_fe_plan *b)
+{
+	if (!cs_fe_hot_egress_equal(a, b))
+		return false;
+#define SAME_PRIVATE(name)                                               \
+	(a->name.words == b->name.words &&                               \
+	 !memcmp(a->name.input, b->name.input, sizeof(a->name.input)) && \
+	 !memcmp(a->name.expected, b->name.expected,                     \
+		 sizeof(a->name.expected)))
+	return SAME_PRIVATE(sdb) && SAME_PRIVATE(mask) && SAME_PRIVATE(miss);
+#undef SAME_PRIVATE
+}
+
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_internal.h b/drivers/net/ethernet/cortina/cs_fe_hot_internal.h
new file mode 100644
index 000000000..3728c3f0b
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_internal.h
@@ -0,0 +1,44 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_HOT_INTERNAL_H
+#define CS_FE_HOT_INTERNAL_H
+#include <linux/cs7542_fe_backend.h>
+#include "cs_fe_hot_access.h"
+#include "cs_fe_hot_lineage.h"
+struct cs_fe_hot_binding {
+	u64 block, version;
+	unsigned long cookie;
+	bool visible, hash_present;
+};
+
+/* Builtin memory: never cleared by module attach/release. */
+
+struct cs_fe_hot_state {
+	struct cs_fe_hot_ledger ledger;
+	struct cs_fe_hot_lineage lineage;
+	struct cs_fe_hot_binding binding[CS_FE_HOT_SLOTS];
+	u64 block_highwater;
+	bool (*guards_ready)(void *context, unsigned int slot);
+	int (*guards_rebind)(void *context, unsigned int slot, const u32 *old_invalid,
+			     const u32 *new_invalid,
+			     unsigned long long end, bool commit);
+	int (*native_range)(void *context, bool prepare, u8 range_bit,
+			    unsigned long long end);
+	void *guard_context;
+};
+
+struct cs_fe_hot_session {
+	struct cs_fe_backend *backend;
+	struct cs_fe_backend_io native;
+	struct cs_fe_hot_request request;
+	enum cs_fe_hot_command command;
+};
+
+struct cs_fe_rows cs_fe_hot_rows(unsigned int slot);
+
+void cs_fe_hot_typed_io(struct cs_fe_hot_session *session,
+			struct cs_fe_backend_io *typed);
+int cs_fe_hot_verify_idle(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *native);
+int cs_fe_live_hot_idle(unsigned int *contexts, unsigned int *leases,
+			bool verify);
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_lineage.c b/drivers/net/ethernet/cortina/cs_fe_hot_lineage.c
new file mode 100644
index 000000000..63f677599
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_lineage.c
@@ -0,0 +1,138 @@
+// SPDX-License-Identifier: GPL-2.0
+#include "cs_fe_hot_lineage.h"
+#ifdef __KERNEL__
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#include <errno.h>
+#include <string.h>
+#endif
+
+int cs_fe_hot_affinity_claim(struct cs_fe_hot_lineage *lineage,
+			     unsigned int slot, unsigned int bucket)
+{
+	if (!lineage || slot >= CS_FE_HOT_SLOTS || bucket >= CS_FE_HOT_BUCKETS)
+		return -EINVAL;
+	if (lineage->bucket_owner[bucket] &&
+	    lineage->bucket_owner[bucket] != slot + 1)
+		return -EADDRINUSE;
+	lineage->bucket_owner[bucket] = slot + 1;
+	return 0;
+}
+
+static void selector_copy(struct cs_fe_hot_selector_image *out,
+			  const struct cs_fe_plan *plan)
+{
+	out->key = plan->key;
+	memcpy(out->hash, plan->hash, sizeof(out->hash));
+	memcpy(out->invalid_input, plan->class_invalid.input,
+	       sizeof(out->invalid_input));
+	memcpy(out->invalid_expected, plan->class_invalid.expected,
+	       sizeof(out->invalid_expected));
+	memcpy(out->valid_input, plan->class_valid.input,
+	       sizeof(out->valid_input));
+	memcpy(out->valid_expected, plan->class_valid.expected,
+	       sizeof(out->valid_expected));
+}
+
+int cs_fe_hot_lineage_begin(struct cs_fe_hot_lineage *lineage,
+			    unsigned int slot, const struct cs_fe_plan *old,
+			    const struct cs_fe_plan *candidate,
+			    unsigned long long *generation)
+{
+	struct cs_fe_hot_transition *transition;
+	int error;
+
+	if (!lineage || !old || !candidate || !generation ||
+	    slot >= CS_FE_HOT_SLOTS || old->key.bucket >= CS_FE_HOT_BUCKETS ||
+	    candidate->key.bucket >= CS_FE_HOT_BUCKETS ||
+	    old->key.bucket != old->key.crc16 >> 4 ||
+	    candidate->key.bucket != candidate->key.crc16 >> 4 ||
+	    old->class_invalid.words != 20 || old->class_valid.words != 20 ||
+	    candidate->class_invalid.words != 20 ||
+	    candidate->class_valid.words != 20)
+		return -EINVAL;
+	transition = &lineage->transition[slot];
+	if (transition->pending || transition->phase != CS_FE_HOT_IDLE)
+		return -EBUSY;
+	if (transition->generation == ~0ULL)
+		return -EOVERFLOW;
+	if (lineage->bucket_owner[old->key.bucket] != slot + 1)
+		return -EUCLEAN;
+	if (!cs_fe_hot_action_equal(old, candidate))
+		return -EOPNOTSUPP;
+	error = cs_fe_hot_affinity_claim(lineage, slot, candidate->key.bucket);
+	if (error)
+		return error;
+	selector_copy(&transition->old_selector, old);
+	selector_copy(&transition->new_selector, candidate);
+	transition->generation++;
+	transition->phase = CS_FE_HOT_NEW_INVALID;
+	*generation = transition->generation;
+	return 0;
+}
+
+static int transition_get(struct cs_fe_hot_lineage *lineage, unsigned int slot,
+			  unsigned long long generation,
+			  struct cs_fe_hot_transition **out)
+{
+	if (!lineage || slot >= CS_FE_HOT_SLOTS || !generation)
+		return -EINVAL;
+	*out = &lineage->transition[slot];
+	if ((*out)->generation != generation)
+		return -ESTALE;
+	return 0;
+}
+
+int cs_fe_hot_lineage_write_begin(struct cs_fe_hot_lineage *lineage,
+				  unsigned int slot,
+				  unsigned long long generation,
+				  enum cs_fe_hot_phase phase)
+{
+	struct cs_fe_hot_transition *transition;
+	int error = transition_get(lineage, slot, generation, &transition);
+
+	if (error)
+		return error;
+	if (phase < CS_FE_HOT_NEW_INVALID || phase > CS_FE_HOT_NEW_VALID ||
+	    transition->phase != phase || transition->pending)
+		return -EPERM;
+	transition->pending = true;
+	return 0;
+}
+
+int cs_fe_hot_lineage_write_complete(struct cs_fe_hot_lineage *lineage,
+				     unsigned int slot,
+				     unsigned long long generation,
+				     enum cs_fe_hot_phase phase, bool verified)
+{
+	struct cs_fe_hot_transition *transition;
+	int error = transition_get(lineage, slot, generation, &transition);
+
+	if (error)
+		return error;
+	if (phase < CS_FE_HOT_NEW_INVALID || phase > CS_FE_HOT_NEW_VALID ||
+	    transition->phase != phase || !transition->pending)
+		return -EPERM;
+	if (!verified) {
+		transition->phase = CS_FE_HOT_FAULT;
+		return -EIO;
+	}
+	transition->pending = false;
+	transition->phase++;
+	return 0;
+}
+
+int cs_fe_hot_lineage_cut(struct cs_fe_hot_lineage *lineage, unsigned int slot,
+			  unsigned long long generation)
+{
+	struct cs_fe_hot_transition *transition;
+	int error = transition_get(lineage, slot, generation, &transition);
+
+	if (error)
+		return error;
+	if (transition->pending || transition->phase != CS_FE_HOT_ACTIVE)
+		return -EPERM;
+	transition->phase = CS_FE_HOT_IDLE;
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_lineage.h b/drivers/net/ethernet/cortina/cs_fe_hot_lineage.h
new file mode 100644
index 000000000..cfcfb14df
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_lineage.h
@@ -0,0 +1,70 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_HOT_LINEAGE_H
+#define CS_FE_HOT_LINEAGE_H
+#include "cs_fe_hot_access.h"
+#include "cs_fe_hot_compare.h"
+
+#define CS_FE_HOT_BUCKETS 4096U
+
+enum cs_fe_hot_phase {
+	CS_FE_HOT_IDLE,
+	CS_FE_HOT_NEW_INVALID,
+	CS_FE_HOT_NEW_HASH,
+	CS_FE_HOT_NEW_VALID,
+	CS_FE_HOT_ACTIVE,
+	CS_FE_HOT_FAULT,
+};
+
+/* No dependent action image or module pointer is duplicated here. */
+struct cs_fe_hot_selector_image {
+	struct cs_fe_key key;
+	u32 hash[4];
+	u32 invalid_input[20], invalid_expected[20];
+	u32 valid_input[20], valid_expected[20];
+};
+
+struct cs_fe_hot_transition {
+	unsigned long long generation;
+	enum cs_fe_hot_phase phase;
+	bool pending;
+	struct cs_fe_hot_selector_image old_selector, new_selector;
+};
+
+struct cs_fe_hot_lineage {
+	/* Permanent action-slot affinity, including withdrawn/failed attempts. */
+	u8 bucket_owner[CS_FE_HOT_BUCKETS];
+	struct cs_fe_hot_transition transition[CS_FE_HOT_SLOTS];
+};
+
+int cs_fe_hot_affinity_claim(struct cs_fe_hot_lineage *lineage,
+			     unsigned int slot, unsigned int bucket);
+/*
+ * Owner lock held. Caller has independently canonicalized candidate and read
+ * actual old CLASS-invalid/HASH-zero, every retained dependency and every trap.
+ * These checks are mandatory executor preconditions, not facts this pure helper
+ * can establish. New bucket's actual all-way emptiness is checked by executor.
+ * Journal before scratch; then replace ONLY slot.plan's selector images.
+ */
+int cs_fe_hot_lineage_begin(struct cs_fe_hot_lineage *lineage,
+			    unsigned int slot, const struct cs_fe_plan *old,
+			    const struct cs_fe_plan *candidate,
+			    unsigned long long *generation);
+/*
+ * Call immediately BEFORE first scratch write. Complete only after literal
+ * full readback. false means uncertain failure: permanently fault, retain all.
+ */
+int cs_fe_hot_lineage_write_begin(struct cs_fe_hot_lineage *lineage,
+				  unsigned int slot,
+				  unsigned long long generation,
+				  enum cs_fe_hot_phase phase);
+int cs_fe_hot_lineage_write_complete(struct cs_fe_hot_lineage *lineage,
+				     unsigned int slot,
+				     unsigned long long generation,
+				     enum cs_fe_hot_phase phase, bool verified);
+/*
+ * After separately verified ordinary withdrawal, permit another begin. This
+ * does not release affinity/dependencies or establish a pipeline drain.
+ */
+int cs_fe_hot_lineage_cut(struct cs_fe_hot_lineage *lineage, unsigned int slot,
+			  unsigned long long generation);
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_hot_tables.c b/drivers/net/ethernet/cortina/cs_fe_hot_tables.c
new file mode 100644
index 000000000..ab60e09b5
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_hot_tables.c
@@ -0,0 +1,920 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Private direction backend. No callback registration/capability/statistics. */
+#ifdef __KERNEL__
+#include <linux/errno.h>
+#include <linux/string.h>
+#else
+#include <errno.h>
+#include <string.h>
+#endif
+#include "cs_fe_hot_internal.h"
+
+/* Exact proven indirect layout; DATA0 is the highest DATA address. */
+const struct cs_fe_backend_table cs_fe_backend_tables[CS_BE_TABLES] = {
+	[CS_BE_CLASS] = { 0x0054, 64, 20, 629 },
+	[CS_BE_SDB] = { 0x00a8, 64, 7, 206 },
+	[CS_BE_FWD] = { 0x00d4, 8192, 4, 113 },
+	[CS_BE_VOQ] = { 0x00f4, 512, 2, 40 },
+	[CS_BE_MASK] = { 0x2068, 64, 5, 149 },
+	[CS_BE_HASH] = { 0x201c, 12288, 4, -1 },
+	[CS_BE_OVERFLOW] = { 0x203c, 64, 2, -1 },
+	[CS_BE_L2] = { 0x0124, 512, 4, 96 },
+	[CS_BE_L3] = { 0x010c, 1024, 5, 128 },
+	[CS_BE_FVLAN] = { 0x0100, 512, 2, 38 },
+};
+
+#define CS_BE_START (1U << 31)
+#define CS_BE_WRITE (1U << 30)
+
+static int cs_be_time(const struct cs_fe_backend_io *io, unsigned long long end)
+{
+	if (io->limit_us && io->limit_us < end)
+		end = io->limit_us;
+	return io->now_us(io->context) >= end ? -ETIMEDOUT : 0;
+}
+
+static int cs_be_wait(const struct cs_fe_backend_io *io, unsigned int access,
+		      unsigned long long end)
+{
+	unsigned long long local = io->now_us(io->context) + 10000;
+	u32 value;
+	int error;
+
+	for (;;) {
+		error = cs_be_time(io, end);
+		if (error)
+			return error;
+		error = io->read32(io->context, access, &value);
+		if (error)
+			return error;
+		if (!(value & CS_BE_START))
+			return cs_be_time(io, end);
+		if (io->now_us(io->context) >= local)
+			return -ETIMEDOUT;
+	}
+}
+
+static int cs_be_read(struct cs_fe_backend *backend,
+		      const struct cs_fe_backend_io *io, unsigned int id,
+		      unsigned int row, unsigned long long end)
+{
+	const struct cs_fe_backend_table *table = &cs_fe_backend_tables[id];
+	struct cs_fe_backend_diag *last = &backend->last;
+	unsigned int word;
+	int error;
+
+	memset(last, 0, sizeof(*last));
+	last->table = id;
+	last->row = row;
+	last->words = table->words;
+	last->error = -EINPROGRESS;
+	error = cs_be_wait(io, table->access, end);
+	if (!error)
+		error = cs_be_time(io, end);
+	if (!error)
+		error = io->write32(io->context, table->access,
+				    CS_BE_START | row);
+	if (!error)
+		error = cs_be_wait(io, table->access, end);
+	for (word = 0; !error && word < table->words; word++) {
+		error = cs_be_time(io, end);
+		if (!error)
+			error = io->read32(io->context,
+					   table->access +
+						   (table->words - word) * 4,
+					   &last->raw[word]);
+		if (!error)
+			last->complete++;
+	}
+	if (!error)
+		error = cs_be_time(io, end);
+	last->error = error;
+	if (backend->observe)
+		backend->observe(backend->observe_context, last);
+	return error;
+}
+
+static int cs_be_compare(struct cs_fe_backend *backend,
+			 const struct cs_fe_backend_io *io, unsigned int id,
+			 unsigned int row, const u32 *expected,
+			 unsigned long long end)
+{
+	int error = cs_be_read(backend, io, id, row, end);
+
+	if (!error && memcmp(backend->last.raw, expected,
+			     cs_fe_backend_tables[id].words * sizeof(u32))) {
+		backend->last.error = -EUCLEAN;
+		error = -EUCLEAN;
+	}
+	return error;
+}
+
+static int cs_be_write(struct cs_fe_backend *backend,
+		       const struct cs_fe_backend_io *io, unsigned int id,
+		       unsigned int row, const u32 *input, const u32 *expected,
+		       unsigned long long end)
+{
+	const struct cs_fe_backend_table *table = &cs_fe_backend_tables[id];
+	unsigned int word;
+	int error = cs_be_wait(io, table->access, end);
+
+	if (error)
+		return error;
+	/* Uncertain scratch/ACCESS publication pins all resources, before low word. */
+	backend->pending = true;
+	for (word = 0; word < table->words; word++) {
+		u32 value = input[word];
+
+		if (table->parity >= 0 &&
+		    word == (unsigned int)table->parity / 32)
+			value &= ~(1U << (table->parity % 32));
+		error = cs_be_time(io, end);
+		if (!error)
+			error = io->write32(io->context,
+					    table->access +
+						    (table->words - word) * 4,
+					    value);
+		if (error)
+			return error;
+	}
+	error = cs_be_time(io, end);
+	if (!error)
+		error = io->write32(io->context, table->access,
+				    CS_BE_START | CS_BE_WRITE | row);
+	if (!error)
+		error = cs_be_wait(io, table->access, end);
+	if (!error)
+		error = cs_be_compare(backend, io, id, row, expected, end);
+	if (!error)
+		backend->pending = false;
+	return error;
+}
+
+static bool cs_be_rows_equal(const struct cs_fe_rows *a,
+			     const struct cs_fe_rows *b)
+{
+	return a->class_row == b->class_row && a->sdb_row == b->sdb_row &&
+	       a->mask_row == b->mask_row && a->miss_fwd == b->miss_fwd &&
+	       a->hit_fwd == b->hit_fwd && a->voq == b->voq && a->l2 == b->l2 &&
+	       a->l3 == b->l3 && a->fvlan == b->fvlan &&
+	       a->priority == b->priority && a->miss_marker == b->miss_marker;
+}
+
+static bool cs_be_plan_equal(const struct cs_fe_plan *a,
+			     const struct cs_fe_plan *b)
+{
+	if (memcmp(a->key.bytes, b->key.bytes, sizeof(a->key.bytes)) ||
+	    a->key.crc32 != b->key.crc32 || a->key.crc16 != b->key.crc16 ||
+	    a->key.bucket != b->key.bucket ||
+	    memcmp(a->hash, b->hash, sizeof(a->hash)) ||
+	    !cs_fe_hot_action_equal(a, b))
+		return false;
+#define CS_BE_SAME_IMAGE(name) \
+	(a->name.words == b->name.words && \
+	 !memcmp(a->name.input, b->name.input, sizeof(a->name.input)) && \
+	 !memcmp(a->name.expected, b->name.expected, sizeof(a->name.expected)))
+	return CS_BE_SAME_IMAGE(class_invalid) && CS_BE_SAME_IMAGE(class_valid);
+#undef CS_BE_SAME_IMAGE
+}
+
+struct cs_fe_rows cs_fe_hot_rows(unsigned int index)
+{
+	return (struct cs_fe_rows){
+		.class_row = 5 + index,
+		.sdb_row = 5 + index,
+		.mask_row = 5 + index,
+		.miss_fwd = 5 + index * 2,
+		.hit_fwd = 6 + index * 2,
+		.voq = 5 + index,
+		.l2 = 5 + index,
+		.l3 = 5 + index,
+		.fvlan = 5 + index,
+		/* Match exact UDP flows ahead of the default CPU class (50). */
+		.priority = 51,
+		.miss_marker = 0x5a123,
+	};
+}
+
+static unsigned long long hot_now(void *context)
+{
+	struct cs_fe_hot_session *session = context;
+
+	return session->native.now_us(session->native.context);
+}
+
+static int hot_status(void *context, u32 *status, u32 *init,
+		      unsigned long long end)
+{
+	struct cs_fe_hot_session *session = context;
+
+	const struct cs_fe_backend_io *io = &session->native;
+	int error = cs_be_time(io, end);
+
+	if (!error)
+		error = io->read32(io->context, 0x2000, status);
+	if (!error)
+		error = cs_be_time(io, end);
+	if (!error)
+		error = io->read32(io->context, 0x2004, init);
+	return error ? error : cs_be_time(io, end);
+}
+
+/*
+ * The native command arrives exclusively from the topology-checked owner.
+ * Its immutable encoder must include the range and error-status comparators.
+ * Unsupported commands and older module revisions cannot publish a rule.
+ */
+static bool hot_routed(const struct cs_fe_hot_session *session)
+{
+	if (!session->request.exact || !session->request.rule ||
+	    !session->request.policy || !session->request.selector.valid)
+		return false;
+	if (session->command == CS_HOT_NATIVE)
+		return (session->request.policy->require_mtu_range ==
+				CS_FE_MTU_RANGE_SMALL ||
+			session->request.policy->require_mtu_range ==
+				CS_FE_MTU_RANGE_1500) &&
+		       !session->request.policy->exact_dscp &&
+		       (cs_fe_l4proto(session->request.rule,
+				      session->request.policy) ==
+				CS_FE_L4_UDP ||
+			cs_fe_l4proto(session->request.rule,
+				      session->request.policy) == CS_FE_L4_TCP);
+	return session->command == CS_HOT_SCOPED &&
+	       !session->request.policy->require_mtu_range;
+}
+
+static int hot_native_range(struct cs_fe_hot_session *session, bool prepare,
+			    unsigned long long end)
+{
+	struct cs_fe_hot_state *state = session->backend->hot_state;
+
+	if (session->command != CS_HOT_NATIVE)
+		return 0;
+	if (!state->native_range || !end)
+		return -EOPNOTSUPP;
+	return state->native_range(state->guard_context, prepare,
+				   session->request.policy->require_mtu_range,
+				   end);
+}
+
+static struct cs_fe_rows hot_result_rows(unsigned int selector,
+					 unsigned int result)
+{
+	struct cs_fe_rows rows = cs_fe_hot_rows(selector);
+
+	rows.hit_fwd = 6 + 2 * result;
+	rows.voq = rows.l2 = rows.l3 = rows.fvlan = 5 + result;
+	return rows;
+}
+
+static int hot_placement(void *context, unsigned int index,
+			 struct cs_fe_rows *out, bool *shared)
+{
+	struct cs_fe_hot_session *session = context;
+
+	struct cs_fe_backend *backend = session->backend;
+	struct cs_fe_hot_state *state = backend->hot_state;
+	struct cs_fe_plan candidate;
+	unsigned int g, free_result = CS_FE_BACKEND_ACTIONS;
+	int error;
+
+	if (!state || !out || !shared || index >= CS_FE_HOT_SLOTS ||
+	    !hot_routed(session))
+		return -EOPNOTSUPP;
+	if (state->ledger.blocked || state->ledger.pending ||
+	    backend->pending || backend->poisoned)
+		return -EUCLEAN;
+	if (state->ledger.slots[index].claimed) {
+		const struct cs_fe_hot_slot *anchor;
+
+		error = cs_fe_hot_graph(&state->ledger, index, &anchor);
+		if (error)
+			return error;
+		*out = state->ledger.slots[index].rows;
+		*shared = anchor != &state->ledger.slots[index];
+		return 0;
+	}
+	*shared = false;
+	if (session->command != CS_HOT_NATIVE) {
+		if (index >= CS_FE_BACKEND_ACTIONS ||
+		    state->ledger.actions[index].anchor_plus_one)
+			return -ENOSPC;
+		*out = cs_fe_hot_rows(index);
+		return 0;
+	}
+	for (g = 0; g < CS_FE_BACKEND_ACTIONS; g++) {
+		const struct cs_fe_hot_action *graph =
+			&state->ledger.actions[g];
+		const struct cs_fe_hot_slot *anchor;
+		const struct cs_fe_backend_lease *lease;
+		unsigned int first;
+
+		if (!graph->anchor_plus_one) {
+			if (free_result == CS_FE_BACKEND_ACTIONS)
+				free_result = g;
+			continue;
+		}
+		first = graph->anchor_plus_one - 1;
+		error = cs_fe_hot_graph(&state->ledger, first, &anchor);
+		if (error)
+			return error;
+		lease = &backend->lease[first];
+		/*
+		 * Protocol comparisons and route-length selection are private to each
+		 * selector's CLASS, MASK and SDB; they do not alter identical output words.
+		 */
+		if (!graph->native || !lease->reserved || !lease->submitted ||
+		    !lease->guarded || !lease->scoped || !lease->scope_exact ||
+		    !lease->policy.require_mtu_range || lease->marker)
+			continue;
+		*out = hot_result_rows(index, g);
+		error = cs_fe_encode(session->request.rule, out,
+				     session->request.policy, &candidate);
+		if (error)
+			return error;
+		if (cs_fe_hot_egress_equal(&anchor->plan, &candidate)) {
+			*shared = true;
+			return 0;
+		}
+	}
+	if (free_result == CS_FE_BACKEND_ACTIONS)
+		return -ENOSPC;
+	*out = hot_result_rows(index, free_result);
+	return 0;
+}
+
+/*
+ * Full physical readback of the proposed parent's immutable results before
+ * attaching another exact classifier. The parent may be active or retired.
+ */
+static int hot_verify_output(struct cs_fe_hot_session *session,
+			     const struct cs_fe_rows *r,
+			     const struct cs_fe_plan *p, unsigned long long end)
+{
+	const u32 zero[CS_FE_BACKEND_WORDS] = {};
+	int error = 0;
+
+#define CHECK_OUTPUT(table, row, words)                                     \
+	do {                                                                \
+		if (!error)                                                 \
+			error = cs_be_compare(session->backend,             \
+					      &session->native, table, row, \
+					      words, end);                  \
+	} while (0)
+	CHECK_OUTPUT(CS_BE_FWD, r->hit_fwd, p->hit.expected);
+	CHECK_OUTPUT(CS_BE_VOQ, r->voq, p->voq.expected);
+	CHECK_OUTPUT(CS_BE_L2, r->l2, p->l2.expected);
+	CHECK_OUTPUT(CS_BE_L3, r->l3, p->write_l3 ? p->l3.expected : zero);
+	CHECK_OUTPUT(CS_BE_FVLAN, r->fvlan,
+		     p->write_fvlan ? p->fvlan.expected : zero);
+#undef CHECK_OUTPUT
+	return error;
+}
+
+static int hot_empty_selector(struct cs_fe_hot_session *session,
+			      const struct cs_fe_rows *r,
+			      const struct cs_fe_plan *p,
+			      unsigned long long end)
+{
+	const u32 zero[CS_FE_BACKEND_WORDS] = {};
+	unsigned int way;
+	int error = 0;
+
+#define EMPTY(table, row)                                                   \
+	do {                                                                \
+		if (!error)                                                 \
+			error = cs_be_compare(session->backend,             \
+					      &session->native, table, row, \
+					      zero, end);                   \
+	} while (0)
+	EMPTY(CS_BE_CLASS, r->class_row);
+	EMPTY(CS_BE_SDB, r->sdb_row);
+	EMPTY(CS_BE_MASK, r->mask_row);
+	EMPTY(CS_BE_FWD, r->miss_fwd);
+	for (way = 0; way < 3; way++)
+		EMPTY(CS_BE_HASH, p->key.bucket + way * 4096U);
+#undef EMPTY
+	return error == -EUCLEAN ? -EADDRINUSE : error;
+}
+
+static int hot_claim(void *context, unsigned int index,
+		     const struct cs_fe_rule *rule,
+		     const struct cs_fe_key_policy *policy,
+		     const struct cs_fe_rows *rows,
+		     const struct cs_fe_plan *plan)
+{
+	struct cs_fe_hot_session *session = context;
+
+	struct cs_fe_backend *backend = session->backend;
+	struct cs_fe_hot_state *state = backend->hot_state;
+	struct cs_fe_hot_slot *slot;
+	struct cs_fe_hot_action *graph;
+	struct cs_fe_rows issued;
+	struct cs_fe_plan canonical;
+	unsigned int other;
+	bool shared;
+	int error;
+
+	(void)rule;
+	(void)policy;
+	if (!state || index >= CS_FE_HOT_SLOTS || !hot_routed(session))
+		return -EOPNOTSUPP;
+	if (state->ledger.blocked || state->ledger.pending ||
+	    backend->pending || backend->poisoned)
+		return -EUCLEAN;
+	error = hot_placement(context, index, &issued, &shared);
+	if (error)
+		return error;
+	if (!cs_be_rows_equal(&issued, rows))
+		return -EUCLEAN;
+	error = cs_fe_encode(session->request.rule, &issued,
+			     session->request.policy, &canonical);
+	if (error)
+		return error;
+	cs_fe_exact_class_ipv4(&canonical, &session->request.rule->original,
+			       session->request.selector.source,
+			       session->request.selector.destination);
+	if (!cs_be_plan_equal(&canonical, plan))
+		return -EUCLEAN;
+	/* Collision refusal precedes any change to the permanent journal. */
+	for (other = 0; other < CS_FE_HOT_SLOTS; other++)
+		if (other != index && state->ledger.slots[other].claimed &&
+		    state->ledger.slots[other].plan.key.bucket ==
+			    canonical.key.bucket)
+			return -EOPNOTSUPP;
+	error = hot_native_range(session, true, session->native.limit_us);
+	if (error)
+		return error;
+	slot = &state->ledger.slots[index];
+	if (slot->claimed)
+		return cs_be_rows_equal(&slot->rows, &issued) &&
+				       cs_be_plan_equal(&slot->plan,
+							&canonical) ?
+			       0 :
+			       -ESTALE;
+	graph = &state->ledger.actions[issued.voq - 5U];
+	if (shared) {
+		unsigned long long end =
+			session->native.now_us(session->native.context) +
+			CS_FE_BACKEND_US;
+
+		if (session->native.limit_us && session->native.limit_us < end)
+			end = session->native.limit_us;
+		error = hot_empty_selector(session, &issued, &canonical, end);
+		if (!error)
+			error = hot_verify_output(session, &issued, &canonical,
+						  end);
+		if (error)
+			return error;
+	} else if (graph->anchor_plus_one || graph->members || graph->visible) {
+		return -EUCLEAN;
+	}
+	error = cs_fe_hot_affinity_claim(&state->lineage, index,
+					 canonical.key.bucket);
+	if (error)
+		return error;
+	slot->rows = issued;
+	slot->plan = canonical;
+	slot->dependency_written = 0;
+	slot->claimed = true; /* Before any physical scratch write. */
+	if (!shared) {
+		graph->anchor_plus_one = index + 1U;
+		graph->native = session->command == CS_HOT_NATIVE;
+	}
+	graph->members |= 1U << index;
+	if (shared) {
+		state->binding[index].block = session->request.block;
+		state->binding[index].cookie = session->request.cookie;
+		state->binding[index].version = session->request.version;
+	}
+	return 0;
+}
+
+/* Actual owner-mediated rebind. No raw offsets cross the module boundary. */
+static int hot_rebind(void *context, unsigned int index,
+		      const struct cs_fe_rule *rule,
+		      const struct cs_fe_key_policy *policy,
+		      const struct cs_fe_plan *proposal, unsigned long long end)
+{
+	struct cs_fe_hot_session *session = context;
+
+	struct cs_fe_backend *backend = session->backend;
+	struct cs_fe_hot_state *state = backend->hot_state;
+	struct cs_fe_hot_slot *slot;
+	struct cs_fe_hot_binding *binding;
+	struct cs_fe_plan canonical;
+	unsigned long long generation;
+	u32 zero[20] = {}, cpu_voq[2] = { 56, 1U << 8 };
+	unsigned int way;
+	int error;
+
+	/* Selection is mutable policy. Actual input and fixed row ownership are not. */
+	(void)rule;
+	(void)policy;
+	if (!state || index >= CS_FE_HOT_SLOTS || !proposal ||
+	    !hot_routed(session))
+		return -EOPNOTSUPP;
+	if (state->ledger.blocked || state->ledger.pending ||
+	    backend->pending || backend->poisoned)
+		return -EUCLEAN;
+	slot = &state->ledger.slots[index];
+	binding = &state->binding[index];
+	if (!slot->claimed || binding->visible || binding->hash_present ||
+	    backend->lease[index].active || !backend->lease[index].rearmable ||
+	    !backend->lease[index].scoped || !backend->lease[index].guarded ||
+	    backend->lease[index].marker)
+		return -EBUSY;
+	if (binding->block == session->request.block &&
+	    session->request.version <= binding->version)
+		return -ESTALE;
+	error = cs_fe_encode(session->request.rule, &slot->rows,
+			     session->request.policy, &canonical);
+	if (error)
+		return error;
+	cs_fe_exact_class_ipv4(&canonical, &session->request.rule->original,
+			       session->request.selector.source,
+			       session->request.selector.destination);
+	if (!cs_be_plan_equal(&canonical, proposal) ||
+	    !cs_fe_hot_action_equal(&slot->plan, &canonical))
+		return -EOPNOTSUPP;
+	if (state->lineage.bucket_owner[canonical.key.bucket] &&
+	    state->lineage.bucket_owner[canonical.key.bucket] != index + 1)
+		return -EADDRINUSE;
+	if (session->native.limit_us && session->native.limit_us < end)
+		end = session->native.limit_us;
+	error = hot_native_range(session, false, end);
+	if (error)
+		return error;
+	error = hot_status(context, &backend->status, &backend->init, end);
+	if (!error && (backend->status != 2 || backend->init))
+		error = -EUCLEAN;
+#define RETAIN(table, row, expected)                                      \
+	do {                                                              \
+		if (!error)                                               \
+			error = cs_be_compare(backend, &session->native,  \
+					      table, row, expected, end); \
+	} while (0)
+	RETAIN(CS_BE_CLASS, slot->rows.class_row,
+	       slot->plan.class_invalid.expected);
+	RETAIN(CS_BE_VOQ, 2, cpu_voq);
+	RETAIN(CS_BE_SDB, slot->rows.sdb_row, slot->plan.sdb.expected);
+	RETAIN(CS_BE_MASK, slot->rows.mask_row, slot->plan.mask.expected);
+	RETAIN(CS_BE_FWD, slot->rows.miss_fwd, slot->plan.miss.expected);
+	RETAIN(CS_BE_FWD, slot->rows.hit_fwd, slot->plan.hit.expected);
+	RETAIN(CS_BE_VOQ, slot->rows.voq, slot->plan.voq.expected);
+	RETAIN(CS_BE_L2, slot->rows.l2, slot->plan.l2.expected);
+	RETAIN(CS_BE_L3, slot->rows.l3,
+	       slot->plan.write_l3 ? slot->plan.l3.expected : zero);
+	RETAIN(CS_BE_FVLAN, slot->rows.fvlan,
+	       slot->plan.write_fvlan ? slot->plan.fvlan.expected : zero);
+	for (way = 0; way < 3; way++)
+		RETAIN(CS_BE_HASH, slot->plan.key.bucket + way * 4096, zero);
+	for (way = 0;
+	     !error && canonical.key.bucket != slot->plan.key.bucket && way < 3;
+	     way++) {
+		error = cs_be_read(backend, &session->native, CS_BE_HASH,
+				   canonical.key.bucket + way * 4096, end);
+		if (!error && memcmp(backend->last.raw, zero, 4 * sizeof(u32)))
+			return -EADDRINUSE;
+	}
+	for (way = 0; way < 64; way++)
+		RETAIN(CS_BE_OVERFLOW, way, zero);
+#undef RETAIN
+	if (!error)
+		error = state->guards_rebind(state->guard_context, index,
+					     slot->plan.class_invalid.expected,
+					     canonical.class_invalid.expected,
+					     end, false);
+	if (!error)
+		error = cs_be_time(&session->native, end);
+	if (error)
+		return error;
+	/* A prior verified rekey withdrawal must cut its current generation. */
+	if (state->lineage.transition[index].phase == CS_FE_HOT_ACTIVE) {
+		error = cs_fe_hot_lineage_cut(&state->lineage, index,
+			state->lineage.transition[index].generation);
+		if (error)
+			return error;
+	}
+	error = cs_fe_hot_lineage_begin(&state->lineage, index, &slot->plan,
+					&canonical, &generation);
+	if (error)
+		return error;
+	/* All child images were compared bit-for-bit; only selector images differ. */
+	slot->plan.key = canonical.key;
+	memcpy(slot->plan.hash, canonical.hash, sizeof(slot->plan.hash));
+	slot->plan.class_invalid = canonical.class_invalid;
+	slot->plan.class_valid = canonical.class_valid;
+	return 0;
+}
+
+static int hot_receipt(void *context, unsigned int index,
+		       struct cs_fe_plan *out)
+{
+	struct cs_fe_hot_session *session = context;
+
+	struct cs_fe_hot_state *state = session->backend->hot_state;
+
+	if (!state || !out || index >= CS_FE_HOT_SLOTS ||
+	    !state->ledger.slots[index].claimed)
+		return -ENOENT;
+	*out = state->ledger.slots[index].plan;
+	return 0;
+}
+
+static int hot_read(void *context, unsigned int table, unsigned int row,
+		    unsigned long long end)
+{
+	struct cs_fe_hot_session *session = context;
+
+	struct cs_fe_hot_access_result access;
+	struct cs_fe_hot_state *state = session->backend->hot_state;
+
+	int error;
+
+	if (!state || table >= CS_BE_TABLES)
+		return -EINVAL;
+	error = cs_fe_hot_access(&state->ledger, table, row, false, NULL, NULL,
+				 cs_fe_backend_tables[table].words, &access);
+	if (error)
+		return error;
+	return cs_be_read(session->backend, &session->native, table, row, end);
+}
+
+static bool same_binding(const struct cs_fe_hot_binding *binding,
+			 const struct cs_fe_hot_session *session)
+{
+	if (binding->block != session->request.block)
+		return false;
+	if (session->command == CS_HOT_UNBIND)
+		return true;
+	return binding->cookie == session->request.cookie &&
+	       session->request.version >= binding->version;
+}
+
+static int hot_write(void *context, unsigned int table, unsigned int row,
+		     const u32 *input, const u32 *expected,
+		     unsigned long long end)
+{
+	struct cs_fe_hot_session *session = context;
+
+	struct cs_fe_backend *backend = session->backend;
+	struct cs_fe_hot_state *state = backend->hot_state;
+	struct cs_fe_hot_access_result access;
+	struct cs_fe_hot_slot *slot;
+	struct cs_fe_hot_binding *binding;
+	bool hash_zero, class_valid, transition_write = false;
+	enum cs_fe_hot_phase phase = CS_FE_HOT_IDLE;
+	struct cs_fe_hot_transition *transition;
+	u32 zero[4] = {};
+	int error;
+
+	if (!state || table >= CS_BE_TABLES)
+		return -EINVAL;
+	error = cs_fe_hot_access(&state->ledger, table, row, true, input,
+				 expected, cs_fe_backend_tables[table].words,
+				 &access);
+	if (session->native.limit_us && session->native.limit_us < end)
+		end = session->native.limit_us;
+	if (error == -EALREADY)
+		return 0; /* Identical sealed dependency is never rewritten. */
+	if (error)
+		return error;
+	if (access.slot >= CS_FE_HOT_SLOTS)
+		return -EUCLEAN;
+	slot = &state->ledger.slots[access.slot];
+	binding = &state->binding[access.slot];
+	hash_zero = table == CS_BE_HASH && !memcmp(input, zero, sizeof(zero));
+	class_valid = table == CS_BE_CLASS &&
+		      !memcmp(input, slot->plan.class_valid.input,
+			      sizeof(slot->plan.class_valid.input));
+	if (table == CS_BE_HASH || table == CS_BE_CLASS) {
+		/* A stale cookie/block can never cut a newly installed association. */
+		if ((binding->visible || binding->hash_present) &&
+		    !same_binding(binding, session))
+			return -ESTALE;
+		if ((table == CS_BE_HASH && !hash_zero) || class_valid) {
+			struct cs_fe_plan canonical;
+
+			if (!hot_routed(session))
+				return -EOPNOTSUPP;
+			error = hot_native_range(session, false, end);
+			if (error)
+				return error;
+			error = cs_fe_encode(session->request.rule, &slot->rows,
+					     session->request.policy,
+					     &canonical);
+			if (error)
+				return error;
+			cs_fe_exact_class_ipv4(&canonical, &session->request.rule->original,
+				session->request.selector.source,
+				session->request.selector.destination);
+			if (!cs_be_plan_equal(&canonical, &slot->plan))
+				return -ESTALE;
+			if (table == CS_BE_HASH) {
+				error = cs_be_compare(backend, &session->native, CS_BE_CLASS,
+					slot->rows.class_row,
+					slot->plan.class_invalid.expected, end);
+				if (error)
+					return error;
+			}
+			if (!state->guards_ready ||
+			    !state->guards_ready(state->guard_context,
+						 access.slot))
+				return -EUCLEAN;
+			if (class_valid && (!binding->hash_present ||
+					    !same_binding(binding, session)))
+				return -EUCLEAN;
+		}
+	}
+	transition = &state->lineage.transition[access.slot];
+	if (transition->phase >= CS_FE_HOT_NEW_INVALID &&
+	    transition->phase <= CS_FE_HOT_NEW_VALID) {
+		if (table == CS_BE_CLASS && !class_valid)
+			phase = CS_FE_HOT_NEW_INVALID;
+		else if (table == CS_BE_HASH && !hash_zero)
+			phase = CS_FE_HOT_NEW_HASH;
+		else if (table == CS_BE_CLASS && class_valid)
+			phase = CS_FE_HOT_NEW_VALID;
+		else
+			return -EPERM;
+		error = cs_fe_hot_lineage_write_begin(&state->lineage,
+						      access.slot,
+						      transition->generation,
+						      phase);
+		if (error)
+			return error;
+		transition_write = true;
+	} else if (transition->phase == CS_FE_HOT_FAULT) {
+		return -EUCLEAN;
+	}
+	state->ledger.pending = true; /* BEFORE first scratch word. */
+	state->ledger.pending_selector_plus_one = access.slot + 1;
+	slot->dependency_written |= access.dependency_bit;
+	error = cs_be_write(backend, &session->native, table, row, input,
+			    expected, end);
+	if (!error && transition_write && phase == CS_FE_HOT_NEW_INVALID)
+		error = state->guards_rebind(state->guard_context, access.slot,
+			transition->old_selector.invalid_expected,
+			transition->new_selector.invalid_expected, end, true);
+	if (transition_write) {
+		int complete = cs_fe_hot_lineage_write_complete(&state->lineage, access.slot,
+					transition->generation,
+			phase, !error);
+		if (!error)
+			error = complete;
+	}
+	if (error)
+		return error; /* Both pending journals and module pin remain. */
+	state->ledger.pending = false;
+	state->ledger.pending_selector_plus_one = 0;
+	if (table == CS_BE_HASH) {
+		binding->hash_present = !hash_zero;
+		if (!hash_zero) {
+			binding->block = session->request.block;
+			binding->cookie = session->request.cookie;
+			binding->version = session->request.version;
+		}
+	}
+	if (table == CS_BE_CLASS) {
+		struct cs_fe_hot_action *graph =
+			&state->ledger.actions[slot->rows.voq - 5U];
+		unsigned int bit = 1U << access.slot;
+
+		binding->visible = class_valid;
+		if (class_valid)
+			graph->visible |= bit;
+		else
+			graph->visible &= ~bit;
+	}
+	return 0;
+}
+
+/*
+ * A failed joined selector retains its permanent reservation and ACL rows.
+ * Use its recorded class and HASH only. Moving a result or clearing another
+ * selector to recover would expose traffic after a firewall change.
+ */
+static int hot_isolate(void *context, unsigned int index)
+{
+	struct cs_fe_hot_session *session = context;
+
+	struct cs_fe_backend *backend = session->backend;
+	struct cs_fe_hot_state *state = backend->hot_state;
+	const struct cs_fe_hot_slot *anchor;
+	struct cs_fe_hot_slot *slot;
+	struct cs_fe_hot_action *graph;
+	struct cs_fe_hot_binding *binding;
+	unsigned long long end;
+	struct cs_fe_backend_io cleanup;
+	const u32 zero[4] = {};
+	int error;
+
+	if (!state || state->ledger.blocked || backend->poisoned ||
+	    cs_fe_hot_graph(&state->ledger, index, &anchor) ||
+	    (state->ledger.pending &&
+	     state->ledger.pending_selector_plus_one != index + 1U))
+		return -EUCLEAN;
+	slot = &state->ledger.slots[index];
+	binding = &state->binding[index];
+	graph = &state->ledger.actions[slot->rows.voq - 5U];
+	if (!(graph->members & ~(1U << index)) ||
+	    !same_binding(binding, session) ||
+	    state->lineage.bucket_owner[slot->plan.key.bucket] != index + 1U ||
+	    state->lineage.transition[index].pending)
+		return -EPERM;
+	/* Independent bounded withdrawal budget. No publication on this path. */
+	cleanup = session->native;
+	end = cleanup.now_us(cleanup.context) + CS_FE_BACKEND_US;
+	cleanup.limit_us = end;
+	state->ledger.pending = true;
+	state->ledger.pending_selector_plus_one = index + 1U;
+	error = cs_be_write(backend, &cleanup, CS_BE_CLASS,
+			    slot->rows.class_row,
+			    slot->plan.class_invalid.input,
+			    slot->plan.class_invalid.expected, end);
+	if (!error)
+		error = cs_be_write(backend, &cleanup, CS_BE_HASH,
+				    slot->plan.key.bucket, zero, zero, end);
+	if (error)
+		return error;
+	slot->fenced = true;
+	graph->visible &= ~(1U << index);
+	binding->visible = false;
+	binding->hash_present = false;
+	state->ledger.pending = false;
+	state->ledger.pending_selector_plus_one = 0;
+	return 0;
+}
+
+void cs_fe_hot_typed_io(struct cs_fe_hot_session *session,
+			struct cs_fe_backend_io *typed)
+{
+	*typed = (struct cs_fe_backend_io){
+		.abi = CS_FE_BACKEND_IO_ABI,
+		.size = sizeof(*typed),
+		.context = session,
+		.extent = session->native.extent,
+		.now_us = hot_now,
+		.limit_us = session->native.limit_us,
+		.selector = session->request.selector,
+		.table_read = hot_read,
+		.table_write = hot_write,
+		.claim = hot_claim,
+		.engine_status = hot_status,
+		.rebind = hot_rebind,
+		.receipt = hot_receipt,
+		.placement = hot_placement,
+		.isolate = hot_isolate,
+	};
+	/* raw read32/write32 remain NULL: no offset interface crosses into .ko. */
+}
+
+int cs_fe_hot_verify_idle(struct cs_fe_backend *backend,
+			  const struct cs_fe_backend_io *native)
+{
+	struct cs_fe_hot_state *state = backend->hot_state;
+	unsigned long long end =
+		native->now_us(native->context) + CS_FE_BACKEND_US;
+	u32 zero[4] = {};
+	unsigned int index;
+	int error;
+
+	if (!state || backend->poisoned || backend->pending ||
+	    state->ledger.pending)
+		return -EUCLEAN;
+	for (index = 0; index < CS_FE_BACKEND_BLOCKS; index++)
+		if (backend->block[index].identity)
+			return -EBUSY;
+	for (index = 0; index < CS_FE_BACKEND_ENTRIES; index++)
+		if (backend->entry[index].active)
+			return -EBUSY;
+	for (index = 0; index < CS_FE_HOT_SLOTS; index++) {
+		struct cs_fe_hot_slot *slot = &state->ledger.slots[index];
+
+		struct cs_fe_hot_transition *transition =
+			&state->lineage.transition[index];
+
+		if (transition->pending ||
+		    (transition->phase != CS_FE_HOT_IDLE &&
+		     transition->phase != CS_FE_HOT_ACTIVE))
+			return -EUCLEAN;
+		if (backend->lease[index].active ||
+		    state->binding[index].visible ||
+		    state->binding[index].hash_present)
+			return -EBUSY;
+		if (!slot->claimed)
+			continue;
+		error = cs_be_compare(backend, native, CS_BE_HASH,
+				      slot->plan.key.bucket, zero, end);
+		if (!error)
+			error = cs_be_compare(backend, native, CS_BE_CLASS,
+					      slot->rows.class_row,
+					      slot->plan.class_invalid.expected,
+					      end);
+		if (error)
+			return error;
+	}
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_native.inc b/drivers/net/ethernet/cortina/cs_fe_native.inc
new file mode 100644
index 000000000..77d37280b
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_native.inc
@@ -0,0 +1,668 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/* Included by the FE owner. No network-device references are kept in slots. */
+#include <linux/icmp.h>
+#include <linux/if_bridge.h>
+#include <linux/jhash.h>
+#include <linux/moduleparam.h>
+#include <linux/netfilter_ipv4.h>
+#include <net/fib_notifier.h>
+#include <net/flow_offload.h>
+#include <net/ip.h>
+#include <net/netevent.h>
+#include <net/switchdev.h>
+
+static atomic_t cs_native_live = ATOMIC_INIT(0);
+static atomic_t cs_native_programming = ATOMIC_INIT(0);
+static atomic64_t cs_native_generation = ATOMIC64_INIT(0);
+static atomic64_t cs_native_scanned = ATOMIC64_INIT(0);
+static unsigned long cs_native_events;
+static bool cs_native_watching;
+
+enum cs_native_event { CS_NATIVE_RECHECK_FDB, CS_NATIVE_REVOKE };
+
+/* RANGE0 and RANGE1 have fixed framing limits, serialized across owners. */
+static DEFINE_MUTEX(cs_native_mtu_lock);
+static const unsigned int cs_native_mtu1500_high = CS_FE_NATIVE_1500_MAX_HIGH;
+
+static int cs_fe_native_range(void *context, bool prepare, u8 range_bit,
+			      unsigned long long end)
+{
+	struct cs7542_fe_live *owner = context;
+	struct cs_fe_backend_io io = cs_fe_live_io(owner);
+	unsigned int row, high;
+	struct cs_fe_native_mtu *range;
+	int err;
+
+	lockdep_assert_held(&owner->lock);
+	if (range_bit != CS_FE_MTU_RANGE_SMALL &&
+	    range_bit != CS_FE_MTU_RANGE_1500)
+		return -EINVAL;
+	row = range_bit == CS_FE_MTU_RANGE_1500;
+	range = &owner->native.range[row];
+	io.limit_us = end;
+	mutex_lock(&cs_native_mtu_lock);
+	high = row ? cs_native_mtu1500_high : CS_FE_NATIVE_SMALL_HIGH;
+	if (!high)
+		err = -EOPNOTSUPP;
+	else if (prepare)
+		err = cs_fe_native_mtu_prepare(range, &io, row, high);
+	else
+		err = cs_fe_native_mtu_verify(range, &io, row, high);
+	mutex_unlock(&cs_native_mtu_lock);
+	return err;
+}
+
+static void cs_native_forget(struct cs_fe_native_flow *flow)
+{
+	if (flow->block) {
+		memset(flow, 0, sizeof(*flow));
+		atomic_dec(&cs_native_live);
+	}
+}
+
+static struct cs_fe_backend_entry *
+cs_native_hw_entry(struct cs7542_fe_live *owner, u64 block,
+		   unsigned long cookie)
+{
+	unsigned int n;
+
+	for (n = 0; n < CS_FE_BACKEND_ENTRIES; n++) {
+		struct cs_fe_backend_entry *entry = &owner->backend.entry[n];
+
+		if (entry->occupied && entry->active && entry->block == block &&
+		    entry->cookie == cookie)
+			return entry;
+	}
+	return NULL;
+}
+
+static bool cs_native_visible(const struct cs7542_fe_live *owner, u64 block,
+			      unsigned long cookie)
+{
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(owner->hot_state.binding); i++) {
+		const struct cs_fe_hot_binding *b =
+			&owner->hot_state.binding[i];
+
+		if (b->block == block && b->cookie == cookie &&
+		    (b->visible || b->hash_present))
+			return true;
+	}
+	return false;
+}
+
+static void cs_fe_native_prune(struct cs7542_fe_live *owner)
+{
+	struct cs_fe_native_flow *flow;
+	unsigned int i;
+
+	lockdep_assert_held(&owner->lock);
+	for (i = 0; i < ARRAY_SIZE(owner->native.flows); i++) {
+		flow = &owner->native.flows[i];
+		if (!flow->block)
+			continue;
+		if (owner->reset_verified ||
+		    (!owner->backend.poisoned && !owner->backend.pending &&
+		     !cs_native_hw_entry(owner, flow->block, flow->cookie) &&
+		     !cs_native_visible(owner, flow->block, flow->cookie)))
+			cs_native_forget(flow);
+	}
+}
+
+static struct cs_fe_native_flow *cs_native_slot(struct cs7542_fe_live *owner,
+						u64 block, unsigned long cookie)
+{
+	struct cs_fe_native_flow *free = NULL;
+	unsigned int i;
+
+	for (i = 0; i < ARRAY_SIZE(owner->native.flows); i++) {
+		struct cs_fe_native_flow *flow = &owner->native.flows[i];
+
+		if (flow->block == block && flow->cookie == cookie)
+			return flow;
+		if (!flow->block && !free)
+			free = flow;
+	}
+	return free;
+}
+
+static struct dsa_port *cs_native_port(int ifindex,
+				       const struct cs_fe_link *link,
+				       const u8 *peer, unsigned int route_mtu)
+{
+	struct net_device *dev = __dev_get_by_index(&init_net, ifindex);
+	struct dsa_port *dp = dsa_port_from_netdev(dev);
+	struct net_device *l3dev;
+
+	ASSERT_RTNL();
+	if (IS_ERR(dp) || !dp->ds || !dp->ds->dev || !dp->cpu_dp ||
+	    !of_device_is_compatible(dp->ds->dev->of_node, "qca,qca8337") ||
+	    !dp->cpu_dp->conduit || dp->cpu_dp->index || dp->lag ||
+	    dp->hsr_dev || dp->index < 1 || dp->index > 5 ||
+	    dp->index != link->switch_port || link->tag_mode != 4 ||
+	    link->cpu_port || link->gmac != 1 || link->base_voq != 8 ||
+	    !netif_running(dev) || !netif_carrier_ok(dev) ||
+	    dsa_port_is_vlan_filtering(dp))
+		return ERR_PTR(-EOPNOTSUPP);
+	l3dev = netdev_master_upper_dev_get(dev);
+	if (l3dev) {
+		if (!netif_is_bridge_master(l3dev) || !netif_running(l3dev) ||
+		    br_vlan_enabled(l3dev) ||
+		    br_port_get_stp_state(dev) != BR_STATE_FORWARDING ||
+		    br_port_flag_is_set(dev, BR_ISOLATED | BR_PORT_LOCKED |
+						     BR_PORT_MAB |
+						     BR_VLAN_TUNNEL) ||
+		    br_fdb_find_port(l3dev, peer, 0) != dev)
+			return ERR_PTR(-EOPNOTSUPP);
+	} else {
+		l3dev = dev;
+	}
+	if (!ether_addr_equal(link->base_mac, l3dev->dev_addr) ||
+	    route_mtu > min(READ_ONCE(dev->mtu), READ_ONCE(l3dev->mtu)))
+		return ERR_PTR(-ESTALE);
+	return dp;
+}
+
+static struct net_device *
+cs_native_path(const struct cs7542_fe_native_request *r)
+{
+	const struct cs_fe_rule *rule = &r->rule;
+	struct dsa_port *in, *out;
+
+	if (!is_valid_ether_addr(r->ingress_smac) ||
+	    !is_valid_ether_addr(rule->dmac) ||
+	    !ether_addr_equal(rule->egress.base_mac, rule->smac) ||
+	    r->route_mtu < CS_FE_NATIVE_SMALL_HIGH || !rule->decrement_ttl ||
+	    rule->egress.rx_qca_meta)
+		return ERR_PTR(-EOPNOTSUPP);
+	in = cs_native_port(r->ingress_ifindex, &rule->ingress, r->ingress_smac,
+			    0);
+	out = cs_native_port(r->egress_ifindex, &rule->egress, rule->dmac,
+			     r->route_mtu);
+	if (IS_ERR(in) || IS_ERR(out) || in->ds != out->ds ||
+	    in->cpu_dp != out->cpu_dp || !netif_running(in->cpu_dp->conduit) ||
+	    !netif_carrier_ok(in->cpu_dp->conduit))
+		return ERR_PTR(-EOPNOTSUPP);
+	return in->cpu_dp->conduit;
+}
+
+static int cs_native_format(struct net_device *conduit, u64 epoch)
+{
+	struct qca8k_persistent_status f = {
+		.version = QCA8K_PERSISTENT_STATUS_VERSION,
+		.size = sizeof(f),
+	};
+	int err;
+
+	err = qca8k_persistent_status(conduit, &f);
+	if (err)
+		return err;
+	if (!epoch || f.epoch != epoch || f.size != sizeof(f) ||
+	    f.version != QCA8K_PERSISTENT_STATUS_VERSION || f.reserved ||
+	    f.closing || f.uncertain || f.first_error || f.held_fault ||
+	    f.requested != 1 || f.ready != 1 || f.known != 1 ||
+	    f.coherent != 1 || f.restore_debt != 1 ||
+	    f.selected != DSA_TAG_PROTO_QCA4 ||
+	    f.tree_protocol != DSA_TAG_PROTO_QCA4)
+		return -ESTALE;
+	return 0;
+}
+
+static int cs_native_cut(struct cs7542_fe_live *owner,
+			 struct cs_fe_native_flow *flow)
+{
+	struct cs_fe_backend_io io = cs_fe_live_io(owner);
+	struct cs_fe_backend_entry *entry;
+	int err;
+
+	if (owner->reset_verified)
+		goto cut;
+	err = cs_fe_live_ready(owner);
+	if (err)
+		return err;
+	entry = cs_native_hw_entry(owner, flow->block, flow->cookie);
+	if (entry) {
+		err = cs_fe_backend_destroy(&owner->backend, &io, flow->block,
+					    flow->cookie, entry->version);
+		if (err)
+			return err;
+	}
+	if (owner->backend.pending ||
+	    cs_native_visible(owner, flow->block, flow->cookie))
+		return -EIO;
+cut:
+	cs_native_forget(flow);
+	return 0;
+}
+
+/*
+ * Admission is tied to netfilter's conntrack snapshot and its exact rule.
+ * Never interpret its opaque cookie as a kernel pointer.
+ */
+static bool cs_native_tcp_match(const struct flow_cls_offload *cls,
+				unsigned long cookie,
+				const struct cs7542_fe_native_request *r)
+{
+	const struct cs_fe_tuple *tuple = &r->rule.original;
+	const u64 allowed = BIT_ULL(FLOW_DISSECTOR_KEY_BASIC) |
+			    BIT_ULL(FLOW_DISSECTOR_KEY_TCP) |
+			    BIT_ULL(FLOW_DISSECTOR_KEY_IPV4_ADDRS) |
+			    BIT_ULL(FLOW_DISSECTOR_KEY_PORTS) |
+			    BIT_ULL(FLOW_DISSECTOR_KEY_CONTROL) |
+			    BIT_ULL(FLOW_DISSECTOR_KEY_META);
+	struct flow_match_ipv4_addrs ip;
+	struct flow_match_control control;
+	struct flow_match_basic basic;
+	struct flow_match_ports ports;
+	struct flow_match_meta meta;
+	struct flow_match_tcp tcp;
+
+	if (!cls || cls->command != FLOW_CLS_REPLACE ||
+	    !cls->nf_tcp_established || !cls->rule ||
+	    !cls->rule->match.dissector || cls->cookie != cookie ||
+	    cls->nf_route_mtu != r->route_mtu ||
+	    cls->rule->match.dissector->used_keys != allowed)
+		return false;
+	flow_rule_match_basic(cls->rule, &basic);
+	flow_rule_match_control(cls->rule, &control);
+	flow_rule_match_ipv4_addrs(cls->rule, &ip);
+	flow_rule_match_ports(cls->rule, &ports);
+	flow_rule_match_meta(cls->rule, &meta);
+	flow_rule_match_tcp(cls->rule, &tcp);
+	return basic.key->n_proto == htons(ETH_P_IP) &&
+	       basic.mask->n_proto == htons(0xffff) &&
+	       basic.key->ip_proto == IPPROTO_TCP &&
+	       basic.mask->ip_proto == 0xff &&
+	       control.key->addr_type == FLOW_DISSECTOR_KEY_IPV4_ADDRS &&
+	       control.mask->addr_type == 0xffff &&
+	       ip.mask->src == htonl(U32_MAX) &&
+	       ip.mask->dst == htonl(U32_MAX) &&
+	       ip.key->src == htonl(tuple->src) &&
+	       ip.key->dst == htonl(tuple->dst) &&
+	       ports.mask->src == htons(0xffff) &&
+	       ports.mask->dst == htons(0xffff) &&
+	       ports.key->src == htons(tuple->sport) &&
+	       ports.key->dst == htons(tuple->dport) &&
+	       meta.mask->ingress_ifindex == -1 &&
+	       meta.key->ingress_ifindex == r->ingress_ifindex &&
+	       !tcp.key->flags &&
+	       tcp.mask->flags == htons(0x05); /* Linux FIN | RST */
+}
+
+static int cs_native_replace(struct cs7542_fe_live *owner, u64 block,
+			     unsigned long cookie, u64 version,
+			     const struct cs7542_fe_native_request *input,
+			     u8 proto, const struct flow_cls_offload *cls)
+{
+	struct cs7542_fe_native_request path;
+	const struct cs7542_fe_native_request *r = &path;
+	struct cs_fe_key_policy policy = {};
+	struct cs_fe_native_flow *slot = NULL;
+	struct cs_fe_backend_entry *entry;
+	struct net_device *conduit;
+	struct cs_fe_backend_io io;
+	u64 gen;
+	int err;
+
+	ASSERT_RTNL();
+	if (!owner || !input || !block || !version ||
+	    input->size != sizeof(*r) ||
+	    (input->abi != CS7542_FE_NATIVE_ABI &&
+	     !(proto == IPPROTO_UDP && input->abi == 1)))
+		return -EINVAL;
+	path = *input;
+	/* An ABI1 UDP caller could have arbitrary tail padding in cs_fe_rule. */
+	path.rule.native_l4proto = proto;
+	atomic_inc(&cs_native_programming);
+	gen = atomic64_read(&cs_native_generation);
+	conduit = cs_native_path(r);
+	err = IS_ERR(conduit) ? PTR_ERR(conduit) :
+				cs_native_format(conduit, r->format_epoch);
+	if (!err && ((proto == IPPROTO_TCP &&
+		      (input->rule.native_l4proto != IPPROTO_TCP ||
+		       !cs_native_tcp_match(cls, cookie, r))) ||
+		     (proto == IPPROTO_UDP && input->abi != 1 &&
+		      input->rule.native_l4proto &&
+		      input->rule.native_l4proto != IPPROTO_UDP)))
+		err = -EOPNOTSUPP;
+	mutex_lock(&owner->lock);
+	if (cs_fe_live_ready(owner)) {
+		err = -ESHUTDOWN;
+		goto out;
+	}
+	cs_fe_native_prune(owner);
+	io = cs_fe_live_io(owner);
+	if (!err &&
+	    (owner->ports[1] != conduit || !READ_ONCE(cs_native_watching) ||
+	     gen != atomic64_read(&cs_native_scanned)))
+		err = -EAGAIN;
+	if (!err) {
+		slot = cs_native_slot(owner, block, cookie);
+		if (!slot)
+			err = -ENOSPC;
+		else if (slot->block && slot->version >= version) {
+			err = -ESTALE;
+			goto out;
+		}
+	}
+	if (err) {
+		err = cs_fe_backend_reject(&owner->backend, &io, block, cookie,
+					   version, err);
+		goto out;
+	}
+	policy.require_mtu_range = cs_fe_native_mtu_select(r->route_mtu, READ_ONCE(cs_native_mtu1500_high));
+	io.limit_us = io.now_us(io.context) + CS_FE_BACKEND_US;
+	io.selector.valid = true;
+	ether_addr_copy(io.selector.source, r->ingress_smac);
+	ether_addr_copy(io.selector.destination, r->rule.ingress.base_mac);
+	/*
+	 * Record the obligation before publication, including an uncertain
+	 * hardware write. A verified inactive tuple is pruned below.
+	 */
+	if (!slot->block)
+		atomic_inc(&cs_native_live);
+	slot->block = block;
+	slot->cookie = cookie;
+	slot->version = version;
+	slot->path = *r;
+	err = cs_fe_backend_replace_native(&owner->backend, &io, block, cookie,
+					   version, &r->rule, &policy);
+	cs_fe_live_pin(owner);
+	entry = cs_native_hw_entry(owner, block, cookie);
+	if (err) {
+		/*
+		 * An older algorithm can decline the new opcode before seeing
+		 * this desired version. A prior association still needs cutting.
+		 */
+		if (entry && entry->version < version)
+			err = cs_fe_backend_reject(&owner->backend, &io, block,
+						   cookie, version, err);
+		goto out;
+	}
+	if (!entry || entry->lease >= ARRAY_SIZE(owner->hot_state.binding) ||
+	    entry->version != version ||
+	    owner->hot_state.binding[entry->lease].block != block ||
+	    owner->hot_state.binding[entry->lease].cookie != cookie ||
+	    !owner->hot_state.binding[entry->lease].visible ||
+	    !owner->hot_state.binding[entry->lease].hash_present)
+		err = cs_native_cut(owner, slot) ?: -EUCLEAN;
+	else if (atomic64_read(&cs_native_generation) != gen)
+		err = cs_native_cut(owner, slot) ?: -ESTALE;
+out:
+	cs_fe_native_prune(owner);
+	mutex_unlock(&owner->lock);
+	atomic_dec(&cs_native_programming);
+	return err;
+}
+
+int cs7542_fe_live_replace_native(struct cs7542_fe_live *owner, u64 block,
+				  unsigned long cookie, u64 version,
+				  const struct cs7542_fe_native_request *r)
+{
+	return cs_native_replace(owner, block, cookie, version, r, IPPROTO_UDP,
+				 NULL);
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_replace_native);
+
+int cs7542_fe_live_replace_native_tcp(struct cs7542_fe_live *owner, u64 block,
+				      unsigned long cookie, u64 version,
+				      const struct cs7542_fe_native_request *r,
+				      const struct flow_cls_offload *cls)
+{
+	return cs_native_replace(owner, block, cookie, version, r, IPPROTO_TCP,
+				 cls);
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_replace_native_tcp);
+
+static int cs_native_scan(bool revoke_all)
+{
+	struct cs7542_fe_live *owner;
+	unsigned int i;
+	int first = 0;
+
+	ASSERT_RTNL();
+	mutex_lock(&cs_fe_live_owners_lock);
+	list_for_each_entry(owner, &cs_fe_live_owners, node) {
+		mutex_lock(&owner->lock);
+		cs_fe_native_prune(owner);
+		for (i = 0; i < ARRAY_SIZE(owner->native.flows); i++) {
+			struct cs_fe_native_flow *flow =
+				&owner->native.flows[i];
+			int err;
+
+			if (!flow->block ||
+			    (!revoke_all &&
+			     !IS_ERR(cs_native_path(&flow->path))))
+				continue;
+			err = cs_native_cut(owner, flow);
+			if (err && !first)
+				first = err;
+		}
+		mutex_unlock(&owner->lock);
+	}
+	mutex_unlock(&cs_fe_live_owners_lock);
+	return first;
+}
+
+static int cs_native_drain(void)
+{
+	unsigned long events;
+	u64 gen;
+	int err;
+
+	ASSERT_RTNL();
+	do {
+		gen = atomic64_read(&cs_native_generation);
+		events = xchg(&cs_native_events, 0UL);
+		err = cs_native_scan(events & BIT(CS_NATIVE_REVOKE));
+		if (err) {
+			set_bit(CS_NATIVE_REVOKE, &cs_native_events);
+			return err;
+		}
+		atomic64_set(&cs_native_scanned, gen);
+	} while (READ_ONCE(cs_native_events));
+	return 0;
+}
+
+static void cs_native_worker(struct work_struct *work)
+{
+	rtnl_lock();
+	cs_native_drain();
+	rtnl_unlock();
+}
+
+static DECLARE_WORK(cs_native_work, cs_native_worker);
+
+static int cs_native_changed(enum cs_native_event kind, bool sync)
+{
+	if (!atomic_read(&cs_native_live) &&
+	    !atomic_read(&cs_native_programming))
+		return NOTIFY_DONE;
+	set_bit(kind, &cs_native_events);
+	atomic64_inc(&cs_native_generation);
+	if (sync)
+		return notifier_from_errno(cs_native_drain());
+	schedule_work(&cs_native_work);
+	return NOTIFY_DONE;
+}
+
+static int cs_native_device(struct notifier_block *nb, unsigned long event,
+			    void *info)
+{
+	struct net_device *dev = netdev_notifier_info_to_dev(info);
+
+	if (!net_eq(dev_net(dev), &init_net))
+		return NOTIFY_DONE;
+	switch (event) {
+	case NETDEV_PRECHANGEUPPER:
+	case NETDEV_PRE_CHANGEADDR:
+	case NETDEV_PRECHANGEMTU:
+	case NETDEV_GOING_DOWN:
+	case NETDEV_UNREGISTER:
+		return cs_native_changed(CS_NATIVE_REVOKE, true);
+	case NETDEV_CHANGE:
+	case NETDEV_CHANGELOWERSTATE:
+	case NETDEV_CHANGEUPPER:
+	case NETDEV_CHANGEMTU:
+	case NETDEV_CHANGEADDR:
+		return cs_native_changed(CS_NATIVE_REVOKE, false);
+	default:
+		return NOTIFY_DONE;
+	}
+}
+
+static int cs_native_fdb(struct notifier_block *nb, unsigned long event,
+			 void *info)
+{
+	struct net_device *dev = switchdev_notifier_info_to_dev(info);
+
+	if (!dev || !net_eq(dev_net(dev), &init_net))
+		return NOTIFY_DONE;
+	switch (event) {
+	case SWITCHDEV_FDB_DEL_TO_DEVICE:
+	case SWITCHDEV_FDB_ADD_TO_DEVICE:
+	case SWITCHDEV_FDB_DEL_TO_BRIDGE:
+	case SWITCHDEV_FDB_ADD_TO_BRIDGE:
+	case SWITCHDEV_FDB_FLUSH_TO_BRIDGE:
+		return cs_native_changed(CS_NATIVE_RECHECK_FDB, false);
+	default:
+		return NOTIFY_DONE;
+	}
+}
+
+/*
+ * Ordinary NUD refreshes keep the same usable next-hop MAC. Notice a change
+ * in address or reachability without expiring flows for every ARP confirmation.
+ * Collisions only make an extra conservative recheck necessary.
+ */
+struct cs_native_arp_state {
+	__be32 address;
+	int ifindex;
+	u8 mac[ETH_ALEN];
+	bool valid;
+};
+
+static struct cs_native_arp_state cs_native_arp[128];
+static DEFINE_SPINLOCK(cs_native_arp_lock);
+
+static bool cs_native_arp_changed(const struct neighbour *neigh)
+{
+	struct cs_native_arp_state next = { .ifindex = neigh->dev->ifindex };
+	struct cs_native_arp_state *last;
+	unsigned int index;
+	bool changed;
+
+	memcpy(&next.address, neigh->primary_key, sizeof(next.address));
+	next.valid = !!(READ_ONCE(neigh->nud_state) & NUD_VALID);
+	neigh_ha_snapshot(next.mac, neigh, neigh->dev);
+	index = jhash_2words((__force u32)next.address, next.ifindex, 0);
+	last = &cs_native_arp[index % ARRAY_SIZE(cs_native_arp)];
+	spin_lock_bh(&cs_native_arp_lock);
+	changed = last->address != next.address ||
+		  last->ifindex != next.ifindex || last->valid != next.valid ||
+		  !ether_addr_equal(last->mac, next.mac);
+	*last = next;
+	spin_unlock_bh(&cs_native_arp_lock);
+	return changed;
+}
+
+static int cs_native_neigh(struct notifier_block *nb, unsigned long event,
+			   void *info)
+{
+	if (event == NETEVENT_NEIGH_UPDATE) {
+		const struct neighbour *neigh = info;
+
+		if (neigh->tbl != arp_table(dev_net(neigh->dev)) ||
+		    neigh->dev->addr_len != ETH_ALEN ||
+		    !net_eq(dev_net(neigh->dev), &init_net) ||
+		    !cs_native_arp_changed(neigh))
+			return NOTIFY_DONE;
+	} else if (event != NETEVENT_REDIRECT &&
+		   event != NETEVENT_IPV4_MPATH_HASH_UPDATE)
+		return NOTIFY_DONE;
+	return cs_native_changed(CS_NATIVE_REVOKE, false);
+}
+
+static int cs_native_fib(struct notifier_block *nb, unsigned long event,
+			 void *info)
+{
+	const struct fib_notifier_info *fib = info;
+
+	if (fib->family != AF_INET)
+		return NOTIFY_DONE;
+	return cs_native_changed(CS_NATIVE_REVOKE, false);
+}
+
+static unsigned int cs_native_icmp(void *priv, struct sk_buff *skb,
+				   const struct nf_hook_state *state)
+{
+	struct icmphdr copy;
+	const struct icmphdr *icmp;
+	const struct iphdr *ip;
+
+	if (!atomic_read(&cs_native_live) &&
+	    !atomic_read(&cs_native_programming))
+		return NF_ACCEPT;
+	ip = ip_hdr(skb);
+	if (ip->protocol == IPPROTO_ICMP && !ip_is_fragment(ip)) {
+		icmp = skb_header_pointer(skb,
+					  skb_network_offset(skb) + ip->ihl * 4,
+					  sizeof(copy), &copy);
+		if (icmp && icmp->type == ICMP_DEST_UNREACH &&
+		    icmp->code == ICMP_FRAG_NEEDED)
+			cs_native_changed(CS_NATIVE_REVOKE, false);
+	}
+	return NF_ACCEPT;
+}
+
+static struct notifier_block cs_native_dev_nb = { .notifier_call =
+							  cs_native_device };
+static struct notifier_block cs_native_fdb_nb = { .notifier_call =
+							  cs_native_fdb };
+static struct notifier_block cs_native_neigh_nb = { .notifier_call =
+							    cs_native_neigh };
+static struct notifier_block cs_native_fib_nb = { .notifier_call =
+							  cs_native_fib };
+static const struct nf_hook_ops cs_native_pmtu_hook = {
+	.hook = cs_native_icmp,
+	.pf = NFPROTO_IPV4,
+	.hooknum = NF_INET_PRE_ROUTING,
+	.priority = NF_IP_PRI_FIRST,
+};
+
+static int __init cs_native_notifiers(void)
+{
+	int err;
+
+	err = register_netdevice_notifier(&cs_native_dev_nb);
+	if (err)
+		return err;
+	err = register_switchdev_notifier(&cs_native_fdb_nb);
+	if (err)
+		goto dev;
+	err = register_netevent_notifier(&cs_native_neigh_nb);
+	if (err)
+		goto fdb;
+	err = register_fib_notifier(&init_net, &cs_native_fib_nb, NULL, NULL);
+	if (err)
+		goto neigh;
+	err = nf_register_net_hook(&init_net, &cs_native_pmtu_hook);
+	if (err)
+		goto fib;
+	WRITE_ONCE(cs_native_watching, true);
+	return 0;
+fib:
+	unregister_fib_notifier(&init_net, &cs_native_fib_nb);
+neigh:
+	unregister_netevent_notifier(&cs_native_neigh_nb);
+fdb:
+	unregister_switchdev_notifier(&cs_native_fdb_nb);
+dev:
+	unregister_netdevice_notifier(&cs_native_dev_nb);
+	return err;
+}
+
+late_initcall(cs_native_notifiers);
+
+#include "cs_fe_native_activity.inc"
diff --git a/drivers/net/ethernet/cortina/cs_fe_native_activity.inc b/drivers/net/ethernet/cortina/cs_fe_native_activity.inc
new file mode 100644
index 000000000..0e8b6c36c
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_native_activity.inc
@@ -0,0 +1,237 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/* An access selects an owned way0 bucket for a read. No bitmap is cleared. */
+#include <linux/moduleparam.h>
+#include <linux/sysfs.h>
+
+/*
+ * The bitmap uses the same selector number that native_activity calls lease.
+ * Retained membership is lifetime ownership. Visible requires CLASS readback.
+ */
+static int cs_native_actions_get(char *buf, const struct kernel_param *kp)
+{
+	struct cs7542_fe_live *owner;
+	unsigned int i, s;
+	int len = 0;
+
+	mutex_lock(&cs_fe_live_owners_lock);
+	list_for_each_entry(owner, &cs_fe_live_owners, node) {
+		mutex_lock(&owner->lock);
+		for (i = 0; i < CS_FE_BACKEND_ACTIONS && len < PAGE_SIZE - 192;
+		     i++) {
+			const struct cs_fe_hot_action *graph =
+				&owner->hot_state.ledger.actions[i];
+			const struct cs_fe_hot_slot *root;
+			u32 fenced = 0;
+
+			if (!graph->anchor_plus_one)
+				continue;
+			if (cs_fe_hot_graph(&owner->hot_state.ledger,
+					    graph->anchor_plus_one - 1,
+					    &root)) {
+				len += sysfs_emit_at(buf, len,
+					"epoch=%llu result=%u inconsistent=1\n",
+					owner->epoch, i);
+				continue;
+			}
+			for (s = 0; s < CS_FE_HOT_SLOTS; s++)
+				if ((graph->members & BIT(s)) &&
+				    owner->hot_state.ledger.slots[s].fenced)
+					fenced |= BIT(s);
+			len += sysfs_emit_at(buf, len,
+				"epoch=%llu result=%u hit_fwd=%u voq=%u l2=%u l3=%u fvlan=%u members=0x%x visible=0x%x fenced=0x%x uncertain=%u\n",
+				owner->epoch, i, root->rows.hit_fwd,
+				root->rows.voq, root->rows.l2, root->rows.l3,
+				root->rows.fvlan, graph->members,
+				graph->visible, fenced,
+				owner->backend.pending ||
+					owner->backend.poisoned ||
+					owner->hot_state.ledger.pending);
+		}
+		mutex_unlock(&owner->lock);
+	}
+	mutex_unlock(&cs_fe_live_owners_lock);
+	return len;
+}
+
+static const struct kernel_param_ops cs_native_actions_ops = {
+	.get = cs_native_actions_get
+};
+
+module_param_cb(native_actions, &cs_native_actions_ops, NULL, 0400);
+
+static bool cs_native_sample_for(const struct cs7542_fe_hot_sample *s,
+				 unsigned int bucket)
+{
+	return s->complete && !s->error && s->valid_words == 2 &&
+	       s->word == (bucket * 6U) / 64 && s->bit == (bucket * 6U) % 64;
+}
+
+/*
+ * A set sticky bit can only establish activity after the most recent zero.
+ * Neither a repeated set bit nor a bit inherited at installation is fresh.
+ */
+static u64 cs_native_hot_stamp(struct cs_fe_native_clock *clock,
+			       const struct cs7542_fe_hot_sample *before,
+			       const struct cs7542_fe_hot_sample *sample)
+{
+	if (clock->baseline_us != before->timestamp_us) {
+		clock->baseline_us = before->timestamp_us;
+		clock->lastuse_us = 0;
+		clock->last_zero_us = before->selected ? 0 :
+							 before->timestamp_us;
+	}
+	if (sample->timestamp_us < before->timestamp_us)
+		return 0;
+	if (!sample->selected) {
+		clock->last_zero_us = sample->timestamp_us;
+	} else if (clock->last_zero_us) {
+		clock->lastuse_us = clock->last_zero_us;
+		clock->last_zero_us = 0;
+	}
+	return clock->lastuse_us;
+}
+
+static bool cs_native_lease_active(const struct cs7542_fe_live *owner,
+				   unsigned int index)
+{
+	const struct cs_fe_hot_binding *binding =
+		&owner->hot_state.binding[index];
+
+	return owner->backend.lease[index].active && binding->visible &&
+	       binding->hash_present;
+}
+
+int cs7542_fe_live_native_lastused(struct cs7542_fe_live *owner, u64 block,
+				   unsigned long cookie,
+				   unsigned long *lastused)
+{
+	const struct cs7542_fe_hot_sample *before;
+	struct cs_fe_backend_entry *entry;
+	struct cs7542_fe_hot_sample sample;
+	struct cs_fe_backend_io io;
+	unsigned int lease, bucket;
+	u64 last, elapsed;
+	int err;
+
+	if (!owner || !lastused)
+		return -EINVAL;
+	mutex_lock(&owner->lock);
+	err = cs_fe_live_ready(owner);
+	if (err)
+		goto out;
+	entry = cs_native_hw_entry(owner, block, cookie);
+	if (!entry || owner->backend.pending ||
+	    entry->lease >= CS_FE_BACKEND_LEASES ||
+	    !cs_native_lease_active(owner, entry->lease) ||
+	    !owner->backend.lease[entry->lease].policy.require_mtu_range) {
+		err = -ENOENT;
+		goto out;
+	}
+	lease = entry->lease;
+	bucket = owner->backend.lease[lease].plan.key.bucket;
+	io = cs_fe_live_io(owner);
+	io.limit_us = io.now_us(io.context) + 3000;
+	err = cs_fe_hot_read(&io, bucket, &sample);
+	if (err)
+		goto out;
+	before = &owner->hot_before[lease];
+	if (!cs_native_sample_for(before, bucket) ||
+	    !cs_native_sample_for(&sample, bucket)) {
+		err = -ENODATA;
+		goto out;
+	}
+	last = cs_native_hot_stamp(&owner->native.clocks[lease], before,
+				   &sample);
+	if (!last) {
+		err = -ENODATA;
+		goto out;
+	}
+	elapsed = io.now_us(io.context) - last;
+	*lastused = jiffies - nsecs_to_jiffies64(elapsed * NSEC_PER_USEC);
+out:
+	mutex_unlock(&owner->lock);
+	return err;
+}
+EXPORT_SYMBOL_GPL(cs7542_fe_live_native_lastused);
+
+static int cs_native_activity_get(char *buf, const struct kernel_param *kp)
+{
+	struct cs7542_fe_live *owner;
+	int len = 0;
+
+	mutex_lock(&cs_fe_live_owners_lock);
+	list_for_each_entry(owner, &cs_fe_live_owners, node) {
+		struct cs_fe_backend_io io;
+		unsigned int i;
+		u32 range = 0;
+		int err, ready;
+
+		mutex_lock(&owner->lock);
+		ready = cs_fe_live_ready(owner);
+		if (!ready && owner->backend.pending)
+			ready = -EBUSY;
+		io = cs_fe_live_io(owner);
+		io.limit_us = io.now_us(io.context) + 12000;
+		err = ready ?:
+			      cs_fe_native_mtu_readback(&owner->native.range[0],
+							&io, 0, &range);
+		len += sysfs_emit_at(buf, len, "epoch=%llu range_error=%d range0=0x%08x\n",
+			owner->epoch, err, range);
+		range = 0;
+		err = ready ?:
+			      cs_fe_native_mtu_readback(&owner->native.range[1],
+							&io, 1, &range);
+		len += sysfs_emit_at(buf, len,
+			"range1_error=%d range1=0x%08x configured_high=%u\n",
+			err, range, READ_ONCE(cs_native_mtu1500_high));
+		for (i = 0;
+		     i < owner->backend.next_lease && len < PAGE_SIZE - 256;
+		     i++) {
+			const struct cs_fe_backend_lease *lease =
+				&owner->backend.lease[i];
+			const struct cs7542_fe_hot_sample *before =
+				&owner->hot_before[i];
+			const struct cs_fe_tuple *tuple = &lease->rule.original;
+			struct cs7542_fe_hot_sample sample = {};
+			unsigned int bucket = lease->plan.key.bucket;
+			bool initial, complete, active;
+			__be32 src, dst;
+
+			if (!lease->policy.require_mtu_range ||
+			    !lease->submitted)
+				continue;
+			active = cs_native_lease_active(owner, i);
+			if (active && !ready)
+				cs_fe_hot_read(&io, bucket, &sample);
+			else if (!active)
+				sample = owner->hot_after[i];
+			initial = cs_native_sample_for(before, bucket);
+			complete = cs_native_sample_for(&sample, bucket) &&
+				   initial &&
+				   sample.timestamp_us >= before->timestamp_us;
+			src = htonl(tuple->src);
+			dst = htonl(tuple->dst);
+			len += sysfs_emit_at(buf, len,
+				"lease=%u bucket=%u active=%u uncertain=%u src=%pI4 dst=%pI4 sport=%u dport=%u before_complete=%u before=%u sample_complete=%u sample=%u transition=%u range_row=%u l4proto=%u\n",
+				i, bucket, active, !!ready, &src, &dst,
+				tuple->sport, tuple->dport, initial,
+				before->selected, complete, sample.selected,
+				complete && !before->selected &&
+					sample.selected,
+				lease->policy.require_mtu_range ==
+					CS_FE_MTU_RANGE_1500,
+				cs_fe_l4proto(&lease->rule, &lease->policy));
+		}
+		mutex_unlock(&owner->lock);
+		if (len >= PAGE_SIZE - 256)
+			break;
+	}
+	mutex_unlock(&cs_fe_live_owners_lock);
+	return len;
+}
+
+static const struct kernel_param_ops cs_native_activity_ops = {
+	.get = cs_native_activity_get
+};
+
+module_param_cb(native_activity, &cs_native_activity_ops, NULL, 0400);
diff --git a/drivers/net/ethernet/cortina/cs_fe_native_mtu.h b/drivers/net/ethernet/cortina/cs_fe_native_mtu.h
new file mode 100644
index 000000000..7a55b1d49
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_native_mtu.h
@@ -0,0 +1,43 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_NATIVE_MTU_H
+#define CS_FE_NATIVE_MTU_H
+
+#include "cs_fe_backend.h"
+
+/* The two positive HASH predicates index immutable, independently owned rows. */
+#define CS_FE_NATIVE_RANGE_ROWS 2U
+#define CS_FE_NATIVE_SMALL_HIGH 1046U
+#define CS_FE_NATIVE_IP_MTU 1500U
+/*
+ * A [64,1046] hardware range ended at IP length 1020 in both directions.
+ * The verified 1526 limit includes a 1500-byte IP packet on QCA4 framing.
+ */
+#define CS_FE_NATIVE_1500_MAX_HIGH 1526U
+
+struct cs_fe_native_mtu {
+	bool owned;
+	bool touched;
+	int error;
+};
+
+static inline u8 cs_fe_native_mtu_select(unsigned int route_mtu,
+					 unsigned int high)
+{
+	if (route_mtu < CS_FE_NATIVE_SMALL_HIGH)
+		return 0;
+	if (high && route_mtu >= CS_FE_NATIVE_IP_MTU)
+		return CS_FE_MTU_RANGE_1500;
+	return CS_FE_MTU_RANGE_SMALL;
+}
+
+int cs_fe_native_mtu_readback(const struct cs_fe_native_mtu *range,
+			      const struct cs_fe_backend_io *io,
+			      unsigned int row, u32 *actual);
+int cs_fe_native_mtu_prepare(struct cs_fe_native_mtu *range,
+			     const struct cs_fe_backend_io *io,
+			     unsigned int row, unsigned int high);
+int cs_fe_native_mtu_verify(struct cs_fe_native_mtu *range,
+			    const struct cs_fe_backend_io *io, unsigned int row,
+			    unsigned int high);
+
+#endif
diff --git a/drivers/net/ethernet/cortina/cs_fe_native_mtu.inc b/drivers/net/ethernet/cortina/cs_fe_native_mtu.inc
new file mode 100644
index 000000000..f0db52c1d
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_native_mtu.inc
@@ -0,0 +1,128 @@
+// SPDX-License-Identifier: GPL-2.0
+/* Included by the driver's sole indirect table owner. */
+#include "cs_fe_native_mtu.h"
+#define MTU_ACCESS 0x288U
+#define MTU_DATA 0x28cU
+
+static u32 cs_fe_native_range_word(unsigned int row, unsigned int high)
+{
+	if (!((row == 0 && high == CS_FE_NATIVE_SMALL_HIGH) ||
+	      (row == 1 && high >= CS_FE_NATIVE_IP_MTU &&
+	       high <= CS_FE_NATIVE_1500_MAX_HIGH)))
+		return 0;
+	return (1U << 28) | (high << 14) | 64U;
+}
+
+static int cs_fe_native_range_read(const struct cs_fe_backend_io *io,
+				   unsigned int row, u32 *word)
+{
+	int ret;
+
+	ret = idle(io, MTU_ACCESS);
+	if (!ret)
+		ret = before(io);
+	if (!ret)
+		ret = io->write32(io->context, MTU_ACCESS, ACL_START | row);
+	if (!ret)
+		ret = idle(io, MTU_ACCESS);
+	if (!ret)
+		ret = before(io);
+	if (!ret)
+		ret = io->read32(io->context, MTU_DATA, word);
+	return ret ?: before(io);
+}
+
+static int cs_fe_native_range_args(const struct cs_fe_native_mtu *range,
+				   const struct cs_fe_backend_io *io)
+{
+	if (!range || !io || !io->read32 || !io->write32 || !io->now_us ||
+	    !io->limit_us || io->extent < MTU_DATA + sizeof(u32))
+		return -EINVAL;
+
+	return range->error;
+}
+
+int cs_fe_native_mtu_readback(const struct cs_fe_native_mtu *range,
+			      const struct cs_fe_backend_io *io,
+			      unsigned int row, u32 *actual)
+{
+	int ret = cs_fe_native_range_args(range, io);
+
+	if (ret || !actual || row >= CS_FE_NATIVE_RANGE_ROWS)
+		return ret ?: -EINVAL;
+	if (!range->owned)
+		return -ENOENT;
+	return cs_fe_native_range_read(io, row, actual);
+}
+
+int cs_fe_native_mtu_verify(struct cs_fe_native_mtu *range,
+			    const struct cs_fe_backend_io *io, unsigned int row,
+			    unsigned int high)
+{
+	u32 expected = cs_fe_native_range_word(row, high);
+	u32 actual;
+	int ret;
+
+	ret = cs_fe_native_range_args(range, io);
+	if (ret || !expected)
+		return ret ?: -EINVAL;
+	if (!range->owned)
+		return -ENOENT;
+
+	ret = cs_fe_native_range_read(io, row, &actual);
+	if (!ret && actual != expected)
+		ret = -EUCLEAN;
+	if (ret)
+		range->error = ret;
+	return ret;
+}
+
+int cs_fe_native_mtu_prepare(struct cs_fe_native_mtu *range,
+			     const struct cs_fe_backend_io *io,
+			     unsigned int row, unsigned int high)
+{
+	u32 expected = cs_fe_native_range_word(row, high);
+	u32 actual;
+	int ret;
+
+	ret = cs_fe_native_range_args(range, io);
+	if (ret || !expected)
+		return ret ?: -EINVAL;
+	if (range->owned)
+		return cs_fe_native_mtu_verify(range, io, row, high);
+
+	ret = cs_fe_native_range_read(io, row, &actual);
+	if (ret)
+		return ret;
+	/*
+	 * The calibration bank and any foreign nonzero row have their own
+	 * lifetime. Even byte-identical contents do not convey ownership.
+	 */
+	if (actual)
+		return -EBUSY;
+
+	ret = before(io);
+	if (ret)
+		return ret;
+	/* A failed write may already have reached the indirect interface. */
+	range->touched = true;
+	ret = io->write32(io->context, MTU_DATA, expected);
+	if (!ret)
+		ret = before(io);
+	if (!ret)
+		ret = io->write32(io->context, MTU_ACCESS,
+				  ACL_START | ACL_WRITE | row);
+	if (!ret)
+		ret = idle(io, MTU_ACCESS);
+	if (!ret)
+		ret = cs_fe_native_range_read(io, row, &actual);
+	if (!ret && actual != expected)
+		ret = -EUCLEAN;
+	if (ret) {
+		range->error = ret;
+		return ret;
+	}
+
+	range->owned = true;
+	return 0;
+}
diff --git a/drivers/net/ethernet/cortina/cs_fe_native_state.h b/drivers/net/ethernet/cortina/cs_fe_native_state.h
new file mode 100644
index 000000000..c86e3a3e3
--- /dev/null
+++ b/drivers/net/ethernet/cortina/cs_fe_native_state.h
@@ -0,0 +1,24 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_NATIVE_STATE_H
+#define CS_FE_NATIVE_STATE_H
+
+#include <linux/cs7542_fe_native.h>
+#include "cs_fe_native_mtu.h"
+
+struct cs_fe_native_flow {
+	u64 block, version;
+	unsigned long cookie;
+	struct cs7542_fe_native_request path;
+};
+
+struct cs_fe_native_clock {
+	u64 baseline_us, last_zero_us, lastuse_us;
+};
+
+struct cs_fe_native_state {
+	struct cs_fe_native_clock clocks[CS_FE_BACKEND_LEASES];
+	struct cs_fe_native_mtu range[CS_FE_NATIVE_RANGE_ROWS];
+	struct cs_fe_native_flow flows[CS_FE_BACKEND_ENTRIES];
+};
+
+#endif
diff --git a/include/linux/cs7542_fe_backend.h b/include/linux/cs7542_fe_backend.h
new file mode 100644
index 000000000..2c412e17f
--- /dev/null
+++ b/include/linux/cs7542_fe_backend.h
@@ -0,0 +1,65 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS7542_FE_BACKEND_H
+#define CS7542_FE_BACKEND_H
+#include <linux/types.h>
+struct module;
+struct cs_fe_backend;
+struct cs_fe_backend_io;
+struct cs_fe_rule;
+struct cs_fe_key_policy;
+struct cs_fe_backend_encoding;
+struct cs_fe_plan;
+#define CS7542_FE_BACKEND_ABI 6
+
+enum cs_fe_hot_command {
+	CS_HOT_REPLACE,
+	CS_HOT_SCOPED,
+	CS_HOT_GUARDED,
+	CS_HOT_MARKER,
+	CS_HOT_ENCODED,
+	CS_HOT_REJECT,
+	CS_HOT_DESTROY,
+	CS_HOT_UNBIND,
+	CS_HOT_NATIVE,
+};
+
+/* Every pointer is borrowed synchronously under the NIC owner mutex. */
+
+#ifndef CS_FE_HOT_SELECTOR_DEFINED
+#define CS_FE_HOT_SELECTOR_DEFINED
+struct cs_fe_hot_selector {
+	u8 source[6], destination[6];
+	bool valid;
+};
+
+#endif
+struct cs_fe_hot_request {
+	struct cs_fe_hot_selector selector;
+	const struct cs_fe_plan
+		*validated_plan; /* optional borrowed owner receipt */
+	u64 block, version;
+	unsigned long cookie;
+	const struct cs_fe_rule *rule;
+	const struct cs_fe_key_policy *policy;
+	const struct cs_fe_backend_encoding *encoding;
+	int reason;
+	bool exact;
+};
+
+struct cs7542_fe_backend_ops {
+	u32 abi, size, state_size, revision;
+	struct module *owner;
+	const char *name;
+	int (*run)(enum cs_fe_hot_command command, struct cs_fe_backend *state,
+		   const struct cs_fe_backend_io *typed_io,
+		   const struct cs_fe_hot_request *request);
+};
+
+/*
+ * Registration pins module text. Runtime release is builtin sysfs only.
+ *
+ * module_exit performs no hardware cleanup and must never drop the last pin.
+ */
+int cs7542_fe_backend_register(const struct cs7542_fe_backend_ops *ops);
+bool cs7542_fe_backend_registered(const struct cs7542_fe_backend_ops *ops);
+#endif
diff --git a/include/linux/cs7542_fe_codec.h b/include/linux/cs7542_fe_codec.h
new file mode 100644
index 000000000..b2a3d7d60
--- /dev/null
+++ b/include/linux/cs7542_fe_codec.h
@@ -0,0 +1,145 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS_FE_ENCODE_H
+#define CS_FE_ENCODE_H
+
+#ifdef __KERNEL__
+#include <linux/types.h>
+#else
+#include <stdbool.h>
+#include <stdint.h>
+typedef uint8_t u8;
+typedef uint16_t u16;
+typedef uint32_t u32;
+#endif
+
+/* Numeric host order. Only the Linux adapter converts network-order tuples. */
+struct cs_fe_tuple {
+	u32 src;
+	u32 dst;
+	u16 sport;
+	u16 dport;
+};
+
+struct cs_fe_link {
+	u8 gmac;
+	u8 tag_mode;
+	u8 switch_port;
+	u8 cpu_port;
+	u16 base_voq;
+	u16 rx_qca_meta;
+	u8 base_mac[6];
+};
+
+struct cs_fe_rule {
+	struct cs_fe_tuple original;
+	struct cs_fe_tuple translated;
+	struct cs_fe_link ingress;
+	struct cs_fe_link egress;
+	u8 smac[6];
+	u8 dmac[6];
+	bool decrement_ttl;
+	/* Consumed only with a native per-packet range. Zero selects legacy UDP. */
+	u8 native_l4proto;
+};
+
+/* Leased by a separate owner, never allocated or deleted by this codec. */
+struct cs_fe_rows {
+	u16 class_row;
+	u16 sdb_row;
+	u16 mask_row;
+	u16 miss_fwd;
+	u16 hit_fwd;
+	u16 voq;
+	u16 l2;
+	u16 l3;
+	u16 fvlan;
+	u8 priority;
+	/* Diagnostic only, with both fallback IP replacements disabled. */
+	u32 miss_marker;
+};
+
+/* NF rules wildcard DSCP. Exact DSCP is an explicit lab profile only. */
+struct cs_fe_key_policy {
+	bool exact_dscp;
+	u8 dscp;
+	/* One positive PKTLEN_RANGE bit, or zero for a profile without a range. */
+	u8 require_mtu_range;
+};
+
+#define CS_FE_L4_TCP 6U
+#define CS_FE_L4_UDP 17U
+
+static inline u8 cs_fe_l4proto(const struct cs_fe_rule *rule,
+			       const struct cs_fe_key_policy *policy)
+{
+	if (policy->require_mtu_range && rule->native_l4proto)
+		return rule->native_l4proto;
+	return CS_FE_L4_UDP;
+}
+
+#define CS_FE_MTU_RANGE_SMALL 1U
+#define CS_FE_MTU_RANGE_1500 2U
+
+struct cs_fe_key {
+	u8 bytes[84];
+	u32 crc32;
+	u16 crc16;
+	u16 bucket;
+};
+
+#define CS_FE_IMAGE(n)           \
+	struct {                 \
+		u32 input[n];    \
+		u32 expected[n]; \
+		u8 words;        \
+	}
+
+/* IHL5, no fragments, valid nonzero UDP checksum, TTL > 1 and MTU guards. */
+#define CS_FE_REQ_PACKET_EXCEPTIONS (1U << 0)
+#define CS_FE_REQ_COLLISION_CHECK (1U << 1)
+#define CS_FE_REQ_OWNER_LIFETIME (1U << 2)
+
+struct cs_fe_plan {
+	struct cs_fe_key key;
+
+	CS_FE_IMAGE(20) class_invalid, class_valid;
+	CS_FE_IMAGE(7) sdb;
+	CS_FE_IMAGE(5) mask, l3;
+	CS_FE_IMAGE(4) miss, hit, l2;
+	CS_FE_IMAGE(2) voq, fvlan;
+	/* Fresh main way0/slot0. No hardware valid bit is invented. */
+	u32 hash[4];
+	unsigned int requirements;
+	bool write_l3;
+	bool write_fvlan;
+	bool source_nat;
+	bool destination_nat;
+	/* Prediction, not an internal-link observation. */
+	u16 predicted_tx_qca;
+};
+
+#undef CS_FE_IMAGE
+
+/*
+ * Pure serialization: return0 is not hardware acceptance. No MMIO, allocation,
+ * retention or exception proof is provided. Failure leaves output untouched.
+ */
+int cs_fe_encode(const struct cs_fe_rule *rule, const struct cs_fe_rows *rows,
+		 const struct cs_fe_key_policy *policy, struct cs_fe_plan *out);
+void cs_fe_exact_class_ipv4(struct cs_fe_plan *plan,
+			    const struct cs_fe_tuple *tuple, const u8 source[6],
+			    const u8 destination[6]);
+
+enum cs_fe_class_match {
+	CS_FE_CLASS_MATCH_DA = 1,
+	CS_FE_CLASS_MATCH_SA = 2,
+	CS_FE_CLASS_MATCH_IP_DA = 4,
+	CS_FE_CLASS_MATCH_IP_SA = 8,
+	CS_FE_CLASS_MATCH_REVERSED_MAC = 16,
+};
+
+void cs_fe_class_addresses(struct cs_fe_plan *plan,
+			   const struct cs_fe_tuple *tuple, const u8 source[6],
+			   const u8 destination[6], unsigned int match);
+
+#endif
diff --git a/include/linux/cs7542_fe_live.h b/include/linux/cs7542_fe_live.h
new file mode 100644
index 000000000..fe863c058
--- /dev/null
+++ b/include/linux/cs7542_fe_live.h
@@ -0,0 +1,58 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef _LINUX_CS7542_FE_LIVE_H
+#define _LINUX_CS7542_FE_LIVE_H
+#include <linux/types.h>
+#include <linux/cs7542_fe_codec.h>
+#define CS7542_FE_LIVE_API_VERSION 1
+#ifndef __KERNEL__
+typedef uint64_t u64;
+#define __iomem
+#endif
+struct device;
+struct net_device;
+struct cs_fe_rule;
+struct cs_fe_key_policy;
+struct cs7542_fe_live;
+/* Built-in owner only; no arbitrary row, address, register or table selector. */
+struct cs7542_fe_live_status {
+	u64 epoch;
+	u32 admitted_requirements, leases, capacity, blocks;
+	int first_error;
+	bool online, closing, poisoned, pending, reset_verified;
+};
+
+/*
+ * Borrowed conduit is resolved to its actual NE context. Returned references
+ *
+ * pin this BUILT-IN owner metadata, never authorize I/O after owner_stop.
+ */
+struct cs7542_fe_live *cs7542_fe_live_get(struct net_device *conduit);
+void cs7542_fe_live_put(struct cs7542_fe_live *owner);
+int cs7542_fe_live_open(struct cs7542_fe_live *owner, u64 *owner_block);
+int cs7542_fe_live_reject(struct cs7542_fe_live *owner, u64 owner_block,
+			  unsigned long cookie, u64 version, int reason);
+int cs7542_fe_live_destroy(struct cs7542_fe_live *owner, u64 owner_block,
+			   unsigned long cookie, u64 current_version);
+int cs7542_fe_live_close(struct cs7542_fe_live *owner, u64 owner_block);
+int cs7542_fe_live_status(struct cs7542_fe_live *owner,
+			  struct cs7542_fe_live_status *status);
+/*
+ * Engine hooks, never called by the loadable provider. init serializes the
+ * existing real FE initialization under the SAME mutex as runtime scratch.
+ * Stop excludes I/O BEFORE devres unmap; reset_done only follows verified
+ * complete NE reset, not merely port-down or a failed reset attempt.
+ */
+struct cs7542_fe_live *cs7542_fe_live_create(struct device *dev,
+					     void __iomem *base,
+					     unsigned int extent);
+int cs7542_fe_live_init(struct cs7542_fe_live *owner,
+			int (*initialize)(struct device *dev,
+					  void __iomem *base));
+void cs7542_fe_live_activate(struct cs7542_fe_live *owner);
+int cs7542_fe_live_bind(struct cs7542_fe_live *owner,
+			struct net_device *conduit, unsigned int gmac);
+void cs7542_fe_live_unbind(struct cs7542_fe_live *owner,
+			   struct net_device *conduit, unsigned int gmac);
+void cs7542_fe_live_stop(struct cs7542_fe_live *owner);
+void cs7542_fe_live_reset_done(struct cs7542_fe_live *owner);
+#endif
diff --git a/include/linux/cs7542_fe_native.h b/include/linux/cs7542_fe_native.h
new file mode 100644
index 000000000..97ab51e28
--- /dev/null
+++ b/include/linux/cs7542_fe_native.h
@@ -0,0 +1,34 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef CS7542_FE_NATIVE_H
+#define CS7542_FE_NATIVE_H
+
+#include <linux/cs7542_fe_live.h>
+
+#define CS7542_FE_NATIVE_ABI 2
+
+/*
+ * Only ordinary Ethernet and Linux route properties cross the module boundary.
+ * The owner exclusively manages hardware resources and decides admission.
+ */
+struct cs7542_fe_native_request {
+	u32 abi, size;
+	u64 format_epoch;
+	u32 ingress_ifindex, egress_ifindex;
+	u16 route_mtu;
+	u8 ingress_smac[6];
+	struct cs_fe_rule rule;
+};
+
+int cs7542_fe_live_replace_native(struct cs7542_fe_live *owner, u64 block, unsigned long cookie,
+	u64 version, const struct cs7542_fe_native_request *request);
+
+struct flow_cls_offload;
+int cs7542_fe_live_replace_native_tcp(struct cs7542_fe_live *owner, u64 block, unsigned long cookie,
+	u64 version, const struct cs7542_fe_native_request *request,
+	const struct flow_cls_offload *cls);
+
+int cs7542_fe_live_native_lastused(struct cs7542_fe_live *owner, u64 block,
+				   unsigned long cookie,
+				   unsigned long *lastused);
+
+#endif
diff --git a/include/linux/cs7542_ft_live.h b/include/linux/cs7542_ft_live.h
new file mode 100644
index 000000000..c7e318eb5
--- /dev/null
+++ b/include/linux/cs7542_ft_live.h
@@ -0,0 +1,70 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef _LINUX_CS7542_FT_LIVE_H
+#define _LINUX_CS7542_FT_LIVE_H
+#include <linux/types.h>
+struct module;
+struct net_device;
+struct flow_cls_offload;
+struct cs7542_ft_live;
+/*
+ * No private NF cookie interpretation. All calls synchronous and borrowed.
+ * rule() may resolve topology with rtnl_trylock ONLY: core BIND holds RTNL.
+ * No raw MMIO is exposed by this entrypoint. A separate built-in FE owner
+ * issues numeric leases and retains quarantine across provider replacement.
+ */
+#define CS7542_FT_LIVE_API_VERSION 1
+struct cs7542_ft_live_ops {
+	u32 api_version;
+	u32 size;
+	struct module *owner;
+	const char *name;
+	int (*open)(void *provider, u64 block, struct net_device *conduit);
+	/*
+	 * REPLACE must retire any prior version before rejecting a new rule.
+	 * Return0 only for a verified installation; pure encoding is NOT acceptance.
+	 * STATS must not fabricate counters/lastused. No borrowed pointer survives.
+	 */
+	int (*rule)(void *provider, u64 block, struct flow_cls_offload *cls);
+	/*
+	 * close success means every lookup owned by this block is inactive; it
+	 * NEVER promises drain/resource reuse. Error keeps provider pinned.
+	 */
+	int (*close)(void *provider, u64 block);
+	/*
+	 * Close all provider-owned non-NF proof handles too. Serialize against its
+	 * controls, cancel further arms, and retain module pin on any uncertainty.
+	 */
+	int (*detach)(void *provider);
+};
+
+int cs7542_ft_live_register(const struct cs7542_ft_live_ops *ops,
+			    void *provider);
+/*
+ * Explicitly call before rmmod. On error registration remains closed+pinned;
+ * retry is permitted. module_exit cannot report failed withdrawal.
+ */
+/*
+ * Runtime unregister must be initiated from built-in detach sysfs, not a
+ * module-text control that could drop its last pin while still executing.
+ * This exported form is for COMING/module_init rollback only.
+ */
+int cs7542_ft_live_unregister(const struct cs7542_ft_live_ops *ops,
+			      void *provider);
+struct cs7542_ft_live *cs7542_ft_live_create(struct net_device *conduit,
+					     u32 gmac);
+int cs7542_ft_live_setup(struct cs7542_ft_live *live, int type, void *data);
+/*
+ * Stop all CPU callback access before freeing the conduit. No owner MMIO
+ * lifetime promise: backend FE owner stop/reset is a separate ordered step.
+ */
+/*
+ * Built-in QCA owner only (not exported to modules): serialize table withdrawal
+ * against a format transition, with admission held through exact readback.
+ */
+int cs7542_ft_live_format_hold(void);
+int cs7542_ft_live_format_release(void);
+bool cs7542_ft_live_format_held(void);
+int cs7542_ft_live_quiesce(struct cs7542_ft_live *live);
+void cs7542_ft_live_put(struct cs7542_ft_live *live);
+ssize_t cs7542_ft_live_format(struct cs7542_ft_live *live, char *buffer);
+#endif
diff --git a/include/linux/dsa/qca8k_persistent.h b/include/linux/dsa/qca8k_persistent.h
new file mode 100644
index 000000000..5363f7ad0
--- /dev/null
+++ b/include/linux/dsa/qca8k_persistent.h
@@ -0,0 +1,45 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef QCA8K_PERSISTENT_STATUS_H
+#define QCA8K_PERSISTENT_STATUS_H
+#include <linux/types.h>
+#include <linux/errno.h>
+
+struct net_device;
+#define QCA8K_PERSISTENT_STATUS_VERSION 1
+struct qca8k_persistent_status {
+	__u32 size;
+	__u32 version;
+	__u64 epoch;
+	__u32 selected;
+	__u32 tree_protocol;
+	__u32 requested;
+	__u32 known;
+	__u32 coherent;
+	__u32 ready;
+	__u32 closing;
+	__u32 restore_debt;
+	__u32 uncertain;
+	__s32 first_error;
+	__s32 held_fault;
+	__u32 conduit_mtu[2];
+	__u32 reserved;
+};
+
+/*
+ * Process context with RTNL held. Read-only, no table programming, deadline or
+ * fabricated bounded ownership. The caller must require known/coherent/ready
+ * and still enforce every independent packet/topology/hardware admission gate.
+ */
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+int qca8k_persistent_status(struct net_device *conduit,
+			    struct qca8k_persistent_status *status);
+#else
+static inline int
+qca8k_persistent_status(struct net_device *conduit,
+			struct qca8k_persistent_status *status)
+{
+	return -EOPNOTSUPP;
+}
+
+#endif
+#endif

-- 
2.53.0

