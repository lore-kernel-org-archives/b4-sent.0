From: Phil Rosenthal <phil@phil.gs>
Date: Sun, 19 Jul 2026 16:18:56 -0400
Subject: [PATCH] KVM: x86/mmu: Skip rmap aging when the rmap lock was
 elided
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260719-rmap-age-elided-submit-v1-1-cb32f2390765@phil.gs>
X-B4-Tracking: v=1; b=H4sIAC8xXWoC/x2MSQqAMAwAvyI5G7DiVr8iHloTNeBGqyIU/27xO
 AMzATw7YQ9tEsDxLV72LYJKExhms02MQpEhz/Iqq5VGt5oDTfS8CDGhv+wqJ+qGLBWlstoaiPH
 heJTnH3f9+36uZLuVaAAAAA==
X-Change-ID: 20260719-rmap-age-elided-submit-98dbd451b9ba
To: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>
Cc: James Houghton <jthoughton@google.com>, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Phil Rosenthal <phil@phil.gs>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784492338; l=5986;
 i=phil@phil.gs; s=20260718; h=from:subject:message-id;
 bh=AB9wnwC4hzODsYdAQ8GBVdzTy/ojWza4YJOqutVPhTM=;
 b=lc8sIjUmRodDeHa6Ck/I43b/DlbZqJTFma4cV2NWzloVrBMU6oSwGYrrI2H/hzg6XrhZFv6kj
 FB7sad4p8kBBVknq69pmmBmoM/adaC9QNOtTvLL+hbyIIMoBDLr8QHY
X-Developer-Key: i=phil@phil.gs; a=ed25519;
 pk=08BMg1YPtTS5NnKn5I1Mq1ra3MdAg49Awe6OjrC59fs=
X-Endpoint-Received: by B4 Relay for phil@phil.gs/20260718 with auth_id=881
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

__kvm_rmap_lock() deliberately elides the rmap lock when it observes an
empty rmap.  In that case kvm_rmap_lock_readonly() also re-enables
preemption and returns zero, so the caller holds neither the rmap lock
nor a preemption reference.  The elision documents the invariant it
relies on:

	 * Elide the lock if the rmap is empty, as lockless walkers (read-only
	 * mode) don't need to (and can't) walk an empty rmap, nor can they add
	 * entries to the rmap.  I.e. the only paths that process empty rmaps
	 * do so while holding mmu_lock for write, and are mutually exclusive.

kvm_rmap_age_gfn_range() ignores the returned value and unconditionally
enters for_each_rmap_spte_lockless().  The iterator starts with
rmap_get_first(), which re-reads rmap_head->val rather than using the
value returned by the lock.  If a writer populates the rmap between the
lock's read and the iterator's re-read, the aging path walks the newly
installed rmap without holding its lock.

For a KVM_RMAP_MANY rmap this leaves the walker following a
pte_list_desc chain that it never locked.  A writer holding mmu_lock for
write may free that chain (e.g. kvm_zap_all_rmap_sptes() on the recycle
path, or any rmap zap) via kmem_cache_free() while the walk is in
progress, giving a slab use-after-free.  Nothing serialises the two: the
aging path runs without mmu_lock when CONFIG_KVM_MMU_LOCKLESS_AGING=y,
and the rmap lock that would otherwise exclude the writer was elided.
Because the empty path re-enables preemption, the interval between the
two reads can span an arbitrary scheduling delay.

Skip the walk when locking returned zero, as required by the
lock-elision invariant.  kvm_rmap_unlock_readonly() already treats zero
as requiring no unlock, so the early continue does not leak a lock or a
preemption reference.  Missing an SPTE installed after the empty
observation is harmless because aging is best-effort.

Fixes: af3b6a9eba48 ("KVM: x86/mmu: Walk rmaps (shadow MMU) without holding mmu_lock when aging gfns")
Cc: stable@vger.kernel.org
Signed-off-by: Phil Rosenthal <phil@phil.gs>
---
This bug was identified and confirmed with AI assistance; per
Documentation/process/security-bugs.rst it is therefore reported in the
open rather than via the security list.

The static analysis and runtime evidence are described separately.

Static: the invariant quoted above is stated by __kvm_rmap_lock(), and
kvm_rmap_age_gfn_range() is the one caller that violates it by walking
after an elided (zero) lock.  This holds regardless of any runtime
result.

Runtime: I confirmed the use-after-free is reachable on a KASAN build
(CONFIG_KASAN_GENERIC=y, CONFIG_KVM_MMU_LOCKLESS_AGING=y, kvm.tdp_mmu=0,
kvm_intel.ept=0 so shared pages build multi-SPTE pte_list_desc rmaps).
This is not a natural reproducer: it is a test-only race amplifier.  A
test hook widens two windows (a delay after the zero-lock observation,
and a delay after the iterator has cached iter->desc) and schedules the
real lockless aging function onto recently recycled gfns.  The alloc and
free are unmodified production paths; only the scheduling of the aging
walk and the two delays are injected.  The test-only instrumentation is
available privately on request.  KASAN then reports a
slab-use-after-free, read in the rmap_get_next() step of
for_each_rmap_spte_lockless() (the symbol is
kvm_rmap_age_gfn_range.isra.0 in the instrumented build):

  BUG: KASAN: slab-use-after-free in kvm_rmap_age_gfn_range.isra.0+0x7e4/0xa60 [kvm]
  Read of size 8 at addr ffff88814690c6d8 by task kworker/12:2/81966
  Workqueue: events age_race_workfn [kvm]     <- test hook: lockless aging, no mmu_lock
   kvm_rmap_age_gfn_range.isra.0+0x7e4/0xa60 [kvm]
   age_race_workfn+0x14b/0x1a0 [kvm]
   process_one_work+0x6c8/0x1020
  Allocated by task 94096:
   kmem_cache_alloc_noprof+0x179/0x460
   __kvm_mmu_topup_memory_cache+0x136/0x540 [kvm]
   paging64_page_fault+0x2b6/0x1e70 [kvm]      <- one vCPU faults, allocs the desc
  Freed by task 94095:
   kmem_cache_free+0x11d/0x4a0
   kvm_zap_all_rmap_sptes+0xe9/0x1a0 [kvm]
   __rmap_add+0x2c4/0x5e0 [kvm]
   mmu_set_spte+0x6d6/0x1060 [kvm]
   paging64_page_fault+0x1385/0x1e70 [kvm]     <- another vCPU, under mmu_lock,
                                                  recycles and frees the desc
  The buggy address belongs to the object at ffff88814690c6c0
   which belongs to the cache pte_list_desc of size 128

The three tasks are distinct (read 81966 / alloc 94096 / free 94095),
confirming genuine concurrency rather than a self-inflicted free.  With
the fix applied under the same injection load, the zero -> populated
window is still observed but the walk is skipped and no KASAN report is
produced.

Alternative fix: this patch fixes the only current caller that ignores
an empty return.  A class-wide alternative would pass the value returned
by kvm_rmap_lock_readonly() into the iterator instead of having
rmap_get_first() re-read the rmap, so no lockless walker could
reintroduce the bug.  I chose the smaller change for ease of
backporting, and can send the larger one if preferred.
---
 arch/x86/kvm/mmu/mmu.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index 234d0a95abf534193e8285e61dfb7e0c56ba19ad..e57c4580f58564bbf984364b3563f6b00aee21a9 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -1723,6 +1723,9 @@ static bool kvm_rmap_age_gfn_range(struct kvm *kvm,
 			rmap_head = gfn_to_rmap(gfn, level, range->slot);
 			rmap_val = kvm_rmap_lock_readonly(rmap_head);
 
+			if (!rmap_val)
+				continue;
+
 			for_each_rmap_spte_lockless(rmap_head, &iter, sptep, spte) {
 				if (!is_accessed_spte(spte))
 					continue;

---
base-commit: 25f744ffa0c8e799e06250ce2e618367b166b0d4
change-id: 20260719-rmap-age-elided-submit-98dbd451b9ba

Best regards,
-- 
Phil Rosenthal <phil@phil.gs>

