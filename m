From: Sadman Fahmid <sadmanf@meta.com>
Date: Tue, 06 Oct 2026 14:04:47 -0400
Subject: [PATCH RESEND 1/2] erofs-utils: lib: fail instead of hanging on
 short reads in erofs_io_xcopy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261006-round1-v1-1-f46b13e11de5@meta.com>
References: <20261006-round1-v1-0-f46b13e11de5@meta.com>
In-Reply-To: <20261006-round1-v1-0-f46b13e11de5@meta.com>
To: linux-erofs@lists.ozlabs.org
Cc: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Sadman Fahmid <sadmanf@meta.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791309888; l=2316;
 i=sadmanf@meta.com; s=20261006; h=from:subject:message-id;
 bh=MG1JVt9vDkGzgmziW91mbF0J45QsL9V9glXUQlVfwfM=;
 b=+Wk7c3nEWhH4GDZ3jTCS4POAXfxBn7Nh9hao7gxPKCKKLIA0VMg8IkfwmGvJxJqYPOGnE6Cw+
 XRcLZ8lGYj9CidHfB4Fb/mEsAFuyC8Abj9Hk6XWitiEE+txhZUY/FFt
X-Developer-Key: i=sadmanf@meta.com; a=ed25519;
 pk=Pc/arXJpm1RPef8qImFuHROn1p3XNX5MWSUxjZWNTa4=
X-Endpoint-Received: by B4 Relay for sadmanf@meta.com/20261006 with auth_id=1125
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

erofs_io_xcopy() falls back to a read/pwrite loop for whatever
copy_file_range() and sendfile() did not copy.  If the source reaches
EOF before `len` bytes have been copied, erofs_io_read() returns 0,
`len` never shrinks and mkfs spins forever instead of reporting the
error.

This is easy to hit with a damaged source, e.g. rebuilding with
`mkfs.erofs --clean=data out.img src.img` where src.img is truncated
in the middle of a file's data, or when a source file shrinks while
mkfs runs.  Return -EIO instead.

While at it, keep calling copy_file_range() until it has copied the
whole range or fails.  A single call may copy less than requested
(e.g. the kernel caps each call at MAX_RW_COUNT, just under 2 GiB,
while callers pass chunks of up to 4 GiB), and the remainder was
previously copied by sendfile() instead of being reflinked.

Signed-off-by: Sadman Fahmid <sadmanf@meta.com>
---
 lib/io.c | 29 ++++++++++++++++-------------
 1 file changed, 16 insertions(+), 13 deletions(-)

diff --git a/lib/io.c b/lib/io.c
index 5c5449f..038fa51 100644
--- a/lib/io.c
+++ b/lib/io.c
@@ -642,9 +642,13 @@ int erofs_io_xcopy(struct erofs_vfile *vout, off_t pos,
 		off_t ret __maybe_unused;
 
 #ifdef HAVE_COPY_FILE_RANGE
-		ret = copy_file_range(vin->fd, NULL, vout->fd, &pos, len, 0);
-		if (ret > 0)
+		while (len) {
+			ret = copy_file_range(vin->fd, NULL, vout->fd, &pos,
+					      len, 0);
+			if (ret <= 0)
+				break;
 			len -= ret;
+		}
 #endif
 #if defined(HAVE_SYS_SENDFILE_H) && defined(HAVE_SENDFILE)
 		if (len && !noseek) {
@@ -660,21 +664,20 @@ int erofs_io_xcopy(struct erofs_vfile *vout, off_t pos,
 #endif
 	}
 
-	do {
+	while (len) {
 		char buf[32768];
-		int ret = min_t(unsigned int, len, sizeof(buf));
+		ssize_t nread, ret;
 
-		ret = erofs_io_read(vin, buf, ret);
+		nread = erofs_io_read(vin, buf, min_t(unsigned int, len,
+						      sizeof(buf)));
+		if (nread <= 0)
+			return nread < 0 ? nread : -EIO;
+		ret = erofs_io_pwrite(vout, buf, pos, nread);
 		if (ret < 0)
 			return ret;
-		if (ret > 0) {
-			ret = erofs_io_pwrite(vout, buf, pos, ret);
-			if (ret < 0)
-				return ret;
-			pos += ret;
-		}
-		len -= ret;
-	} while (len);
+		pos += nread;
+		len -= nread;
+	}
 	return 0;
 }
 

-- 
2.53.0-Meta

