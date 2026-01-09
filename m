From: Per Larsen <perlarsen@google.com>
Date: Fri, 09 Jan 2026 22:34:25 +0000
Subject: [PATCH v4 1/2] KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ in host
 handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260109-host-direct-messages-v4-1-95da4221d186@google.com>
References: <20260109-host-direct-messages-v4-0-95da4221d186@google.com>
In-Reply-To: <20260109-host-direct-messages-v4-0-95da4221d186@google.com>
To: Marc Zyngier <maz@kernel.org>, Joey Gouly <joey.gouly@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Yeoreum Yun <yeoreum.yun@arm.com>, Ben Horgan <ben.horgan@arm.com>, 
 Oliver Upton <oupton@kernel.org>
Cc: Armelle Laine <armellel@google.com>, 
 Sebastien Ene <sebastianene@google.com>, 
 linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767998072; l=2212;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=w/i2Ml6dE6jz3JLbRWYLcU7BlfS1xCbyKvHbkV2MRRA=;
 b=xYmKBs65rSUnbTXmKTCxgMWon/4X3RUxdPsG8Cj2usbIGZu9UjyDqahHlTM25wI9lFyU8ezGk
 Fra7TJtjhoHCo/5jmgFb0vOVgISe6ixXpeX4H3s8r+Y3SFWE/Xfx9yn
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sebastian Ene <sebastianene@google.com>

Allow direct messages to be forwarded from the host. The host should
not be sending framework messages so they are filtered out.

Signed-off-by: Sebastian Ene <sebastianene@google.com>
Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 20 ++++++++++++++++++++
 include/linux/arm_ffa.h       |  3 +++
 2 files changed, 23 insertions(+)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index f731cc4c3f280a32acccca0de92b9ac6c8e05602..fc84595007f310004def7d525371fa7c128f244a 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -862,6 +862,22 @@ static void do_ffa_part_get(struct arm_smccc_1_2_regs *res,
 	hyp_spin_unlock(&host_buffers.lock);
 }
 
+static void do_ffa_direct_msg(struct arm_smccc_1_2_regs *res,
+			      struct kvm_cpu_context *ctxt)
+{
+	DECLARE_REG(u32, flags, ctxt, 2);
+
+	struct arm_smccc_1_2_regs *args = (void *)&ctxt->regs.regs[0];
+
+	/* filter out framework messages and validate SBZ/MBZ bits */
+	if (flags) {
+		ffa_to_smccc_error(res, FFA_RET_INVALID_PARAMETERS);
+		return;
+	}
+
+	arm_smccc_1_2_smc(args, res);
+}
+
 bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 {
 	struct arm_smccc_1_2_regs res;
@@ -920,6 +936,10 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 	case FFA_PARTITION_INFO_GET:
 		do_ffa_part_get(&res, host_ctxt);
 		goto out_handled;
+	case FFA_MSG_SEND_DIRECT_REQ:
+	case FFA_FN64_MSG_SEND_DIRECT_REQ:
+		do_ffa_direct_msg(&res, host_ctxt);
+		goto out_handled;
 	}
 
 	if (ffa_call_supported(func_id))
diff --git a/include/linux/arm_ffa.h b/include/linux/arm_ffa.h
index 81e603839c4a51873090b7e22edbe7b33a7e94df..d209d0cdac1eb804be01e4607acac8f76cc99e40 100644
--- a/include/linux/arm_ffa.h
+++ b/include/linux/arm_ffa.h
@@ -130,6 +130,9 @@
 #define FFA_FEAT_RXTX_MIN_SZ_16K	2
 #define FFA_FEAT_RXTX_MIN_SZ_MASK	GENMASK(1, 0)
 
+/* FFA message flags */
+#define FFA_MSG_FLAGS_MSG_TYPE		BIT(31)
+
 /* FFA Bus/Device/Driver related */
 struct ffa_device {
 	u32 id;

-- 
2.52.0.457.g6b5491de43-goog

