From: Daejun Park <daejun7.park@samsung.com>
Date: Mon, 26 Oct 2026 10:54:06 +0900
Subject: [PATCH 2/2] xfs: don't skip free extents of the longest length in
 a whole-AG FITRIM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261026-xfs-fitrim-skip-v1-2-cddd8414f99c@samsung.com>
References: <20261026-xfs-fitrim-skip-v1-0-cddd8414f99c@samsung.com>
In-Reply-To: <20261026-xfs-fitrim-skip-v1-0-cddd8414f99c@samsung.com>
To: Carlos Maiolino <cem@kernel.org>, linux-xfs@vger.kernel.org
Cc: "Darrick J. Wong" <djwong@kernel.org>, Dave Chinner <dgc@kernel.org>, 
 Christoph Hellwig <hch@lst.de>, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792979644; l=2296;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=aB3YdzosB9+MLmbMgvq8EWq31a8TDk+3lXux5xdb1mU=;
 b=+Jv3c76RNB6Z7iHbgFJyUMxriwOSH/IwqigFKgIczG2+rmLqffC9/t8PhDA8iJqiS0g4JS3gl
 QKXWszn3tLwAhoTWz+l49zyKYhU0gS8CtPX+CJyR+MHTYwmSdG/bvoW
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit a66d636385d6 ("xfs: fix fstrim offset calculations"), the
by-length walk of an AG in FITRIM starts with
xfs_alloc_lookup_ge(cur, 0, pagf_longest) and walks down. The lookup
lands on the longest free extent with the lowest block number. The
other free extents of that length sort after it and are never
discarded.

Start every by-length batch with xfs_alloc_lookup_le() at restart_bno.

Suggested-by: Dave Chinner <dgc@kernel.org>
Link: https://lore.kernel.org/r/ZgiJWxVcVwag0fIP@dread.disaster.area
Cc: stable@vger.kernel.org
Fixes: a66d636385d6 ("xfs: fix fstrim offset calculations")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
In xfs/842, 6 of 15 free extents that held data were not discarded
without this patch, and none with it.

On v6.10 and later this needs the previous patch. Older stable trees
need a small backport, which I can send:
- 6.6.y: always use xfs_alloc_lookup_le(cur, tcur->ar_startblock,
  tcur->ar_blockcount, &i), and backport 23be716b1c4f ("xfs: don't
  assume perags are initialised when trimming AGs") with it.
- 5.10.y to 6.1.y: replace xfs_alloc_lookup_ge(cur, 0, agf_longest)
  with xfs_alloc_lookup_le(cur, NULLAGBLOCK, agf_longest).
---
 fs/xfs/xfs_discard.c | 10 +++++-----
 1 file changed, 5 insertions(+), 5 deletions(-)

diff --git a/fs/xfs/xfs_discard.c b/fs/xfs/xfs_discard.c
index 8120f136af..cdf660344c 100644
--- a/fs/xfs/xfs_discard.c
+++ b/fs/xfs/xfs_discard.c
@@ -200,12 +200,12 @@ xfs_trim_gather_extents(
 		error = xfs_alloc_lookup_le(cur, tcur->start, 0, &i);
 		if (!error && !i)
 			error = xfs_alloc_lookup_ge(cur, tcur->start, 0, &i);
-	} else if (tcur->restart_bno == NULLAGBLOCK) {
-		/* first time through a by-len starts with max length */
-		cur = xfs_cntbt_init_cursor(mp, tp, agbp, pag);
-		error = xfs_alloc_lookup_ge(cur, 0, tcur->count, &i);
 	} else {
-		/* nth time through a by-len starts where we left off */
+		/*
+		 * A by-len walk starts at the last record of the longest
+		 * length (restart_bno is NULLAGBLOCK until the first batch
+		 * ends) and then where the previous batch stopped.
+		 */
 		cur = xfs_cntbt_init_cursor(mp, tp, agbp, pag);
 		error = xfs_alloc_lookup_le(cur, tcur->restart_bno,
 					    tcur->count, &i);

-- 
2.43.0

