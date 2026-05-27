From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:24 -0700
Subject: [PATCH RFC 12/12] Documentation: KVM: Focus acquisition order
 section on preventing deadlocks
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-12-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=1268;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=AsaYP57e05UmB20wkvz2ac8XwGdrnAvpcLv6/4UIzSY=;
 b=/yniIvnWn4q3kTWgqqaHndF4zOmwJDCk3stxZhB8gkrHCBDyaGRJ5dgMjaI2FXpf3UqwGtqcK
 qwfmNRwB7dXCwu4GyjoIDe3TPOjN73gTHFFrxKkm4DEZmg1MiFAmPWK
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Now that the first sentence is already described in more detail in the new
section on synchronization while managing guest faults, drop the first
sentence.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 8 +++-----
 1 file changed, 3 insertions(+), 5 deletions(-)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index 0663ccfe0633d..f26ea3acd0b70 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -26,11 +26,9 @@ The acquisition orders for mutexes are as follows:
 
 - vcpu->mutex is taken outside kvm->slots_lock and kvm->slots_arch_lock
 
-- kvm->mn_active_invalidate_count ensures that pairs of
-  invalidate_range_start() and invalidate_range_end() callbacks
-  use the same memslots array.  kvm->slots_lock and kvm->slots_arch_lock
-  are taken on the waiting side when modifying memslots, so MMU notifiers
-  must not take either kvm->slots_lock or kvm->slots_arch_lock.
+- kvm->slots_lock and kvm->slots_arch_lock are taken on the waiting side when
+  modifying memslots, so MMU notifiers must not take either kvm->slots_lock or
+  kvm->slots_arch_lock.
 
 For SRCU:
 

-- 
2.54.0.823.g6e5bcc1fc9-goog

