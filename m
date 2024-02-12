From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:09 +0000
Subject: [PATCH kmod 08/13] libkmod: always detect the module compression
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-8-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=2385;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=vnwce2nmhp+gEWObCw0gKQhrZ2WjtAclB1+9aE/85S8=;
 b=N2d9JcCxy/n8uPTm3GLc3XE68bos/hi+cNfNg3vQfzE38+bxAugKCSQKaJI5QyXq15WsecDsU
 +uv2gnZoD+ED061sNEYeRuEr2BJRmPdokQvyo8WMkv37KdX0KHC+e2N
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently, when built w/o given compression we'll incorrectly report a
"compression_none".

As we reach do_finit_module(), we'll naively assume that the kernel can
handle the compressed module, yet omit the MODULE_INIT_COMPRESSED_FILE
flag.

As result the kernel will barf at us, do_finit_module will fail with non
-ENOSYS and we won't end in the do_init_module codepath (which will also
fail).

In other words: with this change, you can build kmod without zstd, xz
and zlib support and the kernel will load the modules, assuming it
supports the format \o/

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 27 ++++++++++++++++++---------
 1 file changed, 18 insertions(+), 9 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index 3a79464..b69f1ef 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -174,9 +174,14 @@ out:
 	free((void *)zst_outb.dst);
 	return ret;
 }
+#else
+static int load_zstd(struct kmod_file *file)
+{
+	return -ENOSYS;
+}
+#endif
 
 static const char magic_zstd[] = {0x28, 0xB5, 0x2F, 0xFD};
-#endif
 
 #ifdef ENABLE_XZ
 static void xz_uncompress_belch(struct kmod_file *file, lzma_ret ret)
@@ -275,9 +280,14 @@ static int load_xz(struct kmod_file *file)
 	lzma_end(&strm);
 	return ret;
 }
+#else
+static int load_xz(struct kmod_file *file)
+{
+	return -ENOSYS;
+}
+#endif
 
 static const char magic_xz[] = {0xfd, '7', 'z', 'X', 'Z', 0};
-#endif
 
 #ifdef ENABLE_ZLIB
 #define READ_STEP (4 * 1024 * 1024)
@@ -339,9 +349,14 @@ error:
 	gzclose(gzf); /* closes the gzfd */
 	return err;
 }
+#else
+static int load_zlib(struct kmod_file *file)
+{
+	return -ENOSYS;
+}
+#endif
 
 static const char magic_zlib[] = {0x1f, 0x8b};
-#endif
 
 static const struct comp_type {
 	size_t magic_size;
@@ -349,15 +364,9 @@ static const struct comp_type {
 	const char *magic_bytes;
 	int (*load)(struct kmod_file *file);
 } comp_types[] = {
-#ifdef ENABLE_ZSTD
 	{sizeof(magic_zstd),	KMOD_FILE_COMPRESSION_ZSTD, magic_zstd, load_zstd},
-#endif
-#ifdef ENABLE_XZ
 	{sizeof(magic_xz),	KMOD_FILE_COMPRESSION_XZ, magic_xz, load_xz},
-#endif
-#ifdef ENABLE_ZLIB
 	{sizeof(magic_zlib),	KMOD_FILE_COMPRESSION_ZLIB, magic_zlib, load_zlib},
-#endif
 	{0,			KMOD_FILE_COMPRESSION_NONE, NULL, NULL}
 };
 

-- 
2.43.0

