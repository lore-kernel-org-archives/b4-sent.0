From: Daejun Park <daejun7.park@samsung.com>
Date: Fri, 30 Oct 2026 12:52:57 +0900
Subject: [PATCH] mm/readahead: keep at least half of the async window when
 aligning it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261030-mm-readahead-async-align-v1-1-109dea6851fc@samsung.com>
X-B4-Tracking: v=1; b=H4sIAJgU5GoC/x2MQQqAIBAAvxJ7biEthPpKdNh0q4WyUIhC/HvSZ
 WAOMwkiB+EIQ5Ug8C1RTl9E1RXYjfzKKK446EYb1egejwMDk6OtACm+3iLtsnrkrldz66wyZKD
 kV+BFnn89Tjl/F5UzkmoAAAA=
To: Andrew Morton <akpm@linux-foundation.org>, 
 "Matthew Wilcox (Oracle)" <willy@infradead.org>, Jan Kara <jack@suse.cz>
Cc: Ryan Roberts <ryan.roberts@arm.com>, linux-fsdevel@vger.kernel.org, 
 linux-mm@kvack.org, linux-kernel@vger.kernel.org, 
 Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793332376; l=2790;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=KlGeHCvXeiq1+GF1wuBXkFRE3vYfwUDNHyzWlyHiR68=;
 b=6sgU0Xgwqz6XOoOauwEV72LBz9kw9m5WlIYb+cqZUpHR8kgYzsAyqdlAug65ocGla5qbp/Hrj
 bPKuxR/UQasC8l7t1DapqPOFgn9m5GwmI0sdNdV2RMIBMd8du/pBJp+
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

page_cache_async_ra() trims the end of each new window to a multiple of
1 << ra->order pages. A window that starts just below such a boundary
keeps only a few pages. With read_ahead_kb=128 and max_sectors_kb=512,
1 MiB reads after a 4 KiB read at offset 0 hit this on about one window
in three. They issue three times as many device reads.

Halve the alignment until the trim keeps at least half of the window.

Fixes: 18ebe55a9236 ("mm/readahead: terminate async readahead on natural boundary")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested on mm-new in a QEMU guest with XFS on an emulated NVMe,
read_ahead_kb 128 and a cold cache.

- max_sectors_kb 512, median of 5 runs: reading a 512 MiB file this
  way takes 0.247 s before and 0.180 s after. The device sees 3329 and
  1032 reads.

- Other reads with max_sectors_kb 512: without the 4 KiB read, and with
  64 KiB reads, the times do not change. Random 4 KiB and 64 KiB reads,
  two interleaved streams on one file, and 2 MiB reads at random
  offsets also take the same time. They read the same amount from the
  device, within 0.3%.

With the device's transfer limit at 2 MiB:

- max_sectors_kb 256: 512 KiB reads after the 4 KiB read take 0.626 s
  before and 0.322 s after. The device sees 6147 and 2056 reads.

- max_sectors_kb 1024 or 2048: 1 MiB reads are not trimmed.

- max_sectors_kb 2048, 3 MiB reads: the device sees 343 instead of 271
  reads. The time is 0.120 s instead of 0.118 s, the median of 40 runs.
  The interquartile range is about 0.10 to 0.13 s for both. The window
  stays at 3/4 of the maximum, off the 2 MiB boundary. mm-new reaches
  that boundary by trimming deeply.
---
 mm/readahead.c | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/mm/readahead.c b/mm/readahead.c
index 6e55632902..f4da9b4606 100644
--- a/mm/readahead.c
+++ b/mm/readahead.c
@@ -713,6 +713,17 @@ void page_cache_async_ra(struct readahead_control *ractl,
 	align = 1UL << min(ra->order, ffs(max_pages) - 1);
 	end = ra->start + ra->size;
 	aligned_end = round_down(end, align);
+	/*
+	 * Keep at least half of the window when aligning its end. A
+	 * window that starts just below a large boundary would otherwise
+	 * shrink to a few pages and cap the folio order. Use a smaller
+	 * alignment instead.
+	 */
+	while (aligned_end > ra->start &&
+	       2 * (aligned_end - ra->start) < ra->size) {
+		align >>= 1;
+		aligned_end = round_down(end, align);
+	}
 	if (aligned_end > ra->start)
 		ra->size -= end - aligned_end;
 	ra->async_size = ra->size;

---
base-commit: 9c449f885765cf8d80b2c60b1971e774bba51a3f
change-id: 20261029-mm-readahead-async-align-e491b3dc16a6

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

