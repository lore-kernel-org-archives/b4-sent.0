From: Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
Date: Fri, 13 Nov 2026 15:27:47 +0200
Subject: [PATCH RFC 2/2] clk: scmi: optionally register only clocks
 referenced in the device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-b4-scmi-clk-on-demand-v1-2-7fd162097b57@oss.nxp.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794576479; l=8272;
 i=ghennadi.procopciuc@oss.nxp.com; s=20261113; h=from:subject:message-id;
 bh=uwrgOyoizz013nf3CRlrIPoN2yjLJPfzMYY0JyjnGQ0=;
 b=lvCVKIh7yxdd85coP6C0l47rk9nd5p/47fv8OsL9av2qN7Ftvu4y95JFPGuDr6AWsgX/XcT+H
 5ik5/QhKic7A4+JZbADv4/fGb3AE2QxcTojNxTJ5R5SlwfGhFuZenf+
X-Developer-Key: i=ghennadi.procopciuc@oss.nxp.com; a=ed25519;
 pk=hNLk4ZpONFOVJg3NdDWRU2LtaL+HBg4W2I1KU0+XBmo=
X-Endpoint-Received: by B4 Relay for ghennadi.procopciuc@oss.nxp.com/20261113 with auth_id=1509
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Registering every clock the platform reports costs messages to the
platform and time in the clock core, although most of the clocks are not
used by the board.

Add the dt_referenced_only module parameter, with a Kconfig default, and
document it in kernel-parameters.txt. When it is set, register only the
clocks named by a "clocks", "assigned-clocks" or
"assigned-clock-parents" property of an enabled node, plus their
parents, because the clock core cannot resolve a parent that is not
registered. Disabled nodes are skipped, as sci-clk does, since they
never become consumers. The parent IDs reported by the platform are
checked against the clock count before they index the clock table.

A lookup of a clock that is not registered gets a NULL hw from
of_clk_hw_onecell_get(), and the consumer then uses a dummy clock that
silently does nothing. For the clocks left out by dt_referenced_only,
fail the lookup with -EINVAL instead. -ENOENT is not used, because the
optional clock getters turn it into a NULL clock. A clock that fails to
register keeps the NULL hw, so nothing changes when the parameter is not
set.

The unregistered clocks do not show up in clk_summary, and a device tree
overlay that references a new clock ID or enables a disabled node is not
supported.

Signed-off-by: Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
---
 Documentation/admin-guide/kernel-parameters.txt |   7 ++
 drivers/clk/Kconfig                             |  11 +++
 drivers/clk/clk-scmi.c                          | 120 ++++++++++++++++++++++--
 3 files changed, 132 insertions(+), 6 deletions(-)

diff --git a/Documentation/admin-guide/kernel-parameters.txt b/Documentation/admin-guide/kernel-parameters.txt
index 0b3c140babd9..765ba53b19e0 100644
--- a/Documentation/admin-guide/kernel-parameters.txt
+++ b/Documentation/admin-guide/kernel-parameters.txt
@@ -6941,6 +6941,13 @@ Kernel parameters
 			non-zero "wait" parameter.  See weight_single
 			and weight_many.
 
+	scmi_clk.dt_referenced_only[=<bool>] [CLK]
+			Register only the SCMI clocks referenced by enabled
+			device tree nodes, plus their parents. Enabled when no
+			<bool> value is given.
+			Default value is set by
+			CONFIG_COMMON_CLK_SCMI_DT_REFERENCED_ONLY.
+
 	sdw_mclk_divider=[SDW]
 			Specify the MCLK divider for Intel SoundWire buses in
 			case the BIOS does not provide the clock rate properly.
diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 37a8e35d4178..9642063e543f 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -116,6 +116,17 @@ config COMMON_CLK_SCMI
 	  This driver uses SCMI Message Protocol to interact with the
 	  firmware providing all the clock controls.
 
+config COMMON_CLK_SCMI_DT_REFERENCED_ONLY
+	bool "Register only the SCMI clocks referenced in the device tree"
+	depends on COMMON_CLK_SCMI && OF
+	help
+	  Register only the SCMI clocks referenced in the device tree, plus
+	  their parents, instead of every clock the firmware exposes. This
+	  shortens the boot time on platforms that expose many clocks.
+
+	  Sets the default of the scmi-clk "dt_referenced_only" module
+	  parameter. If unsure, say N.
+
 config COMMON_CLK_SCPI
 	tristate "Clock driver controlled via SCPI interface"
 	depends on ARM_SCPI_PROTOCOL || COMPILE_TEST
diff --git a/drivers/clk/clk-scmi.c b/drivers/clk/clk-scmi.c
index 2dd50c5b4ea8..a8ec782ac279 100644
--- a/drivers/clk/clk-scmi.c
+++ b/drivers/clk/clk-scmi.c
@@ -5,7 +5,9 @@
  * Copyright (C) 2018-2024 ARM Ltd.
  */
 
+#include <linux/bitmap.h>
 #include <linux/bits.h>
+#include <linux/cleanup.h>
 #include <linux/clk-provider.h>
 #include <linux/device.h>
 #include <linux/err.h>
@@ -350,6 +352,93 @@ scmi_clk_ops_select(struct scmi_device *sdev, struct scmi_clk *sclk,
 	return ops;
 }
 
+static bool dt_referenced_only =
+	IS_ENABLED(CONFIG_COMMON_CLK_SCMI_DT_REFERENCED_ONLY);
+module_param(dt_referenced_only, bool, 0444);
+MODULE_PARM_DESC(dt_referenced_only,
+		 "Register only the clocks referenced in the device tree");
+
+static const char * const scmi_clk_ref_props[] = {
+	"clocks", "assigned-clocks", "assigned-clock-parents",
+};
+
+/* Set in @ids the IDs of the @provider clocks referenced by enabled nodes */
+static void scmi_clk_mark_dt_refs(struct device_node *provider,
+				  unsigned long *ids, unsigned int count)
+{
+	struct of_phandle_iterator it;
+	u32 args[MAX_PHANDLE_ARGS];
+	struct device_node *np;
+	const char *prop;
+	int p, err, n;
+
+	for (p = 0; p < ARRAY_SIZE(scmi_clk_ref_props); p++) {
+		prop = scmi_clk_ref_props[p];
+
+		for_each_node_with_property(np, prop) {
+			if (!of_device_is_available(np))
+				continue;
+
+			of_for_each_phandle(&it, err, np, prop, "#clock-cells", -1) {
+				/* Empty entries (<0>) have no node */
+				if (it.node != provider)
+					continue;
+
+				n = of_phandle_iterator_args(&it, args,
+							     MAX_PHANDLE_ARGS);
+				if (n >= 1 && args[0] < count)
+					__set_bit(args[0], ids);
+			}
+		}
+	}
+}
+
+/*
+ * A registered clock needs its parents registered too: a parent_data entry
+ * with no hw makes the clock core look the parent up in the DT, which fails
+ * for this provider. Mark the parents until no new ID is added.
+ */
+static int scmi_clk_mark_parents(const struct scmi_protocol_handle *ph,
+				 unsigned long *ids, unsigned int count)
+{
+	unsigned long *done __free(bitmap) = bitmap_zalloc(count, GFP_KERNEL);
+	const struct scmi_clock_info *info;
+	unsigned int id, j;
+	bool changed;
+
+	if (!done)
+		return -ENOMEM;
+
+	do {
+		changed = false;
+		for_each_set_bit(id, ids, count) {
+			if (test_bit(id, done))
+				continue;
+
+			__set_bit(id, done);
+			info = scmi_proto_clk_ops->info_get(ph, id);
+			for (j = 0; info && j < info->num_parents; j++)
+				if (info->parents[j] < count &&
+				    !__test_and_set_bit(info->parents[j], ids))
+					changed = true;
+		}
+	} while (changed);
+
+	return 0;
+}
+
+static struct clk_hw *scmi_clk_get_hw(struct of_phandle_args *clkspec,
+				      void *data)
+{
+	struct clk_hw *hw = of_clk_hw_onecell_get(clkspec, data);
+
+	if (IS_ERR(hw))
+		pr_warn_ratelimited("scmi-clocks: clock %u is not registered\n",
+				    clkspec->args[0]);
+
+	return hw;
+}
+
 static int scmi_clocks_probe(struct scmi_device *sdev)
 {
 	int idx, count, err;
@@ -391,14 +480,31 @@ static int scmi_clocks_probe(struct scmi_device *sdev)
 	transport_is_atomic = handle->is_transport_atomic(handle,
 							  &atomic_threshold_us);
 
+	unsigned long *ids __free(bitmap) = bitmap_zalloc(count, GFP_KERNEL);
+
+	if (!ids)
+		return -ENOMEM;
+
+	if (dt_referenced_only && np) {
+		scmi_clk_mark_dt_refs(np, ids, count);
+		err = scmi_clk_mark_parents(ph, ids, count);
+		if (err)
+			return err;
+
+		if (bitmap_empty(ids, count))
+			dev_warn(dev, "no clock referenced in the device tree, none registered\n");
+	} else {
+		bitmap_fill(ids, count);
+	}
+
 	sclks = devm_kcalloc(dev, count, sizeof(*sclks), GFP_KERNEL);
 	if (!sclks)
 		return -ENOMEM;
 
 	for (idx = 0; idx < count; idx++)
-		hws[idx] = &sclks[idx].hw;
+		hws[idx] = test_bit(idx, ids) ? &sclks[idx].hw : ERR_PTR(-EINVAL);
 
-	for (idx = 0; idx < count; idx++) {
+	for_each_set_bit(idx, ids, count) {
 		struct scmi_clk *sclk = &sclks[idx];
 		const struct clk_ops *scmi_ops;
 
@@ -434,8 +540,11 @@ static int scmi_clocks_probe(struct scmi_device *sdev)
 				return -ENOMEM;
 
 			for (int i = 0; i < sclk->info->num_parents; i++) {
-				sclk->parent_data[i].index = sclk->info->parents[i];
-				sclk->parent_data[i].hw = hws[sclk->info->parents[i]];
+				u32 pid = sclk->info->parents[i];
+				struct clk_hw *phw = pid < count ? hws[pid] : NULL;
+
+				sclk->parent_data[i].index = pid;
+				sclk->parent_data[i].hw = IS_ERR(phw) ? NULL : phw;
 			}
 		}
 
@@ -451,8 +560,7 @@ static int scmi_clocks_probe(struct scmi_device *sdev)
 		}
 	}
 
-	return devm_of_clk_add_hw_provider(dev, of_clk_hw_onecell_get,
-					   clk_data);
+	return devm_of_clk_add_hw_provider(dev, scmi_clk_get_hw, clk_data);
 }
 
 static const struct scmi_device_id scmi_id_table[] = {

-- 
2.43.0

