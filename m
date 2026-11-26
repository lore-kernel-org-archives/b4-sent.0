From: Daejun Park <daejun7.park@samsung.com>
Date: Thu, 26 Nov 2026 10:45:24 +0900
Subject: [PATCH] nfsd: stop a block layout at the maximum file size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-nfsd-block-maxbytes-v1-1-1869942523f9@samsung.com>
X-B4-Tracking: v=1; b=H4sIADOPB2sC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQyMz3by04hTdpJz85Gzd3MSKpMqS1GJdI9M0c3NT05QkY4NEJaDOgqL
 UtMwKsKnRsbW1ADkIto9lAAAA
To: Chuck Lever <cel@kernel.org>, Jeff Layton <jlayton@kernel.org>
Cc: NeilBrown <neil@brown.name>, Olga Kornievskaia <okorniev@redhat.com>, 
 Dai Ngo <Dai.Ngo@oracle.com>, Tom Talpey <tom@talpey.com>, 
 Christoph Hellwig <hch@lst.de>, Sergey Bashirov <sergeybashirov@gmail.com>, 
 linux-nfs@vger.kernel.org, Daejun Park <daejun7.park@samsung.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795657523; l=1992;
 i=daejun7.park@samsung.com; s=20261006; h=from:subject:message-id;
 bh=NszbfrGTuRyaQObY/OY6rQ5VCgbAPzgwgkSXEuIR8lY=;
 b=13UcwiZpfABYvEKSs3/K7KnvvOT5MTk6vV+4Z0WbZ8B4cz7NB7xvfKFFpkmO9q0mhNaPdoa9p
 UqaUecEXjJoAi/bmHFbaJS1MrFk3+m0CEbkHINIXwqXKkGsmN6P5kl5
X-Developer-Key: i=daejun7.park@samsung.com; a=ed25519;
 pk=4yUfDqGRZTIj0Ik43z1GoMZRWCNm/rgX6uJuM9dtNIg=
X-Endpoint-Received: by B4 Relay for daejun7.park@samsung.com/20261006 with auth_id=1122
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

nfsd4_block_proc_layoutget() calls ->map_blocks again for the rest of
the range after each extent. If the range runs past the maximum file
size, an extent from XFS reaches that size. The next call then asks
for an offset at or past it. Since commit 29f3c1be4e55 ("xfs: clamp
the pNFS layout range to the maximum file size"), xfs_fs_map_blocks()
rejects such an offset with -EINVAL. The LAYOUTGET then fails with
NFS4ERR_INVAL. pynfs GETLAYOUT1, a READ for NFS4_UINT64_MAX, fails
this way.

Stop the loop at an extent that reaches the maximum file size.

Fixes: cc6c40e09d7b ("NFSD/blocklayout: Support multiple extents per LAYOUTGET")
Signed-off-by: Daejun Park <daejun7.park@samsung.com>
---
pynfs GETLAYOUT1 and a READ for NFS4_UINT64_MAX at offset 4096 of a
64 KiB file now get a layout up to 2^63. fstests generic/075, 091 and
263 over the block and SCSI layouts, and the pynfs block tests over
the block layout, give the same results as on nfsd-testing (generic/075
fails with fsx errors on both).

7.4 and 7.3.y (with the backport of 29f3c1be4e55) return the
NFS4ERR_INVAL, so they may want this in stable. Older LTS kernels map
one extent per LAYOUTGET.
---
 fs/nfsd/blocklayout.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/fs/nfsd/blocklayout.c b/fs/nfsd/blocklayout.c
index 23f2365787e..c8942191b5f 100644
--- a/fs/nfsd/blocklayout.c
+++ b/fs/nfsd/blocklayout.c
@@ -182,7 +182,9 @@ nfsd4_block_proc_layoutget(struct svc_rqst *rqstp, struct inode *inode,
 		}
 
 		bex_length = bex->len - (offset - bex->foff);
-		if (bex_length >= length) {
+		/* There is nothing to map past the maximum file size. */
+		if (bex_length >= length ||
+		    bex->foff + bex->len >= inode->i_sb->s_maxbytes) {
 			bl->nr_extents = i + 1;
 			break;
 		}

---
base-commit: 6f174a0eca19e69a14c34b0ed56b60d484f22fd6
change-id: 20261126-nfsd-block-maxbytes-25f7755db30a

Best regards,
-- 
Daejun Park <daejun7.park@samsung.com>

