From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:20 +0400
Subject: [PATCH ath-next 14/16] wifi: ath11k: update hif and pci ops for
 QCN6122
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-14-86729521a75c@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=4286;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=KAfYNiJSlBqkx5nRUcT0tjr+2gqae9Hk9UcR8v+Y2kU=;
 b=tWmSWuokIX04sHQ/skHZfIGfbroeqBvobVRWhObbpfO2LDTFZnARd1W4ShuaoSn+DuIEIo2Gg
 0cmybhN6UJAA23f5a9T1hcSvLmUfA0+fR5KsqeXpXa93YAkgxWis5Ui
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add HIF and PCI ops for QCN6122. QCN6122 by default uses DP window 3.
However, this is configurable, so let's introduce a function to do that and
follow the existing register access code for (hybrid)AHB devices and use
DP window 1.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/ahb.c | 34 ++++++++++++++++++++++++++++++++++
 drivers/net/wireless/ath/ath11k/hif.h |  9 +++++++++
 drivers/net/wireless/ath/ath11k/qmi.c |  2 ++
 3 files changed, 45 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 1b9115311bed..03936f574c8d 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -892,6 +892,18 @@ static int ath11k_ahb_hif_resume(struct ath11k_base *ab)
 	return 0;
 }
 
+static void ath11k_ahb_config_static_window_qcn6122(struct ath11k_base *ab)
+{
+	u32 umac_window = FIELD_GET(ATH11K_PCI_WINDOW_VALUE_MASK, HAL_SEQ_WCSS_UMAC_OFFSET);
+	u32 ce_window = FIELD_GET(ATH11K_PCI_WINDOW_VALUE_MASK, HAL_CE_WFSS_CE_REG_BASE);
+	u32 window;
+
+	window = (umac_window) | (ce_window << 6);
+
+	iowrite32(ATH11K_PCI_WINDOW_ENABLE_BIT | window,
+		  ab->mem + ATH11K_PCI_WINDOW_REG_ADDRESS);
+}
+
 static const struct ath11k_hif_ops ath11k_ahb_hif_ops_ipq8074 = {
 	.start = ath11k_ahb_start,
 	.stop = ath11k_ahb_stop,
@@ -907,6 +919,24 @@ static const struct ath11k_hif_ops ath11k_ahb_hif_ops_ipq8074 = {
 	.ce_irq_disable = ath11k_ahb_ce_irq_disable_sync,
 };
 
+static const struct ath11k_hif_ops ath11k_ahb_hif_ops_qcn6122 = {
+	.start = ath11k_pcic_start,
+	.stop = ath11k_pcic_stop,
+	.read32 = ath11k_pcic_read32,
+	.write32 = ath11k_pcic_write32,
+	.read = NULL,
+	.irq_enable = ath11k_pcic_ext_irq_enable,
+	.irq_disable = ath11k_pcic_ext_irq_disable,
+	.get_msi_address =  ath11k_pcic_get_msi_address,
+	.get_user_msi_vector = ath11k_pcic_get_user_msi_assignment,
+	.map_service_to_pipe = ath11k_pcic_map_service_to_pipe,
+	.power_down = ath11k_ahb_power_down,
+	.power_up = ath11k_ahb_power_up,
+	.ce_irq_enable = ath11k_pci_enable_ce_irqs_except_wake_irq,
+	.ce_irq_disable = ath11k_pci_disable_ce_irqs_except_wake_irq,
+	.config_static_window = ath11k_ahb_config_static_window_qcn6122,
+};
+
 static const struct ath11k_hif_ops ath11k_ahb_hif_ops_wcn6750 = {
 	.start = ath11k_pcic_start,
 	.stop = ath11k_pcic_stop,
@@ -1638,6 +1668,10 @@ static int ath11k_ahb_probe(struct platform_device *pdev)
 		hif_ops = &ath11k_ahb_hif_ops_wcn6750;
 		pci_ops = &ath11k_ahb_pci_ops_wcn6750;
 		break;
+	case ATH11K_HW_QCN6122_HW10:
+		hif_ops = &ath11k_ahb_hif_ops_qcn6122;
+		pci_ops = &ath11k_ahb_pci_ops_wcn6750;
+		break;
 	default:
 		dev_err(&pdev->dev, "unsupported device type %d\n", hw_rev);
 		return -EOPNOTSUPP;
diff --git a/drivers/net/wireless/ath/ath11k/hif.h b/drivers/net/wireless/ath/ath11k/hif.h
index 017fed1b4bd1..2e1a4fedf139 100644
--- a/drivers/net/wireless/ath/ath11k/hif.h
+++ b/drivers/net/wireless/ath/ath11k/hif.h
@@ -32,6 +32,7 @@ struct ath11k_hif_ops {
 	void (*ce_irq_disable)(struct ath11k_base *ab);
 	void (*get_ce_msi_idx)(struct ath11k_base *ab, u32 ce_id, u32 *msi_idx);
 	void (*coredump_download)(struct ath11k_base *ab);
+	void (*config_static_window)(struct ath11k_base *ab);
 };
 
 static inline void ath11k_hif_ce_irq_enable(struct ath11k_base *ab)
@@ -159,4 +160,12 @@ static inline void ath11k_hif_coredump_download(struct ath11k_base *ab)
 		ab->hif.ops->coredump_download(ab);
 }
 
+static inline void ath11k_hif_config_static_window(struct ath11k_base *ab)
+{
+	if (!ab->hw_params.static_window_map || !ab->hif.ops->config_static_window)
+		return;
+
+	ab->hif.ops->config_static_window(ab);
+}
+
 #endif /* _HIF_H_ */
diff --git a/drivers/net/wireless/ath/ath11k/qmi.c b/drivers/net/wireless/ath/ath11k/qmi.c
index 771ef9b5304f..7d77f5c8c609 100644
--- a/drivers/net/wireless/ath/ath11k/qmi.c
+++ b/drivers/net/wireless/ath/ath11k/qmi.c
@@ -2243,6 +2243,8 @@ static int ath11k_qmi_request_device_info(struct ath11k_base *ab)
 	if (!ab->hw_params.ce_remap)
 		ab->mem_ce = ab->mem;
 
+	ath11k_hif_config_static_window(ab);
+
 	return 0;
 out:
 	return ret;

-- 
2.53.0

