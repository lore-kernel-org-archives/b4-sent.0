From: Chuan Liu <chuan.liu@amlogic.com>
Date: Mon, 11 Nov 2024 11:37:02 +0800
Subject: [PATCH v2 2/3] clk: meson: Fix failure of glitch-free mux
 switching
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241111-fix_glitch_free-v2-2-0099fd9ad3e5@amlogic.com>
References: <20241111-fix_glitch_free-v2-0-0099fd9ad3e5@amlogic.com>
In-Reply-To: <20241111-fix_glitch_free-v2-0-0099fd9ad3e5@amlogic.com>
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-amlogic@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731296227; l=8711;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=atOOThnlnG3IFHNRk0s4v4QFpYbDw+X8nwyi0iZYZHw=;
 b=SJ1Q58UzUoM28/g8A6L/ubJfjIKtacTu0tk72GbNpWLNgK6hW40Oq2r5sb6/GSwCPAYn9n5IR
 1xi5qyyqFFzDkH/huhC6vUketMMfDWvwWb7c2HVS5jgIb+1DFuMSl97
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

glitch-free mux has two clock channels (channel 0 and channel 1) with
the same configuration.Channel 0 of glitch-free mux is not only the
clock source for the mux, but also the working clock for glitch free
mux. Therefore, when glitch-free mux switches, it is necessary to ensure
that channel 0 has a clock input, otherwise glitch free mux will not
work and cannot switch to the target channel. So adding flag
CLK_OPS_PARENT_ENABLE ensures that both channels 0 and 1 are enabled
when mux switches.

In fact, we just need to make sure that channel 0 is enabled. The
purpose of CLK_OPS_PARENT_ENABLE may not be to solve our situation, but
adding this flag does solve our current problem.

Fixes: 84af914404db ("clk: meson: a1: add Amlogic A1 Peripherals clock
controller driver")
Fixes: 14ebb3154b8f ("clk: meson: axg: add Video Clocks")
Fixes: f06ac3ed04e8 ("clk: meson: c3: add c3 clock peripherals controller
driver")
Fixes: 085a4ea93d54 ("clk: meson: g12a: add peripheral clock controller")
Fixes: fac9a55b66c9 ("clk: meson-gxbb: Add MALI clocks")
Fixes: 74e1f2521f16 ("clk: meson: meson8b: add the GPU clock tree")
Fixes: 57b55c76aaf1 ("clk: meson: S4: add support for Amlogic S4 SoC
peripheral clock controller")
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/clk/meson/a1-peripherals.c |  4 ++--
 drivers/clk/meson/axg.c            |  4 ++--
 drivers/clk/meson/c3-peripherals.c |  2 +-
 drivers/clk/meson/g12a.c           |  6 +++---
 drivers/clk/meson/gxbb.c           |  6 +++---
 drivers/clk/meson/meson8b.c        | 21 ++++++++++++++++++---
 drivers/clk/meson/s4-peripherals.c | 12 ++++++------
 7 files changed, 35 insertions(+), 20 deletions(-)

diff --git a/drivers/clk/meson/a1-peripherals.c b/drivers/clk/meson/a1-peripherals.c
index 7aa6abb2eb1f..4b9686916b17 100644
--- a/drivers/clk/meson/a1-peripherals.c
+++ b/drivers/clk/meson/a1-peripherals.c
@@ -489,7 +489,7 @@ static struct clk_regmap dspa_sel = {
 			&dspa_b.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -635,7 +635,7 @@ static struct clk_regmap dspb_sel = {
 			&dspb_b.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
diff --git a/drivers/clk/meson/axg.c b/drivers/clk/meson/axg.c
index 1b08daf579b2..a1217dff40fa 100644
--- a/drivers/clk/meson/axg.c
+++ b/drivers/clk/meson/axg.c
@@ -1144,7 +1144,7 @@ static struct clk_regmap axg_vpu = {
 			&axg_vpu_1.hw
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_NO_REPARENT,
+		.flags = CLK_SET_RATE_NO_REPARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -1260,7 +1260,7 @@ static struct clk_regmap axg_vapb_sel = {
 			&axg_vapb_1.hw
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_NO_REPARENT,
+		.flags = CLK_SET_RATE_NO_REPARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
diff --git a/drivers/clk/meson/c3-peripherals.c b/drivers/clk/meson/c3-peripherals.c
index 7dcbf4ebee07..4566c2aeeb19 100644
--- a/drivers/clk/meson/c3-peripherals.c
+++ b/drivers/clk/meson/c3-peripherals.c
@@ -1431,7 +1431,7 @@ static struct clk_regmap hcodec = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_data = hcodec_parent_data,
 		.num_parents = ARRAY_SIZE(hcodec_parent_data),
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
diff --git a/drivers/clk/meson/g12a.c b/drivers/clk/meson/g12a.c
index d3539fe9f7af..4d3b064d09fc 100644
--- a/drivers/clk/meson/g12a.c
+++ b/drivers/clk/meson/g12a.c
@@ -2812,7 +2812,7 @@ static struct clk_regmap g12a_vpu = {
 			&g12a_vpu_1.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_NO_REPARENT,
+		.flags = CLK_SET_RATE_NO_REPARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -3105,7 +3105,7 @@ static struct clk_regmap g12a_vapb_sel = {
 			&g12a_vapb_1.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_NO_REPARENT,
+		.flags = CLK_SET_RATE_NO_REPARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -4039,7 +4039,7 @@ static struct clk_regmap g12a_mali = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_hws = g12a_mali_parent_hws,
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
diff --git a/drivers/clk/meson/gxbb.c b/drivers/clk/meson/gxbb.c
index 262c318edbd5..dfa9ffc61b41 100644
--- a/drivers/clk/meson/gxbb.c
+++ b/drivers/clk/meson/gxbb.c
@@ -1132,7 +1132,7 @@ static struct clk_regmap gxbb_mali = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_hws = gxbb_mali_parent_hws,
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -1613,7 +1613,7 @@ static struct clk_regmap gxbb_vpu = {
 			&gxbb_vpu_1.hw
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_NO_REPARENT,
+		.flags = CLK_SET_RATE_NO_REPARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -1748,7 +1748,7 @@ static struct clk_regmap gxbb_vapb_sel = {
 			&gxbb_vapb_1.hw
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_NO_REPARENT,
+		.flags = CLK_SET_RATE_NO_REPARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
diff --git a/drivers/clk/meson/meson8b.c b/drivers/clk/meson/meson8b.c
index e4b474c5f86c..0af76b527e5b 100644
--- a/drivers/clk/meson/meson8b.c
+++ b/drivers/clk/meson/meson8b.c
@@ -1997,7 +1997,22 @@ static struct clk_regmap meson8b_mali = {
 			&meson8b_mali_1.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		/*
+		 * glitch-free mux has two clock channels (channel 0 and
+		 * channel 1) with the same configuration.Channel 0 of
+		 * glitch-free mux is not only the clock source for the mux,
+		 * but also the working clock for glitch free mux. Therefore,
+		 * when glitch-free mux switches, it is necessary to ensure that
+		 * channel 0 has a clock input, otherwise glitch free mux will
+		 * not work and cannot switch to the target channel. So adding
+		 * flag CLK_OPS_PARENT_ENABLE ensures that both channels 0 and 1
+		 * are enabled when mux switches.
+		 *
+		 * In fact, we just need to make sure that channel 0 is enabled.
+		 * The purpose of CLK_OPS_PARENT_ENABLE may not be to solve our
+		 * situation, but adding this flag does solve our current problem.
+		 */
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -2252,7 +2267,7 @@ static struct clk_regmap meson8b_vpu = {
 			&meson8b_vpu_1.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -2364,7 +2379,7 @@ static struct clk_regmap meson8b_vdec_1 = {
 			&meson8b_vdec_1_2.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
diff --git a/drivers/clk/meson/s4-peripherals.c b/drivers/clk/meson/s4-peripherals.c
index c930cf0614a0..79e0240d58e6 100644
--- a/drivers/clk/meson/s4-peripherals.c
+++ b/drivers/clk/meson/s4-peripherals.c
@@ -1404,7 +1404,7 @@ static struct clk_regmap s4_mali_mux = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_hws = s4_mali_parent_hws,
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -1536,7 +1536,7 @@ static struct clk_regmap s4_vdec_mux = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_hws = s4_vdec_mux_parent_hws,
 		.num_parents = ARRAY_SIZE(s4_vdec_mux_parent_hws),
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -1656,7 +1656,7 @@ static struct clk_regmap s4_hevcf_mux = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_hws = s4_hevcf_mux_parent_hws,
 		.num_parents = ARRAY_SIZE(s4_hevcf_mux_parent_hws),
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -1774,7 +1774,7 @@ static struct clk_regmap s4_vpu = {
 			&s4_vpu_1.hw,
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -1989,7 +1989,7 @@ static struct clk_regmap s4_vpu_clkc_mux = {
 		.ops = &clk_regmap_mux_ops,
 		.parent_hws = s4_vpu_mux_parent_hws,
 		.num_parents = ARRAY_SIZE(s4_vpu_mux_parent_hws),
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 
@@ -2115,7 +2115,7 @@ static struct clk_regmap s4_vapb = {
 			&s4_vapb_1.hw
 		},
 		.num_parents = 2,
-		.flags = CLK_SET_RATE_PARENT,
+		.flags = CLK_SET_RATE_PARENT | CLK_OPS_PARENT_ENABLE,
 	},
 };
 

-- 
2.42.0

