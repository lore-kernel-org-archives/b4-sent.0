From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Mon, 03 Jun 2024 18:04:33 +0800
Subject: [PATCH] clk: meson: s4: fix fixed_pll_dco clock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240603-s4_fixedpll-v1-1-2b2a98630841@amlogic.com>
X-B4-Tracking: v=1; b=H4sIADCVXWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDMwNj3WKT+LTMitSUgpwcXWNLo6QkM6PUZEtzCyWgjoKiVJAcyLTo2Np
 aAPgIUCtdAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Yu Tu <yu.tu@amlogic.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717409074; l=969;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=SOD0rIzjB9of1yjvijBbI9sErwBPGjkFM4JLYIAkE/M=;
 b=EWCSOcnNVVrdnL4wLFgNl2+yIEH8TlQrvcy01wiM/tm0IMyHU3b5njMf9swxD3EF8sp0fC7I7
 SQIYVaOz7myArhV3xPZMCbNAf8qNc/P/MP4qsyCyZEF6SHCnNBeF3vx
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fixed_pll_dco output frequency is not accurate,
add frac factor for fixed_pll_dco clk to fix it.

Fixes: 57b55c76aaf1 ("clk: meson: S4: add support for Amlogic S4 SoC peripheral clock controller")
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/clk/meson/s4-pll.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/clk/meson/s4-pll.c b/drivers/clk/meson/s4-pll.c
index 8dfaeccaadc2..47c0c105e32d 100644
--- a/drivers/clk/meson/s4-pll.c
+++ b/drivers/clk/meson/s4-pll.c
@@ -38,6 +38,11 @@ static struct clk_regmap s4_fixed_pll_dco = {
 			.shift   = 0,
 			.width   = 8,
 		},
+		.frac = {
+			.reg_off = ANACTRL_FIXPLL_CTRL1,
+			.shift   = 0,
+			.width   = 17,
+		},
 		.n = {
 			.reg_off = ANACTRL_FIXPLL_CTRL0,
 			.shift   = 10,

---
base-commit: ba535bce57e71463a86f8b33a0ea88c26e3a6418
change-id: 20240603-s4_fixedpll-392bb62ec978

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

