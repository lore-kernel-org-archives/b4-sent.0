From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:07 +0000
Subject: [PATCH kmod 06/13] libkmod: propagate {zstd,xz,zlib}_load errors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-6-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=2916;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=1wTsCflduLgjBjz0zHH+IVD4+idKLEWwqQ0UYa76W0U=;
 b=cnsIcWPK/UmkEpJ9lOwKD/Mksdbx2R0i5LjTEnrqQCYbLm+4LI6DHbRs1PYBCLJ6hOXc3uXxl
 LAxWc/sUpawDHEX1Nkab15N4PqMW0OHelpJt1w8VxDbuDXbv0DX8fxg
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Propagate any errors during decompression further up the call stack.
Without this we could easily pass NULL as mem to init_module(2).

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c     | 15 +++++++++++----
 libkmod/libkmod-internal.h |  2 +-
 libkmod/libkmod-module.c   |  4 +++-
 3 files changed, 15 insertions(+), 6 deletions(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index 8a0336f..3a79464 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -381,10 +381,17 @@ static int load_reg(struct kmod_file *file)
 
 struct kmod_elf *kmod_file_get_elf(struct kmod_file *file)
 {
+	int err;
+
 	if (file->elf)
 		return file->elf;
 
-	kmod_file_load_contents(file);
+	err = kmod_file_load_contents(file);
+	if (err) {
+		errno = err;
+		return NULL;
+	}
+
 	file->elf = kmod_elf_new(file->memory, file->size);
 	return file->elf;
 }
@@ -460,13 +467,13 @@ error:
 /*
  *  Callers should just check file->memory got updated
  */
-void kmod_file_load_contents(struct kmod_file *file)
+int kmod_file_load_contents(struct kmod_file *file)
 {
 	if (file->memory)
-		return;
+		return 0;
 
 	/*  The load functions already log possible errors. */
-	file->load(file);
+	return file->load(file);
 }
 
 void *kmod_file_get_contents(const struct kmod_file *file)
diff --git a/libkmod/libkmod-internal.h b/libkmod/libkmod-internal.h
index 26a7e28..3bc6e11 100644
--- a/libkmod/libkmod-internal.h
+++ b/libkmod/libkmod-internal.h
@@ -160,7 +160,7 @@ bool kmod_module_is_builtin(struct kmod_module *mod) __attribute__((nonnull(1)))
 /* libkmod-file.c */
 struct kmod_file *kmod_file_open(const struct kmod_ctx *ctx, const char *filename) _must_check_ __attribute__((nonnull(1,2)));
 struct kmod_elf *kmod_file_get_elf(struct kmod_file *file) __attribute__((nonnull(1)));
-void kmod_file_load_contents(struct kmod_file *file) __attribute__((nonnull(1)));
+int kmod_file_load_contents(struct kmod_file *file) __attribute__((nonnull(1)));
 void *kmod_file_get_contents(const struct kmod_file *file) _must_check_ __attribute__((nonnull(1)));
 off_t kmod_file_get_size(const struct kmod_file *file) _must_check_ __attribute__((nonnull(1)));
 enum kmod_file_compression_type kmod_file_get_compression(const struct kmod_file *file) _must_check_ __attribute__((nonnull(1)));
diff --git a/libkmod/libkmod-module.c b/libkmod/libkmod-module.c
index 585da41..1e43482 100644
--- a/libkmod/libkmod-module.c
+++ b/libkmod/libkmod-module.c
@@ -903,7 +903,9 @@ static int do_init_module(struct kmod_module *mod, unsigned int flags,
 	off_t size;
 	int err;
 
-	kmod_file_load_contents(mod->file);
+	err = kmod_file_load_contents(mod->file);
+	if (err)
+		return err;
 
 	if (flags & (KMOD_INSERT_FORCE_VERMAGIC | KMOD_INSERT_FORCE_MODVERSION)) {
 		elf = kmod_file_get_elf(mod->file);

-- 
2.43.0

