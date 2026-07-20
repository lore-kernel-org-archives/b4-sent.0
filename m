From: Phil Rosenthal <phil@phil.gs>
Date: Mon, 20 Jul 2026 13:45:49 -0400
Subject: [PATCH v2] KVM: x86/mmu: Consume the locked rmap value in the
 lockless rmap walk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-rmap-age-elided-submit-v2-1-668973030d47@phil.gs>
X-B4-Tracking: v=1; b=H4sIAMxeXmoC/4WNTQ6CMBBGr0Jm7RhaBCwr72FYtHSASfhpWiQa0
 rtbuYDL95LvfQcE8kwBmuwATzsHXpcE8pJBN+plIGSbGGQuq7wWCv2sHerkaWJLFsPLzLyhult
 jb6UwymhIY+ep5/cZfraJRw7b6j/nzy5+9m9yFyiwM4XsZaHyuiofbuTpOgRoY4xfLgUy5boAA
 AA=
X-Change-ID: 20260719-rmap-age-elided-submit-98dbd451b9ba
To: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>
Cc: James Houghton <jthoughton@google.com>, kvm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Phil Rosenthal <phil@phil.gs>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784569549; l=7579;
 i=phil@phil.gs; s=20260718; h=from:subject:message-id;
 bh=/DA9tDq9OdWhqkYOywLOluO9+lZI4ZToBh2OckB84pY=;
 b=hRcIzQMiu5aaCHxtzdbymoaumM258UybCmTqfSMvvX4oSitF/3/LY2RB3ChI36siYtdrrApc5
 hTNTywkOCnHDYl42Whf1wg6Hiv+mwZZKH98cN3sTrXHEB+yQlqn9FRn
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
enters for_each_rmap_spte_lockless().  The iterator started with
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

Fix the class of bug by having the lockless walk consume the value
returned by the lock instead of re-reading the rmap.  Split
rmap_get_first() into __rmap_get_first(), which starts an iterator from
an already-read rmap value, and make for_each_rmap_spte_lockless() take
that value and call __rmap_get_first() directly.
kvm_rmap_age_gfn_range() passes the value returned by
kvm_rmap_lock_readonly(): when the lock was elided the value is zero,
__rmap_get_first() returns NULL, and the walk is skipped.  No lockless
walker re-reads the rmap, so the lock-elision invariant cannot be
violated, and no lock()-without-paired-unlock() path is added to the
aging code.

Fixes: af3b6a9eba48 ("KVM: x86/mmu: Walk rmaps (shadow MMU) without holding mmu_lock when aging gfns")
Suggested-by: Sean Christopherson <seanjc@google.com>
Cc: stable@vger.kernel.org
Signed-off-by: Phil Rosenthal <phil@phil.gs>
---
This bug was identified and confirmed with AI assistance; per
Documentation/process/security-bugs.rst it is reported in the open
rather than via the security list.

Static: the invariant is stated by __kvm_rmap_lock(); after this change
the lockless walk consumes the value returned by the lock, so no
lockless walker re-reads the rmap.

Runtime: I validated this exact change on a KASAN build
(CONFIG_KASAN_GENERIC=y, CONFIG_KVM_MMU_LOCKLESS_AGING=y, kvm.tdp_mmu=0,
kvm_intel.ept=0 so shared pages build multi-SPTE pte_list_desc rmaps),
using the same test-only race amplifier as v1: it widens the
zero->populated window and schedules the real lockless aging function
onto recently recycled gfns; alloc and free are unmodified production
paths.  With this change reverted, so that the lockless walk re-reads the
rmap as in the unfixed code, KASAN reports the same slab-use-after-free
in kvm_rmap_age_gfn_range described in v1's report (three distinct tasks:
read/alloc/free).  With this patch applied under the same injection load,
the same empty->populated race windows are still observed, including
KVM_RMAP_MANY descriptor chains that would otherwise expose the UAF, but
the walk is skipped and no KASAN report is produced; a positive control
(natural aging via memcg reclaim) continues to age populated rmaps.  The
test-only instrumentation is available privately on request.
---
Changes in v2:
- Implement the class-wide fix Sean suggested instead of v1's explicit
  "if (!rmap_val) continue;" skip -- the alternative already noted in v1.
  Thread the value returned by kvm_rmap_lock_readonly() into the iterator
  (split rmap_get_first() into __rmap_get_first(), make
  for_each_rmap_spte_lockless() consume the locked value) so no lockless
  walker re-reads the rmap, and avoid adding another
  lock()-without-paired-unlock() path.  The fixed runtime behavior is
  unchanged from v1: an elided (zero) lock still skips the walk, now
  structurally because __rmap_get_first() returns NULL rather than an
  explicit early continue.
- Applies cleanly to current kvm/master and to 6.18.y.
- Link to v1: https://lore.kernel.org/r/20260719-rmap-age-elided-submit-v1-1-cb32f2390765@phil.gs
---
 arch/x86/kvm/mmu/mmu.c | 33 +++++++++++++++++++--------------
 1 file changed, 19 insertions(+), 14 deletions(-)

diff --git a/arch/x86/kvm/mmu/mmu.c b/arch/x86/kvm/mmu/mmu.c
index 234d0a95abf534193e8285e61dfb7e0c56ba19ad..42de1f718cfb12f3f9e46e35834183741a35d7e6 100644
--- a/arch/x86/kvm/mmu/mmu.c
+++ b/arch/x86/kvm/mmu/mmu.c
@@ -1225,18 +1225,9 @@ struct rmap_iterator {
 	int pos;			/* index of the sptep */
 };
 
-/*
- * Iteration must be started by this function.  This should also be used after
- * removing/dropping sptes from the rmap link because in such cases the
- * information in the iterator may not be valid.
- *
- * Returns sptep if found, NULL otherwise.
- */
-static u64 *rmap_get_first(struct kvm_rmap_head *rmap_head,
-			   struct rmap_iterator *iter)
+static u64 *__rmap_get_first(unsigned long rmap_val,
+			     struct rmap_iterator *iter)
 {
-	unsigned long rmap_val = kvm_rmap_get(rmap_head);
-
 	if (!rmap_val)
 		return NULL;
 
@@ -1250,6 +1241,19 @@ static u64 *rmap_get_first(struct kvm_rmap_head *rmap_head,
 	return iter->desc->sptes[iter->pos];
 }
 
+/*
+ * Iteration must be started by this function.  This should also be used after
+ * removing/dropping sptes from the rmap link because in such cases the
+ * information in the iterator may not be valid.
+ *
+ * Returns sptep if found, NULL otherwise.
+ */
+static u64 *rmap_get_first(struct kvm_rmap_head *rmap_head,
+			   struct rmap_iterator *iter)
+{
+	return __rmap_get_first(kvm_rmap_get(rmap_head), iter);
+}
+
 /*
  * Must be used with a valid iterator: e.g. after rmap_get_first().
  *
@@ -1284,8 +1288,9 @@ static u64 *rmap_get_next(struct rmap_iterator *iter)
 	__for_each_rmap_spte(_rmap_head_, _iter_, _sptep_)			\
 		if (!WARN_ON_ONCE(!is_shadow_present_pte(*(_sptep_))))	\
 
-#define for_each_rmap_spte_lockless(_rmap_head_, _iter_, _sptep_, _spte_)	\
-	__for_each_rmap_spte(_rmap_head_, _iter_, _sptep_)			\
+#define for_each_rmap_spte_lockless(_rmap_val_, _iter_, _sptep_, _spte_)	\
+	for (_sptep_ = __rmap_get_first(_rmap_val_, _iter_);			\
+	     _sptep_; _sptep_ = rmap_get_next(_iter_))				\
 		if (is_shadow_present_pte(_spte_ = mmu_spte_get_lockless(sptep)))
 
 static void drop_spte(struct kvm *kvm, u64 *sptep)
@@ -1723,7 +1728,7 @@ static bool kvm_rmap_age_gfn_range(struct kvm *kvm,
 			rmap_head = gfn_to_rmap(gfn, level, range->slot);
 			rmap_val = kvm_rmap_lock_readonly(rmap_head);
 
-			for_each_rmap_spte_lockless(rmap_head, &iter, sptep, spte) {
+			for_each_rmap_spte_lockless(rmap_val, &iter, sptep, spte) {
 				if (!is_accessed_spte(spte))
 					continue;
 

---
base-commit: 25f744ffa0c8e799e06250ce2e618367b166b0d4
change-id: 20260719-rmap-age-elided-submit-98dbd451b9ba

Best regards,
-- 
Phil Rosenthal <phil@phil.gs>

