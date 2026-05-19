From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v3 0/6] Open HugeTLB allocation routine for more generic
 use
Date: Mon, 18 May 2026 17:19:39 -0700
Message-Id: <20260518-hugetlb-open-up-v3-0-e14b302477f8@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJusC2oC/2XO0QqDIBiG4VsJj/eHc2VtR7uP0YG5P5OVhposo
 nufBYPBDt+D7+FbiUen0ZNbthKHUXttTYrLKSOyF0Yh6GdqwijjtKQF9LPCMLRgJzQwT4CiFTU
 tq3NLryStJoedfh/io0ndOTtC6B2Kw5E2osvPVUXrsuCc5UqHXMgXugGXYNRdWasGzKUdd63XP
 li3HPci283vE/73JDKgUDMuqCw7Vnfy12q2bfsAJrdSeu0AAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779149988; l=5617;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=bPcX7aY0Fv5p+iHJmDPvkygslezqtdpkp18CjrGXqeo=;
 b=xtN4dDlhtwURik8shZJTiObc9tr0HJGnHBGTfMUDXaOXq3Gy199/XnGMAjV9DOZqhIQQOEfLX
 X5mt6sImpmjAbMV4xcqGvQzplXhMDJurY+WAq/lDUOdeKNg9Ha3Anpk
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

+ Clarified comment on when alloc_hugetlb_folio() chooses to dequeue a page
  as requested by Oscar
    + After refactoring out hugetlb_alloc_folio(), hugetlb_alloc_folio()
      just acts on alloc_flags, so I think the reason for dequeueing is
      sufficiently clear, so I dropped the comment
+ Introduced concept of an interpreted mempolicy (struct mempolicy_interpreted).
    + dequeue_hugetlb_folio() and alloc_buddy_hugetlb_folio() are actually
      operating on an interpreted mempolicy, which comprises nid, nodemask, and
      a mempolicy_mode. mempolicy_mode tells the allocation function how to
      interpret the provided nid and nodemask.
    + I think mempolicy_interpreted could be generalized further outside of
      hugetlb. I think every caller of policy_nodemask() will eventually use the
      information in interpreted mempolicy to make the allocation.
    + Let me know if this makes sense, and if I should go ahead to do more
      refactoring!

Oscar, in my responses to v2, I agreed with your idea of an allocation ctxt, but
after doing some initial refactoring, I think the ctxt isn't really an
allocation context, I felt like I was just putting all the parameters for
hugetlb_alloc_folio() into a struct to get named parameters in C.

Here's my rationale for hugetlb_alloc_folio()'s parameters:

+ hstate
+ subpool
   + I think it makes sense to explicitly provide above two as parameters since
     these are always required for allocation of a hugetlb folio. subpool can be
     NULL, but we do want the caller to explicitly pass something in so subpool
     accounting can be performed within hugetlb_alloc_folio().
+ interpreted mempolicy
   + This summarizes what node the folio should be allocated from.
+ gfp
   + gfp is used in a few ways, relating to the actual allocation and zone to
     allocate from:
       1. It was used to interpret the mempolicy, if there was something
          requested in the gfp.
       2. It is used to determine which zone to allocate from in
          dequeue_hugetlb_folio()
       3. A modified version is used in alloc_buddy_hugetlb_folio() if
          MPOL_PREFERRED_MANY, otherwise it is used as-is to allocate a hugetlb
          folio.
    + I retained gfp as a separate parameter, and not part of
      mempolicy_interpreted, because after the mempolicy is interpreted, gfp is
      no longer used in relation to mempolicy to determine which node to
      allocate on.
+ allocation flags
    + I implemented Oscar's suggestion partially in allocation flags, which will
      allow us to add more allocation knobs without adding more parameters to
      hugetlb_alloc_folio().

[1] https://lore.kernel.org/all/cover.1747264138.git.ackerleytng@google.com/T/
[2] https://github.com/googleprodkernel/linux-cc/tree/wip-gmem-conversions-hugetlb-restructuring-12-08-25

RFC v1: https://lore.kernel.org/all/bb35a69a-5be9-45f5-a557-1902487a1bc2@linux.dev/
v2: https://lore.kernel.org/r/20260506-hugetlb-open-up-v2-0-826a0c5f28fc@google.com

---
Ackerley Tng (6):
      mm: hugetlb: Consolidate interpretation of gbl_chg within alloc_hugetlb_folio()
      mm: hugetlb: Move mpol interpretation out of alloc_buddy_hugetlb_folio_with_mpol()
      mm: hugetlb: Move mpol interpretation out of dequeue_hugetlb_folio_vma()
      mm: hugetlb: Use error variable in alloc_hugetlb_folio
      mm: hugetlb: Move mem_cgroup_charge_hugetlb() earlier in allocation
      mm: hugetlb: Refactor out hugetlb_alloc_folio()

 include/linux/hugetlb.h        |  19 ++++
 include/uapi/linux/mempolicy.h |   2 +-
 mm/hugetlb.c                   | 246 +++++++++++++++++++++++------------------
 3 files changed, 157 insertions(+), 110 deletions(-)
---
base-commit: 4d3a2a466b8d68d852a1f3bbf11204b718428dc4
change-id: 20260504-hugetlb-open-up-eaba80571b09

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

