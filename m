From: Kairui Song <kasong@tencent.com>
Subject: [PATCH 0/3] mm/swap, zswap: fix stale zswap data and swap-in bugs
Date: Fri, 30 Oct 2026 02:31:40 +0800
Message-Id: <20261030-swap-fixes-v1-0-73f73a59f2fc@tencent.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqAIBAG4KvErBPUwKirRAuzqaZFhdMLxLtnt
 fz4HwEYPSFDnQXweBLTuiSoPAM32WVEQX0yaKmNkoUUfNlNDHQjC2WtcdopLIcK0mDz+AWp37S
 /+ehmdPv7ADE+X7ruZW4AAAA=
X-Change-ID: 20261030-swap-fixes-1aa6c2c1e7f9
To: linux-mm@kvack.org
Cc: Andrew Morton <akpm@linux-foundation.org>, Chris Li <chrisl@kernel.org>, 
 Kemeng Shi <shikemeng@huaweicloud.com>, Nhat Pham <nphamcs@gmail.com>, 
 Baoquan He <baoquan.he@linux.dev>, Barry Song <baohua@kernel.org>, 
 Youngjun Park <youngjun.park@lge.com>, Yosry Ahmed <yosry@kernel.org>, 
 Chengming Zhou <chengming.zhou@linux.dev>, 
 Usama Arif <usamaarif642@gmail.com>, David Hildenbrand <david@kernel.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, "Liam R. Howlett" <liam@infradead.org>, 
 Vlastimil Babka <vbabka@kernel.org>, Mike Rapoport <rppt@kernel.org>, 
 Suren Baghdasaryan <surenb@google.com>, Michal Hocko <mhocko@suse.com>, 
 Chuanhua Han <hanchuanhua@oppo.com>, Johannes Weiner <hannes@cmpxchg.org>, 
 Mani Tofigh <mt4022@columbia.edu>, linux-kernel@vger.kernel.org, 
 Kairui Song <kasong@tencent.com>, Josef Bacik <josef@toxicpanda.com>, 
 stable@vger.kernel.org, Chris Mason <mason@kernel.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793298765; l=1904;
 i=kasong@tencent.com; s=kasong-sign-tencent; h=from:subject:message-id;
 bh=wv3cCqMTcjfUYGycGHsVPNfiqXd3kdzJNqs56uK6eQQ=;
 b=H4nxBiyeHaeYaXxggD0n6aJqOAp/dzE0sKP5vEjlbXqvHybzWiKKiK4xx6FXElidAiRXbZqgv
 vJspPul7updDHMMeyka+FAn9lnBoH3tWJNG/rm6XNfePr1wMD0atdSU
X-Developer-Key: i=kasong@tencent.com; a=ed25519;
 pk=kCdoBuwrYph+KrkJnrr7Sm1pwwhGDdZKcKrqiK8Y1mI=
X-Endpoint-Received: by B4 Relay for kasong@tencent.com/kasong-sign-tencent with auth_id=562
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

There are some bug fixes found by AI and collected by David, mostly
originally from Anthropic.  After filtering and dropping a few that are
already being patched up by the community [1] [2], these are the 3 we
kept.  I've reviewed them and they all look good to me, so please help
have a look and we can get them merged soon, they are pretty simple and
clean bug fixes patching real issues.

The zswap bug can return stale data instead of the zeroes that were
written, so it is data corruption and seems critical.  The extent fix is
more urgent than it might look, as it can also read in unexpected data,
but the setup could be really rare. The accounting fix is minor.
The zswap and extent fixes affect stable kernels (v6.12+) and are marked
for stable. The accounting fix only affects v7.3+.

For the extent fix, in the long term we might actually want to detect
extent contiguity and allow mTHP swap-in for single-extent swap files.
We already disable mTHP allocation for swap files, so the current fix is
trivial. It seems the most minimal and correct one for now.
Optimization and cleanups can come later.

Link: https://lore.kernel.org/linux-mm/20261026-swapoff-writeok-v1-1-4f4cd420aa33@columbia.edu/ [1]
Link: https://lore.kernel.org/linux-mm/20260811132209.2862708-3-youngjun.park@lge.com/ [2]

Signed-off-by: Kairui Song <kasong@tencent.com>
---
Chris Mason (1):
      mm, swap: fix large swap-in across swap file extents

Josef Bacik (2):
      mm/zswap: drop the stale zswap entry of a zero folio
      mm/swap: account synchronous swap reads as memory stall

 mm/memory.c  | 16 +++++++++++++---
 mm/page_io.c | 17 +++++++++++++++++
 2 files changed, 30 insertions(+), 3 deletions(-)
---
base-commit: 24d45a1475dd4c671feb1df705f67ef2fc293969
change-id: 20261030-swap-fixes-1aa6c2c1e7f9

Best regards,
--  
Kairui Song <kasong@tencent.com>

