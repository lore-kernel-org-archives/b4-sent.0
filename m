From: George Moussalem <george.moussalem@outlook.com>
Date: Wed, 23 Sep 2026 16:05:13 +0400
Subject: [PATCH ath-next 07/16] wifi: ath11k: Register userPD interrupts
 and SMEM entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-7-86729521a75c@outlook.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=10055;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=7rpr5lypcGKAhre+UQc1WGPdhHabdKnP7DtLs3iPrPY=;
 b=WiChA4t5yACxD/OYP58ovQZ3RNhOIJsQOeGFLG4BJ7b/MvgrZrJ7/bfR4SDpFU2J03zT61yif
 sz/Egm+NbJhAjaD4q43JjOHAGrtB3OLTjEiKDmetlNA1HPo+nGnfUWQ
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Q6 and the ath11k driver communicate using SMEM and IRQs.

Spawn interrupt is triggered once the userPD thread is spawned.
Ready interrupts denote that the userPD is completely powered up and
ready. Stop-ack is to acknowledge the ath11k driver that userPD has
stopped.

The root PD sets the spawn and stop bits in SMEM upon boot which the
ath11k driver reads to derive the userPD ID.

Set the spawn bit in SMEM to instruct Q6 to spawn a userPD which brings
up the radio. Similarly, the stop bit is set when a userPD needs to be
stopped.

Keep track of the userPDs that have been spawned and stopped in the
global rproc_info structure to determine when the rootPD can be stopped.

Move boot and shutdown of the root PD to probe and remove functions
respectively. This is to ensure that the root PD is booted before any
userPDs are spawned. For non-MPD platforms, the this move has no
functional impact.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 drivers/net/wireless/ath/ath11k/ahb.c | 176 ++++++++++++++++++++++++++++++++--
 drivers/net/wireless/ath/ath11k/ahb.h |  25 +++++
 2 files changed, 191 insertions(+), 10 deletions(-)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 9fe2e112dfb8..25f9a992a7d2 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -22,6 +22,13 @@
 #include <linux/soc/qcom/smem.h>
 #include <linux/soc/qcom/smem_state.h>
 
+#define ATH11K_UPD_IRQ_WRD_LEN  18
+static const char *const ath11k_userpd_irq[ATH11K_USERPD_MAX_IRQ] = {
+	"spawn",
+	"ready",
+	"stop-ack",
+};
+
 static const struct of_device_id ath11k_ahb_of_match[] = {
 	/* TODO: Should we change the compatible string to something similar
 	 * to one that ath10k uses?
@@ -46,6 +53,15 @@ MODULE_DEVICE_TABLE(of, ath11k_ahb_of_match);
 #define ATH11K_IRQ_CE0_OFFSET 4
 
 /*
+ * Multi-UserPD Architecture:
+ *
+ * One Q6 RootPD (managed by separate rproc driver) supports multiple
+ * ath12k UserPDs. Each UserPD represents a WiFi radio instance.
+ *
+ * Lifecycle:
+ *  - RootPD boots when first UserPD probes
+ *  - All UserPDs share RootPD's SSR notifier
+ *
  * Global Driver-level Locking:
  *  - ath11k_rproc_info_lock: Protects rproc_info allocation/free
  */
@@ -831,6 +847,126 @@ static const struct ath11k_hif_ops ath11k_ahb_hif_ops_wcn6750 = {
 	.ce_irq_disable = ath11k_pci_disable_ce_irqs_except_wake_irq,
 };
 
+static int ath11k_ahb_init_userpd(struct ath11k_base *ab, int userpd_id)
+{
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
+
+	lockdep_assert_held(&ath11k_rproc_info_lock);
+
+	switch (ab->hw_rev) {
+	case ATH11K_HW_IPQ5018_HW10:
+		if (userpd_id != ATH11K_AHB_USERPD_ID_1)
+			return -EINVAL;
+
+		ab_ahb->userpd_id = userpd_id;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	g_rproc_info->userpd[userpd_id - 1] = ab_ahb;
+	g_rproc_info->num_userpd++;
+
+	return 0;
+}
+
+static irqreturn_t ath11k_userpd_irq_handler(int irq, void *data)
+{
+	struct ath11k_base *ab = data;
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
+
+	if (irq == ab_ahb->userpd_irq_num[ATH11K_USERPD_SPAWN_IRQ]) {
+		complete(&ab_ahb->userpd_spawned);
+	} else if (irq == ab_ahb->userpd_irq_num[ATH11K_USERPD_READY_IRQ]) {
+		complete(&ab_ahb->userpd_ready);
+	} else if (irq == ab_ahb->userpd_irq_num[ATH11K_USERPD_STOP_ACK_IRQ])	{
+		complete(&ab_ahb->userpd_stopped);
+	} else {
+		ath11k_err(ab, "Invalid userpd interrupt\n");
+		return IRQ_NONE;
+	}
+
+	return IRQ_HANDLED;
+}
+
+static void ath11k_ahb_cleanup_userpd(struct ath11k_base *ab)
+{
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
+	struct ath11k_ahb_rproc_info *rproc_info = ab_ahb->rproc_info;
+
+	lockdep_assert_held(&ath11k_rproc_info_lock);
+
+	if (!rproc_info)
+		return;
+
+	if (rproc_info && ab_ahb->userpd_id > 0 &&
+	    ab_ahb->userpd_id < ATH11K_AHB_USERPD_ID_MAX) {
+		rproc_info->userpd[ab_ahb->userpd_id - 1] = NULL;
+		rproc_info->num_userpd--;
+		ab_ahb->rproc_info = NULL;
+	}
+}
+
+static int ath11k_ahb_config_userpd_irq(struct ath11k_base *ab)
+{
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
+	char *upd_irq_name;
+	int userpd_id;
+	int i, ret;
+
+	ab_ahb->spawn_state = devm_qcom_smem_state_get(&ab->pdev->dev, "spawn",
+						       &ab_ahb->spawn_bit);
+	if (IS_ERR(ab_ahb->spawn_state))
+		return dev_err_probe(&ab->pdev->dev, PTR_ERR(ab_ahb->spawn_state),
+				     "Failed to acquire spawn state\n");
+
+	ab_ahb->stop_state = devm_qcom_smem_state_get(&ab->pdev->dev, "stop",
+						      &ab_ahb->stop_bit);
+	if (IS_ERR(ab_ahb->stop_state))
+		return dev_err_probe(&ab->pdev->dev, PTR_ERR(ab_ahb->stop_state),
+				     "Failed to acquire stop state\n");
+
+	mutex_lock(&ath11k_rproc_info_lock);
+
+	userpd_id = ab_ahb->spawn_bit / 8;
+	ret = ath11k_ahb_init_userpd(ab, userpd_id);
+	if (ret) {
+		mutex_unlock(&ath11k_rproc_info_lock);
+		return ret;
+	}
+
+	mutex_unlock(&ath11k_rproc_info_lock);
+
+	for (i = 0; i < ATH11K_USERPD_MAX_IRQ; i++) {
+		ab_ahb->userpd_irq_num[i] = platform_get_irq_byname_optional(ab->pdev,
+									     ath11k_userpd_irq[i]);
+		if (ab_ahb->userpd_irq_num[i] < 0)
+			return ab_ahb->userpd_irq_num[i];
+
+		upd_irq_name = devm_kzalloc(&ab->pdev->dev, ATH11K_UPD_IRQ_WRD_LEN,
+					    GFP_KERNEL);
+		if (!upd_irq_name)
+			return -ENOMEM;
+
+		scnprintf(upd_irq_name, ATH11K_UPD_IRQ_WRD_LEN, "UserPD%u-%s",
+			  ab_ahb->userpd_id, ath11k_userpd_irq[i]);
+		ret = devm_request_threaded_irq(&ab->pdev->dev, ab_ahb->userpd_irq_num[i],
+						NULL, ath11k_userpd_irq_handler,
+						IRQF_TRIGGER_RISING | IRQF_ONESHOT,
+						upd_irq_name, ab);
+		if (ret)
+			return dev_err_probe(&ab->pdev->dev, ret,
+					     "Request %s irq failed: %d\n",
+					     ath11k_userpd_irq[i], ret);
+	}
+
+	init_completion(&ab_ahb->userpd_spawned);
+	init_completion(&ab_ahb->userpd_ready);
+	init_completion(&ab_ahb->userpd_stopped);
+
+	return 0;
+}
+
 static int ath11k_ahb_root_pd_state_notifier(struct notifier_block *nb,
 					     const unsigned long event, void *data)
 {
@@ -1032,7 +1168,7 @@ static int ath11k_ahb_configure_rproc(struct ath11k_base *ab)
 	if (ret < 0) {
 		ret = dev_err_probe(&ab->pdev->dev, ret,
 				    "failed to register rproc notifier\n");
-		goto err_put_rproc;
+		goto err_cleanup_userpd;
 	}
 
 	if (ab->hw_params.m3_fw_support &&
@@ -1057,13 +1193,28 @@ static int ath11k_ahb_configure_rproc(struct ath11k_base *ab)
 
 	mutex_unlock(&ath11k_rproc_info_lock);
 
+	/*
+	 * UserPD interrupts are specific to multi-PD configs/firmware only.
+	 * If interrupts aren't found, continue execution for non-MPD platforms.
+	 */
+	ret = ath11k_ahb_config_userpd_irq(ab);
+	if (ret && ret != -EINVAL && ret != -ENXIO)
+		return dev_err_probe(&ab->pdev->dev, ret,
+				     "failed to configure userpd interrupts\n");
+
 	return 0;
 
 err_unreg_notifier:
 	ath11k_ahb_unregister_rproc_notifier();
 
-err_put_rproc:
-	rproc_put(g_rproc_info->tgt_rproc);
+err_cleanup_userpd:
+	ath11k_ahb_cleanup_userpd(ab);
+	if (g_rproc_info && !g_rproc_info->num_userpd) {
+		rproc_put(g_rproc_info->tgt_rproc);
+		kfree(g_rproc_info);
+		g_rproc_info = NULL;
+	}
+
 	mutex_unlock(&ath11k_rproc_info_lock);
 	return ret;
 }
@@ -1078,15 +1229,19 @@ static void ath11k_ahb_deconfigure_rproc(struct ath11k_base *ab)
 
 	mutex_lock(&ath11k_rproc_info_lock);
 
-	ath11k_ahb_unregister_rproc_notifier();
+	ath11k_ahb_cleanup_userpd(ab);
 
-	if (g_rproc_info->root_pd_booted &&
-	    g_rproc_info->tgt_rproc->state == RPROC_RUNNING)
-		rproc_shutdown(g_rproc_info->tgt_rproc);
+	if (!g_rproc_info->num_userpd) {
+		ath11k_ahb_unregister_rproc_notifier();
 
-	rproc_put(g_rproc_info->tgt_rproc);
-	kfree(g_rproc_info);
-	g_rproc_info = NULL;
+		if (g_rproc_info->root_pd_booted &&
+		    g_rproc_info->tgt_rproc->state == RPROC_RUNNING)
+			rproc_shutdown(g_rproc_info->tgt_rproc);
+
+		rproc_put(g_rproc_info->tgt_rproc);
+		kfree(g_rproc_info);
+		g_rproc_info = NULL;
+	}
 
 	mutex_unlock(&ath11k_rproc_info_lock);
 }
@@ -1429,6 +1584,7 @@ static int ath11k_ahb_probe(struct platform_device *pdev)
 	platform_set_drvdata(pdev, ab);
 	ab_ahb = ath11k_ahb_priv(ab);
 	ab_ahb->ab = ab;
+	ab_ahb->userpd_id = 0;
 
 	ret = ath11k_pcic_register_pci_ops(ab, pci_ops);
 	if (ret) {
diff --git a/drivers/net/wireless/ath/ath11k/ahb.h b/drivers/net/wireless/ath/ath11k/ahb.h
index 033d6223494b..12e0c4d27a0c 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.h
+++ b/drivers/net/wireless/ath/ath11k/ahb.h
@@ -19,6 +19,11 @@
 #define ATH11K_ROOTPD_READY_TIMEOUT		(5 * HZ)
 #define ATH11K_RPROC_AFTER_POWERUP		QCOM_SSR_AFTER_POWERUP
 
+enum ath11k_ahb_userpd_id {
+	ATH11K_AHB_USERPD_ID_1 = 1,
+	ATH11K_AHB_USERPD_ID_MAX,
+};
+
 enum ath11k_ahb_smp2p_msg_id {
 	ATH11K_AHB_POWER_SAVE_ENTER = 1,
 	ATH11K_AHB_POWER_SAVE_EXIT,
@@ -34,10 +39,20 @@ struct ath11k_ahb_rproc_info {
 	void *root_pd_notifier;
 	bool root_pd_booted;
 
+	u8 num_userpd;
+	struct ath11k_ahb *userpd[ATH11K_AHB_USERPD_ID_MAX];
+
 	/* Bitmap of loaded M3 firmwares indexed by hardware revision */
 	u32 m3_loaded;
 };
 
+enum ath11k_ahb_userpd_irq {
+	ATH11K_USERPD_SPAWN_IRQ,
+	ATH11K_USERPD_READY_IRQ,
+	ATH11K_USERPD_STOP_ACK_IRQ,
+	ATH11K_USERPD_MAX_IRQ,
+};
+
 struct ath11k_ahb {
 	struct ath11k_base *ab;
 	struct {
@@ -55,6 +70,16 @@ struct ath11k_ahb {
 		struct qcom_smem_state *smem_state;
 	} smp2p_info;
 	struct ath11k_ahb_rproc_info *rproc_info;
+
+	struct qcom_smem_state *spawn_state;
+	struct qcom_smem_state *stop_state;
+	struct completion userpd_spawned;
+	struct completion userpd_ready;
+	struct completion userpd_stopped;
+	u32 userpd_id;
+	u32 spawn_bit;
+	u32 stop_bit;
+	int userpd_irq_num[ATH11K_USERPD_MAX_IRQ];
 };
 
 static inline struct ath11k_ahb *ath11k_ahb_priv(struct ath11k_base *ab)

-- 
2.53.0

