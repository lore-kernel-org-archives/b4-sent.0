From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:03 +0000
Subject: [PATCH kmod 02/13] libkmod: keep gzFile gzf local to load_zlib()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-2-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=2092;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=dynpgl/ahQS0pC4J5FA730cbtaNUmwCDCWyHTxZtfko=;
 b=OnaUsbxYZ1j1uQmSCFipwGIFtNN8dmD0R7GfYhZHCJ6r1O5/r7Ky9N25ElRq+TF9mpNveY4dr
 yjzTTMwWFB4CPJeIKLtf5C+Kac7WAC5GaD+20bc0kU5EXgOGd02rQ9q
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no need to keep the root gzFile context open for the whole
duration. Once we've copied the decompressed module to file->memory we
can close the handle.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 18 +++++++-----------
 1 file changed, 7 insertions(+), 11 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index b97062b..9a014ea 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -53,9 +53,6 @@ struct kmod_file {
 #endif
 #ifdef ENABLE_XZ
 	bool xz_used;
-#endif
-#ifdef ENABLE_ZLIB
-	gzFile gzf;
 #endif
 	int fd;
 	enum kmod_file_compression_type compression;
@@ -317,6 +314,7 @@ static int load_zlib(struct kmod_file *file)
 	int err = 0;
 	off_t did = 0, total = 0;
 	_cleanup_free_ unsigned char *p = NULL;
+	gzFile gzf;
 	int gzfd;
 
 	errno = 0;
@@ -324,8 +322,8 @@ static int load_zlib(struct kmod_file *file)
 	if (gzfd < 0)
 		return -errno;
 
-	file->gzf = gzdopen(gzfd, "rb"); /* takes ownership of the fd */
-	if (file->gzf == NULL) {
+	gzf = gzdopen(gzfd, "rb"); /* takes ownership of the fd */
+	if (gzf == NULL) {
 		close(gzfd);
 		return -errno;
 	}
@@ -343,12 +341,12 @@ static int load_zlib(struct kmod_file *file)
 			p = tmp;
 		}
 
-		r = gzread(file->gzf, p + did, total - did);
+		r = gzread(gzf, p + did, total - did);
 		if (r == 0)
 			break;
 		else if (r < 0) {
 			int gzerr;
-			const char *gz_errmsg = gzerror(file->gzf, &gzerr);
+			const char *gz_errmsg = gzerror(gzf, &gzerr);
 
 			ERR(file->ctx, "gzip: %s\n", gz_errmsg);
 
@@ -362,19 +360,17 @@ static int load_zlib(struct kmod_file *file)
 	file->memory = p;
 	file->size = did;
 	p = NULL;
+	gzclose(gzf);
 	return 0;
 
 error:
-	gzclose(file->gzf); /* closes the gzfd */
+	gzclose(gzf); /* closes the gzfd */
 	return err;
 }
 
 static void unload_zlib(struct kmod_file *file)
 {
-	if (file->gzf == NULL)
-		return;
 	free(file->memory);
-	gzclose(file->gzf);
 }
 
 static const char magic_zlib[] = {0x1f, 0x8b};

-- 
2.43.0

