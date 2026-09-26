From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 25 Sep 2026 17:50:49 -0700
Subject: [PATCH RFC 02/17] KVM: guest_memfd: Support provider folio
 allocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-gmem-tmpfs-backend-v1-2-d36159822d18@google.com>
References: <20260925-gmem-tmpfs-backend-v1-0-d36159822d18@google.com>
In-Reply-To: <20260925-gmem-tmpfs-backend-v1-0-d36159822d18@google.com>
To: Hugh Dickins <hughd@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, David Hildenbrand <david@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>, 
 vannapurve@google.com, erdemaktas@google.com, jxgao@google.com, 
 rientjes@google.com, fvdl@google.com, jthoughton@google.com, 
 tarunsahu@google.com, pratyush@kernel.org, fuad.tabba@linux.dev, 
 Gregory Price <gourry@gourry.net>, David Woodhouse <dwmw2@infradead.org>, 
 yan.y.zhao@intel.com, michael.roth@amd.com, suzuki.poulose@arm.com, 
 Christian Brauner <brauner@kernel.org>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Nicolin Chen <nicolinc@nvidia.com>, Xu Yilun <yilun.xu@linux.intel.com>, 
 aik@amd.com, aneesh.kumar@kernel.org, Vlastimil Babka <vbabka@kernel.org>
Cc: kernel-team@android.com, kernel-team@meta.com, 
 linux-kernel@vger.kernel.org, linux-mm@kvack.org, kvm@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790383850; l=4521;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=k2wJag3xpkJiPwETrEDU9zeAf8p9w5PDeeJUkL2Wy30=;
 b=owZKCzvSRlsk4pNWUHrAac7TjSqV4V9OZ2vm5pyo4kxj3zk6HBlqYl6Pp0x4cTb4Dcq5IAsvj
 UN0BwPL00V3AdOv5deqq4zfA+D0roElHz1GSsNK5j/d5HO5QLYV9Gc7
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If this guest_memfd was created with a provider, use the provider to
allocate a folio. For folio-based providers, using guest_memfd's filemap is
better because folio->mapping would be guest_memfd's mapping, and so
guest_memfd can handle anything that makes decisions based off
folio->mapping, like memory_failure().

Going along these lines of using gmem's filemap, passing gmem's filemap for
the provider to insert into seems awkward. At least for tmpfs, the
insertion function does a lot of stuff and assumes stuff about the filemap
being a tmpfs one (completely fair). I think it's better to use gmem's
filemap and do charging (memcg) and inode accounting according to
guest_memfd's rules though, hence insertion is done within gmem, in a gmem
filemap.

Going back to folio->mapping pointing to the gmem filemap, we could have
special memory failure handling for guest_memfd folios too, if there's some
kind of central registry of all PFNs belonging to guest_memfd? There are
other usages of folio->mapping, but gmem doesn't participate in those since
gmem doesn't do swap, etc now.

For non-folio-based providers, here's my suggestion: Don't provide
.alloc_folio(), provide some equivalent callback for pfns, track pfns in
gmem. The provider can force gmem to return the folios anytime, the
.attach() can be bidirectional.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 44 ++++++++++++++++++++++++++++++++++++++++----
 1 file changed, 40 insertions(+), 4 deletions(-)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index a13445c26d9d6..5ac2d558c8dd8 100644
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
@@ -50,6 +54,16 @@ static __always_inline struct gmem_inode *GMEM_I(struct inode *inode)
 	return container_of(inode, struct gmem_inode, vfs_inode);
 }
 
+static inline struct folio *gmem_provider_alloc_folio(struct gmem_inode *gi,
+						      pgoff_t index,
+						      struct mempolicy *mpol)
+{
+	if (!gi->provider_ops || !gi->provider_ops->alloc_folio)
+		return ERR_PTR(-EOPNOTSUPP);
+
+	return gi->provider_ops->alloc_folio(gi->provider, index, mpol);
+}
+
 #define kvm_gmem_for_each_file(f, inode) \
 	list_for_each_entry(f, &GMEM_I(inode)->gmem_file_list, entry)
 
@@ -128,6 +142,7 @@ static bool kvm_gmem_range_has_attributes(struct inode *inode,
  */
 static struct folio *kvm_gmem_get_folio(struct inode *inode, pgoff_t index)
 {
+	struct gmem_inode *gi = GMEM_I(inode);
 	/* TODO: Support huge pages. */
 	struct mempolicy *policy;
 	struct folio *folio;
@@ -140,10 +155,29 @@ static struct folio *kvm_gmem_get_folio(struct inode *inode, pgoff_t index)
 	if (!IS_ERR(folio))
 		return folio;
 
-	policy = mpol_shared_policy_lookup(&GMEM_I(inode)->policy, index);
-	folio = __filemap_get_folio_mpol(inode->i_mapping, index,
-					 FGP_LOCK | FGP_CREAT,
-					 mapping_gfp_mask(inode->i_mapping), policy);
+	policy = mpol_shared_policy_lookup(&gi->policy, index);
+	/*
+	 * TODO: Refactor the internal PAGE_SIZE gmem could be an internal
+	 * provider with internal provider_ops.
+	 */
+	if (gi->provider_ops) {
+		folio = gmem_provider_alloc_folio(gi, index, policy);
+		if (!IS_ERR(folio)) {
+			int r = filemap_add_folio(inode->i_mapping, folio,
+						  index, GFP_KERNEL);
+			if (r) {
+				folio_put(folio);
+				folio = ERR_PTR(r);
+			} else {
+				folio_mark_accessed(folio);
+			}
+		}
+	} else {
+		folio = __filemap_get_folio_mpol(inode->i_mapping, index,
+						 FGP_LOCK | FGP_CREAT,
+						 mapping_gfp_mask(inode->i_mapping),
+						 policy);
+	}
 	mpol_cond_put(policy);
 
 	/*
@@ -1334,6 +1368,8 @@ static struct inode *kvm_gmem_alloc_inode(struct super_block *sb)
 	mt_init_flags(&gi->attributes, MT_FLAGS_LOCK_EXTERN | MT_FLAGS_USE_RCU);
 
 	gi->flags = 0;
+	gi->provider = NULL;
+	gi->provider_ops = NULL;
 	INIT_LIST_HEAD(&gi->gmem_file_list);
 	return &gi->vfs_inode;
 }

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

