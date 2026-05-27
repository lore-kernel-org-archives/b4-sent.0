From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:18 -0700
Subject: [PATCH RFC 06/12] Documentation: KVM: Have actual headings for
 exceptions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-6-4fe8b602ff47@google.com>
References: <20260527-kvm-locking-docs-v1-0-4fe8b602ff47@google.com>
In-Reply-To: <20260527-kvm-locking-docs-v1-0-4fe8b602ff47@google.com>
To: Paolo Bonzini <pbonzini@redhat.com>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Tianrui Zhao <zhaotianrui@loongson.cn>, Bibo Mao <maobibo@loongson.cn>, 
 Huacai Chen <chenhuacai@kernel.org>, WANG Xuerui <kernel@xen0n.name>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, Fuad Tabba <tabba@google.com>, 
 vannapurve@google.com, x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, loongarch@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=1576;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=omLCISL/Cs1+39lE29MDupCtm4WwTzGw7vDPKSySNYo=;
 b=hprWgud3QVI1IKRiPLGBIYGbG2occ7We7PsN9/HJiCR/0rZEaqlqEP39d5vxdyx0Gpkil7MJV
 OZNw5t9xeHOAhY9qTRJPjQQyqfcQdggNLhA0ARfSxEm8DrBNtkxx0PE
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Exceptions documented are described but without headings, making it hard to
identify where each exception description ended.

Use actual headings at a lower level than that of the heading used for
Exception to improve readability.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index 5161636cec481..fc4537a7659a9 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -65,7 +65,8 @@ The general rule in KVM is that any modification to shadow page tables
 (and their entries (SPTEs)) must be protected by ``kvm->mmu_lock``,
 with the exceptions described below.
 
-Fast page fault:
+2.1. Fast page fault
+^^^^^^^^^^^^^^^^^^^^
 
 Fast page fault is the fast path which fixes the guest page fault out of
 the mmu-lock on x86. Currently, the page fault can be fast in one of the
@@ -217,7 +218,8 @@ Since the spte is "volatile" if it can be updated out of mmu-lock, we always
 atomically update the spte and the race caused by fast page fault can be avoided.
 See the comments in spte_needs_atomic_update() and mmu_spte_update().
 
-Lockless Access Tracking:
+2.2 Lockless Access Tracking
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 
 This is used for Intel CPUs that are using EPT but do not support the EPT A/D
 bits. In this case, PTEs are tagged as A/D disabled (using ignored bits), and

-- 
2.54.0.823.g6e5bcc1fc9-goog

