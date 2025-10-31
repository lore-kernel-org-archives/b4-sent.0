From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 31 Oct 2025 16:10:08 +0800
Subject: [PATCH v3 1/4] clk: amlogic: Fix out-of-range PLL frequency
 setting
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251031-optimize_pll_driver-v3-1-92f3b2f36a83@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761898227; l=991;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=6onhzW3ODDG4bFoHZLKVZ14BJkN4o2IaabjNVGrsFP0=;
 b=y7Jqs7z4QNs/tnWA3pjqpJDu6y8SCyMGOt9v1jYNHZ6CEi+bTOQkabAxtRF0VzG2xjZecfXcr
 Ey9zrxitmMGAFOuk4W44evTpq2JS4qNTWd0Jzg04fNoUjRao6J2tWaX
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the calculated 'm' falls into the range:

    pll->range->max < m < (1 << pll->m.width)

Here an incorrect 'm' value could be obtained, so an additional
condition is added to ensure that the calculated 'm' stays within a
valid range.

Fixes: 8eed1db1adec6 ("clk: meson: pll: update driver for the g12a")
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 1ea6579a760f..629f6af18ea1 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -191,7 +191,7 @@ static int meson_clk_get_pll_range_index(unsigned long rate,
 	*m = meson_clk_get_pll_range_m(rate, parent_rate, *n, pll);
 
 	/* the pre-divider gives a multiplier too big - stop */
-	if (*m >= (1 << pll->m.width))
+	if (*m > pll->range->max || *m >= (1 << pll->m.width))
 		return -EINVAL;
 
 	return 0;

-- 
2.42.0

