From: Christopher Griffin <christophergriffin05@gmail.com>
Date: Sat, 07 Nov 2026 18:02:42 -0600
Subject: [PATCH] wifi: ath11k: serialize updates of the AHB CE interrupt
 enable registers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-ath11k-ahb-ce-ie-lock-v1-1-4bf2cc474c6e@gmail.com>
X-B4-Tracking: v=1; b=H4sIACG872oC/yXM0QqDMAyF4VeRXC/Q1KGwV5FdpF202YZK68ZAf
 PdFvfw4nH+FIlmlwK1aIctXi06jgS4VxMTjIKgPM3jnGyLXIi+J6IWcAkYbBd9TNNZ94Ma3jus
 r2HfO0uvv6Hb30+UTnhKXPQbb9gd1MqoueQAAAA==
X-Change-ID: 20261107-ath11k-ahb-ce-ie-lock-a3fba6270a34
To: Jeff Johnson <jjohnson@kernel.org>
Cc: Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 linux-wireless@vger.kernel.org, ath11k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Christopher Griffin <christophergriffin05@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794096161; l=4945;
 i=christophergriffin05@gmail.com; s=20261024; h=from:subject:message-id;
 bh=f55mKIhjRDjKmv7VLGI3KY4Ua1+TgC1Bejx8DYIGEbo=;
 b=emDSlfFZPqqTPIkbaTAcKUKXKl48pgHtm4foTh6rZx1GgJzoEmTMvbKEQrP1qjqLatIO3wxGE
 H/hiyU3Vm9EB2vD/ugAwAmataheTx1Gk3WMY+0EDTfKnPfbIBLUI6x8
X-Developer-Key: i=christophergriffin05@gmail.com; a=ed25519;
 pk=oa9tkTNpiGoFWdGvpDHXLSobApmsh9BfrJRJrRJAvWA=
X-Endpoint-Received: by B4 Relay for christophergriffin05@gmail.com/20261024 with auth_id=1309
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ath11k_ahb_ce_irq_enable() and ath11k_ahb_ce_irq_disable() set or clear
a CE's bits in the CE interrupt enable registers with a read-modify-
write. All CEs share these registers, and the updates run without a
lock from each CE's interrupt handler (disable) and tasklet (enable).

While all CE interrupts are handled on one CPU, this does no harm: a
handler that runs in the middle of a tasklet's update only clears a
bit, and the tasklet's write can at worst enable that CE again early.
Once the CE interrupts are spread over CPUs, by irqbalance or by hand,
two CPUs can update a register at the same time and one CE's enable
bit is lost. That CE never interrupts again.

On an IPQ8074 AP, moving the CE1 interrupt to another CPU under load
made WMI commands time out 14 seconds later ("failed to request fw
stats: -110"). The firmware then asserted in hif_ce.c, and after each
recovery the same happened again; the third recovery ended in a kernel
oops.

Take a spinlock around the updates.

Tested-on: IPQ8074 hw2.0 AHB WLAN.HK.2.9.0.1-02146-QCAHKSWPL_SILICONZ-1

The change, this message and the test were written with Claude, an AI
coding assistant.

Signed-off-by: Christopher Griffin <christophergriffin05@gmail.com>
---
Found on an Arista C-360 (IPQ8074) while spreading interrupts over the
CPUs for a throughput test. With the change, the same CE1 interrupt
move ran under two-radio load for several minutes (78k CE1 interrupts
on CPU3) without a WMI timeout; without it the firmware asserted within
a minute. irqbalance would hit the same race.
---
 drivers/net/wireless/ath/ath11k/ahb.c | 9 +++++++++
 drivers/net/wireless/ath/ath11k/ahb.h | 2 ++
 2 files changed, 11 insertions(+)

diff --git a/drivers/net/wireless/ath/ath11k/ahb.c b/drivers/net/wireless/ath/ath11k/ahb.c
index 27d01411b6e9c..6d600c787596a 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.c
+++ b/drivers/net/wireless/ath/ath11k/ahb.c
@@ -271,15 +271,18 @@ static void ath11k_ahb_clearbit32(struct ath11k_base *ab, u8 bit, u32 offset)
 
 static void ath11k_ahb_ce_irq_enable(struct ath11k_base *ab, u16 ce_id)
 {
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
 	const struct ce_attr *ce_attr;
 	const struct ce_ie_addr *ce_ie_addr = ab->hw_params.ce_ie_addr;
 	u32 ie1_reg_addr, ie2_reg_addr, ie3_reg_addr;
+	unsigned long flags;
 
 	ie1_reg_addr = ce_ie_addr->ie1_reg_addr + ATH11K_CE_OFFSET(ab);
 	ie2_reg_addr = ce_ie_addr->ie2_reg_addr + ATH11K_CE_OFFSET(ab);
 	ie3_reg_addr = ce_ie_addr->ie3_reg_addr + ATH11K_CE_OFFSET(ab);
 
 	ce_attr = &ab->hw_params.host_ce_config[ce_id];
+	spin_lock_irqsave(&ab_ahb->ce_ie_lock, flags);
 	if (ce_attr->src_nentries)
 		ath11k_ahb_setbit32(ab, ce_id, ie1_reg_addr);
 
@@ -288,19 +291,23 @@ static void ath11k_ahb_ce_irq_enable(struct ath11k_base *ab, u16 ce_id)
 		ath11k_ahb_setbit32(ab, ce_id + CE_HOST_IE_3_SHIFT,
 				    ie3_reg_addr);
 	}
+	spin_unlock_irqrestore(&ab_ahb->ce_ie_lock, flags);
 }
 
 static void ath11k_ahb_ce_irq_disable(struct ath11k_base *ab, u16 ce_id)
 {
+	struct ath11k_ahb *ab_ahb = ath11k_ahb_priv(ab);
 	const struct ce_attr *ce_attr;
 	const struct ce_ie_addr *ce_ie_addr = ab->hw_params.ce_ie_addr;
 	u32 ie1_reg_addr, ie2_reg_addr, ie3_reg_addr;
+	unsigned long flags;
 
 	ie1_reg_addr = ce_ie_addr->ie1_reg_addr + ATH11K_CE_OFFSET(ab);
 	ie2_reg_addr = ce_ie_addr->ie2_reg_addr + ATH11K_CE_OFFSET(ab);
 	ie3_reg_addr = ce_ie_addr->ie3_reg_addr + ATH11K_CE_OFFSET(ab);
 
 	ce_attr = &ab->hw_params.host_ce_config[ce_id];
+	spin_lock_irqsave(&ab_ahb->ce_ie_lock, flags);
 	if (ce_attr->src_nentries)
 		ath11k_ahb_clearbit32(ab, ce_id, ie1_reg_addr);
 
@@ -309,6 +316,7 @@ static void ath11k_ahb_ce_irq_disable(struct ath11k_base *ab, u16 ce_id)
 		ath11k_ahb_clearbit32(ab, ce_id + CE_HOST_IE_3_SHIFT,
 				      ie3_reg_addr);
 	}
+	spin_unlock_irqrestore(&ab_ahb->ce_ie_lock, flags);
 }
 
 static void ath11k_ahb_sync_ce_irqs(struct ath11k_base *ab)
@@ -1183,6 +1191,7 @@ static int ath11k_ahb_probe(struct platform_device *pdev)
 	}
 
 	ab->hif.ops = hif_ops;
+	spin_lock_init(&ath11k_ahb_priv(ab)->ce_ie_lock);
 	ab->pdev = pdev;
 	ab->hw_rev = hw_rev;
 	ab->fw_mode = ATH11K_FIRMWARE_MODE_NORMAL;
diff --git a/drivers/net/wireless/ath/ath11k/ahb.h b/drivers/net/wireless/ath/ath11k/ahb.h
index 8c1eb1e8e6b13..91bd097ccb900 100644
--- a/drivers/net/wireless/ath/ath11k/ahb.h
+++ b/drivers/net/wireless/ath/ath11k/ahb.h
@@ -23,6 +23,8 @@ struct ath11k_base;
 
 struct ath11k_ahb {
 	struct rproc *tgt_rproc;
+	/* protects the CE interrupt enable registers, shared by all CEs */
+	spinlock_t ce_ie_lock;
 	struct {
 		struct device *dev;
 		struct iommu_domain *iommu_domain;

---
base-commit: ad6bdd5f9030dbcf29a67f40ccdb3fa57afecff5
change-id: 20261107-ath11k-ahb-ce-ie-lock-a3fba6270a34

Best regards,
--  
Christopher Griffin <christophergriffin05@gmail.com>

