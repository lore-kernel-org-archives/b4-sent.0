From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 09 Feb 2026 13:48:53 +0800
Subject: [PATCH 07/13] clk: amlogic: Add duandiv clock driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-a9_clock_driver-v1-7-a9198dc03d2a@amlogic.com>
References: <20260209-a9_clock_driver-v1-0-a9198dc03d2a@amlogic.com>
In-Reply-To: <20260209-a9_clock_driver-v1-0-a9198dc03d2a@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770616142; l=15230;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=lExIppsrGs3hG71peQNd4KEz/nuT8sZa6/ObaVooJnk=;
 b=B3IIxMGqKTCKBnUJMP9hnaQefxTiQhEaz/vXaE3Gja/L1P9mrB8tqWDw/nijoc8hQHiAgYaj6
 93tMWtV6cioCtvGwL6ssxh4h6idEzcxNdZs4HaOwViWZeUPlsdLXdHI
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement clk_ops support for Amlogic dualdiv clocks. The dualdiv clock
comprises two independent divider channels with counters. It achieves
fractional division functionality by alternating between the two divided
clocks.

Amlogic dualdiv clocks are used for modules requiring fractional
division without concern for clock phase or duty cycle, commonly
generating 32.768KHz from a 24MHz crystal input for RTC applications.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/amlogic/Makefile      |   1 +
 drivers/clk/amlogic/clk-dualdiv.c | 365 ++++++++++++++++++++++++++++++++++++++
 drivers/clk/amlogic/clk-dualdiv.h |  27 +++
 drivers/clk/amlogic/clk.c         |   1 +
 drivers/clk/amlogic/clk.h         |   1 +
 5 files changed, 395 insertions(+)

diff --git a/drivers/clk/amlogic/Makefile b/drivers/clk/amlogic/Makefile
index 72cd2525e078..bc2b22b4d3c9 100644
--- a/drivers/clk/amlogic/Makefile
+++ b/drivers/clk/amlogic/Makefile
@@ -5,4 +5,5 @@ obj-$(CONFIG_COMMON_CLK_AMLOGIC) += clk-amlogic.o
 clk-amlogic-y += clk.o
 clk-amlogic-y += clk-basic.o
 clk-amlogic-y += clk-composite.o
+clk-amlogic-y += clk-dualdiv.o
 clk-amlogic-y += clk-noglitch.o
diff --git a/drivers/clk/amlogic/clk-dualdiv.c b/drivers/clk/amlogic/clk-dualdiv.c
new file mode 100644
index 000000000000..1752b89ec0f2
--- /dev/null
+++ b/drivers/clk/amlogic/clk-dualdiv.c
@@ -0,0 +1,365 @@
+// SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#include <linux/module.h>
+
+#include "clk.h"
+#include "clk-basic.h"
+#include "clk-dualdiv.h"
+
+/*
+ * Amlogic dualdiv clock module:
+ *
+ *                          n0         m0     div_mode    clkout_gate
+ *                          |          |        |              |
+ *          clkin_gate      |    n1    |    m1  | force_clkout |
+ *             |            |    |     |    |   |     |        |
+ *      +------|------------|----|-----|----|---|-----|--------|----+
+ *      |      |           \|/   |    \|/   |  \|/    |        |    |
+ *      |      |         +-----+ |  +-----+ |  |\     |        |    |
+ *      |      |     +-->| div |-o->| cnt |-o->| |   \|/       |    |
+ *      |     \|/    |   +-----+ |  +-----+ |  | |   |\        |    |
+ * clk  |  +------+  |           |          |  | |   | |       |    |
+ * in ---->| gate |--+      +----+     +----+  | |-->| |      \|/   |
+ *      |  +------+  |     \|/        \|/      | |   | |   +------+ |
+ *      |            |   +-----+    +-----+    | |   | |-->| gate |----> clk
+ *      |            +-->| div |--->| cnt |--->| |   | |   +------+ |    out
+ *      |            |   +-----+    +-----+    |/    | |            |
+ *      |            +------------------------------>| |            |
+ *      |                                            |/             |
+ *      |                                                           |
+ *      +-----------------------------------------------------------+
+ *
+ * The Amlogic dualdiv clock is used to implement fractional division (e.g., a
+ * 24 MHz input clock with a 32.768 KHz output for the RTC).
+ *
+ * The functional description of these parameters is described below as follows:
+ *   - clkin_gate: clock input gate
+ *   - n0: Divider value corresponding to channel 0
+ *   - n1: Divider value corresponding to channel 1
+ *   - m0: Number of output cycles per burst on channel 0 (switches to channel 1
+ *         after the cycles are output)
+ *   - m1: Number of output cycles per burst on channel 0 (switches to channel 0
+ *         after the cycles are output)
+ *   - div_mode: Division mode configuration:
+ *     - div_mode = 0: Normal division mode:
+ *         dualdiv_out = clk_in / n0;
+ *     - div_mode = 1: Dualdiv (fractional) division mode:
+ *         dualdiv_out = clk_in / ((n0 * m0 + n1 * m1) / (m0 + m1));
+ *   - force_clkout: force clock_out = clock_in
+ *   - clkout_gate: clock output gate
+ *
+ * The fractional division principle of dualdiv is to alternately switch via a
+ * mux between two integer-divided clocks, thereby achieving an effective
+ * fractional division.
+ *
+ * For example, when configuring a dualdiv ratio of 1.75, the clock waveform
+ * is illustrated below (n0 = 1, m0 = 1, n1 = 2, m1 = 3):
+ *
+ *             _   _   _   _   _   _   _   _   _   _   _   _
+ * clk in:    | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|
+ *             _   _   _   _   _   _   _   _   _   _   _   _
+ * channel0:  | |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_| |_|
+ *             __    __    __    __    __    __    __    __
+ * channel1:  |  |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
+ *             _   __    __    __    _   __    __    __    _
+ * clk out:   | |_|  |__|  |__|  |__| |_|  |__|  |__|  |__| |_|
+ *            |<->|<--------------->|<->|<--------------->|<->|
+ *              m0          m1        m0         m1         m0
+ */
+
+#define AML_DUALDIV_REG0_OFFSET			(0)
+#define AML_DUALDIV_REG1_OFFSET			(4)
+
+struct aml_dualdiv_reg_parms {
+	union {
+		struct {
+			u32 n0			:12;  /* bit0 - bit11 */
+			u32 n1			:12;  /* bit12 - bit23 */
+			u32 reserved0		:4;  /* bit24 - bit27 */
+			u32 div_mode		:2;  /* bit28 - bit29 */
+			u32 clkout_gate		:1;  /* bit30 */
+			u32 clkin_gate		:1;  /* bit31 */
+		} bits;
+		u32 val;
+	} reg0;
+	union {
+		struct {
+			u32 m0			:12;  /* bit0 - bit11 */
+			u32 m1			:12;  /* bit12 - bit23 */
+			u32 force_clkout	:1;  /* bit24 */
+			u32 reserved0		:5;  /* bit25 - bit29 */
+			u32 out_mux		:2;  /* bit30 - bit31 */
+
+		} bits;
+		u32 val;
+	} reg1;
+};
+
+static inline unsigned int _get_div_mult(unsigned int val)
+{
+	return val + 1;
+}
+
+static unsigned long
+aml_dualdiv_param_to_rate(unsigned long parent_rate,
+			  const struct aml_clk_dualdiv_param *p)
+{
+	unsigned int n0, n1, m0, m1;
+
+	n0 = _get_div_mult(p->n0);
+	if (!p->div_mode)
+		return DIV_ROUND_CLOSEST(parent_rate, n0);
+
+	n1 = _get_div_mult(p->n1);
+	m0 = _get_div_mult(p->m0);
+	m1 = _get_div_mult(p->m1);
+
+	return DIV_ROUND_CLOSEST(parent_rate * (m0 + m1), n0 * m0 + n1 * m1);
+}
+
+static unsigned long aml_clk_dualdiv_recalc_rate(struct clk_hw *hw,
+						 unsigned long parent_rate)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_dualdiv_data *dualdiv = clk->data;
+	struct aml_dualdiv_reg_parms reg;
+	struct aml_clk_dualdiv_param parm;
+
+	regmap_read(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG1_OFFSET,
+		    &reg.reg1.val);
+	if (reg.reg1.bits.force_clkout == 1)
+		return parent_rate;
+
+	regmap_read(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		    &reg.reg0.val);
+	parm.div_mode = reg.reg0.bits.div_mode;
+	parm.n0 = reg.reg0.bits.n0;
+	parm.n1 = reg.reg0.bits.n1;
+	parm.m0 = reg.reg1.bits.m0;
+	parm.m1 = reg.reg1.bits.m1;
+
+	return aml_dualdiv_param_to_rate(parent_rate, &parm);
+}
+
+/*
+ * NOTE: Dynamically calculating the divider parameters based on the target
+ * frequency has relatively high algorithmic complexity, and the number of
+ * frequency points that require dualdiv division in current use cases is
+ * limited.
+ *
+ * Therefore, only a table-based lookup method is supported to obtain the
+ * best-matched divider parameters at present.
+ */
+static const struct aml_clk_dualdiv_param *
+aml_clk_dualdiv_get_setting(unsigned long rate, unsigned long parent_rate,
+			    struct aml_clk_dualdiv_data *dualdiv)
+{
+	const struct aml_clk_dualdiv_param *table = dualdiv->table;
+	unsigned long best = 0, now = 0;
+	unsigned int i, best_i = 0;
+
+	if (!table)
+		return NULL;
+
+	for (i = 0; i < dualdiv->table_count; i++) {
+		now = aml_dualdiv_param_to_rate(parent_rate, &table[i]);
+
+		/* If we get an exact match, don't bother any further */
+		if (now == rate) {
+			return &table[i];
+		} else if (abs(now - rate) < abs(best - rate)) {
+			best = now;
+			best_i = i;
+		}
+	}
+
+	return (struct aml_clk_dualdiv_param *)&table[best_i];
+}
+
+static int aml_clk_dualdiv_determine_rate(struct clk_hw *hw,
+					  struct clk_rate_request *req)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_dualdiv_data *dualdiv = clk->data;
+	const struct aml_clk_dualdiv_param *setting;
+
+	/* Just need to set "force_clkout" = 1 */
+	if (req->rate == req->best_parent_rate) {
+		req->rate = req->best_parent_rate;
+
+		return 0;
+	}
+
+	setting = aml_clk_dualdiv_get_setting(req->rate, req->best_parent_rate,
+					      dualdiv);
+	if (setting)
+		req->rate = aml_dualdiv_param_to_rate(req->best_parent_rate,
+						      setting);
+	else
+		req->rate = aml_clk_dualdiv_recalc_rate(hw,
+							req->best_parent_rate);
+
+	return 0;
+}
+
+static int aml_clk_dualdiv_set_rate(struct clk_hw *hw, unsigned long rate,
+				    unsigned long parent_rate)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_dualdiv_data *dualdiv = clk->data;
+	struct aml_dualdiv_reg_parms reg;
+	const struct aml_clk_dualdiv_param *setting;
+
+	/* Just need to set "force_clkout" = 1 */
+	if (rate == parent_rate) {
+		regmap_read(clk->map,
+			    dualdiv->reg_offset + AML_DUALDIV_REG1_OFFSET,
+			    &reg.reg1.val);
+		reg.reg1.bits.force_clkout = 1;
+		regmap_write(clk->map,
+			     dualdiv->reg_offset + AML_DUALDIV_REG1_OFFSET,
+			     reg.reg1.val);
+
+		return 0;
+	}
+
+	setting = aml_clk_dualdiv_get_setting(rate, parent_rate, dualdiv);
+	if (!setting)
+		return -EINVAL;
+
+	regmap_read(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		    &reg.reg0.val);
+	regmap_read(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG1_OFFSET,
+		    &reg.reg1.val);
+	reg.reg1.bits.force_clkout = 0;
+
+	reg.reg0.bits.div_mode = setting->div_mode;
+	reg.reg0.bits.n0 = setting->n0;
+	reg.reg0.bits.n1 = setting->n1;
+	reg.reg1.bits.m0 = setting->m0;
+	reg.reg1.bits.m1 = setting->m1;
+
+	regmap_write(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		     reg.reg0.val);
+	regmap_write(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG1_OFFSET,
+		     reg.reg1.val);
+
+	return 0;
+}
+
+static int aml_clk_dualdiv_enable(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_dualdiv_data *dualdiv = clk->data;
+	struct aml_dualdiv_reg_parms reg;
+
+	regmap_read(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		    &reg.reg0.val);
+	reg.reg0.bits.clkin_gate = 1;
+	reg.reg0.bits.clkout_gate = 1;
+
+	regmap_write(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		     reg.reg0.val);
+
+	return 0;
+}
+
+static void aml_clk_dualdiv_disable(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_dualdiv_data *dualdiv = clk->data;
+	struct aml_dualdiv_reg_parms reg;
+
+	regmap_read(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		    &reg.reg0.val);
+	reg.reg0.bits.clkin_gate = 0;
+	reg.reg0.bits.clkout_gate = 0;
+
+	regmap_write(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		     reg.reg0.val);
+}
+
+static int aml_clk_dualdiv_is_enabled(struct clk_hw *hw)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_dualdiv_data *dualdiv = clk->data;
+	struct aml_dualdiv_reg_parms reg;
+
+	regmap_read(clk->map, dualdiv->reg_offset + AML_DUALDIV_REG0_OFFSET,
+		    &reg.reg0.val);
+
+	if (reg.reg0.bits.clkin_gate && reg.reg0.bits.clkout_gate)
+		return 1;
+	else
+		return 0;
+}
+
+#ifdef CONFIG_DEBUG_FS
+#include <linux/debugfs.h>
+
+static int aml_clk_dualdiv_available_rates_show(struct seq_file *s, void *data)
+{
+	struct clk_hw *hw = s->private;
+	struct clk_hw *phw = clk_hw_get_parent(hw);
+	struct aml_clk *clk = to_aml_clk(hw);
+	struct aml_clk_dualdiv_data *dualdiv = clk->data;
+	unsigned long rate, prate;
+	unsigned long core_min_rate, core_max_rate;
+	int i;
+
+	if (!phw) {
+		pr_err("%s: can't get parent\n", clk_hw_get_name(hw));
+
+		return -ENOENT;
+	}
+
+	prate = clk_hw_get_rate(phw);
+	clk_hw_get_rate_range(hw, &core_min_rate, &core_max_rate);
+	if (dualdiv->table) {
+		for (i = 0; i < dualdiv->table_count; i++) {
+			rate = aml_dualdiv_param_to_rate(prate,
+							 &dualdiv->table[i]);
+			if (rate < core_min_rate || rate > core_max_rate)
+				continue;
+
+			seq_printf(s, "%ld\n", (unsigned long)rate);
+		}
+	} else {
+		seq_printf(s, "%ld\n", prate);
+	}
+
+	return 0;
+}
+DEFINE_SHOW_ATTRIBUTE(aml_clk_dualdiv_available_rates);
+
+static void aml_clk_dualdiv_debug_init(struct clk_hw *hw, struct dentry *dentry)
+{
+	struct aml_clk *clk = to_aml_clk(hw);
+
+	debugfs_create_file("clk_type", 0444, dentry, hw, &aml_clk_type_fops);
+	if (clk->type == AML_CLKTYPE_DUALDIV)
+		debugfs_create_file("clk_available_rates", 0444, dentry, hw,
+				    &aml_clk_dualdiv_available_rates_fops);
+}
+#endif /* CONFIG_DEBUG_FS */
+
+const struct clk_ops aml_clk_dualdiv_ops = {
+	.enable		= aml_clk_dualdiv_enable,
+	.disable	= aml_clk_dualdiv_disable,
+	.is_enabled	= aml_clk_dualdiv_is_enabled,
+	.recalc_rate	= aml_clk_dualdiv_recalc_rate,
+	.determine_rate	= aml_clk_dualdiv_determine_rate,
+	.set_rate	= aml_clk_dualdiv_set_rate,
+#ifdef CONFIG_DEBUG_FS
+	.debug_init	= aml_clk_dualdiv_debug_init,
+#endif /* CONFIG_DEBUG_FS */
+};
+EXPORT_SYMBOL_NS_GPL(aml_clk_dualdiv_ops, "CLK_AMLOGIC");
+
+MODULE_DESCRIPTION("Amlogic Dualdiv Driver");
+MODULE_AUTHOR("Chuan Liu <chuan.liu@amlogic.com>");
+MODULE_LICENSE("GPL");
+MODULE_IMPORT_NS("CLK_AMLOGIC");
diff --git a/drivers/clk/amlogic/clk-dualdiv.h b/drivers/clk/amlogic/clk-dualdiv.h
new file mode 100644
index 000000000000..fbbae6686afd
--- /dev/null
+++ b/drivers/clk/amlogic/clk-dualdiv.h
@@ -0,0 +1,27 @@
+/* SPDX-License-Identifier: (GPL-2.0-only OR MIT) */
+/*
+ * Copyright (c) 2026 Amlogic, Inc. All rights reserved
+ */
+
+#ifndef __AML_CLK_DUALDIV_H
+#define __AML_CLK_DUALDIV_H
+
+#include <linux/clk-provider.h>
+
+struct aml_clk_dualdiv_param {
+	unsigned int div_mode;
+	unsigned int n0;
+	unsigned int m0;
+	unsigned int n1;
+	unsigned int m1;
+};
+
+struct aml_clk_dualdiv_data {
+	unsigned int			reg_offset;
+	struct	aml_clk_dualdiv_param	*table;
+	unsigned int			table_count;
+};
+
+extern const struct clk_ops aml_clk_dualdiv_ops;
+
+#endif /* __AML_CLK_DUALDIV_MUX_H */
diff --git a/drivers/clk/amlogic/clk.c b/drivers/clk/amlogic/clk.c
index 12e9596668d2..5431aa320dfa 100644
--- a/drivers/clk/amlogic/clk.c
+++ b/drivers/clk/amlogic/clk.c
@@ -23,6 +23,7 @@ static const struct {
 	ENTRY(AML_CLKTYPE_GATE),
 	ENTRY(AML_CLKTYPE_COMPOSITE),
 	ENTRY(AML_CLKTYPE_NOGLITCH),
+	ENTRY(AML_CLKTYPE_DUALDIV),
 #undef ENTRY
 };
 
diff --git a/drivers/clk/amlogic/clk.h b/drivers/clk/amlogic/clk.h
index 14045fa109c0..c1d58a08e407 100644
--- a/drivers/clk/amlogic/clk.h
+++ b/drivers/clk/amlogic/clk.h
@@ -16,6 +16,7 @@ enum aml_clk_type {
 	AML_CLKTYPE_GATE	= 3,
 	AML_CLKTYPE_COMPOSITE	= 4,
 	AML_CLKTYPE_NOGLITCH	= 5,
+	AML_CLKTYPE_DUALDIV	= 6,
 };
 
 struct aml_clk {

-- 
2.42.0

