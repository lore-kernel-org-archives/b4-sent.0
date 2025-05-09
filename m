From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:07 +0200
Subject: [PATCH 03/12] rcu: Move rcu_stall related sysctls into
 rcu/tree_stall.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-3-d0ad83f5f4c3@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3493;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=GOjBhs9Ib0MUGQiJvmUAWG/9445JnpsIsFkQfqoyx1M=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGgd+yIcQI+tvF5Nf2VvFXZdiynCbCQ6sUxEe
 0XfrKJsz2Y0mokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfsiAAoJELqXzVK3
 lkFP8AML/RLD37zpvtcqTs+AdQPaL/oilhjcYTEBWeV8O06muca2S+v/BCsYCHrWuQ6fuJwa6/L
 kNbBLnGE+/FLg4WqWCSxa9qYc1k6W31LyVk59M9YYpqwr65nWtTVxh+/rW3vNW4mIkmUmVMI85r
 JlmwBQps6LBgQvg9L2r1wpbIDmLQIBSaAu4Y4eLl4hIm7PFgSEY1LTbb3augTLNmTa0Tf6ZdfxO
 ViMZAvqBzzfRBdv9SwhA88E33eptU37Nx8MnxQNMm5NXfA2iJGb/NsQLx5DPDVQtjKl3WO+Jygx
 p64kuZlSl/FL0HLbSl4x1jvWNjeU5tZLuQMc3qgTZSVVYN9M8o3OtF9Vlm/rO38Gw+WwnSUQGrC
 mf0gFT1fa+Ba/CF5rJR9SBN3yRcg0+q6xbHDu0igMPFC1UZDN2bAu4XfPlagJH2dZKiiCl8z4np
 oWou1P5hkekOj6omNQ3SYmiTLPHkF9KQFZwP6rJU9a64iDjk2AU0ibgezMgzA9eystZgCvVX+C4
 HE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move sysctl_panic_on_rcu_stall and sysctl_max_rcu_stall_to_panic into
the kernel/rcu subdirectory. Make these static in tree_stall.h and
removed them as extern from panic.h as their scope is now confined into
one file.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/panic.h   |  2 --
 kernel/rcu/tree_stall.h | 33 +++++++++++++++++++++++++++++++--
 kernel/sysctl.c         | 20 --------------------
 3 files changed, 31 insertions(+), 24 deletions(-)

diff --git a/include/linux/panic.h b/include/linux/panic.h
index 2494d51707ef422dfe191e484c0676e428a2de09..33ecead16b7c1af46aac07fb10b88beed5074b18 100644
--- a/include/linux/panic.h
+++ b/include/linux/panic.h
@@ -27,8 +27,6 @@ extern int panic_on_warn;
 extern unsigned long panic_on_taint;
 extern bool panic_on_taint_nousertaint;
 
-extern int sysctl_panic_on_rcu_stall;
-extern int sysctl_max_rcu_stall_to_panic;
 extern int sysctl_panic_on_stackoverflow;
 
 extern bool crash_kexec_post_notifiers;
diff --git a/kernel/rcu/tree_stall.h b/kernel/rcu/tree_stall.h
index 925fcdad5dea22cfc8b0648546b78870cee485a6..5a0009b7e30b5a057856a3544f841712625699ce 100644
--- a/kernel/rcu/tree_stall.h
+++ b/kernel/rcu/tree_stall.h
@@ -17,8 +17,37 @@
 // Controlling CPU stall warnings, including delay calculation.
 
 /* panic() on RCU Stall sysctl. */
-int sysctl_panic_on_rcu_stall __read_mostly;
-int sysctl_max_rcu_stall_to_panic __read_mostly;
+static int sysctl_panic_on_rcu_stall __read_mostly;
+static int sysctl_max_rcu_stall_to_panic __read_mostly;
+
+static const struct ctl_table rcu_stall_sysctl_table[] = {
+	{
+		.procname	= "panic_on_rcu_stall",
+		.data		= &sysctl_panic_on_rcu_stall,
+		.maxlen		= sizeof(sysctl_panic_on_rcu_stall),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec_minmax,
+		.extra1		= SYSCTL_ZERO,
+		.extra2		= SYSCTL_ONE,
+	},
+	{
+		.procname	= "max_rcu_stall_to_panic",
+		.data		= &sysctl_max_rcu_stall_to_panic,
+		.maxlen		= sizeof(sysctl_max_rcu_stall_to_panic),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec_minmax,
+		.extra1		= SYSCTL_ONE,
+		.extra2		= SYSCTL_INT_MAX,
+	},
+};
+
+static int __init init_rcu_stall_sysctl(void)
+{
+	register_sysctl_init("kernel", rcu_stall_sysctl_table);
+	return 0;
+}
+
+subsys_initcall(init_rcu_stall_sysctl);
 
 #ifdef CONFIG_PROVE_RCU
 #define RCU_STALL_DELAY_DELTA		(5 * HZ)
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index a22f35013da0d838ef421fc5d192f00d1e70fb0f..fd76f0e1d490940a67d72403d72d204ff13d888a 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1706,26 +1706,6 @@ static const struct ctl_table kern_table[] = {
 		.proc_handler	= proc_dointvec,
 	},
 #endif
-#ifdef CONFIG_TREE_RCU
-	{
-		.procname	= "panic_on_rcu_stall",
-		.data		= &sysctl_panic_on_rcu_stall,
-		.maxlen		= sizeof(sysctl_panic_on_rcu_stall),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec_minmax,
-		.extra1		= SYSCTL_ZERO,
-		.extra2		= SYSCTL_ONE,
-	},
-	{
-		.procname	= "max_rcu_stall_to_panic",
-		.data		= &sysctl_max_rcu_stall_to_panic,
-		.maxlen		= sizeof(sysctl_max_rcu_stall_to_panic),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec_minmax,
-		.extra1		= SYSCTL_ONE,
-		.extra2		= SYSCTL_INT_MAX,
-	},
-#endif
 };
 
 int __init sysctl_init_bases(void)

-- 
2.47.2

