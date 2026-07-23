From: Aaron Kling <webgeek1234@gmail.com>
Date: Wed, 22 Jul 2026 21:46:48 -0500
Subject: [PATCH v3 2/2] soc/tegra: pmc: Add Tegra210B01 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260722-t210b01-pmc-v3-2-1c5b970788f2@gmail.com>
References: <20260722-t210b01-pmc-v3-0-1c5b970788f2@gmail.com>
In-Reply-To: <20260722-t210b01-pmc-v3-0-1c5b970788f2@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Thierry Reding <thierry.reding@gmail.com>, devicetree@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>, 
 Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Thomas Makin <halorocker89@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784774814; l=3862;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Y1pHP7vg6I2QmRiAaP+rGxaAo7nCvhZmwdrLipCbgNI=;
 b=6iwi7CxRktYp4fke9ya21qJEIFqPOeABdP5l/JWtOSbgOBAR0VNvZKeWKgFu/3FnW9rLsbd6M
 yToDu3QzuKQCkEJ8HBBhScxB4LyzeD0z7uqqYXM6jOgk6fONC6ulnnt
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Alexandre Hamamdjian <azkali.limited@gmail.com>

The PMC in Tegra210B01 is very similar to the one in the original
Tegra210, but has a few powergate differences. Specifically sata, venc,
and ve2 are removed.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
Co-developed-by: Thomas Makin <halorocker89@gmail.com>
Signed-off-by: Thomas Makin <halorocker89@gmail.com>
Co-developed-by: Aaron Kling <webgeek1234@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/soc/tegra/pmc.c | 61 +++++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 61 insertions(+)

diff --git a/drivers/soc/tegra/pmc.c b/drivers/soc/tegra/pmc.c
index f419a5395545f..d133f445e4ec4 100644
--- a/drivers/soc/tegra/pmc.c
+++ b/drivers/soc/tegra/pmc.c
@@ -3897,6 +3897,66 @@ static const struct tegra_pmc_soc tegra210_pmc_soc = {
 	.has_single_mmio_aperture = true,
 };
 
+static const char * const tegra210b01_powergates[] = {
+	[TEGRA_POWERGATE_CPU] = "crail",
+	[TEGRA_POWERGATE_3D] = "3d",
+	[TEGRA_POWERGATE_PCIE] = "pcie",
+	[TEGRA_POWERGATE_MPE] = "mpe",
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
+static const struct tegra_pmc_soc tegra210b01_pmc_soc = {
+	.supports_core_domain = false,
+	.num_powergates = ARRAY_SIZE(tegra210b01_powergates),
+	.powergates = tegra210b01_powergates,
+	.num_cpu_powergates = ARRAY_SIZE(tegra210_cpu_powergates),
+	.cpu_powergates = tegra210_cpu_powergates,
+	.has_tsense_reset = true,
+	.has_gpu_clamps = true,
+	.needs_mbist_war = false,
+	.has_io_pad_wren = true,
+	.maybe_tz_only = true,
+	.num_io_pads = ARRAY_SIZE(tegra210_io_pads),
+	.io_pads = tegra210_io_pads,
+	.num_io_pad_vctrls = ARRAY_SIZE(tegra210_io_pad_vctrls),
+	.io_pad_vctrls = tegra210_io_pad_vctrls,
+	.num_pin_descs = ARRAY_SIZE(tegra210_pin_descs),
+	.pin_descs = tegra210_pin_descs,
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
@@ -4824,6 +4884,7 @@ static const struct of_device_id tegra_pmc_match[] = {
 	{ .compatible = "nvidia,tegra194-pmc", .data = &tegra194_pmc_soc },
 	{ .compatible = "nvidia,tegra186-pmc", .data = &tegra186_pmc_soc },
 	{ .compatible = "nvidia,tegra210-pmc", .data = &tegra210_pmc_soc },
+	{ .compatible = "nvidia,tegra210b01-pmc", .data = &tegra210b01_pmc_soc },
 	{ .compatible = "nvidia,tegra132-pmc", .data = &tegra124_pmc_soc },
 	{ .compatible = "nvidia,tegra124-pmc", .data = &tegra124_pmc_soc },
 	{ .compatible = "nvidia,tegra114-pmc", .data = &tegra114_pmc_soc },

-- 
2.54.0

