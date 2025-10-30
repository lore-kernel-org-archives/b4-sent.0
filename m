From: Per Larsen <perlarsen@google.com>
Subject: [PATCH v2 0/2] KVM: arm64: Support FF-A direct messaging
 interfaces
Date: Thu, 30 Oct 2025 15:49:15 +0000
Message-Id: <20251030-host-direct-messages-v2-0-9f27cef36730@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPuIA2kC/22NQQ6CMBBFr0Jm7Zi2WEFX3sOwwHYokwglHUI0h
 LtbiUuX7yX//RWEEpPAtVgh0cLCccxgDgW4vh0DIfvMYJSxWpkL9lFm9JzIzTiQSBtI0BqlfdV
 Z2z485OmUqOPXnr03mXuWOab3/rLor/0FS/U/uGhUeDqXZKu60q7ubiHG8KSjiwM027Z9AFX+C
 wa5AAAA
X-Change-ID: 20251029-host-direct-messages-5201d7f55abd
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761839364; l=1188;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=8s1gw4zxVz4gFDdlU/JyqSmtBI+GywyPiSCpoHCeD+A=;
 b=9LSJoD3lZA0ogsX7LA0xU+vNMbRxY6n7pTFWh3e/JFxXdDlXTr4KtfUhi61CMD8w5FrWi1l4E
 vmPTjkBVwR0B0wYyH1/mV+O0LauiIy68LWToplSP+/9mmOsGl6fa4Jk
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Support FFA_MSG_SEND_DIRECT_REQ unconditionally.
Support FFA_MSG_SEND_DIRECT_REQ2 if hypervisor negotiated version 1.2+.

The second patch was part of a previous patch set [0] but was dropped
since the use case was unclear. A clear use case has now appeared [1].

Tested by booting Android under QEMU.

Best Regards,
Per

[0]: https://lore.kernel.org/all/20250730-virtio-msg-ffa-v9-0-7f1b55c8d149@google.com/
[1]: https://lore.kernel.org/all/20251027191729.1704744-1-yeoreum.yun@arm.com/
 

Signed-off-by: Per Larsen <perlarsen@google.com>
---
Changes in v2:
- 1/2: Drop support for FFA_ID_GET interface in host handler.
- Link to v1: https://lore.kernel.org/r/20251030-host-direct-messages-v1-0-463e57871c8f@google.com

---
Per Larsen (1):
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ2 in host handler

Sebastian Ene (1):
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ in host handler

 arch/arm64/kvm/hyp/nvhe/ffa.c | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)
---
base-commit: e53642b87a4f4b03a8d7e5f8507fc3cd0c595ea6
change-id: 20251029-host-direct-messages-5201d7f55abd

Best regards,
-- 
Per Larsen <perlarsen@google.com>

