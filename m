From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 09 May 2025 14:54:14 +0200
Subject: [PATCH 10/12] sysctl: Move sysctl_panic_on_stackoverflow to
 kernel/panic.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250509-jag-mv_ctltables_iter2-v1-10-d0ad83f5f4c3@kernel.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1738;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=iBWZYDpQ2juAjhx5pX1DbD1nKbOZE742NSDAPf/9QSo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGgd+yZVZlAJvlSFeIOK7ZUIBFeRAqCzIUtq1
 EXP6L0iac8e6okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoHfsmAAoJELqXzVK3
 lkFPKsUL/34wrM9l0suCAomA6YIWhJCQFnrdoNObwQnmqYlomYI6m+y92V0xy+ltvIjej2DhMm9
 Zo7HqxRyRmRFfsvqc5OGeZkQQgCiKriH3QMnOiEt7ZNXZZWWura6lhop2H5YVmONmix6awBu8ok
 n6UWQ+lQG8Gg3b+l8Rs+ON5FCfDrM5pFk1VyQnpQ+qKQY8Jz17Isp/gJxz1hPUdCLgWEhuW9kD5
 MTnu4NTj8f7+ZDkSF/2sfIm5O0umKl+BNzXhJ8APNvw9PW2tuX/jD5tTYDxbGfBr1BOchy5eJZe
 DOEJAuJ1fUxNfP4HlZ6OD7TpYvLKsUTEA6cF9YrsqW/TThUbv52ajFr/LHzxj2KbUx9+QTnf3u1
 HdU2RSmv9uKIcVnQBvI80bJftXsSVI2fUQqQfwongGBHQLG4r51JY4KivxNZrgg7qS2CsWccQF9
 73RaPh70zGvXKDXnO7oh+GVcexPplGQ853rGTC8tjEiG6hO9FnaUG2fGqoWkB9/dH2Pn8Cuz8X8
 0A=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/panic.c  | 10 ++++++++++
 kernel/sysctl.c | 10 ----------
 2 files changed, 10 insertions(+), 10 deletions(-)

diff --git a/kernel/panic.c b/kernel/panic.c
index 213c6c9d6a750ff3d17f3cf530b37c619cd816f4..401f0997f654797acc3351040bbbda1845ce00c1 100644
--- a/kernel/panic.c
+++ b/kernel/panic.c
@@ -183,6 +183,16 @@ static const struct ctl_table kern_panic_table[] = {
 		.mode           = 0644,
 		.proc_handler   = proc_douintvec,
 	},
+#if (defined(CONFIG_X86_32) || defined(CONFIG_PARISC)) && \
+	defined(CONFIG_DEBUG_STACKOVERFLOW)
+	{
+		.procname	= "panic_on_stackoverflow",
+		.data		= &sysctl_panic_on_stackoverflow,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+#endif
 };
 
 static __init int kernel_panic_sysctls_init(void)
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index d5bebdd02cd4f1def7d9dd2b85454a9022b600b7..446d77ec44f57a4929389b64fc23d3b180f550b4 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1552,16 +1552,6 @@ static const struct ctl_table kern_table[] = {
 		.mode		= 0444,
 		.proc_handler	= proc_dointvec,
 	},
-#if (defined(CONFIG_X86_32) || defined(CONFIG_PARISC)) && \
-	defined(CONFIG_DEBUG_STACKOVERFLOW)
-	{
-		.procname	= "panic_on_stackoverflow",
-		.data		= &sysctl_panic_on_stackoverflow,
-		.maxlen		= sizeof(int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
-#endif
 #ifdef CONFIG_SYSCTL_ARCH_UNALIGN_NO_WARN
 	{
 		.procname	= "ignore-unaligned-usertrap",

-- 
2.47.2

