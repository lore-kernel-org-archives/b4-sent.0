From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 30 May 2024 19:44:12 -0500
Subject: [PATCH] powerpc/rtas: Prevent Spectre v1 gadget construction in
 sys_rtas()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240530-sys_rtas-nargs-nret-v1-1-129acddd4d89@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAFsdWWYC/x2MQQqAMAzAvjJ6dlCnA/ErIlK0ai9TWhFF/LvDS
 yCH5AFjFTZo3QPKp5hsKUtZOBhXSgt7mbJDwFBjrNDbbYMeZD6RLpnKh6eyaZjmSBERcrkrz3L
 9165/3w+Mize3ZQAAAA==
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>
Cc: Breno Leitao <leitao@debian.org>, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717116259; l=1865;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=7xdTGOSOmIr2E7Iy/w6Rg7Grsm0W7C5NyiYeRCwJGRk=;
 b=K3GPmYx5N84KLR0/qh9q9edOJUNZHWejzXHxWhtyGcMGgZV+2MFcgwuA0kVuqTb6vgrnVVgB8
 YKELPWKjFKhA7C1N8mz+/fvBCPRfcx1VdeMBwpAHktyb8WCWem7PwzF
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Smatch warns:

  arch/powerpc/kernel/rtas.c:1932 __do_sys_rtas() warn: potential
  spectre issue 'args.args' [r] (local cap)

The 'nargs' and 'nret' locals come directly from a user-supplied
buffer and are used as indexes into a small stack-based array and as
inputs to copy_to_user() after they are subject to bounds checks.

Use array_index_nospec() after the bounds checks to clamp these values
for speculative execution.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Reported-by: Breno Leitao <leitao@debian.org>
---
Based on a change originally submitted by Breno Leitao in 2018:

https://lore.kernel.org/linuxppc-dev/1534876926-21849-1-git-send-email-leitao@debian.org/

I've used a Reported-by: tag to credit Breno, let me know if you would
prefer a different tag (perhaps Co-developed-by?)
---
 arch/powerpc/kernel/rtas.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/powerpc/kernel/rtas.c b/arch/powerpc/kernel/rtas.c
index 8064d9c3de86..f7e86e09c49f 100644
--- a/arch/powerpc/kernel/rtas.c
+++ b/arch/powerpc/kernel/rtas.c
@@ -19,6 +19,7 @@
 #include <linux/lockdep.h>
 #include <linux/memblock.h>
 #include <linux/mutex.h>
+#include <linux/nospec.h>
 #include <linux/of.h>
 #include <linux/of_fdt.h>
 #include <linux/reboot.h>
@@ -1916,6 +1917,9 @@ SYSCALL_DEFINE1(rtas, struct rtas_args __user *, uargs)
 	    || nargs + nret > ARRAY_SIZE(args.args))
 		return -EINVAL;
 
+	nargs = array_index_nospec(nargs, ARRAY_SIZE(args.args));
+	nret = array_index_nospec(nret, ARRAY_SIZE(args.args) - nargs);
+
 	/* Copy in args. */
 	if (copy_from_user(args.args, uargs->args,
 			   nargs * sizeof(rtas_arg_t)) != 0)

---
base-commit: be2fc65d66e0406cc9d39d40becaecdf4ee765f3
change-id: 20240530-sys_rtas-nargs-nret-a188eaf5a500

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

