From: Matthew Salsamendi <matthewsalsamendi@gmail.com>
Date: Tue, 17 Nov 2026 16:26:17 -0800
Subject: [PATCH v2 1/2] fs/proc/task_mmu: reset walk_end before each
 pagemap walk
To: Andrew Morton <akpm@linux-foundation.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Lorenzo Stoakes <ljs@kernel.org>
Cc: Chris Down <chris@chrisdown.name>, Vlastimil Babka <vbabka@kernel.org>, 
 Muhammad Usama Anjum <usama.anjum@arm.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, matthewsalsamendi@gmail.com, 
 Jann Horn <jannh@google.com>, Pedro Falcato <pfalcato@suse.de>, 
 linux-fsdevel@vger.kernel.org, stable@vger.kernel.org
Message-Id: <20261118-pagemap-walk-end-v2-1-94cd92d838b3@gmail.com>
In-Reply-To: <20261118-pagemap-walk-end-v2-0-94cd92d838b3@gmail.com>
References: <20261118-pagemap-walk-end-v2-0-94cd92d838b3@gmail.com>
X-Mailer: b4 0.16.0
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794961577; l=1428;
 i=matthewsalsamendi@gmail.com; s=b4-kernel-20261117;
 h=from:subject:message-id; bh=7qGs2hd6Xj+UHbWpzY0D12fJy01dF02sQB04QPCEhTs=;
 b=Mc9ZX82EqhXsHrPuC5JbOue8KSUJJJe+aeJNlnoQt1oDt7qh63ZBSqkMCdmrEMHJu/jJe1kqN
 yPXCwPuokCXCNL51/tvJiRSpZrCbS+ZSW/xH8TYix1x9mLmSaQ/5PNB
X-Developer-Key: i=matthewsalsamendi@gmail.com; a=ed25519;
 pk=K4Lg4pTU46IL2CPz2Nb/u30nsnWJ38MlR2/Co4n0tto=
X-Endpoint-Received: by B4 Relay for matthewsalsamendi@gmail.com/b4-kernel-20261117 with auth_id=1555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When PAGEMAP_SCAN resumes after filling its buffer, it can return ranges
beyond a stale walk_end. This aborts a production game server during
dirty-page tracking.

Reset walk_end before each walk so a completed scan reports the end and
a partial HugeTLB write-protect request keeps its retry address.

Codex assisted with diagnosis, validation and this message.

Fixes: 52526ca7fdb9 ("fs/proc/task_mmu: implement IOCTL to get and optionally clear info about PTEs")
Suggested-by: Chris Down <chris@chrisdown.name>
Suggested-by: Lorenzo Stoakes <ljs@kernel.org>
Cc: stable@vger.kernel.org # 6.7+
Signed-off-by: Matthew Salsamendi <matthewsalsamendi@gmail.com>
---
v2: Use the per-walk reset suggested by Chris and Lorenzo.
    Verified the 513-range refill and 2 MiB HugeTLB retry on x86-64.

Stable: The bug is present in v6.7. The hunk needs a context adjustment
on v6.7 and applies unchanged to v6.8.

 fs/proc/task_mmu.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/fs/proc/task_mmu.c b/fs/proc/task_mmu.c
index b87d3e86442d..8723ffbff77c 100644
--- a/fs/proc/task_mmu.c
+++ b/fs/proc/task_mmu.c
@@ -3155,6 +3155,7 @@ static long do_pagemap_scan(struct mm_struct *mm, unsigned long uarg)
 			mmu_notifier_invalidate_range_start(&range);
 		}
 
+		p.arg.walk_end = 0; /* Reset partial walks. */
 		ret = walk_page_range(mm, walk_start, p.arg.end,
 				      &pagemap_scan_ops, &p);
 

