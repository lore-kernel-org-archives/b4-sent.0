From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:09 -0800
Subject: [PATCH 19/36] xen/console: introduce printk_common()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-19-87b9a8375b7a@ford.com>
References: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
In-Reply-To: <20241126-vuart-ns8250-v1-v1-0-87b9a8375b7a@ford.com>
To: Jan Beulich <jbeulich@suse.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 "Daniel P. Smith" <dpsmith@apertussolutions.com>, 
 Stefano Stabellini <sstabellini@kernel.org>, Julien Grall <julien@xen.org>, 
 Bertrand Marquis <bertrand.marquis@arm.com>, 
 Michal Orzel <michal.orzel@amd.com>, Rahul Singh <rahul.singh@arm.com>, 
 Volodymyr Babchuk <Volodymyr_Babchuk@epam.com>, 
 Alistair Francis <alistair.francis@wdc.com>, 
 Bob Eshleman <bobbyeshleman@gmail.com>, 
 Connor Davis <connojdavis@gmail.com>, 
 Oleksii Kurochko <oleksii.kurochko@gmail.com>, 
 Shawn Anastasio <sanastasio@raptorengineering.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Juergen Gross <jgross@suse.com>, 
 Christian Lindig <christian.lindig@citrix.com>, 
 David Scott <dave@recoil.org>, 
 =?utf-8?q?Marek_Marczykowski-G=C3=B3recki?= <marmarek@invisiblethingslab.com>
Cc: xen-devel@lists.xenproject.org, Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=1598;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=ZaoWKGFunF1v2fJrLgskSFgg/fFHSsN+iDoAE6XfT9Q=;
 b=qf1Tso16MB8AZmrXNCz9umrGZGM1ODTNxpZz1C5AlhIFFZtIt51Zk7hm0IXDTzpOaQ21aT1Xy
 Bnsh8vhnpDLD2g2jthBGW9Vj4jFyK4LFbJhtEQZuruPSO9haplPlZcM
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce new printk() variant for convenient printouts which skip '(XEN)'
prefix on xen console. This is needed for the case when physical console is
owned by a domain w/ in-hypervisor UART emulation enabled.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/drivers/char/console.c | 8 ++++++++
 xen/include/xen/lib.h      | 3 +++
 2 files changed, 11 insertions(+)

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

