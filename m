From: Ackerley Tng <ackerleytng@google.com>
Date: Sun, 30 Aug 2026 17:25:13 -0700
Subject: [PATCH v12 12/45] KVM: guest_memfd: Always fault from guest_memfd
 if in-place conversion is enabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-gmem-inplace-conversion-v12-12-85e5fd25252a@google.com>
References: <20260830-gmem-inplace-conversion-v12-0-85e5fd25252a@google.com>
In-Reply-To: <20260830-gmem-inplace-conversion-v12-0-85e5fd25252a@google.com>
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 jmattson@google.com, jthoughton@google.com, michael.roth@amd.com, 
 oupton@kernel.org, pankaj.gupta@amd.com, qperret@google.com, 
 rick.p.edgecombe@intel.com, rientjes@google.com, shivankg@amd.com, 
 steven.price@arm.com, willy@infradead.org, wyihan@google.com, 
 yan.y.zhao@intel.com, forkloop@google.com, pratyush@kernel.org, 
 suzuki.poulose@arm.com, aneesh.kumar@kernel.org, liam@infradead.org, 
 Paolo Bonzini <pbonzini@redhat.com>, 
 Sean Christopherson <seanjc@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Borislav Petkov <bp@alien8.de>, 
 Dave Hansen <dave.hansen@linux.intel.com>, x86@kernel.org, 
 "H. Peter Anvin" <hpa@zytor.com>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Shuah Khan <shuah@kernel.org>, Vishal Annapurve <vannapurve@google.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Barry Song <baohua@kernel.org>, 
 Axel Rasmussen <axelrasmussen@google.com>, Yuanchu Xie <yuanchu@google.com>, 
 Wei Xu <weixugc@google.com>, Youngjun Park <youngjun.park@lge.com>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Kiryl Shutsemau <kas@kernel.org>, Baoquan He <baoquan.he@linux.dev>, 
 Jason Gunthorpe <jgg@ziepe.ca>, John Hubbard <jhubbard@nvidia.com>, 
 Peter Xu <peterx@redhat.com>, tarunsahu@google.com, 
 Randy Dunlap <rdunlap@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Fuad Tabba <fuad.tabba@linux.dev>, 
 Vlastimil Babka <vbabka@kernel.org>, Baoquan He <baoquan.he@linux.dev>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788135915; l=4450;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=X0oHuYGMuEMc+mIS2D25NifHLJhyfzoCyNVUkFKAoCE=;
 b=EtQxw+QEVWJoZlS70xZzAwu5ZPYmJaQfBkoC/h5utIHwFISWqanhlhfA/RfJ33NDQYkw7Y4kT
 x0KHakJQKe3CW/InZ0fVH/Fv/TtLlWGt56gk9mRZgklUQUp8zSa/3yP
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If a guest_memfd memslot is created but the guest_memfd does not have the
GUEST_MEMFD_FLAG_MMAP set, KVM still fulfils guest faults by looking up the
memslot's userspace_addr.

Set KVM_MEMSLOT_GMEM_ONLY if in-place conversion is enabled so that the
guest_memfd's memory will be used for both shared and private memory. With
in-place conversion, guest_memfd will be the only backing memory for the
memslot.

No validation is performed to require userspace_addr to be a mapping from
the associated guest_memfd because even after validation, userspace is free
to remap something else at the provided userspace_addr.

userspace_addr will still be used by functions like kvm_read_guest(), and
if userspace_addr does not match up with the corresponding memory in the
memslot's guest_memfd (whether userspace_addr points to the wrong offset or
some non-guest_memfd memory, etc), that is a user error.

Requiring both shared and private memory to come from the only associated
guest_memfd simplifies invalidation in stage 2 page tables. On a PUNCH_HOLE
operation on a guest_memfd, the invalidation is now guaranteed to be
invalidating only memory mapped from the given guest_memfd.

Suggested-by: Sean Christopherson <seanjc@google.com>
Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
 Documentation/virt/kvm/api.rst | 22 ++++++++++++++--------
 virt/kvm/guest_memfd.c         |  2 +-
 2 files changed, 15 insertions(+), 9 deletions(-)

diff --git a/Documentation/virt/kvm/api.rst b/Documentation/virt/kvm/api.rst
index 90a29424c54c8..668886f50024d 100644
--- a/Documentation/virt/kvm/api.rst
+++ b/Documentation/virt/kvm/api.rst
@@ -6381,10 +6381,16 @@ mapping for userspace_addr is not required to be valid/populated at the time of
 KVM_SET_USER_MEMORY_REGION2, e.g. shared memory can be lazily mapped/allocated
 on-demand.
 
-When mapping a gfn into the guest, KVM selects shared vs. private, i.e consumes
-userspace_addr vs. guest_memfd, based on the state in guest_memfd, which is the
-sole authority on private vs. shared memory.  See :ref:`KVM_CREATE_GUEST_MEMFD`
-to find out more about the creation-time shared/private status.
+When mapping a gfn into the guest, guest faults are always serviced from
+guest_memfd regardless of whether memory is shared or private.  KVM determines
+shared vs. private based on the state in guest_memfd, which is the sole
+authority on private vs. shared memory.  See :ref:`KVM_CREATE_GUEST_MEMFD` to
+find out more about the creation-time shared/private status.
+
+userspace_addr is expected to be the mmap()-ed address corresponding to the
+right offset within the guest_memfd. Any mismatch between userspace_addr and
+guest_memfd is not validated and is a user error. userspace_addr is only used
+for host-side guest accesses such as kvm_read_guest().
 
 If in-place conversion is disabled, KVM selects shared vs. private, i.e consumes
 userspace_addr vs. guest_memfd, based on the gfn's KVM_MEMORY_ATTRIBUTE_PRIVATE
@@ -6490,10 +6496,10 @@ specified via KVM_CREATE_GUEST_MEMFD.  Currently defined flags:
                                page tables. Private memory cannot.
   ============================ ================================================
 
-When the KVM MMU performs a PFN lookup to service a guest fault and the backing
-guest_memfd has the GUEST_MEMFD_FLAG_MMAP set, then the fault will always be
-consumed from guest_memfd, regardless of whether it is a shared or a private
-fault.
+When the KVM MMU performs a PFN lookup to service a guest fault, the fault will
+always be consumed from guest_memfd, regardless of whether it is a shared or a
+private fault (unless in-place conversion is disabled and the backing
+guest_memfd does not have the GUEST_MEMFD_FLAG_MMAP flag set).
 
 See KVM_SET_USER_MEMORY_REGION2 for additional details.
 
diff --git a/virt/kvm/guest_memfd.c b/virt/kvm/guest_memfd.c
index 0afe1468d2d9d..e41802944756b 100644
--- a/virt/kvm/guest_memfd.c
+++ b/virt/kvm/guest_memfd.c
@@ -746,7 +746,7 @@ int kvm_gmem_bind(struct kvm *kvm, struct kvm_memory_slot *slot,
 	 */
 	WRITE_ONCE(slot->gmem.file, file);
 	slot->gmem.pgoff = start;
-	if (kvm_gmem_supports_mmap(inode))
+	if (gmem_in_place_conversion || kvm_gmem_supports_mmap(inode))
 		slot->flags |= KVM_MEMSLOT_GMEM_ONLY;
 
 	xa_store_range(&f->bindings, start, end - 1, slot, GFP_KERNEL);

-- 
2.55.0.897.gb25b4bd76c-goog

