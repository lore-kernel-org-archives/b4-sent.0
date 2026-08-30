From: Per Larsen <perlarsen@google.com>
Date: Sun, 30 Aug 2026 23:08:13 +0000
Subject: [PATCH v7 1/3] KVM: arm64: Block host-initiated FF-A direct
 responses
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-host-direct-messages-v7-1-45f6e6db72c2@google.com>
References: <20260830-host-direct-messages-v7-0-45f6e6db72c2@google.com>
In-Reply-To: <20260830-host-direct-messages-v7-0-45f6e6db72c2@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788131315; l=1110;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=8AHoa5902lBdwgQQj0S5IoBZHdWqjlLxCvW0VZ4P46k=;
 b=lVUR0IW9heVYxTkTzz63UFlzLz6FnS5mvT3oqFqrWvLIISaAwADTyK2fdfCHeMEb0Dcc0DLSR
 Bm6c5qGAe/fD27T3Z1wSu6KT8UK27gtIO7zVbMh/0xrLlI66QcOW48n
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ffa_call_supported() rejects FFA_MSG_SEND_DIRECT_RESP, but allows
FFA_FN64_MSG_SEND_DIRECT_RESP to be forwarded to firmware.

The host is never the target of an FF-A direct request and therefore
cannot initiate a direct response. Reject both calling conventions.

Suggested-by: Fuad Tabba <tabba@google.com>
Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index a327c2bbb6b6..9e8bb95e8845 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -686,8 +686,10 @@ static bool ffa_call_supported(u64 func_id)
 	case FFA_MSG_SEND:
 	case FFA_MSG_POLL:
 	case FFA_MSG_WAIT:
-	/* 32-bit variants of 64-bit calls */
+	/* The host is never the target of a direct request */
 	case FFA_MSG_SEND_DIRECT_RESP:
+	case FFA_FN64_MSG_SEND_DIRECT_RESP:
+	/* 32-bit variants of 64-bit calls */
 	case FFA_RXTX_MAP:
 	case FFA_MEM_DONATE:
 	case FFA_MEM_RETRIEVE_REQ:

-- 
2.55.0.897.gb25b4bd76c-goog

