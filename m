From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v13 00/44] guest_memfd: In-place conversion support
Date: Thu, 10 Sep 2026 16:55:26 -0700
Message-Id: <20260910-gmem-inplace-conversion-v13-0-dd6fbf94f4e1@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG9Do2oC/33T226cMBAG4FdBXNepPcYnrvoeVS8Ge7yLGmBrC
 EoU5d1jdhVBREFcGXk+jw//ezlSamks6+K9TDS3Yzv0eSDkj6L0V+wvxNqQf5TAQXMAxS4ddaz
 tb8/oifmhnyktRawJPDRBOqMklrn6lii2r3f69588bnAk1iTs/XXx/s7dz55ep2XqtR2nIb3dm
 5jlUvBYTgp5uNwsGWcqegFoOHnrfl2G4fJMT37oymW9udpAoI+hKkOUp0VyiscYdpBaoQrsMaQ
 yFKzm1vvoEWAH6RVS3BxDOkNOYKPQNsJhtYPMBgI4hkyGIPKIVDmtJN9BdoW0ONmaXToK4JSTy
 lgld5BbIXN2Ri5DUkWH5AEp7M9I8FWyZ4ck+H1zXlgiHWSDe0psqLMXIESmOAoVLBrn8D8UbCj
 JTyjIlFWkYgCVv+/UxyMXif695KRNj3CUHY0j3oNWFxys0Z6QKQOGgceKNYSBGamVI9SR/Lfns
 I1pXTz6+7rIfmCJppfUs9vCa1E5MAguOlPndHxlMjNdO9XFbJ4kSx5ymx+fPyXVBRgEAAA=
X-Change-ID: 20260225-gmem-inplace-conversion-bd0dbd39753a
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
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>, 
 Fuad Tabba <fuad.tabba@linux.dev>, Xiaoyao Li <xiaoyao.li@intel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789084533; l=8646;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=3xAm8x8BxRzgrAQrSXJX3gnFRneXWjklDL9ZXrCM6gA=;
 b=tBwALuhzAg1A20WwgjQXyyFKIY1ex8U5p5pDeeO9K/+7xIvJd7mdEmNUHHn+JEMBtMbo+WCcs
 /jqpzD96MFVDmtkwsJhys5mJeDZWb0Xhotl8vQrEiE9Jea5+I28Sxwc
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Here's v13. Thanks everyone for the comments and fast responses!
We're now at ~3 weeks to soft-close at 7.3-rc5.

v13 is based on 7.3-rc2 and:

+ Hugh's patch to export lru_cache_drain_for_folio()
+ Another series [1], which makes kvm_gmem_get_pfn() NOT return a
  refcounted page to KVM.

Here's everything stitched together for your convenience:

https://github.com/googleprodkernel/linux-cc/commits/guest_memfd-inplace-conversion-v13

Changes in v13:

+ Picked up Reviewed-bys
+ Fixed bug Fuad pointed out in "Ensure pages are not in use before
  conversion", and squashed the lru draining in, adopted Sean's
  suggestion.
+ Fixed documentation bug that Fuad pointed out in
  kernel-parameters.txt.

Here's v13 with tests:

https://github.com/googleprodkernel/linux-cc/commits/guest_memfd-inplace-conversion-coco-selftests-v13

Tested with both CONFIG_KVM_VM_MEMORY_ATTRIBUTES enabled and disabled:

+ tools/testing/selftests/kvm/guest_memfd_test.c
+ tools/testing/selftests/kvm/pre_fault_memory_test.c
+ tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
+ tools/testing/selftests/kvm/x86/private_mem_conversions_test.c
+ tools/testing/selftests/kvm/x86/private_mem_kvm_exits_test.c

[1] https://lore.kernel.org/all/20260826-gmem-no-return-page-v4-0-3bb9c1ddb4e3@google.com/

v12: https://lore.kernel.org/r/20260830-gmem-inplace-conversion-v12-0-85e5fd25252a@google.com
v11: https://lore.kernel.org/r/20260826-gmem-inplace-conversion-v11-0-0a15d8a799aa@google.com
v10: https://lore.kernel.org/r/20260807-gmem-inplace-conversion-v10-0-2fc18ee6d3ba@google.com
v9: https://lore.kernel.org/r/20260728-gmem-inplace-conversion-v9-0-35f9aec2aed2@google.com
v8: https://lore.kernel.org/r/20260618-gmem-inplace-conversion-v8-0-9d2959357853@google.com
v7: https://lore.kernel.org/r/20260522-gmem-inplace-conversion-v7-0-2f0fae496530@google.com
v6: https://lore.kernel.org/r/20260507-gmem-inplace-conversion-v6-0-91ab5a8b19a4@google.com
RFC v5: https://lore.kernel.org/r/20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com
RFC v4: https://lore.kernel.org/r/20260326-gmem-inplace-conversion-v4-0-e202fe950ffd@google.com
RFC v3: https://lore.kernel.org/r/20260313-gmem-inplace-conversion-v3-0-5fc12a70ec89@google.com
RFC v2: https://lore.kernel.org/r/cover.1770071243.git.ackerleytng@google.com
RFC v1: https://lore.kernel.org/r/cover.1760731772.git.ackerleytng@google.com

Previous versions of this feature, part of other series, are available at:

+ https://lore.kernel.org/all/bd163de3118b626d1005aa88e71ef2fb72f0be0f.1726009989.git.ackerleytng@google.com/
+ https://lore.kernel.org/all/20250117163001.2326672-6-tabba@google.com/
+ https://lore.kernel.org/all/b784326e9ccae6a08388f1bf39db70a2204bdc51.1747264138.git.ackerleytng@google.com/

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (22):
      KVM: Rename kvm_mem_is_private() to kvm_is_private_gfn()
      KVM: guest_memfd: Always fault from guest_memfd if in-place conversion is enabled
      KVM: guest_memfd: Pass mapping type filter to invalidation helper
      KVM: guest_memfd: Add base support for KVM_SET_MEMORY_ATTRIBUTES2
      KVM: guest_memfd: Ensure pages are not in use before conversion
      KVM: guest_memfd: Call arch make_shared callback for to-shared conversion
      KVM: guest_memfd: Return early if range already has requested attributes
      KVM: guest_memfd: Zero page while getting pfn
      KVM: TDX: Make source page optional for KVM_TDX_INIT_MEM_REGION
      KVM: selftests: Test basic single-page conversion flow
      KVM: selftests: Test conversion flow when INIT_SHARED
      KVM: selftests: Test conversion precision in guest_memfd
      KVM: selftests: Test conversion before allocation
      KVM: selftests: Convert with allocated folios in different layouts
      KVM: selftests: Test that truncation does not change shared/private status
      KVM: selftests: Add helpers to pin pages with CONFIG_GUP_TEST
      KVM: selftests: Test conversion with elevated page refcount
      KVM: selftests: Reset shared memory after hole-punching
      KVM: selftests: Provide function to look up guest_memfd details from gpa
      KVM: selftests: Make TEST_EXPECT_SIGBUS thread-safe
      KVM: selftests: Set up page size and alignment independently for guest_memfd
      KVM: selftests: Update private_mem_conversions_test for in-place conversions

Michael Roth (1):
      KVM: SEV: Make 'uaddr' parameter optional for KVM_SEV_SNP_LAUNCH_UPDATE

Sean Christopherson (21):
      KVM: guest_memfd: Optimize away conversion overheads via dead-code elimination
      KVM: guest_memfd: Use kvm_mem_is_private() when populating guest_memfd memory
      KVM: guest_memfd: Introduce per-gmem attributes, use to guard user mappings
      KVM: Rename KVM_GENERIC_MEMORY_ATTRIBUTES to KVM_VM_MEMORY_ATTRIBUTES
      KVM: Enumerate support for PRIVATE memory iff kvm_arch_has_private_mem is defined
      KVM: Rename memory attribute APIs to prepare for in-place gmem conversion
      KVM: Provide generic interface for checking memory private/shared status
      KVM: guest_memfd: Stub in ability to enable in-place shared<=>private conversion
      KVM: Consolidate private memory and guest_memfd ifdeffery in kvm_host.h
      KVM: guest_memfd: Invalidate both SHARED and PRIVATE mappings for in-place conversions
      KVM: Move KVM_VM_MEMORY_ATTRIBUTES config definition to x86
      KVM: Let userspace disable per-VM mem attributes, enable per-gmem attributes
      KVM: guest_memfd: Enable INIT_SHARED on guest_memfd for x86 Coco VMs
      KVM: selftests: Create gmem fd before "regular" fd when adding memslot
      KVM: selftests: Rename guest_memfd{,_offset} to gmem_{fd,offset}
      KVM: selftests: Add support for mmap() on guest_memfd in core library
      KVM: selftests: Add selftests global for guest memory attributes capability
      KVM: selftests: Add helpers for calling ioctls on guest_memfd
      KVM: selftests: Test that shared/private status is consistent across processes
      KVM: selftests: Provide common function to set memory attributes
      KVM: selftests: Update private memory exits test to work with per-gmem attributes

 Documentation/admin-guide/kernel-parameters.txt    |  25 +
 Documentation/virt/kvm/api.rst                     | 110 ++++-
 .../virt/kvm/x86/amd-memory-encryption.rst         |  14 +-
 Documentation/virt/kvm/x86/intel-tdx.rst           |   4 +
 arch/x86/include/asm/kvm-x86-ops.h                 |   2 +-
 arch/x86/include/asm/kvm_host.h                    |   9 +-
 arch/x86/kvm/Kconfig                               |  15 +-
 arch/x86/kvm/mmu/mmu.c                             |  28 +-
 arch/x86/kvm/svm/sev.c                             |  13 +-
 arch/x86/kvm/vmx/tdx.c                             |   8 +-
 arch/x86/kvm/x86.c                                 |  20 +-
 include/linux/kvm_host.h                           |  83 ++--
 include/trace/events/kvm.h                         |   6 +-
 include/uapi/linux/kvm.h                           |  16 +
 tools/testing/selftests/kvm/Makefile.kvm           |   1 +
 tools/testing/selftests/kvm/include/kvm_util.h     | 139 +++++-
 tools/testing/selftests/kvm/include/test_util.h    |  34 +-
 tools/testing/selftests/kvm/lib/kvm_util.c         | 222 +++++----
 tools/testing/selftests/kvm/lib/test_util.c        |   7 -
 .../kvm/x86/guest_memfd_conversions_test.c         | 512 +++++++++++++++++++++
 .../kvm/x86/private_mem_conversions_test.c         |  66 ++-
 .../selftests/kvm/x86/private_mem_kvm_exits_test.c |  36 +-
 virt/kvm/Kconfig                                   |   3 -
 virt/kvm/guest_memfd.c                             | 468 +++++++++++++++++--
 virt/kvm/kvm_main.c                                |  92 ++--
 25 files changed, 1642 insertions(+), 291 deletions(-)
---
base-commit: 5e036ce12de91c6fd674dad33b169c6150be2a7a
change-id: 20260225-gmem-inplace-conversion-bd0dbd39753a
prerequisite-message-id: 02876cea-5727-2ca4-bead-73659ea6fec4@google.com
prerequisite-patch-id: 28922a76dee80792da6e445a55cdbb4bedc85374
prerequisite-change-id: 20260818-gmem-no-return-page-614927a29f97:v4
prerequisite-patch-id: 38553271bcb80c17dbae29cef5c20bcf95e804f9
prerequisite-patch-id: 0d4b50926073ba4f5e5d8b2c0cdae8869a278863
prerequisite-patch-id: bf39277ddc12818fe562a006f31d7992e5c7d42a
prerequisite-patch-id: 74fe849c04c187074bd380e664e536a07076292d
prerequisite-patch-id: f92bdb4870dd7c1a2026fca1083e4400c2be11d8

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

