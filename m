From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 20 Sep 2024 16:13:13 +0800
Subject: [PATCH] clk: meson: pll: Update the meson_clk_pll_init execution
 judgment logic
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240920-optimize_pll_flag-v1-1-c90d84a80a51@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAJgu7WYC/x3M0QpAMBSA4VfRubZixOFVJC07m1PD2iSRd7dcf
 hf//0CkwBShzx4IdHLkfUso8wzmRW2WBOtkkIWsi65EsfuDV75p8s5NxikrmhYVopaVQQmp84E
 MX/9zGN/3A4BHfd1jAAAA
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726820026; l=2429;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=Bxi0pv+eCzIxvYRz/WWiwYenjJWhGAFp4yX+VQVeYR0=;
 b=SHfpgZJ0kfXUg89lZ7xFZh4+atixE7c7aAQxxNKPJ4Pj5PBehGSJ/C39ZYFB1y/QIK1IadLCz
 53bEMsO8fveCj1E6BYhN0C3BkiwU/wYlJIhy/UB7GJvLoLoI4Jb/f73
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The hardware property of PLL determines that PLL can only be enabled
after PLL has been initialized. If PLL is not initialized, the
corresponding lock bit will not be set to 1, resulting in
meson_clk_pll_is_enabled() returning "false".

Therefore, if PLL is already enabled, there is no need to repeat
initialization, and the judgment "CLK_MESON_PLL_NOINIT_ENABLED" in
meson_clk_pll_init() appears redundant.

---
The hardware property of PLL determines that PLL can only be enabled
after PLL has been initialized. If PLL is not initialized, the
corresponding lock bit will not be set to 1, resulting in
meson_clk_pll_is_enabled() returning "false".

Therefore, if PLL is already enabled, there is no need to repeat
initialization, and the judgment "CLK_MESON_PLL_NOINIT_ENABLED" in
meson_clk_pll_init() appears redundant.

In actual application scenarios, PLL configuration is determined during
the bootloader phase. If PLL has been configured during the bootloader
phase, you need to add a flag to the kernel to avoid PLL
re-initialization, which will increase the coupling between the kernel
and the bootloader.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/clk-pll.c | 3 +--
 drivers/clk/meson/clk-pll.h | 1 -
 2 files changed, 1 insertion(+), 3 deletions(-)

diff --git a/drivers/clk/meson/clk-pll.c b/drivers/clk/meson/clk-pll.c
index 89f0f04a16ab..8df2add40b57 100644
--- a/drivers/clk/meson/clk-pll.c
+++ b/drivers/clk/meson/clk-pll.c
@@ -316,8 +316,7 @@ static int meson_clk_pll_init(struct clk_hw *hw)
 	 * Keep the clock running, which was already initialized and enabled
 	 * from the bootloader stage, to avoid any glitches.
 	 */
-	if ((pll->flags & CLK_MESON_PLL_NOINIT_ENABLED) &&
-	    meson_clk_pll_is_enabled(hw))
+	if (meson_clk_pll_is_enabled(hw))
 		return 0;
 
 	if (pll->init_count) {
diff --git a/drivers/clk/meson/clk-pll.h b/drivers/clk/meson/clk-pll.h
index 949157fb7bf5..cccbf52808b1 100644
--- a/drivers/clk/meson/clk-pll.h
+++ b/drivers/clk/meson/clk-pll.h
@@ -28,7 +28,6 @@ struct pll_mult_range {
 	}
 
 #define CLK_MESON_PLL_ROUND_CLOSEST	BIT(0)
-#define CLK_MESON_PLL_NOINIT_ENABLED	BIT(1)
 
 struct meson_clk_pll_data {
 	struct parm en;

---
base-commit: 0ef513560b53d499c824b77220c537eafe1df90d
change-id: 20240918-optimize_pll_flag-678a88d23f82

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

