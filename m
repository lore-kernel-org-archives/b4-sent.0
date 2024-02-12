From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:08 +0000
Subject: [PATCH kmod 07/13] libkmod: move kmod_file_load_contents as
 applicable
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-7-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1207;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=P4udCeYuUMpIW9quBl7lfm1aEgAkNyDIYoV/mJWVVoQ=;
 b=XUvBbmBX6Y/ENcaTa6JI/AV0aVBXrs82P2iIirqcUF16Q16DVaep0Re0Pim1fUzwgHxOfQ13h
 dAf8Fk4IExsD8UDr6zHqJeZkOx4q5GMWc92FaveloIW6hZwzv6pKROH
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When dealing with an elf, we don't know or care about loading the file.
The kmod_elf subsystem/API will deal with the required parts itself.

Which in this case, already calls kmod_file_load_contents() as
applicable.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-module.c | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/libkmod/libkmod-module.c b/libkmod/libkmod-module.c
index 1e43482..d309948 100644
--- a/libkmod/libkmod-module.c
+++ b/libkmod/libkmod-module.c
@@ -903,10 +903,6 @@ static int do_init_module(struct kmod_module *mod, unsigned int flags,
 	off_t size;
 	int err;
 
-	err = kmod_file_load_contents(mod->file);
-	if (err)
-		return err;
-
 	if (flags & (KMOD_INSERT_FORCE_VERMAGIC | KMOD_INSERT_FORCE_MODVERSION)) {
 		elf = kmod_file_get_elf(mod->file);
 		if (elf == NULL) {
@@ -928,6 +924,10 @@ static int do_init_module(struct kmod_module *mod, unsigned int flags,
 
 		mem = kmod_elf_get_memory(elf);
 	} else {
+		err = kmod_file_load_contents(mod->file);
+		if (err)
+			return err;
+
 		mem = kmod_file_get_contents(mod->file);
 	}
 	size = kmod_file_get_size(mod->file);

-- 
2.43.0

