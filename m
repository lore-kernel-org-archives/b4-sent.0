From: Per Larsen <perlarsen@google.com>
Date: Tue, 01 Jul 2025 22:06:35 +0000
Subject: [PATCH v7 2/5] KVM: arm64: Use SMCCC 1.2 for FF-A initialization
 and in host handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-virtio-msg-ffa-v7-2-995afc3d385e@google.com>
References: <20250701-virtio-msg-ffa-v7-0-995afc3d385e@google.com>
In-Reply-To: <20250701-virtio-msg-ffa-v7-0-995afc3d385e@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, ahomescu@google.com, armellel@google.com, 
 arve@android.com, ayrton@google.com, qperret@google.com, 
 sebastianene@google.com, qwandor@google.com, 
 Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751407606; l=12757;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=o6mY15uz5FBX5hG5cYhKQuI0kzM+cB2A7BI4Z1uCA8A=;
 b=mcGPSy0qTQGnn9qLdg6UFOCsre/3QuIflJb7RmvLMjbZXUnEbVbh4PNYS/NcUGeY1cVhf+9Ao
 dIwcBV5i547CMYIFH9jcpBc/sAaaKJHC8zznQMhAjW78wXOjGss1+JS
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SMCCC 1.1 and prior allows four registers to be sent back as a result
of an FF-A interface. SMCCC 1.2 increases the number of results that can
be sent back to 8 and 16 for 32-bit and 64-bit SMC/HVCs respectively.

FF-A 1.0 references SMCCC 1.2 (reference [4] on page xi) and FF-A 1.2
explicitly requires SMCCC 1.2 so it should be safe to use this version
unconditionally. Moreover, it is simpler to implement FF-A features
without having to worry about compatibility with SMCCC 1.1 and older.

Update the FF-A initialization and host handler code to use SMCCC 1.2.

Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/Makefile |   1 +
 arch/arm64/kvm/hyp/nvhe/ffa.c    | 193 +++++++++++++++++++++++++--------------
 2 files changed, 125 insertions(+), 69 deletions(-)

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
index 2c199d40811efb5bfae199c4a67d8ae3d9307357..65d241ba32403d014b43cc4ef4d5bf9693813809 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -71,36 +71,68 @@ static u32 hyp_ffa_version;
 static bool has_version_negotiated;
 static hyp_spinlock_t version_lock;
 
-static void ffa_to_smccc_error(struct arm_smccc_res *res, u64 ffa_errno)
+static void ffa_to_smccc_error(struct arm_smccc_1_2_regs *res, u64 ffa_errno)
 {
-	*res = (struct arm_smccc_res) {
+	*res = (struct arm_smccc_1_2_regs) {
 		.a0	= FFA_ERROR,
 		.a2	= ffa_errno,
 	};
 }
 
-static void ffa_to_smccc_res_prop(struct arm_smccc_res *res, int ret, u64 prop)
+static void ffa_to_smccc_res_prop(struct arm_smccc_1_2_regs *res, int ret, u64 prop)
 {
 	if (ret == FFA_RET_SUCCESS) {
-		*res = (struct arm_smccc_res) { .a0 = FFA_SUCCESS,
-						.a2 = prop };
+		*res = (struct arm_smccc_1_2_regs) { .a0 = FFA_SUCCESS,
+						      .a2 = prop };
 	} else {
 		ffa_to_smccc_error(res, ret);
 	}
 }
 
-static void ffa_to_smccc_res(struct arm_smccc_res *res, int ret)
+static void ffa_to_smccc_res(struct arm_smccc_1_2_regs *res, int ret)
 {
 	ffa_to_smccc_res_prop(res, ret, 0);
 }
 
 static void ffa_set_retval(struct kvm_cpu_context *ctxt,
-			   struct arm_smccc_res *res)
+			   struct arm_smccc_1_2_regs *res)
 {
+	DECLARE_REG(u64, func_id, ctxt, 0);
 	cpu_reg(ctxt, 0) = res->a0;
 	cpu_reg(ctxt, 1) = res->a1;
 	cpu_reg(ctxt, 2) = res->a2;
 	cpu_reg(ctxt, 3) = res->a3;
+	cpu_reg(ctxt, 4) = res->a4;
+	cpu_reg(ctxt, 5) = res->a5;
+	cpu_reg(ctxt, 6) = res->a6;
+	cpu_reg(ctxt, 7) = res->a7;
+
+	/*
+	 * DEN0028C 2.6: SMC32/HVC32 call from aarch64 must preserve x8-x30.
+	 *
+	 * The most straightforward approach is to look at the function ID
+	 * sent by the caller. However, the caller could send FFA_MSG_WAIT
+	 * which is a 32-bit interface but the reply could very well be 64-bit
+	 * such as FFA_FN64_MSG_SEND_DIRECT_REQ or FFA_MSG_SEND_DIRECT_REQ2.
+	 *
+	 * Instead, we could look at the function ID in the response (a0) but
+	 * that doesn't work either as FFA_VERSION responses put the version
+	 * number (or error code) in w0.
+	 *
+	 * Set x8-x17 iff response contains 64-bit function ID in a0.
+	 */
+	if (func_id != FFA_VERSION && ARM_SMCCC_IS_64(res->a0)) {
+		cpu_reg(ctxt, 8) = res->a8;
+		cpu_reg(ctxt, 9) = res->a9;
+		cpu_reg(ctxt, 10) = res->a10;
+		cpu_reg(ctxt, 11) = res->a11;
+		cpu_reg(ctxt, 12) = res->a12;
+		cpu_reg(ctxt, 13) = res->a13;
+		cpu_reg(ctxt, 14) = res->a14;
+		cpu_reg(ctxt, 15) = res->a15;
+		cpu_reg(ctxt, 16) = res->a16;
+		cpu_reg(ctxt, 17) = res->a17;
+	}
 }
 
 static bool is_ffa_call(u64 func_id)
@@ -113,82 +145,92 @@ static bool is_ffa_call(u64 func_id)
 
 static int ffa_map_hyp_buffers(u64 ffa_page_count)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs res;
 
-	arm_smccc_1_1_smc(FFA_FN64_RXTX_MAP,
-			  hyp_virt_to_phys(hyp_buffers.tx),
-			  hyp_virt_to_phys(hyp_buffers.rx),
-			  ffa_page_count,
-			  0, 0, 0, 0,
-			  &res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_FN64_RXTX_MAP,
+		.a1 = hyp_virt_to_phys(hyp_buffers.tx),
+		.a2 = hyp_virt_to_phys(hyp_buffers.rx),
+		.a3 = ffa_page_count,
+	}, &res);
 
 	return res.a0 == FFA_SUCCESS ? FFA_RET_SUCCESS : res.a2;
 }
 
 static int ffa_unmap_hyp_buffers(void)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs res;
 
-	arm_smccc_1_1_smc(FFA_RXTX_UNMAP,
-			  HOST_FFA_ID,
-			  0, 0, 0, 0, 0, 0,
-			  &res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_RXTX_UNMAP,
+		.a1 = HOST_FFA_ID,
+	}, &res);
 
 	return res.a0 == FFA_SUCCESS ? FFA_RET_SUCCESS : res.a2;
 }
 
-static void ffa_mem_frag_tx(struct arm_smccc_res *res, u32 handle_lo,
+static void ffa_mem_frag_tx(struct arm_smccc_1_2_regs *res, u32 handle_lo,
 			     u32 handle_hi, u32 fraglen, u32 endpoint_id)
 {
-	arm_smccc_1_1_smc(FFA_MEM_FRAG_TX,
-			  handle_lo, handle_hi, fraglen, endpoint_id,
-			  0, 0, 0,
-			  res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_MEM_FRAG_TX,
+		.a1 = handle_lo,
+		.a2 = handle_hi,
+		.a3 = fraglen,
+		.a4 = endpoint_id,
+	}, res);
 }
 
-static void ffa_mem_frag_rx(struct arm_smccc_res *res, u32 handle_lo,
+static void ffa_mem_frag_rx(struct arm_smccc_1_2_regs *res, u32 handle_lo,
 			     u32 handle_hi, u32 fragoff)
 {
-	arm_smccc_1_1_smc(FFA_MEM_FRAG_RX,
-			  handle_lo, handle_hi, fragoff, HOST_FFA_ID,
-			  0, 0, 0,
-			  res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_MEM_FRAG_RX,
+		.a1 = handle_lo,
+		.a2 = handle_hi,
+		.a3 = fragoff,
+		.a4 = HOST_FFA_ID,
+	}, res);
 }
 
-static void ffa_mem_xfer(struct arm_smccc_res *res, u64 func_id, u32 len,
+static void ffa_mem_xfer(struct arm_smccc_1_2_regs *res, u64 func_id, u32 len,
 			  u32 fraglen)
 {
-	arm_smccc_1_1_smc(func_id, len, fraglen,
-			  0, 0, 0, 0, 0,
-			  res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = func_id,
+		.a1 = len,
+		.a2 = fraglen,
+	}, res);
 }
 
-static void ffa_mem_reclaim(struct arm_smccc_res *res, u32 handle_lo,
+static void ffa_mem_reclaim(struct arm_smccc_1_2_regs *res, u32 handle_lo,
 			     u32 handle_hi, u32 flags)
 {
-	arm_smccc_1_1_smc(FFA_MEM_RECLAIM,
-			  handle_lo, handle_hi, flags,
-			  0, 0, 0, 0,
-			  res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_MEM_RECLAIM,
+		.a1 = handle_lo,
+		.a2 = handle_hi,
+		.a3 = flags,
+	}, res);
 }
 
-static void ffa_retrieve_req(struct arm_smccc_res *res, u32 len)
+static void ffa_retrieve_req(struct arm_smccc_1_2_regs *res, u32 len)
 {
-	arm_smccc_1_1_smc(FFA_FN64_MEM_RETRIEVE_REQ,
-			  len, len,
-			  0, 0, 0, 0, 0,
-			  res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_FN64_MEM_RETRIEVE_REQ,
+		.a1 = len,
+		.a2 = len,
+	}, res);
 }
 
-static void ffa_rx_release(struct arm_smccc_res *res)
+static void ffa_rx_release(struct arm_smccc_1_2_regs *res)
 {
-	arm_smccc_1_1_smc(FFA_RX_RELEASE,
-			  0, 0,
-			  0, 0, 0, 0, 0,
-			  res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_RX_RELEASE,
+	}, res);
 }
 
-static void do_ffa_rxtx_map(struct arm_smccc_res *res,
+static void do_ffa_rxtx_map(struct arm_smccc_1_2_regs *res,
 			    struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(phys_addr_t, tx, ctxt, 1);
@@ -267,7 +309,7 @@ static void do_ffa_rxtx_map(struct arm_smccc_res *res,
 	goto out_unlock;
 }
 
-static void do_ffa_rxtx_unmap(struct arm_smccc_res *res,
+static void do_ffa_rxtx_unmap(struct arm_smccc_1_2_regs *res,
 			      struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, id, ctxt, 1);
@@ -368,7 +410,7 @@ static int ffa_host_unshare_ranges(struct ffa_mem_region_addr_range *ranges,
 	return ret;
 }
 
-static void do_ffa_mem_frag_tx(struct arm_smccc_res *res,
+static void do_ffa_mem_frag_tx(struct arm_smccc_1_2_regs *res,
 			       struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, handle_lo, ctxt, 1);
@@ -427,7 +469,7 @@ static void do_ffa_mem_frag_tx(struct arm_smccc_res *res,
 }
 
 static void __do_ffa_mem_xfer(const u64 func_id,
-			      struct arm_smccc_res *res,
+			      struct arm_smccc_1_2_regs *res,
 			      struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, len, ctxt, 1);
@@ -521,7 +563,7 @@ static void __do_ffa_mem_xfer(const u64 func_id,
 		__do_ffa_mem_xfer((fid), (res), (ctxt));	\
 	} while (0);
 
-static void do_ffa_mem_reclaim(struct arm_smccc_res *res,
+static void do_ffa_mem_reclaim(struct arm_smccc_1_2_regs *res,
 			       struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, handle_lo, ctxt, 1);
@@ -634,7 +676,7 @@ static bool ffa_call_supported(u64 func_id)
 	return true;
 }
 
-static bool do_ffa_features(struct arm_smccc_res *res,
+static bool do_ffa_features(struct arm_smccc_1_2_regs *res,
 			    struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, id, ctxt, 1);
@@ -666,17 +708,21 @@ static bool do_ffa_features(struct arm_smccc_res *res,
 static int hyp_ffa_post_init(void)
 {
 	size_t min_rxtx_sz;
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs res;
 
-	arm_smccc_1_1_smc(FFA_ID_GET, 0, 0, 0, 0, 0, 0, 0, &res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs){
+		.a0 = FFA_ID_GET,
+	}, &res);
 	if (res.a0 != FFA_SUCCESS)
 		return -EOPNOTSUPP;
 
 	if (res.a2 != HOST_FFA_ID)
 		return -EINVAL;
 
-	arm_smccc_1_1_smc(FFA_FEATURES, FFA_FN64_RXTX_MAP,
-			  0, 0, 0, 0, 0, 0, &res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs){
+		.a0 = FFA_FEATURES,
+		.a1 = FFA_FN64_RXTX_MAP,
+	}, &res);
 	if (res.a0 != FFA_SUCCESS)
 		return -EOPNOTSUPP;
 
@@ -700,7 +746,7 @@ static int hyp_ffa_post_init(void)
 	return 0;
 }
 
-static void do_ffa_version(struct arm_smccc_res *res,
+static void do_ffa_version(struct arm_smccc_1_2_regs *res,
 			   struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, ffa_req_version, ctxt, 1);
@@ -724,9 +770,10 @@ static void do_ffa_version(struct arm_smccc_res *res,
 	 * first if TEE supports it.
 	 */
 	if (FFA_MINOR_VERSION(ffa_req_version) < FFA_MINOR_VERSION(hyp_ffa_version)) {
-		arm_smccc_1_1_smc(FFA_VERSION, ffa_req_version, 0,
-				  0, 0, 0, 0, 0,
-				  res);
+		arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+			.a0 = FFA_VERSION,
+			.a1 = ffa_req_version,
+		}, res);
 		if (res->a0 == FFA_RET_NOT_SUPPORTED)
 			goto unlock;
 
@@ -743,7 +790,7 @@ static void do_ffa_version(struct arm_smccc_res *res,
 	hyp_spin_unlock(&version_lock);
 }
 
-static void do_ffa_part_get(struct arm_smccc_res *res,
+static void do_ffa_part_get(struct arm_smccc_1_2_regs *res,
 			    struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, uuid0, ctxt, 1);
@@ -759,9 +806,14 @@ static void do_ffa_part_get(struct arm_smccc_res *res,
 		goto out_unlock;
 	}
 
-	arm_smccc_1_1_smc(FFA_PARTITION_INFO_GET, uuid0, uuid1,
-			  uuid2, uuid3, flags, 0, 0,
-			  res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_PARTITION_INFO_GET,
+		.a1 = uuid0,
+		.a2 = uuid1,
+		.a3 = uuid2,
+		.a4 = uuid3,
+		.a5 = flags,
+	}, res);
 
 	if (res->a0 != FFA_SUCCESS)
 		goto out_unlock;
@@ -794,7 +846,7 @@ static void do_ffa_part_get(struct arm_smccc_res *res,
 
 bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs res;
 
 	/*
 	 * There's no way we can tell what a non-standard SMC call might
@@ -863,13 +915,16 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 
 int hyp_ffa_init(void *pages)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs res;
 	void *tx, *rx;
 
 	if (kvm_host_psci_config.smccc_version < ARM_SMCCC_VERSION_1_2)
 		return 0;
 
-	arm_smccc_1_1_smc(FFA_VERSION, FFA_VERSION_1_1, 0, 0, 0, 0, 0, 0, &res);
+	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
+		.a0 = FFA_VERSION,
+		.a1 = FFA_VERSION_1_1,
+	}, &res);
 	if (res.a0 == FFA_RET_NOT_SUPPORTED)
 		return 0;
 

-- 
2.50.0.727.gbf7dc18ff4-goog

