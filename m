From: Emil Velikov <emil.l.velikov@gmail.com>
Date: Mon, 12 Feb 2024 17:23:14 +0000
Subject: [PATCH kmod 13/13] libkmod: always fallback to do_init_module()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240212-decompression-fixes-v1-13-06f92ad07985@gmail.com>
References: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
In-Reply-To: <20240212-decompression-fixes-v1-0-06f92ad07985@gmail.com>
To: linux-modules@vger.kernel.org
Cc: Emil Velikov <emil.l.velikov@gmail.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707758583; l=1269;
 i=emil.l.velikov@gmail.com; s=20230301; h=from:subject:message-id;
 bh=YLQVRnZVvgDMYMKMKqUNfuI2u4VvagtQrxxbP0HW96w=;
 b=dH9WZxNZmaYSoFEZa/rC5AiBsh5aZi9t5itP654DCBcT+JFdIyGDIzRU6uyQQXm70fARrWTdP
 TWZDCB/oeUFBmTOmWcqP6UJ66tRJgDEAhcXhLZ+SNtKM1HwYwcUfWkM
X-Developer-Key: i=emil.l.velikov@gmail.com; a=ed25519;
 pk=qeUTVTNyI3rcR2CfNNWsloTihgzmtbZo98GdxwZKCkY=
X-Endpoint-Received: by B4 Relay for emil.l.velikov@gmail.com/20230301 with auth_id=35
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since the direct loading was introduced a few bugs became obvious that
the compression args used were off - both in-kernel and dkms.

While both of those are fixed already, not all of those have reached all
users. For example: for dkms I'm aiming to do a release just as kmod has
theirs (to align /lib/modules <> /usr/lib/modules support).

Although I am wondering if we can indiscriminatingly callback to the old
do_init_module() in all the cases. This means that we'll catch any
in-kernel decompression issues - invalid args, ENOMEM, other....
Although for others (wrong magic, perm, etc) we will end up doing the
exact kernel work twice.

Overall the trade-off seems worth it, so flip this.

Signed-off-by: Emil Velikov <emil.l.velikov@gmail.com>
---
 libkmod/libkmod-module.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/libkmod/libkmod-module.c b/libkmod/libkmod-module.c
index d309948..2c0d46d 100644
--- a/libkmod/libkmod-module.c
+++ b/libkmod/libkmod-module.c
@@ -980,7 +980,7 @@ KMOD_EXPORT int kmod_module_insert_module(struct kmod_module *mod,
 	}
 
 	err = do_finit_module(mod, flags, args);
-	if (err == -ENOSYS)
+	if (err)
 		err = do_init_module(mod, flags, args);
 
 	if (err < 0)

-- 
2.43.0

