From: Jian Hu <jian.hu@amlogic.com>
Date: Mon, 06 Jul 2026 13:36:03 +0800
Subject: [PATCH] soc: amlogic: clk-measure: Mark the clock measure table as
 __initconst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-clkmsr_optimization-v1-1-70f5aae6e60b@amlogic.com>
X-B4-Tracking: v=1; b=H4sIAMI+S2oC/x2MQQqAIBAAvxJ7Ttg6ZPSViFDbaiktVCIK/550H
 JiZFwJ5pgBd8YKniwMfLkNVFmBW5RYSPGWGGusGJTbC7JsNfjzOyJYfFbMvdEuVmSTqmQhyeXq
 a+f6v/ZDSB4ltrM1lAAAA
X-Change-ID: 20260706-clkmsr_optimization-b8e1cd70bfee
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jian Hu <jian.hu@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783316169; l=3839;
 i=jian.hu@amlogic.com; s=20260415; h=from:subject:message-id;
 bh=n3+FWab2iM1pkmUi4HdCeGFTpcygj++bqfpdmrSHV1Q=;
 b=7PcHvkINB/VwMB1qf+9rKl1NuPq4ZemkkoFmBNTRfTGPIwr6Mi06cbHn4Drh0+fUK8c7OMovV
 Z+DCrLY0u8MBB3j34bpdU4H4xXZG+wFelO0nW9w7TTnQfhJ2e9rQeNT
X-Developer-Key: i=jian.hu@amlogic.com; a=ed25519;
 pk=zHUE+rNtH9z+Sb8au1/elWknjFQmy5QDVkBoxleuOIA=
X-Endpoint-Received: by B4 Relay for jian.hu@amlogic.com/20260415 with auth_id=735
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clock measure table is only used during initialization, and the
table data is copied to the msr_table field of struct meson_msr_data.

Mark it as __initconst so it can be freed after kernel initialization.
Taking T7 as an example, this frees approximately 5 KB of memory,
saving some runtime memory.

Signed-off-by: Jian Hu <jian.hu@amlogic.com>
---
 drivers/soc/amlogic/meson-clk-measure.c | 18 +++++++++---------
 1 file changed, 9 insertions(+), 9 deletions(-)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index 8c4f3cc8c8ab..e1cf67fad83c 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -55,7 +55,7 @@ struct meson_msr {
 #define CLK_MSR_ID(__id, __name) \
 	[__id] = {.id = __id, .name = __name,}
 
-static const struct meson_msr_id clk_msr_m8[] = {
+static const struct meson_msr_id clk_msr_m8[] __initconst = {
 	CLK_MSR_ID(0, "ring_osc_out_ee0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee2"),
@@ -104,7 +104,7 @@ static const struct meson_msr_id clk_msr_m8[] = {
 	CLK_MSR_ID(63, "mipi_csi_cfg"),
 };
 
-static const struct meson_msr_id clk_msr_gx[] = {
+static const struct meson_msr_id clk_msr_gx[] __initconst = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -174,7 +174,7 @@ static const struct meson_msr_id clk_msr_gx[] = {
 	CLK_MSR_ID(82, "ge2d"),
 };
 
-static const struct meson_msr_id clk_msr_axg[] = {
+static const struct meson_msr_id clk_msr_axg[] __initconst = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -248,7 +248,7 @@ static const struct meson_msr_id clk_msr_axg[] = {
 	CLK_MSR_ID(109, "audio_locker_in"),
 };
 
-static const struct meson_msr_id clk_msr_g12a[] = {
+static const struct meson_msr_id clk_msr_g12a[] __initconst = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -364,7 +364,7 @@ static const struct meson_msr_id clk_msr_g12a[] = {
 	CLK_MSR_ID(122, "audio_pdm_dclk"),
 };
 
-static const struct meson_msr_id clk_msr_sm1[] = {
+static const struct meson_msr_id clk_msr_sm1[] __initconst = {
 	CLK_MSR_ID(0, "ring_osc_out_ee_0"),
 	CLK_MSR_ID(1, "ring_osc_out_ee_1"),
 	CLK_MSR_ID(2, "ring_osc_out_ee_2"),
@@ -494,7 +494,7 @@ static const struct meson_msr_id clk_msr_sm1[] = {
 	CLK_MSR_ID(127, "csi2_data"),
 };
 
-static const struct meson_msr_id clk_msr_c3[] = {
+static const struct meson_msr_id clk_msr_c3[] __initconst = {
 	CLK_MSR_ID(0,	"sys_clk"),
 	CLK_MSR_ID(1,	"axi_clk"),
 	CLK_MSR_ID(2,	"rtc_clk"),
@@ -634,7 +634,7 @@ static const struct meson_msr_id clk_msr_c3[] = {
 
 };
 
-static const struct meson_msr_id clk_msr_s4[] = {
+static const struct meson_msr_id clk_msr_s4[] __initconst = {
 	CLK_MSR_ID(0, "sys_clk"),
 	CLK_MSR_ID(1, "axi_clk"),
 	CLK_MSR_ID(2, "rtc_clk"),
@@ -787,7 +787,7 @@ static const struct meson_msr_id clk_msr_s4[] = {
 
 };
 
-static const struct meson_msr_id clk_msr_a1[] = {
+static const struct meson_msr_id clk_msr_a1[] __initconst = {
 	CLK_MSR_ID(0, "tdmout_b_sclk"),
 	CLK_MSR_ID(1, "tdmout_a_sclk"),
 	CLK_MSR_ID(2, "tdmin_lb_sclk"),
@@ -843,7 +843,7 @@ static const struct meson_msr_id clk_msr_a1[] = {
 	CLK_MSR_ID(61, "osc_ring_ramb"),
 };
 
-static const struct meson_msr_id clk_msr_t7[] = {
+static const struct meson_msr_id clk_msr_t7[] __initconst = {
 	CLK_MSR_ID(0, "sys"),
 	CLK_MSR_ID(1, "axi"),
 	CLK_MSR_ID(2, "rtc"),

---
base-commit: 4336e970ec6890fbd424128c352564a9c1dd514a
change-id: 20260706-clkmsr_optimization-b8e1cd70bfee

Best regards,
-- 
Jian Hu <jian.hu@amlogic.com>

