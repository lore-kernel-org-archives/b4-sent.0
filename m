From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 06 Nov 2026 16:36:37 -0800
Subject: [PATCH RFC v3 03/88] mm: shmem: Implement guest_memfd provider
 operations for tmpfs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-gmem-alternative-providers-v3-3-8484dde66a7e@google.com>
References: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
In-Reply-To: <20261106-gmem-alternative-providers-v3-0-8484dde66a7e@google.com>
To: Alexey Kardashevskiy <aik@amd.com>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Christian Brauner <brauner@kernel.org>, 
 David Hildenbrand <david@kernel.org>, David Woodhouse <dwmw2@infradead.org>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, Jianxiong Gao <jxgao@google.com>, 
 John Starks <John.Starks@microsoft.com>, 
 Michael Roth <michael.roth@amd.com>, Paolo Bonzini <pbonzini@redhat.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Vishal Annapurve <vannapurve@google.com>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794011809; l=9029;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=w5F2INXe7PMp1rqtUln4bn2FpG8wydJ1GoS1Y0nfVWo=;
 b=ApZCcNj3gmxsjr9vljr8GO4XoOBmEcNfxs5kg/dUxcnPyZ5Ddc9aDlzef7hGhpAikG4sH/Ytf
 fHBkFLTMguyDH4ZVii+wc8yob3FcAOKHoie/WWtTaRaV/oGo1AFTuQw
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement guest_memfd provider operations to declare that tmpfs supports
providing memory to guest_memfd.

I put guest_memfd_provider_operations as a pointer in struct
file_operations. Being in file_operations generalizes well to other kinds
of providers, like devices, which don't have their own super_operations.

Setting it in shmem_dir_operations allows directory file descriptors
opened on a tmpfs mount to provide memory to guest_memfd.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 fs/libfs.c                  |   4 +-
 include/linux/fs.h          |   6 +++
 include/linux/guest_memfd.h |   4 ++
 mm/shmem.c                  | 126 ++++++++++++++++++++++++++++++++++++++++++++
 4 files changed, 138 insertions(+), 2 deletions(-)

diff --git a/fs/libfs.c b/fs/libfs.c
index 27d7dc16fcb0a..77d3a4fcb5c13 100644
--- a/fs/libfs.c
+++ b/fs/libfs.c
@@ -429,7 +429,7 @@ void simple_offset_destroy(struct offset_ctx *octx)
  * Returns the updated read position if successful; otherwise a
  * negative errno is returned and the read position remains unchanged.
  */
-static loff_t offset_dir_llseek(struct file *file, loff_t offset, int whence)
+loff_t offset_dir_llseek(struct file *file, loff_t offset, int whence)
 {
 	switch (whence) {
 	case SEEK_CUR:
@@ -551,7 +551,7 @@ static void offset_iterate_dir(struct file *file, struct dir_context *ctx)
  * Return values:
  *   %0 - Complete
  */
-static int offset_readdir(struct file *file, struct dir_context *ctx)
+int offset_readdir(struct file *file, struct dir_context *ctx)
 {
 	struct dentry *dir = file->f_path.dentry;
 
diff --git a/include/linux/fs.h b/include/linux/fs.h
index deb411e866617..4f1494c4fbfde 100644
--- a/include/linux/fs.h
+++ b/include/linux/fs.h
@@ -1915,6 +1915,7 @@ struct dir_context {
 
 struct io_uring_cmd;
 struct offset_ctx;
+struct guest_memfd_provider_operations;
 
 struct file_operations {
 	struct module *owner;
@@ -1960,6 +1961,9 @@ struct file_operations {
 	int (*uring_cmd_iopoll)(struct io_uring_cmd *, struct io_comp_batch *,
 				unsigned int poll_flags);
 	int (*mmap_prepare)(struct vm_area_desc *);
+#ifdef CONFIG_KVM_GUEST_MEMFD
+	const struct guest_memfd_provider_operations *gmem_provider_ops;
+#endif
 } __randomize_layout;
 
 /* Supports async buffered reads */
@@ -3337,6 +3341,8 @@ int simple_offset_rename_exchange(struct inode *old_dir,
 				  struct dentry *new_dentry);
 void simple_offset_destroy(struct offset_ctx *octx);
 
+loff_t offset_dir_llseek(struct file *file, loff_t offset, int whence);
+int offset_readdir(struct file *file, struct dir_context *ctx);
 extern const struct file_operations simple_offset_dir_operations;
 
 extern int simple_fsync_noflush(struct file *, loff_t, loff_t, int);
diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
index 218de509769c1..f3e6077c39ac3 100644
--- a/include/linux/guest_memfd.h
+++ b/include/linux/guest_memfd.h
@@ -13,16 +13,20 @@ struct mempolicy;
  * struct guest_memfd_provider_operations - Operations for external memory providers
  * @attach: Attach to a resource file, perform filesystem-specific validation,
  *          and return an opaque provider context.
+ * @release: Release provider context and unpin any resources.
  * @alloc_folio: Allocate an uninserted folio for a given index and NUMA policy.
  *               Must return a pointer to a struct folio on success, or an
  *               ERR_PTR() error code on failure. Must never return NULL.
+ * @invalidate_folio: Notify provider that a folio has been invalidated.
  *
  * Used by filesystems and device drivers that provide memory for guest_memfd.
  */
 struct guest_memfd_provider_operations {
 	void *(*attach)(struct inode *gmem_inode, struct file *resource_file);
+	void (*release)(void *provider);
 	struct folio *(*alloc_folio)(void *provider, pgoff_t index,
 				     struct mempolicy *mpol);
+	void (*invalidate_folio)(void *provider, struct folio *folio);
 };
 
 #endif /* _LINUX_GUEST_MEMFD_H */
diff --git a/mm/shmem.c b/mm/shmem.c
index 848316eaa7f4f..2a9faf8be7382 100644
--- a/mm/shmem.c
+++ b/mm/shmem.c
@@ -38,6 +38,7 @@
 #include <linux/uio.h>
 #include <linux/hugetlb.h>
 #include <linux/fs_parser.h>
+#include <linux/guest_memfd.h>
 #include <linux/swapfile.h>
 #include <linux/iversion.h>
 #include <linux/unicode.h>
@@ -268,6 +269,9 @@ static void shmem_inode_unacct_blocks(struct inode *inode, long pages)
 static const struct super_operations shmem_ops;
 static const struct address_space_operations shmem_aops;
 static const struct file_operations shmem_file_operations;
+#ifdef CONFIG_KVM_GUEST_MEMFD
+static const struct file_operations shmem_dir_operations;
+#endif
 static const struct inode_operations shmem_inode_operations;
 static const struct inode_operations shmem_dir_inode_operations;
 static const struct inode_operations shmem_special_inode_operations;
@@ -3088,7 +3092,11 @@ static struct inode *__shmem_get_inode(struct mnt_idmap *idmap,
 		/* Some things misbehave if size == 0 on a directory */
 		inode->i_size = 2 * BOGO_DIRENT_SIZE;
 		inode->i_op = &shmem_dir_inode_operations;
+#ifdef CONFIG_KVM_GUEST_MEMFD
+		inode->i_fop = &shmem_dir_operations;
+#else
 		inode->i_fop = &simple_offset_dir_operations;
+#endif
 		simple_offset_init(shmem_get_offset_ctx(inode));
 		break;
 	case S_IFLNK:
@@ -5237,6 +5245,124 @@ static const struct inode_operations shmem_special_inode_operations = {
 #endif
 };
 
+#ifdef CONFIG_KVM_GUEST_MEMFD
+static void *shmem_gmem_attach(struct inode *gmem_inode,
+			       struct file *resource_file)
+{
+	struct inode *inode = file_inode(resource_file);
+	struct shmem_sb_info *sbinfo;
+
+	if (!S_ISDIR(inode->i_mode))
+		return ERR_PTR(-ENOTDIR);
+
+	/*
+	 * Would like comments: Requiring the root directory of the mount
+	 * provides a less confusing interface, although this is not strictly
+	 * necessary.
+	 */
+	if (resource_file->f_path.dentry != resource_file->f_path.mnt->mnt_root)
+		return ERR_PTR(-EINVAL);
+
+	if (__mnt_is_readonly(resource_file->f_path.mnt))
+		return ERR_PTR(-EROFS);
+
+	if (inode_permission(file_mnt_idmap(resource_file), inode,
+			     MAY_WRITE | MAY_EXEC))
+		return ERR_PTR(-EACCES);
+
+	/* Enforce noswap because guest_memfd does not support swapping. */
+	sbinfo = SHMEM_SB(inode->i_sb);
+	if (!sbinfo->noswap)
+		return ERR_PTR(-EINVAL);
+
+#ifdef CONFIG_TRANSPARENT_HUGEPAGE
+	/*
+	 * guest_memfd does not support huge pages yet; this restriction can be
+	 * relaxed in the future.
+	 *
+	 * TODO: Block rebinding with huge page support.
+	 */
+	if (sbinfo->huge != SHMEM_HUGE_NEVER)
+		return ERR_PTR(-EINVAL);
+#endif
+
+	return (void *)mntget(resource_file->f_path.mnt);
+}
+
+static void shmem_gmem_release(void *provider)
+{
+	struct vfsmount *mnt = provider;
+
+	mntput(mnt);
+}
+
+/*
+ * TODO: Consider refactoring shmem allocation helpers to share code between
+ * internal tmpfs folio allocation and guest_memfd provider allocation.
+ */
+static struct folio *shmem_gmem_alloc_folio(void *provider, pgoff_t index,
+					    struct mempolicy *mpol)
+{
+	struct mempolicy *sb_mpol = NULL;
+	struct vfsmount *mnt = provider;
+	struct shmem_sb_info *sbinfo;
+	struct folio *folio;
+
+	sbinfo = SHMEM_SB(mnt->mnt_sb);
+	if (sbinfo->max_blocks &&
+	    !percpu_counter_limited_add(&sbinfo->used_blocks,
+					sbinfo->max_blocks, 1))
+		return ERR_PTR(-ENOSPC);
+
+	if (!mpol) {
+		sb_mpol = shmem_get_sbmpol(sbinfo);
+		mpol = sb_mpol;
+	}
+
+	if (mpol)
+		folio = folio_alloc_mpol(GFP_HIGHUSER_MOVABLE, 0, mpol, index,
+					 numa_node_id());
+	else
+		folio = folio_alloc(GFP_HIGHUSER_MOVABLE, 0);
+
+	mpol_cond_put(sb_mpol);
+
+	if (!folio) {
+		if (sbinfo->max_blocks)
+			percpu_counter_sub(&sbinfo->used_blocks, 1);
+		return ERR_PTR(-ENOMEM);
+	}
+
+	return folio;
+}
+
+static void shmem_gmem_invalidate_folio(void *provider, struct folio *folio)
+{
+	struct vfsmount *mnt = provider;
+	struct shmem_sb_info *sbinfo;
+
+	sbinfo = SHMEM_SB(mnt->mnt_sb);
+	if (sbinfo->max_blocks)
+		percpu_counter_sub(&sbinfo->used_blocks, folio_nr_pages(folio));
+}
+
+static const struct guest_memfd_provider_operations shmem_gmem_provider_ops = {
+	.attach			= shmem_gmem_attach,
+	.release		= shmem_gmem_release,
+	.alloc_folio		= shmem_gmem_alloc_folio,
+	.invalidate_folio	= shmem_gmem_invalidate_folio,
+};
+
+static const struct file_operations shmem_dir_operations = {
+	.llseek		= offset_dir_llseek,
+	.iterate_shared	= offset_readdir,
+	.read		= generic_read_dir,
+	.fsync		= noop_fsync,
+	.setlease	= generic_setlease,
+	.gmem_provider_ops = &shmem_gmem_provider_ops,
+};
+#endif /* CONFIG_KVM_GUEST_MEMFD */
+
 static const struct super_operations shmem_ops = {
 	.alloc_inode	= shmem_alloc_inode,
 	.free_inode	= shmem_free_in_core_inode,

-- 
2.56.0.455.g6c5a503b38-goog

