From: Per Larsen <perlarsen@google.com>
Date: Thu, 19 Jun 2025 09:02:58 +0000
Subject: [PATCH v5 5/6] KVM: arm64: Bump the supported version of FF-A to
 1.2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250619-virtio-msg-ffa-v5-5-412c98558807@google.com>
References: <20250619-virtio-msg-ffa-v5-0-412c98558807@google.com>
In-Reply-To: <20250619-virtio-msg-ffa-v5-0-412c98558807@google.com>
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oliver.upton@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@arm.com>
Cc: linux-arm-kernel@lists.infradead.org, kvmarm@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Ayrton Munoz <ayrton@google.com>, 
 Per Larsen <perlarsen@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750323807; l=2922;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=FWsM9cwpDtQRn26k1vqArnhcGBTBM4Gr3l2A+zKhWqA=;
 b=xKbIaeh0Ao2PAFj3bfDz6jesWsBv+WwmJNQ732uSf7QXPWRDCk6XboOcFJb6704n1VDjaO3c8
 Qwou+1cKSBlCvSH2UVdzBY81BmeQyBfH1/dzYLEa6zJp43/mG+8b2GX
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FF-A version 1.2 introduces the DIRECT_REQ2 ABI. Bump the FF-A version
preferred by the hypervisor as a precursor to implementing the 1.2-only
FFA_MSG_SEND_DIRECT_REQ2 and FFA_MSG_SEND_RESP2 messaging interfaces.

We must also use SMCCC 1.2 for 64-bit SMCs if hypervisor negotiated FF-A
1.2, so ffa_set_retval is updated and a new function to call 64-bit smcs
using SMCCC 1.2 with fallback to SMCCC 1.1 is introduced.

Update ffa_call_supported to mark FF-A 1.2 interfaces as unsupported
lest they get forwarded.

Co-developed-by: Ayrton Munoz <ayrton@google.com>
Signed-off-by: Ayrton Munoz <ayrton@google.com>
Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 14 ++++++++++----
 include/linux/arm_ffa.h       |  1 +
 2 files changed, 11 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 6965aa947fb4529c35872ee3976ab8d0b02becca..7b43279aded7d7ef4cce2c294d208c5a66b684e3 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -677,6 +677,12 @@ static bool ffa_call_supported(u64 func_id)
 	case FFA_NOTIFICATION_SET:
 	case FFA_NOTIFICATION_GET:
 	case FFA_NOTIFICATION_INFO_GET:
+	/* Unimplemented interfaces added in FF-A 1.2 */
+	case FFA_MSG_SEND_DIRECT_REQ2:
+	case FFA_MSG_SEND_DIRECT_RESP2:
+	case FFA_CONSOLE_LOG:
+	case FFA_PARTITION_INFO_GET_REGS:
+	case FFA_EL3_INTR_HANDLE:
 		return false;
 	}
 
@@ -734,7 +740,7 @@ static int hyp_ffa_post_init(void)
 	if (regs.a0 != FFA_SUCCESS)
 		return -EOPNOTSUPP;
 
-	switch (regs.a2) {
+	switch (regs.a2 & FFA_FEAT_RXTX_MIN_SZ_MASK) {
 	case FFA_FEAT_RXTX_MIN_SZ_4K:
 		min_rxtx_sz = SZ_4K;
 		break;
@@ -933,7 +939,7 @@ int hyp_ffa_init(void *pages)
 
 	regs = (struct arm_smccc_1_2_regs) {
 		.a0 = FFA_VERSION,
-		.a1 = FFA_VERSION_1_1,
+		.a1 = FFA_VERSION_1_2,
 	};
 	arm_smccc_1_2_smc(&regs, &regs);
 	if (regs.a0 == FFA_RET_NOT_SUPPORTED)
@@ -955,10 +961,10 @@ int hyp_ffa_init(void *pages)
 	if (FFA_MAJOR_VERSION(regs.a0) != 1)
 		return -EOPNOTSUPP;
 
-	if (FFA_MINOR_VERSION(regs.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_1))
+	if (FFA_MINOR_VERSION(regs.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_2))
 		hyp_ffa_version = regs.a0;
 	else
-		hyp_ffa_version = FFA_VERSION_1_1;
+		hyp_ffa_version = FFA_VERSION_1_2;
 
 	tx = pages;
 	pages += KVM_FFA_MBOX_NR_PAGES * PAGE_SIZE;
diff --git a/include/linux/arm_ffa.h b/include/linux/arm_ffa.h
index 5bded24dc24fea8cdcbe42bf79c7c025c3fa5f4b..c0dd6183d956043192114a522b7eef465e7078ac 100644
--- a/include/linux/arm_ffa.h
+++ b/include/linux/arm_ffa.h
@@ -128,6 +128,7 @@
 #define FFA_FEAT_RXTX_MIN_SZ_4K		0
 #define FFA_FEAT_RXTX_MIN_SZ_64K	1
 #define FFA_FEAT_RXTX_MIN_SZ_16K	2
+#define FFA_FEAT_RXTX_MIN_SZ_MASK	3
 
 /* FFA Bus/Device/Driver related */
 struct ffa_device {

-- 
2.50.0.rc2.701.gf1e915cc24-goog

