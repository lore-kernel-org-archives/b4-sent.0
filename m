From: Kairui Song <kasong@tencent.com>
Subject: [PATCH v2 0/4] mm/swap, zswap: fix stale zswap data and swap-in
 bugs
Date: Wed, 04 Nov 2026 00:18:13 +0800
Message-Id: <20261104-swap-fixes-v2-0-204be064be5b@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NOw7CMBBErxJtjZE/IlaouAdKYZY1MRJO5DUGF
 OXuOKGlfJo3MzMwpUAMx2aGRCVwGGMFvWsABxdvJMK1MmipWyWNFPxyk/DhTSyUcy1qVGR9B7U
 wJdqC6p/7H/PzcifM68JqDIHzmD7bW1Gr93e4KCGFNd4ad+i89njKFJFi3uP4gH5Zli/tnpAxu
 AAAAA==
X-Change-ID: 20261030-swap-fixes-1aa6c2c1e7f9
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kairui Song <kasong@tencent.com>, Kemeng Shi <shikemeng@huaweicloud.com>, 
 Nhat Pham <nphamcs@gmail.com>, Baoquan He <baoquan.he@linux.dev>, 
 Barry Song <baohua@kernel.org>, Youngjun Park <youngjun.park@lge.com>, 
 Usama Arif <usamaarif642@gmail.com>, 
 Chengming Zhou <chengming.zhou@linux.dev>, Yosry Ahmed <yosry@kernel.org>, 
 Johannes Weiner <hannes@cmpxchg.org>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chuanhua Han <hanchuanhua@oppo.com>, Mani Tofigh <mt4022@columbia.edu>, 
 NeilBrown <neil@brown.name>, Christoph Hellwig <hch@lst.de>, 
 linux-kernel@vger.kernel.org, Josef Bacik <josef@toxicpanda.com>, 
 stable@vger.kernel.org, Chris Mason <mason@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793722701; l=3669;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=1IXCDeRv/bOKH81RaUG8b0PYhXau5ZH24z8Ggh2fGYw=;
 b=72fU0+BSPT24/wFgiMMSDPMJtafBrwKYZufCn/PCHxqYJt/BKlSgQzT1KxbY9WpmInfMdUr8U
 xXQf2kIoV1rDbmcMdT2xv3OSdvIpPAxQKzxGdJFhIcjGi+xEuUMjuBf
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

There are some bug fixes found by AI and collected by David, mostly
originally from Anthropic.  After filtering and dropping a few that are
already being patched up by the community [1] [2], these are the 3 we
kept.  The accounting fix is in two patches now, the second one from
Johannes to cover asynchronous devices too.

Patches 1 and 2 are marked for stable, they affect v6.12 and later.
Patches 3 and 4 only affect v7.3 and later, so they are not marked for
stable.

The zswap bug in patch 1 can return stale data instead of the zeroes that
were written, so it is data corruption and seems critical.  The extent
fix in patch 2 is more urgent than it might look, as it can also read in
unexpected data, but the setup could be really rare.

For the extent fix, in the long term we might actually want to detect
extent contiguity and allow mTHP swap-in for single-extent swap files.
We already disable mTHP allocation for swap files, so the current fix is
trivial. It seems the most minimal and correct one for now.
Optimization and cleanups can come later.

Patch 3 gives up readahead batching for synchronous devices, as its
changelog says; that only affects the MADV_WILLNEED and swapoff walks,
the fault path never batched.

Testing: tested on arm64 with both zram and swap file over sync device
and async device, everything works as expected, no content mismatch.

Link: https://lore.kernel.org/linux-mm/20261026-swapoff-writeok-v1-1-4f4cd420aa33@columbia.edu/ [1]
Link: https://lore.kernel.org/linux-mm/20260811132209.2862708-3-youngjun.park@lge.com/ [2]
---
Changes in v2:
- The zswap and accounting fixes are unchanged from v1.
- Patch 2 simplifies the known-gap note about the unmerged xswap patch, per
  Nhat.
- New patch 4 from Johannes keeps the swap-in pressure window open across
  a batch so that asynchronous submission is counted as well.
- Link to v1: https://patch.msgid.link/20261030-swap-fixes-v1-0-73f73a59f2fc@tencent.com

To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>
Cc: Chris Li <chrisl@kernel.org>
Cc: Kairui Song <kasong@tencent.com>
Cc: Kemeng Shi <shikemeng@huaweicloud.com>
Cc: Nhat Pham <nphamcs@gmail.com>
Cc: Baoquan He <baoquan.he@linux.dev>
Cc: Barry Song <baohua@kernel.org>
Cc: Youngjun Park <youngjun.park@lge.com>
Cc: Usama Arif <usamaarif642@gmail.com>
Cc: Chengming Zhou <chengming.zhou@linux.dev>
Cc: Yosry Ahmed <yosry@kernel.org>
Cc: Johannes Weiner <hannes@cmpxchg.org>
Cc: David Hildenbrand <david@kernel.org>
Cc: Lorenzo Stoakes <ljs@kernel.org>
Cc: "Liam R. Howlett" <liam@infradead.org>
Cc: Vlastimil Babka <vbabka@kernel.org>
Cc: Mike Rapoport <rppt@kernel.org>
Cc: Suren Baghdasaryan <surenb@google.com>
Cc: Michal Hocko <mhocko@suse.com>
Cc: Chuanhua Han <hanchuanhua@oppo.com>
Cc: Mani Tofigh <mt4022@columbia.edu>
Cc: NeilBrown <neil@brown.name>
Cc: Christoph Hellwig <hch@lst.de>
Cc: linux-kernel@vger.kernel.org

---
Chris Mason (1):
      mm, swap: fix large swap-in across swap file extents

Johannes Weiner (1):
      mm/swap: keep the swap-in pressure window open across a batch

Josef Bacik (2):
      mm/zswap: drop the stale zswap entry of a zero folio
      mm/swap: account synchronous swap reads as memory stall

 include/linux/swap_ops.h | 10 ++++++
 mm/memory.c              | 16 +++++++--
 mm/page_io.c             | 94 +++++++++++++++++++++++++++++++++---------------
 3 files changed, 89 insertions(+), 31 deletions(-)
---
base-commit: 0ea6dc8c4a2192227ec25768625686b8fcd5cb09
change-id: 20261030-swap-fixes-1aa6c2c1e7f9

Best regards,
--  
Kairui Song <kasong@tencent.com>

