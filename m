From: Thomas Prescher <thomas.prescher@cyberus-technology.de>
Date: Thu, 27 Feb 2025 23:45:07 +0100
Subject: [PATCH v2 3/3] mm: hugetlb: log time needed to allocate hugepages
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250227-hugepage-parameter-v2-3-7db8c6dc0453@cyberus-technology.de>
References: <20250227-hugepage-parameter-v2-0-7db8c6dc0453@cyberus-technology.de>
In-Reply-To: <20250227-hugepage-parameter-v2-0-7db8c6dc0453@cyberus-technology.de>
To: Jonathan Corbet <corbet@lwn.net>, Muchun Song <muchun.song@linux.dev>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, Thomas Prescher <thomas.prescher@cyberus-technology.de>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740696310; l=1238;
 i=thomas.prescher@cyberus-technology.de; s=20250221;
 h=from:subject:message-id; bh=DnQm/ufrOp5KRhZift3qcnZk9CLmrzaedzUcrpSfRg8=;
 b=7/+8mcgFy1AHR3tc4v90RSb52SvqhIl5u321vKgF5hXYbL35rYRH5EJuWaxQKtZBEANJ4FLsE
 GApQqF2DaSKBUdDMSL2HpAgAZcgZL7SlkW9ZTzWOBBtKUR8eUEF7l+i
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
index 98dbfa18bee01d01b40cc7c650cd3eca5eae2457..373b6ac4a3824555f91ad9895e66f631f6e1ba82 100644
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
+	pr_info("HugeTLB: allocation took %dms with hugepage_allocation_threads=%ld\n",
+		jiffies_to_msecs(jiffies_end - jiffies_start),
+		hugepage_allocation_threads);
 
 	return h->nr_huge_pages;
 }

-- 
2.48.1

