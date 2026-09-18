From: Jingxiang Zeng <linuszeng@tencent.com>
Date: Fri, 18 Sep 2026 16:53:43 +0800
Subject: [PATCH 3/6] mm: page_counter: drop protection fields from struct
 page_counter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-descriptive-name-v1-3-dfcfdd91b456@tencent.com>
References: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
In-Reply-To: <20260918-descriptive-name-v1-0-dfcfdd91b456@tencent.com>
To: Johannes Weiner <hannes@cmpxchg.org>, Michal Hocko <mhocko@kernel.org>, 
 Roman Gushchin <roman.gushchin@linux.dev>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Maarten Lankhorst <dev@lankhorst.se>, Maxime Ripard <mripard@kernel.org>, 
 Natalie Vock <nat@pixelcluster.dev>, Tejun Heo <tj@kernel.org>, 
 =?utf-8?q?Michal_Koutn=C3=BD?= <mkoutny@suse.com>, 
 Oscar Salvador <osalvador@suse.de>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>
Cc: Jingxiang Zeng <jingxiangzeng.cas@gmail.com>, cgroups@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, linux-doc@vger.kernel.org, 
 Jingxiang Zeng <linuszeng@tencent.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789721651; l=1721;
 i=linuszeng@tencent.com; s=20260909; h=from:subject:message-id;
 bh=GADlg4c7MuNMFrgGvBXbc27o0HpJUKcrZX5lbsFPXjs=;
 b=1jXeFmMF4d9zQQS9hsdMiN/aPBms3k02q4O+kWhQZ8m+MkzNteDbtTrmxJgIpSWeZDVGUAUdr
 L4jsYEoTO8mCLqkgVNx9pNECUvDG3RsxJoXyoLpns9C1TmS/Ppv9kUl
X-Developer-Key: i=linuszeng@tencent.com; a=ed25519;
 pk=6K54xRzYIRWqatrAPy86M4E0MsI92BVJBhXwz5NdC74=
X-Endpoint-Received: by B4 Relay for linuszeng@tencent.com/20260909 with auth_id=1017
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The protection state now lives in struct page_counter_protection, so
remove the emin/min_usage/children_min_usage, elow/low_usage/
children_low_usage, min, low and protection_support fields from struct
page_counter.

Also drop the now-orphaned _pad2_ padding and its comment: with the
protection fields gone it no longer separates the read-mostly fields
from anything, and the structure's cacheline alignment already pads the
tail out.

swap/memsw, kmem, tcpmem and hugetlb counters no longer carry this
unused state: on 64-bit the structure shrinks from three cache lines to
two, saving one cache line.

Signed-off-by: Jingxiang Zeng <linuszeng@tencent.com>
---
 include/linux/page_counter.h | 16 ----------------
 1 file changed, 16 deletions(-)

diff --git a/include/linux/page_counter.h b/include/linux/page_counter.h
index 5020e62aacb4..27467bf3b8e6 100644
--- a/include/linux/page_counter.h
+++ b/include/linux/page_counter.h
@@ -56,27 +56,11 @@ struct page_counter {
 
 	CACHELINE_PADDING(_pad1_);
 
-	/* effective memory.min and memory.min usage tracking */
-	unsigned long emin;
-	atomic_long_t min_usage;
-	atomic_long_t children_min_usage;
-
-	/* effective memory.low and memory.low usage tracking */
-	unsigned long elow;
-	atomic_long_t low_usage;
-	atomic_long_t children_low_usage;
-
 	unsigned long watermark;
 	/* Latest cg2 reset watermark */
 	unsigned long local_watermark;
 
-	/* Keep all the read most fields in a separete cacheline. */
-	CACHELINE_PADDING(_pad2_);
-
-	bool protection_support;
 	bool track_failcnt;
-	unsigned long min;
-	unsigned long low;
 	unsigned long high;
 	unsigned long max;
 	struct page_counter *parent;

-- 
2.43.7

