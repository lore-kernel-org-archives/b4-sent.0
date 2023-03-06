From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 06 Mar 2023 15:33:47 -0600
Subject: [PATCH 8/8] powerpc/rtas: consume retry statuses in sys_rtas()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230220-rtas-queue-for-6-4-v1-8-010e4416f13f@linux.ibm.com>
References: <20230220-rtas-queue-for-6-4-v1-0-010e4416f13f@linux.ibm.com>
In-Reply-To: <20230220-rtas-queue-for-6-4-v1-0-010e4416f13f@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Tyrel Datwyler <tyreld@linux.ibm.com>, 
 Scott Cheloha <cheloha@linux.ibm.com>, Andrew Donnellan <ajd@linux.ibm.com>, 
 Nick Child <nnac123@linux.ibm.com>, Laurent Dufour <ldufour@linux.ibm.com>, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1678138471; l=4978;
 i=nathanl@linux.ibm.com; s=20230206; h=from:subject:message-id;
 bh=c9BQAHGmY2GogAt3U4zGeJroCpzuc+rCQMgEl6+oVsM=;
 b=kKTvEjvwuEI5WkdJ8fnTlIWmo/Rx7sNqbJe1LIa8kz9Le9hpCSffZ0p1Dbh3FNnHHEKbzrDpB
 gnnb9af6Aq1BIiAOKjyz9z5YcHXrMZFC2jNvl2ui8cwrQUvtPK7H5+k
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=6daubz/ymoaMF+8voz7UHwnhluEsmDZuqygIIMWpQQY=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230206 with auth_id=27
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The kernel can handle retrying RTAS function calls in response to
-2/990x in the sys_rtas() handler instead of relaying the intermediate
status to user space.

Justifications:

* Currently it's nondeterministic and quite variable in practice
  whether a retry status is returned for any given invocation of
  sys_rtas(). Therefore user space code cannot be expecting a retry
  result without already being broken.

* This tends to significantly reduce the total number of system calls
  issued by programs such as drmgr which make use of sys_rtas(),
  improving the experience of tracing and debugging such
  programs. This is the main motivation for me: I think this change
  will make it easier for us to characterize current sys_rtas() use
  cases as we move them to other interfaces over time.

* It reduces the number of opportunities for user space to leave
  complex operations, such as those associated with DLPAR, incomplete
  and diffcult to recover.

* We can expect performance improvements for existing sys_rtas()
  users, not only because of overall reduction in the number of system
  calls issued, but also due to the better handling of -2/990x in the
  kernel. For example, librtas still sleeps for 1ms on -2, which is
  completely unnecessary.

Performance differences for PHB add and remove on a small P10 PowerVM
partition are included below. For add, elapsed time is slightly
reduced. For remove, there are more significant improvements: the
number of context switches is reduced by an order of magnitude, and
elapsed time is reduced by over half.

(- before, + after):

  Performance counter stats for 'drmgr -c phb -a -s PHB 23' (5 runs):

-          1,847.58 msec task-clock                       #    0.135 CPUs utilized               ( +- 14.15% )
-            10,867      cs                               #    9.800 K/sec                       ( +- 14.14% )
+          1,901.15 msec task-clock                       #    0.148 CPUs utilized               ( +- 14.13% )
+            10,451      cs                               #    9.158 K/sec                       ( +- 14.14% )

-         13.656557 +- 0.000124 seconds time elapsed  ( +-  0.00% )
+          12.88080 +- 0.00404 seconds time elapsed  ( +-  0.03% )

  Performance counter stats for 'drmgr -c phb -r -s PHB 23' (5 runs):

-          1,473.75 msec task-clock                       #    0.092 CPUs utilized               ( +- 14.15% )
-             2,652      cs                               #    3.000 K/sec                       ( +- 14.16% )
+          1,444.55 msec task-clock                       #    0.221 CPUs utilized               ( +- 14.14% )
+               104      cs                               #  119.957 /sec                        ( +- 14.63% )

-          15.99718 +- 0.00801 seconds time elapsed  ( +-  0.05% )
+           6.54256 +- 0.00830 seconds time elapsed  ( +-  0.13% )

Move the existing rtas_lock-guarded critical section in sys_rtas()
into a conventional rtas_busy_delay()-based loop, returning to user
space only when a final success or failure result is available.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 28 ++++++++++++++++------------
 1 file changed, 16 insertions(+), 12 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 47a2aa43d7d4..c330a22ccc70 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -1798,7 +1798,6 @@ static bool block_rtas_call(int token, int nargs,
 /* We assume to be passed big endian arguments */
 SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 {
-	struct pin_cookie cookie;
 	struct rtas_args args;
 	unsigned long flags;
 	char *buff_copy, *errbuf = NULL;
@@ -1866,20 +1865,25 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 
 	buff_copy = get_errorlog_buffer();
 
-	raw_spin_lock_irqsave(&rtas_lock, flags);
-	cookie = lockdep_pin_lock(&rtas_lock);
+	do {
+		struct pin_cookie cookie;
 
-	rtas_args = args;
-	do_enter_rtas(&rtas_args);
-	args = rtas_args;
+		raw_spin_lock_irqsave(&rtas_lock, flags);
+		cookie = lockdep_pin_lock(&rtas_lock);
 
-	/* A -1 return code indicates that the last command couldn't
-	   be completed due to a hardware error. */
-	if (be32_to_cpu(args.rets[0]) == -1)
-		errbuf = __fetch_rtas_last_error(buff_copy);
+		rtas_args = args;
+		do_enter_rtas(&rtas_args);
+		args = rtas_args;
 
-	lockdep_unpin_lock(&rtas_lock, cookie);
-	raw_spin_unlock_irqrestore(&rtas_lock, flags);
+		/*
+		 * Handle error record retrieval before releasing the lock.
+		 */
+		if (be32_to_cpu(args.rets[0]) == -1)
+			errbuf = __fetch_rtas_last_error(buff_copy);
+
+		lockdep_unpin_lock(&rtas_lock, cookie);
+		raw_spin_unlock_irqrestore(&rtas_lock, flags);
+	} while (rtas_busy_delay(be32_to_cpu(args.rets[0])));
 
 	if (buff_copy) {
 		if (errbuf)

-- 
2.39.1

