From: Ackerley Tng <ackerleytng@google.com>
Subject: [PATCH v5 0/3] Consolidate memory policy interpretation in
 alloc_hugetlb_folio()
Date: Mon, 03 Aug 2026 06:37:57 -0700
Message-Id: <20260803-hugetlb-mpol-interpretation-v5-0-af2b7089f8a9@google.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALaZcGoC/x2MSQqAMAwAvyI5G4jWDb8iHlyiBrRKW0UQ/27wO
 AwzD3h2wh7q6AHHl3jZrUIeRzAsnZ0ZZVSGlNKCKjK4nDOHtcft2FcUG9gdjkMXtMNkKBImQ6X
 pM9CDmknu/9607/sBe6OuEm0AAAA=
X-Change-ID: 20260803-hugetlb-mpol-interpretation-1c61e03073b4
To: Alistair Popple <apopple@nvidia.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Byungchul Park <byungchul@sk.com>, David Hildenbrand <david@kernel.org>, 
 Gregory Price <gourry@gourry.net>, Joshua Hahn <joshua.hahnjy@gmail.com>, 
 Matthew Brost <matthew.brost@intel.com>, 
 Muchun Song <muchun.song@linux.dev>, Oscar Salvador <osalvador@suse.de>, 
 Rakie Kim <rakie.kim@sk.com>, Ying Huang <ying.huang@linux.alibaba.com>, 
 Zi Yan <ziy@nvidia.com>, erdemaktas@google.com, fvdl@google.com, 
 jiaqiyan@google.com, jthoughton@google.com, mhocko@kernel.org, 
 michael.roth@amd.com, pasha.tatashin@soleen.com, pbonzini@redhat.com, 
 peterx@redhat.com, pratyush@kernel.org, rick.p.edgecombe@intel.com, 
 rientjes@google.com, roman.gushchin@linux.dev, seanjc@google.com, 
 shakeel.butt@linux.dev, shivankg@amd.com, vannapurve@google.com, 
 yan.y.zhao@intel.com, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, 
 Ackerley Tng <ackerleytng@google.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785764284; l=2055;
 i=ackerleytng@google.com; s=20260225; h=from:subject:message-id;
 bh=F8YOycuO3n9pyOBJlzGLYA0VTNzGJrpqDpl6r2YRxhs=;
 b=/81mVPLrmqdt8S3FtL95+RIaQasW+MEisG4xehIhpdk2HXO5eFPXLPMjy5Uwdv433hzfM/vc/
 892yhYS4rbuDoLrWjmm5vw+7DS7oD3htmhFX7j4Oo4nPApGYQQ8G4U5
X-Developer-Key: i=ackerleytng@google.com; a=ed25519;
 pk=sAZDYXdm6Iz8FHitpHeFlCMXwabodTm7p8/3/8xUxuU=
X-Endpoint-Received: by B4 Relay for ackerleytng@google.com/20260225 with auth_id=649
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series is the first 3 patches, split out from "Open HugeTLB
allocation routine for more generic use" [1].

I'm splitting these 3 patches into this separate series, and continuing as
v5 from [1] to avoid being blocked on addressing pre-existing
bugs. (Sashiko's reviews on [1] revealed quite a few pre-existing bugs,
which is separately being addressed in [2].)

These 3 patches have been reviewed and can be merged first. (Thank you
Andrew!) The other 3 patches in [1] will probably build on [2], so I'd like
to leave those to later.

In this v5, the only change is to the first patch - I improved the wording
of the comment just above the call to dequeue_hugetlb_folio_vma() in
alloc_hugetlb_folio().

[1] https://lore.kernel.org/all/20260702-hugetlb-open-up-v4-0-d53cefcccf34@google.com/T/
[2] https://lore.kernel.org/all/20260722-hugetlb-alloc-failure-fixes-v4-0-88e8b81970dc@google.com/T/

Testing:

+ libhugetlbfs tests pass
+ tools/testing/selftests/mm/ksft_hugetlb.sh passes

RFC v1: https://lore.kernel.org/all/bb35a69a-5be9-45f5-a557-1902487a1bc2@linux.dev/
v2: https://lore.kernel.org/r/20260506-hugetlb-open-up-v2-0-826a0c5f28fc@google.com
v3: https://lore.kernel.org/r/20260518-hugetlb-open-up-v3-0-e14b302477f8@google.com
v4: https://lore.kernel.org/r/20260702-hugetlb-open-up-v4-0-d53cefcccf34@google.com

Signed-off-by: Ackerley Tng <ackerleytng@google.com>
---
Ackerley Tng (3):
      mm: hugetlb: Consolidate interpretation of gbl_chg within alloc_hugetlb_folio()
      mm: hugetlb: Move mpol interpretation out of alloc_buddy_hugetlb_folio_with_mpol()
      mm: hugetlb: Move mpol interpretation out of dequeue_hugetlb_folio_vma()

 include/uapi/linux/mempolicy.h |   2 +-
 mm/hugetlb.c                   | 110 +++++++++++++++++++++++------------------
 2 files changed, 62 insertions(+), 50 deletions(-)
---
base-commit: 075b74841bd0065a3bda3440873c747938e69b68
change-id: 20260803-hugetlb-mpol-interpretation-1c61e03073b4

Best regards,
--
Ackerley Tng <ackerleytng@google.com>

