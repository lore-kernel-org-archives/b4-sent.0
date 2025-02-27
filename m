From: Thomas Prescher <thomas.prescher@cyberus-technology.de>
Date: Fri, 28 Feb 2025 00:02:12 +0100
Subject: [PATCH v3 3/3] mm: hugetlb: log time needed to allocate hugepages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250228-hugepage-parameter-v3-3-2628e9b2b5c0@cyberus-technology.de>
References: <20250228-hugepage-parameter-v3-0-2628e9b2b5c0@cyberus-technology.de>
In-Reply-To: <20250228-hugepage-parameter-v3-0-2628e9b2b5c0@cyberus-technology.de>
To: Jonathan Corbet <corbet@lwn.net>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Thomas Prescher <thomas.prescher@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740697330; l=1233;
 i=thomas.prescher@cyberus-technology.de; s=20250221;
 h=from:subject:message-id; bh=kVTCFV+/k+LokF7dkdID5wL+yhEPOHMcEjpG7h57QQg=;
 b=nviinN1UkUOO52193TwciC1bmDLsz/73yA7LF21tAe2rtkqUTXcEs3t41sxDWKNPeuMzSfORT
 Amw8zTCZiFNCkhEelV45hTzezgt+y4I9gVdfv+f4fjnpx/kApNWENHU
X-Developer-Key: i=thomas.prescher@cyberus-technology.de; a=ed25519;
 pk=T5MVdLVCc/0UUyv5IcSqGVvGcVkgWW/KtuEo2RRJwM8=
X-Endpoint-Received: by B4 Relay for thomas.prescher@cyberus-technology.de/20250221 with auth_id=345
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Having this information allows users to easily tune
the hugepages_node_threads parameter.

Signed-off-by: Thomas Prescher <thomas.prescher@cyberus-technology.de>
---
 mm/hugetlb.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 98dbfa18bee01d01b40cc7c650cd3eca5eae2457..816e5846222a54255b99515a94e0c1ba9b2b7b27 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -3430,6 +3430,9 @@ static unsigned long __init hugetlb_pages_alloc_boot(struct hstate *h)
 		.numa_aware	= true
 	};
 
+	unsigned long jiffies_start;
+	unsigned long jiffies_end;
+
 	job.thread_fn	= hugetlb_pages_alloc_boot_node;
 	job.start	= 0;
 	job.size	= h->max_huge_pages;
@@ -3457,7 +3460,14 @@ static unsigned long __init hugetlb_pages_alloc_boot(struct hstate *h)
 
 	job.max_threads	= hugepage_allocation_threads;
 	job.min_chunk	= h->max_huge_pages / hugepage_allocation_threads;
+
+	jiffies_start = jiffies;
 	padata_do_multithreaded(&job);
+	jiffies_end = jiffies;
+
+	pr_info("HugeTLB: allocation took %dms with hugepage_alloc_threads=%ld\n",
+		jiffies_to_msecs(jiffies_end - jiffies_start),
+		hugepage_allocation_threads);
 
 	return h->nr_huge_pages;
 }

-- 
2.48.1

