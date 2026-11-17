From: Junho Cha <junho.cha@xcena.com>
Date: Tue, 17 Nov 2026 18:26:55 +0900
Subject: [PATCH] mm/migrate: drop the fault lock and wait killably for
 migration entries
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-junhomax-fix-mm-migrate-killable-v1-1-f6e7b135a159@xcena.com>
X-B4-Tracking: v=1; b=H4sIAN4d/GoC/yWNQQrCMBBFr1Jm7aCJoOJVxMUkTpupTSqTthRK7
 26iy/d5vL9BZhXOcG82UF4ky5gKmEMDPlDqGOVVGOzJXowxV+znFMZIK7ayYowYpVOaGN8yDOQ
 GRuP92bT25ryzUDIf5aL+Lh7PP+fZ9eyn2q2Go8zolJIPdRpVOknHSHlihX3/AmhJrA2kAAAA
X-Change-ID: 20261117-junhomax-fix-mm-migrate-killable-1cc31f28bcb2
To: Andrew Morton <akpm@linux-foundation.org>
Cc: David Hildenbrand <david@kernel.org>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>, 
 Zi Yan <ziy@nvidia.com>, Alistair Popple <apopple@nvidia.com>, 
 Matthew Brost <matthew.brost@intel.com>, 
 =?utf-8?q?Thomas_Hellstr=C3=B6m?= <thomas.hellstrom@linux.intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Junho Cha <junho.cha@xcena.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794907617; l=13411;
 i=junho.cha@xcena.com; s=20261113; h=from:subject:message-id;
 bh=mnGdUHF5t1lOUgEMiGhJVwTTK36023iX/aOSJF8UJzA=;
 b=VFwGqoZy5y6dUZ9bmlZ9RwakB3fe2c3Ij8SR67QV06QWEAjy0q5cXpEVIWpo5x8WndR5Lc9mn
 FnR+zTWOZtHDK30vWR85alepx8lRScSnV/vsLgOx/EqImk/ermpTPV7
X-Developer-Key: i=junho.cha@xcena.com; a=ed25519;
 pk=OkFm4PnuJSze1AVqDdvnpHO7nnDQIheH2qYwg2a6Dyc=
X-Endpoint-Received: by B4 Relay for junho.cha@xcena.com/20261113 with auth_id=1507
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A fault that finds a migration entry sleeps in
softleaf_entry_wait_on_locked() until the entry goes away.  So does a
fault on a device-private entry whose folio is locked by another
thread, since commit b570f37a2ce4 ("mm: Fix a hmm_range_fault()
livelock / starvation problem").  The wait is in TASK_UNINTERRUPTIBLE
and keeps the mmap_lock or per-VMA lock held throughout.

That is fine while a migration takes microseconds.  It is not when the
migration is slow:

 - The wait cannot be killed.  The signal_pending_state() check in the
   wait loop never fires, because TASK_UNINTERRUPTIBLE contains neither
   TASK_INTERRUPTIBLE nor TASK_WAKEKILL.  For example, if the
   migrate_to_ram() handler of a device-private folio waits for a
   device that has stalled, every other thread that faults on the page
   sits in D state, and the only symptom is a hung task warning.

 - The fault lock is held across the wait.  This matters when the
   migration itself runs without that lock, as for move_pages(),
   compaction or memory offlining.  A writer that arrives in the
   meantime, such as munmap() of another page in the same VMA, waits
   for the migration to finish, and faults that come after the writer
   queue behind it.  migrate_to_ram() is called with the fault lock
   held, so for device-private folios only the first point applies.

Making the wait killable alone is not enough.  A fault that returns 0
is retried, so a kernel-mode fault from a uaccess routine would fault
again on the same entry, return at once because the signal is still
pending, and spin until the migration completes.  The fault has to
return VM_FAULT_RETRY so that fault_signal_pending() can end it.

Handle the fault lock the way __folio_lock_or_retry() does.  Pass the
vm_fault to softleaf_entry_wait_on_locked() from do_swap_page().  On the
first attempt of a retryable fault, drop the fault lock before sleeping
and return VM_FAULT_RETRY, or return at once for
FAULT_FLAG_RETRY_NOWAIT.  A FAULT_FLAG_KILLABLE fault sleeps in
TASK_KILLABLE, and if a fatal signal ends a wait that still holds the
lock, drop it and return VM_FAULT_RETRY.

Dropping the lock there is safe.  The wait entry is queued before the
ptl is released, and the entry can only be removed under that ptl, so
no wake up is missed.  Nothing after that uses the vma, and
folio_waitqueue() points into a global hash table, not into the folio.

Callers outside the fault path (hmm, userfaultfd, huge_memory) and the
PMD and hugetlb waits pass NULL and keep the current behaviour.

Tested by holding the migration entries for 8 seconds, with a delay
added after the unmap step of move_pages() and in test_hmm's
migrate_to_ram():

 - SIGKILL to a process waiting on the entry, from user mode or from a
   write() that copies from the page, ends it within a millisecond
   instead of after the migration.  The same holds for a thread waiting
   on a device-private folio.
 - munmap() of another page in the same VMA no longer waits for the
   migration.
 - Without a signal, the write() completes after the migration with
   the right data, using under a millisecond of system time.
 - hmm-tests results are unchanged, and lockdep reports nothing.

Signed-off-by: Junho Cha <junho.cha@xcena.com>
---
The delays used for testing were added locally after the unmap step of
migrate_pages_batch() for MR_SYSCALL and after migrate_vma_setup() in
dmirror_devmem_fault().  They are not part of this patch.
---
 include/linux/migrate.h |  9 ++++++---
 include/linux/swapops.h |  5 +++++
 mm/filemap.c            | 45 ++++++++++++++++++++++++++++++++++++++++++---
 mm/memory.c             |  6 +++---
 mm/migrate.c            | 46 ++++++++++++++++++++++++++++++++++------------
 5 files changed, 90 insertions(+), 21 deletions(-)

diff --git a/include/linux/migrate.h b/include/linux/migrate.h
index 78424b3824c2..f76998930f12 100644
--- a/include/linux/migrate.h
+++ b/include/linux/migrate.h
@@ -66,8 +66,8 @@ bool isolate_folio_to_list(struct folio *folio, struct list_head *list);
 
 int migrate_huge_page_move_mapping(struct address_space *mapping,
 		struct folio *dst, struct folio *src);
-void softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl)
-		__releases(ptl);
+vm_fault_t softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl,
+					 struct vm_fault *vmf) __releases(ptl);
 void folio_migrate_flags(struct folio *newfolio, struct folio *folio);
 int folio_migrate_mapping(struct address_space *mapping,
 		struct folio *newfolio, struct folio *folio, int extra_count);
@@ -99,12 +99,15 @@ static inline int set_movable_ops(const struct movable_operations *ops, enum pag
 	return -ENOSYS;
 }
 
-static inline void softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl)
+static inline vm_fault_t softleaf_entry_wait_on_locked(softleaf_t entry,
+						       spinlock_t *ptl,
+						       struct vm_fault *vmf)
 	__releases(ptl)
 {
 	WARN_ON_ONCE(1);
 
 	spin_unlock(ptl);
+	return 0;
 }
 
 #endif /* CONFIG_MIGRATION */
diff --git a/include/linux/swapops.h b/include/linux/swapops.h
index 603f9e3f909c..6a647fe5e83b 100644
--- a/include/linux/swapops.h
+++ b/include/linux/swapops.h
@@ -216,6 +216,7 @@ static inline swp_entry_t make_migration_entry_dirty(swp_entry_t entry)
 
 extern void migration_entry_wait(struct mm_struct *mm, pmd_t *pmd,
 					unsigned long address);
+vm_fault_t migration_entry_wait_fault(struct vm_fault *vmf);
 extern void migration_entry_wait_huge(struct vm_area_struct *vma, unsigned long addr, pte_t *pte);
 #else  /* CONFIG_MIGRATION */
 static inline swp_entry_t make_readable_migration_entry(pgoff_t offset)
@@ -235,6 +236,10 @@ static inline swp_entry_t make_writable_migration_entry(pgoff_t offset)
 
 static inline void migration_entry_wait(struct mm_struct *mm, pmd_t *pmd,
 					unsigned long address) { }
+static inline vm_fault_t migration_entry_wait_fault(struct vm_fault *vmf)
+{
+	return 0;
+}
 static inline void migration_entry_wait_huge(struct vm_area_struct *vma,
 					     unsigned long addr, pte_t *pte) { }
 
diff --git a/mm/filemap.c b/mm/filemap.c
index b04be64a5069..d3709b4e96fd 100644
--- a/mm/filemap.c
+++ b/mm/filemap.c
@@ -1399,6 +1399,7 @@ static inline int folio_wait_bit_common(struct folio *folio, int bit_nr,
  * device_private entry to be removed.
  * @entry: migration or device_private swap entry.
  * @ptl: already locked ptl. This function will drop the lock.
+ * @vmf: the fault being handled, or NULL when not called from a fault.
  *
  * Wait for a migration entry referencing the given page, or device_private
  * entry referencing a dvice_private page to be unlocked. This is
@@ -1407,17 +1408,28 @@ static inline int folio_wait_bit_common(struct folio *folio, int bit_nr,
  * should be called while holding the ptl for @entry referencing
  * the page.
  *
+ * When @vmf is given, the fault lock is handled as in __folio_lock_or_retry():
+ * if the fault may be retried, the mmap_lock or per-VMA lock is dropped
+ * before sleeping, and a FAULT_FLAG_KILLABLE fault sleeps killably.
+ *
  * Returns after unlocking the ptl.
  *
+ * Return: VM_FAULT_RETRY if the fault lock has been dropped, or if
+ * FAULT_FLAG_RETRY_NOWAIT asked not to wait; 0 otherwise.
+ *
  * This follows the same logic as folio_wait_bit_common() so see the comments
  * there.
  */
-void softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl)
+vm_fault_t softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl,
+					 struct vm_fault *vmf)
 	__releases(ptl)
 {
 	struct wait_page_queue wait_page;
 	wait_queue_entry_t *wait = &wait_page.wait;
+	unsigned int state = TASK_UNINTERRUPTIBLE;
+	bool interrupted = false;
 	bool thrashing = false;
+	vm_fault_t ret = 0;
 	unsigned long pflags;
 	bool in_thrashing;
 	wait_queue_head_t *q;
@@ -1452,16 +1464,34 @@ void softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl)
 	 */
 	spin_unlock(ptl);
 
+	/*
+	 * The wait entry is queued and the entry can only change under the ptl
+	 * dropped above, so no wake up is lost from here on.  The vma is not
+	 * used below, so the fault lock can be dropped before sleeping.
+	 */
+	if (vmf) {
+		if (fault_flag_allow_retry_first(vmf->flags)) {
+			ret = VM_FAULT_RETRY;
+			if (vmf->flags & FAULT_FLAG_RETRY_NOWAIT)
+				goto out;
+			release_fault_lock(vmf);
+		}
+		if (vmf->flags & FAULT_FLAG_KILLABLE)
+			state = TASK_KILLABLE;
+	}
+
 	for (;;) {
 		unsigned int flags;
 
-		set_current_state(TASK_UNINTERRUPTIBLE);
+		set_current_state(state);
 
 		/* Loop until we've been woken or interrupted */
 		flags = smp_load_acquire(&wait->flags);
 		if (!(flags & WQ_FLAG_WOKEN)) {
-			if (signal_pending_state(TASK_UNINTERRUPTIBLE, current))
+			if (signal_pending_state(state, current)) {
+				interrupted = true;
 				break;
+			}
 
 			io_schedule();
 			continue;
@@ -1469,12 +1499,21 @@ void softleaf_entry_wait_on_locked(softleaf_t entry, spinlock_t *ptl)
 		break;
 	}
 
+out:
 	finish_wait(q, wait);
 
 	if (thrashing) {
 		delayacct_thrashing_end(&in_thrashing);
 		psi_memstall_leave(&pflags);
 	}
+
+	/* Let the fault handler see the fatal signal, as for a folio lock. */
+	if (interrupted && !ret) {
+		release_fault_lock(vmf);
+		ret = VM_FAULT_RETRY;
+	}
+
+	return ret;
 }
 #endif
 
diff --git a/mm/memory.c b/mm/memory.c
index ec3d9d99ccee..febafef95d57 100644
--- a/mm/memory.c
+++ b/mm/memory.c
@@ -5007,8 +5007,7 @@ vm_fault_t do_swap_page(struct vm_fault *vmf)
 	entry = softleaf_from_pte(vmf->orig_pte);
 	if (unlikely(!softleaf_is_swap(entry))) {
 		if (softleaf_is_migration(entry)) {
-			migration_entry_wait(vma->vm_mm, vmf->pmd,
-					     vmf->address);
+			ret = migration_entry_wait_fault(vmf);
 		} else if (softleaf_is_device_exclusive(entry)) {
 			vmf->page = softleaf_to_page(entry);
 			ret = remove_device_exclusive_entry(vmf);
@@ -5049,7 +5048,8 @@ vm_fault_t do_swap_page(struct vm_fault *vmf)
 				folio_put(folio);
 			} else {
 				pte_unmap(vmf->pte);
-				softleaf_entry_wait_on_locked(entry, vmf->ptl);
+				ret = softleaf_entry_wait_on_locked(entry,
+								    vmf->ptl, vmf);
 			}
 		} else if (softleaf_is_hwpoison(entry)) {
 			ret = VM_FAULT_HWPOISON;
diff --git a/mm/migrate.c b/mm/migrate.c
index 875079464930..cd06a2bd487f 100644
--- a/mm/migrate.c
+++ b/mm/migrate.c
@@ -485,13 +485,9 @@ void remove_migration_ptes(struct folio *src, struct folio *dst,
 		rmap_walk(dst, &rwc);
 }
 
-/*
- * Something used the pte of a page under migration. We need to
- * get to the page and wait until migration is finished.
- * When we return from this function the fault will be retried.
- */
-void migration_entry_wait(struct mm_struct *mm, pmd_t *pmd,
-			  unsigned long address)
+static vm_fault_t __migration_entry_wait(struct mm_struct *mm, pmd_t *pmd,
+					 unsigned long address,
+					 struct vm_fault *vmf)
 {
 	spinlock_t *ptl;
 	pte_t *ptep;
@@ -500,7 +496,7 @@ void migration_entry_wait(struct mm_struct *mm, pmd_t *pmd,
 
 	ptep = pte_offset_map_lock(mm, pmd, address, &ptl);
 	if (!ptep)
-		return;
+		return 0;
 
 	pte = ptep_get(ptep);
 	pte_unmap(ptep);
@@ -512,10 +508,36 @@ void migration_entry_wait(struct mm_struct *mm, pmd_t *pmd,
 	if (!softleaf_is_migration(entry))
 		goto out;
 
-	softleaf_entry_wait_on_locked(entry, ptl);
-	return;
+	return softleaf_entry_wait_on_locked(entry, ptl, vmf);
 out:
 	spin_unlock(ptl);
+	return 0;
+}
+
+/*
+ * Something used the pte of a page under migration. We need to
+ * get to the page and wait until migration is finished.
+ * When we return from this function the fault will be retried.
+ */
+void migration_entry_wait(struct mm_struct *mm, pmd_t *pmd,
+			  unsigned long address)
+{
+	__migration_entry_wait(mm, pmd, address, NULL);
+}
+
+/**
+ * migration_entry_wait_fault - wait for a migration entry from a fault
+ * @vmf: the fault being handled.
+ *
+ * Like migration_entry_wait(), but drops the fault lock before sleeping
+ * when the fault may be retried, and sleeps killably for a killable fault.
+ *
+ * Return: VM_FAULT_RETRY if the fault lock was dropped, 0 otherwise.
+ */
+vm_fault_t migration_entry_wait_fault(struct vm_fault *vmf)
+{
+	return __migration_entry_wait(vmf->vma->vm_mm, vmf->pmd,
+				      vmf->address, vmf);
 }
 
 #ifdef CONFIG_HUGETLB_PAGE
@@ -547,7 +569,7 @@ void migration_entry_wait_huge(struct vm_area_struct *vma, unsigned long addr, p
 		 * lock release in softleaf_entry_wait_on_locked().
 		 */
 		hugetlb_vma_unlock_read(vma);
-		softleaf_entry_wait_on_locked(entry, ptl);
+		softleaf_entry_wait_on_locked(entry, ptl, NULL);
 		return;
 	}
 
@@ -565,7 +587,7 @@ void pmd_migration_entry_wait(struct mm_struct *mm, pmd_t *pmd)
 	ptl = pmd_lock(mm, pmd);
 	if (!pmd_is_migration_entry(*pmd))
 		goto unlock;
-	softleaf_entry_wait_on_locked(softleaf_from_pmd(*pmd), ptl);
+	softleaf_entry_wait_on_locked(softleaf_from_pmd(*pmd), ptl, NULL);
 	return;
 unlock:
 	spin_unlock(ptl);

---
base-commit: 7e1392a42ea288d70a266f6553fe06f57f8647ea
change-id: 20261117-junhomax-fix-mm-migrate-killable-1cc31f28bcb2

Best regards,
--  
Junho Cha <junho.cha@xcena.com>

