From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:08 +0200
Subject: [PATCH 04/12] mm: move randomize_va_space into memory.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-4-d0ad83f5f4c3@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1890;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=lbD12Kxx59vQ4CfWoFvcmBEI0Z7ENmEnOq1lhFaAf3U=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGgd+yL6XG7IKZNJemnuB1rPOszHmqOCUZ3Zs
 jVgj6kQvsj0HokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfsiAAoJELqXzVK3
 lkFP7zwL+wbFmnyUHyRQDfHaFCGu9MKJ/23nAFqv2PKDDVuL6RnqGSj+Oz9aVfBXXFbgiwfQSdS
 M8Di+bFDTA1BDI23Pc+gkOLFpi/dAxm/ZTV3e8QUzQTCObyrlB/J2n94yJMrOx0txlaxxyZ83i/
 k/Fy7MBTnx3gm4/a78AQCIu98FDMVQNCa5D2Fugr1q5sxsV9OS6qmNMcJDFotIhsmXYTyAvtYzg
 JdnrfOrevEVIcp5CWPDX09gX77gMYx50kH1ZOZ4H/rb7F/JxDqeKvXLgkQJ5Em9k3+zgtunwxH9
 BSxhe5p0LiO9sdZxARP7ufpuEuj2m6gv3quOYh5dxVHr1Hcf9CIiiXK7+AbN2XFEAYg3Ql70HIw
 3u5rhO/KHqWOiSPryFYUXfdE8ScFh/Spr1VxLTqH8p2FAJx3cZN5IraAIDYeR5xEpmN2k9yo0bA
 yGEsnc69Ev3O3LWMJLiF7aZm2CGi2nZIx/7nmrfhvakk6VVLE5L4vjfu35geou9mZQKPOmnLf78
 Kg=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the randomize_va_space variable together with all its sysctl table
elements into memory.c. Register it to the "kernel" directory by
adding it to the subsys initialization calls

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c |  9 ---------
 mm/memory.c     | 18 ++++++++++++++++++
 2 files changed, 18 insertions(+), 9 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index fd76f0e1d490940a67d72403d72d204ff13d888a..adc2d3ea127841d87b7073ed81d6121c9a60e59a 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1688,15 +1688,6 @@ static const struct ctl_table kern_table[] = {
 		.proc_handler	= proc_dointvec,
 	},
 #endif
-#if defined(CONFIG_MMU)
-	{
-		.procname	= "randomize_va_space",
-		.data		= &randomize_va_space,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-#endif
 #ifdef CONFIG_SYSCTL_ARCH_UNALIGN_NO_WARN
 	{
 		.procname	= "ignore-unaligned-usertrap",
diff --git a/mm/memory.c b/mm/memory.c
index ba3ea0a82f7f770b6cacba4526ba9c8c4929ddad..0a9e325fe3d7631e619ab58d79785cc92fd60c29 100644
--- a/mm/memory.c
+++ b/mm/memory.c
@@ -125,6 +125,24 @@ int randomize_va_space __read_mostly =
 					2;
 #endif
 
+static const struct ctl_table mmu_sysctl_table[] = {
+	{
+		.procname	= "randomize_va_space",
+		.data		= &randomize_va_space,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+};
+
+static int __init init_mm_sysctl(void)
+{
+	register_sysctl_init("kernel", mmu_sysctl_table);
+	return 0;
+}
+
+subsys_initcall(init_mm_sysctl);
+
 #ifndef arch_wants_old_prefaulted_pte
 static inline bool arch_wants_old_prefaulted_pte(void)
 {

-- 
2.47.2

