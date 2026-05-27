From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:13 -0700
Subject: [PATCH RFC 01/12] Documentation: KVM: Elaborate comment on
 kvm_usage_lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260527-kvm-locking-docs-v1-1-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=1798;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=1hH8Q0hBBnzb0IjHg5TBjPkm0Xu0Pb4r5XTBzAPfiqY=;
 b=fU+6+4GQIUI8X/J/BwojcC/g3/dZq9Cy1AdwRV6CsRk1oo420RJtTrBz08gADa92ThBWvtsKp
 1qPdl0HarVvDiP2oochMmaqZ8lzASO49loGKy3NHXUUaWuDuMpMpnn4
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original comment talks about cpus_read_lock() and kvm_usage_count, but
doesn't explain why they are related.

Elaborate comment on kvm_usage_lock to provide more context.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 19 +++++++++++++++++--
 1 file changed, 17 insertions(+), 2 deletions(-)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index 662231e958a07..5564c8b38b9cc 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -248,8 +248,23 @@ time it will be set using the Dirty tracking mechanism described above.
 :Arch:		any
 :Protects:	- kvm_usage_count
 		- hardware virtualization enable/disable
-:Comment:	Exists to allow taking cpus_read_lock() while kvm_usage_count is
-		protected, which simplifies the virtualization enabling logic.
+:Comment:       ``kvm_usage_count`` serves to deduplicate hardware
+    virtualization enabling and disabling requests from different VMs
+    being created.
+
+    Hardware virtualization enabling/disabling requires taking
+    ``cpus_read_lock()``.
+
+    ``kvm_lock`` used to also protect ``kvm_usage_count``, but other
+    parts of the Linux kernel holding ``cpus_read_lock()`` need to
+    call into KVM to ensure that VM state remains consistent with the
+    host's state. For example, when the CPU frequency changes, KVM is
+    notified. ``kvmclock_cpufreq_notifier()`` takes ``kvm_lock`` to
+    iterate ``vm_list``.
+
+    To decouple these, use different locks, ``kvm_lock`` for
+    ``vm_list`` and ``kvm_usage_lock`` for enabling/disabling hardware
+    virtualization.
 
 ``kvm->mn_invalidate_lock``
 ^^^^^^^^^^^^^^^^^^^^^^^^^^^

-- 
2.54.0.823.g6e5bcc1fc9-goog

