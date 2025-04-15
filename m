From: Chuan Liu <chuan.liu@amlogic.com>
Date: Tue, 15 Apr 2025 10:45:28 +0800
Subject: [PATCH v3 5/7] soc: amlogic: clk-measure: Add support for S4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250415-clk-measure-v3-5-9b8551dd33b4@amlogic.com>
References: <20250415-clk-measure-v3-0-9b8551dd33b4@amlogic.com>
In-Reply-To: <20250415-clk-measure-v3-0-9b8551dd33b4@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744685155; l=6985;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=f1yZNHZfuwZo3oCuCZ/1ipyUb4zDYUsgVOzb/0UumTA=;
 b=ewP/ejHLfQiMnXGyduhwRSB8WJAwB5Q9/wsascpILyAjEJtuQ76dEf163qOxy6L3gynM/PTsH
 0UwFv1wHGGBA5FpFwAAz8y9fEV65Cgctj/ToLl4jTKQtq3O5HpJN73I
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the clk-measurer clocks IDs for the Amlogic S4 SoC family.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/soc/amlogic/meson-clk-measure.c | 163 ++++++++++++++++++++++++++++++++
 1 file changed, 163 insertions(+)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index dfbc34a976dc..d862e30a244e 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -634,6 +634,159 @@ static const struct meson_msr_id clk_msr_c3[] = {
 
 };
 
+static const struct meson_msr_id clk_msr_s4[] = {
+	CLK_MSR_ID(0, "sys_clk"),
+	CLK_MSR_ID(1, "axi_clk"),
+	CLK_MSR_ID(2, "rtc_clk"),
+	CLK_MSR_ID(5, "mali"),
+	CLK_MSR_ID(6, "cpu_clk_div16"),
+	CLK_MSR_ID(7, "ceca_clk"),
+	CLK_MSR_ID(8, "cecb_clk"),
+	CLK_MSR_ID(10, "fclk_div5"),
+	CLK_MSR_ID(11, "mpll0"),
+	CLK_MSR_ID(12, "mpll1"),
+	CLK_MSR_ID(13, "mpll2"),
+	CLK_MSR_ID(14, "mpll3"),
+	CLK_MSR_ID(15, "fclk_50m"),
+	CLK_MSR_ID(16, "pcie_clk_inp"),
+	CLK_MSR_ID(17, "pcie_clk_inn"),
+	CLK_MSR_ID(18, "mpll_clk_test_out"),
+	CLK_MSR_ID(19, "hifi_pll"),
+	CLK_MSR_ID(20, "gp0_pll"),
+	CLK_MSR_ID(21, "gp1_pll"),
+	CLK_MSR_ID(22, "eth_mppll_50m_ckout"),
+	CLK_MSR_ID(23, "sys_pll_div16"),
+	CLK_MSR_ID(24, "ddr_dpll_pt_clk"),
+	CLK_MSR_ID(30, "mod_eth_phy_ref_clk"),
+	CLK_MSR_ID(31, "mod_eth_tx_clk"),
+	CLK_MSR_ID(32, "eth_125m"),
+	CLK_MSR_ID(33, "eth_rmii"),
+	CLK_MSR_ID(34, "co_clkin_to_mac"),
+	CLK_MSR_ID(35, "mod_eth_rx_clk_rmii"),
+	CLK_MSR_ID(36, "co_rx_clk"),
+	CLK_MSR_ID(37, "co_tx_clk"),
+	CLK_MSR_ID(38, "eth_phy_rxclk"),
+	CLK_MSR_ID(39, "eth_phy_plltxclk"),
+	CLK_MSR_ID(40, "ephy_test_clk"),
+	CLK_MSR_ID(50, "vid_pll_div_clk_out"),
+	CLK_MSR_ID(51, "enci"),
+	CLK_MSR_ID(52, "encp"),
+	CLK_MSR_ID(53, "encl"),
+	CLK_MSR_ID(54, "vdac"),
+	CLK_MSR_ID(55, "cdac_clk_c"),
+	CLK_MSR_ID(56, "mod_tcon_clko"),
+	CLK_MSR_ID(57, "lcd_an_clk_ph2"),
+	CLK_MSR_ID(58, "lcd_an_clk_ph3"),
+	CLK_MSR_ID(59, "hdmitx_pixel"),
+	CLK_MSR_ID(60, "vdin_meas"),
+	CLK_MSR_ID(61, "vpu"),
+	CLK_MSR_ID(62, "vpu_clkb"),
+	CLK_MSR_ID(63, "vpu_clkb_tmp"),
+	CLK_MSR_ID(64, "vpu_clkc"),
+	CLK_MSR_ID(65, "vid_lock"),
+	CLK_MSR_ID(66, "vapb"),
+	CLK_MSR_ID(67, "ge2d"),
+	CLK_MSR_ID(68, "cts_hdcp22_esmclk"),
+	CLK_MSR_ID(69, "cts_hdcp22_skpclk"),
+	CLK_MSR_ID(76, "hdmitx_tmds"),
+	CLK_MSR_ID(77, "hdmitx_sys_clk"),
+	CLK_MSR_ID(78, "hdmitx_fe_clk"),
+	CLK_MSR_ID(79, "rama"),
+	CLK_MSR_ID(93, "vdec"),
+	CLK_MSR_ID(99, "hevcf"),
+	CLK_MSR_ID(100, "demod_core"),
+	CLK_MSR_ID(101, "adc_extclk_in"),
+	CLK_MSR_ID(102, "cts_demod_core_t2_clk"),
+	CLK_MSR_ID(103, "adc_dpll_intclk"),
+	CLK_MSR_ID(104, "adc_dpll_clk_b3"),
+	CLK_MSR_ID(105, "s2_adc_clk"),
+	CLK_MSR_ID(106, "deskew_pll_clk_div32_out"),
+	CLK_MSR_ID(110, "sc"),
+	CLK_MSR_ID(111, "sar_adc"),
+	CLK_MSR_ID(113, "sd_emmc_c"),
+	CLK_MSR_ID(114, "sd_emmc_b"),
+	CLK_MSR_ID(115, "sd_emmc_a"),
+	CLK_MSR_ID(116, "gpio_msr_clk"),
+	CLK_MSR_ID(118, "spicc0"),
+	CLK_MSR_ID(121, "ts"),
+	CLK_MSR_ID(130, "audio_vad_clk"),
+	CLK_MSR_ID(131, "acodec_dac_clk_x128"),
+	CLK_MSR_ID(132, "audio_locker_in_clk"),
+	CLK_MSR_ID(133, "audio_locker_out_clk"),
+	CLK_MSR_ID(134, "audio_tdmout_c_sclk"),
+	CLK_MSR_ID(135, "audio_tdmout_b_sclk"),
+	CLK_MSR_ID(136, "audio_tdmout_a_sclk"),
+	CLK_MSR_ID(137, "audio_tdmin_lb_sclk"),
+	CLK_MSR_ID(138, "audio_tdmin_c_sclk"),
+	CLK_MSR_ID(139, "audio_tdmin_b_sclk"),
+	CLK_MSR_ID(140, "audio_tdmin_a_sclk"),
+	CLK_MSR_ID(141, "audio_resamplea_clk"),
+	CLK_MSR_ID(142, "audio_pdm_sysclk"),
+	CLK_MSR_ID(143, "audio_spdifout_b_mst_clk"),
+	CLK_MSR_ID(144, "audio_spdifout_mst_clk"),
+	CLK_MSR_ID(145, "audio_spdifin_mst_clk"),
+	CLK_MSR_ID(146, "audio_pdm_dclk"),
+	CLK_MSR_ID(147, "audio_resampleb_clk"),
+	CLK_MSR_ID(160, "pwm_j"),
+	CLK_MSR_ID(161, "pwm_i"),
+	CLK_MSR_ID(162, "pwm_h"),
+	CLK_MSR_ID(163, "pwm_g"),
+	CLK_MSR_ID(164, "pwm_f"),
+	CLK_MSR_ID(165, "pwm_e"),
+	CLK_MSR_ID(166, "pwm_d"),
+	CLK_MSR_ID(167, "pwm_c"),
+	CLK_MSR_ID(168, "pwm_b"),
+	CLK_MSR_ID(169, "pwm_a"),
+	CLK_MSR_ID(176, "rng_ring_0"),
+	CLK_MSR_ID(177, "rng_ring_1"),
+	CLK_MSR_ID(178, "rng_ring_2"),
+	CLK_MSR_ID(179, "rng_ring_3"),
+	CLK_MSR_ID(180, "dmc_osc_ring(LVT16)"),
+	CLK_MSR_ID(181, "gpu_osc_ring0(LVT16)"),
+	CLK_MSR_ID(182, "gpu_osc_ring1(ULVT16)"),
+	CLK_MSR_ID(183, "gpu_osc_ring2(SLVT16)"),
+	CLK_MSR_ID(184, "vpu_osc_ring0(SVT24)"),
+	CLK_MSR_ID(185, "vpu_osc_ring1(LVT20)"),
+	CLK_MSR_ID(186, "vpu_osc_ring2(LVT16)"),
+	CLK_MSR_ID(187, "dos_osc_ring0(SVT24)"),
+	CLK_MSR_ID(188, "dos_osc_ring1(SVT16)"),
+	CLK_MSR_ID(189, "dos_osc_ring2(LVT16)"),
+	CLK_MSR_ID(190, "dos_osc_ring3(ULVT20)"),
+	CLK_MSR_ID(192, "axi_sram_osc_ring(SVT16)"),
+	CLK_MSR_ID(193, "demod_osc_ring0"),
+	CLK_MSR_ID(194, "demod_osc_ring1"),
+	CLK_MSR_ID(195, "sar_osc_ring"),
+	CLK_MSR_ID(196, "sys_cpu_osc_ring0"),
+	CLK_MSR_ID(197, "sys_cpu_osc_ring1"),
+	CLK_MSR_ID(198, "sys_cpu_osc_ring2"),
+	CLK_MSR_ID(199, "sys_cpu_osc_ring3"),
+	CLK_MSR_ID(200, "sys_cpu_osc_ring4"),
+	CLK_MSR_ID(201, "sys_cpu_osc_ring5"),
+	CLK_MSR_ID(202, "sys_cpu_osc_ring6"),
+	CLK_MSR_ID(203, "sys_cpu_osc_ring7"),
+	CLK_MSR_ID(204, "sys_cpu_osc_ring8"),
+	CLK_MSR_ID(205, "sys_cpu_osc_ring9"),
+	CLK_MSR_ID(206, "sys_cpu_osc_ring10"),
+	CLK_MSR_ID(207, "sys_cpu_osc_ring11"),
+	CLK_MSR_ID(208, "sys_cpu_osc_ring12"),
+	CLK_MSR_ID(209, "sys_cpu_osc_ring13"),
+	CLK_MSR_ID(210, "sys_cpu_osc_ring14"),
+	CLK_MSR_ID(211, "sys_cpu_osc_ring15"),
+	CLK_MSR_ID(212, "sys_cpu_osc_ring16"),
+	CLK_MSR_ID(213, "sys_cpu_osc_ring17"),
+	CLK_MSR_ID(214, "sys_cpu_osc_ring18"),
+	CLK_MSR_ID(215, "sys_cpu_osc_ring19"),
+	CLK_MSR_ID(216, "sys_cpu_osc_ring20"),
+	CLK_MSR_ID(217, "sys_cpu_osc_ring21"),
+	CLK_MSR_ID(218, "sys_cpu_osc_ring22"),
+	CLK_MSR_ID(219, "sys_cpu_osc_ring23"),
+	CLK_MSR_ID(220, "sys_cpu_osc_ring24"),
+	CLK_MSR_ID(221, "sys_cpu_osc_ring25"),
+	CLK_MSR_ID(222, "sys_cpu_osc_ring26"),
+	CLK_MSR_ID(223, "sys_cpu_osc_ring27"),
+
+};
+
 static int meson_measure_id(struct meson_msr_id *clk_msr_id,
 			    unsigned int duration)
 {
@@ -867,6 +1020,12 @@ static const struct meson_msr_data clk_msr_c3_data = {
 	.reg = &msr_reg_offset_v2,
 };
 
+static const struct meson_msr_data clk_msr_s4_data = {
+	.msr_table = (void *)clk_msr_s4,
+	.msr_count = ARRAY_SIZE(clk_msr_s4),
+	.reg = &msr_reg_offset_v2,
+};
+
 static const struct of_device_id meson_msr_match_table[] = {
 	{
 		.compatible = "amlogic,meson-gx-clk-measure",
@@ -896,6 +1055,10 @@ static const struct of_device_id meson_msr_match_table[] = {
 		.compatible = "amlogic,c3-clk-measure",
 		.data = &clk_msr_c3_data,
 	},
+	{
+		.compatible = "amlogic,s4-clk-measure",
+		.data = &clk_msr_s4_data,
+	},
 	{ /* sentinel */ }
 };
 MODULE_DEVICE_TABLE(of, meson_msr_match_table);

-- 
2.42.0

