From: Sasha Finkelstein <fnkl.kernel@gmail.com>
Date: Wed, 19 Feb 2025 10:26:58 +0100
Subject: [PATCH 2/5] pmdomain: apple: Add force-disable/force-reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250219-isp-v1-2-6d3e89b67c31@gmail.com>
References: <20250219-isp-v1-0-6d3e89b67c31@gmail.com>
In-Reply-To: <20250219-isp-v1-0-6d3e89b67c31@gmail.com>
To: Sven Peter <sven@svenpeter.dev>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Ulf Hansson <ulf.hansson@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, linux-media@vger.kernel.org, imx@lists.linux.dev, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, Asahi Lina <lina@asahilina.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739957223; l=4185;
 i=fnkl.kernel@gmail.com; s=20241124; h=from:subject:message-id;
 bh=ILeuHWleXhwI4K5IQ/A7AJ/hB6N+vx/m/9DJygdXU5M=;
 b=m7tS+W7n9OmHjO2HKePvd2Pb2y/jUt80l6iQFjZPGrA6pxlU8hO8mTLFM4UA4HHPtNg3pqA8U
 zm+sUIF+HJSCtecFbaEhHLjXcK4/HjcE3vEJ6trTzQ/1LcJAYn4+nfO
X-Developer-Key: i=fnkl.kernel@gmail.com; a=ed25519;
 pk=aSkp1PdZ+eF4jpMO6oLvz/YfT5XkBUneWwyhQrOgmsU=
X-Endpoint-Received: by B4 Relay for fnkl.kernel@gmail.com/20241124 with auth_id=283
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Asahi Lina <lina@asahilina.net>

It seems some ISP power states should have their force disable device
access flag set when powered down (which may avoid this problem, but
we're still figuring that out), and on some bit 12 is also explicitly
set before shutdown. Add two properties to handle this case.

Signed-off-by: Asahi Lina <lina@asahilina.net>
Signed-off-by: Sasha Finkelstein <fnkl.kernel@gmail.com>
---
 drivers/pmdomain/apple/pmgr-pwrstate.c | 43 +++++++++++++++++++++++++++++-----
 1 file changed, 37 insertions(+), 6 deletions(-)

diff --git a/drivers/pmdomain/apple/pmgr-pwrstate.c b/drivers/pmdomain/apple/pmgr-pwrstate.c
index 9467235110f4654e00ab96c25e160e125ef0f3e5..3236d854265c9489cca7affadf4448e8444dd839 100644
--- a/drivers/pmdomain/apple/pmgr-pwrstate.c
+++ b/drivers/pmdomain/apple/pmgr-pwrstate.c
@@ -21,7 +21,8 @@
 #define APPLE_PMGR_AUTO_ENABLE  BIT(28)
 #define APPLE_PMGR_PS_AUTO      GENMASK(27, 24)
 #define APPLE_PMGR_PS_MIN       GENMASK(19, 16)
-#define APPLE_PMGR_PARENT_OFF   BIT(11)
+#define APPLE_PMGR_PS_RESET     BIT(12)
+#define APPLE_PMGR_BUSY         BIT(11)
 #define APPLE_PMGR_DEV_DISABLE  BIT(10)
 #define APPLE_PMGR_WAS_CLKGATED BIT(9)
 #define APPLE_PMGR_WAS_PWRGATED BIT(8)
@@ -44,6 +45,8 @@ struct apple_pmgr_ps {
 	struct regmap *regmap;
 	u32 offset;
 	u32 min_state;
+	bool force_disable;
+	bool force_reset;
 };
 
 #define genpd_to_apple_pmgr_ps(_genpd) container_of(_genpd, struct apple_pmgr_ps, genpd)
@@ -53,7 +56,7 @@ static int apple_pmgr_ps_set(struct generic_pm_domain *genpd, u32 pstate, bool a
 {
 	int ret;
 	struct apple_pmgr_ps *ps = genpd_to_apple_pmgr_ps(genpd);
-	u32 reg;
+	u32 reg, cur;
 
 	ret = regmap_read(ps->regmap, ps->offset, &reg);
 	if (ret < 0)
@@ -64,7 +67,29 @@ static int apple_pmgr_ps_set(struct generic_pm_domain *genpd, u32 pstate, bool a
 		dev_err(ps->dev, "PS %s: powering off with RESET active\n",
 			genpd->name);
 
-	reg &= ~(APPLE_PMGR_AUTO_ENABLE | APPLE_PMGR_FLAGS | APPLE_PMGR_PS_TARGET);
+	if (pstate != APPLE_PMGR_PS_ACTIVE && (ps->force_disable || ps->force_reset)) {
+		u32 reg_pre = reg & ~(APPLE_PMGR_AUTO_ENABLE | APPLE_PMGR_FLAGS);
+
+		if (ps->force_disable)
+			reg_pre |= APPLE_PMGR_DEV_DISABLE;
+		if (ps->force_reset)
+			reg_pre |= APPLE_PMGR_PS_RESET;
+
+		regmap_write(ps->regmap, ps->offset, reg_pre);
+
+		ret = regmap_read_poll_timeout_atomic(
+			ps->regmap, ps->offset, cur,
+			(cur & (APPLE_PMGR_DEV_DISABLE | APPLE_PMGR_PS_RESET)) ==
+			(reg_pre & (APPLE_PMGR_DEV_DISABLE | APPLE_PMGR_PS_RESET)), 1,
+			APPLE_PMGR_PS_SET_TIMEOUT);
+
+		if (ret < 0)
+			dev_err(ps->dev, "PS %s: Failed to set reset/disable bits (now: 0x%x)\n",
+				genpd->name, reg);
+	}
+
+	reg &= ~(APPLE_PMGR_DEV_DISABLE | APPLE_PMGR_PS_RESET |
+		 APPLE_PMGR_AUTO_ENABLE | APPLE_PMGR_FLAGS | APPLE_PMGR_PS_TARGET);
 	reg |= FIELD_PREP(APPLE_PMGR_PS_TARGET, pstate);
 
 	dev_dbg(ps->dev, "PS %s: pwrstate = 0x%x: 0x%x\n", genpd->name, pstate, reg);
@@ -72,16 +97,16 @@ static int apple_pmgr_ps_set(struct generic_pm_domain *genpd, u32 pstate, bool a
 	regmap_write(ps->regmap, ps->offset, reg);
 
 	ret = regmap_read_poll_timeout_atomic(
-		ps->regmap, ps->offset, reg,
-		(FIELD_GET(APPLE_PMGR_PS_ACTUAL, reg) == pstate), 1,
+		ps->regmap, ps->offset, cur,
+		FIELD_GET(APPLE_PMGR_PS_ACTUAL, cur) == pstate, 1,
 		APPLE_PMGR_PS_SET_TIMEOUT);
+
 	if (ret < 0)
 		dev_err(ps->dev, "PS %s: Failed to reach power state 0x%x (now: 0x%x)\n",
 			genpd->name, pstate, reg);
 
 	if (auto_enable) {
 		/* Not all devices implement this; this is a no-op where not implemented. */
-		reg &= ~APPLE_PMGR_FLAGS;
 		reg |= APPLE_PMGR_AUTO_ENABLE;
 		regmap_write(ps->regmap, ps->offset, reg);
 	}
@@ -244,6 +269,12 @@ static int apple_pmgr_ps_probe(struct platform_device *pdev)
 		}
 	}
 
+	if (of_property_read_bool(node, "apple,force-disable"))
+		ps->force_disable = true;
+
+	if (of_property_read_bool(node, "apple,force-reset"))
+		ps->force_reset = true;
+
 	/* Turn on auto-PM if the domain is already on */
 	if (active)
 		regmap_update_bits(regmap, ps->offset, APPLE_PMGR_FLAGS | APPLE_PMGR_AUTO_ENABLE,

-- 
2.48.1

