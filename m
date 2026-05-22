From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 22 May 2026 13:45:07 -0700
Subject: [PATCH 1/3] KVM: guest_memfd: Use write permissions when GUP-ing
 source pages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260522-fix-sev-gmem-post-populate-v1-1-9fc8d6437b65@google.com>
References: <20260522-fix-sev-gmem-post-populate-v1-0-9fc8d6437b65@google.com>
In-Reply-To: <20260522-fix-sev-gmem-post-populate-v1-0-9fc8d6437b65@google.com>
To: Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Kiryl Shutsemau <kas@kernel.org>, 
 Rick Edgecombe <rick.p.edgecombe@intel.com>, 
 Vishal Annapurve <vannapurve@google.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Michael Roth <michael.roth@amd.com>, 
 Isaku Yamahata <isaku.yamahata@intel.com>, 
 Chao Peng <chao.p.peng@linux.intel.com>, Xiaoyao Li <xiaoyao.li@intel.com>, 
 Zongyao Chen <ZongYao.Chen@linux.alibaba.com>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-coco@lists.linux.dev, Yu Zhang <yu.c.zhang@linux.intel.com>, 
 Fuad Tabba <tabba@google.com>, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779482720; l=3935;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=NOLwc6JliC+gaSDhEKSTPHm5NB60r/tP961hWN1Pkhc=;
 b=aTFMJtLEvgVlBqEj5Dw/cTP/t3oH0sLd50f9WCEDOXRpyo6h3E0l/yR/Aedelcc/W4MjxhgxI
 FhV2a1zxUovBAq38H6gXfATIDzStJ/WiSglU0EdY3Zktm8kJI+h2q1s
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Sean Christopherson <seanjc@google.com>

sev_gmem_post_populate() may write to the source page if there was an error
while performing SNP_LAUNCH_UPDATE.

Since GUP requested only reads, there is a chance sev_gmem_post_populate()
could be writing to some read-only page.

sev_gmem_post_populate() will only ever write the source page if the type
of page being LAUNCH_UPDATEd is a CPUID page. Hence, request a writable
page only when loading the CPUID page.

Since TDX never writes to the source page, always pass false to
kvm_gmem_populate().

With this, even if a read-only mapping or the global zero page was provided
as the source page, GUP will do a copy-on-write, making it writable before
the write happens in gvm_post_populate.

Fixes: 2a62345b30529 ("KVM: guest_memfd: GUP source pages prior to populating guest memory")
Signed-off-by: Sean Christopherson <seanjc@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/svm/sev.c   | 1 +
 arch/x86/kvm/vmx/tdx.c   | 2 +-
 include/linux/kvm_host.h | 3 ++-
 virt/kvm/guest_memfd.c   | 6 ++++--
 4 files changed, 8 insertions(+), 4 deletions(-)

diff --git a/arch/x86/kvm/svm/sev.c b/arch/x86/kvm/svm/sev.c
index 940b97d4a8523..2f254c447923e 100644
--- a/arch/x86/kvm/svm/sev.c
+++ b/arch/x86/kvm/svm/sev.c
@@ -2469,6 +2469,7 @@ static int snp_launch_update(struct kvm *kvm, struct kvm_sev_cmd *argp)
 	sev_populate_args.type = params.type;
 
 	count = kvm_gmem_populate(kvm, params.gfn_start, src, npages,
+				  params.type == KVM_SEV_SNP_PAGE_TYPE_CPUID,
 				  sev_gmem_post_populate, &sev_populate_args);
 	if (count < 0) {
 		argp->error = sev_populate_args.fw_error;
diff --git a/arch/x86/kvm/vmx/tdx.c b/arch/x86/kvm/vmx/tdx.c
index b8c3d3d8bbfe5..00dcfcbc47f68 100644
--- a/arch/x86/kvm/vmx/tdx.c
+++ b/arch/x86/kvm/vmx/tdx.c
@@ -3185,7 +3185,7 @@ static int tdx_vcpu_init_mem_region(struct kvm_vcpu *vcpu, struct kvm_tdx_cmd *c
 		};
 		gmem_ret = kvm_gmem_populate(kvm, gpa_to_gfn(region.gpa),
 					     u64_to_user_ptr(region.source_addr),
-					     1, tdx_gmem_post_populate, &arg);
+					     1, false, tdx_gmem_post_populate, &arg);
 		if (gmem_ret < 0) {
 			ret = gmem_ret;
 			break;
diff --git a/include/linux/kvm_host.h b/include/linux/kvm_host.h
index 4c14aee1fb063..2c5ad9a6d5ce8 100644
--- a/include/linux/kvm_host.h
+++ b/include/linux/kvm_host.h
@@ -2596,7 +2596,8 @@ int kvm_arch_gmem_prepare(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn, int max_ord
 typedef int (*kvm_gmem_populate_cb)(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 				    struct page *page, void *opaque);
 
-long kvm_gmem_populate(struct kvm *kvm, gfn_t gfn, void __user *src, long npages,
+long kvm_gmem_populate(struct kvm *kvm, gfn_t start_gfn, void __user *src,
+		       long npages, bool may_writeback_src,
 		       kvm_gmem_populate_cb post_populate, void *opaque);
 #endif
 
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 69c9d6d546b28..07d8db344872b 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -858,7 +858,8 @@ static long __kvm_gmem_populate(struct kvm *kvm, struct kvm_memory_slot *slot,
 	return ret;
 }
 
-long kvm_gmem_populate(struct kvm *kvm, gfn_t start_gfn, void __user *src, long npages,
+long kvm_gmem_populate(struct kvm *kvm, gfn_t start_gfn, void __user *src,
+		       long npages, bool may_writeback_src,
 		       kvm_gmem_populate_cb post_populate, void *opaque)
 {
 	struct kvm_memory_slot *slot;
@@ -892,8 +893,9 @@ long kvm_gmem_populate(struct kvm *kvm, gfn_t start_gfn, void __user *src, long
 
 		if (src) {
 			unsigned long uaddr = (unsigned long)src + i * PAGE_SIZE;
+			unsigned int flags = may_writeback_src ? FOLL_WRITE : 0;
 
-			ret = get_user_pages_fast(uaddr, 1, 0, &src_page);
+			ret = get_user_pages_fast(uaddr, 1, flags, &src_page);
 			if (ret < 0)
 				break;
 			if (ret != 1) {

-- 
2.54.0.794.g4f17f83d09-goog

