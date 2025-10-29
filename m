From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 29 Oct 2025 18:26:23 +0400
Subject: [PATCH 2/6] wifi: ath11k: add hw params for QCN6122
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251029-ath11k-qcn6122-v1-2-58ed68eba333@outlook.com>
References: <20251029-ath11k-qcn6122-v1-0-58ed68eba333@outlook.com>
In-Reply-To: <20251029-ath11k-qcn6122-v1-0-58ed68eba333@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761747997; l=4833;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=336+JRp6PC1s0koOSi14k/NRUhAY+mOyBfj5s8eLX8o=;
 b=Y08LUfTlUvGw10fN0S/pS3+157GXIWOr8HGsSX5NmErFynLJxOd4MCO0DqxDIRAMUox5IVfTn
 +C2CxiOa616CGcViwJTkqWJ69Ikj1KMOdjb7nS90S5gaLrByptYjRKO
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add QCN6122 platform support.

QCN6122 is a PCIe based solution that is attached to and enumerated
by the WPSS (Wireless Processor SubSystem) Q6 processor.

Though it is a PCIe device, since it is not attached to APSS processor
(Application Processor SubSystem), APSS will be unaware of such a decice
so it is registered to the APSS processor as a platform device (AHB).
Because of this hybrid nature, it is called as a hybrid bus device.

QCN6122 is similar to WCN6750 and follows the same codepath as for
WCN6750 though it does not support shadow regs.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/core.c | 67 ++++++++++++++++++++++++++++++++++
 drivers/net/wireless/ath/ath11k/core.h |  1 +
 drivers/net/wireless/ath/ath11k/qmi.h  |  3 +-
 3 files changed, 70 insertions(+), 1 deletion(-)

diff --git a/drivers/net/wireless/ath/ath11k/core.c b/drivers/net/wireless/ath/ath11k/core.c
index 2810752260f2f7eee226f88d5aea7cdabe7e9ed4..401b843402c6cca0e7fdd61e68b57fa6d5a6ae7e 100644
--- a/drivers/net/wireless/ath/ath11k/core.c
+++ b/drivers/net/wireless/ath/ath11k/core.c
@@ -907,6 +907,73 @@ static const struct ath11k_hw_params ath11k_hw_params[] = {
 		.support_dual_stations = true,
 		.pdev_suspend = false,
 	},
+	{
+		.hw_rev = ATH11K_HW_QCN6122_HW10,
+		.name = "qcn6122 hw1.0",
+		.fw = {
+			.dir = "QCN6122/hw1.0",
+			.board_size = 256 * 1024,
+			.cal_offset = 128 * 1024,
+		},
+		.hal_params = &ath11k_hw_hal_params_ipq8074,
+		.max_radios = MAX_RADIOS_5018,
+		.bdf_addr = 0x4D200000,
+		.hw_ops = &ipq5018_ops,
+		.hal_desc_sz = sizeof(struct hal_rx_desc_qcn9074),
+		.qmi_service_ins_id = ATH11K_QMI_WLFW_SERVICE_INS_ID_V01_QCN6122,
+		.interface_modes = BIT(NL80211_IFTYPE_STATION) |
+					BIT(NL80211_IFTYPE_AP) |
+					BIT(NL80211_IFTYPE_MESH_POINT),
+		.spectral = {
+			.fft_sz = 2,
+			.fft_pad_sz = 0,
+			.summary_pad_sz = 16,
+			.fft_hdr_len = 24,
+			.max_fft_bins = 1024,
+		},
+		.internal_sleep_clock = false,
+		.regs = &wcn6750_regs,
+		.credit_flow = false,
+		.max_tx_ring = 1,
+		.supports_monitor = true,
+		.supports_shadow_regs = false,
+		.idle_ps = false,
+		.supports_suspend = false,
+		.host_ce_config = ath11k_host_ce_config_qcn9074,
+		.ce_count = CE_CNT_5018,
+		.target_ce_config = ath11k_target_ce_config_wlan_ipq5018,
+		.target_ce_count = TARGET_CE_CNT_5018,
+		.svc_to_ce_map = ath11k_target_service_to_ce_map_wlan_ipq5018,
+		.svc_to_ce_map_len = SVC_CE_MAP_LEN_5018,
+		.single_pdev_only = false,
+		.rxdma1_enable = true,
+		.num_rxdma_per_pdev = RXDMA_PER_PDEV_5018,
+		.rx_mac_buf_ring = false,
+		.vdev_start_delay = false,
+		.htt_peer_map_v2 = true,
+		.coldboot_cal_mm = false,
+		.coldboot_cal_ftm = false,
+		.cbcal_restart_fw = true,
+		.fix_l1ss = true,
+		.alloc_cacheable_memory = true,
+		.m3_fw_support = false,
+		.fixed_bdf_addr = true,
+		.fixed_mem_region = true,
+		.static_window_map = true,
+		.hybrid_bus_type = true,
+		.fw_mem_mode = 1,
+		.supports_sta_ps = false,
+		.dbr_debug_support = true,
+		.bios_sar_capa = NULL,
+		.fixed_fw_mem = false,
+		.support_off_channel_tx = false,
+		.tcl_ring_retry = true,
+		.tx_ring_size = DP_TCL_DATA_RING_SIZE,
+		.smp2p_wow_exit = false,
+		.support_fw_mac_sequence = false,
+		.support_dual_stations = false,
+		.pdev_suspend = false,
+	},
 };
 
 static const struct dmi_system_id ath11k_pm_quirk_table[] = {
diff --git a/drivers/net/wireless/ath/ath11k/core.h b/drivers/net/wireless/ath/ath11k/core.h
index e8780b05ce11e39bdd93dd02d39812be90689b40..afc591f9608f48506bf19851169828c519661d72 100644
--- a/drivers/net/wireless/ath/ath11k/core.h
+++ b/drivers/net/wireless/ath/ath11k/core.h
@@ -152,6 +152,7 @@ enum ath11k_hw_rev {
 	ATH11K_HW_IPQ5018_HW10,
 	ATH11K_HW_QCA2066_HW21,
 	ATH11K_HW_QCA6698AQ_HW21,
+	ATH11K_HW_QCN6122_HW10,
 };
 
 enum ath11k_firmware_mode {
diff --git a/drivers/net/wireless/ath/ath11k/qmi.h b/drivers/net/wireless/ath/ath11k/qmi.h
index 7968ab122b65dc28a44eca7b34904f55f717f586..f6014b9662dbe5f4cfc6a2af7010938cad454267 100644
--- a/drivers/net/wireless/ath/ath11k/qmi.h
+++ b/drivers/net/wireless/ath/ath11k/qmi.h
@@ -22,10 +22,11 @@
 #define ATH11K_QMI_WLFW_SERVICE_INS_ID_V01_IPQ8074	0x02
 #define ATH11K_QMI_WLFW_SERVICE_INS_ID_V01_QCN9074	0x07
 #define ATH11K_QMI_WLFW_SERVICE_INS_ID_V01_WCN6750	0x03
+#define ATH11K_QMI_WLFW_SERVICE_INS_ID_V01_QCN6122	0x40
 #define ATH11K_QMI_WLANFW_MAX_TIMESTAMP_LEN_V01	32
 #define ATH11K_QMI_RESP_LEN_MAX			8192
 #define ATH11K_QMI_WLANFW_MAX_NUM_MEM_SEG_V01	52
-#define ATH11K_QMI_CALDB_SIZE			0x480000
+#define ATH11K_QMI_CALDB_SIZE			0x500000
 #define ATH11K_QMI_BDF_EXT_STR_LENGTH		0x20
 #define ATH11K_QMI_FW_MEM_REQ_SEGMENT_CNT	5
 

-- 
2.51.1

