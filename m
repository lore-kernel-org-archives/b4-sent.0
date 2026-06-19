From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 18 Jun 2026 17:31:38 -0700
Subject: [PATCH v8 01/46] KVM: guest_memfd: Introduce per-gmem attributes,
 use to guard user mappings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260618-gmem-inplace-conversion-v8-1-9d2959357853@google.com>
References: <20260618-gmem-inplace-conversion-v8-0-9d2959357853@google.com>
In-Reply-To: <20260618-gmem-inplace-conversion-v8-0-9d2959357853@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 jmattson@google.com, jthoughton@google.com, michael.roth@amd.com, 
 oupton@kernel.org, pankaj.gupta@amd.com, qperret@google.com, 
 rick.p.edgecombe@intel.com, rientjes@google.com, shivankg@amd.com, 
 steven.price@arm.com, tabba@google.com, willy@infradead.org, 
 wyihan@google.com, yan.y.zhao@intel.com, forkloop@google.com, 
 pratyush@kernel.org, suzuki.poulose@arm.com, aneesh.kumar@kernel.org, 
 liam@infradead.org, Paolo Bonzini <pbonzini@redhat.com>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Vishal Annapurve <vannapurve@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Youngjun Park <youngjun.park@lge.com>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Kiryl Shutsemau <kas@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>, 
 Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781829104; l=8345;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=nsdHpKlk+sP4AF3sm4HTiKS8T81szSRv+YhjA8rehUo=;
 b=8qWM8YJmCJIxo50kGb+UQSk/HIisizsO1xrR6VNvgs6iIsdIf/338mBvUZMkIbygHGImC2vOi
 ABNDoq5/mc3DYqQQDnUm6idJuvcY229CCaCpZo0YzSIAX3qmsyRwp6S
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

Start plumbing in guest_memfd support for in-place private<=>shared
conversions by tracking attributes via a maple tree.  KVM currently tracks
private vs. shared attributes on a per-VM basis, which made sense when a
guest_memfd _only_ supported private memory, but tracking per-VM simply
can't work for in-place conversions as the shared/private status of a given
page needs to be per-gmem_inode, not per-VM.

Use the filemap invalidation lock to protect the maple tree, as taking the
lock for read when faulting in memory (for userspace or the guest) isn't
expected to result in meaningful contention, and using a separate lock
would add significant complexity (avoiding deadlock is quite difficult).

Co-developed-by: Vishal Annapurve <vannapurve@google.com>
Signed-off-by: Vishal Annapurve <vannapurve@google.com>
Co-developed-by: Fuad Tabba <tabba@google.com>
Signed-off-by: Fuad Tabba <tabba@google.com>
Co-developed-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Sean Christopherson <seanjc@google.com>
---
 virt/kvm/guest_memfd.c | 133 +++++++++++++++++++++++++++++++++++++++++++------
 1 file changed, 117 insertions(+), 16 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 86690683b2fe3..b4c24fdf159f6 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -4,6 +4,7 @@
 #include <linux/falloc.h>
 #include <linux/fs.h>
 #include <linux/kvm_host.h>
+#include <linux/maple_tree.h>
 #include <linux/mempolicy.h>
 #include <linux/pseudo_fs.h>
 #include <linux/pagemap.h>
@@ -33,6 +34,13 @@ struct gmem_inode {
 	struct list_head gmem_file_list;
 
 	u64 flags;
+	/*
+	 * Every index in this inode, whether memory is populated or
+	 * not, is tracked in attributes. The entire range of indices,
+	 * corresponding to the size of this inode, is represented in
+	 * this maple tree.
+	 */
+	struct maple_tree attributes;
 };
 
 static __always_inline struct gmem_inode *GMEM_I(struct inode *inode)
@@ -60,6 +68,24 @@ static pgoff_t kvm_gmem_get_index(struct kvm_memory_slot *slot, gfn_t gfn)
 	return gfn - slot->base_gfn + slot->gmem.pgoff;
 }
 
+static u64 kvm_gmem_get_attributes(struct inode *inode, pgoff_t index)
+{
+	struct maple_tree *mt = &GMEM_I(inode)->attributes;
+	void *entry = mtree_load(mt, index);
+
+	return WARN_ON_ONCE(!entry) ? 0 : xa_to_value(entry);
+}
+
+static bool kvm_gmem_is_private_mem(struct inode *inode, pgoff_t index)
+{
+	return kvm_gmem_get_attributes(inode, index) & KVM_MEMORY_ATTRIBUTE_PRIVATE;
+}
+
+static bool kvm_gmem_is_shared_mem(struct inode *inode, pgoff_t index)
+{
+	return !kvm_gmem_is_private_mem(inode, index);
+}
+
 static int __kvm_gmem_prepare_folio(struct kvm *kvm, struct kvm_memory_slot *slot,
 				    pgoff_t index, struct folio *folio)
 {
@@ -397,10 +423,13 @@ static vm_fault_t kvm_gmem_fault_user_mapping(struct vm_fault *vmf)
 	if (((loff_t)vmf->pgoff << PAGE_SHIFT) >= i_size_read(inode))
 		return VM_FAULT_SIGBUS;
 
-	if (!(GMEM_I(inode)->flags & GUEST_MEMFD_FLAG_INIT_SHARED))
-		return VM_FAULT_SIGBUS;
+	filemap_invalidate_lock_shared(inode->i_mapping);
+	if (kvm_gmem_is_shared_mem(inode, vmf->pgoff))
+		folio = kvm_gmem_get_folio(inode, vmf->pgoff);
+	else
+		folio = ERR_PTR(-EACCES);
+	filemap_invalidate_unlock_shared(inode->i_mapping);
 
-	folio = kvm_gmem_get_folio(inode, vmf->pgoff);
 	if (IS_ERR(folio)) {
 		if (PTR_ERR(folio) == -EAGAIN)
 			return VM_FAULT_RETRY;
@@ -557,6 +586,51 @@ bool __weak kvm_arch_supports_gmem_init_shared(struct kvm *kvm)
 	return true;
 }
 
+static int kvm_gmem_init_inode(struct inode *inode, loff_t size, u64 flags)
+{
+	struct gmem_inode *gi = GMEM_I(inode);
+	MA_STATE(mas, &gi->attributes, 0, (size >> PAGE_SHIFT) - 1);
+	u64 attrs;
+	int r;
+
+	inode->i_op = &kvm_gmem_iops;
+	inode->i_mapping->a_ops = &kvm_gmem_aops;
+	inode->i_mode |= S_IFREG;
+	inode->i_size = size;
+	mapping_set_gfp_mask(inode->i_mapping, GFP_HIGHUSER);
+
+	/*
+	 * guest_memfd memory is neither migratable nor swappable: set
+	 * inaccessible to gate off both.
+	 */
+	mapping_set_inaccessible(inode->i_mapping);
+	WARN_ON_ONCE(!mapping_unevictable(inode->i_mapping));
+
+	gi->flags = flags;
+
+	mt_set_external_lock(&gi->attributes,
+			     &inode->i_mapping->invalidate_lock);
+
+	/*
+	 * Store default attributes for the entire gmem instance. Ensuring every
+	 * index is represented in the maple tree at all times simplifies the
+	 * conversion and merging logic.
+	 */
+	attrs = gi->flags & GUEST_MEMFD_FLAG_INIT_SHARED ? 0 : KVM_MEMORY_ATTRIBUTE_PRIVATE;
+
+	/*
+	 * Acquire the invalidation lock purely to make lockdep happy.  The
+	 * maple tree library expects all stores to be protected via the lock,
+	 * and the library can't know when the tree is reachable only by the
+	 * caller, as is the case here.
+	 */
+	filemap_invalidate_lock(inode->i_mapping);
+	r = mas_store_gfp(&mas, xa_mk_value(attrs), GFP_KERNEL);
+	filemap_invalidate_unlock(inode->i_mapping);
+
+	return r;
+}
+
 static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags)
 {
 	static const char *name = "[kvm-gmem]";
@@ -587,16 +661,9 @@ static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags)
 		goto err_fops;
 	}
 
-	inode->i_op = &kvm_gmem_iops;
-	inode->i_mapping->a_ops = &kvm_gmem_aops;
-	inode->i_mode |= S_IFREG;
-	inode->i_size = size;
-	mapping_set_gfp_mask(inode->i_mapping, GFP_HIGHUSER);
-	mapping_set_inaccessible(inode->i_mapping);
-	/* Unmovable mappings are supposed to be marked unevictable as well. */
-	WARN_ON_ONCE(!mapping_unevictable(inode->i_mapping));
-
-	GMEM_I(inode)->flags = flags;
+	err = kvm_gmem_init_inode(inode, size, flags);
+	if (err)
+		goto err_inode;
 
 	file = alloc_file_pseudo(inode, kvm_gmem_mnt, name, O_RDWR, &kvm_gmem_fops);
 	if (IS_ERR(file)) {
@@ -799,9 +866,13 @@ int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 	if (!file)
 		return -EFAULT;
 
+	filemap_invalidate_lock_shared(file_inode(file)->i_mapping);
+
 	folio = __kvm_gmem_get_pfn(file, slot, index, pfn, max_order);
-	if (IS_ERR(folio))
-		return PTR_ERR(folio);
+	if (IS_ERR(folio)) {
+		r = PTR_ERR(folio);
+		goto out;
+	}
 
 	if (!folio_test_uptodate(folio)) {
 		clear_highpage(folio_page(folio, 0));
@@ -817,6 +888,8 @@ int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 	else
 		folio_put(folio);
 
+out:
+	filemap_invalidate_unlock_shared(file_inode(file)->i_mapping);
 	return r;
 }
 EXPORT_SYMBOL_FOR_KVM_INTERNAL(kvm_gmem_get_pfn);
@@ -948,6 +1021,15 @@ static struct inode *kvm_gmem_alloc_inode(struct super_block *sb)
 
 	mpol_shared_policy_init(&gi->policy, NULL);
 
+	/*
+	 * Memory attributes are protected by the filemap invalidation lock, but
+	 * the lock structure isn't available at this time.  Immediately mark
+	 * maple tree as using external locking so that accessing the tree
+	 * before it's fully initialized results in NULL pointer dereferences
+	 * and not more subtle bugs.
+	 */
+	mt_init_flags(&gi->attributes, MT_FLAGS_LOCK_EXTERN | MT_FLAGS_USE_RCU);
+
 	gi->flags = 0;
 	INIT_LIST_HEAD(&gi->gmem_file_list);
 	return &gi->vfs_inode;
@@ -955,7 +1037,26 @@ static struct inode *kvm_gmem_alloc_inode(struct super_block *sb)
 
 static void kvm_gmem_destroy_inode(struct inode *inode)
 {
-	mpol_free_shared_policy(&GMEM_I(inode)->policy);
+	struct gmem_inode *gi = GMEM_I(inode);
+
+	mpol_free_shared_policy(&gi->policy);
+
+	/*
+	 * Note!  Checking for an empty tree is functionally necessary
+	 * to avoid explosions if the tree hasn't been fully
+	 * initialized, i.e. if the inode is being destroyed before
+	 * guest_memfd can set the external lock, lockdep would find
+	 * that the tree's internal ma_lock was not held.
+	 */
+	if (!mtree_empty(&gi->attributes)) {
+		/*
+		 * Acquire the invalidation lock purely to make lockdep happy,
+		 * the inode is unreachable at this point.
+		 */
+		filemap_invalidate_lock(inode->i_mapping);
+		__mt_destroy(&gi->attributes);
+		filemap_invalidate_unlock(inode->i_mapping);
+	}
 }
 
 static void kvm_gmem_free_inode(struct inode *inode)

-- 
2.55.0.rc0.738.g0c8ab3ebcc-goog

