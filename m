From: Dickson Wu <dickson.wu@certik.com>
Date: Sat, 28 Nov 2026 04:18:01 +0000
Subject: [PATCH 6.6.y] mm: fix uprobe pte be overwritten when expanding vma
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261128-uprobe-66c-v1-1-aadfd58e836f@certik.com>
X-B4-Tracking: v=1; b=H4sIAPhVCmsC/0WNwQ6CMBBEf4Xs2UVb4yL8ivHQlkVqTEu6YDSEf
 7fVg8d5mXmzgnDyLNBVKyR+evEx5KB2FbjRhBuj73MGfdCklD7jMqVoGYkcntqG3LElpmaAPJg
 SD/71lV2AaqrfcP1hWeyd3VxEpWiNMNpkghsLEg79HOMDC9//D2DbPr8XC12gAAAA
X-Change-ID: 20261128-uprobe-66c-5976c396e67f
In-Reply-To: <2025062009-customs-outskirts-5826@gregkh>
References: <2025062009-customs-outskirts-5826@gregkh>
To: stable@vger.kernel.org
Cc: Pu Lehui <pulehui@huawei.com>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 David Hildenbrand <david@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, linux-mm@kvack.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795839480; l=7675;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=Pxpy5u+zDbncpwIemAT49h1RaeD/R4OBqpJdAtccl90=;
 b=ZcaAzxyJ4dtfcMq8fWyJRezFMjXwULGFL4/XQ70139VGp9a30XjWTnu3z+rSBNz3T7ZkXe/54
 F4jGhulidH6AxmWJC33yVPZDZtlxGKCV5cziQtRBV5mAG7A6GcDinP3
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Pu Lehui <pulehui@huawei.com>

commit 2b12d06c37fd3a394376f42f026a7478d826ed63 upstream.

Patch series "Fix uprobe pte be overwritten when expanding vma".

This patch (of 4):

We encountered a BUG alert triggered by Syzkaller as follows:
   BUG: Bad rss-counter state mm:00000000b4a60fca type:MM_ANONPAGES val:1

And we can reproduce it with the following steps:
1. register uprobe on file at zero offset
2. mmap the file at zero offset:
   addr1 = mmap(NULL, 2 * 4096, PROT_NONE, MAP_PRIVATE, fd, 0);
3. mremap part of vma1 to new vma2:
   addr2 = mremap(addr1, 4096, 2 * 4096, MREMAP_MAYMOVE);
4. mremap back to orig addr1:
   mremap(addr2, 4096, 4096, MREMAP_MAYMOVE | MREMAP_FIXED, addr1);

In step 3, the vma1 range [addr1, addr1 + 4096] will be remap to new vma2
with range [addr2, addr2 + 8192], and remap uprobe anon page from the vma1
to vma2, then unmap the vma1 range [addr1, addr1 + 4096].

In step 4, the vma2 range [addr2, addr2 + 4096] will be remap back to the
addr range [addr1, addr1 + 4096].  Since the addr range [addr1 + 4096,
addr1 + 8192] still maps the file, it will take vma_merge_new_range to
expand the range, and then do uprobe_mmap in vma_complete.  Since the
merged vma pgoff is also zero offset, it will install uprobe anon page to
the merged vma.  However, the upcomming move_page_tables step, which use
set_pte_at to remap the vma2 uprobe pte to the merged vma, will overwrite
the newly uprobe pte in the merged vma, and lead that pte to be orphan.

Since the uprobe pte will be remapped to the merged vma, we can remove the
unnecessary uprobe_mmap upon merged vma.

This problem was first found in linux-6.6.y and also exists in the
community syzkaller:
https://lore.kernel.org/all/000000000000ada39605a5e71711@google.com/T/

Link: https://lkml.kernel.org/r/20250529155650.4017699-1-pulehui@huaweicloud.com
Link: https://lkml.kernel.org/r/20250529155650.4017699-2-pulehui@huaweicloud.com
Fixes: 2b1444983508 ("uprobes, mm, x86: Add the ability to install and remove uprobes breakpoints")
Signed-off-by: Pu Lehui <pulehui@huawei.com>
Suggested-by: Lorenzo Stoakes <lorenzo.stoakes@oracle.com>
Reviewed-by: Lorenzo Stoakes <lorenzo.stoakes@oracle.com>
Acked-by: David Hildenbrand <david@redhat.com>
Cc: Jann Horn <jannh@google.com>
Cc: Liam Howlett <liam.howlett@oracle.com>
Cc: "Masami Hiramatsu (Google)" <mhiramat@kernel.org>
Cc: Oleg Nesterov <oleg@redhat.com>
Cc: Peter Zijlstra <peterz@infradead.org>
Cc: Vlastimil Babka <vbabka@suse.cz>
Cc: stable@vger.kernel.org
Signed-off-by: Andrew Morton <akpm@linux-foundation.org>
[ adapted to 6.6.y: pass skip_vma_uprobe via an internal __vma_merge() ]
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
This failed to apply to 6.6.y, which has no vma_merge_struct to carry
the flag. Instead vma_merge() becomes a wrapper around an internal
__vma_merge() that takes skip_vma_uprobe, and only copy_vma() passes
true, for file-backed VMAs. vma_complete() then skips uprobe_mmap()
for that merge as upstream does. init_multi_vma_prep() zeroes the new
field, so other callers keep the old behaviour. The upstream comment
in copy_vma() is dropped since there's no vmg assignment to hang it on.

Tested on 6.6.163 in a QEMU guest with UPROBES and UPROBE_EVENTS: a
small program registers a perf uprobe on a file, mremaps the first
page away and back so copy_vma() merges it. The base kernel logs
"BUG: Bad rss-counter state" and calls uprobe_mmap() three times; with
the patch there's no warning, two calls, and the merge completes. The
mremap_test and mremap_dontunmap selftests pass on both kernels, and a
W=1 build of mmap.o shows no new warnings. I didn't check that the
probe still fires after the merge.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.
---
 mm/internal.h |  2 ++
 mm/mmap.c     | 35 ++++++++++++++++++++++++++---------
 2 files changed, 28 insertions(+), 9 deletions(-)

diff --git a/mm/internal.h b/mm/internal.h
index 1106bab6abc9..da2f1be0cd45 100644
--- a/mm/internal.h
+++ b/mm/internal.h
@@ -1231,6 +1231,8 @@ struct vma_prepare {
 	struct vm_area_struct *insert;
 	struct vm_area_struct *remove;
 	struct vm_area_struct *remove2;
+
+	bool skip_vma_uprobe :1;
 };
 
 /* pagewalk.c */
diff --git a/mm/mmap.c b/mm/mmap.c
index d1cabe718b63..c50f16c85419 100644
--- a/mm/mmap.c
+++ b/mm/mmap.c
@@ -542,10 +542,13 @@ static inline void vma_complete(struct vma_prepare *vp,
 
 	if (vp->file) {
 		i_mmap_unlock_write(vp->mapping);
-		uprobe_mmap(vp->vma);
 
-		if (vp->adj_next)
-			uprobe_mmap(vp->adj_next);
+		if (!vp->skip_vma_uprobe) {
+			uprobe_mmap(vp->vma);
+
+			if (vp->adj_next)
+				uprobe_mmap(vp->adj_next);
+		}
 	}
 
 	if (vp->remove) {
@@ -860,13 +863,13 @@ can_vma_merge_after(struct vm_area_struct *vma, unsigned long vm_flags,
  * **** is not represented - it will be merged and the vma containing the
  *      area is returned, or the function will return NULL
  */
-struct vm_area_struct *vma_merge(struct vma_iterator *vmi, struct mm_struct *mm,
+static struct vm_area_struct *__vma_merge(struct vma_iterator *vmi, struct mm_struct *mm,
 			struct vm_area_struct *prev, unsigned long addr,
 			unsigned long end, unsigned long vm_flags,
 			struct anon_vma *anon_vma, struct file *file,
 			pgoff_t pgoff, struct mempolicy *policy,
 			struct vm_userfaultfd_ctx vm_userfaultfd_ctx,
-			struct anon_vma_name *anon_name)
+			struct anon_vma_name *anon_name, bool skip_vma_uprobe)
 {
 	struct vm_area_struct *curr, *next, *res;
 	struct vm_area_struct *vma, *adjust, *remove, *remove2;
@@ -1010,6 +1013,7 @@ struct vm_area_struct *vma_merge(struct vma_iterator *vmi, struct mm_struct *mm,
 		goto prealloc_fail;
 
 	init_multi_vma_prep(&vp, vma, adjust, remove, remove2);
+	vp.skip_vma_uprobe = skip_vma_uprobe;
 	VM_WARN_ON(vp.anon_vma && adjust && adjust->anon_vma &&
 		   vp.anon_vma != adjust->anon_vma);
 
@@ -1046,6 +1050,18 @@ struct vm_area_struct *vma_merge(struct vma_iterator *vmi, struct mm_struct *mm,
 	return NULL;
 }
 
+struct vm_area_struct *vma_merge(struct vma_iterator *vmi, struct mm_struct *mm,
+			struct vm_area_struct *prev, unsigned long addr,
+			unsigned long end, unsigned long vm_flags,
+			struct anon_vma *anon_vma, struct file *file,
+			pgoff_t pgoff, struct mempolicy *policy,
+			struct vm_userfaultfd_ctx vm_userfaultfd_ctx,
+			struct anon_vma_name *anon_name)
+{
+	return __vma_merge(vmi, mm, prev, addr, end, vm_flags, anon_vma, file,
+			   pgoff, policy, vm_userfaultfd_ctx, anon_name, false);
+}
+
 /*
  * Rough compatibility check to quickly see if it's even worth looking
  * at sharing an anon_vma.
@@ -3431,10 +3447,11 @@ struct vm_area_struct *copy_vma(struct vm_area_struct **vmap,
 		/* If not registered for remap, uffd context will be cleared. */
 		new_vma = NULL;
 	else
-		new_vma = vma_merge(&vmi, mm, prev, addr, addr + len,
-				    vma->vm_flags, vma->anon_vma, vma->vm_file,
-				    pgoff, vma_policy(vma),
-				    vma->vm_userfaultfd_ctx, anon_vma_name(vma));
+		new_vma = __vma_merge(&vmi, mm, prev, addr, addr + len,
+				      vma->vm_flags, vma->anon_vma, vma->vm_file,
+				      pgoff, vma_policy(vma),
+				      vma->vm_userfaultfd_ctx, anon_vma_name(vma),
+				      vma->vm_file != NULL);
 	if (new_vma) {
 		/*
 		 * Source vma may have been merged into new_vma

---
base-commit: e2bb30811e063ce0db964484357973b855b06572
change-id: 20261128-uprobe-66c-5976c396e67f

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

