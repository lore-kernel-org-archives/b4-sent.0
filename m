From: Per Larsen <perlarsen@google.com>
Date: Wed, 19 Nov 2025 02:07:54 +0000
Subject: [PATCH v3 2/2] KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ2 in
 host handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-host-direct-messages-v3-2-c74d04944b26@google.com>
References: <20251119-host-direct-messages-v3-0-c74d04944b26@google.com>
In-Reply-To: <20251119-host-direct-messages-v3-0-c74d04944b26@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763518092; l=2628;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=0P7CauTG9R1nzKRFKD32UxjLLHMH6ZtNvg/BjDofeXQ=;
 b=EZG9yPi4huWCccQXEesR1wCdc/CnJUYSPaK4VunD6mhrLHI12t9bObg45GcwkKX0FO/4oX1Mq
 QlNJtRd1F5PC/yNtMbD3eBg1eF+aMS2tMTrUiEUIgHzI/EqYBGSppqi
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FF-A 1.2 adds the DIRECT_REQ2 messaging interface which is similar to
the existing FFA_MSG_SEND_DIRECT_{REQ,RESP} functions and can use the
existing handler function. Add support for FFA_MSG_SEND_DIRECT_REQ2 in
the host ffa handler.

Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index a38a3ab497e5eac11777109684a33f02d88d09a1..c794802bda589b315faf978086ad164a2aee510a 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -683,8 +683,10 @@ static bool ffa_call_supported(u64 func_id)
 	case FFA_NOTIFICATION_SET:
 	case FFA_NOTIFICATION_GET:
 	case FFA_NOTIFICATION_INFO_GET:
+		return false;
 	/* Optional interfaces added in FF-A 1.2 */
 	case FFA_MSG_SEND_DIRECT_REQ2:		/* Optional per 7.5.1 */
+		return hyp_ffa_version >= FFA_VERSION_1_2;
 	case FFA_MSG_SEND_DIRECT_RESP2:		/* Optional per 7.5.1 */
 	case FFA_CONSOLE_LOG:			/* Optional per 13.1: not in Table 13.1 */
 	case FFA_PARTITION_INFO_GET_REGS:	/* Optional for virtual instances per 13.1 */
@@ -866,12 +868,16 @@ static void do_ffa_direct_msg(struct arm_smccc_1_2_regs *res,
 			      struct kvm_cpu_context *ctxt,
 			      u64 vm_handle)
 {
+	DECLARE_REG(u64, func_id, ctxt, 0);
 	DECLARE_REG(u32, flags, ctxt, 2);
 
 	struct arm_smccc_1_2_regs *args = (void *)&ctxt->regs.regs[0];
 
-	/* filter out framework messages */
-	if (FIELD_GET(FFA_MSG_FLAGS_MSG_TYPE, flags)) {
+	/*
+	 * filter out framework messages.
+	 * FFA_MSG_SEND_DIRECT_REQ2 is only for partition messages.
+	 */
+	if (func_id != FFA_MSG_SEND_DIRECT_REQ2 && FIELD_GET(FFA_MSG_FLAGS_MSG_TYPE, flags)) {
 		ffa_to_smccc_error(res, FFA_RET_INVALID_PARAMETERS);
 		return;
 	}
@@ -937,6 +943,10 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 	case FFA_PARTITION_INFO_GET:
 		do_ffa_part_get(&res, host_ctxt);
 		goto out_handled;
+	case FFA_MSG_SEND_DIRECT_REQ2:
+		if (!ffa_call_supported(func_id))
+			goto out_not_supported;
+		fallthrough;
 	case FFA_MSG_SEND_DIRECT_REQ:
 	case FFA_FN64_MSG_SEND_DIRECT_REQ:
 
@@ -947,6 +957,7 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 	if (ffa_call_supported(func_id))
 		return false; /* Pass through */
 
+out_not_supported:
 	ffa_to_smccc_error(&res, FFA_RET_NOT_SUPPORTED);
 out_handled:
 	ffa_set_retval(host_ctxt, &res);

-- 
2.52.0.rc1.455.g30608eb744-goog

