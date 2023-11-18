From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Fri, 17 Nov 2023 23:14:20 -0600
Subject: [PATCH v4 02/13] powerpc/rtas: Fall back to linear search on
 failed token->function lookup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231117-papr-sys_rtas-vs-lockdown-v4-2-b794d8cb8502@linux.ibm.com>
References: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
In-Reply-To: <20231117-papr-sys_rtas-vs-lockdown-v4-0-b794d8cb8502@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>
Cc: linuxppc-dev@lists.ozlabs.org, 
 =?utf-8?q?Michal_Such=C3=A1nek?= <msuchanek@suse.de>, tyreld@linux.ibm.com, 
 gcwilson@linux.ibm.com, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1700284468; l=2224;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=fqR135MhV0/mnXuWPlHbA4mjYrNmb6V6F7NtjxwwWz4=;
 b=1gj1CVGDNGrQ3ZnE1gH+Hb4OObRILu/JUtm/Vyb9MInRD39awwl4U0OVriXbAyMlX5jwCkaza
 9EZa2bNMQ0/DDRpYB6/oNo3QjnWU+JaDPwdG+JGyNPho6Rk4lL4MrVk
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enabling any of the powerpc:rtas_* tracepoints at boot is likely to
result in an oops on RTAS platforms. For example, booting a QEMU
pseries model with 'trace_event=powerpc:rtas_input' in the command
line leads to:

  BUG: Kernel NULL pointer dereference on read at 0x00000008
  Oops: Kernel access of bad area, sig: 7 [#1]
  NIP [c00000000004231c] do_enter_rtas+0x1bc/0x460
  LR [c00000000004231c] do_enter_rtas+0x1bc/0x460
  Call Trace:
    do_enter_rtas+0x1bc/0x460 (unreliable)
    rtas_call+0x22c/0x4a0
    rtas_get_boot_time+0x80/0x14c
    read_persistent_clock64+0x124/0x150
    read_persistent_wall_and_boot_offset+0x28/0x58
    timekeeping_init+0x70/0x348
    start_kernel+0xa0c/0xc1c
    start_here_common+0x1c/0x20

(This is preceded by a warning for the failed lookup in
rtas_token_to_function().)

This happens when __do_enter_rtas_trace() attempts a token to function
descriptor lookup before the xarray containing the mappings has been
set up.

Fall back to linear scan of the table if rtas_token_to_function_xarray
is empty.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: 24098f580e2b ("powerpc/rtas: add tracepoints around RTAS entry")
---
 arch/powerpc/kernel/rtas.c | 18 ++++++++++++++----
 1 file changed, 14 insertions(+), 4 deletions(-)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 1ad1869e2e96..f0051881348a 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -557,11 +557,21 @@ static const struct rtas_function *rtas_token_to_function(s32 token)
 		return NULL;
 
 	func = xa_load(&rtas_token_to_function_xarray, token);
+	if (func)
+		return func;
+	/*
+	 * Fall back to linear scan in case the reverse mapping hasn't
+	 * been initialized yet.
+	 */
+	if (xa_empty(&rtas_token_to_function_xarray)) {
+		for_each_rtas_function(func) {
+			if (func->token == token)
+				return func;
+		}
+	}
 
-	if (WARN_ONCE(!func, "unexpected failed lookup for token %d", token))
-		return NULL;
-
-	return func;
+	WARN_ONCE(true, "unexpected failed lookup for token %d", token);
+	return NULL;
 }
 
 /* This is here deliberately so it's only used in this file */

-- 
2.41.0

