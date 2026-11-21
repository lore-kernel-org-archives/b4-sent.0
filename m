From: Han Gao <gaohan@iscas.ac.cn>
Date: Sat, 21 Nov 2026 18:38:08 +0800
Subject: [PATCH 2/2] clk: sophgo: sg2042-clkgen: Keep gates of reserved
 devices enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-b4-sg2042-efi-rtc-v1-2-19898b8ad497@iscas.ac.cn>
References: <20261121-b4-sg2042-efi-rtc-v1-0-19898b8ad497@iscas.ac.cn>
In-Reply-To: <20261121-b4-sg2042-efi-rtc-v1-0-19898b8ad497@iscas.ac.cn>
To: Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Albert Ou <aou@eecs.berkeley.edu>, Alexandre Ghiti <alex@ghiti.fr>, 
 Atish Patra <atish.patra@linux.dev>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Chen Wang <chen.wang@linux.dev>, 
 Inochi Amaoto <inochiama@gmail.com>
Cc: Han Gao <rabenda.cn@gmail.com>, linux-efi@vger.kernel.org, 
 linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-clk@vger.kernel.org, sophgo@lists.linux.dev, 
 Han Gao <gaohan@iscas.ac.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795257496; l=2910;
 i=gaohan@iscas.ac.cn; s=20261021; h=from:subject:message-id;
 bh=FkwMGNzzFP9SAcLoWWEAD8DpNa60dTDRuCtVoBpvCok=;
 b=q3erWT1fwlHrNACKyfuHpCkIL80XgAGDT0V7qQ9mS+QUbZiQmrTwvliwagyujW22SWx/sZF6H
 bwT8bv9x9O2AhcQ4V7L6UQij2B8Mnqdpeu0VWzecd1SoDkGktQ2wX4c
X-Developer-Key: i=gaohan@iscas.ac.cn; a=ed25519;
 pk=J8WHEK3filS86QaCaIHDGafqhxKyQ4K7+vFgRirTIiY=
X-Endpoint-Received: by B4 Relay for gaohan@iscas.ac.cn/20261021 with auth_id=1262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Milk-V Pioneer, firmware can own I2C0 to back the EFI RTC, with the
node marked status = "reserved". I2C0 shares GATE_CLK_APB_I2C with the
I2C controllers Linux uses. When those runtime-suspend, the gate is
switched off under the firmware and GetTime() returns EFI_NOT_READY.

Walk the reserved children of /soc and match their clock references,
as done in commit 6aa175476490 ("clk: renesas: cpg-mssr: Ignore all
clocks assigned to non-Linux system"). Unlike that driver, use
CLK_IS_CRITICAL rather than CLK_IGNORE_UNUSED: the gate is shared with
devices Linux drives, and their runtime PM would still turn it off.

Signed-off-by: Han Gao <gaohan@iscas.ac.cn>
---
 drivers/clk/sophgo/clk-sg2042-clkgen.c | 38 +++++++++++++++++++++++++++++++++-
 1 file changed, 37 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/sophgo/clk-sg2042-clkgen.c b/drivers/clk/sophgo/clk-sg2042-clkgen.c
index 6abc2c973c49..414904965edf 100644
--- a/drivers/clk/sophgo/clk-sg2042-clkgen.c
+++ b/drivers/clk/sophgo/clk-sg2042-clkgen.c
@@ -11,6 +11,8 @@
 #include <linux/clk.h>
 #include <linux/clk-provider.h>
 #include <linux/io.h>
+#include <linux/of.h>
+#include <linux/of_clk.h>
 #include <linux/platform_device.h>
 #include <asm/div64.h>
 
@@ -840,6 +842,35 @@ static int sg2042_clk_register_divs(struct device *dev,
 	return ret;
 }
 
+static bool sg2042_clk_is_reserved(struct device_node *clkgen, unsigned int id)
+{
+	struct device_node *soc __free(device_node) = of_find_node_by_path("/soc");
+	struct device_node *node;
+
+	for_each_reserved_child_of_node(soc, node) {
+		unsigned int i, count = of_clk_get_parent_count(node);
+
+		for (i = 0; i < count; i++) {
+			struct of_phandle_args clkspec;
+			bool match;
+
+			if (of_parse_phandle_with_args(node, "clocks", "#clock-cells",
+						       i, &clkspec))
+				continue;
+
+			match = clkspec.np == clkgen && clkspec.args_count == 1 &&
+				clkspec.args[0] == id;
+			of_node_put(clkspec.np);
+			if (match) {
+				of_node_put(node);
+				return true;
+			}
+		}
+	}
+
+	return false;
+}
+
 static int sg2042_clk_register_gates(struct device *dev,
 				     struct sg2042_clk_data *clk_data,
 				     const struct sg2042_gate_clock gate_clks[],
@@ -850,7 +881,12 @@ static int sg2042_clk_register_gates(struct device *dev,
 	int i, ret = 0;
 
 	for (i = 0; i < num_gate_clks; i++) {
+		unsigned long flags;
+
 		gate = &gate_clks[i];
+		flags = gate->hw.init->flags;
+		if (sg2042_clk_is_reserved(dev->of_node, gate->id))
+			flags |= CLK_IS_CRITICAL;
 		hw = __devm_clk_hw_register_gate
 			(dev,
 			 NULL,
@@ -858,7 +894,7 @@ static int sg2042_clk_register_gates(struct device *dev,
 			 NULL,
 			 gate->hw.init->parent_hws[0],
 			 NULL,
-			 gate->hw.init->flags,
+			 flags,
 			 clk_data->iobase + gate->offset_enable,
 			 gate->bit_idx,
 			 0,

-- 
2.55.0

