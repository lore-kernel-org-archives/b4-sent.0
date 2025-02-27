From: Thomas Prescher <thomas.prescher@cyberus-technology.de>
Date: Fri, 28 Feb 2025 00:02:10 +0100
Subject: [PATCH v3 1/3] mm: hugetlb: improve parallel huge page allocation
 time
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250228-hugepage-parameter-v3-1-2628e9b2b5c0@cyberus-technology.de>
References: <20250228-hugepage-parameter-v3-0-2628e9b2b5c0@cyberus-technology.de>
In-Reply-To: <20250228-hugepage-parameter-v3-0-2628e9b2b5c0@cyberus-technology.de>
To: Jonathan Corbet <corbet@lwn.net>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Thomas Prescher <thomas.prescher@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740697330; l=3225;
 i=thomas.prescher@cyberus-technology.de; s=20250221;
 h=from:subject:message-id; bh=J38/TB8riQAZ4fzuSMdQ3k6+xa/EprG/GBf8GbXV050=;
 b=vOjP4B1DdPNfhvskR5NLf5KL0dhmWvZ8fNSGh+J2B/n9nrAWy1cYAwk4sJjUbqvqK+Wq1RjLV
 KLwMJC6/XAHDMH7TZTR8U4e9ce3TwK3/dB61DC+yHT7uY6kVQvCEhBt
X-Developer-Key: i=thomas.prescher@cyberus-technology.de; a=ed25519;
 pk=T5MVdLVCc/0UUyv5IcSqGVvGcVkgWW/KtuEo2RRJwM8=
X-Endpoint-Received: by B4 Relay for thomas.prescher@cyberus-technology.de/20250221 with auth_id=345
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Before this patch, the kernel currently used a hard coded
value of 2 threads per NUMA node for these allocations.

This patch changes this policy and the kernel now uses 25%
of the available hardware threads for the allocations.

Signed-off-by: Thomas Prescher <thomas.prescher@cyberus-technology.de>
---
 mm/hugetlb.c | 34 ++++++++++++++++++----------------
 1 file changed, 18 insertions(+), 16 deletions(-)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index 163190e89ea16450026496c020b544877db147d1..e9b1b3e2b9d467f067d54359e1401a03f9926108 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -14,9 +14,11 @@
 #include <linux/pagemap.h>
 #include <linux/mempolicy.h>
 #include <linux/compiler.h>
+#include <linux/cpumask.h>
 #include <linux/cpuset.h>
 #include <linux/mutex.h>
 #include <linux/memblock.h>
+#include <linux/minmax.h>
 #include <linux/sysfs.h>
 #include <linux/slab.h>
 #include <linux/sched/mm.h>
@@ -3427,31 +3429,31 @@ static unsigned long __init hugetlb_pages_alloc_boot(struct hstate *h)
 		.numa_aware	= true
 	};
 
+	unsigned int num_allocation_threads = max(num_online_cpus() / 4, 1);
+
 	job.thread_fn	= hugetlb_pages_alloc_boot_node;
 	job.start	= 0;
 	job.size	= h->max_huge_pages;
 
 	/*
-	 * job.max_threads is twice the num_node_state(N_MEMORY),
+	 * job.max_threads is 25% of the available cpu threads by default.
 	 *
-	 * Tests below indicate that a multiplier of 2 significantly improves
-	 * performance, and although larger values also provide improvements,
-	 * the gains are marginal.
+	 * On large servers with terabytes of memory, huge page allocation
+	 * can consume a considerably amount of time.
 	 *
-	 * Therefore, choosing 2 as the multiplier strikes a good balance between
-	 * enhancing parallel processing capabilities and maintaining efficient
-	 * resource management.
+	 * Tests below show how long it takes to allocate 1 TiB of memory with 2MiB huge pages.
+	 * 2MiB huge pages. Using more threads can significantly improve allocation time.
 	 *
-	 * +------------+-------+-------+-------+-------+-------+
-	 * | multiplier |   1   |   2   |   3   |   4   |   5   |
-	 * +------------+-------+-------+-------+-------+-------+
-	 * | 256G 2node | 358ms | 215ms | 157ms | 134ms | 126ms |
-	 * | 2T   4node | 979ms | 679ms | 543ms | 489ms | 481ms |
-	 * | 50G  2node | 71ms  | 44ms  | 37ms  | 30ms  | 31ms  |
-	 * +------------+-------+-------+-------+-------+-------+
+	 * +-----------------------+-------+-------+-------+-------+-------+
+	 * | threads               |   8   |   16  |   32  |   64  |   128 |
+	 * +-----------------------+-------+-------+-------+-------+-------+
+	 * | skylake      144 cpus |   44s |   22s |   16s |   19s |   20s |
+	 * | cascade lake 192 cpus |   39s |   20s |   11s |   10s |    9s |
+	 * +-----------------------+-------+-------+-------+-------+-------+
 	 */
-	job.max_threads	= num_node_state(N_MEMORY) * 2;
-	job.min_chunk	= h->max_huge_pages / num_node_state(N_MEMORY) / 2;
+
+	job.max_threads	= num_allocation_threads;
+	job.min_chunk	= h->max_huge_pages / num_allocation_threads;
 	padata_do_multithreaded(&job);
 
 	return h->nr_huge_pages;

-- 
2.48.1

