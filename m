From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH 0/3] guest_memfd fixes for bind and populate
Date: Fri, 22 May 2026 13:45:06 -0700
Message-Id: <20260522-fix-sev-gmem-post-populate-v1-0-9fc8d6437b65@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFLAEGoC/x3MywrCMBCF4Vcps3YwRoyXVxEXSTtpgyYNmRgKp
 e/e0c2BDw7/CkwlEMOjW6FQCxzmJDgdOugnm0bCMIhBK23URWv0YUGmhmOkiHnmKpO/H1sJ7dk
 48levzP0GEsiF5P2PP19iZ5nQFZv66Zd8t3hMtFTYth3MFdoahwAAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779482720; l=1493;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=f8qzetz34djYUY8P15NPDcr/IAQAFdGPjF0QHjGshe8=;
 b=9rI/i+NUcIJGIRRuU71ssW12eUDlO0B9KL8Jtm8isUGo5UNz1jdJmpC1Qa9+ewkCCnRObODbS
 TkxI12RqUEiAlaR9Mee4GXxZCobzFvyba+mWgRCRTF5fxpiVNR7upCN
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is a group of fixes for the bind and populate flows for
guest_memfd, and fixes some issues reported by Sashiko after reviewing the
guest_memfd in-place conversions series [1] and another fixup series Sean
posted [3].

Sashiko pointed out

+ Possible write to read-only page [1]
    => Fixed in patch 1
+ Signed integer overflow in kvm_gmem_bind() twice: [2][3]
    => Fixed in patch 2
+ Unchecked xa_store_range() [3]
    => Fixed in patch 3

[1] https://lore.kernel.org/all/CA+EHjTwrygfMrZZSw4y7-ry8fidW2x0C7iuF2Q=dnPNHUmNtUg@mail.gmail.com/
[2] https://lore.kernel.org/all/CA+EHjTxcadguOfOo7RpJVtAzcY5JAFZTbrAT_wcN6akMi8gCUg@mail.gmail.com/
[3] https://lore.kernel.org/all/20260522180530.EE9101F00A3E@smtp.kernel.org/

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (1):
      KVM: guest_memfd: Handle errors from xa_store_range() when binding

Sean Christopherson (2):
      KVM: guest_memfd: Use write permissions when GUP-ing source pages
      KVM: guest_memfd: Fix possible signed integer overflow

 arch/x86/kvm/svm/sev.c   |  1 +
 arch/x86/kvm/vmx/tdx.c   |  2 +-
 include/linux/kvm_host.h |  3 ++-
 virt/kvm/guest_memfd.c   | 18 ++++++++++--------
 virt/kvm/kvm_mm.h        |  2 +-
 5 files changed, 15 insertions(+), 11 deletions(-)
---
base-commit: b7fbe9a1bf9ee6c967ef77d366ca58c35fcf1887
change-id: 20260522-fix-sev-gmem-post-populate-a36bef7f0698

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

