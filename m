From: Sadman Fahmid <sadmanf@meta.com>
Date: Tue, 06 Oct 2026 14:04:48 -0400
Subject: [PATCH RESEND 2/2] erofs-utils: lib: close source fd on early
 errors in erofs_mkfs_begin_nondirectory()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-round1-v1-2-f46b13e11de5@meta.com>
References: <20261006-round1-v1-0-f46b13e11de5@meta.com>
In-Reply-To: <20261006-round1-v1-0-f46b13e11de5@meta.com>
To: linux-erofs@lists.ozlabs.org
Cc: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Sadman Fahmid <sadmanf@meta.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791309888; l=1980;
 i=sadmanf@meta.com; s=20261006; h=from:subject:message-id;
 bh=rn2AYDk4gmNMAZ6KTROzM/iZXd90ZGk0DihnmePza4U=;
 b=Gk5IZRNu6v+G5DBuxx3rm09sZWx2dR6iizzPCzJ/FUeWsr/3qAZMVKkbdoHK6cpOgE79gLFlU
 QMZ0uu1fHbCCW9eHazq1U1o4Q81wdVMYTtj8TmoFy4/ZMkqpmGkGXOp
X-Developer-Key: i=sadmanf@meta.com; a=ed25519;
 pk=Pc/arXJpm1RPef8qImFuHROn1p3XNX5MWSUxjZWNTa4=
X-Endpoint-Received: by B4 Relay for sadmanf@meta.com/20261006 with auth_id=1125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If erofs_set_inode_fingerprint() or erofs_prepare_compressed_file()
fails, the source file descriptor opened just above is never closed
since the job carrying it is never queued.  Close it on those paths.

The diskbuf descriptor is left alone as it is owned by the diskbuf.

Signed-off-by: Sadman Fahmid <sadmanf@meta.com>

---
The erofs_begin_compressed_file() failure path is left as is: with
multi-threaded compression, z_erofs_mt_compress() may fail after some
segments have already been queued to workers that read from the fd,
so closing it there would be unsafe.
---
 lib/inode.c | 14 +++++++++++---
 1 file changed, 11 insertions(+), 3 deletions(-)

diff --git a/lib/inode.c b/lib/inode.c
index ec96556..489c44e 100644
--- a/lib/inode.c
+++ b/lib/inode.c
@@ -2086,14 +2086,16 @@ static int erofs_mkfs_begin_nondirectory(const struct erofs_mkfs_btctx *btctx,
 
 		ret = erofs_set_inode_fingerprint(inode, ctx.fd, ctx.fpos);
 		if (ret < 0)
-			return ret;
+			goto err_close;
 
 		if (inode->datasource != EROFS_INODE_DATA_SOURCE_REBUILD_BLOB &&
 		    inode->sbi->available_compr_algs &&
 		    erofs_file_is_compressible(im, inode)) {
 			ctx.ictx = erofs_prepare_compressed_file(im, inode);
-			if (IS_ERR(ctx.ictx))
-				return PTR_ERR(ctx.ictx);
+			if (IS_ERR(ctx.ictx)) {
+				ret = PTR_ERR(ctx.ictx);
+				goto err_close;
+			}
 			erofs_bind_compressed_file_with_fd(ctx.ictx,
 							   ctx.fd, ctx.fpos);
 			ret = erofs_begin_compressed_file(ctx.ictx);
@@ -2103,6 +2105,12 @@ static int erofs_mkfs_begin_nondirectory(const struct erofs_mkfs_btctx *btctx,
 	}
 out:
 	return erofs_mkfs_go(btctx, EROFS_MKFS_JOB_NDIR, &ctx, sizeof(ctx));
+
+err_close:
+	/* the diskbuf fd is shared and released along with the diskbuf */
+	if (inode->datasource != EROFS_INODE_DATA_SOURCE_DISKBUF)
+		close(ctx.fd);
+	return ret;
 }
 
 static int erofs_mkfs_handle_inode(const struct erofs_mkfs_btctx *ctx,

-- 
2.53.0-Meta

