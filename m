From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 robh@kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org
Cc: rva333@protonmail.com, amergnat@baylibre.com, me@adomerle.pw, 
 devicetree@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, phone-devel@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v5 2/3] soc: mediatek: mtk-pmic-pwrap: Skip WDT source and
 init on arbiter SoCs
Date: Sat, 28 Nov 2026 04:36:31 +0000
Message-Id: <20261128043629.67417-3-iasnezhkov@gmail.com>
In-Reply-To: <20261128043629.67417-1-iasnezhkov@gmail.com>
References: <20261128043629.67417-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795840589; l=3153;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=Olk5p4P7Ta5NkxLPdczqkMU6NbZVlJ+bSIfjfAU8K+w=;
 b=09LCe56FcQeyMWpC9kqoszJZEOLPk9XlVF/qbSz6ukumQiMkr0Y4A9RNiVGIlx6hhDQkIRBIv
 NRlGn5H1cqlA4dSzAgFOLZysOjWhpNFq4PsvUAgx2oQ5i4zi59yXXd7
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 9d498d0b4043 ("soc: mediatek: pwrap: add arbiter capability")
added PWRAP_CAP_ARB for PMIF-SPI arbiter SoCs (MT6873, MT8195, and the
upcoming MT6789), where the bootloader already initializes the wrapper
and the watchdog registers (PWRAP_WDT_UNIT, PWRAP_WDT_SRC_EN, and
PWRAP_WDT_SRC_EN_1) are absent from the per-SoC register tables.

However, pwrap_probe() only guarded PWRAP_WDT_UNIT with
!HAS_CAP(wrp->master->caps, PWRAP_CAP_ARB), leaving the writes to
PWRAP_WDT_SRC_EN and PWRAP_WDT_SRC_EN_1 unconditional. Because omitted
entries in static const int regs[] default to 0, those writes land at
offset 0x0 (PWRAP_INIT_DONE2) and overwrite it with wdt_src
(0xffffffff) on every probe. Similarly, falling into pwrap_init() on
PWRAP_CAP_ARB SoCs would write legacy non-arbiter registers whose
offsets also default to 0x0.

Extend the !HAS_CAP(wrp->master->caps, PWRAP_CAP_ARB) guard in
pwrap_probe() to cover PWRAP_WDT_SRC_EN, PWRAP_WDT_SRC_EN_1, and the
cold pwrap_init() fallback.

Fixes: 9d498d0b4043 ("soc: mediatek: pwrap: add arbiter capability")
Signed-off-by: Ilia Snezhkov <iasnezhkov@gmail.com>
---
Changes since v4:
- Rebased onto linux-next (after dev_err_probe() conversion in
  pwrap_probe()).

Added in v3. Drafted with an AI coding assistant.

 drivers/soc/mediatek/mtk-pmic-wrap.c | 21 ++++++++++++---------
 1 file changed, 12 insertions(+), 9 deletions(-)

diff --git a/drivers/soc/mediatek/mtk-pmic-wrap.c b/drivers/soc/mediatek/mtk-pmic-wrap.c
index 11f6f30..bdc0f90 100644
--- a/drivers/soc/mediatek/mtk-pmic-wrap.c
+++ b/drivers/soc/mediatek/mtk-pmic-wrap.c
@@ -2553,7 +2553,8 @@ static int pwrap_probe(struct platform_device *pdev)
 	 * The PMIC could already be initialized by the bootloader.
 	 * Skip initialization here in this case.
 	 */
-	if (!pwrap_readl(wrp, PWRAP_INIT_DONE2)) {
+	if (!HAS_CAP(wrp->master->caps, PWRAP_CAP_ARB) &&
+	    !pwrap_readl(wrp, PWRAP_INIT_DONE2)) {
 		ret = pwrap_init(wrp);
 		if (ret)
 			return dev_err_probe(wrp->dev, ret, "init failed\n");
@@ -2571,16 +2572,18 @@ static int pwrap_probe(struct platform_device *pdev)
 				     "initialization isn't finished\n");
 
 	/* Initialize watchdog, may not be done by the bootloader */
-	if (!HAS_CAP(wrp->master->caps, PWRAP_CAP_ARB))
+	if (!HAS_CAP(wrp->master->caps, PWRAP_CAP_ARB)) {
 		pwrap_writel(wrp, 0xf, PWRAP_WDT_UNIT);
 
-	/*
-	 * Since STAUPD was not used on mt8173 platform,
-	 * so STAUPD of WDT_SRC which should be turned off
-	 */
-	pwrap_writel(wrp, wrp->master->wdt_src, PWRAP_WDT_SRC_EN);
-	if (HAS_CAP(wrp->master->caps, PWRAP_CAP_WDT_SRC1))
-		pwrap_writel(wrp, wrp->master->wdt_src, PWRAP_WDT_SRC_EN_1);
+		/*
+		 * Since STAUPD was not used on mt8173 platform,
+		 * so STAUPD of WDT_SRC which should be turned off
+		 */
+		pwrap_writel(wrp, wrp->master->wdt_src, PWRAP_WDT_SRC_EN);
+		if (HAS_CAP(wrp->master->caps, PWRAP_CAP_WDT_SRC1))
+			pwrap_writel(wrp, wrp->master->wdt_src,
+				     PWRAP_WDT_SRC_EN_1);
+	}
 
 	if (HAS_CAP(wrp->master->caps, PWRAP_CAP_ARB))
 		pwrap_writel(wrp, 0x3, PWRAP_TIMER_EN);
-- 
2.54.0 (Apple Git-157)


