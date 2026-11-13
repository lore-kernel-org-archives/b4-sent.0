From: Kairui Song <kasong@tencent.com>
Subject: [PATCH RFC 0/8] mm/huge_memory: clean up and speed up large folio
 splitting
Date: Sat, 14 Nov 2026 05:26:16 +0800
Message-Id: <20261114-swap-thp-split-v1-0-dfa8d4fa448d@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS0NT3eLyxALdkowC3eKCnMwSXYM0C7MkU1OTJBOjVCWgpoKi1LTMCrC
 B0UpBbs5KsRDB4tKkrNTkEpBRUGVFqYWlQOtKIGpja2sBcGOPo4wAAAA=
X-Change-ID: 20260915-swap-thp-split-0f86b554b42e
To: linux-mm@kvack.org
Cc: David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Matthew Wilcox <willy@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Qi Zheng <qi.zheng@linux.dev>, Shakeel Butt <shakeel.butt@linux.dev>, 
 Barry Song <baohua@kernel.org>, Axel Rasmussen <axelrasmussen@google.com>, 
 Yuanchu Xie <yuanchu@google.com>, Wei Xu <weixugc@google.com>, 
 Baoquan He <baoquan.he@linux.dev>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, Zi Yan <ziy@nvidia.com>, 
 Nico Pache <nico.pache@linux.dev>, Ryan Roberts <ryan.roberts@arm.com>, 
 Dev Jain <dev.jain@arm.com>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794605194; l=3345;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=/AbmnhDe2IJOrI78TkMUD1kXfK1J0O/e9ZtX3/CBXHc=;
 b=ZvIY7X4nvjD93wMA1BdYlQtatOQkZhI09urInLIAqNDsnRzPPbovJU2IFJM/8GMfgHOgpdduy
 bFeZZpGL/5QDNi+NWOuQeujVOGwfqIr1SpMs/ffdtk2+JnI4XBof3iu
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

This series slghtly cleans up the large folio split path and reduces
its overhead: uniformly splitting PMD sized file folios to order 0
is over 20% faster.

I realize this might not be the best time for pushing more optimizations,
but I am posting this as an early RFC as it adds two helpers, folio_prev()
and xas_prev_canonical(), and uses them to walk the after-split folios
in reverse, saving a few local variables, avoiding a for-loop pitfall [1],
and publishing the folios with a single Xarray walk.

Walking backwards also changes the order the pieces are put on the LRU or
the reclaim list: they are now in ascending order instead of descending,
which is the actually intended order. The effect was not very
measurable though.

New code is mostly the two helpers and an Xarray selftest. The change to
mm/huge_memory.c is LOC-neutral.

Worth noting (not part of the series): I found these useful while
preparation for supporting all kinds of folio splitting folios in the
swap cache. I also tried to get rid of lruvec lock for the splitting,
or at least decouple the lock and reduce lock scope of it. It turns out,
not cleanly doable at this moment, and the main blocker is: MGLRU.
MGLRU will read a folio's size without holding a ref, solely depending
on the LRU lock to stabilize. To improve this, another rework of MGLRU's
reclaim progress is needed (which will also cover the problem fount by
the MGLRU-FG series that MGLRU sometime have a higher contention than
CLRU on reclaim isolation).

Testing
=======

Split overhead on a 32 vCPU x86-64 KVM guest, 31 GiB RAM, 4K base
pages, 2M THP.  Split a 1 GiB shmem file (512 PMD-sized folios)
uniformly to order 0 through /sys/kernel/debug/split_huge_pages and
time that single write with bash's `time`.  Medians over 12
interleaved rounds per kernel

Test script:
   mount -t tmpfs -o size=2G,huge=always tmpfs /mnt
   fallocate -l 1G /mnt/big
   time echo /mnt/big,0x0,0x40000,0 > /sys/kernel/debug/split_huge_pages
   rm -f /mnt/big
   umount /mnt

Result:
                        Before        After
real                    17 ms        13 ms   (-24%)
sys                     17 ms        13 ms   (-24%)

End to end test showed no regression.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Kairui Song (8):
      mm: add folio_prev()
      xarray: add xas_prev_canonical()
      mm/huge_memory: avoid an unnecessary folio size reading
      mm/huge_memory: walk the after-split file folios in reverse order
      mm/huge_memory: publish split folios by walking backwards
      mm/huge_memory: rearrange split routine handling for better optimization
      mm/huge_memory: walk the after-split anon folios in reverse order
      mm/huge_memory: walk the folios reversely for the release loop

 include/linux/mm.h     |  23 +++++++++++
 include/linux/xarray.h |  49 +++++++++++++++++++++++
 lib/test_xarray.c      |  97 +++++++++++++++++++++++++++++++++++++++++++++
 lib/xarray.c           |   8 ----
 mm/huge_memory.c       | 105 +++++++++++++++++++++++++------------------------
 5 files changed, 222 insertions(+), 60 deletions(-)
---
base-commit: fae273e48c398c56b819151a607a6c8792dadef0
change-id: 20260915-swap-thp-split-0f86b554b42e

Best regards,
--  
Kairui Song <kasong@tencent.com>

