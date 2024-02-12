From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:04 +0000
Subject: [PATCH kmod 03/13] libkmod: remove kmod_file::{zstd,xz}_used flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-3-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1540;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=Og0Ag/13F9A4cnAYBK+i+58A4Qix9B4oLZpytfwcabE=;
 b=aqf5N4FQGPUJAkW7v1M065AjQGCZxzI5UInNS0o3k8GazeKKfCR1OKQNJtmvKH6MCNDNBKR6K
 obDFm5x/S3+CxA9y7o9AY+DIA7ZDyuuIVZ9t12G1IGf5Ist8bvXzdWi
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are used to protect a free(file->memory), within their respective
unload functions. Where the sole caller of the unload function already
does a NULL check prior.

Even so, free(NULL) is guaranteed to be safe by the standard.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 12 ------------
 1 file changed, 12 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index 9a014ea..abd4723 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -48,12 +48,6 @@ struct file_ops {
 };
 
 struct kmod_file {
-#ifdef ENABLE_ZSTD
-	bool zstd_used;
-#endif
-#ifdef ENABLE_XZ
-	bool xz_used;
-#endif
 	int fd;
 	enum kmod_file_compression_type compression;
 	off_t size;
@@ -176,7 +170,6 @@ static int load_zstd(struct kmod_file *file)
 
 	ZSTD_freeDStream(dstr);
 	free((void *)zst_inb.src);
-	file->zstd_used = true;
 	file->memory = zst_outb.dst;
 	file->size = zst_outb.pos;
 	return 0;
@@ -190,8 +183,6 @@ out:
 
 static void unload_zstd(struct kmod_file *file)
 {
-	if (!file->zstd_used)
-		return;
 	free(file->memory);
 }
 
@@ -269,7 +260,6 @@ static int xz_uncompress(lzma_stream *strm, struct kmod_file *file)
 			goto out;
 		}
 	}
-	file->xz_used = true;
 	file->memory = p;
 	file->size = total;
 	return 0;
@@ -299,8 +289,6 @@ static int load_xz(struct kmod_file *file)
 
 static void unload_xz(struct kmod_file *file)
 {
-	if (!file->xz_used)
-		return;
 	free(file->memory);
 }
 

-- 
2.43.0

