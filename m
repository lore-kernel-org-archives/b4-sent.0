From: Per Larsen <perlarsen@google.com>
Date: Tue, 13 May 2025 06:28:31 +0000
Subject: [PATCH v3 2/3] KVM: arm64: Bump the supported version of FF-A to
 1.2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250513-virtio-msg-ffa-v3-2-d66c76ff1b2c@google.com>
References: <20250513-virtio-msg-ffa-v3-0-d66c76ff1b2c@google.com>
In-Reply-To: <20250513-virtio-msg-ffa-v3-0-d66c76ff1b2c@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, sebastianene@google.com, 
 lpieralisi@kernel.org, arve@android.com, qwandor@google.com, 
 kernel-team@android.com, armellel@google.com, perl@immunant.com, 
 jean-philippe@linaro.org, ahomescu@google.com, tabba@google.com, 
 qperret@google.com, james.morse@arm.com, Ayrton Munoz <ayrton@google.com>, 
 Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1747117739; l=7509;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=g+IX2CMQ1LETs57Pbs9qsYHceDkL3ouPwJ+4oHoRF5o=;
 b=dFfedZgYGlDwEbaPfeCO049PEXIVPIqOge8qgNLmQmzsVATQKLUYyipR2AL0kYjkp4adVphNa
 QFQCGa3m5W4BNqOhx6eT/5TbEBeNpLjeVgvZMCH25Yvfgn1v9J8n3B6
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FF-A version 1.2 introduces the DIRECT_REQ2 ABI. Bump the FF-A version
preferred by the hypervisor as a precursor to implementing the 1.2-only
FFA_MSG_SEND_DIRECT_REQ2 and FFA_MSG_SEND_RESP2 messaging interfaces.

We must also use SMCCC 1.2 for 64-bit SMCs if hypervisor negotiated FF-A
1.2, so ffa_set_retval is updated and a new function to call 64-bit smcs
using SMCCC 1.2 with fallback to SMCCC 1.1 is introduced.

Update deny-list in ffa_call_supported to mark FFA_NOTIFICATION_* and
interfaces added in FF-A 1.2 as unsupported lest they get forwarded.

Co-developed-by: Ayrton Munoz <ayrton@google.com>
Signed-off-by: Ayrton Munoz <ayrton@google.com>
Signed-off-by: Per Larsen <perlarsen@google.com>
Signed-off-by: Per Larsen <perl@immunant.com>
---
 arch/arm64/kvm/hyp/include/nvhe/ffa.h |  1 +
 arch/arm64/kvm/hyp/nvhe/Makefile      |  1 +
 arch/arm64/kvm/hyp/nvhe/ffa.c         | 88 ++++++++++++++++++++++++++++++++---
 include/linux/arm_ffa.h               |  1 +
 4 files changed, 85 insertions(+), 6 deletions(-)

diff --git a/arch/arm64/kvm/hyp/include/nvhe/ffa.h b/arch/arm64/kvm/hyp/include/nvhe/ffa.h
index 146e0aebfa1c7c9834c75a9a29bf87eb6f94f436..02def6fe51f5079b12c168585e12f862211c4c91 100644
--- a/arch/arm64/kvm/hyp/include/nvhe/ffa.h
+++ b/arch/arm64/kvm/hyp/include/nvhe/ffa.h
@@ -13,5 +13,6 @@
 
 int hyp_ffa_init(void *pages);
 bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id);
+u32 ffa_get_hypervisor_version(void);
 
 #endif /* __KVM_HYP_FFA_H */
diff --git a/arch/arm64/kvm/hyp/nvhe/Makefile b/arch/arm64/kvm/hyp/nvhe/Makefile
index b43426a493df5a388caa920e259cc8c54d118a1b..95404ff16dac0389f45a3ee2c13a93b3ebebaf6d 100644
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
index 2c199d40811efb5bfae199c4a67d8ae3d9307357..403fde6ca4d6ec49566ef60709cedbaef9f04592 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -101,6 +101,55 @@ static void ffa_set_retval(struct kvm_cpu_context *ctxt,
 	cpu_reg(ctxt, 1) = res->a1;
 	cpu_reg(ctxt, 2) = res->a2;
 	cpu_reg(ctxt, 3) = res->a3;
+
+	/*
+	 * Other result registers must be zero per DEN0077A but SMC32/HVC32 must
+	 * preserve x8-x30 per DEN0028.
+	 */
+	cpu_reg(ctxt, 4) = 0;
+	cpu_reg(ctxt, 5) = 0;
+	cpu_reg(ctxt, 6) = 0;
+	cpu_reg(ctxt, 7) = 0;
+
+	/*
+	 * Per DEN0077A v1.2 11.2, the caller is expected to write zeroes to
+	 * unused parameter registers.
+	 */
+	if (ARM_SMCCC_IS_64(res->a0)) {
+		if (ffa_get_hypervisor_version() >= FFA_VERSION_1_2) {
+			cpu_reg(ctxt, 8) = 0;
+			cpu_reg(ctxt, 9) = 0;
+			cpu_reg(ctxt, 10) = 0;
+			cpu_reg(ctxt, 11) = 0;
+			cpu_reg(ctxt, 12) = 0;
+			cpu_reg(ctxt, 13) = 0;
+			cpu_reg(ctxt, 14) = 0;
+			cpu_reg(ctxt, 15) = 0;
+			cpu_reg(ctxt, 16) = 0;
+			cpu_reg(ctxt, 17) = 0;
+		}
+	}
+}
+
+/* Call SMC64 using SMCCC 1.2 if hyp negotiated FF-A 1.2 falling back to 1.1 */
+static void arm_smccc_1_x_smc(u64 func_id, u64 a1, u64 a2, u64 a3,
+			      u64 a4, u64 a5, u64 a6, u64 a7,
+			      struct arm_smccc_res *res)
+{
+	struct arm_smccc_1_2_regs args, regs = {0};
+
+	/* SMC64 only as SMC32 must preserve x8-x30 per DEN0028 1.6G Sec 2.6 */
+	if (ARM_SMCCC_IS_64(func_id) &&
+		ffa_get_hypervisor_version() >= FFA_VERSION_1_2) {
+		args = (struct arm_smccc_1_2_regs) { func_id, a1, a2, a3, a4,
+						     a5, a6, a7 };
+		arm_smccc_1_2_smc(&args, &regs);
+		*res = (struct arm_smccc_res) { .a0 = regs.a0, .a1 = regs.a1,
+						.a2 = regs.a2, .a3 = regs.a3 };
+		return;
+	}
+
+	arm_smccc_1_1_smc(func_id, a1, a2, a3, a4, a5, a6, a7, res);
 }
 
 static bool is_ffa_call(u64 func_id)
@@ -115,7 +164,7 @@ static int ffa_map_hyp_buffers(u64 ffa_page_count)
 {
 	struct arm_smccc_res res;
 
-	arm_smccc_1_1_smc(FFA_FN64_RXTX_MAP,
+	arm_smccc_1_x_smc(FFA_FN64_RXTX_MAP,
 			  hyp_virt_to_phys(hyp_buffers.tx),
 			  hyp_virt_to_phys(hyp_buffers.rx),
 			  ffa_page_count,
@@ -174,7 +223,7 @@ static void ffa_mem_reclaim(struct arm_smccc_res *res, u32 handle_lo,
 
 static void ffa_retrieve_req(struct arm_smccc_res *res, u32 len)
 {
-	arm_smccc_1_1_smc(FFA_FN64_MEM_RETRIEVE_REQ,
+	arm_smccc_1_x_smc(FFA_FN64_MEM_RETRIEVE_REQ,
 			  len, len,
 			  0, 0, 0, 0, 0,
 			  res);
@@ -628,6 +677,20 @@ static bool ffa_call_supported(u64 func_id)
 	case FFA_RXTX_MAP:
 	case FFA_MEM_DONATE:
 	case FFA_MEM_RETRIEVE_REQ:
+	/* Optional notification interfaces added in FF-A 1.1 */
+	case FFA_NOTIFICATION_BITMAP_CREATE:
+	case FFA_NOTIFICATION_BITMAP_DESTROY:
+	case FFA_NOTIFICATION_BIND:
+	case FFA_NOTIFICATION_UNBIND:
+	case FFA_NOTIFICATION_SET:
+	case FFA_NOTIFICATION_GET:
+	case FFA_NOTIFICATION_INFO_GET:
+	/* Unimplemented interfaces added in FF-A 1.2 */
+	case FFA_MSG_SEND_DIRECT_REQ2:
+	case FFA_MSG_SEND_DIRECT_RESP2:
+	case FFA_CONSOLE_LOG:
+	case FFA_PARTITION_INFO_GET_REGS:
+	case FFA_EL3_INTR_HANDLE:
 		return false;
 	}
 
@@ -680,7 +743,7 @@ static int hyp_ffa_post_init(void)
 	if (res.a0 != FFA_SUCCESS)
 		return -EOPNOTSUPP;
 
-	switch (res.a2) {
+	switch (res.a2 & FFA_FEAT_RXTX_MIN_SZ_MASK) {
 	case FFA_FEAT_RXTX_MIN_SZ_4K:
 		min_rxtx_sz = SZ_4K;
 		break;
@@ -861,6 +924,18 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 	return true;
 }
 
+u32 ffa_get_hypervisor_version(void)
+{
+	u32 version = 0;
+
+	hyp_spin_lock(&version_lock);
+	if (has_version_negotiated)
+		version = hyp_ffa_version;
+	hyp_spin_unlock(&version_lock);
+
+	return version;
+}
+
 int hyp_ffa_init(void *pages)
 {
 	struct arm_smccc_res res;
@@ -869,7 +944,7 @@ int hyp_ffa_init(void *pages)
 	if (kvm_host_psci_config.smccc_version < ARM_SMCCC_VERSION_1_2)
 		return 0;
 
-	arm_smccc_1_1_smc(FFA_VERSION, FFA_VERSION_1_1, 0, 0, 0, 0, 0, 0, &res);
+	arm_smccc_1_1_smc(FFA_VERSION, FFA_VERSION_1_2, 0, 0, 0, 0, 0, 0, &res);
 	if (res.a0 == FFA_RET_NOT_SUPPORTED)
 		return 0;
 
@@ -889,10 +964,11 @@ int hyp_ffa_init(void *pages)
 	if (FFA_MAJOR_VERSION(res.a0) != 1)
 		return -EOPNOTSUPP;
 
-	if (FFA_MINOR_VERSION(res.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_1))
+	/* See do_ffa_guest_version before bumping maximum supported version. */
+	if (FFA_MINOR_VERSION(res.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_2))
 		hyp_ffa_version = res.a0;
 	else
-		hyp_ffa_version = FFA_VERSION_1_1;
+		hyp_ffa_version = FFA_VERSION_1_2;
 
 	tx = pages;
 	pages += KVM_FFA_MBOX_NR_PAGES * PAGE_SIZE;
diff --git a/include/linux/arm_ffa.h b/include/linux/arm_ffa.h
index 5bded24dc24fea8cdcbe42bf79c7c025c3fa5f4b..c0dd6183d956043192114a522b7eef465e7078ac 100644
--- a/include/linux/arm_ffa.h
+++ b/include/linux/arm_ffa.h
@@ -128,6 +128,7 @@
 #define FFA_FEAT_RXTX_MIN_SZ_4K		0
 #define FFA_FEAT_RXTX_MIN_SZ_64K	1
 #define FFA_FEAT_RXTX_MIN_SZ_16K	2
+#define FFA_FEAT_RXTX_MIN_SZ_MASK	3
 
 /* FFA Bus/Device/Driver related */
 struct ffa_device {

-- 
2.49.0.1045.g170613ef41-goog

