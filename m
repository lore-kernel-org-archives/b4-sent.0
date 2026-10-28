From: Xuheng Li <xuheng@cs.columbia.edu>
Date: Wed, 28 Oct 2026 23:02:10 +0000
Subject: [PATCH] KVM: arm64: Add an ISB after mapping a hyp fixmap slot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-fixmap-isb-v1-1-6c9f0f9cb810@cs.columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyML3bTMitzEAt3M4iTd5GTLFHMz01Rj86RkJaCGgqJUoCzYsOjY2lo
 AeJvqclwAAAA=
X-Change-ID: 20261028-fixmap-isb-cc9d765e37bc
To: Marc Zyngier <maz@kernel.org>, Oliver Upton <oupton@kernel.org>
Cc: Quentin Perret <qperret@google.com>, Will Deacon <will@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, 
 Mark Rutland <mark.rutland@arm.com>, Fuad Tabba <fuad.tabba@linux.dev>, 
 Joey Gouly <joey.gouly@arm.com>, Steffen Eiden <seiden@linux.ibm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, kvmarm@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Xuheng Li <xuheng@cs.columbia.edu>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793228530; l=1807;
 i=xuheng@cs.columbia.edu; s=20261028; h=from:subject:message-id;
 bh=MRI3I7XYX2g8m/5nRZspzMo8wXyH7lpxeGQhbbi2qGg=;
 b=QsMY43bA+fBdaVPVPnbfW9T26X1m6bDnOE7uREQ34isPF0d5YMF7mQSstVSg6VOotubIGaW9A
 r5yGUIqIiLpB2fu5VZSh8xzoazibgmP2GJdt7mXdoCFHaXbfoEdnjGO
X-Developer-Key: i=xuheng@cs.columbia.edu; a=ed25519;
 pk=L1HVV+goqxYmEMO/OXakL6uf9isSpgk2QrLlFqyZ2Qs=
X-Endpoint-Received: by B4 Relay for xuheng@cs.columbia.edu/20261028 with auth_id=1349
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

fixmap_map_slot() installs a valid PTE for the CPU's fixmap slot (or
the fixblock slot) and issues a DSB ISHST before returning the slot's
VA, which the caller then accesses.  It does not issue an ISB.

The DSB guarantees that the PTE write has completed, but without a
context synchronization event the architecture does not guarantee that
a later access on the same CPU uses the new entry: its translation may
have been performed speculatively while the slot was still invalid, in
which case the access takes a translation fault.  At EL2 that fault
ends in hyp_panic().  The clear side, fixmap_clear_slot(), already ends
with an ISB.

A litmus test of the same shape (map the slot, DSB ISHST, load through
it) faulted on a Cortex-A72 in 2 out of 100M runs.  Arm's herd7 model
with -variant vmsa also allows the fault, and forbids it once the ISB
is added.

Add the missing ISB.  This covers both hyp_fixmap_map() and
hyp_fixblock_map(), which share fixmap_map_slot().

Fixes: aa6948f82f0b ("KVM: arm64: Add per-cpu fixmap infrastructure at EL2")
Cc: stable@vger.kernel.org
Signed-off-by: Xuheng Li <xuheng@cs.columbia.edu>
---
 arch/arm64/kvm/hyp/nvhe/mm.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/kvm/hyp/nvhe/mm.c b/arch/arm64/kvm/hyp/nvhe/mm.c
index b95d98cfe..83b74c522 100644
--- a/arch/arm64/kvm/hyp/nvhe/mm.c
+++ b/arch/arm64/kvm/hyp/nvhe/mm.c
@@ -316,6 +316,7 @@ static void *fixmap_map_slot(struct hyp_fixmap_slot *slot, phys_addr_t phys)
 	pte |= kvm_phys_to_pte(phys) | KVM_PTE_VALID;
 	WRITE_ONCE(*ptep, pte);
 	dsb(ishst);
+	isb();
 
 	return (void *)slot->addr;
 }

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261028-fixmap-isb-cc9d765e37bc

Best regards,
-- 
Xuheng Li <xuheng@cs.columbia.edu>

