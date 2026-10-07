From: Sadman Fahmid <sadmanf@meta.com>
Date: Wed, 07 Oct 2026 15:15:26 -0400
Subject: [PATCH v2] erofs-utils: lib: fail instead of hanging on short
 reads in erofs_io_xcopy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261007-round1-v2-1-3ffc17bb9028@meta.com>
X-B4-Tracking: v=1; b=H4sIAE2axmoC/2XMQQ7CIBCF4as0sxbDoCJx1XuYLigMdhYtBirRN
 Nxd7Nbl//LybZApMWW4dRskKpw5Li3UoQM32eVBgn1rUFJplFKLFF+LR2HJGKNGRcFdoZ2fiQK
 /d+g+tJ44rzF9drfgb/0jCgopwlmPeCJET5d+ptUeXZxhqLV+AR8zXUubAAAA
In-Reply-To: <20261006-round1-v1-0-f46b13e11de5@meta.com>
References: <20261006-round1-v1-0-f46b13e11de5@meta.com>
To: linux-erofs@lists.ozlabs.org
Cc: Gao Xiang <xiang@kernel.org>, Chao Yu <chao@kernel.org>, 
 Sadman Fahmid <sadmanf@meta.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791400527; l=2792;
 i=sadmanf@meta.com; s=20261006; h=from:subject:message-id;
 bh=TGlOZrYN1BFG0KcNzoiID2GMDIUwqHE0DArnbupBDYs=;
 b=KU3kb7pUkikuqdy3RGrl90IRL5z9+/Rk9Hr/k+Col/wwAuO8UWIjjVTc+JHssjtdiO7QFdPqD
 dDJpYpoY7aQAPYr9uvDk6MrtAI5hAICFBPzdxYfEV/KfkhW/jd0rNs5
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
Changes in v2:
- Use min_t(s64, len, sizeof(buf)) and int read/write result
  variables, as suggested by Gao Xiang. Each request is bounded
  to 32 KiB.
- Resend only the short-read fix. Gao Xiang already applied
  the fd-leak fix (patch 2 from v1).
- Link to v1:
  https://lore.kernel.org/r/20261006-round1-v1-0-f46b13e11de5@meta.com
---
 lib/io.c | 29 ++++++++++++++++-------------
 1 file changed, 16 insertions(+), 13 deletions(-)

diff --git a/lib/io.c b/lib/io.c
index 5c5449f..ea3bcbf 100644
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
+		int nread = min_t(s64, len, sizeof(buf));
+		int ret;
 
-		ret = erofs_io_read(vin, buf, ret);
+		nread = erofs_io_read(vin, buf, nread);
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
 

---
base-commit: 1c230a485f25837cb51d6fc79332f30758d9006c
change-id: 20261006-round1-ae8882b2efc7

Best regards,
-- 
Sadman Fahmid <sadmanf@meta.com>

