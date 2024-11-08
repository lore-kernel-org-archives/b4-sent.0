From: Daniel Gomez <da.gomez@samsung.com>
Date: Fri, 08 Nov 2024 17:12:15 +0100
Subject: [PATCH RFC v3 3/4] module: update state and release reference
 under lock
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241108-modules-ro_after_init-v3-3-6dd041b588a5@samsung.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1731082346; l=927;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=oDK90qbYeBOZipkuaq567b8TktP7UW9UN57bt99vHXY=;
 b=66ib05tLV5YIvQdiwB6EdW2FQlciFDI8VnOCbvAoLDNo9f0q92j48REvKz2O62bMMp4KTZsDa
 u3HaxoUHdV5A2+WA8zNVf55mbFYUAnUdmd1IWvh5DsVP0LMV8/9bPiK
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ensure the module state change and reference drop operations are
performed within module_mutex to prevent potential race conditions in
the failure path.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 kernel/module/main.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/kernel/module/main.c b/kernel/module/main.c
index 35a50ded64a6..2b45a6efa0a9 100644
--- a/kernel/module/main.c
+++ b/kernel/module/main.c
@@ -2994,10 +2994,12 @@ static noinline int do_init_module(struct module *mod)
 fail_free_freeinit:
 	kfree(freeinit);
 fail:
+	mutex_lock(&module_mutex);
 	/* Try to protect us from buggy refcounters. */
 	mod->state = MODULE_STATE_GOING;
-	synchronize_rcu();
 	module_put(mod);
+	mutex_unlock(&module_mutex);
+	synchronize_rcu();
 	blocking_notifier_call_chain(&module_notify_list,
 				     MODULE_STATE_GOING, mod);
 	klp_module_going(mod);

-- 
2.39.2

