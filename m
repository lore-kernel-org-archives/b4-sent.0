From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 18 Jan 2024 09:25:12 -0600
Subject: [PATCH RFC 1/5] dump_stack: Make arch description buffer
 __ro_after_init
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240118-update-dump-stack-arch-str-v1-1-5c0f98d017b5@linux.ibm.com>
References: <20240118-update-dump-stack-arch-str-v1-0-5c0f98d017b5@linux.ibm.com>
In-Reply-To: <20240118-update-dump-stack-arch-str-v1-0-5c0f98d017b5@linux.ibm.com>
To: "Aneesh Kumar K.V" <aneesh.kumar@linux.ibm.com>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>, 
 Brian King <brking@linux.ibm.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 John Ogness <john.ogness@linutronix.de>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Petr Mladek <pmladek@suse.com>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 Steven Rostedt <rostedt@goodmis.org>
Cc: linux-kernel@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1705591541; l=904;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=uGRC5bEXAZpqbl74Y43nE5tPlwjA0DDYCHWXiMdO7oY=;
 b=mRB3b+vZUc4j1CZuAqps+dMLW3dhH0rtknvVIhYr75cbUsWxHXQzwL1XHsgm2Dka6lOqHqzli
 tuQArMMkTQ6A8GpmfpD4X7jCoFyeMG5WzBkP2vlcjAz4E3Oo1hWIy2X
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The static hardware description buffer is populated by arch code
during boot and should not change afterwards, so mark it
__ro_after_init.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 lib/dump_stack.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/lib/dump_stack.c b/lib/dump_stack.c
index 83471e81501a..1057f102f6f2 100644
--- a/lib/dump_stack.c
+++ b/lib/dump_stack.c
@@ -6,6 +6,7 @@
 
 #include <linux/kernel.h>
 #include <linux/buildid.h>
+#include <linux/cache.h>
 #include <linux/export.h>
 #include <linux/sched.h>
 #include <linux/sched/debug.h>
@@ -15,7 +16,7 @@
 #include <linux/utsname.h>
 #include <linux/stop_machine.h>
 
-static char dump_stack_arch_desc_str[128];
+static char dump_stack_arch_desc_str[128] __ro_after_init;
 
 /**
  * dump_stack_set_arch_desc - set arch-specific str to show with task dumps

-- 
2.43.0

