From: Per Larsen <perlarsen@google.com>
Date: Sat, 19 Jul 2025 02:11:28 +0000
Subject: [PATCH v8 6/7] KVM: arm64: Bump the supported version of FF-A to
 1.2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250719-virtio-msg-ffa-v8-6-03e8e8dbe856@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1752891112; l=1443;
 i=perlarsen@google.com; s=20250508; h=from:subject:message-id;
 bh=txfowO+ukMF1cKRkbyV9oZR3idRq8KAQfVviP632O2Y=;
 b=NmwH2Kl37jGkp56jhbSbjWyVhPM0UcN4v1fv/oFMEnt32iE+WCcBK521NsQkGB53tMdYwe3+b
 NYM1hXaTEcXBUsHjEqgsfXeqjbpo/+wdUCh2HaU7CK5szV0s45uKG7y
X-Developer-Key: i=perlarsen@google.com; a=ed25519;
 pk=jjc/Ta4VmrLRmMoahP6d1mBcKzvWU+nsmdtYe2oS2kQ=
X-Endpoint-Received: by B4 Relay for perlarsen@google.com/20250508 with auth_id=402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

FF-A version 1.2 introduces the DIRECT_REQ2 ABI. Bump the FF-A version
preferred by the hypervisor as a precursor to implementing the 1.2-only
FFA_MSG_SEND_DIRECT_REQ2 and FFA_MSG_SEND_RESP2 messaging interfaces.

Co-developed-by: Ayrton Munoz <ayrton@google.com>
Signed-off-by: Ayrton Munoz <ayrton@google.com>
Signed-off-by: Per Larsen <perlarsen@google.com>
---
 arch/arm64/kvm/hyp/nvhe/ffa.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/arch/arm64/kvm/hyp/nvhe/ffa.c b/arch/arm64/kvm/hyp/nvhe/ffa.c
index 2cbecc9af5d27a9e7c8497001cf9b0987c72bdb4..f6d964df53c3e21ba85984f35cc7b6859012d1b0 100644
--- a/arch/arm64/kvm/hyp/nvhe/ffa.c
+++ b/arch/arm64/kvm/hyp/nvhe/ffa.c
@@ -930,7 +930,7 @@ int hyp_ffa_init(void *pages)
 
 	arm_smccc_1_2_smc(&(struct arm_smccc_1_2_regs) {
 		.a0 = FFA_VERSION,
-		.a1 = FFA_VERSION_1_1,
+		.a1 = FFA_VERSION_1_2,
 	}, &res);
 	if (res.a0 == FFA_RET_NOT_SUPPORTED)
 		return 0;
@@ -951,10 +951,10 @@ int hyp_ffa_init(void *pages)
 	if (FFA_MAJOR_VERSION(res.a0) != 1)
 		return -EOPNOTSUPP;
 
-	if (FFA_MINOR_VERSION(res.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_1))
+	if (FFA_MINOR_VERSION(res.a0) < FFA_MINOR_VERSION(FFA_VERSION_1_2))
 		hyp_ffa_version = res.a0;
 	else
-		hyp_ffa_version = FFA_VERSION_1_1;
+		hyp_ffa_version = FFA_VERSION_1_2;
 
 	tx = pages;
 	pages += KVM_FFA_MBOX_NR_PAGES * PAGE_SIZE;

-- 
2.50.0.727.gbf7dc18ff4-goog

