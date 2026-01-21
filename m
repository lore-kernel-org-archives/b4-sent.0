From: Per Larsen <perlarsen@google.com>
Subject: [PATCH v5 0/2] KVM: arm64: Support FF-A direct messaging
 interfaces
Date: Wed, 21 Jan 2026 08:27:11 +0000
Message-Id: <20260121-host-direct-messages-v5-0-2c1614c94e80@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOCNcGkC/43PwWrDMAwG4FcpPs9Dku042WnvMXpIbTkxrHWxg
 1kpefc5ZWOMrrDjL9D3S1dROEcu4mV3FZlrLDGdWjBPO+Hm8TSxjL5lQUAGgQY5p7JIHzO7RR6
 5lHHiIg0BehuMGQ9etNVz5hA/buzbvuU5liXly62l4jb9AhX8DVaUIHWn2NjeouvD65TS9M7PL
 h3FJlb6j0JNGQJZx0F1VsGdon4UxAfPVdUUZ7UHPWh9oO5O0d9KBwiPFL3dYvyoidBj/1tZ1/U
 TYrxToYsBAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768984038; l=2274;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=cQzCdOlysfcwSAXig6FKFPi8qbVKzsFXGYR1TM3D2sM=;
 b=tbWIPz2+0mSpsec3Xa3QoVglkBclxYCItvNgsUk21mpl9u7YjOgTnHoVxhKwd+Rz1XkEVsTsA
 3tEGoyXf7EwCFP5X0SfvcVeTrifAgIygwdr8/RQgY1zrcCx1dWrnp4i
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
Changes in v5:
- 1/2: do_ffa_direct_msg: validate that sender is HOST_FFA_ID.
- Link to v4: https://lore.kernel.org/r/20260109-host-direct-messages-v4-0-95da4221d186@google.com

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

 arch/arm64/kvm/hyp/nvhe/ffa.c | 39 ++++++++++++++++++++++++++++++++++++++-
 1 file changed, 38 insertions(+), 1 deletion(-)
---
base-commit: 6c790212c588fddeb0d852f2790840753bb604b1
change-id: 20251029-host-direct-messages-5201d7f55abd

Best regards,
-- 
Per Larsen <perlarsen@google.com>

