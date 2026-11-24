From: Ernest Borowski <ernest.borowski.git@proton.me>
Date: Tue, 24 Nov 2026 23:49:35 +0100
Subject: [PATCH v2 01/11] iomap: punch out a run of clean blocks in one
 call
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-b4-ntfs-delalloc-fixes-v2-1-f394c800ec03@proton.me>
References: <20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me>
In-Reply-To: <20261124-b4-ntfs-delalloc-fixes-v2-0-f394c800ec03@proton.me>
To: Namjae Jeon <linkinjeon@kernel.org>, Hyunchul Lee <hyc.lee@gmail.com>, 
 Baolin Liu <liubaolin12138@163.com>
Cc: Christian Brauner <brauner@kernel.org>, Christoph Hellwig <hch@lst.de>, 
 "Darrick J. Wong" <djwong@kernel.org>, ntfs@lists.linux.dev, 
 linux-fsdevel@vger.kernel.org, linux-xfs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Zhan Xusheng <zhanxusheng1024@gmail.com>, 
 stable@vger.kernel.org, Ernest Borowski <ernest.borowski.git@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2172;
 i=ernest.borowski.git@proton.me; s=default; h=from:subject:message-id;
 bh=QlRHNgKKZw1I17ErZyU+XJVQumdcF0YH4l4Xvps8Y4o=;
 b=owGbwMvMwCVWzJ65uCpJ5D/jabUkhmw2kXrbcEuZj8WTn5SXF3TU3fhumjPpeBfHAf7Fsy/Mr
 p6W6XWho5SFQYyLQVZMkaXj/40Qn5Bvn5bFafXBzGFlAhnCwMUpABPpncrwP3WTxrEsYwPOb+9W
 t005uONeCXPV+6b5s13tZjkaFUrMeM7I0Ls75ffh+7mzPCR1N+UreArvq7b/Fs/FluHCdu117tM
 aXgA=
X-Developer-Key: i=ernest.borowski.git@proton.me; a=openpgp;
 fpr=88FFD8544C54F6F2A65E2A8E730769A37A6214FF
X-Endpoint-Received: by B4 Relay for ernest.borowski.git@proton.me/default with auth_id=1589
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iomap_write_delalloc_ifs_punch() calls ->punch() once for every clean
block of a dirty folio.  A file system that reserves delayed allocation
space in units larger than a block can release a unit only when one call
covers it whole.  ntfs reserves whole clusters and uses 512 byte blocks,
so with 1 KiB clusters a buffered write into a hole that fails after
zeroing the first cluster of a 4 KiB folio leaves the other three
clusters of that folio reserved, and writeback later allocates them.

Pass each run of contiguous clean blocks to ->punch() in one call.  XFS
and ext4 punch any range they are given, so for them this only means
fewer calls.

"ntfs: punch out the delalloc reservation of a failed buffered write"
later in this series needs this, so it goes to stable with it.

Cc: stable@vger.kernel.org
Signed-off-by: Ernest Borowski <ernest.borowski.git@proton.me>
---
 fs/iomap/buffered-io.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/fs/iomap/buffered-io.c b/fs/iomap/buffered-io.c
index 6d843b168d..2eb8070e34 100644
--- a/fs/iomap/buffered-io.c
+++ b/fs/iomap/buffered-io.c
@@ -1364,6 +1364,9 @@ static void iomap_write_delalloc_ifs_punch(struct inode *inode,
 	 * blocks within a folio which are marked uptodate
 	 * but not dirty. In that case it is necessary to punch
 	 * out such blocks to avoid leaking any delalloc blocks.
+	 * Pass each run of clean blocks in one call: a file system
+	 * that reserves space in units larger than a block can only
+	 * release a unit that it sees whole.
 	 */
 	ifs = folio->private;
 	if (!ifs)
@@ -1374,9 +1377,12 @@ static void iomap_write_delalloc_ifs_punch(struct inode *inode,
 	last_blk = offset_in_folio(folio, last_byte) >> blkbits;
 	while ((first_blk = ifs_next_clean_block(folio, first_blk, last_blk))
 		       <= last_blk) {
+		unsigned int next_blk = ifs_next_dirty_block(folio,
+				first_blk + 1, last_blk);
+
 		punch(inode, folio_pos(folio) + (first_blk << blkbits),
-				1 << blkbits, iomap);
-		first_blk++;
+				(loff_t)(next_blk - first_blk) << blkbits, iomap);
+		first_blk = next_blk;
 	}
 }
 

-- 
2.56.1

