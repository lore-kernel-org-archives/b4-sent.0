From: Per Larsen <perlarsen@google.com>
Subject: [PATCH v7 0/3] KVM: arm64: Support FF-A direct messaging
 interfaces
Date: Sun, 30 Aug 2026 23:08:12 +0000
Message-Id: <20260830-host-direct-messages-v7-0-45f6e6db72c2@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANy3lGoC/43PwWrDMAwG4FcpPs/DkmU72WnvMXZIbTkxrHWJQ
 9goefc5ZaMbWWDHX6BP+q+i8Ji4iKfDVYw8p5LyuQb3cBB+6M49yxRqFqjQgMJWDrlMMqSR/SR
 PXErXc5EGFQQXjemOQdTVy8gxvd/Yl9eah1SmPH7crsywTr9Arf4GZ5BKktVsXOPAN/G5z7l/4
 0efT2IVZ/yPglVpIzrPUVun1UbRdwVgp9ysq+IdBUUt0RHtRqFvxSpQewqtv5jQESIEaLaK+aE
 g7CimKujBAvmWuNk2snfFqD3FVkVH6qJDx6Exv5RlWT4Be75FAhcCAAA=
X-Change-ID: 20251029-host-direct-messages-5201d7f55abd
To: Marc Zyngier <maz@kernel.org>, Joey Gouly <joey.gouly@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Yeoreum Yun <yeoreum.yun@arm.com>, Ben Horgan <ben.horgan@arm.com>, 
 Oliver Upton <oupton@kernel.org>
Cc: Sebastien Ene <sebastianene@google.com>, 
 linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Per Larsen <perlarsen@google.com>, 
 Fuad Tabba <fuad.tabba@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788131315; l=3303;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=l87EwSkD1CEn4+bfwgv4gal/kTthTgQXI2kg63rlZWc=;
 b=4SU4ydR/4qW466dgQe0E/kB7YR/oY/pH7E6YpEreh01jPVRt6qHZCHbII/Fta98o+wdMra1sK
 Uyh2G9hx720CsqhyEWBEwXwGdG+h0nH/Y+kMUUzNml5CjdMutvfBenz
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Block host-initiated FF-A direct responses.
Support FFA_MSG_SEND_DIRECT_REQ unconditionally.
Support FFA_MSG_SEND_DIRECT_REQ2 if hypervisor negotiated version 1.2+.

Framework messages (FF-A control plane) are filtered out. For
FFA_MSG_SEND_DIRECT_REQ, we look at flags in w2. Messages using the REQ2
interface are always partition messages.

The third patch was part of a previous patch set [0] but was dropped
since the use case was unclear. A clear use case has now appeared: use
TPM device with CRB over FF-A when kernel boots with pkvm [1].

Tested by booting Android under QEMU.

Best Regards,
Per

[0]: https://lore.kernel.org/all/20250730-virtio-msg-ffa-v9-0-7f1b55c8d149@google.com/
[1]: https://lore.kernel.org/all/20251027191729.1704744-1-yeoreum.yun@arm.com/

Signed-off-by: Per Larsen <perlarsen@google.com>
---
Changes in v7:
- New patch 1/3: block FFA_FN64_MSG_SEND_DIRECT_RESP. Only the 32-bit
  variant was denied, so the host could send unvalidated 64-bit direct
  responses to EL3, including a forged sender endpoint ID
- Use hyp_smccc_1_2_smc() so the call is bracketed by hyp_exit/hyp_enter;
  the pass-through path already traced these calls
- Declare endp/flags as u64 and reject a non-zero x1[63:32]: these are
  w1/w2, but the raw 64-bit registers are forwarded to EL3
- Pass the canonicalised func_id to do_ffa_direct_msg() rather than
  re-reading x0, which still carries ARM_SMCCC_CALL_HINTS
- Link to v6: https://lore.kernel.org/r/20260501-host-direct-messages-v6-0-3f4af727ed85@google.com

Changes in v6:
- 1/2: validate that bits 31:16 of w1 is HOST_FFA_ID.
- Link to v5: https://lore.kernel.org/r/20260121-host-direct-messages-v5-0-2c1614c94e80@google.com

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
Per Larsen (2):
      KVM: arm64: Block host-initiated FF-A direct responses
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ2 in host handler

Sebastian Ene (1):
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ in host handler

 arch/arm64/kvm/hyp/nvhe/ffa.c | 44 +++++++++++++++++++++++++++++++++++++++++--
 include/linux/arm_ffa.h       |  2 ++
 2 files changed, 44 insertions(+), 2 deletions(-)
---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20251029-host-direct-messages-5201d7f55abd

Best regards,
-- 
Per Larsen <perlarsen@google.com>

