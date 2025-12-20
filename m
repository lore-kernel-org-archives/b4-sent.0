From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Date: Sat, 20 Dec 2025 16:26:31 +0100
Subject: [PATCH v6 3/4] platform/surface: aggregator_registry: Add Surface
 Pro 11 (QCOM)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251220-surface-sp11-for-next-v6-3-81f7451edb77@gmail.com>
References: <20251220-surface-sp11-for-next-v6-0-81f7451edb77@gmail.com>
In-Reply-To: <20251220-surface-sp11-for-next-v6-0-81f7451edb77@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Maximilian Luz <luzmaximilian@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jeff Johnson <jjohnson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, ath12k@lists.infradead.org, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Dale Whinham <daleyo@gmail.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766244472; l=2027;
 i=jerome.debretagne@gmail.com; s=20251217; h=from:subject:message-id;
 bh=T3FVcCFZemvYy2B2tfWs5X5U9WEV1cgBV3QQZBYuEGE=;
 b=yGgnk7WT0PhLT7Kz1WPWzhTkpz50FfTMIYW9V3oNbOHzBVBrf/zIa4Yq3PgeYUBZJ8pCL2cWi
 zxFRd+mElrWA+KP9reQ1fvPvM5BMSiNzU/JCufIoUrTExmS6g//6goY
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=DcPD9n3oDMsPkt+12tU96swmGb5H86cxt+yiEVcUEGk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20251217 with auth_id=580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Dale Whinham <daleyo@gmail.com>

This enables support for the Qualcomm-based Surface Pro 11.

Signed-off-by: Dale Whinham <daleyo@gmail.com>
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
Reviewed-by: Maximilian Luz <luzmaximilian@gmail.com>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
---
 drivers/platform/surface/surface_aggregator_registry.c | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/drivers/platform/surface/surface_aggregator_registry.c b/drivers/platform/surface/surface_aggregator_registry.c
index 78ac3a8fbb736384f7e50f1888a71297a892a7c3..0599d5adf02e61583cf3e1fc11000070f51f7be3 100644
--- a/drivers/platform/surface/surface_aggregator_registry.c
+++ b/drivers/platform/surface/surface_aggregator_registry.c
@@ -406,6 +406,22 @@ static const struct software_node *ssam_node_group_sp9_5g[] = {
 	NULL,
 };
 
+/* Devices for Surface Pro 11 (ARM/QCOM) */
+static const struct software_node *ssam_node_group_sp11[] = {
+	&ssam_node_root,
+	&ssam_node_hub_kip,
+	&ssam_node_bat_ac,
+	&ssam_node_bat_main,
+	&ssam_node_tmp_sensors,
+	&ssam_node_hid_kip_keyboard,
+	&ssam_node_hid_kip_penstash,
+	&ssam_node_hid_kip_touchpad,
+	&ssam_node_hid_kip_fwupd,
+	&ssam_node_hid_sam_sensors,
+	&ssam_node_kip_tablet_switch,
+	NULL,
+};
+
 /* -- SSAM platform/meta-hub driver. ---------------------------------------- */
 
 static const struct acpi_device_id ssam_platform_hub_acpi_match[] = {
@@ -482,6 +498,8 @@ MODULE_DEVICE_TABLE(acpi, ssam_platform_hub_acpi_match);
 static const struct of_device_id ssam_platform_hub_of_match[] __maybe_unused = {
 	/* Surface Pro 9 5G (ARM/QCOM) */
 	{ .compatible = "microsoft,arcata", (void *)ssam_node_group_sp9_5g },
+	/* Surface Pro 11 (ARM/QCOM) */
+	{ .compatible = "microsoft,denali", (void *)ssam_node_group_sp11 },
 	/* Surface Laptop 7 */
 	{ .compatible = "microsoft,romulus13", (void *)ssam_node_group_sl7 },
 	{ .compatible = "microsoft,romulus15", (void *)ssam_node_group_sl7 },

-- 
2.47.3

