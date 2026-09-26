From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH RFC 00/17] Allow guest_memfd to be created using a resource
 (pool) fd
Date: Fri, 25 Sep 2026 17:50:47 -0700
Message-Id: <20260925-gmem-tmpfs-backend-v1-0-d36159822d18@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOcWt2oC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyMT3fTc1FzdktyCtGLdpMTk7NS8FF0Dc9NUS0sDI0uTREMloMaCotS
 0zAqwodFKQW7OSrEQweLSpKzU5BKQcUq1tQA6Z2lUewAAAA==
X-Change-ID: 20260924-gmem-tmpfs-backend-075e990294a1
To: Hugh Dickins <hughd@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Sean Christopherson <seanjc@google.com>, 
 Paolo Bonzini <pbonzini@redhat.com>, David Hildenbrand <david@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Shuah Khan <shuah@kernel.org>, 
 vannapurve@google.com, erdemaktas@google.com, jxgao@google.com, 
 rientjes@google.com, fvdl@google.com, jthoughton@google.com, 
 tarunsahu@google.com, pratyush@kernel.org, fuad.tabba@linux.dev, 
 Gregory Price <gourry@gourry.net>, David Woodhouse <dwmw2@infradead.org>, 
 yan.y.zhao@intel.com, michael.roth@amd.com, suzuki.poulose@arm.com, 
 Christian Brauner <brauner@kernel.org>, Jason Gunthorpe <jgg@ziepe.ca>, 
 Nicolin Chen <nicolinc@nvidia.com>, Xu Yilun <yilun.xu@linux.intel.com>, 
 aik@amd.com, aneesh.kumar@kernel.org, Vlastimil Babka <vbabka@kernel.org>
Cc: kernel-team@android.com, kernel-team@meta.com, 
 linux-kernel@vger.kernel.org, linux-mm@kvack.org, kvm@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790383849; l=7712;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=uDkfCcxCODk5XvmjtQcG8AagV+2UQjKDO7MxHp1FCvA=;
 b=HwKKmE/PN2ll9X17SLMOv4txXTvmNEnD2EVCoqTAPOmsD+X4sgo+/1WErfxlEe+t8gIo8N0Ao
 2Y8GyT/R98vBSrtXrTWVcOHH9UnZotpnD8s8Yfln4MDD2Q9dfhmQc5+
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

== Motivation

guest_memfd is KVM's guest-first memory provider that was created for
CoCo VMs and will support all VMs.

Today, guest_memfd only supports the equivalent of anonymous
PAGE_SIZE-d memfd memory, and has a lot to catch up to (HugeTLBfs,
tmpfs, DAX, etc) since almost anything can be mmap()-ed and handed to
KVM in a memslot.

I'd like to find a generic interface that would fit different
providers.

== Overview

Think of guest_memfd as a permissions (shared/private) and
KVM-know-how layer wrapping memory allocated from some provider.

This RFC illustrates how a resource pool fd can be handed to
guest_memfd to describe how it should allocate memory.

I believe this is extensible to many different kinds of memory
providers. :)

I'd like to discuss this at LPC 2026's KVM MC [1]. See y'all there!

== How userspace will use this feature

Do one of these,

  resource_fd = fsmount();
  resource_fd = open("/root/of/mount");

Then hand it to KVM_CREATE_GUEST_MEMFD,

  gmem_fd = ioctl(KVM_CREATE_GUEST_MEMFD,
                  GUEST_MEMFD_FLAG_USE_RESOURCE, resource_fd);

And then use gmem_fd as before.

== How to become a provider?

Implement this in the provider's struct super_operations,

  struct guest_memfd_provider_operations {
          void *(*attach)(struct file *resource_file);
          void (*release)(void *provider);
          struct folio *(*alloc_folio)(void *provider, pgoff_t index,
                                       struct mempolicy *mpol);
          void (*invalidate_folio)(void *provider, struct folio *folio);
  };

And the existence of these ops when guest_memfd accesses resource_fd
will determine if the provider is supported.

One requirement of this design is to allow new providers at runtime.

== Questions you might have

=== Why implement in struct super_operations?

It's one of the options to allow guest_memfd to find ops, and for an
RFC I think this requires the least new code and makes a simpler
illustration.

We would progressively add support for kernel-internal providers by
implementing guest_memfd_provider_operations, and loadable filesystem
modules can also implement the ops and be picked up at runtime.

Another option would be to have some kind of registry. Please see
changelog of patch 1 for discussion of options.

=== What if my provider doesn't deal with pages?

Frank and David Woodhouse [2] have use cases for providers that use
PFNs, and this is definitely something a generic interface must
support.

Here are some options I can think of:

1. Don't define .alloc_folio(), instead define .alloc_pfn()
2. Refactor .alloc_folio() to .alloc_pfn()

Either way, I think guest_memfd should still be the primary manager of
the memory.

=== Why have guest_memfd be the primary manager of the memory?

==== For folio-based providers

I propose we allocate the folios based on how the allocator was
configured:

+ e.g. for tmpfs,
    + Use mount page size.
    + Respect mount size limits.
    + Use guest_memfd mpol and fall back to mount mpol.
        + Gregory, now you can set mpol upfront on a mount! [3])
+ Use all the config that your provider has for allocation, reuse all
  those interfaces that your provider already has to do the config so
  guest_memfd doesn't have to reinvent those.

Once allocated, follow guest_memfd's rules on:

+ Tracking number of allocated bytes for this guest_memfd
+ memcg charging
+ Mapping into stage 2 page tables
+ Shared/private conversions
+ memory failure handling
+ etc

For the above split, I had the provider allocate, and then insert the
folio into guest_memfd's filemap.

I think of guest_memfd as the primary manager in the sense that
folio->mapping points to guest_memfd's filemap, which will allow
guest_memfd to handle memory failure by guest_memfd's rules.

Memory failure handling by guest_memfd's rules is something core to
guest_memfd. When guest_memfd supports huge pages, we'd like to be
able to split and only unmap the very page with a memory failure from
stage 2, which will keep guests running longer.

The provider can perform more handling of memory failure; we could
work out the ordering between guest_memfd and the provider.

Other than memory failure, there are other users that use
folio->mapping to determine what action to take. For now AFAICT
guest_memfd doesn't support those, but maybe it will need to in
future.

==== For PFN-based providers

For PFN-based providers, guest_memfd can be taught to store PFNs in
the xarray (like DAX does, perhaps?).

=== But my provider must be able to revoke memory from the guest!

I think that can be achieved with a bidirectional .attach(), where the
provider saves a pointer to the guest_memfd instance.

When memory must be revoked, it can tell the guest_memfd instance to
invalidate the page from everywhere. This has the nice benefit that
guest_memfd already respects the KVM MMU invalidation protocol, so the
provider doesn't have to learn the protocol.

== About this RFC

I chose tmpfs because I think it's the closest provider to the
existing anonymous PAGE_SIZE folios that guest_memfd supports.

The patches in this RFC was written with the help of AI and with many
edits from me.

This was built on top of Sean's kvm-x86 coco branch.

[1] https://lpc.events/event/20/contributions/2551/
[2] https://lore.kernel.org/all/20260720111259.122911-1-dwmw2@infradead.org/
[3] https://lore.kernel.org/all/20260902194657.79075-1-gourry@gourry.net/

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (17):
      mm: shmem: Implement guest_memfd provider operations for tmpfs
      KVM: guest_memfd: Support provider folio allocation
      KVM: guest_memfd: Support provider folio invalidation
      KVM: guest_memfd: Add helper to attach resource provider file
      KVM: selftests: Add helper to create guest_memfd with a resource file
      KVM: selftests: Test negative validation of resource_fd argument
      KVM: selftests: Test rejection of unsupported filesystem for resource_fd
      KVM: selftests: Test rejection of tmpfs file for resource_fd
      KVM: selftests: Test rejection of swap tmpfs mounts
      KVM: selftests: Test rejection of hugepage tmpfs mounts
      KVM: selftests: Test guest_memfd with anonymous fsmount() tmpfs pool
      KVM: selftests: Test guest_memfd with mounted tmpfs root directory
      KVM: selftests: Test guest_memfd resource pool sharing across instances
      KVM: selftests: Test memory allocation against shared tmpfs resource pool
      KVM: selftests: Test that shared tmpfs resource pool size limit is respected
      KVM: selftests: Test guest execution with tmpfs-backed guest_memfd
      KVM: selftests: Document testing TODOs

 Documentation/virt/kvm/api.rst                 |  28 +-
 include/linux/fs/super_types.h                 |   4 +
 include/linux/guest_memfd.h                    |  29 ++
 include/linux/kvm_host.h                       |   2 +-
 include/uapi/linux/kvm.h                       |   5 +-
 mm/shmem.c                                     | 112 +++++++
 tools/include/uapi/linux/kvm.h                 |   5 +-
 tools/testing/selftests/kvm/guest_memfd_test.c | 404 +++++++++++++++++++++++--
 tools/testing/selftests/kvm/include/kvm_util.h |  23 +-
 virt/kvm/guest_memfd.c                         | 118 +++++++-
 10 files changed, 673 insertions(+), 57 deletions(-)
---
base-commit: 37e0791600e5f1e2837a270c885296a172f5825e
change-id: 20260924-gmem-tmpfs-backend-075e990294a1

Best regards,
--  
Ackerley Tng <ackerleytng@google.com>

