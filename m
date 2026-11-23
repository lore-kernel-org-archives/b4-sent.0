From: Fil Dunsky <filipp.dunsky@gmail.com>
Date: Mon, 23 Nov 2026 21:41:14 +0300
Subject: [PATCH 3/5] clk: Add Cortina Systems CS7542 strap-selected clocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-cs7542-syscon-v1-3-49858e631449@gmail.com>
References: <20261123-cs7542-syscon-v1-0-49858e631449@gmail.com>
In-Reply-To: <20261123-cs7542-syscon-v1-0-49858e631449@gmail.com>
To: Bartosz Golaszewski <brgl@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Linus Walleij <linusw@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Arnd Bergmann <arnd@arndb.de>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459271; l=5002;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=JEa90SGQ0FgER4S1FcL2NkC7oSwXVNfRbOUFnfhpGuk=;
 b=e0rWIO8xaF7w/JxsQI1xMpXHd7PA0yFu8QyZU0nPuYXJuZbaup7pL+v3doiI2mBjTRi0pqYQ3
 4w6h8Ukd29VAWNQe8XizC1ikSTIqHkjSXy5cPSfa07jcQ2a0Jt0chie
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register APB, CPU and AXI fixed-rate outputs from GLOBAL_STRAP[3:1],
using the seven configurations recorded in the vendor kernel. Reject
the reserved encoding instead of publishing a guessed frequency.

Register before timer initialization and leave the syscon platform node
available for its pinctrl child. Use the shared regmap, only read strap
status, and unwind all registered clocks if provider setup fails. This
is intentionally not a DVFS or programmable PLL driver.

AI assistance: Codex prepared this change from the existing OpenWrt port
and GPL vendor sources.

Signed-off-by: Fil Dunsky <filipp.dunsky@gmail.com>
---
 drivers/clk/Kconfig      |  9 +++++
 drivers/clk/Makefile     |  1 +
 drivers/clk/clk-cs7542.c | 90 ++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 100 insertions(+)

diff --git a/drivers/clk/Kconfig b/drivers/clk/Kconfig
index 37a8e35d4..47b5265fe 100644
--- a/drivers/clk/Kconfig
+++ b/drivers/clk/Kconfig
@@ -58,6 +58,15 @@ config LMK04832
 	  Say yes here to build support for Texas Instruments' LMK04832 Ultra
 	  Low-Noise JESD204B Compliant Clock Jitter Cleaner With Dual Loop PLLs
 
+config COMMON_CLK_CS7542
+	bool "Cortina Systems CS7542 strap-selected clocks"
+	depends on OF && HAS_IOMEM
+	select MFD_SYSCON
+	help
+	  Read the boot straps of the CS7542 global control block to provide
+	  its APB, CPU and AXI clocks. This driver does not change PLLs or
+	  dividers. It is built in because the APB clock is needed by timers.
+
 config COMMON_CLK_APPLE_NCO
 	tristate "Clock driver for Apple SoC NCOs"
 	depends on ARCH_APPLE || COMPILE_TEST
diff --git a/drivers/clk/Makefile b/drivers/clk/Makefile
index 52d138d4f..16b1168c8 100644
--- a/drivers/clk/Makefile
+++ b/drivers/clk/Makefile
@@ -63,6 +63,7 @@ obj-$(CONFIG_ARCH_AXXIA)		+= clk-axm5516.o
 obj-$(CONFIG_COMMON_CLK_BD718XX)	+= clk-bd718x7.o
 obj-$(CONFIG_COMMON_CLK_BM1880)		+= clk-bm1880.o
 obj-$(CONFIG_COMMON_CLK_CDCE706)	+= clk-cdce706.o
+obj-$(CONFIG_COMMON_CLK_CS7542)		+= clk-cs7542.o
 obj-$(CONFIG_COMMON_CLK_CDCE925)	+= clk-cdce925.o
 obj-$(CONFIG_ARCH_CLPS711X)		+= clk-clps711x.o
 obj-$(CONFIG_COMMON_CLK_CS2000_CP)	+= clk-cs2000-cp.o
diff --git a/drivers/clk/clk-cs7542.c b/drivers/clk/clk-cs7542.c
new file mode 100644
index 000000000..4e6c1e98a
--- /dev/null
+++ b/drivers/clk/clk-cs7542.c
@@ -0,0 +1,90 @@
+// SPDX-License-Identifier: GPL-2.0-only
+/* Cortina Systems CS7542 strap-selected clocks */
+
+#include <linux/bitfield.h>
+#include <linux/clk-provider.h>
+#include <linux/err.h>
+#include <linux/init.h>
+#include <linux/mfd/syscon.h>
+#include <linux/of.h>
+#include <linux/printk.h>
+#include <linux/regmap.h>
+#include <linux/slab.h>
+
+#include <dt-bindings/clock/cortina,cs7542-clock.h>
+
+#define CS7542_GLOBAL_STRAP	0x0c
+#define CS7542_STRAP_SPEED	GENMASK(3, 1)
+#define CS7542_NUM_CLKS		3
+
+/* Rates from the GPL vendor kernel's get_platform_clk(). */
+static const unsigned long cs7542_rates[][CS7542_NUM_CLKS] = {
+	/* APB, CPU, AXI */
+	{ 100000000, 400000000, 133333333 },
+	{ 100000000, 600000000, 150000000 },
+	{ 100000000, 700000000, 140000000 },
+	{ 100000000, 800000000, 160000000 },
+	{ 100000000, 900000000, 150000000 },
+	{ 150000000, 750000000, 150000000 },
+	{ 170000000, 850000000, 141666667 },
+};
+
+static const char * const cs7542_clock_names[] = {
+	[CS7542_CLK_APB] = "cs7542-apb",
+	[CS7542_CLK_CPU] = "cs7542-cpu",
+	[CS7542_CLK_AXI] = "cs7542-axi",
+};
+
+static void __init cs7542_clk_init(struct device_node *np)
+{
+	struct clk_hw_onecell_data *data;
+	struct regmap *map;
+	unsigned int strap, speed;
+	int i, ret;
+
+	map = syscon_node_to_regmap(np);
+	if (IS_ERR(map)) {
+		pr_err("%pOF: cannot get global regmap: %ld\n", np, PTR_ERR(map));
+		return;
+	}
+
+	ret = regmap_read(map, CS7542_GLOBAL_STRAP, &strap);
+	if (ret) {
+		pr_err("%pOF: cannot read clock strap: %d\n", np, ret);
+		return;
+	}
+
+	speed = FIELD_GET(CS7542_STRAP_SPEED, strap);
+	if (speed >= ARRAY_SIZE(cs7542_rates)) {
+		pr_err("%pOF: unsupported clock strap %u\n", np, speed);
+		return;
+	}
+
+	data = kzalloc_flex(*data, hws, CS7542_NUM_CLKS);
+	if (!data)
+		return;
+	data->num = CS7542_NUM_CLKS;
+
+	for (i = 0; i < CS7542_NUM_CLKS; i++) {
+		data->hws[i] = clk_hw_register_fixed_rate(NULL,
+							  cs7542_clock_names[i], NULL,
+							  0, cs7542_rates[speed][i]);
+		if (IS_ERR(data->hws[i])) {
+			ret = PTR_ERR(data->hws[i]);
+			goto err_unregister;
+		}
+	}
+
+	ret = of_clk_add_hw_provider(np, of_clk_hw_onecell_get, data);
+	if (!ret)
+		return;
+
+err_unregister:
+	while (i--)
+		clk_hw_unregister_fixed_rate(data->hws[i]);
+	kfree(data);
+	pr_err("%pOF: cannot register clocks: %d\n", np, ret);
+}
+
+/* Timers need APB before platform devices, but the pinctrl child must probe. */
+CLK_OF_DECLARE_DRIVER(cs7542_clk, "cortina,cs7542-syscon", cs7542_clk_init);

-- 
2.53.0

