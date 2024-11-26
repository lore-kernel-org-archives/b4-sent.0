From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:04 -0800
Subject: [PATCH 14/36] xen/domain: enable max_init_domid for all
 architectures
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-14-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=3782;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=yaQRDGz2W+Ijh9JWeI+JahaekRUAILaRwxdJICvftvE=;
 b=Cpw86+mRzAjuPvdWy+ql0J5AE4/wZWwSFWswO+Khyo0kNcLmJbm4nSQUK7OJQrG7/wywrPs6V
 +/6vEBR8fRWDpnQsSDMChi/Z7902+RqQjGkmF0v0XR7oR3vrJFrG73O
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move max_init_domid to a public API and enable for all architectures.
That is pre-requisite change for console focus switch logic cleanup.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/arm/include/asm/setup.h   | 2 --
 xen/arch/arm/setup.c               | 2 --
 xen/arch/ppc/include/asm/setup.h   | 2 --
 xen/arch/riscv/include/asm/setup.h | 2 --
 xen/arch/x86/include/asm/setup.h   | 2 --
 xen/common/domain.c                | 3 +++
 xen/include/xen/domain.h           | 2 ++
 7 files changed, 5 insertions(+), 10 deletions(-)

diff --git a/xen/arch/arm/include/asm/setup.h b/xen/arch/arm/include/asm/setup.h
index 64c227d171fc7b92e5b62d9fd42e5662871bd12b..d4e1670cd69cdd4475b2a5eb316d2c0601090ed7 100644
--- a/xen/arch/arm/include/asm/setup.h
+++ b/xen/arch/arm/include/asm/setup.h
@@ -19,8 +19,6 @@ struct map_range_data
     struct rangeset *irq_ranges;
 };
 
-extern domid_t max_init_domid;
-
 void copy_from_paddr(void *dst, paddr_t paddr, unsigned long len);
 
 size_t estimate_efi_size(unsigned int mem_nr_banks);
diff --git a/xen/arch/arm/setup.c b/xen/arch/arm/setup.c
index 71ebaa77ca94ab6f5878135406dd3b6d79a59754..b4855ede8876b365101a2d6a146384a39a503382 100644
--- a/xen/arch/arm/setup.c
+++ b/xen/arch/arm/setup.c
@@ -58,8 +58,6 @@ struct cpuinfo_arm __read_mostly system_cpuinfo;
 bool __read_mostly acpi_disabled;
 #endif
 
-domid_t __read_mostly max_init_domid;
-
 static __used void init_done(void)
 {
     int rc;
diff --git a/xen/arch/ppc/include/asm/setup.h b/xen/arch/ppc/include/asm/setup.h
index e4f64879b68ca5aac24bd9544255143e6ef693f3..956fa6985adb23375bd41d3e5d34d9d5f0712bd5 100644
--- a/xen/arch/ppc/include/asm/setup.h
+++ b/xen/arch/ppc/include/asm/setup.h
@@ -1,6 +1,4 @@
 #ifndef __ASM_PPC_SETUP_H__
 #define __ASM_PPC_SETUP_H__
 
-#define max_init_domid (0)
-
 #endif /* __ASM_PPC_SETUP_H__ */
diff --git a/xen/arch/riscv/include/asm/setup.h b/xen/arch/riscv/include/asm/setup.h
index c0214a9bf295f516572af87841e40ff6aaf79b28..0bbb8ab37cf9af89206a09c0f11767b090814ea9 100644
--- a/xen/arch/riscv/include/asm/setup.h
+++ b/xen/arch/riscv/include/asm/setup.h
@@ -3,8 +3,6 @@
 #ifndef ASM__RISCV__SETUP_H
 #define ASM__RISCV__SETUP_H
 
-#define max_init_domid (0)
-
 #endif /* ASM__RISCV__SETUP_H */
 
 /*
diff --git a/xen/arch/x86/include/asm/setup.h b/xen/arch/x86/include/asm/setup.h
index 5c2391a8684b66efdf4b092409ed33935db6b40c..296348655b9d146c73acc305cc9edd5fd46f7d47 100644
--- a/xen/arch/x86/include/asm/setup.h
+++ b/xen/arch/x86/include/asm/setup.h
@@ -69,6 +69,4 @@ extern bool opt_dom0_verbose;
 extern bool opt_dom0_cpuid_faulting;
 extern bool opt_dom0_msr_relaxed;
 
-#define max_init_domid (0)
-
 #endif
diff --git a/xen/common/domain.c b/xen/common/domain.c
index 2f67aa06ed50e69c27cedc8d7f6eb0b469fe81cd..d8f6829db50dabba7464004b39eea39f6970f800 100644
--- a/xen/common/domain.c
+++ b/xen/common/domain.c
@@ -65,6 +65,9 @@ DEFINE_RCU_READ_LOCK(domlist_read_lock);
 static struct domain *domain_hash[DOMAIN_HASH_SIZE];
 struct domain *domain_list;
 
+/* Last known non-system domain ID. */
+domid_t __read_mostly max_init_domid;
+
 /*
  * Insert a domain into the domlist/hash.  This allows the domain to be looked
  * up by domid, and therefore to be the subject of hypercalls/etc.
diff --git a/xen/include/xen/domain.h b/xen/include/xen/domain.h
index 601ef431cf621af44c867400499b73b845eb137a..6102826a929ff7aad58a4bc40974815071a97446 100644
--- a/xen/include/xen/domain.h
+++ b/xen/include/xen/domain.h
@@ -171,6 +171,8 @@ extern bool vmtrace_available;
 
 extern bool vpmu_is_available;
 
+extern domid_t max_init_domid;
+
 domid_t get_initial_domain_id(void);
 
 #endif /* __XEN_DOMAIN_H__ */

-- 
2.34.1

