From: Denis Mukhin <dmukhin@ford.com>
Date: Thu, 05 Dec 2024 20:41:46 -0800
Subject: [PATCH v2 16/35] xen/console: introduce printk_common()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-vuart-ns8250-v1-16-e9aa923127eb@ford.com>
References: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
In-Reply-To: <20241205-vuart-ns8250-v1-0-e9aa923127eb@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Andrew Cooper <andrew.cooper3@citrix.com>, 
 Jan Beulich <jbeulich@suse.com>, Julien Grall <julien@xen.org>, 
 Stefano Stabellini <sstabellini@kernel.org>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733460094; l=2804;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=0ZbhB6X3j//rZlvA+RHGboOQv/T4QXzBiywEl761Zm0=;
 b=mvzE8dnFdKifjiI0dNonuR4BBXjCK1QgfdIVHGd90YVxQ4pyP2joNBy5YkM/E0s0jgY0pCc59
 ZutJT2tuuA5B0gthGeK0qfNuZBTsquHOQi7NQWwUpYzKUjR3VI2XKEp
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce new printk() variant for convenient printouts which skip '(XEN)'
prefix on xen console. This is needed for the case when physical console is
owned by a domain w/ in-hypervisor UART emulation enabled.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 automation/eclair_analysis/ECLAIR/deviations.ecl | 2 +-
 xen/drivers/char/console.c                       | 8 ++++++++
 xen/include/xen/lib.h                            | 3 +++
 3 files changed, 12 insertions(+), 1 deletion(-)

diff --git a/automation/eclair_analysis/ECLAIR/deviations.ecl b/automation/eclair_analysis/ECLAIR/deviations.ecl
index 2f58f292036e3561118ce9664a92756b1b938739..c59d075262e9e6618ea2a2d27611a537ded3a776 100644
--- a/automation/eclair_analysis/ECLAIR/deviations.ecl
+++ b/automation/eclair_analysis/ECLAIR/deviations.ecl
@@ -522,7 +522,7 @@ safe."
 -config=MC3R1.R17.1,reports+={deliberate,"any_area(^.*va_list.*$&&context(ancestor_or_self(^.*printf\\(.*\\)$)))"}
 -config=MC3R1.R17.1,reports+={deliberate,"any_area(^.*va_list.*$&&context(ancestor_or_self(name(panic)&&kind(function))))"}
 -config=MC3R1.R17.1,reports+={deliberate,"any_area(^.*va_list.*$&&context(ancestor_or_self(name(elf_call_log_callback)&&kind(function))))"}
--config=MC3R1.R17.1,reports+={deliberate,"any_area(^.*va_list.*$&&context(ancestor_or_self(name(vprintk_common)&&kind(function))))"}
+-config=MC3R1.R17.1,reports+={deliberate,"any_area(^.*va_list.*$&&context(ancestor_or_self(name(^v?printk_common)&&kind(function))))"}
 -config=MC3R1.R17.1,macros+={hide , "^va_(arg|start|copy|end)$"}
 -doc_end
 
diff --git a/xen/drivers/char/console.c b/xen/drivers/char/console.c
index 86bf899ada8f8221ffc77bcffb1f58777a22198e..f034ce5aab3f3bf59b0df9fa583ee9ce32dbf665 100644
--- a/xen/drivers/char/console.c
+++ b/xen/drivers/char/console.c
@@ -968,6 +968,14 @@ void printk(const char *fmt, ...)
     va_end(args);
 }
 
+void printk_common(const char *fmt, ...)
+{
+    va_list args;
+    va_start(args, fmt);
+    vprintk_common("", fmt, args);
+    va_end(args);
+}
+
 void guest_printk(const struct domain *d, const char *fmt, ...)
 {
     va_list args;
diff --git a/xen/include/xen/lib.h b/xen/include/xen/lib.h
index 81b722ea3e801e9089aaf8758249feb3a758c4f7..8a7ff2e8af9089796ff28ef8d01c00e9845782ca 100644
--- a/xen/include/xen/lib.h
+++ b/xen/include/xen/lib.h
@@ -61,6 +61,9 @@ debugtrace_printk(const char *fmt, ...) {}
 extern void printk(const char *fmt, ...)
     __attribute__ ((format (printf, 1, 2), cold));
 
+extern void printk_common(const char *fmt, ...)
+    __attribute__ ((format (printf, 1, 2)));
+
 #define printk_once(fmt, args...)               \
 ({                                              \
     static bool __read_mostly once_;            \

-- 
2.34.1

