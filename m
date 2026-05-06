From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v2 0/6] Open HugeTLB allocation routine for more generic
 use
Date: Wed, 06 May 2026 08:54:36 -0700
Message-Id: <20260506-hugetlb-open-up-v2-0-826a0c5f28fc@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADxk+2kC/x3MQQ6DIBBA0auYWReCRNR25T2aLpCOSKqMGdG0M
 d69xOVb/H/AihxwhUdxAOMe1kAxQ98KcKONHkV4Z4NWulZGVWLcPKapF7RgFNsi0Pa2VaYpe3W
 HXC2MQ/hex+cre2CaRRoZ7fVxtCPLsmlUa6q61tKHJK37IE/4S9F3nshPKB3NcJ5/DiQmdp8AA
 AA=
X-Change-ID: 20260504-hugetlb-open-up-eaba80571b09
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, fvdl@google.com, 
 jiaqiyan@google.com, joshua.hahnjy@gmail.com, jthoughton@google.com, 
 mhocko@kernel.org, michael.roth@amd.com, pasha.tatashin@soleen.com, 
 pbonzini@redhat.com, peterx@redhat.com, pratyush@kernel.org, 
 rick.p.edgecombe@intel.com, rientjes@google.com, roman.gushchin@linux.dev, 
 seanjc@google.com, shakeel.butt@linux.dev, shivankg@amd.com, 
 vannapurve@google.com, yan.y.zhao@intel.com, Dan Williams <djbw@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778082886; l=3086;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=tVd9R9UGaExwjc88058u0c2WJO0rxP5vN7hvHA7LEZY=;
 b=UT9hQwclJuvOCfr+MjB/cjc67EeWP/7MENcnlpbEQyxJp3v0qDjaR+YwsCdZjQac/YJ+l+dAQ
 44V3SnWKGdVC1wsVg3GJBjui8ZpTuFTfgpQqwUhn6QbVoQqZGRFAOqW
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

The motivation for this patch series is guest_memfd, which would like
to use HugeTLB as a generic source of huge pages but not adopt
HugeTLB's reservation at mmap() time.

By refactoring alloc_hugetlb_folio() and some dependent functions,
there is now an option to allocate HugeTLB folios without providing a
VMA. Specifically, HugeTLB allocation used to be dependent on the VMA
to

1. Look up reservations in the resv_map
2. Get mpol, stored at vma->vm_policy

This refactoring provides hugetlb_alloc_folio(), which focuses on just
the allocation itself, and associated memory and HugeTLB charging
(cgroups). alloc_hugetlb_folio() still handles reservations in the
resv_map and subpools.

Regarding naming, I'm definitely open to alternative names :) I chose
hugetlb_alloc_folio() because I'm seeing this function as a general
allocation function that is provided by the HugeTLB subsystem (hence
the hugetlb_ prefix). I'm intending for alloc_hugetlb_folio() to be
later refactored as a static function for use just by HugeTLB, and
HugeTLBfs should probably use hugetlb_alloc_folio() directly.

To see how hugetlb_alloc_folio() is used by guest_memfd, the most
recent patch series that uses this more generic HugeTLB allocation
routine is at [1], and a newer revision of that patch series is at
[2].

Independently of guest_memfd, I believe this change is useful in
simplifying alloc_hugetlb_folio(). alloc_hugetlb_folio() was so
coupled to a VMA that even HugeTLBfs allocates HugeTLB folios using a
pseudo-VMA.

Testing:

+ libhugetlbfs tests pass
+ ./tools/testing/selftests/mm/ksft_hugetlb.sh passes

Changes in this revision:

+ No longer reintroduces try-commit-cancel protocol for hugetlb's memcg charging.
    + "mm: memcontrol: eliminate the problem of dying memory cgroup
      for LRU folios" was merged, and memcg seems to be moving away
      from the try-commit-cancel protcol, with try_charge() no longer
      having any users [3].

[1] https://lore.kernel.org/all/cover.1747264138.git.ackerleytng@google.com/T/
[2] https://github.com/googleprodkernel/linux-cc/tree/wip-gmem-conversions-hugetlb-restructuring-12-08-25
[3] https://lore.kernel.org/all/bb35a69a-5be9-45f5-a557-1902487a1bc2@linux.dev/

---
Ackerley Tng (6):
      mm: hugetlb: Consolidate interpretation of gbl_chg within alloc_hugetlb_folio()
      mm: hugetlb: Move mpol interpretation out of alloc_buddy_hugetlb_folio_with_mpol()
      mm: hugetlb: Move mpol interpretation out of dequeue_hugetlb_folio_vma()
      mm: hugetlb: Use error variable in alloc_hugetlb_folio
      mm: hugetlb: Move mem_cgroup_charge_hugetlb() earlier in allocation
      mm: hugetlb: Refactor out hugetlb_alloc_folio()

 include/linux/hugetlb.h |   3 +
 mm/hugetlb.c            | 209 ++++++++++++++++++++++++++----------------------
 2 files changed, 117 insertions(+), 95 deletions(-)
---
base-commit: adc1e5c6203cf13fe05a1ead08edcb3d3a3baae8
change-id: 20260504-hugetlb-open-up-eaba80571b09

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

