From: Per Larsen <perlarsen@google.com>
Subject: [PATCH 0/2] KVM: arm64: Support FF-A direct messaging interfaces
Date: Thu, 30 Oct 2025 12:29:38 +0000
Message-Id: <20251030-host-direct-messages-v1-0-463e57871c8f@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADNaA2kC/x3MQQqAIBBA0avErBtQQaKuEi1Mx5pFGY5EIN09a
 fkW/1cQykwCU1ch083C6WzQfQd+d+dGyKEZjDJWKzPinqRg4Ey+4EEibiNBa5QOQ7TWrQFaemW
 K/PzbeXnfD7oEG9ZmAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761827390; l=1005;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=8lOt5hjMRohwbmB1ls9eEfGExLapiWvkkYYw/nN1DJc=;
 b=SJc2WqLL6M7DVif/tAgJkM8/baVdgfC8ov9MMIpqIYFzZPFOsWgplIQTkOdS2vLv+95zxxAYh
 2taGWk+ftFWCco5JzZEUezmUWPMA5uE16SLfkeGoq5HMLDAN/meb0wr
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
Per Larsen (1):
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ2 in host handler

Sebastian Ene (1):
      KVM: arm64: Support FFA_MSG_SEND_DIRECT_REQ in host handler

 arch/arm64/kvm/hyp/nvhe/ffa.c | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)
---
base-commit: e53642b87a4f4b03a8d7e5f8507fc3cd0c595ea6
change-id: 20251029-host-direct-messages-5201d7f55abd

Best regards,
-- 
Per Larsen <perlarsen@google.com>

