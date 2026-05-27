From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:14 -0700
Subject: [PATCH RFC 02/12] Documentation: KVM: Consolidate notes about
 cpu_read_lock() and kvm_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-2-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=1641;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=g71wqImwKNA2W1d9aVPqMV7Uh2kOm/LmCZhr5oX9KEc=;
 b=tp9bB0rR932atLXHEHhRX+PGjo7Pn9ZSpQ3wo1LyHKIYaRGe/jBPOdCQfNdTxOyq8w9lMnUj6
 msk2J3WyEuOBBi3gyIsz2NhLOdOGjuUnCy0Ux1Nd5x9Qy5tyibGzGaj
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the detail about cpu_read_lock() and kvm_lock to where the acquisition
order is mentioned.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 12 +++++-------
 1 file changed, 5 insertions(+), 7 deletions(-)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index 5564c8b38b9cc..1e8cbbe3ba706 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -10,6 +10,11 @@ KVM Lock Overview
 The acquisition orders for mutexes are as follows:
 
 - cpus_read_lock() is taken outside kvm_lock
+    - Taking cpus_read_lock() outside of kvm_lock is problematic,
+      despite it being the official ordering, as it is quite easy to
+      unknowingly trigger cpus_read_lock() while holding kvm_lock.
+      Use caution when walking vm_list, e.g. avoid complex operations
+      when possible.
 
 - kvm_usage_lock is taken outside cpus_read_lock()
 
@@ -28,13 +33,6 @@ The acquisition orders for mutexes are as follows:
   are taken on the waiting side when modifying memslots, so MMU notifiers
   must not take either kvm->slots_lock or kvm->slots_arch_lock.
 
-cpus_read_lock() vs kvm_lock:
-
-- Taking cpus_read_lock() outside of kvm_lock is problematic, despite that
-  being the official ordering, as it is quite easy to unknowingly trigger
-  cpus_read_lock() while holding kvm_lock.  Use caution when walking vm_list,
-  e.g. avoid complex operations when possible.
-
 For SRCU:
 
 - ``synchronize_srcu(&kvm->srcu)`` is called inside critical sections

-- 
2.54.0.823.g6e5bcc1fc9-goog

