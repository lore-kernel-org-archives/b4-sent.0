From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:15 -0700
Subject: [PATCH RFC 03/12] Documentation: KVM: Consolidate notes about
 kvm->slots_lock and irq_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-3-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=1205;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=5xqYuflg/lHRaHVhIbofzsJqCQI4L326JDxGJuO8b0U=;
 b=/bIlnjfndGdNS+ll2dxYYvqLLoNppW84HDwXhvbpWFF04ZPlHUMWp75WsSLCcKYSYWt61B5P7
 mXli/FQOdC4BvZ0ynYtyfQjBM8Q6lsysXNUKDjZXn5ui6jUMED+c4jb
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the detail about ordering between kvm->slots_lock and kvm->irq_lock to
where the two locks are first mentioned.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index 1e8cbbe3ba706..67dd2066f6d98 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -21,12 +21,11 @@ The acquisition orders for mutexes are as follows:
 - kvm->lock is taken outside vcpu->mutex
 
 - kvm->lock is taken outside kvm->slots_lock and kvm->irq_lock
+    - kvm->slots_lock is taken outside kvm->irq_lock, though acquiring
+      them together is quite rare.
 
 - vcpu->mutex is taken outside kvm->slots_lock and kvm->slots_arch_lock
 
-- kvm->slots_lock is taken outside kvm->irq_lock, though acquiring
-  them together is quite rare.
-
 - kvm->mn_active_invalidate_count ensures that pairs of
   invalidate_range_start() and invalidate_range_end() callbacks
   use the same memslots array.  kvm->slots_lock and kvm->slots_arch_lock

-- 
2.54.0.823.g6e5bcc1fc9-goog

