From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 06 Sep 2024 13:52:36 +0800
Subject: [PATCH 4/4] clk: meson: s4: pll: hifi_pll frequency is not
 accurate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-fix_clk-v1-4-2977ef0d72e7@amlogic.com>
References: <20240906-fix_clk-v1-0-2977ef0d72e7@amlogic.com>
In-Reply-To: <20240906-fix_clk-v1-0-2977ef0d72e7@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725601955; l=856;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=ro5ykdJDKk3Y3xDmm5Xm1OoCgPIR4AFyD2bYCkCFPEE=;
 b=IZ/yVuY2wLIpYN/mhZKmh78eSRhQWPOQXk6dCtA0gTmfYzo0NItf/y9PgHvE5d6fhK5WadFzv
 FjJPFyhAp4AAYn5pGpB2DtD/haOcypyrWQKn+SK+pRys+RXlfwNHg5p
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fractional denominator of S4's hifi_pll fractional multiplier is
fixed to 100000, so flag CLK_MESON_PLL_FIXED_FRAC_MAX is added.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/s4-pll.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/meson/s4-pll.c b/drivers/clk/meson/s4-pll.c
index a97e19057b05..a793ac2e8cc7 100644
--- a/drivers/clk/meson/s4-pll.c
+++ b/drivers/clk/meson/s4-pll.c
@@ -371,7 +371,8 @@ static struct clk_regmap s4_hifi_pll_dco = {
 		.range = &s4_gp0_pll_mult_range,
 		.init_regs = s4_hifi_init_regs,
 		.init_count = ARRAY_SIZE(s4_hifi_init_regs),
-		.flags = CLK_MESON_PLL_ROUND_CLOSEST,
+		.flags = CLK_MESON_PLL_ROUND_CLOSEST |
+			 CLK_MESON_PLL_FIXED_FRAC_MAX,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hifi_pll_dco",

-- 
2.42.0

