From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:05 +0000
Subject: [PATCH kmod 04/13] libkmod: clear file->memory if map fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-4-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1017;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=al1dK4HvZ5PCQ4yUkG1+INHPpcQTPWCE4hwkvTyh6Uo=;
 b=udM3cpyiH3c1vGygmQo+2yfr1L4mDfY1Mk21tp8R9fjbY+vbbiIiyIEcm4a9Qyb1F1arhZeVJ
 iJyCq1c1NUWDn02kEphWkyNyJMaR8ADvcEs+5rDieWgJtc6GnVrAwrZ
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On mmap failure file->memory is set to -1, which we'll happily pass down
to munmap later on.

More importantly, since we do a NULL check in kmod_file_load_contents()
we will exit the function without (re)attempting the load again.

Since we ignore the return code for the load function(s), one can end up
calling kmod_elf_get_memory() and feed that -1 into init_module.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-file.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/libkmod/libkmod-file.c b/libkmod/libkmod-file.c
index abd4723..b408aed 100644
--- a/libkmod/libkmod-file.c
+++ b/libkmod/libkmod-file.c
@@ -392,8 +392,10 @@ static int load_reg(struct kmod_file *file)
 	file->size = st.st_size;
 	file->memory = mmap(NULL, file->size, PROT_READ, MAP_PRIVATE,
 			    file->fd, 0);
-	if (file->memory == MAP_FAILED)
+	if (file->memory == MAP_FAILED) {
+		file->memory = NULL;
 		return -errno;
+	}
 
 	return 0;
 }

-- 
2.43.0

