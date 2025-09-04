From: Simon Schuster <schuster.simon@siemens-energy.com>
Date: Thu, 04 Sep 2025 13:36:52 +0200
Subject: [PATCH] rv/ltl_monitor: adapt handle_task_newtask to u64
 clone_flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250904-trace-task-newtask-fix-callbacks-v1-1-8edb3d557365@siemens-energy.com>
X-B4-Tracking: v=1; b=H4sIANN5uWgC/x2NQQqDQAxFryJZGxitU7RXERcxRhuUsUwGWxDv3
 sHV48Hj/xNMoorBqzghyqGme8hSlQXwm8IiqFN2qF3tXecaTJFYMJGtGOR7c9YfMm3bSLwajpV
 vn4+GfTcR5JlPlBzcF/1wXX/dCTs2cgAAAA==
X-Change-ID: 20250904-trace-task-newtask-fix-callbacks-b158634c59da
To: Steven Rostedt <rostedt@goodmis.org>, 
 Christian Brauner <brauner@kernel.org>, 
 Stephen Rothwell <sfr@canb.auug.org.au>
Cc: David Hildenbrand <david@redhat.com>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, Arnd Bergmann <arnd@arndb.de>, 
 linux-trace-kernel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 kernel test robot <lkp@intel.com>, 
 Simon Schuster <schuster.simon@siemens-energy.com>
X-Mailer: b4 0.14.3-dev-2ce6c
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756985832; l=2094;
 i=schuster.simon@siemens-energy.com; s=20250818; h=from:subject:message-id;
 bh=csJ5txv6tqXJkqrIKhkf4TfiADTvCuVUIksSMgyFOQc=;
 b=38kU7qTU3ePme9DQA8Us2hLlr+NTH5vWQV+CBallDDv1+gLQMyaXqtUPGu2nQ1fcpi28/61XV
 ZZRnu69MyC5CqWYDz/cxbvX75QNMrlichdqEVJIep+QIIh6PWPsSZvz
X-Developer-Key: i=schuster.simon@siemens-energy.com; a=ed25519;
 pk=PUhOMiSp43aSeRE1H41KApxYOluamBFFiMfKlBjocvo=
X-Endpoint-Received: by B4 Relay for schuster.simon@siemens-energy.com/20250818 with auth_id=495
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Since commit edd3cb05c00a ("copy_process: pass clone_flags as u64 across
calltree") the task_newtask trace event exposes clone_flags as u64 to
its callbacks.

However, ltl_monitor was not adapted, resulting in a faulty callback.
This also resulted in an lkp build warning due to
-Wincompatible-pointer-types.

Fixes: edd3cb05c00a ("copy_process: pass clone_flags as u64 across calltree")
Reported-by: Stephen Rothwell <sfr@canb.auug.org.au>
Closes: https://lore.kernel.org/lkml/20250904113334.18822d43@canb.auug.org.au/
Reported-by: kernel test robot <lkp@intel.com>
Closes: https://lore.kernel.org/oe-kbuild-all/202509040134.bQVbm7ja-lkp@intel.com/
Signed-off-by: Simon Schuster <schuster.simon@siemens-energy.com>
---
I did further search for other in-tree users of the task_newtask
callback, but the trace macros make it a bit harder. Yet, as far as I
could see, there are none, so this patch hopefully resolves the problem
for good. The other matches all relate to "tp_btf/task_newtask", which
seems to be unaffected.

With this patch, ARCH=S390 allmodconfig -- that originally tripped the
LKP builds -- now builds without further -Wincompatible-pointer-types
warnings.

Sorry for causing this trouble, and thanks to Stephen Rothwell for
testing/reporting.
---
 include/rv/ltl_monitor.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/rv/ltl_monitor.h b/include/rv/ltl_monitor.h
index 67031a774e3d..5368cf5fd623 100644
--- a/include/rv/ltl_monitor.h
+++ b/include/rv/ltl_monitor.h
@@ -56,7 +56,7 @@ static void ltl_task_init(struct task_struct *task, bool task_creation)
 	ltl_atoms_fetch(task, mon);
 }
 
-static void handle_task_newtask(void *data, struct task_struct *task, unsigned long flags)
+static void handle_task_newtask(void *data, struct task_struct *task, u64 flags)
 {
 	ltl_task_init(task, true);
 }

---
base-commit: edd3cb05c00a040dc72bed20b14b5ba865188bce
change-id: 20250904-trace-task-newtask-fix-callbacks-b158634c59da

Best regards,
-- 
Simon Schuster <schuster.simon@siemens-energy.com>

