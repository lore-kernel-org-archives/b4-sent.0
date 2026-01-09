From: Per Larsen <perlarsen@google.com>
Subject: [PATCH v4 0/2] KVM: arm64: Support FF-A direct messaging
 interfaces
Date: Fri, 09 Jan 2026 22:34:24 +0000
Message-Id: <20260109-host-direct-messages-v4-0-95da4221d186@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHCCYWkC/43PSwrCMBCA4auUrI3k2bSuvIe4aJNJG7CNJCUop
 Xc3LYKICi7/gfmGmVGE4CCiQzGjAMlF58ccYlcg3TdjB9iZ3IgRJilhNe59nLBxAfSEB4ix6SB
 iyQg1ykrZtAbl1WsA624bezrn7l2cfLhvVxJdp0+Qk+9gophgUXKQqlJUV/bYed9dYK/9gFYxs
 X8UlpXaMqXB8lJx8qHwl0Lpj+cSz4pWwhBRC9Gy8k1ZluUB9++Vt0UBAAA=
X-Change-ID: 20251029-host-direct-messages-5201d7f55abd
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767998072; l=2128;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=uANFCEmcX63XWgQM35Dj9Sq/pNBgm6UWZiRuDN/bYHk=;
 b=aF5ssKxPqGYzDwYPs8/gWzPT7cTJyRm20BTQzTtIOoTQd/xoO6zxYErntLB+vTzD6UWo39jzZ
 dKqyl3XVnZ3BHNqSquFeV8afUAqccCekAcLicvAKDugexTc/BgVe7lg
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support FFA_MSG_SEND_DIRECT_REQ unconditionally.
Support FFA_MSG_SEND_DIRECT_REQ2 if hypervisor negotiated version 1.2+.

Framework messages (FF-A control plane) are filtered out. For
FFA_MSG_SEND_DIRECT_REQ, we look at flags in w2. Messages using the REQ2
interface are always partition messages.

The second patch was part of a previous patch set [0] but was dropped
since the use case was unclear. A clear use case has now appeared: use
TPM device with CRB over FF-A when kernel boots with pkvm [1].

Tested by booting Android under QEMU.

Best Regards,
Per

[0]: https://lore.kernel.org/all/20250730-virtio-msg-ffa-v9-0-7f1b55c8d149@google.com/
[1]: https://lore.kernel.org/all/20251027191729.1704744-1-yeoreum.yun@arm.com/
 

Signed-off-by: Per Larsen <perlarsen@google.com>
---
Changes in v4:
- 1/2: do_ffa_direct_msg: check that flag in w2 is zero; drop unused vm_handle parameter.
- 2/2: ffa_call_supported: simplify logic by reordering cases.
-      do_ffa_direct_msg: switch polarity of check and update comment.
- Link to v3: https://lore.kernel.org/r/20251119-host-direct-messages-v3-0-c74d04944b26@google.com

Changes in v3:
- Filter out framework messages as suggested by Will Deacon. Update cover letter accordingly.
- Update trailers: Reviewed-by: Yeoreum Yun <yeoreum.yun@arm.com>
- Link to v2: https://lore.kernel.org/r/20251030-host-direct-messages-v2-0-9f27cef36730@google.com

Changes in v2:
- 1/2: Drop support for FFA_ID_GET interface in host handler.
- Link to v1: https://lore.kernel.org/r/20251030-host-direct-messages-v1-0-463e57871c8f@google.com

---
Per Larsen (1):
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ2 in host handler

Sebastian Ene (1):
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ in host handler

 arch/arm64/kvm/hyp/nvhe/ffa.c | 33 ++++++++++++++++++++++++++++++++-
 include/linux/arm_ffa.h       |  3 +++
 2 files changed, 35 insertions(+), 1 deletion(-)
---
base-commit: 372800cb95a35a7c40a07e2e0f7de4ce6786d230
change-id: 20251029-host-direct-messages-5201d7f55abd

Best regards,
-- 
Per Larsen <perlarsen@google.com>

