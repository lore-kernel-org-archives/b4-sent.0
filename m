From: Daniel Gomez <da.gomez@samsung.com>
Date: Fri, 08 Nov 2024 17:12:13 +0100
Subject: [PATCH RFC v3 1/4] module: remove module_deallocate() unused param
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241108-modules-ro_after_init-v3-1-6dd041b588a5@samsung.com>
References: <20241108-modules-ro_after_init-v3-0-6dd041b588a5@samsung.com>
In-Reply-To: <20241108-modules-ro_after_init-v3-0-6dd041b588a5@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Sami Tolvanen <samitolvanen@google.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Thomas Gleixner <tglx@linutronix.de>, Jinjie Ruan <ruanjinjie@huawei.com>, 
 Jens Axboe <axboe@kernel.dk>
Cc: "Daniel Gomez (Samsung)" <d+samsung@kruces.com>, 
 linux-modules@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731082346; l=1219;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=A6gqpizSENgaBLBO0Z0bdDnIpaPO10y9Bcdf+FyWroA=;
 b=O7Dbg4205CdfeJlhE+bW3nIQfANZpxsZmBln1qQ0yCbBltIyVE72FQIb3iTKVLmaOI5GiLv7+
 LS+p0Qm1bY/BylXOXe0q0fXAS4yRgFxaHr7jyllw5j3BFa0KEBBIMha
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The module_deallocate() function no longer requires the struct load_info
parameter as of commit 48fd11880b5ef04270be8a87d9a9a9ee2fdae338 ("module:
Fix performance regression on modules with large symbol tables"). This
commit removes the now-unused parameter.

No functional changes.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 kernel/module/main.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/kernel/module/main.c b/kernel/module/main.c
index 5399c182b3cb..e0b2a8d9e324 100644
--- a/kernel/module/main.c
+++ b/kernel/module/main.c
@@ -2767,7 +2767,7 @@ static struct module *layout_and_allocate(struct load_info *info, int flags)
 }
 
 /* mod is no longer valid after this! */
-static void module_deallocate(struct module *mod, struct load_info *info)
+static void module_deallocate(struct module *mod)
 {
 	percpu_modfree(mod);
 	module_arch_freeing_init(mod);
@@ -3417,7 +3417,7 @@ static int load_module(struct load_info *info, const char __user *uargs,
 				       mod->mem[type].size);
 	}
 
-	module_deallocate(mod, info);
+	module_deallocate(mod);
  free_copy:
 	/*
 	 * The info->len is always set. We distinguish between

-- 
2.39.2

