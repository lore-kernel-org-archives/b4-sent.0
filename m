From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:13 +0000
Subject: [PATCH kmod 12/13] libkmod: keep
 KMOD_FILE_COMPRESSION_NONE/load_reg in comp_types
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-12-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1865;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=eg4QwfmoJWQ60x2hJ543Y3vC1Tb/8riHCGxkXzk+eG8=;
 b=uzOuE6T9A8QFRCFEYa+9kvPc9yobUxetur2RoHCrRNC8K9OaeJaju0woiZkOM7hW5w8BUg4kd
 1IHLkUj3hvGC81pZAKt20+9VMguL3Whp4D1NhFRbuOdi8XGxbVTVz7S
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It's cleaner to handle all compression types and load functions in the
same style.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 19 ++++++++-----------
 1 file changed, 8 insertions(+), 11 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index db775a6..f162a10 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -385,7 +385,7 @@ static const struct comp_type {
 	{sizeof(magic_zstd),	KMOD_FILE_COMPRESSION_ZSTD, magic_zstd, load_zstd},
 	{sizeof(magic_xz),	KMOD_FILE_COMPRESSION_XZ, magic_xz, load_xz},
 	{sizeof(magic_zlib),	KMOD_FILE_COMPRESSION_ZLIB, magic_zlib, load_zlib},
-	{0,			KMOD_FILE_COMPRESSION_NONE, NULL, NULL}
+	{0,			KMOD_FILE_COMPRESSION_NONE, NULL, load_reg}
 };
 
 struct kmod_elf *kmod_file_get_elf(struct kmod_file *file)
@@ -409,7 +409,6 @@ struct kmod_file *kmod_file_open(const struct kmod_ctx *ctx,
 						const char *filename)
 {
 	struct kmod_file *file = calloc(1, sizeof(struct kmod_file));
-	const struct comp_type *itr;
 	char buf[7];
 	ssize_t sz;
 
@@ -439,19 +438,17 @@ struct kmod_file *kmod_file_open(const struct kmod_ctx *ctx,
 		return NULL;
 	}
 
-	for (itr = comp_types; itr->load != NULL; itr++) {
-		if (memcmp(buf, itr->magic_bytes, itr->magic_size) == 0) {
-			file->load = itr->load;
-			file->compression = itr->compression;
+	for (unsigned int i = 0; i < ARRAY_SIZE(comp_types); i++) {
+		const struct comp_type *itr = &comp_types[i];
+
+		file->load = itr->load;
+		file->compression = itr->compression;
+		if (itr->magic_size &&
+		    memcmp(buf, itr->magic_bytes, itr->magic_size) == 0) {
 			break;
 		}
 	}
 
-	if (file->load == NULL) {
-		file->load = load_reg;
-		file->compression = KMOD_FILE_COMPRESSION_NONE;
-	}
-
 	file->ctx = ctx;
 
 	return file;

-- 
2.43.0

