From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:06 +0000
Subject: [PATCH kmod 05/13] libkmod: nuke struct file_ops
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-5-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=4466;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=0Vi3uPtKabgYtJwqqoOuNWe6m7WAwfuOOzVybC1+mxc=;
 b=6nMv7lsUTpUGAdN8xblVMwtjE4FhsCIXCc3bSCk7IXVXeBgnmw8kGK0mzTtvFFby+LhcH1FP/
 /XI9gFgfvArB87PrD/49nT++9/dzxR4+SKyeYDrul8SacWMru2Oj9c2
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

With the previous commits, we removed the need for a distinct unload
callback.

So nuke the struct all together and only use/keep the load one around.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 62 +++++++++++++++-----------------------------------
 1 file changed, 18 insertions(+), 44 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index b408aed..8a0336f 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -41,18 +41,12 @@
 #include "libkmod.h"
 #include "libkmod-internal.h"
 
-struct kmod_file;
-struct file_ops {
-	int (*load)(struct kmod_file *file);
-	void (*unload)(struct kmod_file *file);
-};
-
 struct kmod_file {
 	int fd;
 	enum kmod_file_compression_type compression;
 	off_t size;
 	void *memory;
-	const struct file_ops *ops;
+	int (*load)(struct kmod_file *file);
 	const struct kmod_ctx *ctx;
 	struct kmod_elf *elf;
 };
@@ -181,11 +175,6 @@ out:
 	return ret;
 }
 
-static void unload_zstd(struct kmod_file *file)
-{
-	free(file->memory);
-}
-
 static const char magic_zstd[] = {0x28, 0xB5, 0x2F, 0xFD};
 #endif
 
@@ -287,11 +276,6 @@ static int load_xz(struct kmod_file *file)
 	return ret;
 }
 
-static void unload_xz(struct kmod_file *file)
-{
-	free(file->memory);
-}
-
 static const char magic_xz[] = {0xfd, '7', 'z', 'X', 'Z', 0};
 #endif
 
@@ -356,11 +340,6 @@ error:
 	return err;
 }
 
-static void unload_zlib(struct kmod_file *file)
-{
-	free(file->memory);
-}
-
 static const char magic_zlib[] = {0x1f, 0x8b};
 #endif
 
@@ -368,18 +347,18 @@ static const struct comp_type {
 	size_t magic_size;
 	enum kmod_file_compression_type compression;
 	const char *magic_bytes;
-	const struct file_ops ops;
+	int (*load)(struct kmod_file *file);
 } comp_types[] = {
 #ifdef ENABLE_ZSTD
-	{sizeof(magic_zstd),	KMOD_FILE_COMPRESSION_ZSTD, magic_zstd, {load_zstd, unload_zstd}},
+	{sizeof(magic_zstd),	KMOD_FILE_COMPRESSION_ZSTD, magic_zstd, load_zstd},
 #endif
 #ifdef ENABLE_XZ
-	{sizeof(magic_xz),	KMOD_FILE_COMPRESSION_XZ, magic_xz, {load_xz, unload_xz}},
+	{sizeof(magic_xz),	KMOD_FILE_COMPRESSION_XZ, magic_xz, load_xz},
 #endif
 #ifdef ENABLE_ZLIB
-	{sizeof(magic_zlib),	KMOD_FILE_COMPRESSION_ZLIB, magic_zlib, {load_zlib, unload_zlib}},
+	{sizeof(magic_zlib),	KMOD_FILE_COMPRESSION_ZLIB, magic_zlib, load_zlib},
 #endif
-	{0,			KMOD_FILE_COMPRESSION_NONE, NULL, {NULL, NULL}}
+	{0,			KMOD_FILE_COMPRESSION_NONE, NULL, NULL}
 };
 
 static int load_reg(struct kmod_file *file)
@@ -400,15 +379,6 @@ static int load_reg(struct kmod_file *file)
 	return 0;
 }
 
-static void unload_reg(struct kmod_file *file)
-{
-	munmap(file->memory, file->size);
-}
-
-static const struct file_ops reg_ops = {
-	load_reg, unload_reg
-};
-
 struct kmod_elf *kmod_file_get_elf(struct kmod_file *file)
 {
 	if (file->elf)
@@ -436,7 +406,7 @@ struct kmod_file *kmod_file_open(const struct kmod_ctx *ctx,
 		goto error;
 	}
 
-	for (itr = comp_types; itr->ops.load != NULL; itr++) {
+	for (itr = comp_types; itr->load != NULL; itr++) {
 		if (magic_size_max < itr->magic_size)
 			magic_size_max = itr->magic_size;
 	}
@@ -459,17 +429,17 @@ struct kmod_file *kmod_file_open(const struct kmod_ctx *ctx,
 			goto error;
 		}
 
-		for (itr = comp_types; itr->ops.load != NULL; itr++) {
+		for (itr = comp_types; itr->load != NULL; itr++) {
 			if (memcmp(buf, itr->magic_bytes, itr->magic_size) == 0) {
-				file->ops = &itr->ops;
+				file->load = itr->load;
 				file->compression = itr->compression;
 				break;
 			}
 		}
 	}
 
-	if (file->ops == NULL) {
-		file->ops = &reg_ops;
+	if (file->load == NULL) {
+		file->load = load_reg;
 		file->compression = KMOD_FILE_COMPRESSION_NONE;
 	}
 
@@ -496,7 +466,7 @@ void kmod_file_load_contents(struct kmod_file *file)
 		return;
 
 	/*  The load functions already log possible errors. */
-	file->ops->load(file);
+	file->load(file);
 }
 
 void *kmod_file_get_contents(const struct kmod_file *file)
@@ -524,8 +494,12 @@ void kmod_file_unref(struct kmod_file *file)
 	if (file->elf)
 		kmod_elf_unref(file->elf);
 
-	if (file->memory)
-		file->ops->unload(file);
+	if (file->compression == KMOD_FILE_COMPRESSION_NONE) {
+		if (file->memory)
+			munmap(file->memory, file->size);
+	} else {
+		free(file->memory);
+	}
 
 	close(file->fd);
 	free(file);

-- 
2.43.0

