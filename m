From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 06 Sep 2024 13:52:35 +0800
Subject: [PATCH 3/4] clk: meson: s4: pll: hifi_pll support fractional
 multiplier
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240906-fix_clk-v1-3-2977ef0d72e7@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725601955; l=1150;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=9arg64z8UgGz40ls665ct4U5mW7FxNd6ZQXnRFwYvkw=;
 b=IogfYnGomgoFnpWnEW+aCeCWGoCRu5sjduQc9ITv14leLMU9GP9TTYlf8pekBb+LXLIr543YO
 OhNH1AkivSsAjqqOQYQGUTeWrKmzZRYalqnckEaeovZLnZ6Hg/9bc83
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The s4's hifi_pll supports a fractional frequency multiplier, but frac
parameters are not configured in the driver.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/s4-pll.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/drivers/clk/meson/s4-pll.c b/drivers/clk/meson/s4-pll.c
index b0258933fb9d..a97e19057b05 100644
--- a/drivers/clk/meson/s4-pll.c
+++ b/drivers/clk/meson/s4-pll.c
@@ -329,7 +329,6 @@ static struct clk_regmap s4_gp0_pll = {
  * Internal hifi pll emulation configuration parameters
  */
 static const struct reg_sequence s4_hifi_init_regs[] = {
-	{ .reg = ANACTRL_HIFIPLL_CTRL1,	.def = 0x00010e56 },
 	{ .reg = ANACTRL_HIFIPLL_CTRL2,	.def = 0x00000000 },
 	{ .reg = ANACTRL_HIFIPLL_CTRL3,	.def = 0x6a285c00 },
 	{ .reg = ANACTRL_HIFIPLL_CTRL4,	.def = 0x65771290 },
@@ -354,6 +353,11 @@ static struct clk_regmap s4_hifi_pll_dco = {
 			.shift   = 10,
 			.width   = 5,
 		},
+		.frac = {
+			.reg_off = ANACTRL_HIFIPLL_CTRL1,
+			.shift   = 0,
+			.width   = 17,
+		},
 		.l = {
 			.reg_off = ANACTRL_HIFIPLL_CTRL0,
 			.shift   = 31,

-- 
2.42.0

