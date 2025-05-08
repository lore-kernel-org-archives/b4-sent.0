From: Per Larsen <perlarsen@google.com>
Date: Thu, 08 May 2025 08:38:54 +0000
Subject: [PATCH v2 3/3] KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ2 in
 host handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250508-virtio-msg-ffa-v2-3-ed84f8053965@google.com>
References: <20250508-virtio-msg-ffa-v2-0-ed84f8053965@google.com>
In-Reply-To: <20250508-virtio-msg-ffa-v2-0-ed84f8053965@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, arve@android.com, lpieralisi@kernel.org, 
 qwandor@google.com, jean-philippe@linaro.org, james.morse@arm.com, 
 perl@immunant.com, tabba@google.com, kernel-team@android.com, 
 armellel@google.com, qperret@google.com, sebastianene@google.com, 
 ahomescu@google.com, Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746693571; l=6782;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=IGMQIIrUrHG9Da+sVqUyprEmAlWez8rBv29B3RzV3og=;
 b=XZvdV1OUGgx7Sv1wa4rmaJQAuCcvIoOhh+OOXn/0sOBOvenTaWZVMJsf/w/XburA6om+Rh+mO
 qk5zng3THLGByuCONoKycEDMkV0Jre8taVX6hLE5dZpmFhruhHgsaNS
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FF-A 1.2 adds the DIRECT_REQ2 messaging interface which is similar to
the existing FFA_MSG_SEND_DIRECT_{REQ,RESP} functions except that it
uses the SMC calling convention v1.2 which allows calls to use x4-x17 as
argument and return registers. Add support for FFA_MSG_SEND_DIRECT_REQ2
in the host ffa handler.

Signed-off-by: Per Larsen <perlarsen@google.com>
Signed-off-by: Per Larsen <perl@immunant.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 114 +++++++++++++++++++++++++++++++++++++++++-
 include/linux/arm_ffa.h       |   2 +
 2 files changed, 114 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 3fa5d1ae26c40fb96ad2deb834882bb3e0af5637..5ffbc0d496fca830a5f3af5bd9edd63b8e79b028 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -79,6 +79,14 @@ static void ffa_to_smccc_error(struct arm_smccc_res *res, u64 ffa_errno)
 	};
 }
 
+static void ffa_to_smccc_1_2_error(struct arm_smccc_1_2_regs *regs, u64 ffa_errno)
+{
+	*regs = (struct arm_smccc_1_2_regs) {
+		.a0	= FFA_ERROR,
+		.a2	= ffa_errno,
+	};
+}
+
 static void ffa_to_smccc_res_prop(struct arm_smccc_res *res, int ret, u64 prop)
 {
 	if (ret == FFA_RET_SUCCESS) {
@@ -89,11 +97,24 @@ static void ffa_to_smccc_res_prop(struct arm_smccc_res *res, int ret, u64 prop)
 	}
 }
 
+static void ffa_to_smccc_1_2_regs_prop(struct arm_smccc_1_2_regs *regs, int ret, u64 prop)
+{
+	if (ret == FFA_RET_SUCCESS)
+		*regs = (struct arm_smccc_1_2_regs) { .a0 = FFA_SUCCESS,
+						      .a2 = prop };
+	else
+		ffa_to_smccc_1_2_error(regs, ret);
+}
+
 static void ffa_to_smccc_res(struct arm_smccc_res *res, int ret)
 {
 	ffa_to_smccc_res_prop(res, ret, 0);
 }
 
+static void ffa_to_smccc_1_2_regs(struct arm_smccc_1_2_regs *regs, int ret)
+{
+	ffa_to_smccc_1_2_regs_prop(regs, ret, 0);
+}
 
 static void ffa_set_retval(struct kvm_cpu_context *ctxt,
 			   struct arm_smccc_res *res)
@@ -136,6 +157,29 @@ static void ffa_set_retval(struct kvm_cpu_context *ctxt,
 	}
 }
 
+static void ffa_set_retval_smccc_1_2(struct kvm_cpu_context *ctxt,
+			   struct arm_smccc_1_2_regs *regs)
+{
+	cpu_reg(ctxt, 0) = regs->a0;
+	cpu_reg(ctxt, 1) = regs->a1;
+	cpu_reg(ctxt, 2) = regs->a2;
+	cpu_reg(ctxt, 3) = regs->a3;
+	cpu_reg(ctxt, 4) = regs->a4;
+	cpu_reg(ctxt, 5) = regs->a5;
+	cpu_reg(ctxt, 6) = regs->a6;
+	cpu_reg(ctxt, 7) = regs->a7;
+	cpu_reg(ctxt, 8) = regs->a8;
+	cpu_reg(ctxt, 9) = regs->a9;
+	cpu_reg(ctxt, 10) = regs->a10;
+	cpu_reg(ctxt, 11) = regs->a11;
+	cpu_reg(ctxt, 12) = regs->a12;
+	cpu_reg(ctxt, 13) = regs->a13;
+	cpu_reg(ctxt, 14) = regs->a14;
+	cpu_reg(ctxt, 15) = regs->a15;
+	cpu_reg(ctxt, 16) = regs->a16;
+	cpu_reg(ctxt, 17) = regs->a17;
+}
+
 /* Call SMC64 using SMCCC 1.2 if hyp negotiated FF-A 1.2 falling back to 1.1 */
 static void arm_smccc_1_x_smc(u64 func_id, u64 a1, u64 a2, u64 a3,
 			      u64 a4, u64 a5, u64 a6, u64 a7,
@@ -696,7 +740,6 @@ static bool ffa_call_supported(u64 func_id)
 	case FFA_NOTIFICATION_GET:
 	case FFA_NOTIFICATION_INFO_GET:
 	/* Unimplemented interfaces added in FF-A 1.2 */
-	case FFA_MSG_SEND_DIRECT_REQ2:
 	case FFA_MSG_SEND_DIRECT_RESP2:
 	case FFA_CONSOLE_LOG:
 	case FFA_PARTITION_INFO_GET_REGS:
@@ -707,6 +750,21 @@ static bool ffa_call_supported(u64 func_id)
 	return true;
 }
 
+/*
+ * Must a given FFA function use the SMC calling convention v1.2?
+ */
+static bool ffa_call_needs_smccc_1_2(u64 func_id)
+{
+	switch (func_id) {
+	case FFA_MSG_SEND_DIRECT_REQ2:
+	case FFA_MSG_SEND_DIRECT_RESP2:
+	case FFA_PARTITION_INFO_GET_REGS:
+		return true;
+	}
+
+	return false;
+}
+
 static bool do_ffa_features(struct arm_smccc_res *res,
 			    struct kvm_cpu_context *ctxt)
 {
@@ -865,9 +923,47 @@ static void do_ffa_part_get(struct arm_smccc_res *res,
 	hyp_spin_unlock(&host_buffers.lock);
 }
 
+static void do_ffa_direct_msg2(struct arm_smccc_1_2_regs *regs,
+			       struct kvm_cpu_context *ctxt,
+			       u64 vm_handle)
+{
+	DECLARE_REG(u32, func_id, ctxt, 0);
+	DECLARE_REG(u32, endp, ctxt, 1);
+	DECLARE_REG(u64, uuid_lo, ctxt, 2);
+	DECLARE_REG(u64, uuid_hi, ctxt, 3);
+	DECLARE_REG(u64, x4, ctxt, 4);
+	DECLARE_REG(u64, x5, ctxt, 5);
+	DECLARE_REG(u64, x6, ctxt, 6);
+	DECLARE_REG(u64, x7, ctxt, 7);
+	DECLARE_REG(u64, x8, ctxt, 8);
+	DECLARE_REG(u64, x9, ctxt, 9);
+	DECLARE_REG(u64, x10, ctxt, 10);
+	DECLARE_REG(u64, x11, ctxt, 11);
+	DECLARE_REG(u64, x12, ctxt, 12);
+	DECLARE_REG(u64, x13, ctxt, 13);
+	DECLARE_REG(u64, x14, ctxt, 14);
+	DECLARE_REG(u64, x15, ctxt, 15);
+	DECLARE_REG(u64, x16, ctxt, 16);
+	DECLARE_REG(u64, x17, ctxt, 17);
+
+	if (FIELD_GET(FFA_SRC_ENDPOINT_MASK, endp) != vm_handle) {
+		ffa_to_smccc_1_2_regs(regs, FFA_RET_INVALID_PARAMETERS);
+		return;
+	}
+
+	struct arm_smccc_1_2_regs args = {
+		func_id, endp, uuid_lo, uuid_hi,
+		 x4,  x5,  x6,  x7,  x8,  x9, x10,
+		x11, x12, x13, x14, x15, x16, x17
+	};
+
+	arm_smccc_1_2_smc(&args, regs);
+}
+
 bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 {
 	struct arm_smccc_res res;
+	struct arm_smccc_1_2_regs regs;
 
 	/*
 	 * There's no way we can tell what a non-standard SMC call might
@@ -923,14 +1019,28 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 	case FFA_PARTITION_INFO_GET:
 		do_ffa_part_get(&res, host_ctxt);
 		goto out_handled;
+	case FFA_MSG_SEND_DIRECT_REQ2:
+		hyp_spin_lock(&version_lock);
+		if (hyp_ffa_version >= FFA_VERSION_1_2) {
+			do_ffa_direct_msg2(&regs, host_ctxt, HOST_FFA_ID);
+			hyp_spin_unlock(&version_lock);
+			goto out_handled;
+		}
+
+		hyp_spin_unlock(&version_lock);
+		goto out_not_supported;
 	}
 
 	if (ffa_call_supported(func_id))
 		return false; /* Pass through */
 
+out_not_supported:
 	ffa_to_smccc_error(&res, FFA_RET_NOT_SUPPORTED);
 out_handled:
-	ffa_set_retval(host_ctxt, &res);
+	if (ffa_call_needs_smccc_1_2(func_id))
+		ffa_set_retval_smccc_1_2(host_ctxt, &regs);
+	else
+		ffa_set_retval(host_ctxt, &res);
 	return true;
 }
 
diff --git a/include/linux/arm_ffa.h b/include/linux/arm_ffa.h
index c0dd6183d956043192114a522b7eef465e7078ac..82a35a3b22de426f7e9a8894e76fdf1e933b3d6b 100644
--- a/include/linux/arm_ffa.h
+++ b/include/linux/arm_ffa.h
@@ -269,6 +269,8 @@ bool ffa_partition_check_property(struct ffa_device *dev, u32 property)
 	(ffa_partition_check_property(dev, FFA_PARTITION_DIRECT_REQ2_RECV) && \
 	 !dev->mode_32bit)
 
+#define FFA_SRC_ENDPOINT_MASK	GENMASK(31, 16)
+
 /* For use with FFA_MSG_SEND_DIRECT_{REQ,RESP} which pass data via registers */
 struct ffa_send_direct_data {
 	unsigned long data0; /* w3/x3 */

-- 
2.49.0.987.g0cc8ee98dc-goog

