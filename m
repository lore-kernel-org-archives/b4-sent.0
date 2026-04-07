From: Kairui Song <kasong@tencent.com>
Subject: [PATCH RFC 0/2] mm, swap: fix swapin race that causes inaccurate
 memcg accounting
Date: Tue, 07 Apr 2026 22:55:41 +0800
Message-Id: <20260407-swap-memcg-fix-v1-0-a473ce2e5bb8@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEwNz3eLyxALd3NTc5HTdtMwKXcuUJIOk5GTjtERzMyWgpoKiVKAw2MB
 opSA3Z6VYiGBxaVJWanIJyCil2loA+uYQK3cAAAA=
X-Change-ID: 20260407-swap-memcg-fix-9db0bcc3fa76
To: linux-mm@kvack.org
Cc: Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <bhe@redhat.com>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Alexandre Ghiti <alex@ghiti.fr>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Hugh Dickins <hughd@google.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 Chuanhua Han <hanchuanhua@oppo.com>, linux-kernel@vger.kernel.org, 
 cgroups@vger.kernel.org, Kairui Song <kasong@tencent.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775573744; l=5405;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=ktiFYUkm17rtWG9ixEvpBIbYQmlh9KYi2e+f5EL5XCo=;
 b=4buYa029bKRDja+FudcwHiadO4RPbc7haNQ9UhhSEB6duzxw3I44ZRV4k0i+0hQXiX0dnEc5j
 Gkfn3V+rOu8CBGklC4jLMUdhig4dBZdcjwMZoWpvGy1ZQEwwSOWBEM3
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While doing code inspection, I noticed there is a long-existing issue
THP swapin may got charged into the wrong memcg since commit
242d12c981745 ("mm: support large folios swap-in for sync io devices").
And a recent fix made it a bit worse.

The error seem not serious. The worst that could happen is slightly
inaccurate memcg accounting as the charge will go to an unexpected but
somehow still relevant memcg. The chance is seems extremely low.
This issue will be fixed (and found during the rebase of) swap table P4
but may worth a separate fix. Sending as RFC first in case I'm missing
anything, or I'm overlooking the result, or overthinking about it.

And recent commit 9acbe135588e ("mm/swap: fix swap cache memcg
accounting") extended this issue for ordinary swap too (see patch 1 in
this series). The chance is still extremely low and doesn't seem to have
a significant negative result.

The problem occurs when swapin tries to allocate and charge a swapin
folio without holding any lock or pinning the swap slot first. It's
possible that the page table or mapping may change. Another thread may
swap in and free these memory, the swap slots are also freed. Then if
another mem cgroup faulted these memory again, thing get messy.

Usually, this is still fine since the user of the charged folio -
swapin, anon or shmem, will double check if the page table or mapping
is still the same and abort if not. But the PTE or mapping entry could
got swapped out again using the same swap entry. Now the page table or
mapping does look the same. But the swapout is done after the resource
is owned by another cgroup (e.g. by MADV & realloc), then, back to the
initial caller the start the swapin and charged the folio, it can keep
using the old charged folio, which means we chaged into a wrong cgroup.

The problem is similar to what we fixed with commit 13ddaf26be324
("mm/swap: fix race when skipping swapcache"). There is no data
corruption since IO is guarded by swap cache or the old HAS_CACHE
bit in commit 242d12c981745 ("mm: support large folios swap-in for sync
io devices").

The chance should be extremely low, it requires multiple cgroups to hit
a set of rare time windows in a row together, so far I haven't found a
good way to reproduce it, but in theory it is possible, and at least
looks risky:

CPU0 (memcg0 runnig)                | CPU1 (also memcg0 running)
                                    |
do_swap_page() of entry X           |
<direct swapin path>                |
<alloc folio A, charge into memcg0> |
... interrupted ...                 |
                                    | do_swap_page() of same entry X
                                    | <finish swapin>
                                    | set_pte_at() - a folio installed
                                    | <frees the folio with MADV_FREE>
                                    | <migrate to another *memcg1*>
                                    | <fault and install another folio>
                                    |   the folio belong to *memcg 1*
                                    | <swapout the using same entry X>
... continue ...                    |   now entry X belongs to *memcg 1*
pte_same() <- Check pass, PTE seems |
              unchanged, but now    |
              belong to memcg1.     |
set_pte_at() <- folio A installed,  |
                memcg0 is charged.  |

The folio got charged to memcg0, but it really should be charged to
memcg1 as the PTE / folio is owned by memcg1 before the last swapout.
Fortunately there is no leak, swap accounting will still be uncharging
memcg1. memcg0 is not completely irrelevant as it's true that it is now
memcg1 faulting this folio. Shmem may have similar issue.

Patch 1 fixes this issue for order 0 / non-SYNCHRONOUS_IO swapin, Patch
2 fixes this issue for SYNCHRONOUS_IO swapin.

If we consider this problem trivial, I suggest we fix it for order 0
swapin first since that's a more common and recent issue since a recent
commit.

SYNCHRONOUS_IO fix seems also good, but it changes the current fallback
logic. Instead of fallback to next order it will fallback to order 0
directly. That should be fine though. This issue can be fixed / cleaned
up in a better way with swap table P4 as demostrated previously by
allocating the folio in swap cache directly with proper fallback and a
more compat loop for error handling:

https://lore.kernel.org/linux-mm/20260220-swap-table-p4-v1-4-104795d19815@tencent.com/

Having this series merged first should also be fine. In theory, this
series may also reduce memcg thrashing of large folios since duplicated
charging is avoided for raced swapin.

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Kairui Song (2):
      mm, swap: fix potential race of charging into the wrong memcg
      mm, swap: fix race of charging into the wrong memcg for THP

 mm/memcontrol.c |  3 +--
 mm/memory.c     | 53 ++++++++++++++++++++-------------------------
 mm/shmem.c      | 15 ++++---------
 mm/swap.h       |  5 +++--
 mm/swap_state.c | 66 +++++++++++++++++++++++++++++++++++++++++----------------
 5 files changed, 79 insertions(+), 63 deletions(-)
---
base-commit: 96881c429af113d53414341d0609c47f3a0017c6
change-id: 20260407-swap-memcg-fix-9db0bcc3fa76

Best regards,
--  
Kairui Song <kasong@tencent.com>

