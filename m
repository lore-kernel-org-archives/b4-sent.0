From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v6 00/43] guest_memfd: In-place conversion support
Date: Thu, 07 May 2026 13:22:19 -0700
Message-Id: <20260507-gmem-inplace-conversion-v6-0-91ab5a8b19a4@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAHz0/GkC/3XOwY7CIBAG4FcxnJddHEptPfkexgMdhpasBQOGa
 EzffUEP7mbT45/M//3zYImio8T2mweLlF1ywZfQfmwYTtqPxJ0pmYGAVgAoPs40c+cvZ43EMfh
 MsXb4YIQZjOx3SmpW2pdI1t2e8vFU8qAT8SFqj1P1vvP85el2raeTS9cQ788fsqyF15zcytW5L
 LngyuIW9E4Qdv1hDGE80yeGmdW93PyCoF2HmgJRObPUK2Gt+QepN9RAtw6pApmuFR2iRQ3wB1q
 W5Qejh3ofbAEAAA==
X-Change-ID: 20260225-gmem-inplace-conversion-bd0dbd39753a
To: aik@amd.com, andrew.jones@linux.dev, binbin.wu@linux.intel.com, 
 brauner@kernel.org, chao.p.peng@linux.intel.com, david@kernel.org, 
 ira.weiny@intel.com, jmattson@google.com, jthoughton@google.com, 
 michael.roth@amd.com, oupton@kernel.org, pankaj.gupta@amd.com, 
 qperret@google.com, rick.p.edgecombe@intel.com, rientjes@google.com, 
 shivankg@amd.com, steven.price@arm.com, tabba@google.com, 
 willy@infradead.org, wyihan@google.com, yan.y.zhao@intel.com, 
 forkloop@google.com, pratyush@kernel.org, suzuki.poulose@arm.com, 
 aneesh.kumar@kernel.org, liam@infradead.org, 
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
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <bhe@redhat.com>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Youngjun Park <youngjun.park@lge.com>, Qi Zheng <qi.zheng@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Vlastimil Babka <vbabka@kernel.org>
Cc: kvm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, linux-mm@kvack.org, 
 linux-coco@lists.linux.dev, Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778185365; l=9937;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=kgKZO4h2eVvkn8wuMk3gXIDfRMzXQVLQ4LVyu2XGn7Y=;
 b=0V3uJDwYZJQjjlQTEBaaPZVgwbzAwCsO4IgutmnZuaAIID7tgmfFzi8w2geQSGLX0TRdm5Hfe
 wm6wCAgISEWAS1VEXjE6hrbwBOZO+uzpTMWCCdJjZXYiz704PVsBS2+
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is v6 of guest_memfd in-place conversion support, now out of RFC.

Up till now, guest_memfd supports the entire inode worth of memory being
used as all-shared, or all-private. CoCo VMs may request guest memory to be
converted between private and shared states, and the only way to support
that currently would be to have the userspace VMM provide two sources of
backing memory from completely different areas of physical memory.

pKVM has a use case for in-place sharing: the guest and host may be
cooperating on given data, and pKVM doesn't protect data through
encryption, so copying that given data between different areas of physical
memory as part of conversions would be unnecessary work.

This series also serves as a foundation for guest_memfd huge page
support. Now, guest_memfd only supports PAGE_SIZE pages, so if two sources
of backing memory are used, the userspace VMM could maintain a steady total
memory utilized by punching out the pages that are not used. When huge
pages are available in guest_memfd, even if the backing memory source
supports hole punching within a huge page, punching out pages to maintain
the total memory utilized by a VM would be introducing lots of
fragmentation.

In-place conversion avoids fragmentation by allowing the same physical
memory to be used for both shared and private memory, with guest_memfd
tracks the shared/private status of all the pages at a per-page
granularity.

The central principle, which guest_memfd continues to uphold, is that any
guest-private page will not be mappable to host userspace. All pages will
be mmap()-able in host userspace, but accesses to guest-private pages (as
tracked by guest_memfd) will result in a SIGBUS.

This series introduces a guest_memfd ioctl (not kvm, vm or vcpu, but
guest_memfd ioctl) that allows userspace to set memory
attributes (shared/private) directly through the guest_memfd. This is the
appropriate interface because shared/private-ness is a property of memory
and hence the request should be sent directly to the memory provider -
guest_memfd.

Tested with both CONFIG_KVM_VM_MEMORY_ATTRIBUTES enabled and disabled:

+ tools/testing/selftests/kvm/guest_memfd_test.c
+ tools/testing/selftests/kvm/pre_fault_memory_test.c
+ tools/testing/selftests/kvm/x86/guest_memfd_conversions_test.c
+ tools/testing/selftests/kvm/x86/private_mem_conversions_test.c
+ tools/testing/selftests/kvm/x86/private_mem_conversions_test.sh
+ tools/testing/selftests/kvm/x86/private_mem_kvm_exits_test.c

Updates for this revision:

+ Dropped everything to do with content modes (ZERO/PRESERVE) (thanks
  Michael and Sean!)
    + Discussed this at PUCK on 2026-05-06
    + guest_memfd was taking on too much complexity to try to paper
      over differences in how trusted firmware handle conversions
+ Addressed Liam's comments about usage of the maple_tree

TODOs

+ Resolve issue where guest_memfd_conversions_test, which uses the
  kselftest framework, doesn't perform teardown on assertion
  failure. Please see proposal at [9]
+ Test with TDX selftests. We're in the process of rebasing TDX selftests
  on this series and will post updates when that's tested.

I would like feedback on:

+ The use of private_mem_conversions_test.sh to run different options in
  private_mem_conversions_test. If this makes sense, I'll adjust the
  Makefile to have private_mem_conversions_test tested only via the script.

This series is based on kvm/next, and here's the tree for your convenience:

https://github.com/googleprodkernel/linux-cc/commits/guest_memfd-inplace-conversion-v6

Older series:

+ RFCv5 is at [8]
+ RFCv4 is at [7]
+ RFCv3 is at [6]
+ RFCv2 is at [5]
+ RFCv1 is at [4]
+ Previous versions of this feature, part of other series, are available at
  [1][2][3].

[1] https://lore.kernel.org/all/bd163de3118b626d1005aa88e71ef2fb72f0be0f.1726009989.git.ackerleytng@google.com/
[2] https://lore.kernel.org/all/20250117163001.2326672-6-tabba@google.com/
[3] https://lore.kernel.org/all/b784326e9ccae6a08388f1bf39db70a2204bdc51.1747264138.git.ackerleytng@google.com/
[4] https://lore.kernel.org/all/cover.1760731772.git.ackerleytng@google.com/T/
[5] https://lore.kernel.org/all/cover.1770071243.git.ackerleytng@google.com/T/
[6] https://lore.kernel.org/r/20260313-gmem-inplace-conversion-v3-0-5fc12a70ec89@google.com/T/
[7] https://lore.kernel.org/all/20260326-gmem-inplace-conversion-v4-0-e202fe950ffd@google.com/T/
[8] https://lore.kernel.org/r/20260428-gmem-inplace-conversion-v5-0-d8608ccfca22@google.com
[9] https://lore.kernel.org/all/20260414-selftest-global-metadata-v1-0-fd223922bc57@google.com/T/

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (25):
      KVM: x86/mmu: Bug the VM if gmem attributes are queried to determine max mapping level
      KVM: guest_memfd: Update kvm_gmem_populate() to use gmem attributes
      KVM: guest_memfd: Only prepare folios for private pages
      KVM: Move kvm_supported_mem_attributes() to kvm_host.h
      KVM: guest_memfd: Add base support for KVM_SET_MEMORY_ATTRIBUTES2
      KVM: guest_memfd: Ensure pages are not in use before conversion
      KVM: guest_memfd: Call arch invalidate hooks on conversion
      KVM: guest_memfd: Return early if range already has requested attributes
      KVM: guest_memfd: Advertise KVM_SET_MEMORY_ATTRIBUTES2 ioctl
      KVM: guest_memfd: Handle lru_add fbatch refcounts during conversion safety check
      KVM: guest_memfd: Use actual size for invalidation in kvm_gmem_release()
      KVM: guest_memfd: Determine invalidation filter from memory attributes
      KVM: TDX: Make source page optional for KVM_TDX_INIT_MEM_REGION
      KVM: selftests: Test basic single-page conversion flow
      KVM: selftests: Test conversion flow when INIT_SHARED
      KVM: selftests: Test conversion precision in guest_memfd
      KVM: selftests: Test conversion before allocation
      KVM: selftests: Convert with allocated folios in different layouts
      KVM: selftests: Test that truncation does not change shared/private status
      KVM: selftests: Test conversion with elevated page refcount
      KVM: selftests: Reset shared memory after hole-punching
      KVM: selftests: Provide function to look up guest_memfd details from gpa
      KVM: selftests: Make TEST_EXPECT_SIGBUS thread-safe
      KVM: selftests: Update private_mem_conversions_test to mmap() guest_memfd
      KVM: selftests: Add script to exercise private_mem_conversions_test

Michael Roth (1):
      KVM: SEV: Make 'uaddr' parameter optional for KVM_SEV_SNP_LAUNCH_UPDATE

Sean Christopherson (17):
      KVM: guest_memfd: Introduce per-gmem attributes, use to guard user mappings
      KVM: Rename KVM_GENERIC_MEMORY_ATTRIBUTES to KVM_VM_MEMORY_ATTRIBUTES
      KVM: Enumerate support for PRIVATE memory iff kvm_arch_has_private_mem is defined
      KVM: Stub in ability to disable per-VM memory attribute tracking
      KVM: guest_memfd: Wire up kvm_get_memory_attributes() to per-gmem attributes
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
      KVM: selftests: Check fd/flags provided to mmap() when setting up memslot
      KVM: selftests: Update private memory exits test to work with per-gmem attributes

 Documentation/virt/kvm/api.rst                     |  78 +++-
 .../virt/kvm/x86/amd-memory-encryption.rst         |  15 +-
 Documentation/virt/kvm/x86/intel-tdx.rst           |   4 +
 arch/x86/include/asm/kvm_host.h                    |   2 +-
 arch/x86/kvm/Kconfig                               |  15 +-
 arch/x86/kvm/mmu/mmu.c                             |  13 +-
 arch/x86/kvm/svm/sev.c                             |  18 +-
 arch/x86/kvm/vmx/tdx.c                             |  11 +-
 arch/x86/kvm/x86.c                                 |  13 +-
 include/linux/kvm_host.h                           |  53 ++-
 include/trace/events/kvm.h                         |   4 +-
 include/uapi/linux/kvm.h                           |  16 +
 mm/swap.c                                          |   2 +
 tools/testing/selftests/kvm/Makefile.kvm           |   5 +
 tools/testing/selftests/kvm/include/kvm_util.h     | 138 +++++-
 tools/testing/selftests/kvm/include/test_util.h    |  34 +-
 .../selftests/kvm/kvm_has_gmem_attributes.c        |  17 +
 tools/testing/selftests/kvm/lib/kvm_util.c         | 133 +++---
 tools/testing/selftests/kvm/lib/test_util.c        |   7 -
 .../kvm/x86/guest_memfd_conversions_test.c         | 487 +++++++++++++++++++++
 .../kvm/x86/private_mem_conversions_test.c         |  53 ++-
 .../kvm/x86/private_mem_conversions_test.sh        | 128 ++++++
 .../selftests/kvm/x86/private_mem_kvm_exits_test.c |  36 +-
 virt/kvm/Kconfig                                   |   3 +-
 virt/kvm/guest_memfd.c                             | 457 +++++++++++++++++--
 virt/kvm/kvm_main.c                                |  82 +++-
 26 files changed, 1636 insertions(+), 188 deletions(-)
---
base-commit: 6d35786de28116ecf78797a62b84e6bf3c45aa5a
change-id: 20260225-gmem-inplace-conversion-bd0dbd39753a

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

