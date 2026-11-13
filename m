From: Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
Date: Fri, 13 Nov 2026 15:27:46 +0200
Subject: [PATCH RFC 1/2] firmware: arm_scmi: clock: discover clock domains
 on first use
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-scmi-clk-on-demand-v1-1-7fd162097b57@oss.nxp.com>
References: <20261113-b4-scmi-clk-on-demand-v1-0-7fd162097b57@oss.nxp.com>
In-Reply-To: <20261113-b4-scmi-clk-on-demand-v1-0-7fd162097b57@oss.nxp.com>
To: Brian Masney <bmasney+clk@redhat.com>, 
 Sudeep Holla <sudeep.holla@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Cristian Marussi <cristian.marussi@arm.com>
Cc: linux-doc@vger.kernel.org, Alberto Ruiz <aruizrui@redhat.com>, 
 linux-arm-kernel@lists.infradead.org, Christophe Lizzi <clizzi@redhat.com>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 arm-scmi@vger.kernel.org, Eric Chanudet <echanude@redhat.com>, 
 Enric Balletbo <eballetb@redhat.com>, NXP S32 Linux Team <s32@nxp.com>, 
 Jonathan Corbet <corbet@lwn.net>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794576479; l=13263;
 i=ghennadi.procopciuc@oss.nxp.com; s=20261113; h=from:subject:message-id;
 bh=m6wgrgZ8AgVX0/wwAJXM4DOFHjBScSop3ClJXnn9sMw=;
 b=xApzx6ZSen2hAtw9bnDZ8DauhYWK7x6qHBqEqiK+W/e6gZJijVfqg6HoZtvi8VsARU2rSleN3
 1hxLktsr6zRCcoFXQlxP9ShjD9fkuQXz72imXvoXYNMOjqncM3+t4c1
X-Developer-Key: i=ghennadi.procopciuc@oss.nxp.com; a=ed25519;
 pk=hNLk4ZpONFOVJg3NdDWRU2LtaL+HBg4W2I1KU0+XBmo=
X-Endpoint-Received: by B4 Relay for ghennadi.procopciuc@oss.nxp.com/20261113 with auth_id=1509
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

scmi_clock_protocol_init() queries the attributes, rates and parents of
every clock domain the platform reports. With hundreds of clocks this is
more than a thousand messages at init, most of them for clocks that are
never used.

Query only the protocol version and attributes at init, and discover
each clock domain on the first operation that needs it.

Discovery can sleep, so the operations that can run in atomic context
(enable, disable and OEM config) fail with -EAGAIN for a clock that is
not discovered yet. A clock for which info_get() returned its info is
always discovered.

A failed discovery is returned to the caller, and the clock is
discovered again on the next operation, so a transient transport error
does not leave the clock unusable until the protocol is released. As a
result, info_get() now returns NULL for a clock whose
CLOCK_DESCRIBE_RATES fails, and clk-scmi does not register it. Before,
the clock was registered without rate information.

The rates and parents arrays are now allocated after the devres group of
the protocol instance is closed, so allocate them with kcalloc() and free
them in a new instance_deinit callback.

is_notify_supported() is called for every clock when the protocol events
are registered, before any clock is discovered, and must not trigger
discovery. It now reports the protocol level support, and
set_notify_enabled() discovers the clock and rejects it with -EOPNOTSUPP
if it does not support the event. Every clock is then a supported source
of the events the protocol supports, so enabling an event for all
sources discovers every clock.
No in-tree driver registers SCMI clock notifiers.

Signed-off-by: Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
---
 drivers/firmware/arm/scmi/clock.c | 160 ++++++++++++++++++++++++++++----------
 include/linux/scmi_protocol.h     |   4 +-
 2 files changed, 122 insertions(+), 42 deletions(-)

diff --git a/drivers/firmware/arm/scmi/clock.c b/drivers/firmware/arm/scmi/clock.c
index 0278705d809e..010b63b63703 100644
--- a/drivers/firmware/arm/scmi/clock.c
+++ b/drivers/firmware/arm/scmi/clock.c
@@ -5,9 +5,11 @@
  * Copyright (C) 2018-2022 ARM Ltd.
  */
 
+#include <linux/cleanup.h>
 #include <linux/math64.h>
 #include <linux/module.h>
 #include <linux/limits.h>
+#include <linux/mutex.h>
 #include <linux/sort.h>
 
 #include "protocols.h"
@@ -159,6 +161,7 @@ struct scmi_clock_rate_notify_payld {
 
 struct scmi_clock_desc {
 	u32 id;
+	bool discovered;
 	unsigned int tot_rates;
 	struct scmi_clock_rates r;
 #define	RATE_MIN	0
@@ -175,6 +178,7 @@ struct clock_info {
 	bool notify_rate_changed_cmd;
 	bool notify_rate_change_requested_cmd;
 	atomic_t cur_async_req;
+	struct mutex discover_lock;	/* serializes the discovery of clkds */
 	struct scmi_clock_desc *clkds;
 #define CLOCK_INFO(c, i)	(&(((c)->clkds + (i))->info))
 	int (*clock_config_set)(const struct scmi_protocol_handle *ph,
@@ -192,15 +196,6 @@ static enum scmi_clock_protocol_cmd evt_2_cmd[] = {
 	CLOCK_RATE_CHANGE_REQUESTED_NOTIFY,
 };
 
-static inline struct scmi_clock_info *
-scmi_clock_domain_lookup(struct clock_info *ci, u32 clk_id)
-{
-	if (clk_id >= ci->num_clocks)
-		return ERR_PTR(-EINVAL);
-
-	return CLOCK_INFO(ci, clk_id);
-}
-
 static int
 scmi_clock_protocol_attributes_get(const struct scmi_protocol_handle *ph,
 				   struct clock_info *ci)
@@ -271,9 +266,9 @@ static int iter_clk_possible_parents_update_state(struct scmi_iterator_state *st
 	if (!st->max_resources) {
 		int num_parents = st->num_returned + st->num_remaining;
 
-		p->clkd->info.parents = devm_kcalloc(p->dev, num_parents,
-						     sizeof(*p->clkd->info.parents),
-						     GFP_KERNEL);
+		p->clkd->info.parents = kcalloc(num_parents,
+						sizeof(*p->clkd->info.parents),
+						GFP_KERNEL);
 		if (!p->clkd->info.parents)
 			return -ENOMEM;
 
@@ -484,8 +479,8 @@ iter_clk_describe_update_state(struct scmi_iterator_state *st,
 	if (!st->max_resources) {
 		unsigned int tot_rates = st->num_returned + st->num_remaining;
 
-		p->clkd->r.rates = devm_kcalloc(p->dev, tot_rates,
-						sizeof(*p->clkd->r.rates), GFP_KERNEL);
+		p->clkd->r.rates = kcalloc(tot_rates, sizeof(*p->clkd->r.rates),
+					   GFP_KERNEL);
 		if (!p->clkd->r.rates)
 			return -ENOMEM;
 
@@ -638,6 +633,74 @@ scmi_clock_describe_rates_get(const struct scmi_protocol_handle *ph,
 	return 0;
 }
 
+/*
+ * Discovery runs after the devres group of the protocol instance is closed,
+ * so the rates and parents arrays cannot be devm-allocated and are freed
+ * here instead.
+ */
+static void scmi_clock_desc_free(struct scmi_clock_desc *clkd)
+{
+	kfree(clkd->r.rates);
+	kfree(clkd->info.parents);
+}
+
+static int scmi_clock_discover(const struct scmi_protocol_handle *ph,
+			       struct clock_info *ci, u32 clk_id)
+{
+	struct scmi_clock_desc *clkd = &ci->clkds[clk_id];
+	int ret;
+
+	guard(mutex)(&ci->discover_lock);
+
+	if (clkd->discovered)
+		return 0;
+
+	clkd->id = clk_id;
+	ret = scmi_clock_attributes_get(ph, clk_id, ci);
+	if (!ret)
+		ret = scmi_clock_describe_rates_get(ph, clk_id, ci);
+	if (ret) {
+		/*
+		 * Start the next attempt from a clean descriptor, so that a
+		 * transient error does not leave the clock unusable and the
+		 * iterators do not leak the arrays of this attempt.
+		 */
+		scmi_clock_desc_free(clkd);
+		memset(clkd, 0, sizeof(*clkd));
+		return ret;
+	}
+
+	/* Pairs with the acquire in the lookup */
+	smp_store_release(&clkd->discovered, true);
+
+	return 0;
+}
+
+static struct scmi_clock_info *
+scmi_clock_domain_lookup(const struct scmi_protocol_handle *ph,
+			 struct clock_info *ci, u32 clk_id, bool atomic)
+{
+	struct scmi_clock_desc *clkd;
+	int ret;
+
+	if (clk_id >= ci->num_clocks)
+		return ERR_PTR(-EINVAL);
+
+	clkd = &ci->clkds[clk_id];
+	/* Pairs with the release once the clock is discovered */
+	if (!smp_load_acquire(&clkd->discovered)) {
+		/* Discovery sleeps, so an atomic caller can only use known clocks */
+		if (WARN_ON_ONCE(atomic))
+			return ERR_PTR(-EAGAIN);
+
+		ret = scmi_clock_discover(ph, ci, clk_id);
+		if (ret)
+			return ERR_PTR(ret);
+	}
+
+	return &clkd->info;
+}
+
 static int
 scmi_clock_rate_get(const struct scmi_protocol_handle *ph,
 		    u32 clk_id, u64 *value)
@@ -670,7 +733,7 @@ static int scmi_clock_rate_set(const struct scmi_protocol_handle *ph,
 	struct clock_info *ci = ph->get_priv(ph);
 	struct scmi_clock_info *clk;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, false);
 	if (IS_ERR(clk))
 		return PTR_ERR(clk);
 
@@ -726,7 +789,7 @@ static int scmi_clock_determine_rate(const struct scmi_protocol_handle *ph,
 	if (!rate)
 		return -EINVAL;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, false);
 	if (IS_ERR(clk))
 		return PTR_ERR(clk);
 
@@ -768,7 +831,7 @@ scmi_clock_all_rates_get(const struct scmi_protocol_handle *ph, u32 clk_id)
 	struct scmi_clock_desc *clkd;
 	struct scmi_clock_info *clk;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, false);
 	if (IS_ERR(clk) || !clk->name[0])
 		return NULL;
 
@@ -827,7 +890,7 @@ scmi_clock_set_parent(const struct scmi_protocol_handle *ph, u32 clk_id,
 	struct clock_info *ci = ph->get_priv(ph);
 	struct scmi_clock_info *clk;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, false);
 	if (IS_ERR(clk))
 		return PTR_ERR(clk);
 
@@ -923,7 +986,7 @@ static int scmi_clock_enable(const struct scmi_protocol_handle *ph, u32 clk_id,
 	struct clock_info *ci = ph->get_priv(ph);
 	struct scmi_clock_info *clk;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, atomic);
 	if (IS_ERR(clk))
 		return PTR_ERR(clk);
 
@@ -940,7 +1003,7 @@ static int scmi_clock_disable(const struct scmi_protocol_handle *ph, u32 clk_id,
 	struct clock_info *ci = ph->get_priv(ph);
 	struct scmi_clock_info *clk;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, atomic);
 	if (IS_ERR(clk))
 		return PTR_ERR(clk);
 
@@ -1041,7 +1104,7 @@ static int scmi_clock_config_oem_set(const struct scmi_protocol_handle *ph,
 	struct clock_info *ci = ph->get_priv(ph);
 	struct scmi_clock_info *clk;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, atomic);
 	if (IS_ERR(clk))
 		return PTR_ERR(clk);
 
@@ -1060,7 +1123,7 @@ static int scmi_clock_config_oem_get(const struct scmi_protocol_handle *ph,
 	struct clock_info *ci = ph->get_priv(ph);
 	struct scmi_clock_info *clk;
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, atomic);
 	if (IS_ERR(clk))
 		return PTR_ERR(clk);
 
@@ -1084,7 +1147,7 @@ scmi_clock_info_get(const struct scmi_protocol_handle *ph, u32 clk_id)
 	struct scmi_clock_info *clk;
 	struct clock_info *ci = ph->get_priv(ph);
 
-	clk = scmi_clock_domain_lookup(ci, clk_id);
+	clk = scmi_clock_domain_lookup(ph, ci, clk_id, false);
 	if (IS_ERR(clk))
 		return NULL;
 
@@ -1113,23 +1176,16 @@ static const struct scmi_clk_proto_ops clk_proto_ops = {
 static bool scmi_clk_notify_supported(const struct scmi_protocol_handle *ph,
 				      u8 evt_id, u32 src_id)
 {
-	bool supported;
-	struct scmi_clock_info *clk;
 	struct clock_info *ci = ph->get_priv(ph);
 
-	if (evt_id >= ARRAY_SIZE(evt_2_cmd))
-		return false;
-
-	clk = scmi_clock_domain_lookup(ci, src_id);
-	if (IS_ERR(clk))
+	if (evt_id >= ARRAY_SIZE(evt_2_cmd) || src_id >= ci->num_clocks)
 		return false;
 
+	/* No clock is discovered yet, so report the protocol level support */
 	if (evt_id == SCMI_EVENT_CLOCK_RATE_CHANGED)
-		supported = clk->rate_changed_notifications;
-	else
-		supported = clk->rate_change_requested_notifications;
+		return ci->notify_rate_changed_cmd;
 
-	return supported;
+	return ci->notify_rate_change_requested_cmd;
 }
 
 static int scmi_clk_rate_notify(const struct scmi_protocol_handle *ph,
@@ -1157,10 +1213,23 @@ static int scmi_clk_set_notify_enabled(const struct scmi_protocol_handle *ph,
 				       u8 evt_id, u32 src_id, bool enable)
 {
 	int ret, cmd_id;
+	bool supported;
+	struct scmi_clock_info *clk;
+	struct clock_info *ci = ph->get_priv(ph);
 
 	if (evt_id >= ARRAY_SIZE(evt_2_cmd))
 		return -EINVAL;
 
+	clk = scmi_clock_domain_lookup(ph, ci, src_id, false);
+	if (IS_ERR(clk))
+		return PTR_ERR(clk);
+
+	supported = evt_id == SCMI_EVENT_CLOCK_RATE_CHANGED ?
+		    clk->rate_changed_notifications :
+		    clk->rate_change_requested_notifications;
+	if (!supported)
+		return -EOPNOTSUPP;
+
 	cmd_id = evt_2_cmd[evt_id];
 	ret = scmi_clk_rate_notify(ph, src_id, cmd_id, enable);
 	if (ret)
@@ -1229,9 +1298,20 @@ static const struct scmi_protocol_events clk_protocol_events = {
 	.num_events = ARRAY_SIZE(clk_events),
 };
 
+static int scmi_clock_protocol_deinit(const struct scmi_protocol_handle *ph)
+{
+	struct clock_info *cinfo = ph->get_priv(ph);
+	int i;
+
+	for (i = 0; i < cinfo->num_clocks; i++)
+		scmi_clock_desc_free(&cinfo->clkds[i]);
+
+	return 0;
+}
+
 static int scmi_clock_protocol_init(const struct scmi_protocol_handle *ph)
 {
-	int clkid, ret;
+	int ret;
 	struct clock_info *cinfo;
 
 	dev_dbg(ph->dev, "Clock Version %d.%d\n",
@@ -1250,12 +1330,9 @@ static int scmi_clock_protocol_init(const struct scmi_protocol_handle *ph)
 	if (!cinfo->clkds)
 		return -ENOMEM;
 
-	for (clkid = 0; clkid < cinfo->num_clocks; clkid++) {
-		cinfo->clkds[clkid].id = clkid;
-		ret = scmi_clock_attributes_get(ph, clkid, cinfo);
-		if (!ret)
-			scmi_clock_describe_rates_get(ph, clkid, cinfo);
-	}
+	ret = devm_mutex_init(ph->dev, &cinfo->discover_lock);
+	if (ret)
+		return ret;
 
 	if (PROTOCOL_REV_MAJOR(ph->version) >= 0x3) {
 		cinfo->clock_config_set = scmi_clock_config_set_v2;
@@ -1272,6 +1349,7 @@ static const struct scmi_protocol scmi_clock = {
 	.id = SCMI_PROTOCOL_CLOCK,
 	.owner = THIS_MODULE,
 	.instance_init = &scmi_clock_protocol_init,
+	.instance_deinit = &scmi_clock_protocol_deinit,
 	.ops = &clk_proto_ops,
 	.events = &clk_protocol_events,
 	.supported_version = SCMI_PROTOCOL_SUPPORTED_VERSION,
diff --git a/include/linux/scmi_protocol.h b/include/linux/scmi_protocol.h
index 3f7cc35eb861..c326f4edc9a0 100644
--- a/include/linux/scmi_protocol.h
+++ b/include/linux/scmi_protocol.h
@@ -84,7 +84,9 @@ enum scmi_clock_oem_config {
  *	by SCMI Clock Protocol
  *
  * @count_get: get the count of clocks provided by SCMI
- * @info_get: get the information of the specified clock
+ * @info_get: get the information of the specified clock. The clock is
+ *	      discovered on the first call for it, which sends messages to
+ *	      the platform, so this can sleep
  * @rate_get: request the current clock rate of a clock
  * @rate_set: set the clock rate of a clock
  * @determine_rate: determine the effective rate that can be supported by a

-- 
2.43.0

