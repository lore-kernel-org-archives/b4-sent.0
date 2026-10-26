From: Daejun Park <daejun7.park@samsung.com>
Date: Mon, 26 Oct 2026 10:54:05 +0900
Subject: [PATCH 1/2] xfs: don't skip free extents in later batches of a
 whole-AG FITRIM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-xfs-fitrim-skip-v1-1-cddd8414f99c@samsung.com>
References: <20261026-xfs-fitrim-skip-v1-0-cddd8414f99c@samsung.com>
In-Reply-To: <20261026-xfs-fitrim-skip-v1-0-cddd8414f99c@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Dave Chinner <dgc@kernel.org>, 
 Christoph Hellwig <hch@lst.de>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792979644; l=2664;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=DE365ED791/wL0LS/rT/QAJXNoFtBUJ5xTlLjkGgwvg=;
 b=g/3nDUd4lVQpRloxEOxvQahx9DatIYcS7ZBFC0N1+fRSDlymFNElW9xpALEYpmKvuqI6eYdXg
 91u87HoOC9oD+fBH5cKgcnRbK6vpyUtnVtNh87ZLwhXnWRwwWPD1bfG
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A whole-device FITRIM walks every AG but the last by length, in
batches. xfs_trim_gather_extents() saves the record to restart from in
tcur->start. But tcur->start is also the start of the range to trim.
Later batches therefore never discard the free extents below that
block.

Save the restart record in a new restart_bno field.

Cc: stable@vger.kernel.org # v6.10
Fixes: b0ffe661fab4 ("xfs: fix performance problems when fstrimming a subset of a fragmented AG")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
In the first layout of the new fstests case xfs/842, 409 of 512 free
extents that held data were not discarded without this patch, and none
with it.
---
 fs/xfs/xfs_discard.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)

diff --git a/fs/xfs/xfs_discard.c b/fs/xfs/xfs_discard.c
index 906221ffe9..8120f136af 100644
--- a/fs/xfs/xfs_discard.c
+++ b/fs/xfs/xfs_discard.c
@@ -155,6 +155,8 @@ struct xfs_trim_cur {
 	xfs_agblock_t	end;
 	xfs_extlen_t	minlen;
 	bool		by_bno;
+	/* restart point (with count) for the by-length walk */
+	xfs_agblock_t	restart_bno;
 };
 
 static int
@@ -198,14 +200,15 @@ xfs_trim_gather_extents(
 		error = xfs_alloc_lookup_le(cur, tcur->start, 0, &i);
 		if (!error && !i)
 			error = xfs_alloc_lookup_ge(cur, tcur->start, 0, &i);
-	} else if (tcur->start == 0) {
+	} else if (tcur->restart_bno == NULLAGBLOCK) {
 		/* first time through a by-len starts with max length */
 		cur = xfs_cntbt_init_cursor(mp, tp, agbp, pag);
 		error = xfs_alloc_lookup_ge(cur, 0, tcur->count, &i);
 	} else {
 		/* nth time through a by-len starts where we left off */
 		cur = xfs_cntbt_init_cursor(mp, tp, agbp, pag);
-		error = xfs_alloc_lookup_le(cur, tcur->start, tcur->count, &i);
+		error = xfs_alloc_lookup_le(cur, tcur->restart_bno,
+					    tcur->count, &i);
 	}
 	if (error)
 		goto out_del_cursor;
@@ -235,9 +238,15 @@ xfs_trim_gather_extents(
 		if (--batch <= 0) {
 			/*
 			 * Update the cursor to point at this extent so we
-			 * restart the next batch from this extent.
+			 * restart the next batch from this extent. The
+			 * by-length walk does not visit extents in block
+			 * order, so it must keep the start of the range and
+			 * restart from restart_bno instead.
 			 */
-			tcur->start = fbno;
+			if (tcur->by_bno)
+				tcur->start = fbno;
+			else
+				tcur->restart_bno = fbno;
 			tcur->count = flen;
 			break;
 		}
@@ -340,6 +349,7 @@ xfs_trim_perag_extents(
 		.start		= start,
 		.end		= end,
 		.minlen		= minlen,
+		.restart_bno	= NULLAGBLOCK,
 	};
 	int			error = 0;
 

-- 
2.43.0

