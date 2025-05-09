From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:06 +0200
Subject: [PATCH 02/12] locking/rtmutex: Move max_lock_depth into rtmutex.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-2-d0ad83f5f4c3@kernel.org>
References: <20250509-jag-mv_ctltables_iter2-v1-0-d0ad83f5f4c3@kernel.org>
In-Reply-To: <20250509-jag-mv_ctltables_iter2-v1-0-d0ad83f5f4c3@kernel.org>
To: Luis Chamberlain <mcgrof@kernel.org>, Petr Pavlu <petr.pavlu@suse.com>, 
 Sami Tolvanen <samitolvanen@google.com>, 
 Daniel Gomez <da.gomez@samsung.com>, Kees Cook <kees@kernel.org>, 
 Peter Zijlstra <peterz@infradead.org>, Ingo Molnar <mingo@redhat.com>, 
 Will Deacon <will@kernel.org>, Boqun Feng <boqun.feng@gmail.com>, 
 Waiman Long <longman@redhat.com>, "Paul E. McKenney" <paulmck@kernel.org>, 
 Frederic Weisbecker <frederic@kernel.org>, 
 Neeraj Upadhyay <neeraj.upadhyay@kernel.org>, 
 Joel Fernandes <joel@joelfernandes.org>, 
 Josh Triplett <josh@joshtriplett.org>, Uladzislau Rezki <urezki@gmail.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Lai Jiangshan <jiangshanlai@gmail.com>, Zqiang <qiang.zhang1211@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 Helge Deller <deller@gmx.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-modules@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, rcu@vger.kernel.org, linux-mm@kvack.org, 
 linux-parisc@vger.kernel.org, linux-serial@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3350;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=m38oSF1bsk4q8XGkb05UXXsxgbOmuEMD50QR+Uz7CYc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGgd+yFGAm/Om5FxfE5IBLkbOWnP5gjnTcP/E
 wE2pCdoia9aUIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfshAAoJELqXzVK3
 lkFPej4L/3tUO7WMqQqglIlWRHXlqTWnxNRYnKJZsiWhYbMrGWU4eNprXYMvMDxp4JszWCrc+s/
 dHmZpjlZm84mz3wparfKY41aEWSr7T1OyrvxIHx+unxR9zyRa+ILYevo9846AmVIaP24Eh0rn/3
 5Cie9W07x5dm/HcvUcOwFgQ1dv9o41QFMKP2kyAnbmhmXtQeF3w54Sjg1Z0KB8PO4YvSJNUReGL
 WzaCrJEvSmK2XEzGGrjEeb3FlYKd0OfHShmxh3fnX7xb9CzwgsS+6NNqsuRLVIv0gTZShloGJr7
 8uDDxU2WngQ49c6Jb5IDh+QtPUfDul3yqLOkx0XpwzoEmrzVkgrPk6iZV960PvH51ShMRX15ca5
 ZHZ3neelFOecKdIjeq52ldmUvrYdxZYiv/YeW2hnSDdQQ78uPma7JuRm7RrJ/tGA96vqd00i43Y
 IE4RlTg9xRQXIFnwXFOWjnTph14ioLpEP8BCgrqaTOB8/JrM47yU5/1EECWiK/lMDwB3lSgRJH6
 JM=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the max_lock_depth sysctl table element and variable into
rtmutex.c. Make the variable static as it no longer needs to be
exported. Removed the rtmutex.h include from sysctl.c.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/rtmutex.h      |  2 --
 kernel/locking/rtmutex.c     | 23 +++++++++++++++++++++++
 kernel/locking/rtmutex_api.c |  5 -----
 kernel/sysctl.c              | 12 ------------
 4 files changed, 23 insertions(+), 19 deletions(-)

diff --git a/include/linux/rtmutex.h b/include/linux/rtmutex.h
index 7d049883a08ace049384d70b4c97e3f4fb0e46f8..dc9a51cda97cdb6ac8e12be5209071744101b703 100644
--- a/include/linux/rtmutex.h
+++ b/include/linux/rtmutex.h
@@ -18,8 +18,6 @@
 #include <linux/rbtree_types.h>
 #include <linux/spinlock_types_raw.h>
 
-extern int max_lock_depth; /* for sysctl */
-
 struct rt_mutex_base {
 	raw_spinlock_t		wait_lock;
 	struct rb_root_cached   waiters;
diff --git a/kernel/locking/rtmutex.c b/kernel/locking/rtmutex.c
index c80902eacd797c669dedcf10966a8cff38524b50..705a0e0fd72ab8da051e4227a5b89cb3d1539524 100644
--- a/kernel/locking/rtmutex.c
+++ b/kernel/locking/rtmutex.c
@@ -29,6 +29,29 @@
 #include "rtmutex_common.h"
 #include "lock_events.h"
 
+/*
+ * Max number of times we'll walk the boosting chain:
+ */
+static int max_lock_depth = 1024;
+
+static const struct ctl_table rtmutex_sysctl_table[] = {
+	{
+		.procname	= "max_lock_depth",
+		.data		= &max_lock_depth,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+};
+
+static int __init init_rtmutex_sysctl(void)
+{
+	register_sysctl_init("kernel", rtmutex_sysctl_table);
+	return 0;
+}
+
+subsys_initcall(init_rtmutex_sysctl);
+
 #ifndef WW_RT
 # define build_ww_mutex()	(false)
 # define ww_container_of(rtm)	NULL
diff --git a/kernel/locking/rtmutex_api.c b/kernel/locking/rtmutex_api.c
index 191e4720e546627aed0d7ec715673b1b8753b130..2b5da8af206da6ee72df1234a4db94f5c4f6f882 100644
--- a/kernel/locking/rtmutex_api.c
+++ b/kernel/locking/rtmutex_api.c
@@ -8,11 +8,6 @@
 #define RT_MUTEX_BUILD_MUTEX
 #include "rtmutex.c"
 
-/*
- * Max number of times we'll walk the boosting chain:
- */
-int max_lock_depth = 1024;
-
 /*
  * Debug aware fast / slowpath lock,trylock,unlock
  *
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 473133d9651eac4ef44b8b63a44b77189818ac08..a22f35013da0d838ef421fc5d192f00d1e70fb0f 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -59,9 +59,6 @@
 #include <asm/nmi.h>
 #include <asm/io.h>
 #endif
-#ifdef CONFIG_RT_MUTEXES
-#include <linux/rtmutex.h>
-#endif
 
 /* shared constants to be used in various sysctls */
 const int sysctl_vals[] = { 0, 1, 2, 3, 4, 100, 200, 1000, 3000, INT_MAX, 65535, -1 };
@@ -1709,15 +1706,6 @@ static const struct ctl_table kern_table[] = {
 		.proc_handler	= proc_dointvec,
 	},
 #endif
-#ifdef CONFIG_RT_MUTEXES
-	{
-		.procname	= "max_lock_depth",
-		.data		= &max_lock_depth,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-#endif
 #ifdef CONFIG_TREE_RCU
 	{
 		.procname	= "panic_on_rcu_stall",

-- 
2.47.2

