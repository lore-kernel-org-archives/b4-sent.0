From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 31 Oct 2025 16:10:11 +0800
Subject: [PATCH v3 4/4] clk: amlogic: Optimize PLL enable timing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251031-optimize_pll_driver-v3-4-92f3b2f36a83@amlogic.com>
References: <20251031-optimize_pll_driver-v3-0-92f3b2f36a83@amlogic.com>
In-Reply-To: <20251031-optimize_pll_driver-v3-0-92f3b2f36a83@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761898227; l=2090;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=3bVoQCKgnuZ/IY+cWp9z2timk+2eNG6PU6hMfKQ9QKc=;
 b=PaR4cC+nx1zlBGR24Xc20vUT2lEJgJbv9J7AWiZu9QbNIDq2BkxtlT0lPMVoKhLR7ofEt/Xpz
 XzFQVzImYksCF6+t+rElWpS5+OSqL/J/xLPNCqFmzWFOpoFoJvkbaTD
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

l_detect controls the enablement of the PLL lock detection module.
It should remain disabled while the internal PLL circuits are
reaching a steady state; otherwise, the lock signal may be falsely
triggered high.

A 20 us delay has been added before enabling the PLL, so there’s no
need for an additional 10 us delay before enabling current_en.

Currently, only A1 supports both l_detect and current_en, so this
patch will only affect A1.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 12 +++++++-----
 1 file changed, 7 insertions(+), 5 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index cdb39a723bd0..c9b941adf688 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -383,6 +383,10 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 	if (MESON_PARM_APPLICABLE(&pll->rst))
 		meson_parm_write(clk->map, &pll->rst, 1);
 
+	/* Disable the PLL lock-detect module */
+	if (MESON_PARM_APPLICABLE(&pll->l_detect))
+		meson_parm_write(clk->map, &pll->l_detect, 1);
+
 	/* Enable the pll */
 	meson_parm_write(clk->map, &pll->en, 1);
 
@@ -401,20 +405,18 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 	 * Compared with the previous SoCs, self-adaption current module
 	 * is newly added for A1, keep the new power-on sequence to enable the
 	 * PLL. The sequence is:
-	 * 1. enable the pll, delay for 10us
+	 * 1. enable the pll, delay for 20us
 	 * 2. enable the pll self-adaption current module, delay for 40us
 	 * 3. enable the lock detect module
 	 */
 	if (MESON_PARM_APPLICABLE(&pll->current_en)) {
-		udelay(10);
 		meson_parm_write(clk->map, &pll->current_en, 1);
 		udelay(40);
 	}
 
-	if (MESON_PARM_APPLICABLE(&pll->l_detect)) {
-		meson_parm_write(clk->map, &pll->l_detect, 1);
+	/* Enable the lock-detect module */
+	if (MESON_PARM_APPLICABLE(&pll->l_detect))
 		meson_parm_write(clk->map, &pll->l_detect, 0);
-	}
 
 	if (meson_clk_pll_wait_lock(hw)) {
 		/* disable PLL when PLL lock failed. */

-- 
2.42.0

