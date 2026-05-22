From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v2 0/5] guest_memfd fixes for bind and populate
Date: Fri, 22 May 2026 15:46:05 -0700
Message-Id: <20260522-fix-sev-gmem-post-populate-v2-0-3f196bfad5a1@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK3cEGoC/42OQQ6DIBBFr2JYd1rFitpV79G4QByQVMQAJTbGu
 xc9QTc/ecmfN38jHp1GTx7ZRhxG7bWdE9BLRsTIZ4Wgh8SE5pTlFaUg9QoeIyiDBhbrQ4rlM/G
 AwEvWo6xlztqGJMHiMLVP+atL3HOP0Ds+i/FQvqO5zbiGozpqH6z7njNicRz89TEWkEMrRTOwe
 1n3rHoqa9WEV2EN6fZ9/wFiQLMA4AAAAA==
X-Change-ID: 20260522-fix-sev-gmem-post-populate-a36bef7f0698
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779489969; l=2251;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=YDqzzpOoMui2E3wv3kn89z0sp2AgvB3IklDsmhCEX4Q=;
 b=Ngg2QhvHi/U8GF86Timm1/2rbheXnWIovVJHbYVH1hNHPVJ7CSEYs/+n0l3b7i4rgyUyTPgHa
 +evnoqMAXBVBPSlaSdxCVGvTODD+H0oUHRSU7Iqbx/6sixkwY9QtsTj
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is a group of fixes for the bind and populate flows for
guest_memfd, and fixes some issues reported by Sashiko after reviewing the
guest_memfd in-place conversions series [1] and another fixup series Sean
posted [3].

Changes in v2:

+ Add patch 4 and 5 to fix more issues, see below
+ Also update stub for kvm_gmem_bind()

Sashiko pointed out

+ Possible write to read-only page [1]
    => Fixed in patch 1
+ Signed integer overflow in kvm_gmem_bind() twice: [2][3]
    => Fixed in patch 2
+ Unchecked xa_store_range() [3]
    => Fixed in patch 3
+ Ordering issue with kmap_* and kunmap_* in sev_gmem_post_populate() [4]
    => Fixed in patch 4
+ Ordering issue with kmap_* and kunmap_* in sev_gmem_post_populate() [5]
    => Fixed in patch 5

[1] https://lore.kernel.org/all/CA+EHjTwrygfMrZZSw4y7-ry8fidW2x0C7iuF2Q=dnPNHUmNtUg@mail.gmail.com/
[2] https://lore.kernel.org/all/CA+EHjTxcadguOfOo7RpJVtAzcY5JAFZTbrAT_wcN6akMi8gCUg@mail.gmail.com/
[3] https://lore.kernel.org/all/20260522180530.EE9101F00A3E@smtp.kernel.org/
[4] https://sashiko.dev/#/patchset/20260507-gmem-inplace-conversion-v6-0-91ab5a8b19a4%40google.com?part=21
[5] https://sashiko.dev/#/patchset/20260522-fix-sev-gmem-post-populate-v1-0-9fc8d6437b65%40google.com?part=1

v1: https://lore.kernel.org/r/20260522-fix-sev-gmem-post-populate-v1-0-9fc8d6437b65@google.com

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (3):
      KVM: guest_memfd: Handle errors from xa_store_range() when binding
      KVM: SNP: Fix kunmap_local() unmapping order
      KVM: SNP: Mark source page dirty in sev_gmem_post_populate

Sean Christopherson (2):
      KVM: guest_memfd: Use write permissions when GUP-ing source pages
      KVM: guest_memfd: Fix possible signed integer overflow

 arch/x86/kvm/svm/sev.c   |  6 ++++--
 arch/x86/kvm/vmx/tdx.c   |  2 +-
 include/linux/kvm_host.h |  3 ++-
 virt/kvm/guest_memfd.c   | 24 ++++++++++++++++--------
 virt/kvm/kvm_mm.h        |  4 ++--
 5 files changed, 25 insertions(+), 14 deletions(-)
---
base-commit: b7fbe9a1bf9ee6c967ef77d366ca58c35fcf1887
change-id: 20260522-fix-sev-gmem-post-populate-a36bef7f0698

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

