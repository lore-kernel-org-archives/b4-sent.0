From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:03 -0800
Subject: [PATCH 13/36] xen/domain: add get_initial_domain_id()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-13-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=3214;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=e/LNB+9Wk5d4Vu+ImwNmQARBXeefJiOOq9L8JfHstNA=;
 b=p4c6qAznAvJRnp/3HVjjynj1T4WRFFM62MWF06rptmAfMPUraD8W5+8g56LcbD6mMjTtn9dyK
 3ID6rRQiP1UCksYsjKunjlrT8zbD94uIl0NQoksdMflBSXs+VQ4OJ2s
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move get_initial_domain_id() to a public API and enable for all architectures.
That is pre-requisite change for console focus switch logic cleanup.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/include/asm/pv/shim.h |  4 ++--
 xen/arch/x86/pv/shim.c             |  4 ++--
 xen/common/domain.c                | 10 ++++++++++
 xen/include/xen/domain.h           |  2 ++
 4 files changed, 16 insertions(+), 4 deletions(-)

diff --git a/xen/arch/x86/include/asm/pv/shim.h b/xen/arch/x86/include/asm/pv/shim.h
index 6153e27005986881ad87e9db0b555b30edc59fc0..1515ad1b0680aa11ab91a152a1944fc1bb477a79 100644
--- a/xen/arch/x86/include/asm/pv/shim.h
+++ b/xen/arch/x86/include/asm/pv/shim.h
@@ -31,7 +31,7 @@ long cf_check pv_shim_cpu_up(void *data);
 long cf_check pv_shim_cpu_down(void *data);
 void pv_shim_online_memory(unsigned int nr, unsigned int order);
 void pv_shim_offline_memory(unsigned int nr, unsigned int order);
-domid_t get_initial_domain_id(void);
+domid_t pv_shim_initial_domain_id(void);
 uint64_t pv_shim_mem(uint64_t avail);
 void pv_shim_fixup_e820(void);
 const struct platform_bad_page *pv_shim_reserved_pages(unsigned int *size);
@@ -76,7 +76,7 @@ static inline void pv_shim_offline_memory(unsigned int nr, unsigned int order)
 {
     ASSERT_UNREACHABLE();
 }
-static inline domid_t get_initial_domain_id(void)
+static inline domid_t pv_shim_initial_domain_id(void)
 {
     return 0;
 }
diff --git a/xen/arch/x86/pv/shim.c b/xen/arch/x86/pv/shim.c
index 81e4a0516d18b359561f471f1d96e38977661ca7..17cb30620290c76cf42251f70cfa4199c0e165d1 100644
--- a/xen/arch/x86/pv/shim.c
+++ b/xen/arch/x86/pv/shim.c
@@ -328,7 +328,7 @@ int pv_shim_shutdown(uint8_t reason)
     }
 
     /* Update domain id. */
-    d->domain_id = get_initial_domain_id();
+    d->domain_id = pv_shim_initial_domain_id();
 
     /* Clean the iomem range. */
     BUG_ON(iomem_deny_access(d, 0, ~0UL));
@@ -1016,7 +1016,7 @@ void pv_shim_offline_memory(unsigned int nr, unsigned int order)
     }
 }
 
-domid_t get_initial_domain_id(void)
+domid_t pv_shim_initial_domain_id(void)
 {
     uint32_t eax, ebx, ecx, edx;
 
diff --git a/xen/common/domain.c b/xen/common/domain.c
index 92263a4fbdc57159b4a32d9d4ee038f9f37804ed..2f67aa06ed50e69c27cedc8d7f6eb0b469fe81cd 100644
--- a/xen/common/domain.c
+++ b/xen/common/domain.c
@@ -45,6 +45,7 @@
 
 #ifdef CONFIG_X86
 #include <asm/guest.h>
+#include <asm/pv/shim.h>
 #endif
 
 /* Linux config option: propageted to domain0 */
@@ -2229,6 +2230,15 @@ int continue_hypercall_on_cpu(
     return 0;
 }
 
+domid_t get_initial_domain_id(void)
+{
+#ifdef CONFIG_X86
+    return pv_shim_initial_domain_id();
+#else
+    return 0;
+#endif
+}
+
 /*
  * Local variables:
  * mode: C
diff --git a/xen/include/xen/domain.h b/xen/include/xen/domain.h
index 3de56352911347a54cce310f0211bcc213d8a08d..601ef431cf621af44c867400499b73b845eb137a 100644
--- a/xen/include/xen/domain.h
+++ b/xen/include/xen/domain.h
@@ -171,4 +171,6 @@ extern bool vmtrace_available;
 
 extern bool vpmu_is_available;
 
+domid_t get_initial_domain_id(void);
+
 #endif /* __XEN_DOMAIN_H__ */

-- 
2.34.1

