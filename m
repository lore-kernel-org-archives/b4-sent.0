From: Per Larsen <perlarsen@google.com>
Date: Thu, 30 Oct 2025 12:29:39 +0000
Subject: [PATCH 1/2] KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ in host
 handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251030-host-direct-messages-v1-1-463e57871c8f@google.com>
References: <20251030-host-direct-messages-v1-0-463e57871c8f@google.com>
In-Reply-To: <20251030-host-direct-messages-v1-0-463e57871c8f@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Yeoreum Yun <yeoreum.yun@arm.com>, Ben Horgan <ben.horgan@arm.com>
Cc: Armelle Laine <armellel@google.com>, 
 Sebastien Ene <sebastianene@google.com>, 
 linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761827390; l=1511;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=BppMAkhVkyzCH/xZJ6azsBbY51/loFYz2Cn3TqCanQA=;
 b=AI5KD/hIn/k7xCivnA6GNaEoDO7W4H6pgzXhONdZ2MNgVT/57rQhIb/m43ttB8XKzxYgDa7iC
 WZU6vWuApYfCKlaHl+bg35iFoBh0WB3ipZm5MeYLxpBSmgEZkY6xfPN
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sebastian Ene <sebastianene@google.com>

Allow direct messages to be forwarded from the host.

Signed-off-by: Sebastian Ene <sebastianene@google.com>
Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 4e16f9b96f637599873b16148c6e40cf1210aa3e..191dcb301cca3986758fb6a49f15f1799de9f1d1 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -857,6 +857,15 @@ static void do_ffa_part_get(struct arm_smccc_1_2_regs *res,
 	hyp_spin_unlock(&host_buffers.lock);
 }
 
+static void do_ffa_direct_msg(struct arm_smccc_1_2_regs *res,
+			      struct kvm_cpu_context *ctxt,
+			      u64 vm_handle)
+{
+	struct arm_smccc_1_2_regs *args = (void *)&ctxt->regs.regs[0];
+
+	arm_smccc_1_2_smc(args, res);
+}
+
 bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 {
 	struct arm_smccc_1_2_regs res;
@@ -915,6 +924,13 @@ bool kvm_host_ffa_handler(struct kvm_cpu_context *host_ctxt, u32 func_id)
 	case FFA_PARTITION_INFO_GET:
 		do_ffa_part_get(&res, host_ctxt);
 		goto out_handled;
+	case FFA_ID_GET:
+		ffa_to_smccc_res_prop(&res, FFA_RET_SUCCESS, HOST_FFA_ID);
+		goto out_handled;
+	case FFA_MSG_SEND_DIRECT_REQ:
+	case FFA_FN64_MSG_SEND_DIRECT_REQ:
+		do_ffa_direct_msg(&res, host_ctxt, HOST_FFA_ID);
+		goto out_handled;
 	}
 
 	if (ffa_call_supported(func_id))

-- 
2.51.1.851.g4ebd6896fd-goog

