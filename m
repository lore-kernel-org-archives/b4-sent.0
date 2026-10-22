From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 22 Oct 2026 16:27:34 -0700
Subject: [PATCH RFC v2 02/50] KVM: guest_memfd: Route folio allocation
 through native provider operations
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261022-gmem-alternative-providers-v2-2-5dd1dc6c660a@google.com>
References: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
In-Reply-To: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711664; l=6480;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=/6ChK+dhNyFC5epULer4MMTl5heO+eaQ0hyuSzmx3Fo=;
 b=za/ALoHb/ybC9kgi6o2avnw/xTRhb+35RtnrYcvmZnrWvKtTjSZTkiZbEU0bys25KYfAoQfI6
 RPM9vxjHJ70CI2szG/reUm3EdeeRow6j6qo08Wm3qQ7SAt8dhK26dXk
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Conceptually refactor the buddy allocator providing guest_memfd with
order-0 folios as the native provider.

Define operations with an alloc_folio callback for the native provider,
which still uses filemap_alloc_folio to allocate folios as before. Also
define the attach callback to establish provider context. Route folio
allocation in the get-folio path through provider ops, and set up the
native provider during creation using a sentinel fd and attach.

Attach the provider only after the entire inode and pseudo-file have been
initialized. Exposing the inode to external providers before allocating the
file or populating the file list risks race conditions and use-after-free
bugs if an external provider immediately triggers operations on the
guest_memfd inode.

Now that the inode is exposed for other providers, add a write barrier to
commit everything in the inode before the provider (and other racing
provider threads) gets to use the gmem inode.

Expose provider operations so external providers across the kernel can
implement them.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 include/linux/guest_memfd.h | 28 +++++++++++++++
 virt/kvm/guest_memfd.c      | 86 ++++++++++++++++++++++++++++++++++++++++++---
 2 files changed, 110 insertions(+), 4 deletions(-)

diff --git a/include/linux/guest_memfd.h b/include/linux/guest_memfd.h
new file mode 100644
index 0000000000000..218de509769c1
--- /dev/null
+++ b/include/linux/guest_memfd.h
@@ -0,0 +1,28 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef _LINUX_GUEST_MEMFD_H
+#define _LINUX_GUEST_MEMFD_H
+
+#include <linux/types.h>
+
+struct file;
+struct folio;
+struct inode;
+struct mempolicy;
+
+/**
+ * struct guest_memfd_provider_operations - Operations for external memory providers
+ * @attach: Attach to a resource file, perform filesystem-specific validation,
+ *          and return an opaque provider context.
+ * @alloc_folio: Allocate an uninserted folio for a given index and NUMA policy.
+ *               Must return a pointer to a struct folio on success, or an
+ *               ERR_PTR() error code on failure. Must never return NULL.
+ *
+ * Used by filesystems and device drivers that provide memory for guest_memfd.
+ */
+struct guest_memfd_provider_operations {
+	void *(*attach)(struct inode *gmem_inode, struct file *resource_file);
+	struct folio *(*alloc_folio)(void *provider, pgoff_t index,
+				     struct mempolicy *mpol);
+};
+
+#endif /* _LINUX_GUEST_MEMFD_H */
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index f865fa0e46840..545c3e646e9c1 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -3,6 +3,7 @@
 #include <linux/backing-dev.h>
 #include <linux/falloc.h>
 #include <linux/fs.h>
+#include <linux/guest_memfd.h>
 #include <linux/kvm_host.h>
 #include <linux/maple_tree.h>
 #include <linux/mempolicy.h>
@@ -35,6 +36,9 @@ struct gmem_inode {
 	struct inode vfs_inode;
 	struct list_head gmem_file_list;
 
+	void *provider;
+	const struct guest_memfd_provider_operations *provider_ops;
+
 	u64 flags;
 	/*
 	 * Every index in this inode, whether memory is populated or
@@ -50,6 +54,65 @@ static __always_inline struct gmem_inode *GMEM_I(struct inode *inode)
 	return container_of(inode, struct gmem_inode, vfs_inode);
 }
 
+static void *gmem_native_attach(struct inode *gmem_inode,
+				struct file *resource_file)
+{
+	return GMEM_I(gmem_inode);
+}
+
+static struct folio *gmem_native_alloc_folio(void *provider, pgoff_t index,
+					     struct mempolicy *mpol)
+{
+	struct gmem_inode *gi = provider;
+	struct folio *folio;
+	gfp_t gfp;
+
+	gfp = mapping_gfp_mask(gi->vfs_inode.i_mapping);
+	folio = filemap_alloc_folio(gfp, 0, mpol);
+	if (!folio)
+		return ERR_PTR(-ENOMEM);
+
+	return folio;
+}
+
+static const struct guest_memfd_provider_operations gmem_native_provider_ops = {
+	.attach = gmem_native_attach,
+	.alloc_folio = gmem_native_alloc_folio,
+};
+
+#define GMEM_RESOURCE_FD_NATIVE (-1)
+
+static int kvm_gmem_attach_resource(struct inode *inode, int resource_fd)
+{
+	const struct guest_memfd_provider_operations *ops = NULL;
+	struct file *resource_file = NULL;
+	void *provider;
+
+	if (resource_fd == GMEM_RESOURCE_FD_NATIVE)
+		ops = &gmem_native_provider_ops;
+	else
+		return -EOPNOTSUPP;
+
+	provider = ops->attach(inode, resource_file);
+	if (IS_ERR(provider))
+		return PTR_ERR(provider);
+
+	GMEM_I(inode)->provider = provider;
+	GMEM_I(inode)->provider_ops = ops;
+
+	return 0;
+}
+
+static struct folio *gmem_provider_alloc_folio(struct gmem_inode *gi,
+					       pgoff_t index,
+					       struct mempolicy *mpol)
+{
+	if (gi->provider_ops && gi->provider_ops->alloc_folio)
+		return gi->provider_ops->alloc_folio(gi->provider, index, mpol);
+
+	return ERR_PTR(-EOPNOTSUPP);
+}
+
 #define kvm_gmem_for_each_file(f, inode) \
 	list_for_each_entry(f, &GMEM_I(inode)->gmem_file_list, entry)
 
@@ -143,11 +206,10 @@ static struct folio *kvm_gmem_get_folio(struct inode *inode, pgoff_t index)
 		return folio;
 
 	policy = mpol_shared_policy_lookup(&GMEM_I(inode)->policy, index);
-	folio = filemap_alloc_folio(mapping_gfp_mask(inode->i_mapping), 0,
-				    policy);
+	folio = gmem_provider_alloc_folio(GMEM_I(inode), index, policy);
 	mpol_cond_put(policy);
-	if (!folio)
-		return ERR_PTR(-ENOMEM);
+	if (IS_ERR(folio))
+		return folio;
 
 	r = filemap_add_folio(inode->i_mapping, folio, index, GFP_KERNEL);
 	if (r) {
@@ -996,6 +1058,20 @@ static int __kvm_gmem_create(struct kvm *kvm, loff_t size, u64 flags)
 	xa_init(&f->bindings);
 	list_add(&f->entry, &GMEM_I(inode)->gmem_file_list);
 
+	/*
+	 * Ensure all inode and file initialization (such as gmem_file_list and
+	 * bindings) is globally visible before exposing the inode to the
+	 * provider in ->attach().
+	 */
+	smp_wmb();
+
+	err = kvm_gmem_attach_resource(inode, GMEM_RESOURCE_FD_NATIVE);
+	if (err) {
+		fput(file);
+		put_unused_fd(fd);
+		return err;
+	}
+
 	fd_install(fd, file);
 	return fd;
 
@@ -1355,6 +1431,8 @@ static struct inode *kvm_gmem_alloc_inode(struct super_block *sb)
 	mt_init_flags(&gi->attributes, MT_FLAGS_LOCK_EXTERN | MT_FLAGS_USE_RCU);
 
 	gi->flags = 0;
+	gi->provider = NULL;
+	gi->provider_ops = NULL;
 	INIT_LIST_HEAD(&gi->gmem_file_list);
 	return &gi->vfs_inode;
 }

-- 
2.56.0.257.gf7497c7d27-goog

