From: Thomas Prescher <thomas.prescher@cyberus-technology.de>
Date: Fri, 21 Feb 2025 14:49:04 +0100
Subject: [PATCH 2/2] mm: hugetlb: log time needed to allocate hugepages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250221-hugepage-parameter-v1-2-fa49a77c87c8@cyberus-technology.de>
References: <20250221-hugepage-parameter-v1-0-fa49a77c87c8@cyberus-technology.de>
In-Reply-To: <20250221-hugepage-parameter-v1-0-fa49a77c87c8@cyberus-technology.de>
To: Jonathan Corbet <corbet@lwn.net>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Thomas Prescher <thomas.prescher@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740145745; l=1236;
 i=thomas.prescher@cyberus-technology.de; s=20250221;
 h=from:subject:message-id; bh=+RVZ6u1nzdp1931lwTDAnLSee61rdleZduyoY/lMDIA=;
 b=4+fAS5E5X1tj0juCLlk8wApea1Mw0hFQMhgVoxUvNua6eliTe5IqQoAihZ6t8J1ZOqKoXwCkS
 PyHzdDBHY34C9m3qRY5CD7zL8gr1jDVg1stVn8oZoDsw6CVRLFkgv8z
X-Developer-Key: i=thomas.prescher@cyberus-technology.de; a=ed25519;
 pk=T5MVdLVCc/0UUyv5IcSqGVvGcVkgWW/KtuEo2RRJwM8=
X-Endpoint-Received: by B4 Relay for thomas.prescher@cyberus-technology.de/20250221 with auth_id=345
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Having this information allows users to easily tune
the hugepages_node_threads parameter.

Signed-off-by: Thomas Prescher <thomas.prescher@cyberus-technology.de>
---
 mm/hugetlb.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/mm/hugetlb.c b/mm/hugetlb.c
index b7d24c41e0f9d22f5b86c253e29a2eca28460026..2aa5724a385494f9d6f1d644a2bfe547591fc96c 100644
--- a/mm/hugetlb.c
+++ b/mm/hugetlb.c
@@ -3428,6 +3428,9 @@ static unsigned long __init hugetlb_pages_alloc_boot(struct hstate *h)
 		.numa_aware	= true
 	};
 
+	unsigned long jiffies_start;
+	unsigned long jiffies_end;
+
 	job.thread_fn	= hugetlb_pages_alloc_boot_node;
 	job.start	= 0;
 	job.size	= h->max_huge_pages;
@@ -3450,7 +3453,13 @@ static unsigned long __init hugetlb_pages_alloc_boot(struct hstate *h)
 	 */
 	job.max_threads	= num_node_state(N_MEMORY) * allocation_threads_per_node;
 	job.min_chunk	= h->max_huge_pages / num_node_state(N_MEMORY) / allocation_threads_per_node;
+
+	jiffies_start = jiffies;
 	padata_do_multithreaded(&job);
+	jiffies_end = jiffies;
+
+	printk(KERN_DEBUG "HugeTLB: allocation took %dms\n",
+	    jiffies_to_msecs(jiffies_end - jiffies_start));
 
 	return h->nr_huge_pages;
 }

-- 
2.48.1

