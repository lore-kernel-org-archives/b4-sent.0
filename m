From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:09 +0200
Subject: [PATCH 05/12] parisc/power: Move soft-power into power.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-5-d0ad83f5f4c3@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2508;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=rapDihnXNpERecGhvKjpm1dlmjRPjcehXnhZxS8O2Xw=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGgd+yOtnQB/bJFt/7J5h4oiYG8sIaqpsH1ED
 v9nLDttnyWwn4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfsjAAoJELqXzVK3
 lkFPFaAL/Ar0qxWKRezFimngFzcnCsml3mGCyVaueqDYkhIcXd9TAx4Vy2cbd8a6EyROmFFeF0r
 rVCXwDYsGMaqo2dGI1CisaSk43tUbGRUrAjy1d0hnUNKg2akUhqGpv0z5/KHp0bNdVtIEykxQwp
 RR4bF+33DGLOfOKwBq3XsCheE9gvVSvQStge4+MR/jNHTMy0ZW7CGAhCucj9EH8bpVa3GzHdYNV
 uS/c89PQ5kSKvJBi3Y252xpjBbYCDbEkn0tojDZJ7Ep0hIsQT9Mlph3bYXGt0hhgH9byKOQo/1j
 8ooJpt5ydx76RfZ17U3pO1p/4eFA6wHWm6zYrMt6VbprDCuSg7BxIUfq7cWUA36mc06me/305ZO
 X73egkYLEiSbevWt4UoUxMOv/VavPwPfdrOBmByYPaB90vqcFqCUZUiY7O4kN0gV4yRARoL00K4
 NT03pMxoTZZpPF7Fh6dp0xpLzvZ2r5JvfKtIJnOR1h8SEFSXHPnid/uoqmvqLCUI42yfnmgd/76
 jc=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the soft-power ctl table into parisc/power.c. As a consequence the
pwrsw_enabled var is made static.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 drivers/parisc/power.c | 20 +++++++++++++++++++-
 include/linux/sysctl.h |  1 -
 kernel/sysctl.c        |  9 ---------
 3 files changed, 19 insertions(+), 11 deletions(-)

diff --git a/drivers/parisc/power.c b/drivers/parisc/power.c
index 7a6a3e7f2825be5191e024e6c7af1cd688219b75..9d6c7bf72e2958348e263a7e82025038694ebfbc 100644
--- a/drivers/parisc/power.c
+++ b/drivers/parisc/power.c
@@ -83,7 +83,25 @@ static struct task_struct *power_task;
 #define SYSCTL_FILENAME	"sys/kernel/power"
 
 /* soft power switch enabled/disabled */
-int pwrsw_enabled __read_mostly = 1;
+static int pwrsw_enabled __read_mostly = 1;
+
+static const struct ctl_table power_sysctl_table[] = {
+	{
+		.procname	= "soft-power",
+		.data		= &pwrsw_enabled,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+};
+
+static int __init init_power_sysctl(void)
+{
+	register_sysctl_init("kernel", power_sysctl_table);
+	return 0;
+}
+
+arch_initcall(init_power_sysctl);
 
 /* main kernel thread worker. It polls the button state */
 static int kpowerswd(void *param)
diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 40a6ac6c9713f3504c4dfcb4fcc77dff7dce8ca6..ae762eabb7c9715e973356cadafbaaea3f20c7e9 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -242,7 +242,6 @@ int do_proc_douintvec(const struct ctl_table *table, int write,
 				  int write, void *data),
 		      void *data);
 
-extern int pwrsw_enabled;
 extern int unaligned_enabled;
 extern int unaligned_dump_stack;
 extern int no_unaligned_warning;
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index adc2d3ea127841d87b7073ed81d6121c9a60e59a..718140251972b797f5aa5a056de40e8856805eed 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1594,15 +1594,6 @@ static const struct ctl_table kern_table[] = {
 		.extra2		= SYSCTL_ONE,
 	},
 #endif
-#ifdef CONFIG_PARISC
-	{
-		.procname	= "soft-power",
-		.data		= &pwrsw_enabled,
-		.maxlen		= sizeof (int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-#endif
 #ifdef CONFIG_SYSCTL_ARCH_UNALIGN_ALLOW
 	{
 		.procname	= "unaligned-trap",

-- 
2.47.2

