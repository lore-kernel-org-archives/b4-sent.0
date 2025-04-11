From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 11 Apr 2025 20:42:46 +0800
Subject: [PATCH 4/7] soc: amlogic: clk-measure: Add support for C3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250411-clk-measure-v1-4-cb46a78d019a@amlogic.com>
References: <20250411-clk-measure-v1-0-cb46a78d019a@amlogic.com>
In-Reply-To: <20250411-clk-measure-v1-0-cb46a78d019a@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744375372; l=6642;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=L9md6qqXJ5QGcx1nSe1cJoMiNoD+ixqwC9sxrOdsQHk=;
 b=t7hS9G47AGDeQjttw08J1JVBY/bkT5wI2BgfjWKJye3g6Jc0FOYkaPYSRlB9oECHa/YCjVq0M
 FSwVVhs3yVyCsh5ccbiTl5aERWYJQfs6eFK++T2/Z0HvbMPXEiOp1RW
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the clk-measurer clocks IDs for the Amlogic C3 SoC family.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/soc/amlogic/meson-clk-measure.c | 158 ++++++++++++++++++++++++++++++++
 1 file changed, 158 insertions(+)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index 30387d26307c..c6daddb8f1b8 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -497,6 +497,146 @@ static const struct meson_msr_id clk_msr_sm1[] = {
 	CLK_MSR_ID(127, "csi2_data"),
 };
 
+static const struct meson_msr_id clk_msr_c3[] = {
+	CLK_MSR_ID(0,	"sys_clk"),
+	CLK_MSR_ID(1,	"axi_clk"),
+	CLK_MSR_ID(2,	"rtc_clk"),
+	CLK_MSR_ID(3,	"p20_usb2_ckout"),
+	CLK_MSR_ID(4,	"eth_mpll_test"),
+	CLK_MSR_ID(5,	"sys_pll"),
+	CLK_MSR_ID(6,	"cpu_clk_div16"),
+	CLK_MSR_ID(7,	"ts_pll"),
+	CLK_MSR_ID(8,	"fclk_div2"),
+	CLK_MSR_ID(9,	"fclk_div2p5"),
+	CLK_MSR_ID(10,	"fclk_div3"),
+	CLK_MSR_ID(11,	"fclk_div4"),
+	CLK_MSR_ID(12,	"fclk_div5"),
+	CLK_MSR_ID(13,	"fclk_div7"),
+	CLK_MSR_ID(15,	"fclk_50m"),
+	CLK_MSR_ID(16,	"sys_oscin32k_i"),
+	CLK_MSR_ID(17,	"mclk_pll"),
+	CLK_MSR_ID(19,	"hifi_pll"),
+	CLK_MSR_ID(20,	"gp0_pll"),
+	CLK_MSR_ID(21,	"gp1_pll"),
+	CLK_MSR_ID(22,	"eth_mppll_50m_ckout"),
+	CLK_MSR_ID(23,	"sys_pll_div16"),
+	CLK_MSR_ID(24,	"ddr_dpll_pt_clk"),
+	CLK_MSR_ID(26,	"nna_core"),
+	CLK_MSR_ID(27,	"rtc_sec_pulse_out"),
+	CLK_MSR_ID(28,	"rtc_osc_clk_out"),
+	CLK_MSR_ID(29,	"debug_in_clk"),
+	CLK_MSR_ID(30,	"mod_eth_phy_ref_clk"),
+	CLK_MSR_ID(31,	"mod_eth_tx_clk"),
+	CLK_MSR_ID(32,	"eth_125m"),
+	CLK_MSR_ID(33,	"eth_rmii"),
+	CLK_MSR_ID(34,	"co_clkin_to_mac"),
+	CLK_MSR_ID(36,	"co_rx_clk"),
+	CLK_MSR_ID(37,	"co_tx_clk"),
+	CLK_MSR_ID(38,	"eth_phy_rxclk"),
+	CLK_MSR_ID(39,	"eth_phy_plltxclk"),
+	CLK_MSR_ID(40,	"ephy_test_clk"),
+	CLK_MSR_ID(66,	"vapb"),
+	CLK_MSR_ID(67,	"ge2d"),
+	CLK_MSR_ID(68,	"dewarpa"),
+	CLK_MSR_ID(70,	"mipi_dsi_meas"),
+	CLK_MSR_ID(71,	"dsi_phy"),
+	CLK_MSR_ID(79,	"rama"),
+	CLK_MSR_ID(94,	"vc9000e_core"),
+	CLK_MSR_ID(95,	"vc9000e_sys"),
+	CLK_MSR_ID(96,	"vc9000e_aclk"),
+	CLK_MSR_ID(97,	"hcodec"),
+	CLK_MSR_ID(106,	"deskew_pll_clk_div32_out"),
+	CLK_MSR_ID(107,	"mipi_csi_phy_clk_out[0]"),
+	CLK_MSR_ID(108,	"mipi_csi_phy_clk_out[1]"),
+	CLK_MSR_ID(110,	"spifc"),
+	CLK_MSR_ID(111,	"saradc"),
+	CLK_MSR_ID(112,	"ts"),
+	CLK_MSR_ID(113,	"sd_emmc_c"),
+	CLK_MSR_ID(114,	"sd_emmc_b"),
+	CLK_MSR_ID(115,	"sd_emmc_a"),
+	CLK_MSR_ID(116,	"gpio_msr_clk"),
+	CLK_MSR_ID(117,	"spicc_b"),
+	CLK_MSR_ID(118,	"spicc_a"),
+	CLK_MSR_ID(122,	"mod_audio_pdm_dclk_o"),
+	CLK_MSR_ID(124,	"o_earcrx_dmac_clk"),
+	CLK_MSR_ID(125,	"o_earcrx_cmdc_clk"),
+	CLK_MSR_ID(126,	"o_earctx_dmac_clk"),
+	CLK_MSR_ID(127,	"o_earctx_cmdc_clk"),
+	CLK_MSR_ID(128,	"o_tohdmitx_bclk"),
+	CLK_MSR_ID(129,	"o_tohdmitx_mclk"),
+	CLK_MSR_ID(130,	"o_tohdmitx_spdif_clk"),
+	CLK_MSR_ID(131,	"o_toacodec_bclk"),
+	CLK_MSR_ID(132,	"o_toacodec_mclk"),
+	CLK_MSR_ID(133,	"o_spdifout_b_mst_clk"),
+	CLK_MSR_ID(134,	"o_spdifout_mst_clk"),
+	CLK_MSR_ID(135,	"o_spdifin_mst_clk"),
+	CLK_MSR_ID(136,	"o_audio_mclk"),
+	CLK_MSR_ID(137,	"o_vad_clk"),
+	CLK_MSR_ID(138,	"o_tdmout_d_sclk"),
+	CLK_MSR_ID(139,	"o_tdmout_c_sclk"),
+	CLK_MSR_ID(140,	"o_tdmout_b_sclk"),
+	CLK_MSR_ID(141,	"o_tdmout_a_sclk"),
+	CLK_MSR_ID(142,	"o_tdminb_1b_sclk"),
+	CLK_MSR_ID(143,	"o_tdmin_1b_sclk"),
+	CLK_MSR_ID(144,	"o_tdmin_d_sclk"),
+	CLK_MSR_ID(145,	"o_tdmin_c_sclk"),
+	CLK_MSR_ID(146,	"o_tdmin_b_sclk"),
+	CLK_MSR_ID(147,	"o_tdmin_a_sclk"),
+	CLK_MSR_ID(148,	"o_resampleb_clk"),
+	CLK_MSR_ID(149,	"o_resamplea_clk"),
+	CLK_MSR_ID(150,	"o_pdmb_sysclk"),
+	CLK_MSR_ID(151,	"o_pdmb_dclk"),
+	CLK_MSR_ID(152,	"o_pdm_sysclk"),
+	CLK_MSR_ID(153,	"o_pdm_dclk"),
+	CLK_MSR_ID(154,	"c_alockerb_out_clk"),
+	CLK_MSR_ID(155,	"c_alockerb_in_clk"),
+	CLK_MSR_ID(156,	"c_alocker_out_clk"),
+	CLK_MSR_ID(157,	"c_alocker_in_clk"),
+	CLK_MSR_ID(158,	"audio_mst_clk[34]"),
+	CLK_MSR_ID(159,	"audio_mst_clk[35]"),
+	CLK_MSR_ID(160,	"pwm_n"),
+	CLK_MSR_ID(161,	"pwm_m"),
+	CLK_MSR_ID(162,	"pwm_l"),
+	CLK_MSR_ID(163,	"pwm_k"),
+	CLK_MSR_ID(164,	"pwm_j"),
+	CLK_MSR_ID(165,	"pwm_i"),
+	CLK_MSR_ID(166,	"pwm_h"),
+	CLK_MSR_ID(167,	"pwm_g"),
+	CLK_MSR_ID(168,	"pwm_f"),
+	CLK_MSR_ID(169,	"pwm_e"),
+	CLK_MSR_ID(170,	"pwm_d"),
+	CLK_MSR_ID(171,	"pwm_c"),
+	CLK_MSR_ID(172,	"pwm_b"),
+	CLK_MSR_ID(173,	"pwm_a"),
+	CLK_MSR_ID(174,	"AU_DAC1_CLK_TO_GPIO"),
+	CLK_MSR_ID(175,	"AU_ADC_CLK_TO_GPIO"),
+	CLK_MSR_ID(176,	"rng_ring_osc_clk[0]"),
+	CLK_MSR_ID(177,	"rng_ring_osc_clk[1]"),
+	CLK_MSR_ID(178,	"rng_ring_osc_clk[2]"),
+	CLK_MSR_ID(179,	"rng_ring_osc_clk[3]"),
+	CLK_MSR_ID(180,	"sys_cpu_ring_osc_clk[0]"),
+	CLK_MSR_ID(181,	"sys_cpu_ring_osc_clk[1]"),
+	CLK_MSR_ID(182,	"sys_cpu_ring_osc_clk[2]"),
+	CLK_MSR_ID(183,	"sys_cpu_ring_osc_clk[3]"),
+	CLK_MSR_ID(184,	"sys_cpu_ring_osc_clk[4]"),
+	CLK_MSR_ID(185,	"sys_cpu_ring_osc_clk[5]"),
+	CLK_MSR_ID(186,	"sys_cpu_ring_osc_clk[6]"),
+	CLK_MSR_ID(187,	"sys_cpu_ring_osc_clk[7]"),
+	CLK_MSR_ID(188,	"sys_cpu_ring_osc_clk[8]"),
+	CLK_MSR_ID(189,	"sys_cpu_ring_osc_clk[9]"),
+	CLK_MSR_ID(190,	"sys_cpu_ring_osc_clk[10]"),
+	CLK_MSR_ID(191,	"sys_cpu_ring_osc_clk[11]"),
+	CLK_MSR_ID(192,	"am_ring_osc_clk_out[12](dmc)"),
+	CLK_MSR_ID(193,	"am_ring_osc_clk_out[13](rama)"),
+	CLK_MSR_ID(194,	"am_ring_osc_clk_out[14](nna)"),
+	CLK_MSR_ID(195,	"am_ring_osc_clk_out[15](nna)"),
+	CLK_MSR_ID(200,	"rng_ring_osc_clk_1[0]"),
+	CLK_MSR_ID(201,	"rng_ring_osc_clk_1[1]"),
+	CLK_MSR_ID(202,	"rng_ring_osc_clk_1[2]"),
+	CLK_MSR_ID(203,	"rng_ring_osc_clk_1[3]"),
+
+};
+
 static int meson_measure_id(struct meson_msr_id *clk_msr_id,
 			    unsigned int duration)
 {
@@ -729,6 +869,20 @@ static const struct meson_msr_data clk_msr_sm1_data = {
 	},
 };
 
+static const struct meson_msr_data clk_msr_c3_data = {
+	.msr_table = (void *)clk_msr_c3,
+	.msr_count = ARRAY_SIZE(clk_msr_c3),
+	.reg = {
+		.reg0 = 0x0,
+		.reg1 = 0x4,
+		.reg2 = 0x8,
+		.reg3 = 0xc,
+		.reg4 = 0x10,
+		.reg5 = 0x14,
+		.duty = 0x18,
+	},
+};
+
 static const struct of_device_id meson_msr_match_table[] = {
 	{
 		.compatible = "amlogic,meson-gx-clk-measure",
@@ -754,6 +908,10 @@ static const struct of_device_id meson_msr_match_table[] = {
 		.compatible = "amlogic,meson-sm1-clk-measure",
 		.data = &clk_msr_sm1_data,
 	},
+	{
+		.compatible = "amlogic,c3-clk-measure",
+		.data = &clk_msr_c3_data,
+	},
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, meson_msr_match_table);

-- 
2.42.0

