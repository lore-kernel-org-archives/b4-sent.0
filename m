From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 29 Oct 2025 18:26:26 +0400
Subject: [PATCH 5/6] wifi: ath11k: add multipd support for QCN6122
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251029-ath11k-qcn6122-v1-5-58ed68eba333@outlook.com>
References: <20251029-ath11k-qcn6122-v1-0-58ed68eba333@outlook.com>
In-Reply-To: <20251029-ath11k-qcn6122-v1-0-58ed68eba333@outlook.com>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761747997; l=4796;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=wfJCOLdDasJ1dIO5v/sGeipzvLRwEDiv/orAU1lK7ig=;
 b=hO0zotmMQKU+pCPVaXheybqxYq7jqzphqz6cWD2fnXPgd+2NjHxivZauWEc/hytJBOkvZTdxI
 d1kgbvTamTRBaBSJvpwgXeQ1Qqa0QsR6K7H9Q/BXYEDMSzYLjoB53V/
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IPQ5018/QCN6122 platforms use multi PD (protection domains) to avoid
having one instance of the running Q6 firmware crashing resulting in
crashing the others.

The IPQ5018 platform can have up to two QCN6122 wifi chips.
To differentiate the two, the PD instance number (1 or 2) is added to
the QMI service instance ID, which the QCN6122 firmware also expects.
IPQ5018 internal wifi is always the first PD while QCN6122 cards must be
second or third.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
See below patch for more info:
https://lore.kernel.org/all/20231110091939.3025413-1-quic_mmanikan@quicinc.com/
---
 drivers/net/wireless/ath/ath11k/ahb.c  | 31 +++++++++++++++++++++++++++++++
 drivers/net/wireless/ath/ath11k/core.h |  4 ++++
 drivers/net/wireless/ath/ath11k/pci.c  |  1 +
 3 files changed, 36 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 7b267dd62e964b2c4d6c3bbe016abd1ad0297219..820a383e88caf125892176e421b0121fed7e7055 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -429,6 +429,7 @@ static void ath11k_ahb_init_qmi_ce_config(struct ath11k_base *ab)
 	cfg->svc_to_ce_map_len = ab->hw_params.svc_to_ce_map_len;
 	cfg->svc_to_ce_map = ab->hw_params.svc_to_ce_map;
 	ab->qmi.service_ins_id = ab->hw_params.qmi_service_ins_id;
+	ab->qmi.service_ins_id += ab->userpd_id;
 }
 
 static void ath11k_ahb_free_ext_irq(struct ath11k_base *ab)
@@ -1101,6 +1102,28 @@ static int ath11k_ahb_fw_resources_init(struct ath11k_base *ab)
 	return ret;
 }
 
+static int ath11k_get_userpd_id(struct device *dev, int *userpd)
+{
+	int ret, userpd_id;
+
+	ret = of_property_read_u32(dev->of_node, "qcom,userpd", &userpd_id);
+
+	if (ret)
+		return ret;
+
+	switch (userpd_id) {
+	case 2:
+		*userpd = ATH11K_QCN6122_USERPD_2;
+		break;
+	case 3:
+		*userpd = ATH11K_QCN6122_USERPD_3;
+		break;
+	default:
+		return -EINVAL;
+	}
+	return 0;
+}
+
 static int ath11k_ahb_fw_resource_deinit(struct ath11k_base *ab)
 {
 	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
@@ -1142,6 +1165,7 @@ static int ath11k_ahb_probe(struct platform_device *pdev)
 	const struct ath11k_hif_ops *hif_ops;
 	const struct ath11k_pci_ops *pci_ops;
 	enum ath11k_hw_rev hw_rev;
+	int userpd_id = 0;
 	int ret;
 
 	hw_rev = (uintptr_t)device_get_match_data(&pdev->dev);
@@ -1160,6 +1184,12 @@ static int ath11k_ahb_probe(struct platform_device *pdev)
 	case ATH11K_HW_QCN6122_HW10:
 		hif_ops = &ath11k_ahb_hif_ops_qcn6122;
 		pci_ops = &ath11k_ahb_pci_ops_wcn6750;
+		ret = ath11k_get_userpd_id(&pdev->dev, &userpd_id);
+		if (ret) {
+			dev_err(&pdev->dev, "failed to get userpd: %d\n", ret);
+			return ret;
+		}
+		dev_info(&pdev->dev, "multi-pd architecture - userpd: %d\n", userpd_id);
 		break;
 	default:
 		dev_err(&pdev->dev, "unsupported device type %d\n", hw_rev);
@@ -1182,6 +1212,7 @@ static int ath11k_ahb_probe(struct platform_device *pdev)
 	ab->hif.ops = hif_ops;
 	ab->pdev = pdev;
 	ab->hw_rev = hw_rev;
+	ab->userpd_id = userpd_id;
 	ab->fw_mode = ATH11K_FIRMWARE_MODE_NORMAL;
 	platform_set_drvdata(pdev, ab);
 
diff --git a/drivers/net/wireless/ath/ath11k/core.h b/drivers/net/wireless/ath/ath11k/core.h
index afc591f9608f48506bf19851169828c519661d72..87e047c9a0debc35aa3d37cb0125e741085f73d9 100644
--- a/drivers/net/wireless/ath/ath11k/core.h
+++ b/drivers/net/wireless/ath/ath11k/core.h
@@ -48,6 +48,9 @@
 #define ATH11K_INVALID_HW_MAC_ID	0xFF
 #define ATH11K_CONNECTION_LOSS_HZ	(3 * HZ)
 
+#define	ATH11K_QCN6122_USERPD_2		1
+#define	ATH11K_QCN6122_USERPD_3		2
+
 /* SMBIOS type containing Board Data File Name Extension */
 #define ATH11K_SMBIOS_BDF_EXT_TYPE 0xF8
 
@@ -969,6 +972,7 @@ struct ath11k_base {
 	struct list_head peers;
 	wait_queue_head_t peer_mapping_wq;
 	u8 mac_addr[ETH_ALEN];
+	int userpd_id;
 	int irq_num[ATH11K_IRQ_NUM_MAX];
 	struct ath11k_ext_irq_grp ext_irq_grp[ATH11K_EXT_IRQ_GRP_NUM_MAX];
 	struct ath11k_targ_cap target_caps;
diff --git a/drivers/net/wireless/ath/ath11k/pci.c b/drivers/net/wireless/ath/ath11k/pci.c
index d8655badd96d0f4b6946f8af927d878aaa3147ad..89b882bdf08446fd2d429d9a360c90f68c740bdb 100644
--- a/drivers/net/wireless/ath/ath11k/pci.c
+++ b/drivers/net/wireless/ath/ath11k/pci.c
@@ -383,6 +383,7 @@ static void ath11k_pci_init_qmi_ce_config(struct ath11k_base *ab)
 	cfg->svc_to_ce_map = ab->hw_params.svc_to_ce_map;
 	cfg->svc_to_ce_map_len = ab->hw_params.svc_to_ce_map_len;
 	ab->qmi.service_ins_id = ab->hw_params.qmi_service_ins_id;
+	ab->qmi.service_ins_id += ab->userpd_id;
 
 	ath11k_ce_get_shadow_config(ab, &cfg->shadow_reg_v2,
 				    &cfg->shadow_reg_v2_len);

-- 
2.51.1

