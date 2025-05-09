From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:13 +0200
Subject: [PATCH 09/12] sysctl: move cad_pid into kernel/pid.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-9-d0ad83f5f4c3@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3106;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=bpddqMKPTBhFpPzB7Q4vEETp0NRXruc3g0KF10Cik6o=;
 b=kA0DAAoBupfNUreWQU8ByyZiAGgd+yWiielUUZACujyl8jOrulsz1fYpBCHwtYK+YtZFw5/za
 4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfslAAoJELqXzVK3lkFPcdoL/3K0
 M/MaJWC4QAeabx7/KfG9il1+qnbzwuXO3ZCy8VPeYq7BERSFODTJupA9U4Z73cuYJIgvWD3BqdB
 gZyPD5wrmFGrb5goKkjtmXJPSgMbNxzbmCZpHvchlkgWMiaj6qBnR2uAAN04BoIq1k85sKnfJnu
 z3jzXB4uMIL4DI/G5vOMvAgHYJWk5sTwmcgQtlBeWJiBqLkCy2N4sbbykzpmo6yuRFnbSpAqM/b
 cktCdto61a4CS97jv7kPB74xmO1gwruMUVHP99OfSZhmD+E7SzLcs5MhkitLftMov3hnHn8rRI6
 Q7tLo4fW5pWjdSFMN8TsJVyzBzLDNZ5TlfzZnhu+6sfP7Y4+HttHcwwUjU9xQ1n4eUu8m/d/mQP
 K+86JrrX2uB9A42mQ35aFapsPmvU+M1ygWLhiKmFw19vTgXGgXLIXCIu7BUufcxh8yarQ2A21BL
 sECoALsl2QU5r2tYvYZeNJzCvFYFnbHoB0fihlJgx4hPhpaTJgKzEb+IysjQ==
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move cad_pid as well as supporting function proc_do_cad_pid into
kernel/pic.c. Replaced call to __do_proc_dointvec with proc_dointvec
inside proc_do_cad_pid which requires the copy of the ctl_table to
handle the temp value.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/pid.c    | 32 ++++++++++++++++++++++++++++++++
 kernel/sysctl.c | 31 -------------------------------
 2 files changed, 32 insertions(+), 31 deletions(-)

diff --git a/kernel/pid.c b/kernel/pid.c
index 4ac2ce46817fdefff8888681bb5ca3f2676e8add..bc87ba08ae8b7c67f3457b31309b56b5d90f8c52 100644
--- a/kernel/pid.c
+++ b/kernel/pid.c
@@ -717,6 +717,29 @@ static struct ctl_table_root pid_table_root = {
 	.set_ownership	= pid_table_root_set_ownership,
 };
 
+static int proc_do_cad_pid(const struct ctl_table *table, int write, void *buffer,
+		size_t *lenp, loff_t *ppos)
+{
+	struct pid *new_pid;
+	pid_t tmp_pid;
+	int r;
+	struct ctl_table tmp_table = *table;
+
+	tmp_pid = pid_vnr(cad_pid);
+	tmp_table.data = &tmp_pid;
+
+	r = proc_dointvec(&tmp_table, write, buffer, lenp, ppos);
+	if (r || !write)
+		return r;
+
+	new_pid = find_get_pid(tmp_pid);
+	if (!new_pid)
+		return -ESRCH;
+
+	put_pid(xchg(&cad_pid, new_pid));
+	return 0;
+}
+
 static const struct ctl_table pid_table[] = {
 	{
 		.procname	= "pid_max",
@@ -727,6 +750,15 @@ static const struct ctl_table pid_table[] = {
 		.extra1		= &pid_max_min,
 		.extra2		= &pid_max_max,
 	},
+#ifdef CONFIG_PROC_SYSCTL
+	{
+		.procname	= "cad_pid",
+		.data		= NULL,
+		.maxlen		= sizeof(int),
+		.mode		= 0600,
+		.proc_handler	= proc_do_cad_pid,
+	},
+#endif
 };
 #endif
 
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 9d8db9cef11122993d850ab5c753e3da1cbfb5cc..d5bebdd02cd4f1def7d9dd2b85454a9022b600b7 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1224,28 +1224,6 @@ int proc_dointvec_ms_jiffies(const struct ctl_table *table, int write, void *buf
 				do_proc_dointvec_ms_jiffies_conv, NULL);
 }
 
-static int proc_do_cad_pid(const struct ctl_table *table, int write, void *buffer,
-		size_t *lenp, loff_t *ppos)
-{
-	struct pid *new_pid;
-	pid_t tmp;
-	int r;
-
-	tmp = pid_vnr(cad_pid);
-
-	r = __do_proc_dointvec(&tmp, table, write, buffer,
-			       lenp, ppos, NULL, NULL);
-	if (r || !write)
-		return r;
-
-	new_pid = find_get_pid(tmp);
-	if (!new_pid)
-		return -ESRCH;
-
-	put_pid(xchg(&cad_pid, new_pid));
-	return 0;
-}
-
 /**
  * proc_do_large_bitmap - read/write from/to a large bitmap
  * @table: the sysctl table
@@ -1541,15 +1519,6 @@ static const struct ctl_table kern_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dostring,
 	},
-#endif
-#ifdef CONFIG_PROC_SYSCTL
-	{
-		.procname	= "cad_pid",
-		.data		= NULL,
-		.maxlen		= sizeof (int),
-		.mode		= 0600,
-		.proc_handler	= proc_do_cad_pid,
-	},
 #endif
 	{
 		.procname	= "overflowuid",

-- 
2.47.2

