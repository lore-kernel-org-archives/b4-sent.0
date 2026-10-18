From: Aaron Kling <webgeek1234@gmail.com>
Date: Sun, 18 Oct 2026 17:20:34 -0500
Subject: [PATCH] thermal: tegra: Add Tegra210B01 Support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-t210b01-thermal-v1-1-af15746d86a3@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avIrBN0sISuEi3MphooC5UIpLsnL
 d/i/wKJIlOCXhSIdHPiM1ToRoDfXFhJ8lwNqLBTVhuZUatJaZk3iofbJaKlzi8zttZAra5ICz/
 /cRjf9wNRmrJbYQAAAA==
X-Change-ID: 20260714-t210b01-thermal-227e6cfd2574
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: linux-pm@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Srikar Srimath Tirumala <srikars@nvidia.com>, 
 Eugene Vernik <crimsonslayer76@gmail.com>, 
 Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792362045; l=8514;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=tasHCnJCsRYbeWivlJvsHpb3bzuaoA6s/dlDC0QLHE8=;
 b=cu6omQ6B4u1Lx3XbAu0A4hkEOuNQzHB6vuHd9TmEv3j/xfc5IAD1DUSL1bFCnVPauRsq735xe
 QLo3u/Ynt3+Chb8FUHtwb4P3tgekHKV1neMPZdYI5wWL96KD/DrqX7P
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Tegra210B01 SOC_THERM configuration. There are two main differences
from the original Tegra210:

* There is no mem thermal sensor
* Pdiv and pdiv_ate differ

Based-on: https://gitlab.com/nvidia/nv-tegra/linux-5.10/-/commit/b15149a15154e6b2fc827f4f169e37c9e5b389d9
Based-on-patch-by: Srikar Srimath Tirumala <srikars@nvidia.com>
Co-developed-by: Eugene Vernik <crimsonslayer76@gmail.com>
Signed-off-by: Eugene Vernik <crimsonslayer76@gmail.com>
Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
thermal: tegra: Add Tegra210B01 Support
---
 drivers/thermal/tegra/soctherm.c          |   4 +
 drivers/thermal/tegra/soctherm.h          |   1 +
 drivers/thermal/tegra/tegra210-soctherm.c | 133 ++++++++++++++++++++++++++++++
 3 files changed, 138 insertions(+)

diff --git a/drivers/thermal/tegra/soctherm.c b/drivers/thermal/tegra/soctherm.c
index d8e988a0d43e9..95451d1bd4e62 100644
--- a/drivers/thermal/tegra/soctherm.c
+++ b/drivers/thermal/tegra/soctherm.c
@@ -2082,6 +2082,10 @@ static const struct of_device_id tegra_soctherm_of_match[] = {
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
index aa4af9268b05d..4bc1e44e28827 100644
--- a/drivers/thermal/tegra/soctherm.h
+++ b/drivers/thermal/tegra/soctherm.h
@@ -156,6 +156,7 @@ extern const struct tegra_soctherm_soc tegra132_soctherm;
 
 #ifdef CONFIG_ARCH_TEGRA_210_SOC
 extern const struct tegra_soctherm_soc tegra210_soctherm;
+extern const struct tegra_soctherm_soc tegra210b01_soctherm;
 #endif
 
 #endif
diff --git a/drivers/thermal/tegra/tegra210-soctherm.c b/drivers/thermal/tegra/tegra210-soctherm.c
index f6e1493f0202f..b4f2c7837fd69 100644
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
@@ -63,6 +71,25 @@ static const struct tegra_tsensor_group tegra210_tsensor_group_cpu = {
 	.thermctl_lvl0_dn_thresh_mask = TEGRA210_THERMCTL_LVL0_DN_THRESH_MASK,
 };
 
+static const struct tegra_tsensor_group tegra210b01_tsensor_group_cpu = {
+	.id = TEGRA124_SOCTHERM_SENSOR_CPU,
+	.name = "cpu",
+	.sensor_temp_offset = SENSOR_TEMP1,
+	.sensor_temp_mask = SENSOR_TEMP1_CPU_TEMP_MASK,
+	.pdiv = 12,
+	.pdiv_ate = 6,
+	.pdiv_mask = SENSOR_PDIV_CPU_MASK,
+	.pllx_hotspot_diff = 10,
+	.pllx_hotspot_mask = SENSOR_HOTSPOT_CPU_MASK,
+	.thermtrip_any_en_mask = TEGRA210_THERMTRIP_ANY_EN_MASK,
+	.thermtrip_enable_mask = TEGRA210_THERMTRIP_CPU_EN_MASK,
+	.thermtrip_threshold_mask = TEGRA210_THERMTRIP_CPU_THRESH_MASK,
+	.thermctl_isr_mask = THERM_IRQ_CPU_MASK,
+	.thermctl_lvl0_offset = THERMCTL_LEVEL0_GROUP_CPU,
+	.thermctl_lvl0_up_thresh_mask = TEGRA210_THERMCTL_LVL0_UP_THRESH_MASK,
+	.thermctl_lvl0_dn_thresh_mask = TEGRA210_THERMCTL_LVL0_DN_THRESH_MASK,
+};
+
 static const struct tegra_tsensor_group tegra210_tsensor_group_gpu = {
 	.id = TEGRA124_SOCTHERM_SENSOR_GPU,
 	.name = "gpu",
@@ -82,6 +109,25 @@ static const struct tegra_tsensor_group tegra210_tsensor_group_gpu = {
 	.thermctl_lvl0_dn_thresh_mask = TEGRA210_THERMCTL_LVL0_DN_THRESH_MASK,
 };
 
+static const struct tegra_tsensor_group tegra210b01_tsensor_group_gpu = {
+	.id = TEGRA124_SOCTHERM_SENSOR_GPU,
+	.name = "gpu",
+	.sensor_temp_offset = SENSOR_TEMP1,
+	.sensor_temp_mask = SENSOR_TEMP1_GPU_TEMP_MASK,
+	.pdiv = 12,
+	.pdiv_ate = 6,
+	.pdiv_mask = SENSOR_PDIV_GPU_MASK,
+	.pllx_hotspot_diff = 5,
+	.pllx_hotspot_mask = SENSOR_HOTSPOT_GPU_MASK,
+	.thermtrip_any_en_mask = TEGRA210_THERMTRIP_ANY_EN_MASK,
+	.thermtrip_enable_mask = TEGRA210_THERMTRIP_GPU_EN_MASK,
+	.thermtrip_threshold_mask = TEGRA210_THERMTRIP_GPUMEM_THRESH_MASK,
+	.thermctl_isr_mask = THERM_IRQ_GPU_MASK,
+	.thermctl_lvl0_offset = THERMCTL_LEVEL0_GROUP_GPU,
+	.thermctl_lvl0_up_thresh_mask = TEGRA210_THERMCTL_LVL0_UP_THRESH_MASK,
+	.thermctl_lvl0_dn_thresh_mask = TEGRA210_THERMCTL_LVL0_DN_THRESH_MASK,
+};
+
 static const struct tegra_tsensor_group tegra210_tsensor_group_pll = {
 	.id = TEGRA124_SOCTHERM_SENSOR_PLLX,
 	.name = "pll",
@@ -99,6 +145,23 @@ static const struct tegra_tsensor_group tegra210_tsensor_group_pll = {
 	.thermctl_lvl0_dn_thresh_mask = TEGRA210_THERMCTL_LVL0_DN_THRESH_MASK,
 };
 
+static const struct tegra_tsensor_group tegra210b01_tsensor_group_pll = {
+	.id = TEGRA124_SOCTHERM_SENSOR_PLLX,
+	.name = "pll",
+	.sensor_temp_offset = SENSOR_TEMP2,
+	.sensor_temp_mask = SENSOR_TEMP2_PLLX_TEMP_MASK,
+	.pdiv = 12,
+	.pdiv_ate = 6,
+	.pdiv_mask = SENSOR_PDIV_PLLX_MASK,
+	.thermtrip_any_en_mask = TEGRA210_THERMTRIP_ANY_EN_MASK,
+	.thermtrip_enable_mask = TEGRA210_THERMTRIP_TSENSE_EN_MASK,
+	.thermtrip_threshold_mask = TEGRA210_THERMTRIP_TSENSE_THRESH_MASK,
+	.thermctl_isr_mask = THERM_IRQ_TSENSE_MASK,
+	.thermctl_lvl0_offset = THERMCTL_LEVEL0_GROUP_TSENSE,
+	.thermctl_lvl0_up_thresh_mask = TEGRA210_THERMCTL_LVL0_UP_THRESH_MASK,
+	.thermctl_lvl0_dn_thresh_mask = TEGRA210_THERMCTL_LVL0_DN_THRESH_MASK,
+};
+
 static const struct tegra_tsensor_group tegra210_tsensor_group_mem = {
 	.id = TEGRA124_SOCTHERM_SENSOR_MEM,
 	.name = "mem",
@@ -125,6 +188,12 @@ static const struct tegra_tsensor_group *tegra210_tsensor_groups[] = {
 	&tegra210_tsensor_group_mem,
 };
 
+static const struct tegra_tsensor_group *tegra210b01_tsensor_groups[] = {
+	&tegra210b01_tsensor_group_cpu,
+	&tegra210b01_tsensor_group_gpu,
+	&tegra210b01_tsensor_group_pll,
+};
+
 static const struct tegra_tsensor tegra210_tsensors[] = {
 	{
 		.name = "cpu0",
@@ -193,6 +262,58 @@ static const struct tegra_tsensor tegra210_tsensors[] = {
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
+		.group = &tegra210b01_tsensor_group_cpu,
+	}, {
+		.name = "cpu1",
+		.base = 0xe0,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x084,
+		.fuse_corr_alpha = 1126200,
+		.fuse_corr_beta = -67500,
+		.group = &tegra210b01_tsensor_group_cpu,
+	}, {
+		.name = "cpu2",
+		.base = 0x100,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x088,
+		.fuse_corr_alpha = 1098400,
+		.fuse_corr_beta = 2251100,
+		.group = &tegra210b01_tsensor_group_cpu,
+	}, {
+		.name = "cpu3",
+		.base = 0x120,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x12c,
+		.fuse_corr_alpha = 1108000,
+		.fuse_corr_beta = 602700,
+		.group = &tegra210b01_tsensor_group_cpu,
+	}, {
+		.name = "gpu",
+		.base = 0x180,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x154,
+		.fuse_corr_alpha = 1074300,
+		.fuse_corr_beta = 2734900,
+		.group = &tegra210b01_tsensor_group_gpu,
+	}, {
+		.name = "pllx",
+		.base = 0x1a0,
+		.config = &tegra210b01_tsensor_config,
+		.calib_fuse_offset = 0x160,
+		.fuse_corr_alpha = 1039700,
+		.fuse_corr_beta = 6829100,
+		.group = &tegra210b01_tsensor_group_pll,
+	},
+};
+
 /*
  * Mask/shift bits in FUSE_TSENSOR_COMMON and
  * FUSE_TSENSOR_COMMON, which are described in
@@ -230,3 +351,15 @@ const struct tegra_soctherm_soc tegra210_soctherm = {
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

---
base-commit: 49362394dad7df66c274c867a271394c10ca2bb8
change-id: 20260714-t210b01-thermal-227e6cfd2574

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

