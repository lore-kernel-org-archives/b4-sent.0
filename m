From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v4 0/6] Open HugeTLB allocation routine for more generic
 use
Date: Thu, 02 Jul 2026 09:21:44 -0700
Message-Id: <20260702-hugetlb-open-up-v4-0-d53cefcccf34@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABiQRmoC/2XOwY6DIBSF4VdpWA/mighMV32PySyQuSAZKwaR1
 BjfvWgySSddnsX58m9kxuhxJtfLRiJmP/swlsE/LsT0enRI/U/ZhAET0AKn/eIwDR0NE450mSj
 qTitoZd3BJymvKaL1j1P8+i7bxnCnqY+oT8eEjLGqpQTVciFY5XyqtPnFOOCaRndzIbgBKxPuh
 9b7OYW4nnmZHeZfiXgryYwCVUxoMK1lyppX60jJzQtQq3egKQDWvGuAcSmt+gfs+/4Ef5oKAy4
 BAAA=
X-Change-ID: 20260504-hugetlb-open-up-eaba80571b09
To: Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 David Hildenbrand <david@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, fvdl@google.com, 
 jiaqiyan@google.com, joshua.hahnjy@gmail.com, jthoughton@google.com, 
 mhocko@kernel.org, michael.roth@amd.com, pasha.tatashin@soleen.com, 
 pbonzini@redhat.com, peterx@redhat.com, pratyush@kernel.org, 
 rick.p.edgecombe@intel.com, rientjes@google.com, roman.gushchin@linux.dev, 
 seanjc@google.com, shakeel.butt@linux.dev, shivankg@amd.com, 
 vannapurve@google.com, yan.y.zhao@intel.com, Zi Yan <ziy@nvidia.com>, 
 Matthew Brost <matthew.brost@intel.com>, Rakie Kim <rakie.kim@sk.com>, 
 Byungchul Park <byungchul@sk.com>, Gregory Price <gourry@gourry.net>, 
 Ying Huang <ying.huang@linux.alibaba.com>, 
 Alistair Popple <apopple@nvidia.com>, Dan Williams <djbw@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783009310; l=3720;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=hiTTHL9a0qLiWbd6zy0olFhlRuJG9+JDT8dd4m9jteg=;
 b=ERg9hmAD6VrUmgCkE7oQ5DfH9+yxr8RuhcVr2UAd2eaQ+8HZRPQw0bazPfS2q/LlF2fW2V599
 hzJIL49uXUdDJq94xDBCFKDgEq44hMo8g4reAYSPfrNULI/FotDk+5c
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

Andrew, thanks for nudging me to send a v4!

Oscar, you mentioned that you wanted to do a closer review on v3, hope you
find time to review v4 soon!

Changes in this revision:

+ Define gfp within hugetlb_alloc_folio() instead of having it as a
  parameter so users aren't able to override gfp arbitrarily as Oscar
  requested.
+ Addressed some of Sashiko's comments [4]. Some of the issues I didn't address
  were pre-existing issues. Since v3 of this series Sashiko was updated to
  actually send mails. I'd let Sashiko point them out again and then we should
  discuss those!

[1] https://lore.kernel.org/all/cover.1747264138.git.ackerleytng@google.com/T/
[2] https://github.com/googleprodkernel/linux-cc/tree/wip-gmem-conversions-hugetlb-restructuring-12-08-25
[3] https://lore.kernel.org/all/agqaUcVp_hwH-VXr@localhost.localdomain/
[4] https://sashiko.dev/#/patchset/20260518-hugetlb-open-up-v3-0-e14b302477f8@google.com

RFC v1: https://lore.kernel.org/all/bb35a69a-5be9-45f5-a557-1902487a1bc2@linux.dev/
v2: https://lore.kernel.org/r/20260506-hugetlb-open-up-v2-0-826a0c5f28fc@google.com
v3: https://lore.kernel.org/r/20260518-hugetlb-open-up-v3-0-e14b302477f8@google.com

---
Ackerley Tng (6):
      mm: hugetlb: Consolidate interpretation of gbl_chg within alloc_hugetlb_folio()
      mm: hugetlb: Move mpol interpretation out of alloc_buddy_hugetlb_folio_with_mpol()
      mm: hugetlb: Move mpol interpretation out of dequeue_hugetlb_folio_vma()
      mm: hugetlb: Use error variable in alloc_hugetlb_folio
      mm: hugetlb: Move mem_cgroup_charge_hugetlb() earlier in allocation
      mm: hugetlb: Refactor out hugetlb_alloc_folio()

 include/linux/hugetlb.h        |  18 +++
 include/uapi/linux/mempolicy.h |   2 +-
 mm/hugetlb.c                   | 269 ++++++++++++++++++++++++-----------------
 3 files changed, 175 insertions(+), 114 deletions(-)
---
base-commit: 4a50a141f05a8d1737661b19ee22ff8455b94409
change-id: 20260504-hugetlb-open-up-eaba80571b09

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

