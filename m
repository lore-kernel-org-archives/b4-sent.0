From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 25 Sep 2026 17:50:50 -0700
Subject: [PATCH RFC 03/17] KVM: guest_memfd: Support provider folio
 invalidation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260925-gmem-tmpfs-backend-v1-3-d36159822d18@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790383850; l=3424;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=HcCpVRdef3JCMSn2VvVwvzxMYU+D6iq2rei81oGu4lo=;
 b=eWvF/vgmoEI5Wqhqk1edUIUfKJCkkkuEQ5SluDzgA4sqW7on378bDcWX9fZvhhV6hfBE5zkE3
 p1qPPfnWtm/B6laliCdNe2KkBm/AX2cVnPXANHEBFUmHG4vn88XsHd4
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tmpfs increments the total number of used pages on the mount at allocation
time, so that number has to be decremented when the folio is removed from
tmpfs' ownership.

In this model where guest_memfd allocates from a tmpfs mount, I believe we
should respect the limits set in the mount, hence I require .alloc_folio()
to increment.

.invalidate_folio() is then the counterpart to .alloc_folio(), for undoing
any provider-specific per-folio work during allocations.

.invalidate_folio() requires mapping_set_release_always(). Not sure how odd
it is to use that mapping flag.

Using .free_folio() is hard because folio->mapping is NULL by then, so I
can't reach provider information. The provider information could also be
stuffed in folio->private? What do people think of that?

Another alternative would be to use a custom truncation function in
guest_memfd, just like shmem_truncate_range() or shmem_undo_range(). The
con is that guest_memfd might at some point support more generic mm stuff
like swap/reclaim, of some form? Or maybe never? Shall we go custom now and
unify later? Or just not think too far ahead?

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 virt/kvm/guest_memfd.c | 23 +++++++++++++++++++++++
 1 file changed, 23 insertions(+)

diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 5ac2d558c8dd8..00f3bd0cf21e6 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -64,6 +64,13 @@ static inline struct folio *gmem_provider_alloc_folio(struct gmem_inode *gi,
 	return gi->provider_ops->alloc_folio(gi->provider, index, mpol);
 }
 
+static inline void gmem_provider_invalidate_folio(struct gmem_inode *gi,
+						  struct folio *folio)
+{
+	if (gi->provider_ops && gi->provider_ops->invalidate_folio)
+		gi->provider_ops->invalidate_folio(gi->provider, folio);
+}
+
 #define kvm_gmem_for_each_file(f, inode) \
 	list_for_each_entry(f, &GMEM_I(inode)->gmem_file_list, entry)
 
@@ -166,6 +173,7 @@ static struct folio *kvm_gmem_get_folio(struct inode *inode, pgoff_t index)
 			int r = filemap_add_folio(inode->i_mapping, folio,
 						  index, GFP_KERNEL);
 			if (r) {
+				gmem_provider_invalidate_folio(gi, folio);
 				folio_put(folio);
 				folio = ERR_PTR(r);
 			} else {
@@ -893,10 +901,24 @@ static void kvm_gmem_free_folio(struct folio *folio)
 }
 #endif
 
+static void kvm_gmem_invalidate_folio(struct folio *folio, size_t offset,
+				      size_t len)
+{
+	struct inode *inode = folio->mapping->host;
+	struct gmem_inode *gi = GMEM_I(inode);
+
+	/* guest_memfd only allows truncating full folios. */
+	if (WARN_ON_ONCE(offset != 0 || len != folio_size(folio)))
+		return;
+
+	gmem_provider_invalidate_folio(gi, folio);
+}
+
 static const struct address_space_operations kvm_gmem_aops = {
 	.dirty_folio = noop_dirty_folio,
 	.migrate_folio	= kvm_gmem_migrate_folio,
 	.error_remove_folio = kvm_gmem_error_folio,
+	.invalidate_folio = kvm_gmem_invalidate_folio,
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM
 	.free_folio = kvm_gmem_free_folio,
 #endif
@@ -935,6 +957,7 @@ static int kvm_gmem_init_inode(struct inode *inode, loff_t size, u64 flags)
 	 */
 	mapping_set_inaccessible(inode->i_mapping);
 	WARN_ON_ONCE(!mapping_unevictable(inode->i_mapping));
+	mapping_set_release_always(inode->i_mapping);
 
 	gi->flags = flags;
 

-- 
2.56.0.rc1.315.gc6ed9934b7-goog

