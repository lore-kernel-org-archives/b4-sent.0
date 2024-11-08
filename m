From: Daniel Gomez <da.gomez@samsung.com>
Date: Fri, 08 Nov 2024 17:12:14 +0100
Subject: [PATCH RFC v3 2/4] module: avoid double ref drop on ro_after_init
 failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241108-modules-ro_after_init-v3-2-6dd041b588a5@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731082346; l=1137;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=9DltLcORsUZtMTYEZ5ybIyns3a3KM2mPjN1YlLgDFI0=;
 b=QZs431yGGNbH/0/7tBF4itYMit6iYIAJECiADp0Xq/FSZbSS3fyf+8N8yLOlqCVaakbY8YlG3
 nr9/IXGgCWmCuTJXB82rd7r27cxS+jDRSl+P4zu79plf5pt/OAoUKsO
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ensure the module reference is only dropped once in case we fail at
MOD_RO_AFTER_INIT case.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 kernel/module/main.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/kernel/module/main.c b/kernel/module/main.c
index e0b2a8d9e324..35a50ded64a6 100644
--- a/kernel/module/main.c
+++ b/kernel/module/main.c
@@ -2941,8 +2941,6 @@ static noinline int do_init_module(struct module *mod)
 	ftrace_free_mem(mod, mod->mem[MOD_INIT_TEXT].base,
 			mod->mem[MOD_INIT_TEXT].base + mod->mem[MOD_INIT_TEXT].size);
 	mutex_lock(&module_mutex);
-	/* Drop initial reference. */
-	module_put(mod);
 	trim_init_extable(mod);
 #ifdef CONFIG_KALLSYMS
 	/* Switch to core kallsyms now init is done: kallsyms may be walking! */
@@ -2951,6 +2949,8 @@ static noinline int do_init_module(struct module *mod)
 	ret = module_enable_rodata_ro(mod, true);
 	if (ret)
 		goto fail_mutex_unlock;
+	/* Drop initial reference. */
+	module_put(mod);
 	mod_tree_remove_init(mod);
 	module_arch_freeing_init(mod);
 	for_class_mod_mem_type(type, init) {

-- 
2.39.2

