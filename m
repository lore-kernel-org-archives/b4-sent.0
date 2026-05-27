From: Ackerley Tng <ackerleytng@google.com>
Date: Wed, 27 May 2026 08:33:21 -0700
Subject: [PATCH RFC 09/12] Documentation: KVM: Document synchronization for
 managing guest faults
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260527-kvm-locking-docs-v1-9-4fe8b602ff47@google.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779896001; l=6122;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=qtMOxyeP5ch21YYzClGkI6coJJOBcrx7UDfHl0oxiyE=;
 b=ZLCGPfSxzOWhzxer3lPOoW8Xf+IoErNOQmSifHUvrPQo82wBll8m7eGZttpVwVQqj7yjyti43
 78hYb4H5CmGDNYj5SKX4oT3LEEtKjKf4ovfwqD7TgaDcawPtUY/OgDc
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document how synchronization is used while managing guest faults centrally
so code comments can point users at a central place.

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/locking.rst | 108 +++++++++++++++++++++++++++++++++++++
 1 file changed, 108 insertions(+)

diff --git a/Documentation/virt/kvm/locking.rst b/Documentation/virt/kvm/locking.rst
index f12664443e913..0663ccfe0633d 100644
--- a/Documentation/virt/kvm/locking.rst
+++ b/Documentation/virt/kvm/locking.rst
@@ -339,3 +339,111 @@ time it will be set using the Dirty tracking mechanism described above.
     cpu_hotplug_lock is held, e.g. from cpufreq_boost_trigger_state(), and many
     operations need to take cpu_hotplug_lock when loading a vendor module, e.g.
     updating static calls.
+
+4. Synchronization while managing guest faults
+----------------------------------------------
+
+This section explains the intersection of these synchronization mechanisms:
+
+- ``kvm->srcu`` (for memslots)
+- ``kvm->mmu_invalidate_*`` (pending invalidations)
+- ``kvm->mn_*`` (synchronization for ``kvm->mmu_invalidate_*``)
+
+4.1 Overview
+^^^^^^^^^^^^
+
+KVM resolves guest page faults by translating the Guest Frame Number (GFN) into
+a Page Frame Number (PFN) via memslots and then populating its shadow page
+tables with the resulting mapping.
+
+While handling the guest page fault, KVM must ensure a consistent view of the
+active memslots container, so KVM takes ``srcu_read_lock(&kvm->srcu);``.
+
+Guest page fault handling can race with some request from host userspace to
+invalidate shadow page tables. These requests originate from a few places, such
+as
+
+1. MMU Notifiers: KVM registers callbacks with the kernel’s memory management
+   subsystem to know when there are changes to mappings in the host userspace
+   page tables.
+2. Memslot Updates: The host userspace VMM, such as QEMU may use the
+   ``KVM_SET_USER_MEMORY_REGION`` ioctl to add, delete, or move a memslot. KVM
+   must zap the affected shadow page tables to ensure the guest doesn't access
+   stale mappings.
+3. Memory Attribute Changes: The ``KVM_SET_MEMORY_ATTRIBUTES`` ioctl allows
+   userspace to change attributes for a range of guest memory (e.g., setting a
+   range as "private" for Confidential Computing). This also requires
+   invalidating existing shadow mappings.
+
+When such a race occurs, KVM optimistically allows the faulting logic to
+proceed, but just before committing the fault, KVM will check for a pending
+invalidation, and retry the fault process if there is a pending invalidation
+affecting the GFN where the fault occurred.
+
+4.2 Tracking pending invalidations with ``kvm->mmu_invalidate*`` fields
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+A "pending invalidation" is determined using a combination of
+
+- ``kvm->mmu_invalidate_in_progress``
+- ``kvm->mmu_invalidate_range_start`` and ``kvm->mmu_invalidate_range_end``
+- ``kvm->mmu_invalidate_seq``
+
+``is_page_fault_stale()`` shows how the above fields are used to determine if
+the page fault is stale and requires a retry.
+
+To protect the above combination of fields, a lock is used, which is the
+``kvm->mmu_lock``.
+
+4.2.1 Derived information vs pending invalidations
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Generally, the result of any information derived from GFN aka page
+attribute/page metadata lookups may race with invalidations. Here are some
+examples of lookups:
+
+- ``host_pfn_mapping_level()`` uses memslot information to find the mapping
+  level of pages in host userspace page tables. If there's an invalidation, the
+  pages that were mapped would no longer be mapped and hence the mapping level
+  result would be stale.
+
+There are several ways to ensure valid results:
+
+- Check ``mmu_invalidate_retry_gfn()`` after grabbing the result, before
+  consuming it. In this case, ``mmu_lock`` doesn't need to be held during the
+  lookup, but it does need to be held while checking the MMU notifier. KVM's
+  guest page fault handling uses this option.
+- Hold ``mmu_lock`` AND ensure there is no in-progress MMU notifier invalidation
+  event for the hva. This can be done by explicit checking the MMU notifier or
+  by ensuring that KVM already has a valid mapping that covers the
+  hva. ``kvm_mmu_recover_huge_pages()`` uses this option.
+
+4.3 Further optimization: ignoring invalidations if there is no matching memslot
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+Invalidation is only really required when the invalidated memory range overlaps
+with some memslot. Without a matching memslot, the invalidation request could
+actually just be ignored. Hence, KVM only updates the ``kvm->mmu_invalidate_*``
+fields and takes ``kvm->mmu_lock`` if it finds a matching memslot.
+
+This creates another problem: if memslots are updated while there is an ongoing
+invalidation, then the updates to the fields and the lock would be imbalanced.
+
+4.4 Synchronization for invalidation lock/fields: ``kvm->mn_*``
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+
+To make sure the updates to the invalidation lock/fields are balanced, KVM has a
+further layer of synchronization. ``kvm_swap_active_memslots()`` enforces that
+changes to memslots are only committed once all pending invalidations are
+complete.
+
+In other words, ``kvm->mn_*`` ensures the following does not happen:
+
+1. Some memslot existed, causing a pending invalidation request to be recorded
+   in the ``kvm->mmu_invalidate_*`` fields
+2. Memslot got removed, so the invalidation request was never removed from the
+   ``kvm->mmu_invalidate_*`` fields.
+
+In addition, ``kvm_swap_active_memslots()`` also enforces that changes to
+memslots are complete before doing ``synchronize_srcu(&kvm->srcu)`` to make sure
+running readers of the old memslots container are done before freeing it.

-- 
2.54.0.823.g6e5bcc1fc9-goog

