From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:12 +0000
Subject: [PATCH kmod 11/13] libkmod: move load_reg() further up
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-11-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1695;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=s7DGIk3v5vJZUPUJq4qUIG5k2dwH6qeNbl7Ccp04tdM=;
 b=r+xUgnwpNFv2pLM9zfu/g+v/Ncb451QKQmLwLfooiRmjkaiKwgrO8YpIpoo1nNwAZGpC8KHlN
 3Ax90X3qGebDHBMoyGar0BjA3ntxKXFtVlwhzoSzZWsQQJKuY4R32ze
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We're about to reference it in comp_types with next commit.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 24 ++++++++++++------------
 1 file changed, 12 insertions(+), 12 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index c4893fd..db775a6 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -358,18 +358,6 @@ static int load_zlib(struct kmod_file *file)
 
 static const char magic_zlib[] = {0x1f, 0x8b};
 
-static const struct comp_type {
-	size_t magic_size;
-	enum kmod_file_compression_type compression;
-	const char *magic_bytes;
-	int (*load)(struct kmod_file *file);
-} comp_types[] = {
-	{sizeof(magic_zstd),	KMOD_FILE_COMPRESSION_ZSTD, magic_zstd, load_zstd},
-	{sizeof(magic_xz),	KMOD_FILE_COMPRESSION_XZ, magic_xz, load_xz},
-	{sizeof(magic_zlib),	KMOD_FILE_COMPRESSION_ZLIB, magic_zlib, load_zlib},
-	{0,			KMOD_FILE_COMPRESSION_NONE, NULL, NULL}
-};
-
 static int load_reg(struct kmod_file *file)
 {
 	struct stat st;
@@ -388,6 +376,18 @@ static int load_reg(struct kmod_file *file)
 	return 0;
 }
 
+static const struct comp_type {
+	size_t magic_size;
+	enum kmod_file_compression_type compression;
+	const char *magic_bytes;
+	int (*load)(struct kmod_file *file);
+} comp_types[] = {
+	{sizeof(magic_zstd),	KMOD_FILE_COMPRESSION_ZSTD, magic_zstd, load_zstd},
+	{sizeof(magic_xz),	KMOD_FILE_COMPRESSION_XZ, magic_xz, load_xz},
+	{sizeof(magic_zlib),	KMOD_FILE_COMPRESSION_ZLIB, magic_zlib, load_zlib},
+	{0,			KMOD_FILE_COMPRESSION_NONE, NULL, NULL}
+};
+
 struct kmod_elf *kmod_file_get_elf(struct kmod_file *file)
 {
 	int err;

-- 
2.43.0

