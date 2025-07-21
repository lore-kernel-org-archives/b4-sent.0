From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 20 Jul 2025 21:15:07 -0500
Subject: [PATCH v2 13/17] thermal: tegra: Add Tegra210B01 Support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250720-t210b01-v2-13-9cb209f1edfc@gmail.com>
References: <20250720-t210b01-v2-0-9cb209f1edfc@gmail.com>
In-Reply-To: <20250720-t210b01-v2-0-9cb209f1edfc@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Nagarjuna Kristam <nkristam@nvidia.com>, JC Kuo <jckuo@nvidia.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Mathias Nyman <mathias.nyman@intel.com>, 
 Peter De Schrijver <pdeschrijver@nvidia.com>, 
 Prashant Gaikwad <pgaikwad@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-phy@lists.infradead.org, 
 linux-usb@vger.kernel.org, Thierry Reding <treding@nvidia.com>, 
 linux-pm@vger.kernel.org, linux-clk@vger.kernel.org, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1753064238; l=4742;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=X9sFXbY3g6CEPdEtGSFPcYYAsaj7iJ9O8yGRXMBB1/8=;
 b=ggKnfH9xMlNn0Qp31JU5+phLd2reqvQBOqTF1Qb/A00xYDJcwBJEeoLYcu65vS5VjXEBV5X1n
 Tk2SaTIS8kRAxptbF4THvDoiKw761VSZ04mk2qK3iq8coD1Lb7DhUPX
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Tegra210B01 SOC_THERM configuration

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
 drivers/thermal/tegra/soctherm.c          |  4 ++
 drivers/thermal/tegra/soctherm.h          |  1 +
 drivers/thermal/tegra/tegra210-soctherm.c | 78 +++++++++++++++++++++++++++++++
 3 files changed, 83 insertions(+)

diff --git a/drivers/thermal/tegra/soctherm.c b/drivers/thermal/tegra/soctherm.c
index 926f1052e6de04fc4d5ff78334b52ffe98cdf4ca..e07ae0e5553f38b78f30bb88a0e02aca995d7b5a 100644
--- a/drivers/thermal/tegra/soctherm.c
+++ b/drivers/thermal/tegra/soctherm.c
@@ -2065,6 +2065,10 @@ static const struct of_device_id tegra_soctherm_of_match[] = {
 		.compatible = "nvidia,tegra210-soctherm",
 		.data = &tegra210_soctherm,
 	},
+	{
+		.compatible = "nvidia,tegra210b01-soctherm",
+		.data = &tegra210b01_soctherm,
+	},
 #endif
 	{ },
 };
diff --git a/drivers/thermal/tegra/soctherm.h b/drivers/thermal/tegra/soctherm.h
index 70501e73d586230d3caca8dea0966afd7f23142a..0d80e739b67da23571137db0cc3140c8967fa071 100644
--- a/drivers/thermal/tegra/soctherm.h
+++ b/drivers/thermal/tegra/soctherm.h
@@ -147,6 +147,7 @@ extern const struct tegra_soctherm_soc tegra132_soctherm;
 
 #ifdef CONFIG_ARCH_TEGRA_210_SOC
 extern const struct tegra_soctherm_soc tegra210_soctherm;
+extern const struct tegra_soctherm_soc tegra210b01_soctherm;
 #endif
 
 #endif
diff --git a/drivers/thermal/tegra/tegra210-soctherm.c b/drivers/thermal/tegra/tegra210-soctherm.c
index d0ff793f18c561230497b57b325ae87f12a7b83a..b9871e12ec20c1f309ae6ff358fde4f5ce771ea8 100644
--- a/drivers/thermal/tegra/tegra210-soctherm.c
+++ b/drivers/thermal/tegra/tegra210-soctherm.c
@@ -44,6 +44,14 @@ static const struct tegra_tsensor_configuration tegra210_tsensor_config = {
 	.tsample_ate = 480,
 };
 
+static const struct tegra_tsensor_configuration tegra210b01_tsensor_config = {
+	.tall = 16300,
+	.tiddq_en = 1,
+	.ten_count = 1,
+	.tsample = 240,
+	.tsample_ate = 480,
+};
+
 static const struct tegra_tsensor_group tegra210_tsensor_group_cpu = {
 	.id = TEGRA124_SOCTHERM_SENSOR_CPU,
 	.name = "cpu",
@@ -125,6 +133,12 @@ static const struct tegra_tsensor_group *tegra210_tsensor_groups[] = {
 	&tegra210_tsensor_group_mem,
 };
 
+static const struct tegra_tsensor_group *tegra210b01_tsensor_groups[] = {
+	&tegra210_tsensor_group_cpu,
+	&tegra210_tsensor_group_gpu,
+	&tegra210_tsensor_group_pll,
+};
+
 static const struct tegra_tsensor tegra210_tsensors[] = {
 	{
 		.name = "cpu0",
@@ -193,6 +207,58 @@ static const struct tegra_tsensor tegra210_tsensors[] = {
 	},
 };
 
+static const struct tegra_tsensor tegra210b01_tsensors[] = {
+	{
+		.name = "cpu0",
+		.base = 0xc0,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x098,
+		.fuse_corr_alpha = 1085000,
+		.fuse_corr_beta = 3244200,
+		.group = &tegra210_tsensor_group_cpu,
+	}, {
+		.name = "cpu1",
+		.base = 0xe0,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x084,
+		.fuse_corr_alpha = 1126200,
+		.fuse_corr_beta = -67500,
+		.group = &tegra210_tsensor_group_cpu,
+	}, {
+		.name = "cpu2",
+		.base = 0x100,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x088,
+		.fuse_corr_alpha = 1098400,
+		.fuse_corr_beta = 2251100,
+		.group = &tegra210_tsensor_group_cpu,
+	}, {
+		.name = "cpu3",
+		.base = 0x120,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x12c,
+		.fuse_corr_alpha = 1108000,
+		.fuse_corr_beta = 602700,
+		.group = &tegra210_tsensor_group_cpu,
+	}, {
+		.name = "gpu",
+		.base = 0x180,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x154,
+		.fuse_corr_alpha = 1074300,
+		.fuse_corr_beta = 2734900,
+		.group = &tegra210_tsensor_group_gpu,
+	}, {
+		.name = "pllx",
+		.base = 0x1a0,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x160,
+		.fuse_corr_alpha = 1039700,
+		.fuse_corr_beta = 6829100,
+		.group = &tegra210_tsensor_group_pll,
+	},
+};
+
 /*
  * Mask/shift bits in FUSE_TSENSOR_COMMON and
  * FUSE_TSENSOR_COMMON, which are described in
@@ -226,3 +292,15 @@ const struct tegra_soctherm_soc tegra210_soctherm = {
 	.use_ccroc = false,
 	.thermtrips = tegra210_tsensor_thermtrips,
 };
+
+const struct tegra_soctherm_soc tegra210b01_soctherm = {
+	.tsensors = tegra210b01_tsensors,
+	.num_tsensors = ARRAY_SIZE(tegra210b01_tsensors),
+	.ttgs = tegra210b01_tsensor_groups,
+	.num_ttgs = ARRAY_SIZE(tegra210b01_tsensor_groups),
+	.tfuse = &tegra210_soctherm_fuse,
+	.thresh_grain = TEGRA210_THRESH_GRAIN,
+	.bptt = TEGRA210_BPTT,
+	.use_ccroc = false,
+	.thermtrips = tegra210_tsensor_thermtrips,
+};

-- 
2.50.1

