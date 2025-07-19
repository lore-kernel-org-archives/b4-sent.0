From: Per Larsen <perlarsen@google.com>
Date: Sat, 19 Jul 2025 02:11:26 +0000
Subject: [PATCH v8 4/7] KVM: arm64: Mark optional FF-A 1.2 interfaces as
 unsupported
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250719-virtio-msg-ffa-v8-4-03e8e8dbe856@google.com>
References: <20250719-virtio-msg-ffa-v8-0-03e8e8dbe856@google.com>
In-Reply-To: <20250719-virtio-msg-ffa-v8-0-03e8e8dbe856@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, ahomescu@google.com, armellel@google.com, 
 arve@android.com, ayrton@google.com, qperret@google.com, 
 sebastianene@google.com, qwandor@google.com, 
 Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752891112; l=1289;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=dgBVrMdjAZFSIYAnESFiV+uLEGMo1SRSm+p8aDNjGJQ=;
 b=IMDnhHhg0FoazYMmOZA5MqsjVPfiAVVoRRaOwqYguuaRhtoI9suue0RLYVCELMYFA2XwFnrmW
 SiPndnyo+0qDWbM6/aUAyJ88rBrYneqLwdQgpn7XWKjl1F0F3qQYkKZ
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Update ffa_call_supported to mark FF-A 1.2 interfaces as unsupported
lest they get forwarded. FFA_MSG_SEND_DIRECT_REQ2 is not marked as
unsupported because a later patch in this series adds support.

Also mark FFA_EL3_INTR_HANDLE as unsupported as it is only valid for
physical instances.

Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 50ec52bcce4b4443c2f3ffeda455594733f3a5a0..5a173ea481940236356e2bc4248d094a858a0923 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -671,6 +671,12 @@ static bool ffa_call_supported(u64 func_id)
 	case FFA_NOTIFICATION_SET:
 	case FFA_NOTIFICATION_GET:
 	case FFA_NOTIFICATION_INFO_GET:
+	/* Optional interfaces added in FF-A 1.2 */
+	case FFA_MSG_SEND_DIRECT_RESP2:		/* Optional per 7.5.1 */
+	case FFA_CONSOLE_LOG:			/* Optional per 13.1: not in Table 13.1 */
+	case FFA_PARTITION_INFO_GET_REGS:	/* Optional for virtual instances per 13.1 */
+	/* Unsupported interfaces added in FF-A 1.2 */
+	case FFA_EL3_INTR_HANDLE:		/* Only valid for secure physical instances */
 		return false;
 	}
 

-- 
2.50.0.727.gbf7dc18ff4-goog

