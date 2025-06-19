From: Per Larsen <perlarsen@google.com>
Date: Thu, 19 Jun 2025 09:02:55 +0000
Subject: [PATCH v5 2/6] KVM: arm64: Use SMCCC 1.2 in
 hyp_ffa_{init,post_init}
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250619-virtio-msg-ffa-v5-2-412c98558807@google.com>
References: <20250619-virtio-msg-ffa-v5-0-412c98558807@google.com>
In-Reply-To: <20250619-virtio-msg-ffa-v5-0-412c98558807@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750323807; l=3417;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=ITbJy+U88TKFuEMoRcW/LDBaFV7Te3dLSP/C39fWi6U=;
 b=a8Q66bWbjAHiQ8So3UnvJcSeMp19/fIenT+YRS/1O5zV5OnYaPiSu2af0Z4rlfF2M6oWkHJWh
 vTfvBA8/qEqDtKNd7cF0z5mfSYGrlPmEZDS9nSQBUlMO+JpUrfd9bew
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FF-A is based on SMCCC 1.2. Move the FF-A initialization code to SMCCC
1.2 as it simplifies later changes in this patchset.

Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/Makefile |  1 +
 arch/arm64/kvm/hyp/nvhe/ffa.c    | 37 +++++++++++++++++++++++--------------
 2 files changed, 24 insertions(+), 14 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/Makefile b/arch/arm64/kvm/hyp/nvhe/Makefile
index a76522d63c3e630795db5972a99abc3d24bc5e26..f859a8fb41a25effea1edd977bef889423153399 100644
--- a/arch/arm64/kvm/hyp/nvhe/Makefile
+++ b/arch/arm64/kvm/hyp/nvhe/Makefile
@@ -27,6 +27,7 @@ hyp-obj-y := timer-sr.o sysreg-sr.o debug-sr.o switch.o tlb.o hyp-init.o host.o
 	 cache.o setup.o mm.o mem_protect.o sys_regs.o pkvm.o stacktrace.o ffa.o
 hyp-obj-y += ../vgic-v3-sr.o ../aarch32.o ../vgic-v2-cpuif-proxy.o ../entry.o \
 	 ../fpsimd.o ../hyp-entry.o ../exception.o ../pgtable.o
+hyp-obj-y += ../../../kernel/smccc-call.o
 hyp-obj-$(CONFIG_LIST_HARDENED) += list_debug.o
 hyp-obj-y += $(lib-objs)
 
diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 2c199d40811efb5bfae199c4a67d8ae3d9307357..51bbe8f9c94584e9001ee769cbfd608d930ff723 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -666,21 +666,26 @@ static bool do_ffa_features(struct arm_smccc_res *res,
 static int hyp_ffa_post_init(void)
 {
 	size_t min_rxtx_sz;
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs regs = {
+		.a0 = FFA_ID_GET,
+	};
 
-	arm_smccc_1_1_smc(FFA_ID_GET, 0, 0, 0, 0, 0, 0, 0, &res);
-	if (res.a0 != FFA_SUCCESS)
+	arm_smccc_1_2_smc(&regs, &regs);
+	if (regs.a0 != FFA_SUCCESS)
 		return -EOPNOTSUPP;
 
-	if (res.a2 != HOST_FFA_ID)
+	if (regs.a2 != HOST_FFA_ID)
 		return -EINVAL;
 
-	arm_smccc_1_1_smc(FFA_FEATURES, FFA_FN64_RXTX_MAP,
-			  0, 0, 0, 0, 0, 0, &res);
-	if (res.a0 != FFA_SUCCESS)
+	regs = (struct arm_smccc_1_2_regs){
+		.a0 = FFA_FEATURES,
+		.a1 = FFA_FN64_RXTX_MAP,
+	};
+	arm_smccc_1_2_smc(&regs, &regs);
+	if (regs.a0 != FFA_SUCCESS)
 		return -EOPNOTSUPP;
 
-	switch (res.a2) {
+	switch (regs.a2) {
 	case FFA_FEAT_RXTX_MIN_SZ_4K:
 		min_rxtx_sz = SZ_4K;
 		break;
@@ -863,14 +868,18 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 
 int hyp_ffa_init(void *pages)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs regs;
 	void *tx, *rx;
 
 	if (kvm_host_psci_config.smccc_version < ARM_SMCCC_VERSION_1_2)
 		return 0;
 
-	arm_smccc_1_1_smc(FFA_VERSION, FFA_VERSION_1_1, 0, 0, 0, 0, 0, 0, &res);
-	if (res.a0 == FFA_RET_NOT_SUPPORTED)
+	regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_VERSION,
+		.a1 = FFA_VERSION_1_1,
+	};
+	arm_smccc_1_2_smc(&regs, &regs);
+	if (regs.a0 == FFA_RET_NOT_SUPPORTED)
 		return 0;
 
 	/*
@@ -886,11 +895,11 @@ int hyp_ffa_init(void *pages)
 	 * ABI return NOT_SUPPORTED rather than a version number, according to
 	 * DEN0077A v1.1 REL0 18.6.4.
 	 */
-	if (FFA_MAJOR_VERSION(res.a0) != 1)
+	if (FFA_MAJOR_VERSION(regs.a0) != 1)
 		return -EOPNOTSUPP;
 
-	if (FFA_MINOR_VERSION(res.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_1))
-		hyp_ffa_version = res.a0;
+	if (FFA_MINOR_VERSION(regs.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_1))
+		hyp_ffa_version = regs.a0;
 	else
 		hyp_ffa_version = FFA_VERSION_1_1;
 

-- 
2.50.0.rc2.701.gf1e915cc24-goog

