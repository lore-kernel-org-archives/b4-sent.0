From: Mani Tofigh <mt4022@columbia.edu>
Date: Mon, 26 Oct 2026 20:22:08 -0400
Subject: [PATCH] mm/huge_memory: fix deferred split list corruption on
 partial unmap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-thpsplit-careful-v1-1-d357d70fd6f4@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWM3QpAQBBGX0Vzbcuun+RV5II1GIltZ0nJuxtcf
 Bfnq3MuYPSEDFV0gceDmLZVQMcR2KldR1TUC4NJTKFlKkyO3UJB2dbjsC8q6U1m0zQ3pUYQzcl
 N55esm59572a04e3AfT9m52FudAAAAA==
X-Change-ID: 20261026-thpsplit-careful-0d24c335281e
To: Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Zi Yan <ziy@nvidia.com>, 
 Baolin Wang <baolin.wang@linux.alibaba.com>, 
 "Liam R. Howlett" <liam@infradead.org>, Nico Pache <nico.pache@linux.dev>, 
 Ryan Roberts <ryan.roberts@arm.com>, Dev Jain <dev.jain@arm.com>, 
 Barry Song <baohua@kernel.org>, Lance Yang <lance.yang@linux.dev>, 
 Usama Arif <usama.arif@linux.dev>, Kiryl Shutsemau <kas@kernel.org>, 
 Shakeel Butt <shakeel.butt@linux.dev>, Johannes Weiner <hannes@cmpxchg.org>, 
 "Lorenzo Stoakes (Oracle)" <ljs@kernel.org>
Cc: Kairui Song <kasong@tencent.com>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, tz2294@columbia.edu, stable@vger.kernel.org, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793060528; l=3512;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=pha4OdGyQ4NhPNP6DwAJZ4oCpNywbxpPmtNX7GrzxYg=;
 b=7VLNDgQ+nZmJUOOibAGbpRr7p9F168Ou6+p4nEc/G93b4pqw8pWPnPlMgvVFQTGz6iyrewo/L
 4GdrnZhQHbvD4bFiU5sRRUQ/3dA35CBBwyWMP1eXYox+kR2PP+Myazg
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When a THP is partially unmapped while the deferred split shrinker is
scanning it, the deferred split list can end up corrupted.  With
CONFIG_DEBUG_LIST, freeing the folio later reports:

  [  523.871401] list_del corruption. prev->next should be ffd40000005e0090, but was ffd4000000500090. (prev=ffd40000005e0090)
  [  523.871412] WARNING: lib/list_debug.c:62 at __list_del_entry_valid_or_report+0x177/0x220, CPU#0: thpsplit/63
  ...
  [  523.900715] Call Trace:
  [  523.901753]  __list_lru_del+0x5f/0x220
  [  523.902588]  __folio_unqueue_deferred_split+0x238/0x520
  ...

Without CONFIG_DEBUG_LIST, the list is left pointing at the folio
after it has been freed.

Since commit fafaeceb89a5 ("mm: switch deferred split shrinker to
list_lru"), deferred_split_scan() moves the folios it scans onto a
private list under the list_lru lock, drops the lock, and then removes
each folio from that list with list_del_init(), which sets
entry->next = entry and then entry->prev = entry.  Another task may
in the meantime partially unmap the same folio and call
deferred_split_folio(), which queues it only if list_empty() reports
it as not queued, and list_empty() reads only entry->next.  If that
happens between the two stores, the folio is queued again, and the
store to entry->prev that follows breaks the new link:

  Task A (shrinker)                     Task B (partial unmap)
  -----------------                     ----------------------
  list_del_init(entry)
    entry->next = entry
                                        deferred_split_folio()
                                          list_empty(entry) is true
                                          list_add_tail(entry)
    entry->prev = entry
    /* overwrites the prev link that
       list_add_tail() just set */

Use list_del_init_careful() instead.  It sets entry->prev first and
then entry->next with smp_store_release(), so once list_empty() sees
the entry as empty, the shrinker has finished writing to it.

The reproducer repeatedly faults in THPs and partially unmaps them
while the deferred split shrinker, run through
/proc/sys/vm/drop_caches on the same CPU, is scanning them.  This bug
was found and replayed using a deterministic hypervisor currently
under development, but the non-deterministic C reproducer can
typically trigger it in the 10-500s time range.  With the fix, nothing
is triggered after 1800 seconds.

Fixes: fafaeceb89a5 ("mm: switch deferred split shrinker to list_lru")
Cc: stable@vger.kernel.org
Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
Reproducer: https://github.com/manitofigh/thpsplit-repro/blob/main/thpsplit.c
---
 mm/huge_memory.c | 6 +++++-
 1 file changed, 5 insertions(+), 1 deletion(-)

diff --git a/mm/huge_memory.c b/mm/huge_memory.c
index 1e5d68acf62a..f4f7d757a310 100644
--- a/mm/huge_memory.c
+++ b/mm/huge_memory.c
@@ -4668,7 +4668,11 @@ static unsigned long deferred_split_scan(struct shrinker *shrink,
 		bool did_split = false;
 		bool underused = false;
 
-		list_del_init(&folio->_deferred_list);
+		/*
+		 * deferred_split_folio() may queue the folio again as soon as
+		 * list_empty() in __list_lru_add() sees it empty.
+		 */
+		list_del_init_careful(&folio->_deferred_list);
 
 		if (!folio_test_partially_mapped(folio)) {
 			/*

---
base-commit: e9011a65d78258901ba123c5f522bef26d29902f
change-id: 20261026-thpsplit-careful-0d24c335281e

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

