From: Ackerley Tng <ackerleytng@google.com>
Date: Fri, 22 May 2026 15:46:09 -0700
Subject: [PATCH v2 4/5] KVM: SNP: Fix kunmap_local() unmapping order
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260522-fix-sev-gmem-post-populate-v2-4-3f196bfad5a1@google.com>
References: <20260522-fix-sev-gmem-post-populate-v2-0-3f196bfad5a1@google.com>
In-Reply-To: <20260522-fix-sev-gmem-post-populate-v2-0-3f196bfad5a1@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779489969; l=1450;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=VX9xGFMfWmL5HGm1mHjTtC4xZdzEbomljfer0iqVaEQ=;
 b=FqRXMgrQiAATjkjhq9UmxaSoOh/KdH1pj4wJC6/RV9QZBUUylr1KVoYNH10wJ+vMYjySGY31T
 vsuLxRE2R4rB46qc+v+yCu6HlrhMPWNheqkAo+RrKYcFSmJtFBBLGKU
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mappings created with kmap_local_page() or kmap_local_pfn() must be
unmapped in the reverse order they were acquired, following a LIFO
(last-in, first-out) stack-based approach.

In sev_gmem_post_populate(), src_vaddr is mapped first and dst_vaddr is
mapped second. The current code incorrectly calls kunmap_local() for
src_vaddr before dst_vaddr.

Swap the kunmap_local() calls to ensure the mappings are released in the
correct order.

Fixes: 2a62345b3052 ("KVM: guest_memfd: GUP source pages prior to populating guest memory")
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 arch/x86/kvm/svm/sev.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/x86/kvm/svm/sev.c b/arch/x86/kvm/svm/sev.c
index 2f254c447923e..dbf75326a40f4 100644
--- a/arch/x86/kvm/svm/sev.c
+++ b/arch/x86/kvm/svm/sev.c
@@ -2360,8 +2360,8 @@ static int sev_gmem_post_populate(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 
 		memcpy(dst_vaddr, src_vaddr, PAGE_SIZE);
 
-		kunmap_local(src_vaddr);
 		kunmap_local(dst_vaddr);
+		kunmap_local(src_vaddr);
 	}
 
 	ret = rmp_make_private(pfn, gfn << PAGE_SHIFT, PG_LEVEL_4K,
@@ -2396,8 +2396,8 @@ static int sev_gmem_post_populate(struct kvm *kvm, gfn_t gfn, kvm_pfn_t pfn,
 
 		memcpy(src_vaddr, dst_vaddr, PAGE_SIZE);
 
-		kunmap_local(src_vaddr);
 		kunmap_local(dst_vaddr);
+		kunmap_local(src_vaddr);
 	}
 
 out:

-- 
2.54.0.794.g4f17f83d09-goog

