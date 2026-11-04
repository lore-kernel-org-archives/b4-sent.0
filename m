From: Jian Hu <jian.hu@amlogic.com>
Date: Wed, 04 Nov 2026 10:13:53 +0800
Subject: [PATCH v2] clk: meson: Fix PLL enable timing
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-fix_enable_timing-v2-1-05cdaf34fcdb@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAOCU6moC/22NQQqDMBBFryKzbkqSioaueo8iEuMkDmgiiYQW8
 e5Nhe7KrN7n/zc7JIyECe7VDhEzJQq+gLxUYCbtHTIaC4PkshFctszSq0evhxn7jRbyjqlaDla
 reiwHZbdGLKXT+ewKT5S2EN/niyy+6c+m/tiyYIK13PKGo7lZqR96mYMjczVhge44jg9Nqm6Dt
 AAAAA==
X-Change-ID: 20261027-fix_enable_timing-842bfa84d4d4
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Stephen Boyd <sboyd@kernel.org>, 
 Brian Masney <bmasney+clk@redhat.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Dmitry Rokosov <ddrokosov@sberdevices.ru>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793758448; l=2881;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=xxrXTMztdBF0a6VBQPK0bEnfAifBskZXSA2NITGHqh4=;
 b=3C/aE4+3IjlZRhPCE2+cmWyBrKfwj3h7F6xGKTAv7WFzD7Xvq/R7XnrXwbaqnesEhZ/KTy9XC
 HvDa3fB608+Bphq7/Q9ei3vd0wOxU7GPwFeplrgBqV81rLq7WR33XbQ
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hardware requires a 50us delay after setting the PLL enable
bit to allow the PLL power-up sequence to complete.

Without this delay, GP0 and HIFI PLLs on Amlogic T7, SM1 and C3
may fail to lock under stress testing.

Add a 50us delay after enabling the PLL and another 50us delay
after deasserting the PLL reset.

Testing on GXL shows that the PLL works correctly without the
additional delay and continues to lock successfully after the
50us delay is added.

On A1, remove the redundant 10us delay before enabling the
self-adaption current module, as the new PLL enable delay already
covers this timing requirement.

Fixes: b6ec400aa153 ("clk: meson: introduce new pll power-on sequence for A1 SoC family")
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
For example, enabling the GP0 PLL at 1512MHz may lose lock and
result in an output I/O error:

echo 1512000000 > /sys/kernel/debug/clk/gp0_pll/clk_rate
echo 1 > /sys/kernel/debug/clk/gp0_pll/clk_prepare_enable
sh: write error: I/O error

Tested on: T7, C3, S4, AXG, GXL, SM1 and A1.
---
Changes in v2:
- Combine Chuan's patch to this patch.
- Update the Fixes tag.
- Move test details below the commit message.
- Link to Chuan's patch: https://lore.kernel.org/all/20251031-optimize_pll_driver-v3-2-92f3b2f36a83@amlogic.com
- Link to v1: https://lore.kernel.org/r/20261028-fix_enable_timing-v1-1-70f060ec3f2a@amlogic.com
---
 drivers/clk/meson/clk-pll.c | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 1ea6579a760f..477eb9958a8d 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -369,20 +369,25 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 	/* Enable the pll */
 	meson_parm_write(clk->map, &pll->en, 1);
 
+	/* Wait for the PLL power-up sequence to complete */
+	udelay(50);
+
 	/* Take the pll out reset */
-	if (MESON_PARM_APPLICABLE(&pll->rst))
+	if (MESON_PARM_APPLICABLE(&pll->rst)) {
 		meson_parm_write(clk->map, &pll->rst, 0);
+		/* Wait for the PLL loop to stabilize */
+		udelay(50);
+	}
 
 	/*
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

