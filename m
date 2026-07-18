From: Aaron Kling <webgeek1234@gmail.com>
Date: Fri, 17 Jul 2026 19:17:03 -0500
Subject: [PATCH 2/2] soc/tegra: pmc: Add Tegra210B01 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260717-t210b01-pmc-v1-2-bf776be8b3a7@gmail.com>
References: <20260717-t210b01-pmc-v1-0-bf776be8b3a7@gmail.com>
In-Reply-To: <20260717-t210b01-pmc-v1-0-bf776be8b3a7@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, Azkali Manad <a.ffcc7@gmail.com>, 
 Thomas Makin <halorocker89@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784333826; l=9501;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=OCQonk6jGTpoZZXZxgWdn6dt1IMUFa28q+B6W0rxEWc=;
 b=zrJSCM70nwdjvdIxOUl62PP0w5YCTLKd/jXQo7oNePjcq69OmsfLPQxoZTsrVWY0+FaXRFp9o
 ljccunzp8wXASUpezwWtoLxIsyjUOCkzbdolB4zFHqXchiAD/f5z2X+
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Azkali Manad <a.ffcc7@gmail.com>

The PMC in Tegra210B01 is very similar to the one in the original
Tegra210, but has a few powergate and pad differences. Add support for
this soc.

Signed-off-by: Azkali Manad <a.ffcc7@gmail.com>
Co-developed-by: Thomas Makin <halorocker89@gmail.com>
Signed-off-by: Thomas Makin <halorocker89@gmail.com>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/tegra/pmc.c | 160 ++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 160 insertions(+)

diff --git a/drivers/soc/tegra/pmc.c b/drivers/soc/tegra/pmc.c
index f419a5395545f..4d77aa66d690c 100644
--- a/drivers/soc/tegra/pmc.c
+++ b/drivers/soc/tegra/pmc.c
@@ -3744,6 +3744,32 @@ static const char * const tegra210_powergates[] = {
 	[TEGRA_POWERGATE_VE2] = "ve2",
 };
 
+static const char * const tegra210b01_powergates[] = {
+	[TEGRA_POWERGATE_CPU] = "crail",
+	[TEGRA_POWERGATE_3D] = "3d",
+	[TEGRA_POWERGATE_PCIE] = "pcie",
+	[TEGRA_POWERGATE_MPE] = "mpe",
+	[TEGRA_POWERGATE_SATA] = "sata",
+	[TEGRA_POWERGATE_CPU1] = "cpu1",
+	[TEGRA_POWERGATE_CPU2] = "cpu2",
+	[TEGRA_POWERGATE_CPU3] = "cpu3",
+	[TEGRA_POWERGATE_CPU0] = "cpu0",
+	[TEGRA_POWERGATE_C0NC] = "c0nc",
+	[TEGRA_POWERGATE_SOR] = "sor",
+	[TEGRA_POWERGATE_DIS] = "dis",
+	[TEGRA_POWERGATE_DISB] = "disb",
+	[TEGRA_POWERGATE_XUSBA] = "xusba",
+	[TEGRA_POWERGATE_XUSBB] = "xusbb",
+	[TEGRA_POWERGATE_XUSBC] = "xusbc",
+	[TEGRA_POWERGATE_VIC] = "vic",
+	[TEGRA_POWERGATE_IRAM] = "iram",
+	[TEGRA_POWERGATE_NVDEC] = "nvdec",
+	[TEGRA_POWERGATE_NVJPG] = "nvjpg",
+	[TEGRA_POWERGATE_AUD] = "aud",
+	[TEGRA_POWERGATE_DFD] = "dfd",
+};
+
+
 static const u8 tegra210_cpu_powergates[] = {
 	TEGRA_POWERGATE_CPU0,
 	TEGRA_POWERGATE_CPU1,
@@ -3897,6 +3923,139 @@ static const struct tegra_pmc_soc tegra210_pmc_soc = {
 	.has_single_mmio_aperture = true,
 };
 
+static const struct tegra_io_pad_soc tegra210b01_io_pads[] = {
+	TEGRA_IO_PAD(TEGRA_IO_PAD_AUDIO, 17, 0x1b8, 0x1bc, "audio"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_AUDIO_HV, 29, 0x1c0, 0x1c4, "audio-hv"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_CAM, 4, 0x1c0, 0x1c4, "cam"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_CSIA, 0, 0x1b8, 0x1bc, "csia"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_CSIB, 1, 0x1b8, 0x1bc, "csib"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_CSIC, 10, 0x1c0, 0x1c4, "csic"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_CSID, 11, 0x1c0, 0x1c4, "csid"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_CSIE, 12, 0x1c0, 0x1c4, "csie"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_CSIF, 13, 0x1c0, 0x1c4, "csif"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DBG, 25, 0x1b8, 0x1bc, "dbg"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DEBUG_NONAO, 26, 0x1b8, 0x1bc, "debug-nonao"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DMIC, 18, 0x1c0, 0x1c4, "dmic"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DP, 19, 0x1c0, 0x1c4, "dp"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DSI, 2, 0x1b8, 0x1bc, "dsi"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DSIB, 7, 0x1c0, 0x1c4, "dsib"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DSIC, 8, 0x1c0, 0x1c4, "dsic"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_DSID, 9, 0x1c0, 0x1c4, "dsid"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_EMMC, 3, 0x1c0, 0x1c4, "emmc"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_EMMC2, 5, 0x1c0, 0x1c4, "emmc2"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_GPIO, 27, 0x1b8, 0x1bc, "gpio"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_HDMI, 28, 0x1b8, 0x1bc, "hdmi"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_HSIC, 19, 0x1b8, 0x1bc, "hsic"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_LVDS, 25, 0x1c0, 0x1c4, "lvds"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_MIPI_BIAS, 3, 0x1b8, 0x1bc, "mipi-bias"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_PEX_BIAS, 4, 0x1b8, 0x1bc, "pex-bias"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_PEX_CLK1, 5, 0x1b8, 0x1bc, "pex-clk1"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_PEX_CLK2, 6, 0x1b8, 0x1bc, "pex-clk2"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_PEX_CNTRL, UINT_MAX, UINT_MAX, UINT_MAX, "pex-cntrl"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_SDMMC1, 1, 0x1c0, 0x1c4, "sdmmc1"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_SDMMC3, 2, 0x1c0, 0x1c4, "sdmmc3"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_SPI, 14, 0x1c0, 0x1c4, "spi"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_SPI_HV, 15, 0x1c0, 0x1c4, "spi-hv"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_UART, 14, 0x1b8, 0x1bc, "uart"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_USB0, 9, 0x1b8, 0x1bc, "usb0"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_USB1, 10, 0x1b8, 0x1bc, "usb1"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_USB2, 11, 0x1b8, 0x1bc, "usb2"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_USB3, 18, 0x1b8, 0x1bc, "usb3"),
+	TEGRA_IO_PAD(TEGRA_IO_PAD_USB_BIAS, 12, 0x1b8, 0x1bc, "usb-bias"),
+};
+
+static const struct tegra_io_pad_vctrl tegra210b01_io_pad_vctrls[] = {
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_AUDIO, PMC_PWR_DET_VALUE, 5),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_AUDIO_HV, PMC_PWR_DET_VALUE, 18),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_CAM, PMC_PWR_DET_VALUE, 10),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_DBG, PMC_PWR_DET_VALUE, 19),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_DMIC, PMC_PWR_DET_VALUE, 20),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_GPIO, PMC_PWR_DET_VALUE, 21),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_PEX_CNTRL, PMC_PWR_DET_VALUE, 11),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_SDMMC1, PMC_PWR_DET_VALUE, 12),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_SDMMC3, PMC_PWR_DET_VALUE, 13),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_SPI, PMC_PWR_DET_VALUE, 22),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_SPI_HV, PMC_PWR_DET_VALUE, 23),
+	TEGRA_IO_PAD_VCTRL(TEGRA_IO_PAD_UART, PMC_PWR_DET_VALUE, 2),
+};
+
+static const struct pinctrl_pin_desc tegra210b01_pin_descs[] = {
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_AUDIO, "audio"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_AUDIO_HV, "audio-hv"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_CAM, "cam"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_CSIA, "csia"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_CSIB, "csib"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_CSIC, "csic"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_CSID, "csid"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_CSIE, "csie"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_CSIF, "csif"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DBG, "dbg"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DEBUG_NONAO, "debug-nonao"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DMIC, "dmic"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DP, "dp"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DSI, "dsi"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DSIB, "dsib"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DSIC, "dsic"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_DSID, "dsid"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_EMMC, "emmc"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_EMMC2, "emmc2"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_GPIO, "gpio"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_HDMI, "hdmi"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_HSIC, "hsic"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_LVDS, "lvds"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_MIPI_BIAS, "mipi-bias"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_PEX_BIAS, "pex-bias"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_PEX_CLK1, "pex-clk1"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_PEX_CLK2, "pex-clk2"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_PEX_CNTRL, "pex-cntrl"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_SDMMC1, "sdmmc1"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_SDMMC3, "sdmmc3"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_SPI, "spi"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_SPI_HV, "spi-hv"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_UART, "uart"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_USB0, "usb0"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_USB1, "usb1"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_USB2, "usb2"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_USB3, "usb3"),
+	TEGRA_IO_PIN_DESC(TEGRA_IO_PAD_USB_BIAS, "usb-bias"),
+};
+
+static const struct tegra_pmc_soc tegra210b01_pmc_soc = {
+	.supports_core_domain = false,
+	.num_powergates = ARRAY_SIZE(tegra210b01_powergates),
+	.powergates = tegra210b01_powergates,
+	.num_cpu_powergates = ARRAY_SIZE(tegra210_cpu_powergates),
+	.cpu_powergates = tegra210_cpu_powergates,
+	.has_tsense_reset = true,
+	.has_gpu_clamps = true,
+	.needs_mbist_war = false,
+	.has_io_pad_wren = false,
+	.maybe_tz_only = true,
+	.num_io_pads = ARRAY_SIZE(tegra210b01_io_pads),
+	.io_pads = tegra210b01_io_pads,
+	.num_io_pad_vctrls = ARRAY_SIZE(tegra210b01_io_pad_vctrls),
+	.io_pad_vctrls = tegra210b01_io_pad_vctrls,
+	.num_pin_descs = ARRAY_SIZE(tegra210b01_pin_descs),
+	.pin_descs = tegra210b01_pin_descs,
+	.regs = &tegra20_pmc_regs,
+	.init = tegra20_pmc_init,
+	.setup_irq_polarity = tegra20_pmc_setup_irq_polarity,
+	.powergate_set = tegra114_powergate_set,
+	.irq_set_wake = tegra210_pmc_irq_set_wake,
+	.irq_set_type = tegra210_pmc_irq_set_type,
+	.reset_sources = tegra210_reset_sources,
+	.num_reset_sources = ARRAY_SIZE(tegra210_reset_sources),
+	.reset_levels = NULL,
+	.num_reset_levels = 0,
+	.num_wake_events = ARRAY_SIZE(tegra210_wake_events),
+	.wake_events = tegra210_wake_events,
+	.pmc_clks_data = tegra_pmc_clks_data,
+	.num_pmc_clks = ARRAY_SIZE(tegra_pmc_clks_data),
+	.has_blink_output = true,
+	.has_usb_sleepwalk = true,
+	.has_single_mmio_aperture = true,
+};
+
 static const struct tegra_io_pad_soc tegra186_io_pads[] = {
 	TEGRA_IO_PAD(TEGRA_IO_PAD_CSIA, 0, 0x74, 0x78, "csia"),
 	TEGRA_IO_PAD(TEGRA_IO_PAD_CSIB, 1, 0x74, 0x78, "csib"),
@@ -4824,6 +4983,7 @@ static const struct of_device_id tegra_pmc_match[] = {
 	{ .compatible = "nvidia,tegra194-pmc", .data = &tegra194_pmc_soc },
 	{ .compatible = "nvidia,tegra186-pmc", .data = &tegra186_pmc_soc },
 	{ .compatible = "nvidia,tegra210-pmc", .data = &tegra210_pmc_soc },
+	{ .compatible = "nvidia,tegra210b01-pmc", .data = &tegra210b01_pmc_soc },
 	{ .compatible = "nvidia,tegra132-pmc", .data = &tegra124_pmc_soc },
 	{ .compatible = "nvidia,tegra124-pmc", .data = &tegra124_pmc_soc },
 	{ .compatible = "nvidia,tegra114-pmc", .data = &tegra114_pmc_soc },

-- 
2.54.0

