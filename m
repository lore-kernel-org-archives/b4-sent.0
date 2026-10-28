From: Jian Hu <jian.hu@amlogic.com>
Date: Wed, 28 Oct 2026 20:44:27 +0800
Subject: [PATCH] clk: meson: Fix PLL enable timing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-fix_enable_timing-v1-1-70f060ec3f2a@amlogic.com>
X-B4-Tracking: v=1; b=H4sIACru4WoC/x2MUQqAIBAFrxL7naAiJV0lIqxWWygLjQiku7fEf
 A3MewUyJsIMXVUg4U2Zjsii6grm1cWAghZ20FI3SupWeHpGjG7acLxopxiENXryzpqFAd6dCTn
 6P/vhfT9ze29gYwAAAA==
X-Change-ID: 20261027-fix_enable_timing-842bfa84d4d4
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793191468; l=2238;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=YfHg1NjHkAGSOc2XXMaHJKDSXCBv1aRkCpS0Jq7/gDQ=;
 b=qTW8KkZNLM3nV9LOBSEEfQv+uKohpmDxYarjmNUCZ87YMmcC+ZjOFJeNXG7A7twBX6tKFMe48
 rrpR1N39P4PDMv+hoT7jDY1Y1lqjTL1eiOqT7SGtztMv14yYImlyOrh
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hardware requires a 50us delay after setting the PLL enable
bit to meet its timing requirements.

Without this delay, GP0 and HIFI PLLs on Amlogic T7, SM1 and C3
may fail to lock under stress testing.

For example, enabling the GP0 PLL at 1512MHz may lose lock and
result in an output I/O error:

echo 1512000000 > /sys/kernel/debug/clk/gp0_pll/clk_rate
echo 1 > /sys/kernel/debug/clk/gp0_pll/clk_prepare_enable
sh: write error: I/O error

Add the required 50us delay after enabling the PLL.

Testing on GXL shows that the PLL works correctly without the
additional delay and continues to lock successfully after the
50us delay is added.

On A1, remove the redundant 10us delay before enabling the
self-adaption current module, as the new PLL enable delay already
covers this timing requirement.

Tested on: T7, C3, S4, AXG, GXL, SM1 and A1.

Fixes: e40c7e3cda07 ("clk: meson: clk-pll: add enable bit")
Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 1ea6579a760f..77ea2960120f 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -368,6 +368,7 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 
 	/* Enable the pll */
 	meson_parm_write(clk->map, &pll->en, 1);
+	udelay(50);
 
 	/* Take the pll out reset */
 	if (MESON_PARM_APPLICABLE(&pll->rst))
@@ -377,12 +378,11 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 	 * Compared with the previous SoCs, self-adaption current module
 	 * is newly added for A1, keep the new power-on sequence to enable the
 	 * PLL. The sequence is:
-	 * 1. enable the pll, delay for 10us
+	 * 1. enable the pll, delay for 50us
 	 * 2. enable the pll self-adaption current module, delay for 40us
 	 * 3. enable the lock detect module
 	 */
 	if (MESON_PARM_APPLICABLE(&pll->current_en)) {
-		udelay(10);
 		meson_parm_write(clk->map, &pll->current_en, 1);
 		udelay(40);
 	}

---
base-commit: 363f97a1ce635b86be7fd263d56a040fbd87bdbb
change-id: 20261027-fix_enable_timing-842bfa84d4d4

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

