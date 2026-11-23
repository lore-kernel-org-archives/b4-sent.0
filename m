From: Amir Hosseini <me@amir.fyi>
Date: Mon, 23 Nov 2026 20:15:49 +0000
Subject: [PATCH] mm/mm_init: don't shrink large system hash tables below
 low_limit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-mm-hash-low-limit-v1-1-8a803aa8ac70@amir.fyi>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB0wSTHgVcRFjFMzYrRktC2Id
 2+sy7f4/wChxCTQFAckerPwumSosgAf3DIS8pANutK1UtpgjBicBJzXD84ceUNjnXEP660fFOT
 ulejJ3/+z7W7L3k/kt2sE5/kDSiF5bXUAAAA=
X-Change-ID: 20261123-mm-hash-low-limit-37a3a47c7cd1
To: Mike Rapoport <rppt@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Eric Dumazet <edumazet@kernel.org>, "David S. Miller" <davem@davemloft.net>
Cc: linux-mm@kvack.org, Muchun Song <muchun.song@linux.dev>, 
 netdev@vger.kernel.org, Amir Hosseini <me@amir.fyi>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795464951; l=4501;
 i=me@amir.fyi; s=archbox; h=from:subject:message-id;
 bh=WPCrCh616UcUkUJ0vkYRNurwFSh+B3LJalviBGxSKIY=;
 b=dDXYaITR/9+vETOai4ym8o/T+Iz7M6pTmCu5CpZPCow7sXOPhxBS5s8oXwcLtmoU6p46fwI7z
 YjAnvL44ac6CW5F+m6/Es8JyJhJtkMJGiBgn0mqyBgqXnUp5a1xuazL
X-Developer-Key: i=me@amir.fyi; a=ed25519;
 pk=YmuzvXl0k+J8pTqIG0kjwtCeJ1ggyIgBHm2jFmzNbeU=
X-Endpoint-Received: by B4 Relay for me@amir.fyi/archbox with auth_id=1620
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When an allocation fails, alloc_large_system_hash() halves the table and
retries until it is down to a single page.  It does not stop at
low_limit, although commit 31fe62b95866 ("mm: add a low limit to
alloc_large_system_hash") added low_limit precisely so that callers need
not check the size they get back.

The TCP source port perturbation table depends on that.  It passes
low_limit == high_limit == INET_TABLE_PERTURB_SIZE and neither
_hash_shift nor _hash_mask, so it cannot learn the real size, and
__inet_hash_connect() fills and indexes INET_TABLE_PERTURB_SIZE entries.
On a single node system hashdist is off and the table needs one order-6
GFP_ATOMIC allocation.  If that fails, e.g. because most memory was
reserved for HugeTLB at boot, the situation commit e67b72b90b7e ("tcp:
use alloc_large_system_hash() to allocate table_perturb") was meant to
handle, the table is silently halved and the first connect() writes up
to 240 KiB of random bytes past its end, typically into the TCP
established hash table:

  Table-perturb hash table entries: 32768 (order: 5, 131072 bytes, linear)
  ...
  Oops: general protection fault, probably for non-canonical address 0xe480dbf6b420b3d9: 0000 [#1] SMP KASAN
  RIP: 0010:__inet_lookup_established+0x168/0x5d0
  Call Trace:
   <IRQ>
   tcp_v4_rcv
   ip_protocol_deliver_rcu
   ip_local_deliver

Stop halving at low_limit.  If the linear allocation still fails, retry
the same size with vmalloc_huge(), which this function already uses for
tables that are too large for the page allocator or when hashdist is
set, and which does not need physically contiguous memory.  If that
fails too, panic as before.

Reproduced on v7.4-rc4 in an x86_64 QEMU guest (virtme-ng, 1 node,
KASAN) by failing just that allocation with CONFIG_FAIL_PAGE_ALLOC and
fail_page_alloc=1,100,<space>,1, where <space> was measured with the
kmem:mm_page_alloc tracepoint so that the one injected failure hits the
Table-perturb allocation.  Without this patch the table is halved and
the kernel crashes as above on the first connect(); with it the table
keeps 65536 entries (vmalloc) and the system works normally.

The reproducer and fix were developed with the help of Claude Code.

Fixes: 31fe62b95866 ("mm: add a low limit to alloc_large_system_hash")
Cc: stable@vger.kernel.org
Signed-off-by: Amir Hosseini <me@amir.fyi>
---
 mm/mm_init.c | 18 ++++++++++++++++--
 1 file changed, 16 insertions(+), 2 deletions(-)

diff --git a/mm/mm_init.c b/mm/mm_init.c
index d99af80ec752..418068bad006 100644
--- a/mm/mm_init.c
+++ b/mm/mm_init.c
@@ -2359,6 +2359,7 @@ void __init page_alloc_init_late(void)
  * - it is assumed that the hash table must contain an exact power-of-2
  *   quantity of entries
  * - limit is the number of hash buckets, not the total allocation size
+ * - the table has at least low_limit entries, callers may rely on that
  */
 void *__init alloc_large_system_hash(const char *tablename,
 				     unsigned long bucketsize,
@@ -2371,7 +2372,7 @@ void *__init alloc_large_system_hash(const char *tablename,
 				     unsigned long high_limit)
 {
 	unsigned long long max = high_limit;
-	unsigned long log2qty, size;
+	unsigned long log2qty, min_log2qty, size;
 	void *table;
 	gfp_t gfp_flags;
 	bool virt;
@@ -2420,6 +2421,7 @@ void *__init alloc_large_system_hash(const char *tablename,
 		numentries = max;
 
 	log2qty = ilog2(numentries);
+	min_log2qty = max(order_base_2(low_limit), 1);
 
 	gfp_flags = (flags & HASH_ZERO) ? GFP_ATOMIC | __GFP_ZERO : GFP_ATOMIC;
 	do {
@@ -2445,7 +2447,19 @@ void *__init alloc_large_system_hash(const char *tablename,
 			table = alloc_pages_exact(size, gfp_flags);
 			kmemleak_alloc(table, size, 1, gfp_flags);
 		}
-	} while (!table && size > PAGE_SIZE && --log2qty);
+	} while (!table && size > PAGE_SIZE && log2qty > min_log2qty &&
+		 --log2qty);
+
+	/*
+	 * Shrinking below low_limit would break callers that size other data
+	 * from it, so fall back to vmalloc, which needs no contiguous memory.
+	 */
+	if (!table && !virt && !(flags & HASH_EARLY)) {
+		table = vmalloc_huge(size, gfp_flags);
+		virt = true;
+		if (table)
+			huge = is_vm_area_hugepages(table);
+	}
 
 	if (!table)
 		panic("Failed to allocate %s hash table\n", tablename);

---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-mm-hash-low-limit-37a3a47c7cd1

Best regards,
--  
Amir Hosseini <me@amir.fyi>

