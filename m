From: Shmuel Melamud <smelamud@redhat.com>
Date: Fri, 30 May 2025 01:58:57 +0300
Subject: [PATCH v2] renesas: Renesas R-Car Gen4 watchdog driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250530-us-renesas-watchdog-v2-1-b0d8f96c64dc@redhat.com>
X-B4-Tracking: v=1; b=H4sIALDmOGgC/x3MSwqFMAxA0a1IxgZKpIhuRRzUJmomVRo/D8S9v
 +LwDO59wCSrGPTVA1kuNd1SAdUVxDWkRVC5GMiRd75xeBpmSWLB8A5HXHlbkGLb8TSxj0xQyj3
 LrL/vOozv+wfIwWnGZQAAAA==
X-Change-ID: 20250530-us-renesas-watchdog-2c79dbbd5cd2
To: Tom Rini <trini@konsulko.com>, Nobuhiro Iwamatsu <iwamatsu@nigauri.org>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Lukasz Majewski <lukma@denx.de>, Sean Anderson <seanga2@gmail.com>, 
 Stefan Roese <sr@denx.de>, Mattijs Korpershoek <mkorpershoek@kernel.org>
Cc: u-boot@lists.denx.de, Shmuel Leib Melamud <smelamud@redhat.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748559539; l=8194;
 i=smelamud@redhat.com; s=20250530; h=from:subject:message-id;
 bh=gfsCbLyHoxkKtDbS5e2d9TDnTRSSLkd3c2DT0B21lx4=;
 b=/JTp5yGS4+BEg3GxKPxh3vWIkzwnhwdu83SZiLdU0UEN63Ac5mYR/jiEy0pYrHJGL8VPgeQ0j
 JA5SjPbq0ikDybs9BoxxxQK3Eu9xopYh/Tkc+jlA1nU9QKCKC618LN9
X-Developer-Key: i=smelamud@redhat.com; a=ed25519;
 pk=B1DFtpdxDPQudtnqMHSFRRSJziu3zB49J6oZUBo0qI8=
X-Endpoint-Received: by B4 Relay for smelamud@redhat.com/20250530 with auth_id=418
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support of Renesas R-Car Gen4 watchdog timer. Timeouts up to
8184.0s are supported (CKS1 register is not involved). The watchdog
uses the clock type CLK_TYPE_GEN4_MDSEL, so handling of this constant
is added to gen3_clk_get_rate64() function.

The timeout is set in
dts/upstream/src/arm64/renesas/r8a779f0-spider-cpu.dtsi section &rwdt.

This patch was tested on real Renesas R8A779F0 hardware. If the watchdog
driver is enabled at the build time, the watchdog timer is initialized
when U-Boot starts. Under normal circumstances, U-Boot loads the kernel,
it starts systemd and systemd continues to pet the watchdog. If systemd
is not started before the timeout expires, the watchdog resets the
board.

Signed-off-by: Shmuel Leib Melamud <smelamud@redhat.com>
---
 drivers/clk/renesas/clk-rcar-gen3.c |   4 +-
 drivers/watchdog/Kconfig            |   8 ++
 drivers/watchdog/Makefile           |   1 +
 drivers/watchdog/renesas_wdt.c      | 172 ++++++++++++++++++++++++++++++++++++
 4 files changed, 184 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/renesas/clk-rcar-gen3.c b/drivers/clk/renesas/clk-rcar-gen3.c
index 375cc4a4930873ad0d5509c19ad04a0ea5545aa0..5745acf4023c9114f6fa13b5e4baa306c5b57d33 100644
--- a/drivers/clk/renesas/clk-rcar-gen3.c
+++ b/drivers/clk/renesas/clk-rcar-gen3.c
@@ -68,7 +68,7 @@ static int gen3_clk_get_parent(struct gen3_clk_priv *priv, struct clk *clk,
 		if (ret)
 			return ret;
 
-		if (core->type == CLK_TYPE_GEN3_MDSEL) {
+		if (core->type == CLK_TYPE_GEN3_MDSEL || core->type == CLK_TYPE_GEN4_MDSEL) {
 			shift = priv->cpg_mode & BIT(core->offset) ? 0 : 16;
 			parent->dev = clk->dev;
 			parent->id = core->parent >> shift;
@@ -318,6 +318,8 @@ static u64 gen3_clk_get_rate64(struct clk *clk)
 						"FIXED");
 
 	case CLK_TYPE_GEN3_MDSEL:
+		fallthrough;
+	case CLK_TYPE_GEN4_MDSEL:
 		shift = priv->cpg_mode & BIT(core->offset) ? 0 : 16;
 		div = (core->div >> shift) & 0xffff;
 		rate = gen3_clk_get_rate64(&parent) / div;
diff --git a/drivers/watchdog/Kconfig b/drivers/watchdog/Kconfig
index 1bb67f5035231df9f6ce01adb08d074855393143..a0f2948335f9c3b74b7823f039e578ff4030e97c 100644
--- a/drivers/watchdog/Kconfig
+++ b/drivers/watchdog/Kconfig
@@ -335,6 +335,14 @@ config WDT_K3_RTI_FW_FILE
 
 endif
 
+config WDT_RENESAS
+	bool "Renesas watchdog timer support"
+	depends on WDT && R8A779F0
+	select CLK
+	select CLK_RENESAS
+	help
+	  Enables Renesas SoC R8A779F0 watchdog timer support.
+
 config WDT_SANDBOX
 	bool "Enable Watchdog Timer support for Sandbox"
 	depends on SANDBOX && WDT
diff --git a/drivers/watchdog/Makefile b/drivers/watchdog/Makefile
index e6bd4c587af6133c405dde6dbada8050debc781c..c4467d6e126d0c3e119bf8014b302e5b1432f541 100644
--- a/drivers/watchdog/Makefile
+++ b/drivers/watchdog/Makefile
@@ -43,6 +43,7 @@ obj-$(CONFIG_WDT_MTK) += mtk_wdt.o
 obj-$(CONFIG_WDT_NPCM) += npcm_wdt.o
 obj-$(CONFIG_WDT_OCTEONTX) += octeontx_wdt.o
 obj-$(CONFIG_WDT_OMAP3) += omap_wdt.o
+obj-$(CONFIG_WDT_RENESAS) += renesas_wdt.o
 obj-$(CONFIG_WDT_SBSA) += sbsa_gwdt.o
 obj-$(CONFIG_WDT_K3_RTI) += rti_wdt.o
 obj-$(CONFIG_WDT_SIEMENS_PMIC) += siemens_pmic_wdt.o
diff --git a/drivers/watchdog/renesas_wdt.c b/drivers/watchdog/renesas_wdt.c
new file mode 100644
index 0000000000000000000000000000000000000000..97550794a2e7108ee63aa0011f55c8c0fa77adb9
--- /dev/null
+++ b/drivers/watchdog/renesas_wdt.c
@@ -0,0 +1,172 @@
+// SPDX-License-Identifier: GPL-2.0+
+// Copyright 2025 Red Hat, Inc., Shmuel Leib Melamud <smelamud@redhat.com>
+
+#include <clk.h>
+#include <dm.h>
+#include <wdt.h>
+#include <asm/io.h>
+#include <dm/device_compat.h>
+#include <linux/delay.h>
+#include <linux/iopoll.h>
+
+#define usleep_range(a, b) udelay((b))
+
+struct renesas_wdt {
+	u32 cnt;
+	u32 csra;
+	u32 csrb;
+};
+
+#define RWTCSRA_WOVF	BIT(4)
+#define RWTCSRA_WRFLG	BIT(5)
+#define RWTCSRA_TME		BIT(7)
+
+#define CSR_MASK	0xA5A5A500
+#define CNT_MASK	0x5A5A0000
+
+/*
+ * In probe, clk_rate is checked to be not more than 16 bit * biggest clock
+ * divider (12 bits). d is only a factor to fully utilize the WDT counter and
+ * will not exceed its 16 bits. Thus, no overflow, we stay below 32 bits.
+ */
+#define MUL_BY_CLKS_PER_SEC(p, d) \
+	DIV_ROUND_UP((d) * (p)->clk_rate, clk_divs[(p)->cks])
+
+/* d is 16 bit, clk_divs 12 bit -> no 32 bit overflow */
+#define DIV_BY_CLKS_PER_SEC(p, d) ((d) * clk_divs[(p)->cks] / (p)->clk_rate)
+
+static const unsigned int clk_divs[] = { 1, 4, 16, 32, 64, 128, 1024, 4096 };
+
+struct renesas_wdt_priv {
+	struct renesas_wdt __iomem *wdt;
+	unsigned long clk_rate;
+	u8 cks;
+	struct clk clk;
+};
+
+static void rwdt_wait_cycles(struct renesas_wdt_priv *priv, unsigned int cycles)
+{
+	unsigned int delay;
+
+	delay = DIV_ROUND_UP(cycles * 1000000, priv->clk_rate);
+
+	usleep_range(delay, 2 * delay);
+}
+
+static int renesas_wdt_start(struct udevice *dev, u64 timeout, ulong flags)
+{
+	struct renesas_wdt_priv *priv = dev_get_priv(dev);
+	u64 max_timeout;
+	u8 val;
+
+	max_timeout = DIV_BY_CLKS_PER_SEC(priv, 65536);
+	timeout = min(max_timeout, timeout / 1000);
+
+	/* Stop the timer before we modify any register */
+	val = readb_relaxed(&priv->wdt->csra) & ~RWTCSRA_TME;
+	writel_relaxed(val | CSR_MASK, &priv->wdt->csra);
+	/* Delay 2 cycles before setting watchdog counter */
+	rwdt_wait_cycles(priv, 2);
+
+	while (readb_relaxed(&priv->wdt->csra) & RWTCSRA_WRFLG)
+		cpu_relax();
+
+	writel_relaxed((65536 - MUL_BY_CLKS_PER_SEC(priv, timeout)) | CNT_MASK,
+		       &priv->wdt->cnt);
+
+	writel_relaxed(priv->cks | RWTCSRA_TME | CSR_MASK, &priv->wdt->csra);
+
+	return 0;
+}
+
+static int renesas_wdt_stop(struct udevice *dev)
+{
+	struct renesas_wdt_priv *priv = dev_get_priv(dev);
+
+	writel_relaxed(priv->cks | CSR_MASK, &priv->wdt->csra);
+
+	return 0;
+}
+
+static int renesas_wdt_reset(struct udevice *dev)
+{
+	struct renesas_wdt_priv *priv = dev_get_priv(dev);
+	u8 val;
+
+	/* Stop the timer before we modify any register */
+	val = readb_relaxed(&priv->wdt->csra) & ~RWTCSRA_TME;
+	writel_relaxed(val | CSR_MASK, &priv->wdt->csra);
+	/* Delay 2 cycles before setting watchdog counter */
+	rwdt_wait_cycles(priv, 2);
+
+	writel_relaxed(0xffff | CNT_MASK, &priv->wdt->cnt);
+	/* smallest divider to reboot soon */
+	writel_relaxed(0 | CSR_MASK, &priv->wdt->csra);
+
+	readb_poll_timeout(&priv->wdt->csra, val, !(val & RWTCSRA_WRFLG), 100);
+
+	writel_relaxed(RWTCSRA_TME | CSR_MASK, &priv->wdt->csra);
+
+	/* wait 2 cycles, so watchdog will trigger */
+	rwdt_wait_cycles(priv, 2);
+
+	return 0;
+}
+
+static int renesas_wdt_probe(struct udevice *dev)
+{
+	struct renesas_wdt_priv *priv = dev_get_priv(dev);
+	unsigned long clks_per_sec;
+	int ret, i;
+
+	priv->wdt = dev_remap_addr(dev);
+	if (!priv->wdt)
+		return -EINVAL;
+
+	ret = clk_get_by_index(dev, 0, &priv->clk);
+	if (ret < 0)
+		return ret;
+
+	ret = clk_enable(&priv->clk);
+	if (ret)
+		return ret;
+
+	priv->clk_rate = clk_get_rate(&priv->clk);
+	if (!priv->clk_rate)
+		return -ENOENT;
+
+	for (i = ARRAY_SIZE(clk_divs) - 1; i >= 0; i--) {
+		clks_per_sec = priv->clk_rate / clk_divs[i];
+		if (clks_per_sec && clks_per_sec < 65536) {
+			priv->cks = i;
+			break;
+		}
+	}
+
+	/* can't find a suitable clock divider */
+	if (i < 0)
+		return -ERANGE;
+
+	return 0;
+}
+
+static const struct wdt_ops renesas_wdt_ops = {
+	.start = renesas_wdt_start,
+	.reset = renesas_wdt_reset,
+	.stop = renesas_wdt_stop,
+};
+
+static const struct udevice_id renesas_wdt_ids[] = {
+	{ .compatible = "renesas,r8a779f0-wdt" },
+	{ .compatible = "renesas,rcar-gen4-wdt" },
+	{}
+};
+
+U_BOOT_DRIVER(wdt_renesas) = {
+	.name = "wdt_renesas",
+	.id = UCLASS_WDT,
+	.of_match = renesas_wdt_ids,
+	.ops = &renesas_wdt_ops,
+	.probe	= renesas_wdt_probe,
+	.priv_auto = sizeof(struct renesas_wdt_priv),
+};

---
base-commit: 3b6760ddeb4ef940226921017cd9088c89784b01
change-id: 20250530-us-renesas-watchdog-2c79dbbd5cd2

Best regards,
-- 
Shmuel Leib Melamud <smelamud@redhat.com>

