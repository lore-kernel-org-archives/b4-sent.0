From: Harrison Crosse <harrison@crosse.dev>
Date: Wed, 18 Nov 2026 16:56:41 -0500
Subject: [PATCH 1/2] mm/gup: make mlock() and MAP_POPULATE handle
 VM_FAULT_RETRY properly
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-mmpop-populate-v1-1-9c561d178d11@crosse.dev>
References: <20261118-mmpop-populate-v1-0-9c561d178d11@crosse.dev>
In-Reply-To: <20261118-mmpop-populate-v1-0-9c561d178d11@crosse.dev>
To: David Hildenbrand <david@kernel.org>, Jason Gunthorpe <jgg@ziepe.ca>, 
 John Hubbard <jhubbard@nvidia.com>, Peter Xu <peterx@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Shuah Khan <shuah@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Josef Bacik <josef@toxicpanda.com>, 
 Johannes Weiner <hannes@cmpxchg.org>, Jan Kara <jack@suse.cz>, 
 Harrison Crosse <harrison@crosse.dev>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795039163; l=8262;
 i=harrison@crosse.dev; s=20261117; h=from:subject:message-id;
 bh=o68P5YM1Dim45OasWUC3bF7sN6yAaM3DW9PetPgRC/s=;
 b=wMywT4ZYui4m+Gr0BQNzKVCKGUsOs8ElQLremHykfZO3gQlEasMlfWRhgJxvo670cC69t7XUb
 CtHOhvEHU2AAP+NoMgKynw/kYmxTgANI2mN8jBocLFjhxSZWR9nw9gp
X-Developer-Key: i=harrison@crosse.dev; a=ed25519;
 pk=fwi/XME2YaW/BDBQ76FmKgF9xHZwRb+dxlVCbxuyojo=
X-Endpoint-Received: by B4 Relay for harrison@crosse.dev/20261117 with auth_id=1552
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If every read of a page of a file mapping fails, mmap(MAP_POPULATE)
and mlock() of that mapping do not return: the task spins in
__mm_populate(), submitting a new read of the page on each iteration,
until it gets a fatal signal. Touching the same page gets SIGBUS, and
madvise(MADV_POPULATE_READ) fails with -EFAULT.

The first fault on the page reaches filemap_fault() with
FAULT_FLAG_ALLOW_RETRY and without FAULT_FLAG_TRIED. filemap_fault()
releases the mmap_lock to read the page and, because it released the
lock, returns VM_FAULT_RETRY before it looks at the result of the read.
It cannot report the error then: a fault that has released the lock
returns VM_FAULT_RETRY or VM_FAULT_COMPLETED, and neither carries an
error. faultin_page() turns VM_FAULT_RETRY into -EBUSY, so
__get_user_pages() stops at that page without an error, and
__mm_populate() calls populate_vma_page_range() again at that address,
again without FOLL_TRIED. The page fault handlers and
__get_user_pages_locked() retry with FAULT_FLAG_TRIED instead, and on
that attempt filemap_fault() reads the page with the lock held and
returns VM_FAULT_SIGBUS if the read fails.

Commit 631426ba1d45 ("mm/madvise: make MADV_POPULATE_(READ|WRITE) handle
VM_FAULT_RETRY properly") fixed the same loop for MADV_POPULATE_* by
calling __get_user_pages_locked(). That does not fit here:
__get_user_pages_locked() retakes the mmap_lock itself and carries on
with the GUP flags it was given, while populate_vma_page_range()
derives those flags from the VMA that __mm_populate() looks up again,
and may skip, after each unlock. Retrying with a NULL locked instead
would drop FAULT_FLAG_ALLOW_RETRY and FAULT_FLAG_KILLABLE, so a
userfaultfd range would fail rather than wait, and folio lock waits
would not be killable.

Instead, have __mm_populate() remember the address of the page whose
fault released the mmap_lock. When the next iteration starts at that
address, fault in that page alone with FOLL_TRIED, as
__get_user_pages_locked() does, then continue with the rest of the
range as before. The retry reads the page with the mmap_lock held, as
filemap_fault() did for a page that was not uptodate before v5.1, and
as the other GUP retries do. With a persistent read error the retry
fails with -EFAULT: mlock() returns -ENOMEM
(__mlock_posix_error_return() maps -EFAULT to it), and MAP_POPULATE,
which ignores populate errors, returns the mapping. A fatal signal
still ends the loop, with -EINTR from __get_user_pages() or, if it
interrupts the FOLL_TRIED read, with -EFAULT. The other callers of
populate_vma_page_range() pass a NULL locked, so they cannot get
VM_FAULT_RETRY and are unchanged.

Reproduced with ext4 on dm-linear over a loop device, with the eight
sectors of one page of a file mapped to the dm "error" target, on arm64
(Debian's 6.12.116 and v7.4-rc3) and x86_64 (v7.4-rc3): mmap(MAP_POPULATE)
and mlock() of the file were still running in the kernel after 5 seconds
and ended when sent SIGKILL. On 6.12.116, the block layer tracepoints
showed about 280,000 bios a second being submitted and failed.

The analysis, the patch and this changelog were prepared with the help
of an AI coding assistant (Claude).

Fixes: 6b4c9f446981 ("filemap: drop the mmap_sem for all blocking operations")
Link: https://lore.kernel.org/all/20191105182211.GA33242@cmpxchg.org/
Link: https://lore.kernel.org/all/20240314161300.382526-1-david@redhat.com/
Cc: stable@vger.kernel.org
Signed-off-by: Harrison Crosse <harrison@crosse.dev>
---
Tested on x86_64 v7.4-rc3 under QEMU (TCG): with the error page,
mmap(MAP_POPULATE) returns the mapping and mlock() fails with ENOMEM,
MADV_POPULATE_READ still fails with EFAULT and touching the page still
gets SIGBUS. With reads of that page delayed by 1 s with dm-delay,
SIGKILL during the read ends the task within 2 ms. Without a read
error, MAP_POPULATE, MAP_LOCKED, mlock() and mlockall() map every page,
and the map_populate, mlock2-tests, mlock-random-test, madv_populate,
mremap_dontunmap, on-fault-limit and guard-regions selftests have no
failures, nor does populate_eio from the next patch. On arm64 v7.4-rc3
under QEMU (TCG), populate_eio fails its mmap(MAP_POPULATE) and mlock()
checks without this patch and passes all three with it.

Not tested: the other checks above on arm64, page sizes other than 4K,
transient read errors, userfaultfd ranges, file systems other than ext4
and FUSE, real disks, non-fatal signals, and the rest of the mm
selftests.
---
 mm/gup.c | 36 ++++++++++++++++++++++++++++++++----
 1 file changed, 32 insertions(+), 4 deletions(-)

diff --git a/mm/gup.c b/mm/gup.c
index 2b405cce2..e666761ed 100644
--- a/mm/gup.c
+++ b/mm/gup.c
@@ -1795,11 +1795,12 @@ static __always_inline long __get_user_pages_locked(struct mm_struct *mm,
 }
 
 /**
- * populate_vma_page_range() -  populate a range of pages in the vma.
+ * __populate_vma_page_range() -  populate a range of pages in the vma.
  * @vma:   target vma
  * @start: start address
  * @end:   end address
  * @locked: whether the mmap_lock is still held
+ * @tried: whether this retries a fault that released the mmap_lock
  *
  * This takes care of mlocking the pages too if VM_LOCKED is set.
  *
@@ -1814,8 +1815,9 @@ static __always_inline long __get_user_pages_locked(struct mm_struct *mm,
  * If @locked is non-NULL, it must held for read only and may be
  * released.  If it's released, *@locked will be set to 0.
  */
-long populate_vma_page_range(struct vm_area_struct *vma,
-		unsigned long start, unsigned long end, int *locked)
+static long __populate_vma_page_range(struct vm_area_struct *vma,
+				      unsigned long start, unsigned long end,
+				      int *locked, bool tried)
 {
 	struct mm_struct *mm = vma->vm_mm;
 	unsigned long nr_pages = (end - start) / PAGE_SIZE;
@@ -1860,6 +1862,8 @@ long populate_vma_page_range(struct vm_area_struct *vma,
 
 	if (locked)
 		gup_flags |= FOLL_UNLOCKABLE;
+	if (tried)
+		gup_flags |= FOLL_TRIED;
 
 	/*
 	 * We made sure addr is within a VMA, so the following will
@@ -1871,6 +1875,13 @@ long populate_vma_page_range(struct vm_area_struct *vma,
 	return ret;
 }
 
+long populate_vma_page_range(struct vm_area_struct *vma,
+			     unsigned long start, unsigned long end,
+			     int *locked)
+{
+	return __populate_vma_page_range(vma, start, end, locked, false);
+}
+
 /*
  * faultin_page_range() - populate (prefault) page tables inside the
  *			  given range readable/writable
@@ -1934,7 +1945,9 @@ int __mm_populate(unsigned long start, unsigned long len, int ignore_errors)
 {
 	struct mm_struct *mm = current->mm;
 	unsigned long end, nstart, nend;
+	unsigned long retry_addr = 0;
 	struct vm_area_struct *vma = NULL;
+	bool retry = false, tried;
 	int locked = 0;
 	long ret = 0;
 
@@ -1967,8 +1980,21 @@ int __mm_populate(unsigned long start, unsigned long len, int ignore_errors)
 		 * Now fault in a range of pages. populate_vma_page_range()
 		 * double checks the vma flags, so that it won't mlock pages
 		 * if the vma was already munlocked.
+		 *
+		 * filemap_fault() reports a read error only when
+		 * FAULT_FLAG_TRIED is set: on a first attempt it releases the
+		 * mmap_lock for the read and returns VM_FAULT_RETRY whatever
+		 * the result. So when the last call released the lock at
+		 * nstart, retry that page with FOLL_TRIED, and only that page,
+		 * so that later pages still get a first attempt that releases
+		 * the lock for the read. Compare the address because nstart
+		 * moves past that page if it is no longer mapped, or its VMA
+		 * is skipped, when the lock is retaken.
 		 */
-		ret = populate_vma_page_range(vma, nstart, nend, &locked);
+		tried = retry && nstart == retry_addr;
+		ret = __populate_vma_page_range(vma, nstart,
+						tried ? nstart + PAGE_SIZE : nend,
+						&locked, tried);
 		if (ret < 0) {
 			if (ignore_errors) {
 				ret = 0;
@@ -1977,6 +2003,8 @@ int __mm_populate(unsigned long start, unsigned long len, int ignore_errors)
 			break;
 		}
 		nend = nstart + ret * PAGE_SIZE;
+		retry = !locked;
+		retry_addr = nend;
 		ret = 0;
 	}
 	if (locked)

-- 
2.56.1

