From: Ackerley Tng <ackerleytng@google.com>
Date: Sun, 30 Aug 2026 17:25:02 -0700
Subject: [PATCH v12 01/45] KVM: guest_memfd: Optimize away conversion
 overheads via dead-code elimination
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-gmem-inplace-conversion-v12-1-85e5fd25252a@google.com>
References: <20260830-gmem-inplace-conversion-v12-0-85e5fd25252a@google.com>
In-Reply-To: <20260830-gmem-inplace-conversion-v12-0-85e5fd25252a@google.com>
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
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788135915; l=3210;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=KU5lBT3XbWircUdxqmS0fnCYMooY3DNtiddyAdBDhH4=;
 b=wRmS6WFV25eBLlkWhcNyTW8umJE+UPeg3uo0+Q/XM+JU1xnLi6JSPz7bg3Lq5iuNlI20eGVdN
 DspTez7dVYLAdbPlQJTf6Vo6/pxxxjuYSdhZdAGOK71ZI1A0hl3fCXc
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

Add and use kvm_arch_has_gmem_convert() to guard guest_memfd's invocation
of arch hooks related to converting memory between private and shared, as
only one half of the x86 CoCo duo needs the runtime hooks (any pre-work is
pure overhead for TDX).  At this exact moment, the overhead is negligible,
but that will change when in-place conversion comes along, at which point
to-shared conversions will "need" to find all affected folios prior to
calling into arch code.  In quotes because very technically that work could
be pushed to arch code, but that would bleed guest_memfd details into arch
code and would be far worse than adding yet another kvm_arch_has... hook.

Opportunistically provide the kvm_arch_gmem_make_private() declaration, and
rely on dead-code elimination to eliminate the call to non-existent code
when CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT=n.

Reported-by: Binbin Wu <binbin.wu@linux.intel.com>
Closes: https://lore.kernel.org/all/1ec08cd8-3072-4753-ad5e-cd34956647f8@linux.intel.com
Suggested-by: Ackerley Tng <ackerleytng@google.com>
Signed-off-by: Sean Christopherson <seanjc@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/include/asm/kvm_host.h | 3 +++
 include/linux/kvm_host.h        | 3 ++-
 virt/kvm/guest_memfd.c          | 5 ++---
 3 files changed, 7 insertions(+), 4 deletions(-)

diff --git a/arch/x86/include/asm/kvm_host.h b/arch/x86/include/asm/kvm_host.h
index 683bb8bf43a94..6beddd8a0c749 100644
--- a/arch/x86/include/asm/kvm_host.h
+++ b/arch/x86/include/asm/kvm_host.h
@@ -1854,6 +1854,9 @@ enum kvm_intr_type {
 #ifdef CONFIG_KVM_GENERIC_MEMORY_ATTRIBUTES
 #define kvm_arch_has_private_mem(kvm) ((kvm)->arch.has_private_mem)
 #endif
+#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
+#define kvm_arch_has_gmem_convert() (!!kvm_x86_ops.gmem_make_private)
+#endif
 
 #define kvm_arch_has_readonly_mem(kvm) (!(kvm)->arch.has_protected_state)
 
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index 502465119ca0c..b7516e19ef419 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2597,9 +2597,10 @@ static inline int kvm_gmem_get_pfn(struct kvm *kvm,
 }
 #endif /* CONFIG_KVM_GUEST_MEMFD */
 
-#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
 int kvm_arch_gmem_make_private(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 			       kvm_pfn_t nr_pages);
+#ifndef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
+#define kvm_arch_has_gmem_convert() false
 #endif
 
 #ifdef CONFIG_HAVE_KVM_ARCH_GMEM_POPULATE
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 798d91df69537..2190e4d6b6bea 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -772,11 +772,10 @@ int kvm_gmem_get_pfn(struct kvm *kvm, struct kvm_memory_slot *slot,
 		folio_mark_uptodate(folio);
 	}
 
-#ifdef CONFIG_HAVE_KVM_ARCH_GMEM_CONVERT
-	if (kvm_gmem_is_private_mem(file_inode(file), index))
+	if (kvm_arch_has_gmem_convert() &&
+	    kvm_gmem_is_private_mem(file_inode(file), index))
 		r = kvm_arch_gmem_make_private(kvm, gfn, *pfn,
 					       (kvm_pfn_t)1 << *max_order);
-#endif
 
 	folio_unlock(folio);
 	folio_put(folio);

-- 
2.55.0.897.gb25b4bd76c-goog

