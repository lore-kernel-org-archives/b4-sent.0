From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 07 Dec 2023 17:35:47 -0600
Subject: [PATCH v5 08/13] powerpc/rtas: Warn if per-function lock isn't
 held
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231207-papr-sys_rtas-vs-lockdown-v5-8-2ce965636a58@linux.ibm.com>
References: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
In-Reply-To: <20231207-papr-sys_rtas-vs-lockdown-v5-0-2ce965636a58@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, 
 "Aneesh Kumar K.V (IBM)" <aneesh.kumar@kernel.org>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701992313; l=1931;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=WeXFrQimFfnHGgmR7i5yQRK5CXtu2ckkZ+eRYu/mNRs=;
 b=XT53HGdVRT4F1cRAiaWlZ38jWNSACafNy+8GhDfhvXtwo0AQ/XMG/eZA88mvLSLn26W12qeJl
 rvI25FJgIpbCLvR1EGFFyu9LD/T4zJyekzbBDguUmXjqGRET5oD3vZx
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the function descriptor has a populated lock member, then callers
are required to hold it across calls. Now that the firmware activation
sequence is appropriately guarded, we can warn when the requirement
isn't satisfied.

__do_enter_rtas_trace() gets reorganized a bit as a result of
performing the function descriptor lookup unconditionally now.

Reviewed-by: Aneesh Kumar K.V (IBM) <aneesh.kumar@kernel.org>
Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 arch/powerpc/kernel/rtas.c | 21 +++++++++------------
 1 file changed, 9 insertions(+), 12 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 72f6b5a402dd..7e793b503e29 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -671,28 +671,25 @@ static void __do_enter_rtas(struct rtas_args *args)
 
 static void __do_enter_rtas_trace(struct rtas_args *args)
 {
-	const char *name = NULL;
+	const struct rtas_function *func = rtas_token_to_function(be32_to_cpu(args->token));
 
-	if (args == &rtas_args)
-		lockdep_assert_held(&rtas_lock);
 	/*
-	 * If the tracepoints that consume the function name aren't
-	 * active, avoid the lookup.
+	 * If there is a per-function lock, it must be held by the
+	 * caller.
 	 */
-	if ((trace_rtas_input_enabled() || trace_rtas_output_enabled())) {
-		const s32 token = be32_to_cpu(args->token);
-		const struct rtas_function *func = rtas_token_to_function(token);
+	if (func->lock)
+		lockdep_assert_held(func->lock);
 
-		name = func->name;
-	}
+	if (args == &rtas_args)
+		lockdep_assert_held(&rtas_lock);
 
-	trace_rtas_input(args, name);
+	trace_rtas_input(args, func->name);
 	trace_rtas_ll_entry(args);
 
 	__do_enter_rtas(args);
 
 	trace_rtas_ll_exit(args);
-	trace_rtas_output(args, name);
+	trace_rtas_output(args, func->name);
 }
 
 static void do_enter_rtas(struct rtas_args *args)

-- 
2.41.0

