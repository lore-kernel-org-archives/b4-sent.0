From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:02 +0000
Subject: [PATCH kmod 01/13] libkmod: use a dup()'d fd for zlib
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-1-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1845;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=snuU8CYNYYFir4PHCqEikR5PrKmafS0jh0cCrGpEUuM=;
 b=A/1wI8pVP1bQlACvosmS2wNa1xBBVLNlKwBUCiOpgOtLSjrsJz8Nr6LUXy8LzXPKGfyCybfd1
 8iki4PVtcToDyhlELSQlynjr6lOEQoDlR47N2zPai316QqMjLV25iXJ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The gzdopen() API used, takes ownership of the fd. To make that more
explicit we clear it (-1) as applicable.

Yet again, kmod has explicit API to return the fd to the user - which
currently is used solely when uncompressed, so we're safe.

Regardless - simply duplicate the fd locally and use that with zlib.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 19 ++++++++++++-------
 1 file changed, 12 insertions(+), 7 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index b138e7e..b97062b 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -317,12 +317,18 @@ static int load_zlib(struct kmod_file *file)
 	int err = 0;
 	off_t did = 0, total = 0;
 	_cleanup_free_ unsigned char *p = NULL;
+	int gzfd;
 
 	errno = 0;
-	file->gzf = gzdopen(file->fd, "rb");
-	if (file->gzf == NULL)
+	gzfd = fcntl(file->fd, F_DUPFD_CLOEXEC, 3);
+	if (gzfd < 0)
+		return -errno;
+
+	file->gzf = gzdopen(gzfd, "rb"); /* takes ownership of the fd */
+	if (file->gzf == NULL) {
+		close(gzfd);
 		return -errno;
-	file->fd = -1; /* now owned by gzf due gzdopen() */
+	}
 
 	for (;;) {
 		int r;
@@ -359,7 +365,7 @@ static int load_zlib(struct kmod_file *file)
 	return 0;
 
 error:
-	gzclose(file->gzf);
+	gzclose(file->gzf); /* closes the gzfd */
 	return err;
 }
 
@@ -368,7 +374,7 @@ static void unload_zlib(struct kmod_file *file)
 	if (file->gzf == NULL)
 		return;
 	free(file->memory);
-	gzclose(file->gzf); /* closes file->fd */
+	gzclose(file->gzf);
 }
 
 static const char magic_zlib[] = {0x1f, 0x8b};
@@ -535,7 +541,6 @@ void kmod_file_unref(struct kmod_file *file)
 	if (file->memory)
 		file->ops->unload(file);
 
-	if (file->fd >= 0)
-		close(file->fd);
+	close(file->fd);
 	free(file);
 }

-- 
2.43.0

