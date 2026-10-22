From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH RFC v2 00/50] guest_memfd alternative providers
Date: Thu, 22 Oct 2026 16:27:32 -0700
Message-Id: <20261022-gmem-alternative-providers-v2-0-5dd1dc6c660a@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOWb2moC/yXMQQ6CMBBG4auQWdsEmiDq1sQDuDUuCvODY6SQa
 W1MCHen6vK9xbdQgAoCnYqFFEmCTD6H3RXUPZwfYIRzky3tviqr2gwjRuNeEepdlAQz65SEocH
 UfDxwY9G7likDs6KXzw+/0fVypvt/hnf7RBe/LK3rBtvYtEmDAAAA
X-Change-ID: 20261015-gmem-alternative-providers-5d98d72efabd
To: Alex Williamson <alex@shazbot.org>, Alexander Graf <graf@amazon.de>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, 
 Alexey Kardashevskiy <aik@amd.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "Aneesh Kumar K.V" <aneesh.kumar@kernel.org>, 
 Ashish Kalra <ashish.kalra@amd.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Baolu Lu <baolu.lu@linux.intel.com>, Bill Wendling <morbo@google.com>, 
 Borislav Petkov <bp@alien8.de>, Catalin Marinas <catalin.marinas@arm.com>, 
 Christian Brauner <brauner@kernel.org>, 
 =?utf-8?q?Christian_K=C3=B6nig?= <christian.koenig@amd.com>, 
 Connor Williamson <connordw@amazon.com>, 
 Dave Hansen <dave.hansen@linux.intel.com>, 
 Dave Jiang <dave.jiang@intel.com>, David Hildenbrand <david@kernel.org>, 
 David Rientjes <rientjes@google.com>, David Woodhouse <dwmw2@infradead.org>, 
 Erdem Aktas <erdemaktas@google.com>, Frank van der Linden <fvdl@google.com>, 
 Fred Griffoul <fgriffo@amazon.co.uk>, Fred Griffoul <griffoul@gmail.com>, 
 Gregory Price <gourry@gourry.net>, "H. Peter Anvin" <hpa@zytor.com>, 
 Hugh Dickins <hughd@google.com>, Ingo Molnar <mingo@redhat.com>, 
 Jacob Pan <jacob.pan@linux.microsoft.com>, 
 James Houghton <jthoughton@google.com>, Jan Kara <jack@suse.cz>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Jianxiong Gao <jxgao@google.com>, 
 Joerg Roedel <joro@8bytes.org>, Joey Gouly <joey.gouly@arm.com>, 
 John Starks <John.Starks@microsoft.com>, Jonathan Corbet <corbet@lwn.net>, 
 Justin Stitt <justinstitt@google.com>, Kevin Tian <kevin.tian@intel.com>, 
 Lorenzo Stoakes <ljs@kernel.org>, Marc Zyngier <maz@kernel.org>, 
 Michael Roth <michael.roth@amd.com>, Mike Rapoport <rppt@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolin Chen <nicolinc@nvidia.com>, Oliver Upton <oupton@kernel.org>, 
 Paolo Bonzini <pbonzini@redhat.com>, Pratyush Yadav <pratyush@kernel.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Robin Murphy <robin.murphy@arm.com>, 
 Samiullah Khawaja <skhawaja@google.com>, 
 Sean Christopherson <seanjc@google.com>, Shuah Khan <shuah@kernel.org>, 
 Steffen Eiden <seiden@linux.ibm.com>, Steven Price <steven.price@arm.com>, 
 Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Tarun Sahu <tarunsahu@google.com>, Thomas Gleixner <tglx@kernel.org>, 
 Tom Lendacky <thomas.lendacky@amd.com>, Tycho Andersen <tycho@kernel.org>, 
 Vishal Annapurve <vannapurve@google.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Will Deacon <will@kernel.org>, 
 Xu Yilun <yilun.xu@linux.intel.com>, Yan Zhao <yan.y.zhao@intel.com>, 
 Zenghui Yu <yuzenghui@huawei.com>, x86@kernel.org, 
 Shuah Khan <skhan@linuxfoundation.org>, Fuad Tabba <fuad.tabba@linux.dev>
Cc: kvm@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, llvm@lists.linux.dev, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.17-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792711664; l=14655;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=nFLgyN1Pj6noTRSjY5D6Pyoh6B9lcZYrtGYcU1wlCRQ=;
 b=+ex4O8Hy8Z1rn0M+v1cRMTTz9f9EtA8sIUs0kt9KKi1byJD+eSbNlioRHzexgnlScZYJKO984
 MvY5TLn4Xl+CHbolmC6A96XxDBHtKs23gemms+PMVFHWASLngjnzMfD
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Here's RFC v2 of guest_memfd alternative providers, continuing from "Allow
guest_memfd to be created using a resource (pool) fd", which I'm considering
RFC v1.

This RFC v2 is actually at least 2 series, so please don't be thrown off by the
number of patches. It's a lot of number of patches, but I've also taken a lot of
effort to make each patch understandable (hopefully not just to me) :).

The first 18 patches are largely the same as RFC v1 (only 5 patches, 13 selftest
patches!). Here are the main changes:

1. .attach() actually needs two params, both the gmem inode and the file being
   attached. This is needed for the "native" provider as (suggested in
   Fred/David Woodhouse's pair of series [1][2]). and for revocation from the
   provider (See patch "samples/kvm: Support dynamic revocation via
   kvm_gmem_revoke").
2. The guest_memfd_provider_operations are now attached to struct
   file_operations instead of struct super_operations. Using file_operations
   will allow guest_memfd to use resources that don't have a meaningful
   superblock (like Fred's memory provider sample).

Then we have a bunch of 10 patches beginning with a direct am of Fred's memory
provider sample (MPS), followed by a bunch of patches _removing_ features from
MPS to get a more focused subset of features. This bunch of patches ends with a
basic test for MPS to convince myself that it works.

I recommend jumping to the MPS selftest, which illustrates the trimmed feature set:

1. No need for memory to be set aside at boot time now. Instead, MPS_NEW_FILE
   allocates the requested size from CMA. For small file sizes for testing, this
   should be fine?
2. The CMA memory allocated at MPS file creation time stays for the entire
   lifetime of the MPS file.
3. MPS_SET_PRESENT remains so userspace can emulate the provider revoking
   memory. I removed all the donate/reclaim/move operations and child ownership
   tracking. IIUC from David's comments that the "move" (and other) operations
   are basically revoke then give.
4. MPS_GET_STATS remains as a testing tool, to check that MPS_SET_PRESENT
   worked, at least in terms of page counts.
5. No more MMAP_CAPABLE or not, I'm proposing that the provider should not
   provide any backdoor for userspace to access memory contents. All memory
   accesses should go via guest_memfd so guest_memfd can manage page tables
   based on shared/private state.

And then I added 13 patches adding PFN mode support for other providers.

PFN mode allows providers (like MPS) to provide PFNs via guest_memfd to all the
users/page tables (userspace, stage 2, and, in some later patch series,
IOMMUFD).

I'm thinking of PFN mode as a requirement for non-resource-pool-fds. The
distinction I came to realize is that if the resource fd represents a resource
_pool_, like tmpfs (or HugeTLBfs), the resource can be allocated from the pool
and can be fully owned by guest_memfd.

For something like MPS, the resource is not specially allocated for
guest_memfd. I wouldn't say the provider owns the resource, but I do I think
this is closer to David/Fred's model where the provider still tracks the memory,
especially wrt whether the provider owns a page vs when it is in use by
guest_memfd.

In this RFC, I made MPS track the offset to PFN mapping, and various operations
in guest_memfd rely on the provider's offset <-> PFN mapping.

In the 13 patches, I gradually update the various operations in guest_memfd to
work with PFNs:

1. kvm_gmem_get_pfn calls .get_pfn() on the provider.
2. kvm_gmem_fault_user_mapping calls .get_pfn() on the provider.
3. Converting to private stops checking refcounts (N/A for PFN providers)
4. Converting to shared calls into provider to look up PFN, and then calls CoCo
   reclaim on those PFNs.
5. fallocate on guest_memfd passes on the allocation request to the provider.
6. Hole punch on guest_memfd requires CoCo reclaim too.
7. Inode release/destruction requires CoCo reclaim too.
8. Truncation (hole punch or inode destruction) requires notifying the provider
   that guest_memfd is no longer using the memory (.put_pfn_range), so that now
   the provider knows it fully owns the memory.

And then I also added a kvm_gmem_revoke(), which is close but not the same as
punch_hole.

The provider and guest_memfd really need to coordinate. The provider can't zero
memory while guest_memfd is still using the memory, .put_pfn_range informs the
provider that guest_memfd is done using the memory. The provider can still
revoke memory anytime from guest_memfd.

Then I have 5 patches to implement PFN mode provider support for MPS, and
finally a selftest.

It was zeroing that pulled things together for me. At first, I wanted MPS to
manage all the zeroing. Pre-zeroing before any use, triggered from userspace, or
zeroing after use, where the VM can go ahead and shutdown first. I wanted to
have MPS support the write() syscall so userspace can directly zero the memory.

CoCo is a core part of guest_memfd. The write() syscall shouldn't be usable on
CoCo private memory, so I would need some kind of shared/private check from
MPS. KVM already has a shared/private check, but that check is not meant to be
stable, because the KVM MMU is so integrated with guest_memfd that before
committing the results of the shared/private check, KVM would check for KVM MMU
invalidations, and not commit the result if the result is stale.

Imo we cannot expect providers to respect the same invalidation protocol. The
alternative is to take the filemap_invalidate_lock, which guest_memfd uses to
protect the shared/private state. My take on this is that having any memory
access going to the provider call into guest_memfd is going to either result in
races or ABBA locking issues. Hence, imo the solution is to have a top-down flow
of all accesses through guest_memfd, and have guest_memfd orchestrate the
conversions and mappings in all the page tables (userspace or stage 2).

There was another thing about userspace faults. This RFC performs
vmf_insert_pfn() under filemap_invalidate_lock(), and this serializes things
with revocation requests coming from the provider. I'm relying on guest_memfd
coordinating both revocation and userspace accesses together with shared/private
conversions, and I think having every provider do that coordination would be a
lot to ask.

For this RFC, I didn't explicitly add any tracking in MPS for whether memory is
owned by MPS or currently in use by guest_memfd. I took a shortcut where
MPS_NEW_FILE would allocate fresh folios (zeroed) and .put_pfn_range()
notifications from guest_memfd would zero the memory. To allow MPS to be zeroed
from userspace, imo we would track owned by MPS/in-use in guest_memfd, and
direct accesses would only be permitted if owned by MPS. Owned/in-use is
distinct from absent/present, since an in-use range can still be marked absent
(forcing a revoke from guest_memfd). With the tracking, direct zeroing from
userspace (not through guest_memfd) would only be allowed if owned by MPS. For
this RFC, I zeroed in MPS after .put_pfn_range(), so that's also when the memory
is owned by MPS.

I previously proposed taking the PFN and storing it in the guest_memfd inode's
xarray, but I think that isn't useful. Storing the PFN in guest_memfd can't
indicate to MPS that the PFN is in-use, since a PFN is just some number, unlike
for pages where there's a refcount and metadata in struct page.

The remaining request from David/Fred that I haven't prototyped is the IOMMUFD
interaction. I briefly described how I think it would work in "samples/kvm:
Support dynamic revocation via kvm_gmem_revoke". Sami also pointed out to me
offline, and kind of mentioned in [3], that the IOMMU doesn't support faulting.
When guest_memfd does conversions to private, we'd have to zap from IOMMU (or
remap as private, for Confidential IO). This is the same as for stage 2, but
unlike stage 2, we can't rely on CPU faults to bring in shared pages. On a
conversion to shared, we'd have to map into IOMMU page tables.

Aneesh, thanks for your series [4], I haven't got a chance to look at it yet. I
will before I continue this prototype for IOMMU. I want to get feedback on this
part first.

If we agree the trimmed MPS implementation covers all the required MPS features,
I can squash the MPS changes so the next RFC won't have this many patches. :)

This was built on kvm/next, and the series is also available here for your
convenience:

https://github.com/googleprodkernel/linux-cc/tree/gmem-alternative-providers-rfc-v2

Testing: these pass:

+ ./tools/testing/selftests/kvm/mem_provider_sample_test
+ ./tools/testing/selftests/kvm/guest_memfd_test
+ ./tools/testing/selftests/kvm/x86/guest_memfd_conversions_test

RFC v1: https://lore.kernel.org/all/20260925-gmem-tmpfs-backend-v1-0-d36159822d18@google.com/

[1] David Woodhouse's RFC v2 https://lore.kernel.org/all/20260720111259.122911-1-dwmw2@infradead.org/
[2] Fred's RFC v2: https://lore.kernel.org/all/20261006183235.16576-1-griffoul@gmail.com/
[3] Sami on IOMMUFD https://lore.kernel.org/all/atkO08eCJzLX6R58@google.com/
[4] Aneesh: guest_memfd + VFIO: https://lore.kernel.org/all/20261017073149.1303738-1-aneesh.kumar@kernel.org/

---
Ackerley Tng (49):
      KVM: guest_memfd: Split folio allocation and insertion in kvm_gmem_get_folio
      KVM: guest_memfd: Route folio allocation through native provider operations
      mm: shmem: Implement guest_memfd provider operations for tmpfs
      KVM: guest_memfd: Support provider folio invalidation
      KVM: guest_memfd: Support using resource provider
      KVM: selftests: Add helper to create guest_memfd with a resource file
      KVM: selftests: Test negative validation of resource_fd argument
      KVM: selftests: Test rejection of unsupported filesystem for resource_fd
      KVM: selftests: Test rejection of memfd for resource_fd
      KVM: selftests: Test rejection of swap tmpfs mounts
      KVM: selftests: Test rejection of hugepage tmpfs mounts
      KVM: selftests: Test rejection of regular file in tmpfs mount
      KVM: selftests: Test guest_memfd with tmpfs resource pool
      KVM: selftests: Test guest_memfd resource pool sharing across instances
      KVM: selftests: Test memory allocation against shared tmpfs resource pool
      KVM: selftests: Test that shared tmpfs resource pool size limit is respected
      KVM: selftests: Test guest execution with tmpfs-backed guest_memfd
      KVM: selftests: Document testing TODOs
      KVM: selftests: Test guest_memfd conversions with tmpfs backing
      samples/kvm: Remove donate, reclaim, and move operations from sample provider
      samples/kvm: Remove readonly support from sample provider
      samples/kvm: Remove child ownership tracking from sample provider
      samples/kvm: Remove MPS_SETUP support from sample provider
      samples/kvm: Remove MMAP_CAPABLE flag from sample provider
      samples/kvm: Remove fixed address and length module parameters
      samples/kvm: Remove mem_provider_ops from sample provider
      samples/kvm: Make provider files independent of a root pool
      samples/kvm: Move set_present ioctl from device to provider file
      KVM: selftests: Add basic test for sample memory provider
      KVM: guest_memfd: Support getting PFNs for stage 2 from providers
      KVM: guest_memfd: Refactor error handling in kvm_gmem_fault_user_mapping
      KVM: guest_memfd: Support mmap and user fault handling in PFN mode
      KVM: guest_memfd: Skip checking outstanding references in PFN mode
      KVM: guest_memfd: Support converting to shared in PFN mode
      KVM: guest_memfd: Support preallocating memory via fallocate in PFN mode
      KVM: guest_memfd: Clamp hole punch range to inode size
      KVM: guest_memfd: Support reclaim during hole punch in PFN mode
      KVM: guest_memfd: Support arch reclaim on inode destruction in PFN mode
      KVM: guest_memfd: Support put_pfn_range provider op in PFN mode
      KVM: guest_memfd: Add TODO for memory failure handling in PFN mode
      KVM: guest_memfd: Allow attaching PFN-backed providers
      KVM: guest_memfd: Export kvm_gmem_revoke for provider-driven revocation
      KVM: selftests: Test flag dependency of PFN_MODE on USE_RESOURCE
      samples/kvm: Implement attach and release provider ops in sample provider
      samples/kvm: Implement get_pfn provider operation
      samples/kvm: Implement put_pfn_range provider operation
      samples/kvm: Support dynamic revocation via kvm_gmem_revoke
      samples/kvm: Implement lookup_pfn_range provider operation
      KVM: selftests: Test guest_memfd conversions with sample memory provider backing

Fred Griffoul (1):
      samples/kvm: Add a memory provider sample

 Documentation/virt/kvm/api.rst                     |  34 +-
 arch/x86/kvm/Makefile                              |   3 +-
 fs/libfs.c                                         |   4 +-
 include/linux/fs.h                                 |   6 +
 include/linux/guest_memfd.h                        |  68 ++++
 include/linux/kvm_host.h                           |   3 +-
 include/uapi/linux/kvm.h                           |   6 +-
 mm/shmem.c                                         | 126 ++++++
 samples/Kconfig                                    |  11 +
 samples/Makefile                                   |   1 +
 samples/kvm/Makefile                               |   2 +
 samples/kvm/mem_provider_sample.c                  | 339 ++++++++++++++++
 samples/kvm/mem_provider_sample.h                  |  54 +++
 tools/include/uapi/linux/kvm.h                     |   6 +-
 tools/testing/selftests/kvm/Makefile.kvm           |   1 +
 tools/testing/selftests/kvm/guest_memfd_test.c     | 277 +++++++++++++-
 tools/testing/selftests/kvm/include/kvm_util.h     |  24 +-
 tools/testing/selftests/kvm/include/test_util.h    |   2 +
 tools/testing/selftests/kvm/lib/kvm_util.c         |   9 +-
 tools/testing/selftests/kvm/lib/test_util.c        |  56 +++
 .../selftests/kvm/mem_provider_sample_test.c       | 147 +++++++
 .../kvm/x86/guest_memfd_conversions_test.c         |  91 ++++-
 virt/kvm/guest_memfd.c                             | 424 +++++++++++++++++++--
 23 files changed, 1635 insertions(+), 59 deletions(-)
---
base-commit: 7e60162b16f9da0d2fa83da5c1723b6853a0ac1d
change-id: 20261015-gmem-alternative-providers-5d98d72efabd

Best regards,
--  
Ackerley Tng <ackerleytng@google.com>

