From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 11 Nov 2024 17:37:28 +0800
Subject: [PATCH] clk: meson: Fix children of ro_clk may be tampered with
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241111-fix_childclk_of_roclk_has_been_tampered_with-v1-1-f8c1b6ffdcb0@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAFfQMWcC/x2NwQrCMBBEf6Xs2YCJJYK/IrKkm61ZrEnZFBVK/
 72pc5p3eDMrVFbhCrduBeWPVCm5gT11QCnkJxuJjcGdXW9bzCg/pCRTpOmFZUQtR0mh4sCccQn
 vmZUjfmVJxts4EHl3ufYe2uSs3Pz/3f2xbTsnulnBfgAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jian Hu <jian.hu@amlogic.com>, Dmitry Rokosov <ddrokosov@sberdevices.ru>, 
 Yu Tu <yu.tu@amlogic.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731317850; l=13683;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=YxXioEaTtbKEjn0qaJusuyt0oVp19SJ+e2gENpuSvCg=;
 b=lve99QSTWeR4830u6P+GXxi4kW75eZvQBMZfogiMVdx3BYUicBNbWSh8Yy3jJQksisGuhnS+i
 +T6eAG1B1fTCoAiv5qtC73I0kW+poQV5eLDef2UNgavxvAzkx/7OuO6
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When setting the rate of a clock using clk_regmap_divider_ro_ops, the
rate of its children may be tampered with.

Fixes: 84af914404db ("clk: meson: a1: add Amlogic A1 Peripherals clock controller driver")
Fixes: 87173557d2f6 ("clk: meson: clk-pll: remove od parameters")
Fixes: 085a4ea93d54 ("clk: meson: g12a: add peripheral clock controller")
Fixes: 64aa7008e957 ("clk: meson: add a driver for the Meson8/8b/8m2 DDR clock controller")
Fixes: 57b55c76aaf1 ("clk: meson: S4: add support for Amlogic S4 SoC peripheral clock controller")
Fixes: e787c9c55eda ("clk: meson: S4: add support for Amlogic S4 SoC PLL clock driver")
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Background: During the execution of clk_set_rate(), the function 
clk_core_round_rate_nolock() is called to calculate the matching rate
and save it to 'core->new_rate'. At the same time, it recalculates and
updates its 'child->newrate'. Finally, clk_change_rate() is called to
set all 'new_rates'.

In clk_regmap_divider_ro_ops, there is an implementation of
'determine_rate'. If a clock (name as 'ro_divider') that references
clk_regmap_divider_ro_ops is not configured with CLK_DIVIDER_READ_ONLY,
it will result in the calculation of an incorrect core->new_rate and
potentially tamper with child->newrate, ultimately leading to the
corruption of the rate for 'ro_divider's' children.
---
 drivers/clk/meson/a1-peripherals.c |  2 ++
 drivers/clk/meson/axg.c            |  5 +++--
 drivers/clk/meson/g12a.c           | 23 ++++++++++++++---------
 drivers/clk/meson/gxbb.c           | 18 ++++++++++--------
 drivers/clk/meson/meson8-ddr.c     |  2 +-
 drivers/clk/meson/meson8b.c        |  4 +++-
 drivers/clk/meson/s4-peripherals.c |  2 ++
 drivers/clk/meson/s4-pll.c         |  2 +-
 8 files changed, 36 insertions(+), 22 deletions(-)

diff --git a/drivers/clk/meson/a1-peripherals.c b/drivers/clk/meson/a1-peripherals.c
index 7aa6abb2eb1f..eedf7c2bf970 100644
--- a/drivers/clk/meson/a1-peripherals.c
+++ b/drivers/clk/meson/a1-peripherals.c
@@ -266,6 +266,7 @@ static struct clk_regmap sys_b_div = {
 		.offset = SYS_CLK_CTRL0,
 		.shift = 16,
 		.width = 10,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_b_div",
@@ -314,6 +315,7 @@ static struct clk_regmap sys_a_div = {
 		.offset = SYS_CLK_CTRL0,
 		.shift = 0,
 		.width = 10,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_a_div",
diff --git a/drivers/clk/meson/axg.c b/drivers/clk/meson/axg.c
index 1b08daf579b2..eb86c4d10046 100644
--- a/drivers/clk/meson/axg.c
+++ b/drivers/clk/meson/axg.c
@@ -71,7 +71,7 @@ static struct clk_regmap axg_fixed_pll = {
 		.offset = HHI_MPLL_CNTL,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll",
@@ -130,7 +130,7 @@ static struct clk_regmap axg_sys_pll = {
 		.offset = HHI_SYS_PLL_CNTL,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_pll",
@@ -471,6 +471,7 @@ static struct clk_regmap axg_mpll_prediv = {
 		.offset = HHI_MPLL_CNTL5,
 		.shift = 12,
 		.width = 1,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll_prediv",
diff --git a/drivers/clk/meson/g12a.c b/drivers/clk/meson/g12a.c
index d3539fe9f7af..c7c9fdfd021f 100644
--- a/drivers/clk/meson/g12a.c
+++ b/drivers/clk/meson/g12a.c
@@ -76,7 +76,7 @@ static struct clk_regmap g12a_fixed_pll = {
 		.offset = HHI_FIX_PLL_CNTL0,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll",
@@ -443,6 +443,7 @@ static struct clk_regmap g12a_cpu_clk_mux1_div = {
 		.offset = HHI_SYS_CPU_CLK_CNTL0,
 		.shift = 20,
 		.width = 6,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "cpu_clk_dyn1_div",
@@ -627,6 +628,7 @@ static struct clk_regmap g12b_cpub_clk_mux1_div = {
 		.offset = HHI_SYS_CPUB_CLK_CNTL,
 		.shift = 20,
 		.width = 6,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "cpub_clk_dyn1_div",
@@ -746,6 +748,7 @@ static struct clk_regmap sm1_dsu_clk_mux0_div = {
 		.offset = HHI_SYS_CPU_CLK_CNTL5,
 		.shift = 4,
 		.width = 6,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "dsu_clk_dyn0_div",
@@ -781,6 +784,7 @@ static struct clk_regmap sm1_dsu_clk_mux1_div = {
 		.offset = HHI_SYS_CPU_CLK_CNTL5,
 		.shift = 20,
 		.width = 6,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "dsu_clk_dyn1_div",
@@ -1198,7 +1202,7 @@ static struct clk_regmap g12a_cpu_clk_apb_div = {
 		.offset = HHI_SYS_CPU_CLK_CNTL1,
 		.shift = 3,
 		.width = 3,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "cpu_clk_apb_div",
@@ -1232,7 +1236,7 @@ static struct clk_regmap g12a_cpu_clk_atb_div = {
 		.offset = HHI_SYS_CPU_CLK_CNTL1,
 		.shift = 6,
 		.width = 3,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "cpu_clk_atb_div",
@@ -1266,7 +1270,7 @@ static struct clk_regmap g12a_cpu_clk_axi_div = {
 		.offset = HHI_SYS_CPU_CLK_CNTL1,
 		.shift = 9,
 		.width = 3,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "cpu_clk_axi_div",
@@ -1300,7 +1304,7 @@ static struct clk_regmap g12a_cpu_clk_trace_div = {
 		.offset = HHI_SYS_CPU_CLK_CNTL1,
 		.shift = 20,
 		.width = 3,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "cpu_clk_trace_div",
@@ -1736,7 +1740,7 @@ static struct clk_regmap sm1_gp1_pll = {
 		.shift = 16,
 		.width = 3,
 		.flags = (CLK_DIVIDER_POWER_OF_TWO |
-			  CLK_DIVIDER_ROUND_CLOSEST),
+			  CLK_DIVIDER_ROUND_CLOSEST | CLK_DIVIDER_READ_ONLY),
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "gp1_pll",
@@ -1999,7 +2003,7 @@ static struct clk_regmap g12a_hdmi_pll_od = {
 		.offset = HHI_HDMI_PLL_CNTL0,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_od",
@@ -2017,7 +2021,7 @@ static struct clk_regmap g12a_hdmi_pll_od2 = {
 		.offset = HHI_HDMI_PLL_CNTL0,
 		.shift = 18,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_od2",
@@ -2035,7 +2039,7 @@ static struct clk_regmap g12a_hdmi_pll = {
 		.offset = HHI_HDMI_PLL_CNTL0,
 		.shift = 20,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll",
@@ -4048,6 +4052,7 @@ static struct clk_regmap g12a_ts_div = {
 		.offset = HHI_TS_CLK_CNTL,
 		.shift = 0,
 		.width = 8,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "ts_div",
diff --git a/drivers/clk/meson/gxbb.c b/drivers/clk/meson/gxbb.c
index 262c318edbd5..e2b419100e0c 100644
--- a/drivers/clk/meson/gxbb.c
+++ b/drivers/clk/meson/gxbb.c
@@ -131,7 +131,7 @@ static struct clk_regmap gxbb_fixed_pll = {
 		.offset = HHI_MPLL_CNTL,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll",
@@ -267,7 +267,7 @@ static struct clk_regmap gxbb_hdmi_pll_od = {
 		.offset = HHI_HDMI_PLL_CNTL2,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_od",
@@ -285,7 +285,7 @@ static struct clk_regmap gxbb_hdmi_pll_od2 = {
 		.offset = HHI_HDMI_PLL_CNTL2,
 		.shift = 22,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_od2",
@@ -303,7 +303,7 @@ static struct clk_regmap gxbb_hdmi_pll = {
 		.offset = HHI_HDMI_PLL_CNTL2,
 		.shift = 18,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll",
@@ -321,7 +321,7 @@ static struct clk_regmap gxl_hdmi_pll_od = {
 		.offset = HHI_HDMI_PLL_CNTL + 8,
 		.shift = 21,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_od",
@@ -339,7 +339,7 @@ static struct clk_regmap gxl_hdmi_pll_od2 = {
 		.offset = HHI_HDMI_PLL_CNTL + 8,
 		.shift = 23,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll_od2",
@@ -357,7 +357,7 @@ static struct clk_regmap gxl_hdmi_pll = {
 		.offset = HHI_HDMI_PLL_CNTL + 8,
 		.shift = 19,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "hdmi_pll",
@@ -413,7 +413,7 @@ static struct clk_regmap gxbb_sys_pll = {
 		.offset = HHI_SYS_PLL_CNTL,
 		.shift = 10,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "sys_pll",
@@ -703,6 +703,7 @@ static struct clk_regmap gxbb_mpll_prediv = {
 		.offset = HHI_MPLL_CNTL5,
 		.shift = 12,
 		.width = 1,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll_prediv",
@@ -911,6 +912,7 @@ static struct clk_regmap gxbb_mpeg_clk_div = {
 		.offset = HHI_MPEG_CLK_CNTL,
 		.shift = 0,
 		.width = 7,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpeg_clk_div",
diff --git a/drivers/clk/meson/meson8-ddr.c b/drivers/clk/meson/meson8-ddr.c
index 4b73ea244b63..950f323072fb 100644
--- a/drivers/clk/meson/meson8-ddr.c
+++ b/drivers/clk/meson/meson8-ddr.c
@@ -65,7 +65,7 @@ static struct clk_regmap meson8_ddr_pll = {
 		.offset = AM_DDR_PLL_CNTL,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "ddr_pll",
diff --git a/drivers/clk/meson/meson8b.c b/drivers/clk/meson/meson8b.c
index e4b474c5f86c..4dba11c0ab7e 100644
--- a/drivers/clk/meson/meson8b.c
+++ b/drivers/clk/meson/meson8b.c
@@ -104,7 +104,7 @@ static struct clk_regmap meson8b_fixed_pll = {
 		.offset = HHI_MPLL_CNTL,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll",
@@ -457,6 +457,7 @@ static struct clk_regmap meson8b_mpll_prediv = {
 		.offset = HHI_MPLL_CNTL5,
 		.shift = 12,
 		.width = 1,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpll_prediv",
@@ -635,6 +636,7 @@ static struct clk_regmap meson8b_mpeg_clk_div = {
 		.offset = HHI_MPEG_CLK_CNTL,
 		.shift = 0,
 		.width = 7,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "mpeg_clk_div",
diff --git a/drivers/clk/meson/s4-peripherals.c b/drivers/clk/meson/s4-peripherals.c
index c930cf0614a0..470431355e25 100644
--- a/drivers/clk/meson/s4-peripherals.c
+++ b/drivers/clk/meson/s4-peripherals.c
@@ -175,6 +175,7 @@ static struct clk_regmap s4_sysclk_b_div = {
 		.offset = CLKCTRL_SYS_CLK_CTRL0,
 		.shift = 16,
 		.width = 10,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "sysclk_b_div",
@@ -221,6 +222,7 @@ static struct clk_regmap s4_sysclk_a_div = {
 		.offset = CLKCTRL_SYS_CLK_CTRL0,
 		.shift = 0,
 		.width = 10,
+		.flags = CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "sysclk_a_div",
diff --git a/drivers/clk/meson/s4-pll.c b/drivers/clk/meson/s4-pll.c
index d8e621e79428..5dc051afc06a 100644
--- a/drivers/clk/meson/s4-pll.c
+++ b/drivers/clk/meson/s4-pll.c
@@ -72,7 +72,7 @@ static struct clk_regmap s4_fixed_pll = {
 		.offset = ANACTRL_FIXPLL_CTRL0,
 		.shift = 16,
 		.width = 2,
-		.flags = CLK_DIVIDER_POWER_OF_TWO,
+		.flags = CLK_DIVIDER_POWER_OF_TWO | CLK_DIVIDER_READ_ONLY,
 	},
 	.hw.init = &(struct clk_init_data){
 		.name = "fixed_pll",

---
base-commit: 664988eb47dd2d6ae1d9e4188ec91832562f8f26
change-id: 20241111-fix_childclk_of_roclk_has_been_tampered_with-61dbcc623746

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

