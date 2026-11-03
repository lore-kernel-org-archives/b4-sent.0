From: Daejun Park <daejun7.park@samsung.com>
Date: Tue, 03 Nov 2026 18:04:11 +0900
Subject: [PATCH] pnfs/blocklayout: commit the layout before reading through
 the MDS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-nfs-bl-mdsread-v1-1-9b29915bbab7@samsung.com>
X-B4-Tracking: v=1; b=H4sIAIqj6WoC/x3MQQqAIBBA0avErBvIFKGuEi1MxxooCwcikO6et
 HyL/wsIZSaBsSmQ6WbhM1WotgG/ubQScqiGvuut6rTCFAWXHY8gmVxAbWyM3tDgvIEaXZkiP/9
 wmt/3A3KBvq9gAAAA
To: Trond Myklebust <trondmy@kernel.org>, Anna Schumaker <anna@kernel.org>
Cc: Christoph Hellwig <hch@lst.de>, 
 Benjamin Coddington <ben.coddington@hammerspace.com>, 
 linux-nfs@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793696650; l=2270;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=WBV4O1aChXYgb5EMs6LEz+MGYblqNH73Uzx1H9P7xWs=;
 b=MfOWEb1eb+VnNW12yPE3M4dqZNyh7pwb45bt0Tbf86q39cKdg2S+NZ4FsUiHDlZ0zrjhbvIRm
 JJF8zzlKF16ACuVyqEup9uFBlYAWL+E7gv125j6CewpSudPQzDX6EXv
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bl_pg_init_read() sends some reads to the MDS, such as unaligned
O_DIRECT reads. The MDS need not see layout writes before LAYOUTCOMMIT
(RFC 8881, section 12.5.4). With Linux nfsd on XFS, such a read after
an O_DIRECT write into a hole returns zeroes.

Send a synchronous LAYOUTCOMMIT first. An asynchronous one could be
overtaken by the READ. If the LAYOUTCOMMIT returns an error, fail the
read.

Fixes: f742dc4a3258 ("pnfsblock: fix non-aligned DIO read")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
Tested with Linux nfsd on XFS, unaligned O_DIRECT reads only. The read
after the write returned zeroes in 5 of 5 runs before and the data
after. generic/013, 091 and 263 pass.

A failed LAYOUTCOMMIT now fails the read instead of a later fsync.

"pnfs/blocklayout: don't let a READ layout hide written extents" fixes
the same zeroes for reads through a READ layout.
---
 fs/nfs/blocklayout/blocklayout.c | 13 ++++++++++++-
 1 file changed, 12 insertions(+), 1 deletion(-)

diff --git a/fs/nfs/blocklayout/blocklayout.c b/fs/nfs/blocklayout/blocklayout.c
index b7a3211c58..54825aaad3 100644
--- a/fs/nfs/blocklayout/blocklayout.c
+++ b/fs/nfs/blocklayout/blocklayout.c
@@ -839,12 +839,16 @@ is_aligned_req(struct nfs_pageio_descriptor *pgio,
 static void
 bl_pg_init_read(struct nfs_pageio_descriptor *pgio, struct nfs_page *req)
 {
+	int err;
+
 	if (!is_aligned_req(pgio, req, SECTOR_SIZE, false)) {
 		nfs_pageio_reset_read_mds(pgio);
-		return;
+		goto out_commit;
 	}
 
 	pnfs_generic_pg_init_read(pgio, req);
+	if (pgio->pg_error < 0)
+		return;
 
 	if (pgio->pg_lseg &&
 		test_bit(NFS_LSEG_UNAVAILABLE, &pgio->pg_lseg->pls_flags)) {
@@ -853,6 +857,13 @@ bl_pg_init_read(struct nfs_pageio_descriptor *pgio, struct nfs_page *req)
 		pnfs_set_lo_fail(pgio->pg_lseg);
 		nfs_pageio_reset_read_mds(pgio);
 	}
+	if (pgio->pg_lseg)
+		return;
+out_commit:
+	/* The MDS may not see layout writes until LAYOUTCOMMIT. */
+	err = pnfs_layoutcommit_inode(pgio->pg_inode, true);
+	if (err < 0)
+		pgio->pg_error = err;
 }
 
 /*

---
base-commit: eea3fef32a9cf36abcb5975a5a594e4135a6b026
change-id: 20261031-nfs-bl-mdsread-346ffc4e9ac4

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

