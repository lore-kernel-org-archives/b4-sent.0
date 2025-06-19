From: Per Larsen <perlarsen@google.com>
Date: Thu, 19 Jun 2025 09:02:56 +0000
Subject: [PATCH v5 3/6] KVM: arm64: Use SMCCC 1.2 in host FF-A handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250619-virtio-msg-ffa-v5-3-412c98558807@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750323807; l=19023;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=00kEKcyG22cmXQ8SuPQG3HoX0UoAL0AI9XTekw8ywlE=;
 b=IOtd+Bpx0yIbc6yH4khFTR2FF+R9eb7iyGg1Ojn4RamnCyEwJLwWx6sZApJfjkXWfm6yddjkV
 M4rBKRDPiF7AFxyeqQZmQFEEj2JkDUgFqOr87xnRtmgPK7wZW8n/dHA
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

SMCCC 1.1 and prior allows four registers to be sent back as a result
of an FF-A interface. SMCCC 1.2 increases the number of results that can
(and often must) be sent back to 8 and 16 for 32-bit and 64-bit SMC/HVCs
respectively.

FF-A 1.0 references SMCCC 1.2 (reference [4] on page xi) and FF-A 1.2
explicitly requires SMCCC 1.2 so it should be safe to use this version
unconditionally. Moreover, it is simpler to implement FF-A features
without having to worry about compatibility with SMCCC 1.1 and older.

Add SMCCC 1.2 helper routines and use this version unconditionally.

Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 297 ++++++++++++++++++++++++------------------
 1 file changed, 173 insertions(+), 124 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 51bbe8f9c94584e9001ee769cbfd608d930ff723..23b75b9f0bcc62724f0d0d185ac2ed2526375da4 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -71,36 +71,55 @@ static u32 hyp_ffa_version;
 static bool has_version_negotiated;
 static hyp_spinlock_t version_lock;
 
-static void ffa_to_smccc_error(struct arm_smccc_res *res, u64 ffa_errno)
+static void ffa_to_smccc_1_2_error(struct arm_smccc_1_2_regs *regs, u64 ffa_errno)
 {
-	*res = (struct arm_smccc_res) {
+	*regs = (struct arm_smccc_1_2_regs) {
 		.a0	= FFA_ERROR,
 		.a2	= ffa_errno,
 	};
 }
 
-static void ffa_to_smccc_res_prop(struct arm_smccc_res *res, int ret, u64 prop)
+static void ffa_to_smccc_regs_prop(struct arm_smccc_1_2_regs *regs, int ret,
+				   u64 prop)
 {
 	if (ret == FFA_RET_SUCCESS) {
-		*res = (struct arm_smccc_res) { .a0 = FFA_SUCCESS,
-						.a2 = prop };
+		*regs = (struct arm_smccc_1_2_regs) { .a0 = FFA_SUCCESS,
+						      .a2 = prop };
 	} else {
-		ffa_to_smccc_error(res, ret);
+		ffa_to_smccc_1_2_error(regs, ret);
 	}
 }
 
-static void ffa_to_smccc_res(struct arm_smccc_res *res, int ret)
+static void ffa_to_smccc_regs(struct arm_smccc_1_2_regs *regs, int ret)
 {
-	ffa_to_smccc_res_prop(res, ret, 0);
+	ffa_to_smccc_regs_prop(regs, ret, 0);
 }
 
 static void ffa_set_retval(struct kvm_cpu_context *ctxt,
-			   struct arm_smccc_res *res)
+			   struct arm_smccc_1_2_regs *regs)
 {
-	cpu_reg(ctxt, 0) = res->a0;
-	cpu_reg(ctxt, 1) = res->a1;
-	cpu_reg(ctxt, 2) = res->a2;
-	cpu_reg(ctxt, 3) = res->a3;
+	cpu_reg(ctxt, 0) = regs->a0;
+	cpu_reg(ctxt, 1) = regs->a1;
+	cpu_reg(ctxt, 2) = regs->a2;
+	cpu_reg(ctxt, 3) = regs->a3;
+	cpu_reg(ctxt, 4) = regs->a4;
+	cpu_reg(ctxt, 5) = regs->a5;
+	cpu_reg(ctxt, 6) = regs->a6;
+	cpu_reg(ctxt, 7) = regs->a7;
+
+	/* DEN0028C 2.6: SMC32/HVC32 call from aarch64 must preserve x8-x30 */
+	if (ARM_SMCCC_IS_64(regs->a0)) {
+		cpu_reg(ctxt, 8) = regs->a8;
+		cpu_reg(ctxt, 9) = regs->a9;
+		cpu_reg(ctxt, 10) = regs->a10;
+		cpu_reg(ctxt, 11) = regs->a11;
+		cpu_reg(ctxt, 12) = regs->a12;
+		cpu_reg(ctxt, 13) = regs->a13;
+		cpu_reg(ctxt, 14) = regs->a14;
+		cpu_reg(ctxt, 15) = regs->a15;
+		cpu_reg(ctxt, 16) = regs->a16;
+		cpu_reg(ctxt, 17) = regs->a17;
+	}
 }
 
 static bool is_ffa_call(u64 func_id)
@@ -113,82 +132,104 @@ static bool is_ffa_call(u64 func_id)
 
 static int ffa_map_hyp_buffers(u64 ffa_page_count)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs regs;
 
-	arm_smccc_1_1_smc(FFA_FN64_RXTX_MAP,
-			  hyp_virt_to_phys(hyp_buffers.tx),
-			  hyp_virt_to_phys(hyp_buffers.rx),
-			  ffa_page_count,
-			  0, 0, 0, 0,
-			  &res);
+	regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_FN64_RXTX_MAP,
+		.a1 = hyp_virt_to_phys(hyp_buffers.tx),
+		.a2 = hyp_virt_to_phys(hyp_buffers.rx),
+		.a3 = ffa_page_count,
+	};
+	arm_smccc_1_2_smc(&regs, &regs);
+	if (regs.a0 != FFA_SUCCESS)
+		return regs.a2;
 
-	return res.a0 == FFA_SUCCESS ? FFA_RET_SUCCESS : res.a2;
+	return regs.a0 == FFA_SUCCESS ? FFA_RET_SUCCESS : regs.a2;
 }
 
 static int ffa_unmap_hyp_buffers(void)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs regs;
 
-	arm_smccc_1_1_smc(FFA_RXTX_UNMAP,
-			  HOST_FFA_ID,
-			  0, 0, 0, 0, 0, 0,
-			  &res);
+	regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_RXTX_UNMAP,
+		.a1 = HOST_FFA_ID,
+	};
+	arm_smccc_1_2_smc(&regs, &regs);
+	if (regs.a0 != FFA_SUCCESS)
+		return regs.a2;
 
-	return res.a0 == FFA_SUCCESS ? FFA_RET_SUCCESS : res.a2;
+	return regs.a0 == FFA_SUCCESS ? FFA_RET_SUCCESS : regs.a2;
 }
 
-static void ffa_mem_frag_tx(struct arm_smccc_res *res, u32 handle_lo,
+static void ffa_mem_frag_tx(struct arm_smccc_1_2_regs *regs, u32 handle_lo,
 			     u32 handle_hi, u32 fraglen, u32 endpoint_id)
 {
-	arm_smccc_1_1_smc(FFA_MEM_FRAG_TX,
-			  handle_lo, handle_hi, fraglen, endpoint_id,
-			  0, 0, 0,
-			  res);
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_MEM_FRAG_TX,
+		.a1 = handle_lo,
+		.a2 = handle_hi,
+		.a3 = fraglen,
+		.a4 = endpoint_id,
+	};
+	arm_smccc_1_2_smc(regs, regs);
 }
 
-static void ffa_mem_frag_rx(struct arm_smccc_res *res, u32 handle_lo,
+static void ffa_mem_frag_rx(struct arm_smccc_1_2_regs *regs, u32 handle_lo,
 			     u32 handle_hi, u32 fragoff)
 {
-	arm_smccc_1_1_smc(FFA_MEM_FRAG_RX,
-			  handle_lo, handle_hi, fragoff, HOST_FFA_ID,
-			  0, 0, 0,
-			  res);
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_MEM_FRAG_RX,
+		.a1 = handle_lo,
+		.a2 = handle_hi,
+		.a3 = fragoff,
+		.a4 = HOST_FFA_ID,
+	};
+	arm_smccc_1_2_smc(regs, regs);
 }
 
-static void ffa_mem_xfer(struct arm_smccc_res *res, u64 func_id, u32 len,
+static void ffa_mem_xfer(struct arm_smccc_1_2_regs *regs, u64 func_id, u32 len,
 			  u32 fraglen)
 {
-	arm_smccc_1_1_smc(func_id, len, fraglen,
-			  0, 0, 0, 0, 0,
-			  res);
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0 = func_id,
+		.a1 = len,
+		.a2 = fraglen,
+	};
+	arm_smccc_1_2_smc(regs, regs);
 }
 
-static void ffa_mem_reclaim(struct arm_smccc_res *res, u32 handle_lo,
+static void ffa_mem_reclaim(struct arm_smccc_1_2_regs *regs, u32 handle_lo,
 			     u32 handle_hi, u32 flags)
 {
-	arm_smccc_1_1_smc(FFA_MEM_RECLAIM,
-			  handle_lo, handle_hi, flags,
-			  0, 0, 0, 0,
-			  res);
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_MEM_RECLAIM,
+		.a1 = handle_lo,
+		.a2 = handle_hi,
+		.a3 = flags,
+	};
+	arm_smccc_1_2_smc(regs, regs);
 }
 
-static void ffa_retrieve_req(struct arm_smccc_res *res, u32 len)
+static void ffa_retrieve_req(struct arm_smccc_1_2_regs *regs, u32 len)
 {
-	arm_smccc_1_1_smc(FFA_FN64_MEM_RETRIEVE_REQ,
-			  len, len,
-			  0, 0, 0, 0, 0,
-			  res);
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_FN64_MEM_RETRIEVE_REQ,
+		.a1 = len,
+		.a2 = len,
+	};
+	arm_smccc_1_2_smc(regs, regs);
 }
 
-static void ffa_rx_release(struct arm_smccc_res *res)
+static void ffa_rx_release(struct arm_smccc_1_2_regs *regs)
 {
-	arm_smccc_1_1_smc(FFA_RX_RELEASE,
-			  0, 0,
-			  0, 0, 0, 0, 0,
-			  res);
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_RX_RELEASE,
+	};
+	arm_smccc_1_2_smc(regs, regs);
 }
 
-static void do_ffa_rxtx_map(struct arm_smccc_res *res,
+static void do_ffa_rxtx_map(struct arm_smccc_1_2_regs *regs,
 			    struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(phys_addr_t, tx, ctxt, 1);
@@ -253,7 +294,7 @@ static void do_ffa_rxtx_map(struct arm_smccc_res *res,
 out_unlock:
 	hyp_spin_unlock(&host_buffers.lock);
 out:
-	ffa_to_smccc_res(res, ret);
+	ffa_to_smccc_regs(regs, ret);
 	return;
 
 err_unpin_tx:
@@ -267,7 +308,7 @@ static void do_ffa_rxtx_map(struct arm_smccc_res *res,
 	goto out_unlock;
 }
 
-static void do_ffa_rxtx_unmap(struct arm_smccc_res *res,
+static void do_ffa_rxtx_unmap(struct arm_smccc_1_2_regs *regs,
 			      struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, id, ctxt, 1);
@@ -297,7 +338,7 @@ static void do_ffa_rxtx_unmap(struct arm_smccc_res *res,
 out_unlock:
 	hyp_spin_unlock(&host_buffers.lock);
 out:
-	ffa_to_smccc_res(res, ret);
+	ffa_to_smccc_regs(regs, ret);
 }
 
 static u32 __ffa_host_share_ranges(struct ffa_mem_region_addr_range *ranges,
@@ -368,7 +409,7 @@ static int ffa_host_unshare_ranges(struct ffa_mem_region_addr_range *ranges,
 	return ret;
 }
 
-static void do_ffa_mem_frag_tx(struct arm_smccc_res *res,
+static void do_ffa_mem_frag_tx(struct arm_smccc_1_2_regs *regs,
 			       struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, handle_lo, ctxt, 1);
@@ -400,20 +441,20 @@ static void do_ffa_mem_frag_tx(struct arm_smccc_res *res,
 		 * to restore the global state back to what it was prior to
 		 * transmission of the first fragment.
 		 */
-		ffa_mem_reclaim(res, handle_lo, handle_hi, 0);
-		WARN_ON(res->a0 != FFA_SUCCESS);
+		ffa_mem_reclaim(regs, handle_lo, handle_hi, 0);
+		WARN_ON(regs->a0 != FFA_SUCCESS);
 		goto out_unlock;
 	}
 
-	ffa_mem_frag_tx(res, handle_lo, handle_hi, fraglen, endpoint_id);
-	if (res->a0 != FFA_SUCCESS && res->a0 != FFA_MEM_FRAG_RX)
+	ffa_mem_frag_tx(regs, handle_lo, handle_hi, fraglen, endpoint_id);
+	if (regs->a0 != FFA_SUCCESS && regs->a0 != FFA_MEM_FRAG_RX)
 		WARN_ON(ffa_host_unshare_ranges(buf, nr_ranges));
 
 out_unlock:
 	hyp_spin_unlock(&host_buffers.lock);
 out:
 	if (ret)
-		ffa_to_smccc_res(res, ret);
+		ffa_to_smccc_regs(regs, ret);
 
 	/*
 	 * If for any reason this did not succeed, we're in trouble as we have
@@ -427,7 +468,7 @@ static void do_ffa_mem_frag_tx(struct arm_smccc_res *res,
 }
 
 static void __do_ffa_mem_xfer(const u64 func_id,
-			      struct arm_smccc_res *res,
+			      struct arm_smccc_1_2_regs *regs,
 			      struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, len, ctxt, 1);
@@ -491,14 +532,14 @@ static void __do_ffa_mem_xfer(const u64 func_id,
 	if (ret)
 		goto out_unlock;
 
-	ffa_mem_xfer(res, func_id, len, fraglen);
+	ffa_mem_xfer(regs, func_id, len, fraglen);
 	if (fraglen != len) {
-		if (res->a0 != FFA_MEM_FRAG_RX)
+		if (regs->a0 != FFA_MEM_FRAG_RX)
 			goto err_unshare;
 
-		if (res->a3 != fraglen)
+		if (regs->a3 != fraglen)
 			goto err_unshare;
-	} else if (res->a0 != FFA_SUCCESS) {
+	} else if (regs->a0 != FFA_SUCCESS) {
 		goto err_unshare;
 	}
 
@@ -506,7 +547,7 @@ static void __do_ffa_mem_xfer(const u64 func_id,
 	hyp_spin_unlock(&host_buffers.lock);
 out:
 	if (ret)
-		ffa_to_smccc_res(res, ret);
+		ffa_to_smccc_regs(regs, ret);
 	return;
 
 err_unshare:
@@ -514,14 +555,14 @@ static void __do_ffa_mem_xfer(const u64 func_id,
 	goto out_unlock;
 }
 
-#define do_ffa_mem_xfer(fid, res, ctxt)				\
+#define do_ffa_mem_xfer(fid, regs, ctxt)			\
 	do {							\
 		BUILD_BUG_ON((fid) != FFA_FN64_MEM_SHARE &&	\
 			     (fid) != FFA_FN64_MEM_LEND);	\
-		__do_ffa_mem_xfer((fid), (res), (ctxt));	\
-	} while (0);
+		__do_ffa_mem_xfer((fid), (regs), (ctxt));	\
+	} while (0)
 
-static void do_ffa_mem_reclaim(struct arm_smccc_res *res,
+static void do_ffa_mem_reclaim(struct arm_smccc_1_2_regs *regs,
 			       struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, handle_lo, ctxt, 1);
@@ -544,13 +585,13 @@ static void do_ffa_mem_reclaim(struct arm_smccc_res *res,
 		.handle		= handle,
 	};
 
-	ffa_retrieve_req(res, sizeof(*buf));
+	ffa_retrieve_req(regs, sizeof(*buf));
 	buf = hyp_buffers.rx;
-	if (res->a0 != FFA_MEM_RETRIEVE_RESP)
+	if (regs->a0 != FFA_MEM_RETRIEVE_RESP)
 		goto out_unlock;
 
-	len = res->a1;
-	fraglen = res->a2;
+	len = regs->a1;
+	fraglen = regs->a2;
 
 	ep_mem_access = (void *)buf +
 			ffa_mem_desc_offset(buf, 0, hyp_ffa_version);
@@ -563,34 +604,34 @@ static void do_ffa_mem_reclaim(struct arm_smccc_res *res,
 	if (WARN_ON(offset > len ||
 		    fraglen > KVM_FFA_MBOX_NR_PAGES * PAGE_SIZE)) {
 		ret = FFA_RET_ABORTED;
-		ffa_rx_release(res);
+		ffa_rx_release(regs);
 		goto out_unlock;
 	}
 
 	if (len > ffa_desc_buf.len) {
 		ret = FFA_RET_NO_MEMORY;
-		ffa_rx_release(res);
+		ffa_rx_release(regs);
 		goto out_unlock;
 	}
 
 	buf = ffa_desc_buf.buf;
 	memcpy(buf, hyp_buffers.rx, fraglen);
-	ffa_rx_release(res);
+	ffa_rx_release(regs);
 
 	for (fragoff = fraglen; fragoff < len; fragoff += fraglen) {
-		ffa_mem_frag_rx(res, handle_lo, handle_hi, fragoff);
-		if (res->a0 != FFA_MEM_FRAG_TX) {
+		ffa_mem_frag_rx(regs, handle_lo, handle_hi, fragoff);
+		if (regs->a0 != FFA_MEM_FRAG_TX) {
 			ret = FFA_RET_INVALID_PARAMETERS;
 			goto out_unlock;
 		}
 
-		fraglen = res->a3;
+		fraglen = regs->a3;
 		memcpy((void *)buf + fragoff, hyp_buffers.rx, fraglen);
-		ffa_rx_release(res);
+		ffa_rx_release(regs);
 	}
 
-	ffa_mem_reclaim(res, handle_lo, handle_hi, flags);
-	if (res->a0 != FFA_SUCCESS)
+	ffa_mem_reclaim(regs, handle_lo, handle_hi, flags);
+	if (regs->a0 != FFA_SUCCESS)
 		goto out_unlock;
 
 	reg = (void *)buf + offset;
@@ -601,7 +642,7 @@ static void do_ffa_mem_reclaim(struct arm_smccc_res *res,
 	hyp_spin_unlock(&host_buffers.lock);
 
 	if (ret)
-		ffa_to_smccc_res(res, ret);
+		ffa_to_smccc_regs(regs, ret);
 }
 
 /*
@@ -634,7 +675,7 @@ static bool ffa_call_supported(u64 func_id)
 	return true;
 }
 
-static bool do_ffa_features(struct arm_smccc_res *res,
+static bool do_ffa_features(struct arm_smccc_1_2_regs *regs,
 			    struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, id, ctxt, 1);
@@ -659,7 +700,7 @@ static bool do_ffa_features(struct arm_smccc_res *res,
 	}
 
 out_handled:
-	ffa_to_smccc_res_prop(res, ret, prop);
+	ffa_to_smccc_regs_prop(regs, ret, prop);
 	return true;
 }
 
@@ -705,22 +746,22 @@ static int hyp_ffa_post_init(void)
 	return 0;
 }
 
-static void do_ffa_version(struct arm_smccc_res *res,
+static void do_ffa_version(struct arm_smccc_1_2_regs *regs,
 			   struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, ffa_req_version, ctxt, 1);
 
 	if (FFA_MAJOR_VERSION(ffa_req_version) != 1) {
-		res->a0 = FFA_RET_NOT_SUPPORTED;
+		regs->a0 = FFA_RET_NOT_SUPPORTED;
 		return;
 	}
 
 	hyp_spin_lock(&version_lock);
 	if (has_version_negotiated) {
 		if (FFA_MINOR_VERSION(ffa_req_version) < FFA_MINOR_VERSION(hyp_ffa_version))
-			res->a0 = FFA_RET_NOT_SUPPORTED;
+			regs->a0 = FFA_RET_NOT_SUPPORTED;
 		else
-			res->a0 = hyp_ffa_version;
+			regs->a0 = hyp_ffa_version;
 		goto unlock;
 	}
 
@@ -729,26 +770,28 @@ static void do_ffa_version(struct arm_smccc_res *res,
 	 * first if TEE supports it.
 	 */
 	if (FFA_MINOR_VERSION(ffa_req_version) < FFA_MINOR_VERSION(hyp_ffa_version)) {
-		arm_smccc_1_1_smc(FFA_VERSION, ffa_req_version, 0,
-				  0, 0, 0, 0, 0,
-				  res);
-		if (res->a0 == FFA_RET_NOT_SUPPORTED)
+		*regs = (struct arm_smccc_1_2_regs) {
+			.a0 = FFA_VERSION,
+			.a1 = ffa_req_version,
+		};
+		arm_smccc_1_2_smc(regs, regs);
+		if (regs->a0 == FFA_RET_NOT_SUPPORTED)
 			goto unlock;
 
 		hyp_ffa_version = ffa_req_version;
 	}
 
 	if (hyp_ffa_post_init()) {
-		res->a0 = FFA_RET_NOT_SUPPORTED;
+		regs->a0 = FFA_RET_NOT_SUPPORTED;
 	} else {
 		smp_store_release(&has_version_negotiated, true);
-		res->a0 = hyp_ffa_version;
+		regs->a0 = hyp_ffa_version;
 	}
 unlock:
 	hyp_spin_unlock(&version_lock);
 }
 
-static void do_ffa_part_get(struct arm_smccc_res *res,
+static void do_ffa_part_get(struct arm_smccc_1_2_regs *regs,
 			    struct kvm_cpu_context *ctxt)
 {
 	DECLARE_REG(u32, uuid0, ctxt, 1);
@@ -760,18 +803,24 @@ static void do_ffa_part_get(struct arm_smccc_res *res,
 
 	hyp_spin_lock(&host_buffers.lock);
 	if (!host_buffers.rx) {
-		ffa_to_smccc_res(res, FFA_RET_BUSY);
+		ffa_to_smccc_regs(regs, FFA_RET_BUSY);
 		goto out_unlock;
 	}
 
-	arm_smccc_1_1_smc(FFA_PARTITION_INFO_GET, uuid0, uuid1,
-			  uuid2, uuid3, flags, 0, 0,
-			  res);
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0 = FFA_PARTITION_INFO_GET,
+		.a1 = uuid0,
+		.a2 = uuid1,
+		.a3 = uuid2,
+		.a4 = uuid3,
+		.a5 = flags,
+	};
+	arm_smccc_1_2_smc(regs, regs);
 
-	if (res->a0 != FFA_SUCCESS)
+	if (regs->a0 != FFA_SUCCESS)
 		goto out_unlock;
 
-	count = res->a2;
+	count = regs->a2;
 	if (!count)
 		goto out_unlock;
 
@@ -780,7 +829,7 @@ static void do_ffa_part_get(struct arm_smccc_res *res,
 		if (flags & 0x1)
 			goto out_unlock;
 
-		partition_sz  = res->a3;
+		partition_sz  = regs->a3;
 	} else {
 		/* FFA_VERSION_1_0 lacks the size in the response */
 		partition_sz = FFA_1_0_PARTITON_INFO_SZ;
@@ -788,7 +837,7 @@ static void do_ffa_part_get(struct arm_smccc_res *res,
 
 	copy_sz = partition_sz * count;
 	if (copy_sz > KVM_FFA_MBOX_NR_PAGES * PAGE_SIZE) {
-		ffa_to_smccc_res(res, FFA_RET_ABORTED);
+		ffa_to_smccc_regs(regs, FFA_RET_ABORTED);
 		goto out_unlock;
 	}
 
@@ -799,7 +848,7 @@ static void do_ffa_part_get(struct arm_smccc_res *res,
 
 bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 {
-	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs regs;
 
 	/*
 	 * There's no way we can tell what a non-standard SMC call might
@@ -819,50 +868,50 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 
 	if (func_id != FFA_VERSION &&
 	    !smp_load_acquire(&has_version_negotiated)) {
-		ffa_to_smccc_error(&res, FFA_RET_INVALID_PARAMETERS);
+		ffa_to_smccc_1_2_error(&regs, FFA_RET_INVALID_PARAMETERS);
 		goto out_handled;
 	}
 
 	switch (func_id) {
 	case FFA_FEATURES:
-		if (!do_ffa_features(&res, host_ctxt))
+		if (!do_ffa_features(&regs, host_ctxt))
 			return false;
 		goto out_handled;
 	/* Memory management */
 	case FFA_FN64_RXTX_MAP:
-		do_ffa_rxtx_map(&res, host_ctxt);
+		do_ffa_rxtx_map(&regs, host_ctxt);
 		goto out_handled;
 	case FFA_RXTX_UNMAP:
-		do_ffa_rxtx_unmap(&res, host_ctxt);
+		do_ffa_rxtx_unmap(&regs, host_ctxt);
 		goto out_handled;
 	case FFA_MEM_SHARE:
 	case FFA_FN64_MEM_SHARE:
-		do_ffa_mem_xfer(FFA_FN64_MEM_SHARE, &res, host_ctxt);
+		do_ffa_mem_xfer(FFA_FN64_MEM_SHARE, &regs, host_ctxt);
 		goto out_handled;
 	case FFA_MEM_RECLAIM:
-		do_ffa_mem_reclaim(&res, host_ctxt);
+		do_ffa_mem_reclaim(&regs, host_ctxt);
 		goto out_handled;
 	case FFA_MEM_LEND:
 	case FFA_FN64_MEM_LEND:
-		do_ffa_mem_xfer(FFA_FN64_MEM_LEND, &res, host_ctxt);
+		do_ffa_mem_xfer(FFA_FN64_MEM_LEND, &regs, host_ctxt);
 		goto out_handled;
 	case FFA_MEM_FRAG_TX:
-		do_ffa_mem_frag_tx(&res, host_ctxt);
+		do_ffa_mem_frag_tx(&regs, host_ctxt);
 		goto out_handled;
 	case FFA_VERSION:
-		do_ffa_version(&res, host_ctxt);
+		do_ffa_version(&regs, host_ctxt);
 		goto out_handled;
 	case FFA_PARTITION_INFO_GET:
-		do_ffa_part_get(&res, host_ctxt);
+		do_ffa_part_get(&regs, host_ctxt);
 		goto out_handled;
 	}
 
 	if (ffa_call_supported(func_id))
 		return false; /* Pass through */
 
-	ffa_to_smccc_error(&res, FFA_RET_NOT_SUPPORTED);
+	ffa_to_smccc_1_2_error(&regs, FFA_RET_NOT_SUPPORTED);
 out_handled:
-	ffa_set_retval(host_ctxt, &res);
+	ffa_set_retval(host_ctxt, &regs);
 	return true;
 }
 

-- 
2.50.0.rc2.701.gf1e915cc24-goog

