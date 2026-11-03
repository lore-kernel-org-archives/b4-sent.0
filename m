From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 03 Nov 2026 13:19:26 +0900
Subject: [PATCH v2] mm/readahead: align the async window in
 page_cache_ra_order()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-mm-readahead-async-align-v2-1-c3c304cbca59@samsung.com>
X-B4-Tracking: v=1; b=H4sIAM1g6WoC/3WNQQrCMBBFr1Jm7UiSarCuvId0MSbTdsCkkmixl
 N7dWNzKwIf34b9ZIHMSznCuFkg8SZYxFjC7CtxAsWcUXxiMMlYr02AImJg8DSWQ8hwd0l36iHx
 o9K32TluyUOaPxJ28N/W1LTxIfo5p3j5N+tv+pLX6L500llONZ7Kno+7cJVPIr9jv3RigXdf1A
 09w6YLCAAAA
To: Andrew Morton <akpm@linux-foundation.org>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>
Cc: Ryan Roberts <ryan.roberts@arm.com>, linux-fsdevel@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793679738; l=5655;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=Y6K49ChbLQ/vvrZa8N0/zgs6RJ3DJ7DdEewXatAf4Zw=;
 b=qkVlea5bIYUPbnzum2mHckAQvFbKLK2nD6gYINP9fYoPR6sA/KB4vBwgtLvorta6jrMUzytkA
 S58uRJ4d29DALnO40WT9tIZWXfdrNooaUG9qaTpR6qG8/e5Gs7rcYgJ
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

page_cache_async_ra() rounds each window end down to a multiple of
1 << ra->order pages before page_cache_ra_order() clamps the folio
order. A window starting just below a boundary shrinks to a few pages.
With read_ahead_kb=128 and max_sectors_kb=512, 1 MiB reads after a
4 KiB read at offset 0 hit this on one window in three. On a 512 MiB
XFS file over QEMU NVMe (cold cache), that takes 0.251 s, 3329 device
reads, and 9721 folios (none of order 7).

Pass a flag in struct readahead_control and align the window end in
page_cache_ra_order(), stepping the order down to keep at least half of
the window. The read then takes 0.200 s, 1031 device reads, and 1039
folios (1021 of order 7).

Fixes: 18ebe55a9236 ("mm/readahead: terminate async readahead on natural boundary")
Suggested-by: Jan Kara <jack@suse.cz>
Link: https://lore.kernel.org/r/747jhqta3plrrx3bfikceoltsewshdpejdei2qjpn3onnvtu3p@cptmb4phbn54
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Changes in v2:
- Pass a flag in struct readahead_control, align the async window in
  page_cache_ra_order(), and report folio order counts (Jan Kara).
- Summarize the benchmark setup and performance results in the changelog
  (Andrew Morton).

Tested on mm-new in a QEMU guest with XFS on an emulated NVMe (2 MiB
max transfer size), read_ahead_kb 128 and a cold cache, median of 5
runs (folio orders from mm_filemap_add_to_page_cache):

- max_sectors_kb 512, 1 MiB reads after a 4 KiB read at offset 0 on a
  512 MiB file: 0.251 s and 3329 device reads before, 0.200 s and 1031
  after. Folios drop from 9721 (none of order 7) to 1039 (1021 of
  order 7). Without the 4 KiB read, and with 64 KiB reads, device reads
  and device bytes stay within 0.1%.

- max_sectors_kb 256, 512 KiB reads after the 4 KiB read: 6147 device
  reads before and 2055 after. Folios drop from 15867 (none of order 6)
  to 2060 (2045 of order 6).

- max_sectors_kb 1024 or 2048, 1 MiB reads after the 4 KiB read: 1029
  and 1030 device reads. Folios drop from 2839 (766 of order 7) to 1039
  (1021 of order 7).

- max_sectors_kb 2048, 3 MiB reads after the 4 KiB read: 273 device
  reads and 315 folios (249 of order 9) before, 265 device reads and
  277 folios (252 of order 9) after.

- Non-sequential reads (max_sectors_kb 2048: random 4 KiB or 64 KiB
  reads, two interleaved streams, and 2 MiB regions at random offsets):
  device reads and device bytes stay within 0.1%.
---
 include/linux/pagemap.h |  1 +
 mm/readahead.c          | 41 +++++++++++++++++++++++++++++++----------
 2 files changed, 32 insertions(+), 10 deletions(-)

diff --git a/include/linux/pagemap.h b/include/linux/pagemap.h
index 73af18a373..669d296edd 100644
--- a/include/linux/pagemap.h
+++ b/include/linux/pagemap.h
@@ -1413,6 +1413,7 @@ struct readahead_control {
 	bool _workingset;
 	unsigned long _pflags;
 	bool _forward;
+	bool _align_end;
 };
 
 #define DEFINE_READAHEAD(ractl, f, r, m, i)				\
diff --git a/mm/readahead.c b/mm/readahead.c
index 6e55632902..959c9a7b48 100644
--- a/mm/readahead.c
+++ b/mm/readahead.c
@@ -498,6 +498,35 @@ void page_cache_ra_order(struct readahead_control *ractl,
 		goto fallback;
 	}
 
+	new_order = min(mapping_max_folio_order(mapping), new_order);
+	new_order = min_t(unsigned int, new_order, ilog2(ra->size));
+	new_order = max(new_order, min_order);
+
+	/*
+	 * The caller allows the window to shrink so that it ends on a folio
+	 * boundary, rather than ending in small folios. Keep at least half of
+	 * the window: one that starts just below a boundary would otherwise
+	 * shrink to a few pages. Use a smaller order instead.
+	 */
+	if (ractl->_align_end) {
+		pgoff_t end = start + ra->size;
+
+		while (new_order > min_order) {
+			pgoff_t aligned_end = round_down(end, 1UL << new_order);
+
+			if (aligned_end <= start)
+				break;
+			if (2 * (aligned_end - start) >= ra->size) {
+				ra->size = aligned_end - start;
+				ra->async_size = ra->size;
+				new_order = min_t(unsigned int, new_order,
+						  ilog2(ra->size));
+				break;
+			}
+			new_order--;
+		}
+	}
+
 	if (limit > index + ra->size - 1) {
 		limit = index + ra->size - 1;
 		mark = index + ra->size - ra->async_size;
@@ -506,10 +535,6 @@ void page_cache_ra_order(struct readahead_control *ractl,
 		mark = ULONG_MAX;
 	}
 
-	new_order = min(mapping_max_folio_order(mapping), new_order);
-	new_order = min_t(unsigned int, new_order, ilog2(ra->size));
-	new_order = max(new_order, min_order);
-
 	ra->order = new_order;
 
 	/* See comment in page_cache_ra_unbounded() */
@@ -656,7 +681,7 @@ void page_cache_async_ra(struct readahead_control *ractl,
 	unsigned long max_pages;
 	struct file_ra_state *ra = ractl->ra;
 	pgoff_t index = readahead_index(ractl);
-	pgoff_t expected, start, end, aligned_end, align;
+	pgoff_t expected, start;
 
 	/* no readahead */
 	if (!ra->ra_pages)
@@ -710,13 +735,9 @@ void page_cache_async_ra(struct readahead_control *ractl,
 	ra->size = get_next_ra_size(ra, max_pages);
 readit:
 	ra->order += 2;
-	align = 1UL << min(ra->order, ffs(max_pages) - 1);
-	end = ra->start + ra->size;
-	aligned_end = round_down(end, align);
-	if (aligned_end > ra->start)
-		ra->size -= end - aligned_end;
 	ra->async_size = ra->size;
 	ractl->_index = ra->start;
+	ractl->_align_end = true;
 	page_cache_ra_order(ractl, ra);
 }
 EXPORT_SYMBOL_GPL(page_cache_async_ra);

---
base-commit: 9c449f885765cf8d80b2c60b1971e774bba51a3f
change-id: 20261029-mm-readahead-async-align-e491b3dc16a6

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

