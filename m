From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:10 +0400
Subject: [PATCH ath-next 04/16] wifi: ath11k: Add support for loading m3
 mbn firmware
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-4-86729521a75c@outlook.com>
References: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
In-Reply-To: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vignesh Viswanathan <vignesh.viswanathan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=10329;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=b8Zwusm7H6v4vsfbn9Gmvu7jm5Rc6Udk2jN5W6UTq0I=;
 b=YwAx/XlVOYQPqU/hTQeqMwskJ+PKx0sZif1StO+0evCwNHHNbk6Ag7aQrgNoCN9WPRWdvWs7j
 6IZc8YupXZ0A0AawVfBGohNsQ0/GyIMfPwpAA9+or1VksU6/SJpRIHp
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for loading m3 firmware in MDT file format which is
different from the m3.bin file format. This is required for several
ath11k wifi chips such as IPQ5018.

The rproc driver is used to load the Q6 firmware binaries / MDT segments
into memory for the root PD and user PDs if present. However, the m3
firmware blob is not. The m3 firmware in MBN (MDT) format is loaded by
ath11k as part of the root PD boot sequence for AHB platform chips.

For chips for which the m3 firmware is outside of the Q6 memory
carveout, obtain the memory region from the device tree and load the m3
firmware into that region. Otherwise, fall back to the Q6 memory region
of the rproc node itself.

Keep track of whether m3 firmware has been loaded in the global
rproc_info struct using a bitmap. In a configuration with multiple
wifi chips of the same hardware revision, the m3 firmware requires to be
loaded only once.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/ahb.c  | 65 ++++++++++++++++++++++++++++++++++
 drivers/net/wireless/ath/ath11k/ahb.h  |  3 ++
 drivers/net/wireless/ath/ath11k/core.c | 12 ++++++-
 drivers/net/wireless/ath/ath11k/hw.h   |  8 +++++
 drivers/net/wireless/ath/ath11k/qmi.c  |  6 ++--
 5 files changed, 91 insertions(+), 3 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 86723a2eb3d2..9fe2e112dfb8 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -18,6 +18,7 @@
 #include "qmi.h"
 #include <linux/remoteproc.h>
 #include "pcic.h"
+#include <linux/soc/qcom/mdt_loader.h>
 #include <linux/soc/qcom/smem.h>
 #include <linux/soc/qcom/smem_state.h>
 
@@ -890,6 +891,7 @@ static struct ath11k_ahb_rproc_info *ath11k_ahb_rproc_info_alloc(struct ath11k_b
 		return NULL;
 
 	rproc_info->root_pd_booted = false;
+	rproc_info->m3_loaded = 0;
 	init_completion(&rproc_info->rootpd_ready);
 	ab_ahb->rproc_info = rproc_info;
 
@@ -962,6 +964,58 @@ static int ath11k_ahb_boot_root_pd(struct ath11k_base *ab)
 	return 0;
 }
 
+static int ath11k_ahb_load_m3_firmware(struct ath11k_base *ab)
+{
+	char m3_fw_name[ATH11K_FW_NAME_LEN];
+	const struct firmware *m3_fw = NULL;
+	struct device_node *node;
+	struct resource res = {};
+	phys_addr_t mem_phys;
+	void *mem_region;
+	size_t mem_size;
+	int ret;
+
+	ret = of_reserved_mem_region_to_resource_byname(ab->dev->of_node,
+							"m3-region", &res);
+	/* If m3 region isn't found, fall back to the mem region of the rproc */
+	if (ret && ret == -EINVAL) {
+		node = g_rproc_info->tgt_rproc->dev.parent->of_node;
+		ret = of_reserved_mem_region_to_resource(node, 0, &res);
+	}
+	if (ret) {
+		ath11k_err(ab, "Failed to get m3 memory resource: %d\n", ret);
+		return ret;
+	}
+
+	mem_phys = res.start;
+	mem_size = resource_size(&res);
+	mem_region = devm_memremap(ab->dev, mem_phys, mem_size, MEMREMAP_WC);
+
+	snprintf(m3_fw_name, sizeof(m3_fw_name), "%s/%s/%s",
+		 ATH11K_FW_DIR, ab->hw_params.fw.dir, ATH11K_M3_MBN_FILE);
+
+	ret = request_firmware(&m3_fw, m3_fw_name, ab->dev);
+	if (ret < 0) {
+		ath11k_err(ab, "Failed to request firmware: %d\n", ret);
+		return ret;
+	}
+
+	if (!m3_fw->size || m3_fw->size > mem_size) {
+		ath11k_err(ab, "Invalid firmware size\n");
+		release_firmware(m3_fw);
+		return -EINVAL;
+	}
+
+	ret = qcom_mdt_load_no_init(ab->dev, m3_fw, m3_fw_name, mem_region,
+				    mem_phys, mem_size, &mem_phys);
+	if (ret)
+		ath11k_err(ab, "Failed to load MDT segments: %d\n", ret);
+
+	release_firmware(m3_fw);
+
+	return ret;
+}
+
 static int ath11k_ahb_configure_rproc(struct ath11k_base *ab)
 {
 	int ret;
@@ -981,6 +1035,17 @@ static int ath11k_ahb_configure_rproc(struct ath11k_base *ab)
 		goto err_put_rproc;
 	}
 
+	if (ab->hw_params.m3_fw_support &&
+	    ab->hw_params.fw.m3_loader == ath11k_m3_fw_loader_ahb &&
+	    !(g_rproc_info->m3_loaded & BIT(ab->hw_params.hw_rev))) {
+		ret = ath11k_ahb_load_m3_firmware(ab);
+		if (ret) {
+			ath11k_err(ab, "failed to load m3 firmware: %d\n", ret);
+			goto err_unreg_notifier;
+		}
+		g_rproc_info->m3_loaded |= BIT(ab->hw_params.hw_rev);
+	}
+
 	if (g_rproc_info->tgt_rproc->state != RPROC_RUNNING) {
 		ret = ath11k_ahb_boot_root_pd(ab);
 		if (ret) {
diff --git a/drivers/net/wireless/ath/ath11k/ahb.h b/drivers/net/wireless/ath/ath11k/ahb.h
index 99a361e0091f..033d6223494b 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.h
+++ b/drivers/net/wireless/ath/ath11k/ahb.h
@@ -33,6 +33,9 @@ struct ath11k_ahb_rproc_info {
 	struct notifier_block root_pd_nb;
 	void *root_pd_notifier;
 	bool root_pd_booted;
+
+	/* Bitmap of loaded M3 firmwares indexed by hardware revision */
+	u32 m3_loaded;
 };
 
 struct ath11k_ahb {
diff --git a/drivers/net/wireless/ath/ath11k/core.c b/drivers/net/wireless/ath/ath11k/core.c
index d2ed6a0ea7e3..428f382e74a9 100644
--- a/drivers/net/wireless/ath/ath11k/core.c
+++ b/drivers/net/wireless/ath/ath11k/core.c
@@ -46,6 +46,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "IPQ8074/hw2.0",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_ahb,
 		},
 		.max_radios = 3,
 		.bdf_addr = 0x4B0C0000,
@@ -135,6 +136,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "IPQ6018/hw1.0",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_ahb,
 		},
 		.max_radios = 2,
 		.bdf_addr = 0x4ABC0000,
@@ -222,6 +224,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "QCA6390/hw2.0",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_qmi,
 		},
 		.max_radios = 3,
 		.bdf_addr = 0x4B0C0000,
@@ -314,6 +317,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "QCN9074/hw1.0",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_qmi,
 		},
 		.max_radios = 1,
 		.single_pdev_only = false,
@@ -400,6 +404,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "WCN6855/hw2.0",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_qmi,
 		},
 		.max_radios = 3,
 		.bdf_addr = 0x4B0C0000,
@@ -492,6 +497,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "WCN6855/hw2.1",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_qmi,
 		},
 		.max_radios = 3,
 		.bdf_addr = 0x4B0C0000,
@@ -582,6 +588,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "WCN6750/hw1.0",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_qmi,
 		},
 		.max_radios = 1,
 		.bdf_addr = 0x4B0C0000,
@@ -667,6 +674,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "IPQ5018/hw1.0",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_ahb,
 		},
 		.max_radios = MAX_RADIOS_5018,
 		.bdf_addr = 0x4BA00000,
@@ -724,7 +732,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 		.dbr_debug_support = true,
 		.global_reset = false,
 		.bios_sar_capa = NULL,
-		.m3_fw_support = false,
+		.m3_fw_support = true,
 		.fixed_bdf_addr = true,
 		.fixed_mem_region = true,
 		.static_window_map = false,
@@ -752,6 +760,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "QCA2066/hw2.1",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_qmi,
 		},
 		.max_radios = 3,
 		.bdf_addr = 0x4B0C0000,
@@ -843,6 +852,7 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 			.dir = "QCA6698AQ/hw2.1",
 			.board_size = 256 * 1024,
 			.cal_offset = 128 * 1024,
+			.m3_loader = ath11k_m3_fw_loader_qmi,
 		},
 		.max_radios = 3,
 		.bdf_addr = 0x4B0C0000,
diff --git a/drivers/net/wireless/ath/ath11k/hw.h b/drivers/net/wireless/ath/ath11k/hw.h
index 4996536fbd14..5a1100ceb895 100644
--- a/drivers/net/wireless/ath/ath11k/hw.h
+++ b/drivers/net/wireless/ath/ath11k/hw.h
@@ -72,6 +72,7 @@
 #define ATH11k_HW_RATECODE_CCK_SHORT_PREAM_MASK  0x4
 
 #define ATH11K_FW_DIR			"ath11k"
+#define ATH11K_FW_NAME_LEN		35
 
 #define ATH11K_BOARD_MAGIC		"QCA-ATH11K-BOARD"
 #define ATH11K_BOARD_API2_FILE		"board-2.bin"
@@ -79,6 +80,7 @@
 #define ATH11K_DEFAULT_CAL_FILE		"caldata.bin"
 #define ATH11K_AMSS_FILE		"amss.bin"
 #define ATH11K_M3_FILE			"m3.bin"
+#define ATH11K_M3_MBN_FILE		"m3_fw.mbn"
 #define ATH11K_REGDB_FILE_NAME		"regdb.bin"
 
 #define ATH11K_CE_OFFSET(ab)	(ab->mem_ce - ab->mem)
@@ -137,6 +139,11 @@ struct ath11k_hw_hal_params {
 	size_t num_tx_rings;
 };
 
+enum ath11k_m3_fw_loaders {
+	ath11k_m3_fw_loader_ahb,
+	ath11k_m3_fw_loader_qmi,
+};
+
 struct ath11k_hw_params {
 	const char *name;
 	u16 hw_rev;
@@ -147,6 +154,7 @@ struct ath11k_hw_params {
 		const char *dir;
 		size_t board_size;
 		size_t cal_offset;
+		enum ath11k_m3_fw_loaders m3_loader;
 	} fw;
 
 	const struct ath11k_hw_ops *hw_ops;
diff --git a/drivers/net/wireless/ath/ath11k/qmi.c b/drivers/net/wireless/ath/ath11k/qmi.c
index 7dc07339b957..bd81e8d3d5f7 100644
--- a/drivers/net/wireless/ath/ath11k/qmi.c
+++ b/drivers/net/wireless/ath/ath11k/qmi.c
@@ -1724,7 +1724,8 @@ int ath11k_qmi_host_cap_send(struct ath11k_base *ab)
 	req.bdf_support_valid = 1;
 	req.bdf_support = 1;
 
-	if (ab->hw_params.m3_fw_support) {
+	if (ab->hw_params.m3_fw_support &&
+	    ab->hw_params.fw.m3_loader == ath11k_m3_fw_loader_qmi) {
 		req.m3_support_valid = 1;
 		req.m3_support = 1;
 		req.m3_cache_support_valid = 1;
@@ -2589,7 +2590,8 @@ int ath11k_qmi_wlanfw_m3_info_send(struct ath11k_base *ab)
 	memset(&req, 0, sizeof(req));
 	memset(&resp, 0, sizeof(resp));
 
-	if (ab->hw_params.m3_fw_support) {
+	if (ab->hw_params.m3_fw_support &&
+	    ab->hw_params.fw.m3_loader == ath11k_m3_fw_loader_qmi) {
 		ret = ath11k_qmi_m3_load(ab);
 		if (ret) {
 			ath11k_err(ab, "failed to load m3 firmware: %d", ret);

-- 
2.53.0

