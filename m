From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:10 +0000
Subject: [PATCH kmod 09/13] libkmod: swap alloca usage for a few assert_cc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-9-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1663;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=XPT/ZixMYN/E3QF0xKFi5IKVYm1O2Fs0Z8DdyQGwNPg=;
 b=jsdW4IsoknHmKJGjSqwIeZ974sfzKlQNxyU7QbZXEyfleS0NmbphAOBRNIdyI3Ei+fDPUlAqC
 5aq88pNxiVgBZdSpX/5gupR9OzyIV2Y3Bv5ZvegpecqO7ZKMR8UPC4g
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since all the compression magic is always available now, we don't need
to loop at runtime nor use alloca - latter of which comes with a handful
of caveats.

Simply throw in a few assert_cc(), which will trigger at build-time.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 22 ++++++++--------------
 1 file changed, 8 insertions(+), 14 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index b69f1ef..5b88d6c 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -410,7 +410,6 @@ struct kmod_file *kmod_file_open(const struct kmod_ctx *ctx,
 {
 	struct kmod_file *file = calloc(1, sizeof(struct kmod_file));
 	const struct comp_type *itr;
-	size_t magic_size_max = 0;
 	int err = 0;
 
 	if (file == NULL)
@@ -422,22 +421,17 @@ struct kmod_file *kmod_file_open(const struct kmod_ctx *ctx,
 		goto error;
 	}
 
-	for (itr = comp_types; itr->load != NULL; itr++) {
-		if (magic_size_max < itr->magic_size)
-			magic_size_max = itr->magic_size;
-	}
-
-	if (magic_size_max > 0) {
-		char *buf = alloca(magic_size_max + 1);
+	{
+		char buf[7];
 		ssize_t sz;
 
-		if (buf == NULL) {
-			err = -errno;
-			goto error;
-		}
-		sz = read_str_safe(file->fd, buf, magic_size_max + 1);
+		assert_cc(sizeof(magic_zstd) < sizeof(buf));
+		assert_cc(sizeof(magic_xz) < sizeof(buf));
+		assert_cc(sizeof(magic_zlib) < sizeof(buf));
+
+		sz = read_str_safe(file->fd, buf, sizeof(buf));
 		lseek(file->fd, 0, SEEK_SET);
-		if (sz != (ssize_t)magic_size_max) {
+		if (sz != (sizeof(buf) - 1)) {
 			if (sz < 0)
 				err = sz;
 			else

-- 
2.43.0

