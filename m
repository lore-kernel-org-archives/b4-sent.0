From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Wed, 25 Nov 2026 23:50:33 +0300
Subject: [PATCH RFC net-next 5/7] net: dsa: qca8k: select the four-byte
 format before port activation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-almondplus-offload-rfc-v1-5-703175c6340c@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795639829; l=61426;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=bUSt3pDQgh/H9XGb04MdFUXYSnI8JSWFqeIgcNKIwV0=;
 b=6kb3VRg9pIKbaGCL2rTw2bBjfjmNtW+53AaFDmgGSXl/nqt4Bspf08lT9BVyg9exr4ZYX06kP
 /YbMRDATr14Dygw18YTscrFKBc0h4sYVToXV9sjgZO9ifijvMvMv37b
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Select the requested format from the CPU ports before DSA chooses its
tagger. Stop packet actors and verify the switch header state before
opening user ports. Use MDIO for management and preserve both conduit
MTUs.

On teardown, retire flowtable lookups before changing the format.
Restore and verify the two-byte baseline before releasing the format
hold. The initial supported topology is the CS7542 dual-conduit QCA8337
arrangement; unsupported topologies remain rejected.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/net/dsa/qca/persistent_qca4.h              | 178 ++++++
 drivers/net/dsa/qca/persistent_qca4_mtu.h          | 165 ++++++
 drivers/net/dsa/qca/qca8k-8xxx.c                   | 123 +++-
 drivers/net/dsa/qca/qca8k-common.c                 |  42 +-
 drivers/net/dsa/qca/qca8k-persistent-boot.inc      | 632 +++++++++++++++++++++
 drivers/net/dsa/qca/qca8k-persistent-lifecycle.inc | 394 +++++++++++++
 drivers/net/dsa/qca/qca8k.h                        |  40 ++
 7 files changed, 1564 insertions(+), 10 deletions(-)

diff --git a/drivers/net/dsa/qca/persistent_qca4.h b/drivers/net/dsa/qca/persistent_qca4.h
new file mode 100644
index 000000000..6e4dc2162
--- /dev/null
+++ b/drivers/net/dsa/qca/persistent_qca4.h
@@ -0,0 +1,178 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/* Source-only transaction core. No driver hookup or register-address API. */
+#ifndef QCA4_PERSISTENT_TRANSACTION_H
+#define QCA4_PERSISTENT_TRANSACTION_H
+#ifdef __KERNEL__
+#include <linux/types.h>
+#include <linux/errno.h>
+typedef u32 qca4_word;
+#else
+#include <stdint.h>
+#include <stdbool.h>
+#include <errno.h>
+typedef uint32_t qca4_word;
+#endif
+
+#define QCA4_PERSISTENT_MASK 0x1ffffU
+#define QCA4_PERSISTENT_VALUE 0x18100U
+#define QCA4_PERSISTENT_CPU_HEADER 0xaU
+
+/*
+ * Stop/restore callbacks must attempt every relevant field and preserve the
+ * first errno separately from verified readback. Only the actual bus owner
+ * may implement them; this header supplies no hardware executor.
+ */
+struct qca4_persistent_ops {
+	void *context;
+	int (*quiesce)(void *context);
+	int (*stop_all_macs)(void *context);
+	int (*read_global)(void *context, qca4_word *value);
+	int (*read_cpu_header)(void *context, unsigned int cpu_port,
+			       qca4_word *value);
+	int (*set_global)(void *context, qca4_word value, bool restore,
+			  bool *verified);
+	int (*software_ready)(void *context);
+	int (*replay_cpu_enables)(void *context);
+};
+
+struct qca4_persistent_state {
+	bool requested;
+	bool hardware4;
+	bool ready;
+	bool saved_valid;
+	bool restore_pending;
+	bool unknown;
+	qca4_word saved_header;
+	int first_error;
+};
+
+static inline int qca4_persistent_error(struct qca4_persistent_state *state,
+					int error)
+{
+	if (error < 0 && !state->first_error)
+		state->first_error = error;
+	return error;
+}
+
+/*
+ * May run only after all packet actors are closed/drained, before software
+ * detachment, or during unpublished setup unwind. No running tagger is flipped.
+ */
+static inline int qca4_persistent_restore(struct qca4_persistent_state *state,
+					  struct qca4_persistent_ops *ops)
+{
+	bool verified = false;
+	int error;
+
+	state->ready = false;
+	error = ops->quiesce(ops->context);
+	if (error)
+		return qca4_persistent_error(state, error);
+	error = ops->stop_all_macs(ops->context);
+	if (error)
+		return qca4_persistent_error(state, error);
+	if (!state->restore_pending)
+		return 0;
+	if (!state->saved_valid)
+		return qca4_persistent_error(state, -EUCLEAN);
+	error = ops->set_global(ops->context, state->saved_header, true,
+				&verified);
+	qca4_persistent_error(state, error);
+	if (!verified) {
+		state->unknown = true;
+		return error ? error : qca4_persistent_error(state, -EIO);
+	}
+	state->hardware4 = false;
+	state->restore_pending = false;
+	state->unknown = false;
+	return error;
+}
+
+static inline int qca4_persistent_begin(struct qca4_persistent_state *state,
+					struct qca4_persistent_ops *ops,
+					bool opt_in)
+{
+	qca4_word header;
+	bool verified = false;
+	int error;
+
+	if (!opt_in)
+		return 0; /* Default QCA2: zero callbacks and zero new I/O. */
+	if (state->requested || state->restore_pending || state->first_error)
+		return -EBUSY;
+	state->requested = true;
+	error = ops->quiesce(ops->context);
+	if (error)
+		return qca4_persistent_error(state, error);
+	error = ops->stop_all_macs(ops->context);
+	if (error)
+		return qca4_persistent_error(state, error);
+	error = ops->read_global(ops->context, &header);
+	if (error)
+		return qca4_persistent_error(state, error);
+	if (header & 0x10000U)
+		return qca4_persistent_error(state, -EUCLEAN);
+	state->saved_header = header & QCA4_PERSISTENT_MASK;
+	state->saved_valid = true;
+	error = ops->read_cpu_header(ops->context, 0, &header);
+	if (!error && header != QCA4_PERSISTENT_CPU_HEADER)
+		error = -EUCLEAN;
+	if (!error)
+		error = ops->read_cpu_header(ops->context, 6, &header);
+	if (!error && header != QCA4_PERSISTENT_CPU_HEADER)
+		error = -EUCLEAN;
+	if (error)
+		return qca4_persistent_error(state, error);
+	state->restore_pending = true; /* Before a possibly applied write. */
+	error = ops->set_global(ops->context, QCA4_PERSISTENT_VALUE, false,
+				&verified);
+	if (error || !verified) {
+		qca4_persistent_error(state, error ? error : -EIO);
+		(void)qca4_persistent_restore(state, ops);
+		return state->first_error;
+	}
+	state->hardware4 = true;
+	return 0;
+}
+
+/*
+ * First-user-open gate, after actual DSA conduit setup. software_ready must
+ * check both actual dsa_ptr/tag_ops/rcv identities AND effective MTUs. The
+ * conduit MTU setter returning success earlier is insufficient evidence.
+ */
+static inline int qca4_persistent_ready(struct qca4_persistent_state *state,
+					struct qca4_persistent_ops *ops)
+{
+	qca4_word header;
+	int error;
+
+	if (!state->hardware4 || state->unknown || state->first_error)
+		return -EIO;
+	error = ops->software_ready(ops->context);
+	if (error)
+		return error;
+	error = ops->read_global(ops->context, &header);
+	if (!error && (header & QCA4_PERSISTENT_MASK) != QCA4_PERSISTENT_VALUE)
+		error = -EUCLEAN;
+	if (!error)
+		error = ops->read_cpu_header(ops->context, 0, &header);
+	if (!error && header != QCA4_PERSISTENT_CPU_HEADER)
+		error = -EUCLEAN;
+	if (!error)
+		error = ops->read_cpu_header(ops->context, 6, &header);
+	if (!error && header != QCA4_PERSISTENT_CPU_HEADER)
+		error = -EUCLEAN;
+	if (!error)
+		error = ops->replay_cpu_enables(ops->context);
+	if (error) {
+		int stopped = ops->stop_all_macs(ops->context);
+
+		if (stopped)
+			state->unknown = true;
+		return qca4_persistent_error(state, error);
+	}
+	state->ready = true;
+	return 0;
+}
+
+#endif
diff --git a/drivers/net/dsa/qca/persistent_qca4_mtu.h b/drivers/net/dsa/qca/persistent_qca4_mtu.h
new file mode 100644
index 000000000..efbc482bb
--- /dev/null
+++ b/drivers/net/dsa/qca/persistent_qca4_mtu.h
@@ -0,0 +1,165 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#ifndef QCA4_PERSISTENT_MTU_H
+#define QCA4_PERSISTENT_MTU_H
+#include "persistent_qca4.h"
+
+enum qca4_persistent_mtu_field {
+	QCA4_PMTU_CONDUIT0,
+	QCA4_PMTU_CONDUIT6,
+	QCA4_PMTU_FRAME,
+	QCA4_PMTU_MAC0,
+	QCA4_PMTU_MAC6,
+	QCA4_PMTU_FIELDS,
+};
+
+struct qca4_persistent_mtu_state {
+	qca4_word saved[QCA4_PMTU_FIELDS];
+	qca4_word committed_mtu[2];
+	qca4_word committed_frame;
+	bool committed_valid;
+	bool pending;
+	bool unknown;
+	int first_error;
+};
+
+struct qca4_persistent_mtu_ops {
+	void *context;
+	int (*read)(void *context, enum qca4_persistent_mtu_field field, qca4_word *value);
+	int (*write)(void *context, enum qca4_persistent_mtu_field field, qca4_word value,
+		     bool restore, bool *verified);
+};
+
+static inline void qca4_pmtu_error(struct qca4_persistent_mtu_state *state,
+				   int error)
+{
+	if (error && !state->first_error)
+		state->first_error = error;
+}
+
+static inline int qca4_pmtu_write(struct qca4_persistent_mtu_ops *ops,
+				  enum qca4_persistent_mtu_field field,
+				  qca4_word value, bool restore, bool *verified)
+{
+	int ret;
+
+	*verified = false;
+	ret = ops->write(ops->context, field, value, restore, verified);
+	return ret ? ret : *verified ? 0 : -EIO;
+}
+
+/*
+ * Caller holds RTNL and the SAME mutex used by async MAC callbacks. No nested
+ * phylink stop/close here. Both CPU MACs must be independently verified stopped
+ * before any conduit/global frame update, including rollback.
+ */
+static inline int qca4_pmtu_restore(struct qca4_persistent_mtu_state *state,
+				    struct qca4_persistent_mtu_ops *ops)
+{
+	bool verified, stopped = true, restored = true;
+	int field, ret, first = 0;
+
+	if (!state->pending)
+		return 0;
+	for (field = QCA4_PMTU_MAC0; field <= QCA4_PMTU_MAC6; field++) {
+		ret = qca4_pmtu_write(ops, field, 0, true, &verified);
+		if (ret && !first)
+			first = ret;
+		if (!verified)
+			stopped = false;
+	}
+	if (!stopped)
+		goto unknown;
+	for (field = QCA4_PMTU_CONDUIT0; field <= QCA4_PMTU_FRAME; field++) {
+		ret = qca4_pmtu_write(ops, field, state->saved[field], true,
+				      &verified);
+		if (ret && !first)
+			first = ret;
+		if (!verified)
+			restored = false;
+	}
+	if (!restored)
+		goto unknown;
+	for (field = QCA4_PMTU_MAC0; field <= QCA4_PMTU_MAC6; field++) {
+		ret = qca4_pmtu_write(ops, field, state->saved[field], true,
+				      &verified);
+		if (ret && !first)
+			first = ret;
+		if (!verified)
+			restored = false;
+	}
+	if (!restored) {
+		/* A possibly applied restore cannot leave one CPU active. */
+		for (field = QCA4_PMTU_MAC0; field <= QCA4_PMTU_MAC6; field++) {
+			ret = qca4_pmtu_write(ops, field, 0, true, &verified);
+			if (ret && !first)
+				first = ret;
+		}
+		goto unknown;
+	}
+	state->pending = false;
+	state->unknown = false;
+	qca4_pmtu_error(state, first);
+	return first;
+unknown:
+	state->unknown = true;
+	qca4_pmtu_error(state, first ? first : -EIO);
+	return first ? first : -EIO;
+}
+
+static inline int qca4_pmtu_change(struct qca4_persistent_mtu_state *state,
+				   struct qca4_persistent_mtu_ops *ops,
+				   qca4_word conduit_mtu, qca4_word frame)
+{
+	bool verified;
+	int field, ret, original;
+
+	if (state->pending || state->unknown || state->first_error)
+		return -EUCLEAN;
+	for (field = 0; field < QCA4_PMTU_FIELDS; field++) {
+		ret = ops->read(ops->context, field, &state->saved[field]);
+		if (ret)
+			return ret;
+	}
+	/*
+	 * DSA may already have changed the assigned conduit before invoking
+	 * port_change_mtu. Restore our last committed pair, not that half-new
+	 * snapshot. On initial readiness, both actual values are the baseline.
+	 */
+	if (state->committed_valid) {
+		state->saved[QCA4_PMTU_CONDUIT0] = state->committed_mtu[0];
+		state->saved[QCA4_PMTU_CONDUIT6] = state->committed_mtu[1];
+	}
+	state->pending = true;
+	for (field = QCA4_PMTU_MAC0; field <= QCA4_PMTU_MAC6; field++) {
+		ret = qca4_pmtu_write(ops, field, 0, false, &verified);
+		if (ret)
+			goto rollback;
+	}
+	for (field = QCA4_PMTU_CONDUIT0; field <= QCA4_PMTU_FRAME; field++) {
+		ret = qca4_pmtu_write(ops, field,
+				      field == QCA4_PMTU_FRAME ? frame :
+								 conduit_mtu,
+				      false, &verified);
+		if (ret)
+			goto rollback;
+	}
+	for (field = QCA4_PMTU_MAC0; field <= QCA4_PMTU_MAC6; field++) {
+		ret = qca4_pmtu_write(ops, field, state->saved[field], true,
+				      &verified);
+		if (ret)
+			goto rollback;
+	}
+	state->pending = false;
+	state->committed_valid = true;
+	state->committed_mtu[0] = conduit_mtu;
+	state->committed_mtu[1] = conduit_mtu;
+	state->committed_frame = frame;
+	return 0;
+rollback:
+	original = ret;
+	qca4_pmtu_error(state, original);
+	(void)qca4_pmtu_restore(state, ops);
+	return original;
+}
+
+#endif
diff --git a/drivers/net/dsa/qca/qca8k-8xxx.c b/drivers/net/dsa/qca/qca8k-8xxx.c
index 382753bcc..3e120ddaa 100644
--- a/drivers/net/dsa/qca/qca8k-8xxx.c
+++ b/drivers/net/dsa/qca/qca8k-8xxx.c
@@ -174,6 +174,9 @@ static void qca8k_rw_reg_ack_handler(struct dsa_switch *ds, struct sk_buff *skb)
 	u8 len, cmd;
 	int i;
 
+	if (qca8k_private_mgmt_blocked(priv))
+		return;
+
 	mgmt_ethhdr = (struct qca_mgmt_ethhdr *)skb_mac_header(skb);
 	mgmt_eth_data = &priv->mgmt_eth_data;
 
@@ -321,6 +324,9 @@ static int qca8k_read_eth(struct qca8k_priv *priv, u32 reg, u32 *val, int len)
 	bool ack;
 	int ret;
 
+	if (qca8k_private_mgmt_blocked(priv))
+		return -EOPNOTSUPP;
+
 	skb = qca8k_alloc_mdio_header(MDIO_READ, reg, NULL,
 				      QCA8K_ETHERNET_MDIO_PRIORITY, len);
 	if (!skb)
@@ -329,7 +335,7 @@ static int qca8k_read_eth(struct qca8k_priv *priv, u32 reg, u32 *val, int len)
 	mutex_lock(&mgmt_eth_data->mutex);
 
 	/* Check if the mgmt_conduit if is operational */
-	if (!priv->mgmt_conduit) {
+	if (qca8k_private_mgmt_blocked(priv) || !priv->mgmt_conduit) {
 		kfree_skb(skb);
 		mutex_unlock(&mgmt_eth_data->mutex);
 		return -EINVAL;
@@ -373,6 +379,9 @@ static int qca8k_write_eth(struct qca8k_priv *priv, u32 reg, u32 *val, int len)
 	bool ack;
 	int ret;
 
+	if (qca8k_private_mgmt_blocked(priv))
+		return -EOPNOTSUPP;
+
 	skb = qca8k_alloc_mdio_header(MDIO_WRITE, reg, val,
 				      QCA8K_ETHERNET_MDIO_PRIORITY, len);
 	if (!skb)
@@ -381,7 +390,7 @@ static int qca8k_write_eth(struct qca8k_priv *priv, u32 reg, u32 *val, int len)
 	mutex_lock(&mgmt_eth_data->mutex);
 
 	/* Check if the mgmt_conduit if is operational */
-	if (!priv->mgmt_conduit) {
+	if (qca8k_private_mgmt_blocked(priv) || !priv->mgmt_conduit) {
 		kfree_skb(skb);
 		mutex_unlock(&mgmt_eth_data->mutex);
 		return -EINVAL;
@@ -513,7 +522,7 @@ qca8k_bulk_read(void *ctx, const void *reg_buf, size_t reg_len,
 	struct qca8k_priv *priv = ctx;
 	u32 reg = *(u16 *)reg_buf;
 
-	if (priv->mgmt_conduit &&
+	if (!qca8k_private_mgmt_blocked(priv) && priv->mgmt_conduit &&
 	    !qca8k_read_eth(priv, reg, val_buf, val_len))
 		return 0;
 
@@ -536,7 +545,7 @@ qca8k_bulk_gather_write(void *ctx, const void *reg_buf, size_t reg_len,
 	u32 reg = *(u16 *)reg_buf;
 	u32 *val = (u32 *)val_buf;
 
-	if (priv->mgmt_conduit &&
+	if (!qca8k_private_mgmt_blocked(priv) && priv->mgmt_conduit &&
 	    !qca8k_write_eth(priv, reg, val, val_len))
 		return 0;
 
@@ -564,7 +573,8 @@ qca8k_regmap_update_bits(void *ctx, uint32_t reg, uint32_t mask, uint32_t write_
 {
 	struct qca8k_priv *priv = ctx;
 
-	if (!qca8k_regmap_update_bits_eth(priv, reg, mask, write_val))
+	if (!qca8k_private_mgmt_blocked(priv) &&
+	    !qca8k_regmap_update_bits_eth(priv, reg, mask, write_val))
 		return 0;
 
 	return qca8k_regmap_update_bits_mii(priv, reg, mask, write_val);
@@ -635,6 +645,9 @@ qca8k_phy_eth_command(struct qca8k_priv *priv, bool read, int phy,
 	int ret, ret1;
 	bool ack;
 
+	if (qca8k_private_mgmt_blocked(priv))
+		return -EOPNOTSUPP;
+
 	if (regnum >= QCA8K_MDIO_MASTER_MAX_REG)
 		return -EINVAL;
 
@@ -690,7 +703,7 @@ qca8k_phy_eth_command(struct qca8k_priv *priv, bool read, int phy,
 
 	/* Check if mgmt_conduit is operational */
 	mgmt_conduit = priv->mgmt_conduit;
-	if (!mgmt_conduit) {
+	if (qca8k_private_mgmt_blocked(priv) || !mgmt_conduit) {
 		mutex_unlock(&mgmt_eth_data->mutex);
 		mutex_unlock(&priv->bus->mdio_lock);
 		ret = -EINVAL;
@@ -1465,6 +1478,12 @@ qca8k_phylink_mac_link_up(struct phylink_config *config,
 	int port = dp->index;
 	u32 reg;
 
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	if (!READ_ONCE(priv->persistent_boot.requested) &&
+	    READ_ONCE(priv->private_open_blocked))
+		return;
+#endif
+
 	if (phylink_autoneg_inband(mode)) {
 		reg = QCA8K_PORT_STATUS_LINK_AUTO;
 	} else {
@@ -1494,6 +1513,12 @@ qca8k_phylink_mac_link_up(struct phylink_config *config,
 	}
 
 	reg |= QCA8K_PORT_STATUS_TXMAC | QCA8K_PORT_STATUS_RXMAC;
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	if (qca8k_persistent_link_up(priv, port, reg))
+		return;
+	if (READ_ONCE(priv->private_open_blocked))
+		return;
+#endif
 
 	qca8k_write(priv, QCA8K_REG_PORT_STATUS(port), reg);
 }
@@ -1673,6 +1698,9 @@ static void qca8k_mib_autocast_handler(struct dsa_switch *ds, struct sk_buff *sk
 	u8 port;
 	int i;
 
+	if (qca8k_private_mgmt_blocked(priv))
+		return;
+
 	mib_ethhdr = (struct mib_ethhdr *)skb_mac_header(skb);
 	mib_eth_data = &priv->mib_eth_data;
 
@@ -1720,6 +1748,10 @@ qca8k_get_ethtool_stats_eth(struct dsa_switch *ds, int port, u64 *data)
 	mib_eth_data = &priv->mib_eth_data;
 
 	mutex_lock(&mib_eth_data->mutex);
+	if (qca8k_private_mgmt_blocked(priv)) {
+		mutex_unlock(&mib_eth_data->mutex);
+		return -EOPNOTSUPP;
+	}
 
 	reinit_completion(&mib_eth_data->rw_done);
 
@@ -1768,6 +1800,9 @@ static enum dsa_tag_protocol
 qca8k_get_tag_protocol(struct dsa_switch *ds, int port,
 		       enum dsa_tag_protocol mp)
 {
+	if (IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE))
+		return READ_ONCE(
+			((struct qca8k_priv *)ds->priv)->private_tag_protocol);
 	return DSA_TAG_PROTO_QCA;
 }
 
@@ -1782,6 +1817,18 @@ qca8k_conduit_change(struct dsa_switch *ds, const struct net_device *conduit,
 	if (dp->index != 0)
 		return;
 
+	if (IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)) {
+		mutex_lock(&priv->mib_eth_data.mutex);
+		mutex_lock(&priv->mgmt_eth_data.mutex);
+		priv->mgmt_conduit =
+			operational && !qca8k_private_mgmt_blocked(priv) ?
+				(struct net_device *)conduit :
+				NULL;
+		mutex_unlock(&priv->mgmt_eth_data.mutex);
+		mutex_unlock(&priv->mib_eth_data.mutex);
+		return;
+	}
+
 	mutex_lock(&priv->mgmt_eth_data.mutex);
 	mutex_lock(&priv->mib_eth_data.mutex);
 
@@ -1804,6 +1851,14 @@ static int qca8k_connect_tag_protocol(struct dsa_switch *ds,
 		tagger_data->mib_autocast_handler = qca8k_mib_autocast_handler;
 
 		break;
+	case DSA_TAG_PROTO_QCA4:
+		if (!IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE) ||
+		    ((struct qca8k_priv *)ds->priv)->private_tag_protocol !=
+			    DSA_TAG_PROTO_QCA4)
+			return -EOPNOTSUPP;
+		/* No tagger_data allocation/legacy14-byte callbacks for private4. */
+		break;
+
 	default:
 		return -EOPNOTSUPP;
 	}
@@ -1851,8 +1906,11 @@ static void qca8k_setup_hol_fixup(struct qca8k_priv *priv, int port)
 			   mask);
 }
 
-static int
-qca8k_setup(struct dsa_switch *ds)
+#if !IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+#define qca8k_setup_native qca8k_setup
+#endif
+
+static int qca8k_setup_native(struct dsa_switch *ds)
 {
 	struct qca8k_priv *priv = ds->priv;
 	struct dsa_port *dp;
@@ -2023,6 +2081,10 @@ qca8k_setup(struct dsa_switch *ds)
 	return 0;
 }
 
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+#include "qca8k-persistent-boot.inc"
+#endif
+
 static const struct phylink_mac_ops qca8k_phylink_mac_ops = {
 	.mac_select_pcs	= qca8k_phylink_mac_select_pcs,
 	.mac_config	= qca8k_phylink_mac_config,
@@ -2032,6 +2094,9 @@ static const struct phylink_mac_ops qca8k_phylink_mac_ops = {
 
 static const struct dsa_switch_ops qca8k_switch_ops = {
 	.get_tag_protocol	= qca8k_get_tag_protocol,
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	.teardown		= qca8k_persistent_dsa_teardown,
+#endif
 	.setup			= qca8k_setup,
 	.get_strings		= qca8k_get_strings,
 	.get_ethtool_stats	= qca8k_get_ethtool_stats,
@@ -2080,6 +2145,7 @@ qca8k_sw_probe(struct mdio_device *mdiodev)
 	if (!priv)
 		return -ENOMEM;
 
+	priv->private_tag_protocol = DSA_TAG_PROTO_QCA;
 	priv->bus = mdiodev->bus;
 	priv->dev = &mdiodev->dev;
 	priv->info = of_device_get_match_data(priv->dev);
@@ -2130,7 +2196,17 @@ qca8k_sw_probe(struct mdio_device *mdiodev)
 	mutex_init(&priv->reg_mutex);
 	dev_set_drvdata(&mdiodev->dev, priv);
 
-	return dsa_register_switch(priv->ds);
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	mutex_init(&priv->persistent_lock);
+	ret = qca8k_persistent_boot_admit(priv);
+	if (ret)
+		return ret;
+#endif
+	ret = dsa_register_switch(priv->ds);
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	qca8k_persistent_register_complete(priv, ret);
+#endif
+	return ret;
 }
 
 static void
@@ -2142,6 +2218,13 @@ qca8k_sw_remove(struct mdio_device *mdiodev)
 	if (!priv)
 		return;
 
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	if (priv->persistent_boot.requested) {
+		qca8k_persistent_remove(priv);
+		return;
+	}
+#endif
+
 	for (i = 0; i < QCA8K_NUM_PORTS; i++)
 		qca8k_port_set_status(priv, i, 0);
 
@@ -2155,6 +2238,14 @@ static void qca8k_sw_shutdown(struct mdio_device *mdiodev)
 	if (!priv)
 		return;
 
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	if (priv->persistent_boot.requested) {
+		qca8k_persistent_shutdown(priv);
+		dev_set_drvdata(&mdiodev->dev, NULL);
+		return;
+	}
+#endif
+
 	dsa_switch_shutdown(priv->ds);
 
 	dev_set_drvdata(&mdiodev->dev, NULL);
@@ -2181,6 +2272,11 @@ static int qca8k_suspend(struct device *dev)
 {
 	struct qca8k_priv *priv = dev_get_drvdata(dev);
 
+	if (IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE) &&
+	    (READ_ONCE(priv->private_open_blocked) ||
+	     priv->private_tag_protocol == DSA_TAG_PROTO_QCA4))
+		return -EBUSY;
+
 	qca8k_set_pm(priv, 0);
 
 	return dsa_switch_suspend(priv->ds);
@@ -2190,10 +2286,16 @@ static int qca8k_resume(struct device *dev)
 {
 	struct qca8k_priv *priv = dev_get_drvdata(dev);
 
+	if (IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE) &&
+	    (READ_ONCE(priv->private_open_blocked) ||
+	     priv->private_tag_protocol == DSA_TAG_PROTO_QCA4))
+		return -EBUSY;
+
 	qca8k_set_pm(priv, 1);
 
 	return dsa_switch_resume(priv->ds);
 }
+
 #endif /* CONFIG_PM_SLEEP */
 
 static SIMPLE_DEV_PM_OPS(qca8k_pm_ops,
@@ -2236,6 +2338,9 @@ static struct mdio_driver qca8kmdio_driver = {
 	.shutdown = qca8k_sw_shutdown,
 	.mdiodrv.driver = {
 		.name = "qca8k",
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+		.suppress_bind_attrs = true,
+#endif
 		.of_match_table = qca8k_of_match,
 		.pm = &qca8k_pm_ops,
 	},
diff --git a/drivers/net/dsa/qca/qca8k-common.c b/drivers/net/dsa/qca/qca8k-common.c
index ab978cc83..2f690593e 100644
--- a/drivers/net/dsa/qca/qca8k-common.c
+++ b/drivers/net/dsa/qca/qca8k-common.c
@@ -467,6 +467,15 @@ void qca8k_port_set_status(struct qca8k_priv *priv, int port, int enable)
 {
 	u32 mask = QCA8K_PORT_STATUS_TXMAC | QCA8K_PORT_STATUS_RXMAC;
 
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	if (qca8k_persistent_port_status(priv, port, enable))
+		return;
+#endif
+
+	if (enable && IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE) &&
+	    READ_ONCE(priv->private_open_blocked))
+		return;
+
 	/* Port 0 and 6 have no internal PHY */
 	if (port > 0 && port < 6)
 		mask |= QCA8K_PORT_STATUS_LINK_AUTO;
@@ -496,7 +505,8 @@ void qca8k_get_ethtool_stats(struct dsa_switch *ds, int port,
 	u32 hi = 0;
 	int ret;
 
-	if (priv->mgmt_conduit && priv->info->ops->autocast_mib &&
+	if (!qca8k_private_mgmt_blocked(priv) && priv->mgmt_conduit &&
+	    priv->info->ops->autocast_mib &&
 	    priv->info->ops->autocast_mib(ds, port, data) > 0)
 		return;
 
@@ -741,6 +751,31 @@ int qca8k_port_enable(struct dsa_switch *ds, int port,
 		      struct phy_device *phy)
 {
 	struct qca8k_priv *priv = ds->priv;
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	int ret;
+
+	if (READ_ONCE(priv->persistent_boot.requested) &&
+	    dsa_is_cpu_port(ds, port)) {
+		mutex_lock(&priv->persistent_lock);
+		if (!priv->persistent_boot.ready) {
+			priv->persistent_cpu_requested |= BIT(port);
+			priv->port_enabled_map |= BIT(port);
+			mutex_unlock(&priv->persistent_lock);
+			return 0;
+		}
+		mutex_unlock(&priv->persistent_lock);
+	}
+	if (dsa_is_user_port(ds, port)) {
+		ret = qca8k_persistent_first_user(priv);
+		if (ret)
+			return ret;
+	}
+
+#endif
+
+	if (IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE) &&
+	    READ_ONCE(priv->private_open_blocked))
+		return -EIO;
 
 	qca8k_port_set_status(priv, port, 1);
 	priv->port_enabled_map |= BIT(port);
@@ -764,6 +799,11 @@ int qca8k_port_change_mtu(struct dsa_switch *ds, int port, int new_mtu)
 	struct qca8k_priv *priv = ds->priv;
 	int ret;
 
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	if (READ_ONCE(priv->persistent_boot.requested))
+		return qca8k_persistent_change_mtu(priv, port, new_mtu);
+#endif
+
 	/* We have only have a general MTU setting.
 	 * DSA always set the CPU port's MTU to the largest MTU of the user
 	 * ports.
diff --git a/drivers/net/dsa/qca/qca8k-persistent-boot.inc b/drivers/net/dsa/qca/qca8k-persistent-boot.inc
new file mode 100644
index 000000000..88638bb53
--- /dev/null
+++ b/drivers/net/dsa/qca/qca8k-persistent-boot.inc
@@ -0,0 +1,632 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+#include <linux/cs7542_ft_live.h>
+#include <net/net_namespace.h>
+#define QCA4_PRIVATE_MAC_MASK \
+	(QCA8K_PORT_STATUS_TXMAC | QCA8K_PORT_STATUS_RXMAC)
+static void qca8k_private4_block_management(void *context)
+{
+	struct qca8k_priv *priv = context;
+
+	if (priv->private_management_drained)
+		return;
+	WRITE_ONCE(priv->private_mgmt_blocked, true);
+	mutex_lock(&priv->mib_eth_data.mutex);
+	mutex_lock_nested(&priv->bus->mdio_lock, MDIO_MUTEX_NESTED);
+	mutex_lock(&priv->mgmt_eth_data.mutex);
+	priv->mgmt_conduit = NULL;
+	mutex_unlock(&priv->mgmt_eth_data.mutex);
+	mutex_unlock(&priv->bus->mdio_lock);
+	mutex_unlock(&priv->mib_eth_data.mutex);
+	synchronize_net();
+	priv->private_management_drained = true;
+}
+
+static void qca8k_private4_close_links(struct qca8k_priv *priv)
+{
+	struct dsa_port *dp;
+
+	ASSERT_RTNL();
+	dsa_switch_for_each_user_port(dp, priv->ds)
+		if (dp->user && dp->user->flags & IFF_UP)
+			dev_close(dp->user);
+	dsa_switch_for_each_cpu_port(dp, priv->ds)
+		if (dp->conduit && dp->conduit->flags & IFF_UP)
+			dev_close(dp->conduit);
+	synchronize_net();
+}
+
+/* SPDX-License-Identifier: GPL-2.0 */
+/* Private opt-in boot adapter; default profile remains native QCA2. */
+#include <linux/dsa/qca8k_persistent.h>
+static int qca8k_persistent_software_ready(struct qca8k_priv *priv,
+					   bool bootstrap)
+{
+	struct dsa_switch *ds = priv->ds;
+	struct dsa_port *cpu, *user;
+	unsigned int needed_mtu = ETH_DATA_LEN;
+	unsigned int cpu_mask = 0;
+
+	ASSERT_RTNL();
+	if (!ds->dst->setup || !ds->dst->tag_ops ||
+	    ds->dst->tag_ops->proto != DSA_TAG_PROTO_QCA4)
+		return -EAGAIN;
+	dsa_switch_for_each_user_port(user, ds) {
+		if (!user->user)
+			return -ENODEV;
+		if (!bootstrap)
+			needed_mtu = max_t(unsigned int, needed_mtu,
+					   user->user->mtu);
+	}
+	dsa_switch_for_each_cpu_port(cpu, ds) {
+		if (cpu->index != 0 && cpu->index != 6)
+			return -EOPNOTSUPP;
+		cpu_mask |= BIT(cpu->index);
+		if (!cpu->conduit || cpu->conduit->dsa_ptr != cpu ||
+		    !cpu->tag_ops ||
+		    cpu->tag_ops->proto != DSA_TAG_PROTO_QCA4 ||
+		    cpu->rcv != cpu->tag_ops->rcv)
+			return -EUCLEAN;
+		/*
+		 * dsa_conduit_setup() can swallow dev_set_mtu() failure. Check
+		 * the actual effective MTU on BOTH configured conduits instead.
+		 */
+		if (cpu->conduit->mtu < needed_mtu +
+						cpu->tag_ops->needed_headroom +
+						cpu->tag_ops->needed_tailroom)
+			return -EMSGSIZE;
+	}
+	return cpu_mask == (BIT(0) | BIT(6)) ? 0 : -ENODEV;
+}
+
+/*
+ * Replay only CPU enables recorded during setup, never arbitrary user MACs.
+ * A failed replay closes the format again; its first errno remains sticky.
+ */
+static int qca8k_persistent_replay_cpus(struct qca8k_priv *priv)
+{
+	unsigned int port;
+	u32 actual;
+	u32 mask = QCA8K_PORT_STATUS_SPEED | QCA4_PRIVATE_MAC_MASK |
+		   QCA8K_PORT_STATUS_TXFLOW | QCA8K_PORT_STATUS_RXFLOW |
+		   QCA8K_PORT_STATUS_DUPLEX | QCA8K_PORT_STATUS_LINK_AUTO;
+	int ret;
+
+	if (priv->persistent_status_valid != (BIT(0) | BIT(6)))
+		return -EAGAIN;
+
+	for (port = 0; port <= 6; port += 6) {
+		u32 wanted = priv->persistent_status[port == 6];
+
+		if (!(priv->persistent_cpu_requested & BIT(port)))
+			wanted &= ~QCA4_PRIVATE_MAC_MASK;
+
+		ret = qca8k_rmw(priv, QCA8K_REG_PORT_STATUS(port), mask,
+				wanted);
+		if (ret)
+			return ret;
+		ret = qca8k_read_mii(priv, QCA8K_REG_PORT_STATUS(port),
+				     &actual);
+		if (ret)
+			return ret;
+		if ((actual & mask) != (wanted & mask))
+			return -EIO;
+	}
+	return 0;
+}
+
+static int qca8k_persistent_stop_cpus(struct qca8k_priv *priv)
+{
+	unsigned int port;
+	u32 actual;
+	int first = 0, ret;
+
+	for (port = 0; port <= 6; port += 6) {
+		ret = qca8k_rmw(priv, QCA8K_REG_PORT_STATUS(port),
+				QCA4_PRIVATE_MAC_MASK, 0);
+		if (ret && !first)
+			first = ret;
+		ret = qca8k_read_mii(priv, QCA8K_REG_PORT_STATUS(port),
+				     &actual);
+		if (!ret && (actual & QCA4_PRIVATE_MAC_MASK))
+			ret = -EIO;
+		if (ret && !first)
+			first = ret;
+	}
+	return first;
+}
+
+static int qca8k_persistent_mtu_read(void *context,
+				     enum qca4_persistent_mtu_field field,
+				     qca4_word *value)
+{
+	struct qca8k_priv *priv = context;
+	unsigned int port =
+		field == QCA4_PMTU_CONDUIT6 || field == QCA4_PMTU_MAC6 ? 6 : 0;
+	struct dsa_port *cpu = dsa_to_port(priv->ds, port);
+	u32 reg;
+	int ret;
+
+	if (field <= QCA4_PMTU_CONDUIT6) {
+		if (!cpu || !cpu->conduit)
+			return -ENODEV;
+		*value = cpu->conduit->mtu;
+		return 0;
+	}
+	reg = field == QCA4_PMTU_FRAME ? QCA8K_MAX_FRAME_SIZE :
+					 QCA8K_REG_PORT_STATUS(port);
+	ret = qca8k_read_mii(priv, reg, value);
+	if (!ret && field >= QCA4_PMTU_MAC0)
+		*value &= QCA4_PRIVATE_MAC_MASK;
+	return ret;
+}
+
+static int qca8k_persistent_mtu_write(void *context,
+				      enum qca4_persistent_mtu_field field,
+				      qca4_word value, bool restore,
+				      bool *verified)
+{
+	struct qca8k_priv *priv = context;
+	unsigned int port =
+		field == QCA4_PMTU_CONDUIT6 || field == QCA4_PMTU_MAC6 ? 6 : 0;
+	struct dsa_port *cpu = dsa_to_port(priv->ds, port);
+	u32 actual = 0, mask, reg;
+	int ret, checked;
+
+	ASSERT_RTNL();
+	lockdep_assert_held(&priv->persistent_lock);
+	(void)restore; /* Persistent operations use native bounded MDIO in both directions. */
+	*verified = false;
+	if (!priv->private_mgmt_blocked)
+		return -EPERM;
+	if (field <= QCA4_PMTU_CONDUIT6) {
+		if (!cpu || !cpu->conduit)
+			return -ENODEV;
+		/*
+		 * Correct netdevice API, including actual notifier/MTU limits. No
+		 * phylink stop occurs here. Callbacks share persistent_lock.
+		 */
+		ret = dev_set_mtu(cpu->conduit, value);
+		*verified = cpu->conduit->mtu == value;
+		return ret ? ret : *verified ? 0 : -EIO;
+	}
+	reg = field == QCA4_PMTU_FRAME ? QCA8K_MAX_FRAME_SIZE :
+					 QCA8K_REG_PORT_STATUS(port);
+	mask = field == QCA4_PMTU_FRAME ? ~0U : QCA4_PRIVATE_MAC_MASK;
+	/*
+	 * Persistent operation has no fabricated bounded-owner deadline. The
+	 * native MDIO driver bounds each actual low/high bus transaction.
+	 * Rollback uses the same checked owner, preserving the original errno.
+	 */
+	ret = qca8k_rmw(priv, reg, mask, value);
+	checked = qca8k_read_mii(priv, reg, &actual);
+	*verified = !checked && !((actual ^ value) & mask);
+	return ret ? ret : checked ? checked : *verified ? 0 : -EIO;
+}
+
+static struct qca4_persistent_mtu_ops
+qca8k_persistent_mtu_ops(struct qca8k_priv *priv)
+{
+	return (struct qca4_persistent_mtu_ops){
+		.context = priv,
+		.read = qca8k_persistent_mtu_read,
+		.write = qca8k_persistent_mtu_write,
+	};
+}
+
+/*
+ * Core has already changed one conduit before its CPU callback. Apply the
+ * passed aggregate there, then independently validate the user callback using
+ * its proposed MTU. A repeated already-verified pair is idempotent. Setup can
+ * ignore CPU callback errors: first-open readiness remains the traffic gate.
+ */
+static int qca8k_persistent_change_mtu_locked(struct qca8k_priv *priv, int port,
+					      int mtu)
+{
+	struct qca4_persistent_mtu_ops ops = qca8k_persistent_mtu_ops(priv);
+	struct dsa_port *user;
+	unsigned int largest = ETH_DATA_LEN;
+	bool blocked;
+	int ret = 0;
+
+	ASSERT_RTNL();
+	if (!dsa_is_user_port(priv->ds, port) &&
+	    !dsa_is_cpu_port(priv->ds, port))
+		return -EOPNOTSUPP;
+	if (mtu <= 0 || mtu > QCA8K_MAX_MTU)
+		return -EINVAL;
+	lockdep_assert_held(&priv->persistent_lock);
+	if (priv->persistent_closing || priv->persistent_boot.first_error ||
+	    priv->persistent_mtu.pending || priv->persistent_mtu.unknown) {
+		ret = -EUCLEAN;
+		goto unlock;
+	}
+	/*
+	 * Early DSA allocation has not yet published both conduits. First-open
+	 * readiness performs the initial checked transaction before MAC replay.
+	 */
+	if (!priv->persistent_boot.ready)
+		goto unlock;
+	if (dsa_is_cpu_port(priv->ds, port)) {
+		largest = max_t(unsigned int, largest, mtu);
+	} else {
+		dsa_switch_for_each_user_port(user, priv->ds) {
+			if (user->user)
+				largest = max_t(unsigned int, largest,
+					user->index == (unsigned int)port ?
+						(unsigned int)mtu :
+						user->user->mtu);
+		}
+	}
+	if (priv->persistent_mtu.committed_valid &&
+	    priv->persistent_mtu.committed_mtu[0] == largest + 4 &&
+	    priv->persistent_mtu.committed_mtu[1] == largest + 4 &&
+	    priv->persistent_mtu.committed_frame ==
+		    largest + ETH_HLEN + ETH_FCS_LEN &&
+	    dsa_to_port(priv->ds, 0)->conduit->mtu == largest + 4 &&
+	    dsa_to_port(priv->ds, 6)->conduit->mtu == largest + 4)
+		goto unlock;
+	blocked = priv->private_open_blocked;
+	priv->private_open_blocked = true;
+	ret = qca4_pmtu_change(&priv->persistent_mtu, &ops, largest + 4,
+			       largest + ETH_HLEN + ETH_FCS_LEN);
+	if (ret) {
+		qca4_persistent_error(&priv->persistent_boot, ret);
+		priv->persistent_boot.ready = false;
+		if (qca8k_persistent_stop_cpus(priv))
+			priv->persistent_boot.unknown = true;
+	} else {
+		priv->private_open_blocked = blocked;
+	}
+unlock:
+	return ret;
+}
+
+int qca8k_persistent_change_mtu(struct qca8k_priv *priv, int port, int mtu)
+{
+	int ret;
+
+	ASSERT_RTNL();
+	mutex_lock(&priv->persistent_lock);
+	ret = qca8k_persistent_change_mtu_locked(priv, port, mtu);
+	mutex_unlock(&priv->persistent_lock);
+	return ret;
+}
+
+static int qca8k_persistent_first_user_locked(struct qca8k_priv *priv)
+{
+	unsigned int port;
+	u32 value;
+	int ret;
+
+	if (!priv->persistent_boot.requested)
+		return 0;
+	ASSERT_RTNL();
+	if (priv->persistent_closing || !priv->persistent_boot.hardware4 ||
+	    priv->persistent_boot.unknown || priv->persistent_boot.first_error)
+		return -EIO;
+	ret = qca8k_persistent_software_ready(priv, !priv->persistent_mtu.committed_valid);
+	/*
+	 * A netdev can be published before the complete DSA tree. This is a
+	 * pre-I/O readiness refusal, not an I/O fault or a permanent latch.
+	 */
+	if (ret == -EAGAIN)
+		return ret;
+	if (ret)
+		goto failed;
+	if (priv->persistent_status_valid != (BIT(0) | BIT(6)))
+		return -EAGAIN;
+	ret = qca8k_read_mii(priv, QCA8K_REG_GLOBAL_HDR_CTRL, &value);
+	if (!ret && (value & QCA4_PERSISTENT_MASK) != QCA4_PERSISTENT_VALUE)
+		ret = -EUCLEAN;
+	for (port = 0; !ret && port <= 6; port += 6) {
+		ret = qca8k_read_mii(priv, QCA8K_REG_PORT_HDR_CTRL(port),
+				     &value);
+		if (!ret && value != QCA4_PERSISTENT_CPU_HEADER)
+			ret = -EUCLEAN;
+	}
+	if (!ret && !priv->persistent_mtu.committed_valid) {
+		struct qca4_persistent_mtu_ops ops =
+			qca8k_persistent_mtu_ops(priv);
+		struct dsa_port *user;
+		unsigned int largest = ETH_DATA_LEN;
+
+		dsa_switch_for_each_user_port(user, priv->ds)
+			if (user->user)
+				largest = max_t(unsigned int, largest,
+						user->user->mtu);
+		ret = qca4_pmtu_change(&priv->persistent_mtu, &ops, largest + 4,
+				       largest + ETH_HLEN + ETH_FCS_LEN);
+	}
+	if (!ret)
+		ret = qca8k_persistent_software_ready(priv, false);
+	if (!ret)
+		ret = qca8k_persistent_replay_cpus(priv);
+	if (ret)
+		goto failed;
+	if (priv->persistent_fe_held) {
+		ret = cs7542_ft_live_format_release();
+		if (ret)
+			goto failed;
+		priv->persistent_fe_held = false;
+	}
+	priv->persistent_boot.ready = true;
+	WRITE_ONCE(priv->private_open_blocked, false);
+	return 0;
+failed:
+	WRITE_ONCE(priv->private_open_blocked, true);
+	priv->persistent_boot.ready = false;
+	qca4_persistent_error(&priv->persistent_boot, ret);
+	if (qca8k_persistent_stop_cpus(priv))
+		priv->persistent_boot.unknown = true;
+	/* No detach or mode clear here. Incomplete boot admission is closed. */
+	return ret;
+}
+
+/*
+ * Lock order: RTNL (when present), phylink's own state locks (when present),
+ * persistent_lock, native MDIO. Never call phylink_stop/dev_close while holding
+ * persistent_lock: those paths wait for resolve work that takes this mutex.
+ */
+int qca8k_persistent_first_user(struct qca8k_priv *priv)
+{
+	int ret;
+
+	if (!READ_ONCE(priv->persistent_boot.requested))
+		return 0;
+	mutex_lock(&priv->persistent_lock);
+	ret = qca8k_persistent_first_user_locked(priv);
+	mutex_unlock(&priv->persistent_lock);
+	return ret;
+}
+
+bool qca8k_persistent_link_up(struct qca8k_priv *priv, int port, u32 status)
+{
+	int ret;
+	u32 actual;
+	u32 mask = QCA8K_PORT_STATUS_SPEED | QCA4_PRIVATE_MAC_MASK |
+		   QCA8K_PORT_STATUS_TXFLOW | QCA8K_PORT_STATUS_RXFLOW |
+		   QCA8K_PORT_STATUS_DUPLEX | QCA8K_PORT_STATUS_LINK_AUTO;
+
+	if (!READ_ONCE(priv->persistent_boot.requested))
+		return false;
+	mutex_lock(&priv->persistent_lock);
+	if (port == 0 || port == 6) {
+		priv->persistent_status[port == 6] = status;
+		priv->persistent_status_valid |= BIT(port);
+		priv->persistent_cpu_requested |= BIT(port);
+	}
+	if (!priv->private_open_blocked) {
+		ret = qca8k_write(priv, QCA8K_REG_PORT_STATUS(port), status);
+		if (!ret)
+			ret = qca8k_read_mii(priv, QCA8K_REG_PORT_STATUS(port),
+					     &actual);
+		if (!ret && ((actual ^ status) & mask))
+			ret = -EIO;
+		if (ret) {
+			priv->private_open_blocked = true;
+			priv->persistent_boot.ready = false;
+			qca4_persistent_error(&priv->persistent_boot, ret);
+			if (qca8k_persistent_stop_cpus(priv))
+				priv->persistent_boot.unknown = true;
+		}
+	}
+	mutex_unlock(&priv->persistent_lock);
+	return true;
+}
+
+bool qca8k_persistent_port_status(struct qca8k_priv *priv, int port,
+				  bool enable)
+{
+	u32 mask = QCA4_PRIVATE_MAC_MASK, verify_mask, actual;
+	int ret;
+
+	if (!READ_ONCE(priv->persistent_boot.requested))
+		return false;
+	mutex_lock(&priv->persistent_lock);
+	if (port == 0 || port == 6) {
+		if (enable)
+			priv->persistent_cpu_requested |= BIT(port);
+		else
+			priv->persistent_cpu_requested &= ~BIT(port);
+	} else {
+		mask |= QCA8K_PORT_STATUS_LINK_AUTO;
+	}
+	if (enable && priv->private_open_blocked)
+		goto unlock;
+	/*
+	 * With user-port auto negotiation, hardware can keep the MAC bits
+	 * clear until link-up. Check the requested auto mode here; the actual
+	 * phylink link-up callback still verifies the complete MAC status.
+	 * Disables and both CPU ports retain the exact MAC-bit check.
+	 */
+	verify_mask = enable && port > 0 && port < 6 ?
+			      QCA8K_PORT_STATUS_LINK_AUTO :
+			      mask;
+	ret = qca8k_rmw(priv, QCA8K_REG_PORT_STATUS(port), mask,
+			enable ? mask : 0);
+	if (!ret)
+		ret = qca8k_read_mii(priv, QCA8K_REG_PORT_STATUS(port),
+				     &actual);
+	if (!ret && (actual & verify_mask) != (enable ? verify_mask : 0))
+		ret = -EIO;
+	if (ret) {
+		priv->private_open_blocked = true;
+		priv->persistent_boot.ready = false;
+		qca4_persistent_error(&priv->persistent_boot, ret);
+		if (qca8k_persistent_stop_cpus(priv))
+			priv->persistent_boot.unknown = true;
+	}
+unlock:
+	mutex_unlock(&priv->persistent_lock);
+	return true;
+}
+
+/*
+ * int-returning preparation only. It is NOT a void MDIO remove veto. The
+ * boot property remains inadmissible until unknown cleanup can prevent driver
+ * core devres release in every reachable detach/unwind path.
+ */
+static int qca8k_persistent_stop_all(struct qca8k_priv *priv,
+				     bool *verified_all)
+{
+	unsigned int port;
+	u32 actual, mask;
+	int ret, checked, first = 0;
+
+	*verified_all = true;
+	for (port = 0; port < QCA8K_NUM_PORTS; port++) {
+		mask = QCA4_PRIVATE_MAC_MASK;
+		if (port > 0 && port < 6)
+			mask |= QCA8K_PORT_STATUS_LINK_AUTO;
+		ret = qca8k_rmw(priv, QCA8K_REG_PORT_STATUS(port), mask, 0);
+		checked = qca8k_read_mii(priv, QCA8K_REG_PORT_STATUS(port),
+					 &actual);
+		if (checked || (actual & mask))
+			*verified_all = false;
+		if (!ret)
+			ret = checked ? checked : (actual & mask) ? -EIO : 0;
+		if (ret && !first)
+			first = ret;
+	}
+	return first;
+}
+
+static int qca8k_persistent_restore_global(struct qca8k_priv *priv)
+{
+	u32 before, actual, expected;
+	int ret, checked;
+
+	if (!priv->persistent_boot.saved_valid)
+		return -EUCLEAN;
+	ret = qca8k_read_mii(priv, QCA8K_REG_GLOBAL_HDR_CTRL, &before);
+	if (ret)
+		return ret;
+	expected = (before & ~QCA4_PERSISTENT_MASK) |
+		   (priv->persistent_boot.saved_header & QCA4_PERSISTENT_MASK);
+	ret = qca8k_rmw(priv, QCA8K_REG_GLOBAL_HDR_CTRL, QCA4_PERSISTENT_MASK,
+			expected);
+	checked = qca8k_read_mii(priv, QCA8K_REG_GLOBAL_HDR_CTRL, &actual);
+	priv->persistent_native2_verified = !checked && actual == expected &&
+					    !(actual & BIT(16));
+	if (priv->persistent_native2_verified) {
+		priv->persistent_boot.restore_pending = false;
+		priv->persistent_boot.hardware4 = false;
+	}
+	return ret				 ? ret :
+	       checked				 ? checked :
+	       priv->persistent_native2_verified ? 0 :
+						   -EIO;
+}
+
+static bool qca8k_persistent_can_release(struct qca8k_priv *priv)
+{
+	lockdep_assert_held(&priv->persistent_lock);
+	return priv->persistent_closing && priv->persistent_fe_held &&
+	       priv->private_open_blocked &&
+	       priv->persistent_stopped_verified &&
+	       priv->persistent_native2_verified &&
+	       !priv->persistent_boot.hardware4 &&
+	       !priv->persistent_boot.restore_pending &&
+	       !priv->persistent_boot.unknown &&
+	       !priv->persistent_mtu.pending && !priv->persistent_mtu.unknown;
+}
+
+static int __maybe_unused
+qca8k_persistent_prepare_detach(struct qca8k_priv *priv)
+{
+	struct qca4_persistent_mtu_ops ops = qca8k_persistent_mtu_ops(priv);
+	int ret, first = 0;
+
+	ASSERT_RTNL();
+	if (!priv->persistent_boot.requested)
+		return 0;
+	if (priv->persistent_cleanup_attempted)
+		return priv->persistent_cleanup_result;
+	priv->persistent_cleanup_attempted = true;
+	mutex_lock(&priv->persistent_lock);
+	priv->persistent_closing = true;
+	priv->private_open_blocked = true;
+	priv->persistent_boot.ready = false;
+	mutex_unlock(&priv->persistent_lock);
+	priv->persistent_fe_held = false;
+	ret = priv->persistent_hold_error ? priv->persistent_hold_error :
+					    cs7542_ft_live_format_hold();
+	if (ret)
+		first = ret;
+	else
+		priv->persistent_fe_held = true;
+	/*
+	 * No persistent_lock: dev_close/phylink_stop can join callbacks that
+	 * take it. Future callbacks remain unable to enable any MAC.
+	 */
+	qca8k_private4_close_links(priv);
+	qca8k_private4_block_management(priv);
+	mutex_lock(&priv->persistent_lock);
+	ret = qca8k_persistent_stop_all(priv,
+					&priv->persistent_stopped_verified);
+	if (ret && !first)
+		first = ret;
+	if (!priv->persistent_stopped_verified || !priv->persistent_fe_held)
+		goto unknown;
+	ret = qca4_pmtu_restore(&priv->persistent_mtu, &ops);
+	if (ret && !first)
+		first = ret;
+	if (priv->persistent_mtu.pending || priv->persistent_mtu.unknown)
+		goto unknown;
+	/*
+	 * MTU rollback may restore prior CPU enables; close/verify them again
+	 * before changing the global format or authorizing detach.
+	 */
+	ret = qca8k_persistent_stop_all(priv,
+					&priv->persistent_stopped_verified);
+	if (ret && !first)
+		first = ret;
+	if (!priv->persistent_stopped_verified)
+		goto unknown;
+	ret = qca8k_persistent_restore_global(priv);
+	if (ret && !first)
+		first = ret;
+	if (!priv->persistent_native2_verified)
+		goto unknown;
+	priv->persistent_boot.unknown = false;
+	if (qca8k_persistent_can_release(priv))
+		priv->private_tag_protocol = DSA_TAG_PROTO_QCA;
+	qca4_persistent_error(&priv->persistent_boot, first);
+	priv->persistent_cleanup_result = first;
+	mutex_unlock(&priv->persistent_lock);
+	return first; /* first I/O error and proved-release eligibility differ */
+unknown:
+	priv->persistent_boot.unknown = true;
+	qca4_persistent_error(&priv->persistent_boot, first ? first : -EIO);
+	priv->persistent_cleanup_result = first ? first : -EIO;
+	mutex_unlock(&priv->persistent_lock);
+	return priv->persistent_cleanup_result;
+}
+
+/*
+ * Only AFTER actual DSA teardown has drained/detached its callbacks. An I/O
+ * error in the history is still reported, but is not itself fabricated current
+ * uncertainty after independent complete readback proved restoration.
+ */
+static int __maybe_unused
+qca8k_persistent_detach_complete(struct qca8k_priv *priv)
+{
+	int ret;
+
+	ASSERT_RTNL();
+	mutex_lock(&priv->persistent_lock);
+	if (!qca8k_persistent_can_release(priv) || priv->ds->setup) {
+		mutex_unlock(&priv->persistent_lock);
+		return -EBUSY;
+	}
+	priv->private_tag_protocol = DSA_TAG_PROTO_QCA;
+	mutex_unlock(&priv->persistent_lock);
+	ret = cs7542_ft_live_format_release();
+	mutex_lock(&priv->persistent_lock);
+	if (!ret)
+		priv->persistent_fe_held = false;
+	mutex_unlock(&priv->persistent_lock);
+	return ret;
+}
+
+#include "qca8k-persistent-lifecycle.inc"
diff --git a/drivers/net/dsa/qca/qca8k-persistent-lifecycle.inc b/drivers/net/dsa/qca/qca8k-persistent-lifecycle.inc
new file mode 100644
index 000000000..bd7892b80
--- /dev/null
+++ b/drivers/net/dsa/qca/qca8k-persistent-lifecycle.inc
@@ -0,0 +1,394 @@
+/* SPDX-License-Identifier: GPL-2.0 */
+/*
+ * Private boot profile. All lifecycle entry points below execute under RTNL;
+ * the fault is only a scalar. No retired QCA/DSA pointer survives in FE hold.
+ */
+static int qca8k_persistent_last_fault;
+static u64 qca8k_persistent_generation;
+
+static int qca8k_persistent_profile(struct qca8k_priv *priv)
+{
+	struct dsa_port *cpu, *user;
+	struct net_device *conduits[2] = {};
+	unsigned int cpu_mask = 0, user_mask = 0;
+	phy_interface_t mode;
+	u32 reg;
+
+	ASSERT_RTNL();
+	if (priv->switch_id != QCA8K_ID_QCA8337 || !priv->ds->dst ||
+	    !priv->ds->dst->tag_ops ||
+	    priv->ds->dst->tag_ops->proto != DSA_TAG_PROTO_QCA4)
+		return -EOPNOTSUPP;
+	dsa_switch_for_each_cpu_port(cpu, priv->ds) {
+		struct device *parent;
+		unsigned int index = cpu->index == 6;
+
+		if ((cpu->index != 0 && cpu->index != 6) || !cpu->conduit ||
+		    !cpu->dn || !of_phy_is_fixed_link(cpu->dn) ||
+		    of_get_phy_mode(cpu->dn, &mode) ||
+		    !phy_interface_mode_is_rgmii(mode))
+			return -EOPNOTSUPP;
+		if (dev_net(cpu->conduit) != &init_net ||
+		    cpu->conduit->flags & IFF_UP)
+			return -EBUSY;
+		/*
+		 * The netdev's direct OF node is ethernet-port@N. Its device
+		 * parent is the shared NE and cannot identify GMAC0 versus GMAC1.
+		 */
+		if (of_property_read_u32(dev_of_node(&cpu->conduit->dev), "reg",
+					 &reg) ||
+		    reg != (cpu->index == 0 ? 1 : 0))
+			return -ENODEV;
+		parent = cpu->conduit->dev.parent;
+		if (!parent || !parent->driver || parent->driver->owner ||
+		    !of_device_is_compatible(dev_of_node(parent),
+					     "cortina,cs7542-ethernet"))
+			return -EOPNOTSUPP;
+		conduits[index] = cpu->conduit;
+		cpu_mask |= BIT(cpu->index);
+	}
+	dsa_switch_for_each_user_port(user, priv->ds) {
+		if (user->index < 1 || user->index > 5)
+			return -EOPNOTSUPP;
+		user_mask |= BIT(user->index);
+	}
+	if (cpu_mask != 0x41 || user_mask != 0x3e ||
+	    conduits[0] == conduits[1] ||
+	    conduits[0]->dev.parent != conduits[1]->dev.parent)
+		return -EOPNOTSUPP;
+	return 0;
+}
+
+static void qca8k_persistent_note_fault(struct qca8k_priv *priv, int error)
+{
+	ASSERT_RTNL();
+	if (!qca8k_persistent_last_fault)
+		qca8k_persistent_last_fault = error ? error : -EIO;
+	dev_err(priv->dev,
+		"persistent4 held fault=%d native2=%u stopped=%u; no reopen or cleanup success\n",
+		qca8k_persistent_last_fault, priv->persistent_native2_verified,
+		priv->persistent_stopped_verified);
+}
+
+static int qca8k_persistent_boot_start(struct qca8k_priv *priv)
+{
+	u32 global;
+	int ret;
+
+	ASSERT_RTNL();
+	ret = qca8k_persistent_profile(priv);
+	if (ret)
+		return ret; /* No actor closure or hardware I/O on failed admission. */
+	priv->persistent_setup_started = true;
+	ret = cs7542_ft_live_format_hold();
+	if (ret) {
+		priv->persistent_hold_error = ret;
+		return ret;
+	} /* format_blocked remains set, even on detach failure. */
+	priv->persistent_fe_held = true;
+	qca8k_private4_block_management(priv);
+	mutex_lock(&priv->persistent_lock);
+	ret = qca8k_persistent_stop_all(priv,
+					&priv->persistent_stopped_verified);
+	if (ret || !priv->persistent_stopped_verified)
+		goto unlock;
+	ret = qca8k_read_mii(priv, QCA8K_REG_GLOBAL_HDR_CTRL, &global);
+	if (ret)
+		goto unlock;
+	/* Recovery baseline is native2, not firmware's possibly retained4. */
+	priv->persistent_boot.saved_header = (global & QCA4_PERSISTENT_MASK) &
+					     ~BIT(16);
+	priv->persistent_boot.saved_valid = true;
+	priv->persistent_boot.restore_pending = true;
+	ret = qca8k_persistent_restore_global(priv);
+	if (!ret && priv->persistent_native2_verified)
+		qca8k_persistent_last_fault =
+			0; /* Actual proved native2 recovery. */
+unlock:
+	mutex_unlock(&priv->persistent_lock);
+	return ret ? ret : priv->persistent_stopped_verified ? 0 : -EIO;
+}
+
+static int qca8k_persistent_boot_hardware4(struct qca8k_priv *priv)
+{
+	u32 before, actual, expected, header;
+	unsigned int port;
+	int ret, checked;
+
+	ASSERT_RTNL();
+	ret = qca8k_persistent_profile(priv);
+	if (ret)
+		return ret;
+	mutex_lock(&priv->persistent_lock);
+	ret = qca8k_persistent_stop_all(priv,
+					&priv->persistent_stopped_verified);
+	if (ret || !priv->persistent_stopped_verified)
+		goto unlock;
+	for (port = 0; port <= 6; port += 6) {
+		ret = qca8k_read_mii(priv, QCA8K_REG_PORT_HDR_CTRL(port),
+				     &header);
+		if (!ret && header != QCA4_PERSISTENT_CPU_HEADER)
+			ret = -EUCLEAN;
+		if (ret)
+			goto unlock;
+	}
+	ret = qca8k_read_mii(priv, QCA8K_REG_GLOBAL_HDR_CTRL, &before);
+	if (ret)
+		goto unlock;
+	if (before & BIT(16)) {
+		ret = -EUCLEAN;
+		goto unlock;
+	}
+	if (qca8k_persistent_generation == ~0ULL) {
+		ret = -EOVERFLOW;
+		goto unlock;
+	}
+	priv->persistent_epoch = ++qca8k_persistent_generation;
+	expected = (before & ~QCA4_PERSISTENT_MASK) | QCA4_PERSISTENT_VALUE;
+	priv->persistent_boot.restore_pending =
+		true; /* Before either data word. */
+	priv->persistent_native2_verified = false;
+	ret = qca8k_rmw(priv, QCA8K_REG_GLOBAL_HDR_CTRL, QCA4_PERSISTENT_MASK,
+			expected);
+	checked = qca8k_read_mii(priv, QCA8K_REG_GLOBAL_HDR_CTRL, &actual);
+	priv->persistent_boot.hardware4 = !checked && actual == expected;
+	if (!ret)
+		ret = checked			      ? checked :
+		      priv->persistent_boot.hardware4 ? 0 :
+							-EIO;
+	priv->persistent_boot.unknown = !priv->persistent_boot.hardware4;
+unlock:
+	mutex_unlock(&priv->persistent_lock);
+	return ret ? ret : priv->persistent_stopped_verified ? 0 : -EIO;
+}
+
+/*
+ * Called while parsed ports still exist: in setup wrapper, internal DSA
+ * teardown, or before normal unregister. Standard software teardown always
+ * follows, even after uncertain hardware cleanup; QCA owns no host DMA memory.
+ */
+static void qca8k_persistent_unwind(struct qca8k_priv *priv, int cause)
+{
+	int error;
+	bool release;
+
+	ASSERT_RTNL();
+	mutex_lock(&priv->persistent_lock);
+	if (cause)
+		qca4_persistent_error(&priv->persistent_boot, cause);
+	mutex_unlock(&priv->persistent_lock);
+	if (!priv->persistent_setup_started)
+		return;
+	error = qca8k_persistent_prepare_detach(priv);
+	mutex_lock(&priv->persistent_lock);
+	release = qca8k_persistent_can_release(priv);
+	mutex_unlock(&priv->persistent_lock);
+	if (!release)
+		qca8k_persistent_note_fault(priv, error ? error : cause);
+}
+
+static int qca8k_setup(struct dsa_switch *ds)
+{
+	struct qca8k_priv *priv = ds->priv;
+	int ret;
+
+	if (!priv->persistent_boot.requested)
+		return qca8k_setup_native(ds);
+	rtnl_lock();
+	ret = qca8k_persistent_boot_start(priv);
+	rtnl_unlock();
+	if (!ret)
+		ret = qca8k_setup_native(ds);
+	if (!ret) {
+		rtnl_lock();
+		ret = qca8k_persistent_boot_hardware4(priv);
+		rtnl_unlock();
+	}
+	if (ret) {
+		rtnl_lock();
+		qca8k_persistent_unwind(priv, ret);
+		rtnl_unlock();
+	}
+	return ret;
+}
+
+static void qca8k_persistent_dsa_teardown(struct dsa_switch *ds)
+{
+	struct qca8k_priv *priv = ds->priv;
+
+	if (!priv->persistent_boot.requested) {
+		return;
+	}
+	/*
+	 * DSA invokes this outside RTNL, including its internal setup failure.
+	 * Never route persistent4 through the timed watchdog-wait invariant.
+	 */
+	rtnl_lock();
+	qca8k_persistent_unwind(priv, 0);
+	rtnl_unlock();
+}
+
+static void qca8k_persistent_register_complete(struct qca8k_priv *priv,
+					       int error)
+{
+	int completed;
+
+	if (!priv->persistent_boot.requested || !error ||
+	    !priv->persistent_setup_started)
+		return;
+	/*
+	 * Ports/dst may have been released by core now. No port dereference:
+	 * hardware cleanup ran while parsed ports were alive in setup/teardown.
+	 */
+	rtnl_lock();
+	completed = qca8k_persistent_detach_complete(priv);
+	if (completed)
+		qca8k_persistent_note_fault(priv, completed);
+	rtnl_unlock();
+}
+
+static void qca8k_persistent_remove(struct qca8k_priv *priv)
+{
+	int completed;
+
+	rtnl_lock();
+	qca8k_persistent_unwind(priv, 0);
+	rtnl_unlock();
+	dsa_unregister_switch(priv->ds);
+	rtnl_lock();
+	completed = qca8k_persistent_detach_complete(priv);
+	if (completed)
+		qca8k_persistent_note_fault(priv, completed);
+	rtnl_unlock();
+}
+
+static void qca8k_persistent_shutdown(struct qca8k_priv *priv)
+{
+	/*
+	 * Driver core drains dev_groups before remove, but not shutdown. Do it
+	 * before drvdata is cleared by the outer shutdown callback.
+	 */
+	rtnl_lock();
+	qca8k_persistent_unwind(priv, 0);
+	rtnl_unlock();
+	dsa_switch_shutdown(priv->ds);
+	/*
+	 * shutdown is NOT unregister: keep FE held through restart, no claim
+	 * that taggers/work/contexts have been destroyed or resources released.
+	 */
+}
+
+/*
+ * DSA parses this same CPU-port property when choosing its tagger. Select
+ * the hardware format before get_tag_protocol(), rather than changing the
+ * running tree through a private sysfs API. All CPU ports must agree.
+ */
+static int qca8k_persistent_boot_admit(struct qca8k_priv *priv)
+{
+	struct device_node *ports;
+	unsigned int cpus = 0, selected = 0;
+	const char *protocol;
+
+	ports = of_get_child_by_name(priv->dev->of_node, "ports");
+	if (!ports)
+		ports = of_get_child_by_name(priv->dev->of_node,
+					     "ethernet-ports");
+	if (!ports)
+		return 0;
+	for_each_available_child_of_node_scoped(ports, port) {
+		if (!of_property_present(port, "ethernet"))
+			continue;
+		cpus++;
+		if (!of_property_read_string(port, "dsa-tag-protocol",
+					     &protocol) &&
+		    !strcmp(protocol, "qca4"))
+			selected++;
+	}
+	of_node_put(ports);
+	if (!selected)
+		return 0;
+	if (selected != cpus)
+		return -EINVAL;
+	priv->persistent_boot.requested = true;
+	priv->private_tag_protocol = DSA_TAG_PROTO_QCA4;
+	priv->private_open_blocked = true;
+	priv->private_mgmt_blocked = true;
+	return 0;
+}
+
+int qca8k_persistent_status(struct net_device *conduit,
+			    struct qca8k_persistent_status *status)
+{
+	struct qca8k_persistent_status snapshot = {
+		.size = sizeof(snapshot),
+		.version = QCA8K_PERSISTENT_STATUS_VERSION,
+	};
+	struct dsa_port *cpu;
+	struct qca8k_priv *priv;
+	unsigned int port;
+	u32 value;
+	int ret = 0;
+
+	ASSERT_RTNL();
+	if (!status || status->size != sizeof(*status) ||
+	    status->version != QCA8K_PERSISTENT_STATUS_VERSION ||
+	    status->reserved || !conduit)
+		return -EINVAL;
+	*status = snapshot;
+	cpu = conduit->dsa_ptr;
+	if (!cpu || !dsa_port_is_cpu(cpu) ||
+	    cpu->ds->ops->get_tag_protocol != qca8k_get_tag_protocol)
+		return -EOPNOTSUPP;
+	priv = cpu->ds->priv;
+	mutex_lock(&priv->persistent_lock);
+	if (!priv->persistent_boot.requested) {
+		ret = -EOPNOTSUPP;
+		goto unlock;
+	}
+	snapshot.conduit_mtu[0] = dsa_to_port(priv->ds, 0)->conduit->mtu;
+	snapshot.conduit_mtu[1] = dsa_to_port(priv->ds, 6)->conduit->mtu;
+	snapshot.epoch = priv->persistent_epoch;
+	snapshot.selected = priv->private_tag_protocol;
+	snapshot.tree_protocol =
+		priv->ds->dst->tag_ops ? priv->ds->dst->tag_ops->proto : 0;
+	snapshot.requested = true;
+	snapshot.ready = priv->persistent_boot.ready;
+	snapshot.closing = priv->persistent_closing;
+	snapshot.restore_debt = priv->persistent_boot.restore_pending;
+	snapshot.uncertain = priv->persistent_boot.unknown ||
+			     priv->persistent_mtu.unknown ||
+			     priv->persistent_mtu.pending;
+	snapshot.first_error = priv->persistent_boot.first_error;
+	snapshot.held_fault = qca8k_persistent_last_fault;
+	if (!snapshot.ready || snapshot.closing || snapshot.uncertain ||
+	    snapshot.first_error || snapshot.held_fault)
+		goto publish;
+	ret = qca8k_persistent_software_ready(priv, false);
+	if (ret)
+		goto publish;
+	ret = qca8k_read_mii(priv, QCA8K_REG_GLOBAL_HDR_CTRL, &value);
+	if (!ret && (value & QCA4_PERSISTENT_MASK) != QCA4_PERSISTENT_VALUE)
+		ret = -EUCLEAN;
+	for (port = 0; !ret && port <= 6; port += 6) {
+		ret = qca8k_read_mii(priv, QCA8K_REG_PORT_HDR_CTRL(port),
+				     &value);
+		if (!ret && value != QCA4_PERSISTENT_CPU_HEADER)
+			ret = -EUCLEAN;
+	}
+	if (!ret) {
+		snapshot.known = true;
+		snapshot.coherent = true;
+		snapshot.conduit_mtu[0] =
+			dsa_to_port(priv->ds, 0)->conduit->mtu;
+		snapshot.conduit_mtu[1] =
+			dsa_to_port(priv->ds, 6)->conduit->mtu;
+	}
+publish:
+	if (ret)
+		snapshot.uncertain = true;
+	*status = snapshot; /* Even an I/O error cannot leave a stale known4. */
+unlock:
+	mutex_unlock(&priv->persistent_lock);
+	return ret;
+}
+EXPORT_SYMBOL_GPL(qca8k_persistent_status);
diff --git a/drivers/net/dsa/qca/qca8k.h b/drivers/net/dsa/qca/qca8k.h
index 956338893..9427e5d7d 100644
--- a/drivers/net/dsa/qca/qca8k.h
+++ b/drivers/net/dsa/qca/qca8k.h
@@ -13,6 +13,14 @@
 #include <linux/gpio/consumer.h>
 #include <linux/leds.h>
 #include <linux/dsa/tag_qca.h>
+#include <net/dsa.h>
+#include <linux/workqueue.h>
+#include "persistent_qca4.h"
+#include "persistent_qca4_mtu.h"
+#include <linux/dsa/qca8k_persistent.h>
+
+#define QCA8K_REG_GLOBAL_HDR_CTRL 0x098
+#define QCA8K_GLOBAL_HDR_CTRL_LEN_4B BIT(16)
 
 #define QCA8K_ETHERNET_MDIO_PRIORITY			7
 #define QCA8K_ETHERNET_PHY_PRIORITY			6
@@ -443,6 +451,9 @@ struct qca8k_led {
 };
 
 struct qca8k_priv {
+	enum dsa_tag_protocol private_tag_protocol;
+	bool private_mgmt_blocked, private_management_drained;
+	bool private_open_blocked;
 	u8 switch_id;
 	u8 switch_revision;
 	u8 mirror_rx;
@@ -469,8 +480,31 @@ struct qca8k_priv {
 	struct qca8k_pcs pcs_port_6;
 	const struct qca8k_match_data *info;
 	struct qca8k_led ports_led[QCA8K_LED_COUNT];
+#if IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE)
+	struct mutex persistent_lock;
+	struct qca4_persistent_state persistent_boot;
+	struct qca4_persistent_mtu_state persistent_mtu;
+	bool persistent_closing;
+	bool persistent_setup_started;
+	bool persistent_cleanup_attempted;
+	int persistent_cleanup_result;
+	int persistent_hold_error;
+	u64 persistent_epoch;
+	bool persistent_fe_held;
+	bool persistent_stopped_verified;
+	bool persistent_native2_verified;
+	u8 persistent_cpu_requested;
+	u8 persistent_status_valid;
+	u32 persistent_status[2];
+#endif
 };
 
+static inline bool qca8k_private_mgmt_blocked(struct qca8k_priv *priv)
+{
+	return IS_ENABLED(CONFIG_NET_DSA_QCA8K_4B_MODE) &&
+	       READ_ONCE(priv->private_mgmt_blocked);
+}
+
 struct qca8k_mib_desc {
 	unsigned int size;
 	unsigned int offset;
@@ -593,4 +627,10 @@ int qca8k_port_lag_join(struct dsa_switch *ds, int port, struct dsa_lag lag,
 int qca8k_port_lag_leave(struct dsa_switch *ds, int port,
 			 struct dsa_lag lag);
 
+int qca8k_persistent_first_user(struct qca8k_priv *priv);
+int qca8k_persistent_change_mtu(struct qca8k_priv *priv, int port, int mtu);
+bool qca8k_persistent_link_up(struct qca8k_priv *priv, int port, u32 status);
+bool qca8k_persistent_port_status(struct qca8k_priv *priv, int port,
+				  bool enable);
+
 #endif /* __QCA8K_H */

-- 
2.53.0

