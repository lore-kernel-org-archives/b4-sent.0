From: Chuan Liu <chuan.liu@amlogic.com>
Date: Thu, 30 Oct 2025 13:24:12 +0800
Subject: [PATCH v2 2/5] clk: amlogic: Improve the issue of PLL lock
 failures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-optimize_pll_driver-v2-2-37273f5b25ab@amlogic.com>
References: <20251030-optimize_pll_driver-v2-0-37273f5b25ab@amlogic.com>
In-Reply-To: <20251030-optimize_pll_driver-v2-0-37273f5b25ab@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>, da@libre.computer
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761801855; l=1329;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=By36+5Xc3F4ZCx2+oODMEZ/7arVOVHo8uzE39j79UAI=;
 b=uZ6pe/g6+Kcpzahmm37OY/aCUYb8QAGsQ9XhgLK57CE/ZIYOWn0w0solOn5GWD1DFWNqs20OZ
 DbfMN8DGCptAdPPnCDKIoA1yjDdyQRO7hVdZKe6PPNqGayQVvll6NrY
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Due to factors such as temperature and process variations, the
internal circuits of the PLL may require a longer time to reach a
steady state, which can result in occasional lock failures on some
SoCs under low-temperature conditions.

After enabling the PLL and releasing its reset, a 20 us delay is
added at each step to provide enough time for the internal PLL
circuit to stabilize, thus reducing the probability of PLL lock
failure.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 629f6af18ea1..f81ebf6cc981 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -368,11 +368,16 @@ static int meson_clk_pll_enable(struct clk_hw *hw)
 
 	/* Enable the pll */
 	meson_parm_write(clk->map, &pll->en, 1);
+	/* Wait for Bandgap and LDO to power up and stabilize */
+	udelay(20);
 
 	/* Take the pll out reset */
 	if (MESON_PARM_APPLICABLE(&pll->rst))
 		meson_parm_write(clk->map, &pll->rst, 0);
 
+	/* Wait for PLL loop stabilization */
+	udelay(20);
+
 	/*
 	 * Compared with the previous SoCs, self-adaption current module
 	 * is newly added for A1, keep the new power-on sequence to enable the

-- 
2.42.0

