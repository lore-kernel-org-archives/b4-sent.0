From: Ackerley Tng <ackerleytng@google.com>
Date: Thu, 10 Sep 2026 16:55:42 -0700
Subject: [PATCH v13 16/44] KVM: guest_memfd: Call arch make_shared callback
 for to-shared conversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260910-gmem-inplace-conversion-v13-16-dd6fbf94f4e1@google.com>
References: <20260910-gmem-inplace-conversion-v13-0-dd6fbf94f4e1@google.com>
In-Reply-To: <20260910-gmem-inplace-conversion-v13-0-dd6fbf94f4e1@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 jmattson@google.com, jthoughton@google.com, michael.roth@amd.com, 
 oupton@kernel.org, pankaj.gupta@amd.com, qperret@google.com, 
 rick.p.edgecombe@intel.com, rientjes@google.com, shivankg@amd.com, 
 steven.price@arm.com, willy@infradead.org, wyihan@google.com, 
 yan.y.zhao@intel.com, forkloop@google.com, pratyush@kernel.org, 
 suzuki.poulose@arm.com, aneesh.kumar@kernel.org, liam@infradead.org, 
 Paolo Bonzini <pbonzini@redhat.com>, 
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
 Jason Gunthorpe <jgg@ziepe.ca>, John Hubbard <jhubbard@nvidia.com>, 
 Peter Xu <peterx@redhat.com>, tarunsahu@google.com, 
 Randy Dunlap <rdunlap@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Fuad Tabba <fuad.tabba@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>, 
 Fuad Tabba <fuad.tabba@linux.dev>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789084533; l=5988;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=pnjcuYiGgOrTACJiDuCpEUUXJmfVPZdc0nxxctxlq1I=;
 b=8n/zqT12bJsDEGglxVJpV0qF7heq6Y/6E8z8+2TPGozDYy2KIXFbkJruoR9CqjTm5xYcISqXB
 uNl2w215XnvChWobjBOo60K/Wh3YvU13WDJU5+Z2PMtVpViNfPkT54t
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When doing in-place conversion from PRIVATE to SHARED, immediately inform
arch code of the conversion for all allocated pages/folios, e.g. so that
arch code can put hardware metadata tables in the correct state.  Eagerly
updating the table for to SHARED conversions avoids having to implement
on-demand updates, e.g. when faulting in host userspace mappings.  Skip the
entire flow if the arch doesn't implement conversion callbacks, as getting
folios from the filemap is noticeably expensive, especially when converting
large chunks of memory.

Deliberately don't eagerly update the metadata table on conversions from
SHARED to PRIVATE, because assigning a page to a VM (versus "returning" it
to the host) requires the exact GFN associated with the page, i.e would
require walking the memslot bindings.  And because KVM *must* do on-demand
metadata updates when getting a PFN for KVM-internal usage, as that's the
only time a relevant memslot binding is guaranteed to exist.

Note!  Inform arch code of the conversion within the protection of the
invalidation sequence, to ensure that any existing mappings are dropped
before hardware is updated, and to ensure that new mappings can't be
established until after the conversion is complete.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
Reviewed-by: Fuad Tabba <fuad.tabba@linux.dev>
---
 arch/x86/include/asm/kvm-x86-ops.h |  2 +-
 arch/x86/include/asm/kvm_host.h    |  2 +-
 arch/x86/kvm/x86.c                 |  5 +++++
 include/linux/kvm_host.h           |  1 +
 virt/kvm/guest_memfd.c             | 42 ++++++++++++++++++++++++++++++++++++++
 5 files changed, 50 insertions(+), 2 deletions(-)

diff --git a/arch/x86/include/asm/kvm-x86-ops.h b/arch/x86/include/asm/kvm-x86-ops.h
index e213c9ae3e301..67b43c167045b 100644
--- a/arch/x86/include/asm/kvm-x86-ops.h
+++ b/arch/x86/include/asm/kvm-x86-ops.h
@@ -150,7 +150,7 @@ KVM_X86_OP_OPTIONAL(alloc_apic_backing_page)
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
 KVM_X86_OP_OPTIONAL_RET0(gmem_make_private)
 #endif
-#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM
+#if defined(CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT) || defined(CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM)
 KVM_X86_OP_OPTIONAL(gmem_make_shared)
 #endif
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_INVALIDATE
diff --git a/arch/x86/include/asm/kvm_host.h b/arch/x86/include/asm/kvm_host.h
index 744c1f6ff03ed..83e26ce45fb79 100644
--- a/arch/x86/include/asm/kvm_host.h
+++ b/arch/x86/include/asm/kvm_host.h
@@ -1732,7 +1732,7 @@ struct kvm_x86_ops {
 	int (*gmem_make_private)(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 				 kvm_pfn_t nr_pages);
 #endif
-#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM
+#if defined(CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT) || defined(CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM)
 	void (*gmem_make_shared)(kvm_pfn_t pfn, kvm_pfn_t nr_pages);
 #endif
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_INVALIDATE
diff --git a/arch/x86/kvm/x86.c b/arch/x86/kvm/x86.c
index 2292249570314..75e03a2f79db2 100644
--- a/arch/x86/kvm/x86.c
+++ b/arch/x86/kvm/x86.c
@@ -10653,6 +10653,11 @@ int kvm_arch_gmem_make_private(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 {
 	return kvm_x86_call(gmem_make_private)(kvm, gfn, pfn, nr_pages);
 }
+
+void kvm_arch_gmem_make_shared(kvm_pfn_t pfn, kvm_pfn_t nr_pages)
+{
+	kvm_x86_call(gmem_make_shared)(pfn, nr_pages);
+}
 #endif
 
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_RECLAIM
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index ab87effdd221f..485f18454eb45 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2610,6 +2610,7 @@ static inline int kvm_gmem_get_pfn(struct kvm *kvm,
 
 int kvm_arch_gmem_make_private(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 			       kvm_pfn_t nr_pages);
+void kvm_arch_gmem_make_shared(kvm_pfn_t pfn, kvm_pfn_t nr_pages);
 #ifndef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
 #define kvm_arch_has_gmem_convert() false
 #endif
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 2de39ce8aec13..85446fe720603 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -588,6 +588,43 @@ static bool kvm_gmem_has_outstanding_references(struct inode *inode,
 	return false;
 }
 
+#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
+static void kvm_gmem_make_shared(struct inode *inode, pgoff_t start, pgoff_t end)
+{
+	struct folio_batch fbatch;
+	pgoff_t next = start;
+	int i;
+
+	folio_batch_init(&fbatch);
+	while (filemap_get_folios(inode->i_mapping, &next, end - 1, &fbatch)) {
+		for (i = 0; i < folio_batch_count(&fbatch); ++i) {
+			struct folio *folio = fbatch.folios[i];
+			pgoff_t start_index, end_index;
+			kvm_pfn_t start_pfn;
+			kvm_pfn_t nr_pages;
+
+			start_index = max(start, folio->index);
+			end_index = min(end, folio_next_index(folio));
+			/*
+			 * end_index is either in folio or points to
+			 * the first page of the next folio. Hence,
+			 * all pages in range [start_index, end_index)
+			 * are contiguous.
+			 */
+			start_pfn = folio_file_pfn(folio, start_index);
+			nr_pages = end_index - start_index;
+
+			kvm_arch_gmem_make_shared(start_pfn, nr_pages);
+		}
+
+		folio_batch_release(&fbatch);
+		cond_resched();
+	}
+}
+#else
+static void kvm_gmem_make_shared(struct inode *inode, pgoff_t start, pgoff_t end) {}
+#endif
+
 static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 				     size_t nr_pages, uint64_t attrs,
 				     pgoff_t *err_index)
@@ -637,7 +674,12 @@ static int __kvm_gmem_set_attributes(struct inode *inode, pgoff_t start,
 
 	filter = to_private ? KVM_FILTER_SHARED : KVM_FILTER_PRIVATE;
 	kvm_gmem_invalidate_start(inode, start, end, filter);
+
+	if (!to_private && kvm_arch_has_gmem_convert())
+		kvm_gmem_make_shared(inode, start, end);
+
 	mas_store_prealloc(&mas, xa_mk_value(attrs));
+
 	kvm_gmem_invalidate_end(inode, start, end);
 out:
 	filemap_invalidate_unlock(mapping);

-- 
2.55.0.1007.g17ff1f9808-goog

