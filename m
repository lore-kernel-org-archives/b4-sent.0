From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:10 +0200
Subject: [PATCH 06/12] fork: mv threads-max into kernel/fork.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-6-d0ad83f5f4c3@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2440;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=g7LsXDd+j505V+MKQpG5RDYoahnYOKgJjZC/QSb5FNw=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGgd+yQ/uWK/HG1C61w82jo0nQJAkZrwNaRTQ
 Kzdwz6TUJcOyIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfskAAoJELqXzVK3
 lkFP5gcMAIFO2d6rVgT6EKcTmTnIIh5UBVX/xKxmcuUTXSbrkCQUFpfo23HIWCeg8lL9+/SmVc/
 wMQuryABzQbKLqJgYFC1QWq55hJcvP+tU2PTyZkeJC/OVtzsTZQ/ekzJOYDMD5OXR7RA7MNpiHw
 DWGtslYalBKnX4v/OZwXHpjwxW7ypE8DnYYz6VIp/aCFYqJydkFGyJZfbvlzKl+mHZoVO2Mrs4i
 SmNFu7CS2gpbq2cBPi1pnre4gHOjRveT+FIx/NZOc1ttqqym6PVJsSQpnUGcTJwXZbwHWsFGhbj
 4u9+eNLUJC4qoDTTYLnroNX83r/N6o5QnbPCBWjuV3fKNVL21qaJnCrONdHewkNLIcIBCc/7Ojb
 k12NIcmQoGPLGzmePG67PgJZq04KQsxm0xdPTiQAyBfhB5up3+XiLPdyLFmALcDrr286yquKuuc
 Rbpu1HJEE6D/X+MWIPZsfT0K9KaTNq1tWG/NTJIcpSunVpPbn0ioZqiTeHwnwZDJdA4QNjcWEC7
 d8=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

make sysctl_max_threads static as it no longer needs to be exported into
sysctl.c.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/sysctl.h |  3 ---
 kernel/fork.c          | 20 +++++++++++++++++++-
 kernel/sysctl.c        |  7 -------
 3 files changed, 19 insertions(+), 11 deletions(-)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index ae762eabb7c9715e973356cadafbaaea3f20c7e9..30bcbc59d12d2f4cec7545e7ee3f5ea5f0eefbd7 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -284,7 +284,4 @@ static inline bool sysctl_is_alias(char *param)
 }
 #endif /* CONFIG_SYSCTL */
 
-int sysctl_max_threads(const struct ctl_table *table, int write, void *buffer,
-		size_t *lenp, loff_t *ppos);
-
 #endif /* _LINUX_SYSCTL_H */
diff --git a/kernel/fork.c b/kernel/fork.c
index c4b26cd8998b8e7b2b516e0bb0b1d4676ff644dc..ed39064b86c25849c4b21cf99ac68dded05038b3 100644
--- a/kernel/fork.c
+++ b/kernel/fork.c
@@ -3470,7 +3470,7 @@ int unshare_files(void)
 	return 0;
 }
 
-int sysctl_max_threads(const struct ctl_table *table, int write,
+static int sysctl_max_threads(const struct ctl_table *table, int write,
 		       void *buffer, size_t *lenp, loff_t *ppos)
 {
 	struct ctl_table t;
@@ -3492,3 +3492,21 @@ int sysctl_max_threads(const struct ctl_table *table, int write,
 
 	return 0;
 }
+
+static const struct ctl_table fork_sysctl_table[] = {
+	{
+		.procname	= "threads-max",
+		.data		= NULL,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= sysctl_max_threads,
+	},
+};
+
+static int __init init_fork_sysctl(void)
+{
+	register_sysctl_init("kernel", fork_sysctl_table);
+	return 0;
+}
+
+subsys_initcall(init_fork_sysctl);
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 718140251972b797f5aa5a056de40e8856805eed..febf328054aa5a7b2462a256598f86f5ded87c90 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1630,13 +1630,6 @@ static const struct ctl_table kern_table[] = {
 		.proc_handler	= proc_do_cad_pid,
 	},
 #endif
-	{
-		.procname	= "threads-max",
-		.data		= NULL,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= sysctl_max_threads,
-	},
 	{
 		.procname	= "overflowuid",
 		.data		= &overflowuid,

-- 
2.47.2

