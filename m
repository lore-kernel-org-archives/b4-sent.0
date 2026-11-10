From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Tue, 10 Nov 2026 15:16:19 +0000
Subject: [PATCH v2] iommu/arm-smmu-v3: Invalidate a new level-1 stream
 table descriptor
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-smmu-l1std-cfgi-v2-1-dabcae9a593c@cs.columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNSwqDQBAFryK9Tos90QGzyj3ExTi22uAnTKski
 HfPxH2WVfDqHaAchBUeyQGBd1FZ5gjmloAf3NwzShsZTGYsUVaiTtOGI+naou96QU9l3hjnOnY
 5xNUrcCfvq1jVkQfRdQmf62Cnn/3f2gkJbcGFye7OFmSfXlO/jNvUiEu53aA+z/ML38AmzrQAA
 AA=
X-Change-ID: 20261109-smmu-l1std-cfgi-c194b2aafea4
To: Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>
Cc: Mostafa Saleh <smostafa@google.com>, 
 linux-arm-kernel@lists.infradead.org, iommu@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Jason Gunthorpe <jgg@ziepe.ca>, 
 Xuheng Li <xuheng@cs.columbia.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794323778; l=3915;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=vrw2x4/NF30qA+HPgtOkavd6zjgXcD+1Xy7g1vNZRQw=;
 b=BhRfG6l6tXiOPUeBYvIBMfVP3wkb5KWA40Amo32/l2sUqL0Q8C3urNZOfxbCrgjmXtle8/qfq
 D2GfVoSPczaCXuMaMxYnYtFLdx4zTB4ldgFN1G7rgpAiCiuipLJoghk
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

arm_smmu_init_l2_strtab() allocates a level-2 stream table when the first
master in its range is added, and makes the level-1 descriptor valid. It
issues no invalidation, and the attach that follows sends only the leaf
form of CMD_CFGI_STE.

IHI 0070 5.1.1 requires the non-leaf form of CMD_CFGI_STE when an L1STD
changes, including when an inactive descriptor with Span == 0 becomes
active. An SMMU that cached the inactive descriptor can keep terminating
the master's transactions as if its StreamID were invalid.

Issue a non-leaf CMD_CFGI_STE after writing the descriptor. The RMR path
runs before the stream table is programmed into the SMMU, and
arm_smmu_device_reset() then issues CMD_CFGI_ALL, so it needs none.

Fixes: 48ec83bcbcf5 ("iommu/arm-smmu: Add initial driver support for ARM SMMUv3 devices")
Reviewed-by: Mostafa Saleh <smostafa@google.com>
Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
Changes in v2:
- Shorten the new comment and drop the one at the RMR call site (Mostafa)
- Add Mostafa's Reviewed-by
- Link to v1: https://lore.kernel.org/r/20261109-smmu-l1std-cfgi-v1-1-65e5203a6516@cs.columbia.edu
---
 drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c | 17 ++++++++++++-----
 1 file changed, 12 insertions(+), 5 deletions(-)

diff --git a/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c b/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
index 6d4520c47..e5c09aaff 100644
--- a/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
+++ b/drivers/iommu/arm/arm-smmu-v3/arm-smmu-v3.c
@@ -2030,7 +2030,8 @@ static void arm_smmu_init_initial_stes(struct arm_smmu_ste *strtab,
 	}
 }
 
-static int arm_smmu_init_l2_strtab(struct arm_smmu_device *smmu, u32 sid)
+static int arm_smmu_init_l2_strtab(struct arm_smmu_device *smmu, u32 sid,
+				   bool live)
 {
 	dma_addr_t l2ptr_dma;
 	struct arm_smmu_strtab_cfg *cfg = &smmu->strtab_cfg;
@@ -2053,6 +2054,11 @@ static int arm_smmu_init_l2_strtab(struct arm_smmu_device *smmu, u32 sid)
 				   ARRAY_SIZE((*l2table)->stes));
 	arm_smmu_write_strtab_l1_desc(&cfg->l2.l1tab[arm_smmu_strtab_l1_idx(sid)],
 				      l2ptr_dma);
+
+	/* An invalid L1STD can be cached */
+	if (live)
+		arm_smmu_cmdq_issue_cmd_with_sync(smmu,
+						  arm_smmu_make_cmd_cfgi_ste(sid, false));
 	return 0;
 }
 
@@ -4261,7 +4267,8 @@ static bool arm_smmu_sid_in_range(struct arm_smmu_device *smmu, u32 sid)
 	return sid < smmu->strtab_cfg.linear.num_ents;
 }
 
-static int arm_smmu_init_sid_strtab(struct arm_smmu_device *smmu, u32 sid)
+static int arm_smmu_init_sid_strtab(struct arm_smmu_device *smmu, u32 sid,
+				    bool live)
 {
 	/* Check the SIDs are in range of the SMMU and our stream table */
 	if (!arm_smmu_sid_in_range(smmu, sid))
@@ -4269,7 +4276,7 @@ static int arm_smmu_init_sid_strtab(struct arm_smmu_device *smmu, u32 sid)
 
 	/* Ensure l2 strtab is initialised */
 	if (smmu->features & ARM_SMMU_FEAT_2_LVL_STRTAB)
-		return arm_smmu_init_l2_strtab(smmu, sid);
+		return arm_smmu_init_l2_strtab(smmu, sid, live);
 
 	return 0;
 }
@@ -4333,7 +4340,7 @@ static int arm_smmu_insert_master(struct arm_smmu_device *smmu,
 		struct rb_node *existing;
 		u32 sid = new_stream->id;
 
-		ret = arm_smmu_init_sid_strtab(smmu, sid);
+		ret = arm_smmu_init_sid_strtab(smmu, sid, true);
 		if (ret)
 			break;
 
@@ -5713,7 +5720,7 @@ static void arm_smmu_rmr_install_bypass_ste(struct arm_smmu_device *smmu)
 
 		rmr = container_of(e, struct iommu_iort_rmr_data, rr);
 		for (i = 0; i < rmr->num_sids; i++) {
-			ret = arm_smmu_init_sid_strtab(smmu, rmr->sids[i]);
+			ret = arm_smmu_init_sid_strtab(smmu, rmr->sids[i], false);
 			if (ret) {
 				dev_err(smmu->dev, "RMR SID(0x%x) bypass failed\n",
 					rmr->sids[i]);

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261109-smmu-l1std-cfgi-c194b2aafea4

Best regards,
-- 
Xuheng Li <xuheng@cs.columbia.edu>

