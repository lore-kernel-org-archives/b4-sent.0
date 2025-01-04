From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:12 -0800
Subject: [PATCH v3 06/24] xen/domain: introduce hardware emulation flags
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-6-c5d36b31d66c@ford.com>
References: <20250103-vuart-ns8250-v3-v1-0-c5d36b31d66c@ford.com>
In-Reply-To: <20250103-vuart-ns8250-v3-v1-0-c5d36b31d66c@ford.com>
To: xen-devel@lists.xenproject.org
Cc: Stefano Stabellini <sstabellini@kernel.org>, 
 Julien Grall <julien@xen.org>, Michal Orzel <michal.orzel@amd.com>, 
 Andrew Cooper <andrew.cooper3@citrix.com>, 
 Anthony PERARD <anthony.perard@vates.tech>, Jan Beulich <jbeulich@suse.com>, 
 =?utf-8?q?Roger_Pau_Monn=C3=A9?= <roger.pau@citrix.com>, 
 Denis Mukhin <dmukhin@ford.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=15422;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=yo4lK/WoRy/gFaXrqWR73G8aid7G29/FsP8hJ1ebvNs=;
 b=x65w53tEdhJNfnDQwDvwDCI6NghHC/63VP4zaLKnVqk0fUWNCWc/gcP61ZPVZC8xu1iwsvXGW
 mUlDZIBx7S4CbRDiYShFkvq1zTtTTSOVcQNRv5cCqQCg228IdGqqj2/
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Define an architecture-independent location for describing hardware emulation
flags for configuring in-hypervisor emulators.

Print d->arch.emulation_flags from 'q' keyhandler for better traceability while
debugging in-hypervisor hardware emulators.

Also, expanded the error message in arch_domain_create() in x86 case when
user-defined domain emulation_flags are incompatible w/ platform supported
emulation_flags.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 tools/helpers/init-xenstore-domain.c             |  1 +
 tools/libs/light/libxl_x86.c                     |  5 +-
 tools/ocaml/libs/xc/xenctrl_stubs.c              |  1 +
 tools/python/xen/lowlevel/xc/xc.c                |  5 +-
 tools/tests/paging-mempool/test-paging-mempool.c |  1 +
 tools/tests/resource/test-resource.c             |  1 +
 tools/tests/tsx/test-tsx.c                       |  1 +
 xen/arch/arm/include/asm/domain.h                |  2 +
 xen/arch/ppc/include/asm/domain.h                |  2 +
 xen/arch/riscv/include/asm/domain.h              |  2 +
 xen/arch/x86/domain.c                            | 11 +++--
 xen/arch/x86/include/asm/domain.h                |  3 +-
 xen/common/keyhandler.c                          |  1 +
 xen/include/Makefile                             |  1 +
 xen/include/public/arch-x86/xen.h                | 30 +-----------
 xen/include/public/virtdev.h                     | 61 ++++++++++++++++++++++++
 xen/include/xen/domain.h                         |  1 +
 17 files changed, 90 insertions(+), 39 deletions(-)

diff --git a/tools/helpers/init-xenstore-domain.c b/tools/helpers/init-xenstore-domain.c
index 01ca667d25d15032e9acaff025e83b80aefd2ecb..4b64a417def59c92b8bfb828468591d00d16c105 100644
--- a/tools/helpers/init-xenstore-domain.c
+++ b/tools/helpers/init-xenstore-domain.c
@@ -16,6 +16,7 @@
 #include <xen-tools/common-macros.h>
 #include <xen-xsm/flask/flask.h>
 #include <xen/io/xenbus.h>
+#include <xen/virtdev.h>
 
 #include "init-dom-json.h"
 
diff --git a/tools/libs/light/libxl_x86.c b/tools/libs/light/libxl_x86.c
index a3164a3077fec7e1b81a34074894dc646954a49a..80a8a4f17a9a2d7f84f94382e110d511b76604a2 100644
--- a/tools/libs/light/libxl_x86.c
+++ b/tools/libs/light/libxl_x86.c
@@ -1,5 +1,6 @@
 #include "libxl_internal.h"
 #include "libxl_arch.h"
+#include <xen/virtdev.h>
 #include <xen/arch-x86/cpuid.h>
 
 int libxl__arch_domain_prepare_config(libxl__gc *gc,
@@ -8,7 +9,9 @@ int libxl__arch_domain_prepare_config(libxl__gc *gc,
 {
     switch(d_config->c_info.type) {
     case LIBXL_DOMAIN_TYPE_HVM:
-        config->arch.emulation_flags = (XEN_X86_EMU_ALL & ~XEN_X86_EMU_VPCI);
+        config->arch.emulation_flags = XEN_X86_EMU_ALL;
+        config->arch.emulation_flags &= ~XEN_X86_EMU_VPCI;
+
         if (!libxl_defbool_val(d_config->b_info.u.hvm.pirq))
             config->arch.emulation_flags &= ~XEN_X86_EMU_USE_PIRQ;
         break;
diff --git a/tools/ocaml/libs/xc/xenctrl_stubs.c b/tools/ocaml/libs/xc/xenctrl_stubs.c
index 863ab3c778cd19637d8c52ec67dac7623be848b5..b693f3458629fb956d543d7491348cf953c67d6f 100644
--- a/tools/ocaml/libs/xc/xenctrl_stubs.c
+++ b/tools/ocaml/libs/xc/xenctrl_stubs.c
@@ -35,6 +35,7 @@
 #define XC_WANT_COMPAT_MAP_FOREIGN_API
 #include <xenctrl.h>
 #include <xenguest.h>
+#include <xen/virtdev.h>
 #include <xen-tools/common-macros.h>
 
 #include "mmap_stubs.h"
diff --git a/tools/python/xen/lowlevel/xc/xc.c b/tools/python/xen/lowlevel/xc/xc.c
index 9feb12ae2b16e48cb5d0c3c45044ae226f152f2d..d064e9e7af2fcc09dbd6485e8b9ef648b8068d00 100644
--- a/tools/python/xen/lowlevel/xc/xc.c
+++ b/tools/python/xen/lowlevel/xc/xc.c
@@ -18,6 +18,7 @@
 #include <netdb.h>
 #include <arpa/inet.h>
 
+#include <xen/virtdev.h>
 #include <xen/elfnote.h>
 #include <xen/hvm/hvm_info_table.h>
 #include <xen/hvm/params.h>
@@ -159,9 +160,7 @@ static PyObject *pyxc_domain_create(XcObject *self,
 
 #if defined (__i386) || defined(__x86_64__)
     if ( config.flags & XEN_DOMCTL_CDF_hvm )
-        config.arch.emulation_flags = XEN_X86_EMU_ALL &
-                                      ~(XEN_X86_EMU_VPCI |
-                                        XEN_X86_EMU_USE_PIRQ);
+        config.arch.emulation_flags = XEN_X86_EMU_BASELINE;
 #elif defined (__arm__) || defined(__aarch64__)
     config.arch.gic_version = XEN_DOMCTL_CONFIG_GIC_NATIVE;
 #else
diff --git a/tools/tests/paging-mempool/test-paging-mempool.c b/tools/tests/paging-mempool/test-paging-mempool.c
index 1ebc13455ac263b8d2067f3676ba324da61abb83..121ffdcd376ddb324130a441352bf2a53d69b1e9 100644
--- a/tools/tests/paging-mempool/test-paging-mempool.c
+++ b/tools/tests/paging-mempool/test-paging-mempool.c
@@ -9,6 +9,7 @@
 #include <xenforeignmemory.h>
 #include <xengnttab.h>
 #include <xen-tools/common-macros.h>
+#include <xen/virtdev.h>
 
 static unsigned int nr_failures;
 #define fail(fmt, ...)                          \
diff --git a/tools/tests/resource/test-resource.c b/tools/tests/resource/test-resource.c
index 1b10be16a6b43f8448a6f4ccf8fd093b6556b915..e388bfeec57b1f16a6ccd9ede8ff1c02c0448393 100644
--- a/tools/tests/resource/test-resource.c
+++ b/tools/tests/resource/test-resource.c
@@ -8,6 +8,7 @@
 #include <xenforeignmemory.h>
 #include <xengnttab.h>
 #include <xen-tools/common-macros.h>
+#include <xen/virtdev.h>
 
 static unsigned int nr_failures;
 #define fail(fmt, ...)                          \
diff --git a/tools/tests/tsx/test-tsx.c b/tools/tests/tsx/test-tsx.c
index 5af04953f340febcf56da9b041338237b71617cb..5681b3c846715e913169277ee4a11ca087013fb6 100644
--- a/tools/tests/tsx/test-tsx.c
+++ b/tools/tests/tsx/test-tsx.c
@@ -29,6 +29,7 @@
 #include <xenctrl.h>
 #include <xenguest.h>
 #include <xen-tools/common-macros.h>
+#include <xen/virtdev.h>
 
 #include "xg_private.h"
 
diff --git a/xen/arch/arm/include/asm/domain.h b/xen/arch/arm/include/asm/domain.h
index f1d72c6e48dfeba347b4cd091ca33603c368b7c0..3dedf758bbd1f142debbc7c2460398e1bea822d7 100644
--- a/xen/arch/arm/include/asm/domain.h
+++ b/xen/arch/arm/include/asm/domain.h
@@ -119,6 +119,8 @@ struct arch_domain
     void *tee;
 #endif
 
+    /* Hardware emulation flags. */
+    uint32_t emulation_flags;
 }  __cacheline_aligned;
 
 struct arch_vcpu
diff --git a/xen/arch/ppc/include/asm/domain.h b/xen/arch/ppc/include/asm/domain.h
index 3a447272c6f28586bf0d610929adbf228579e13f..8aa7b4a6ac0d0850542e94cb28e58c62c3a4b156 100644
--- a/xen/arch/ppc/include/asm/domain.h
+++ b/xen/arch/ppc/include/asm/domain.h
@@ -21,6 +21,8 @@ struct arch_vcpu {
 
 struct arch_domain {
     struct hvm_domain hvm;
+    /* Hardware emulation flags. */
+    uint32_t emulation_flags;
 };
 
 #include <xen/sched.h>
diff --git a/xen/arch/riscv/include/asm/domain.h b/xen/arch/riscv/include/asm/domain.h
index c3d965a559b6ce3661bf17166d0c51853ff295a2..b561e6f4f868e1f4a6670b11111eb8cfe84ca385 100644
--- a/xen/arch/riscv/include/asm/domain.h
+++ b/xen/arch/riscv/include/asm/domain.h
@@ -18,6 +18,8 @@ struct arch_vcpu {
 
 struct arch_domain {
     struct hvm_domain hvm;
+    /* Hardware emulation flags. */
+    uint32_t emulation_flags;
 };
 
 #include <xen/sched.h>
diff --git a/xen/arch/x86/domain.c b/xen/arch/x86/domain.c
index 78a13e6812c9120901d0a70fb3bc1bd6a8b6917d..9669886ac95cbee27c9eb72b16386705b470e7b1 100644
--- a/xen/arch/x86/domain.c
+++ b/xen/arch/x86/domain.c
@@ -753,9 +753,7 @@ static bool emulation_flags_ok(const struct domain *d, uint32_t emflags)
              emflags != (X86_EMU_VPCI | X86_EMU_LAPIC | X86_EMU_IOAPIC) )
             return false;
         if ( !is_hardware_domain(d) &&
-             /* HVM PIRQ feature is user-selectable. */
-             (emflags & ~X86_EMU_USE_PIRQ) !=
-             (X86_EMU_ALL & ~(X86_EMU_VPCI | X86_EMU_USE_PIRQ)) &&
+             xen_emflags_allowable(emflags) != XEN_X86_EMU_BASELINE &&
              emflags != X86_EMU_LAPIC )
             return false;
     }
@@ -818,9 +816,12 @@ int arch_domain_create(struct domain *d,
 
     if ( !emulation_flags_ok(d, emflags) )
     {
-        printk(XENLOG_G_ERR "d%d: Xen does not allow %s domain creation "
+        printk(XENLOG_G_ERR "%pd: Xen does not allow %s %sdomain creation "
                "with the current selection of emulators: %#x\n",
-               d->domain_id, is_hvm_domain(d) ? "HVM" : "PV", emflags);
+               d,
+               is_hvm_domain(d) ? "HVM" : "PV",
+               is_hardware_domain(d) ? "(hardware) " : "",
+               emflags);
         return -EOPNOTSUPP;
     }
     d->arch.emulation_flags = emflags;
diff --git a/xen/arch/x86/include/asm/domain.h b/xen/arch/x86/include/asm/domain.h
index b79d6badd71c4d96279555df62fad75fe817a2b6..2532616bca015d0aad9abc35e14948937ab39b8f 100644
--- a/xen/arch/x86/include/asm/domain.h
+++ b/xen/arch/x86/include/asm/domain.h
@@ -9,6 +9,7 @@
 #include <asm/mce.h>
 #include <asm/vpmu.h>
 #include <asm/x86_emulate.h>
+#include <public/virtdev.h>
 #include <public/vcpu.h>
 #include <public/hvm/hvm_info_table.h>
 
@@ -456,7 +457,7 @@ struct arch_domain
     /* Don't unconditionally inject #GP for unhandled MSRs. */
     bool msr_relaxed;
 
-    /* Emulated devices enabled bitmap. */
+    /* Hardware emulation flags. */
     uint32_t emulation_flags;
 } __cacheline_aligned;
 
diff --git a/xen/common/keyhandler.c b/xen/common/keyhandler.c
index 6ea54838d434f9788e309c79119f1dab92fba6e3..7c331bc17bf279d4dd95ec5bbb540a70657cc1d1 100644
--- a/xen/common/keyhandler.c
+++ b/xen/common/keyhandler.c
@@ -302,6 +302,7 @@ static void cf_check dump_domains(unsigned char key)
             if ( test_bit(i, &d->watchdog_inuse_map) )
                 printk("    watchdog %d expires in %d seconds\n",
                        i, (u32)((d->watchdog_timer[i].expires - NOW()) >> 30));
+        printk("    emulation_flags %#x\n", d->arch.emulation_flags);
 
         arch_dump_domain_info(d);
 
diff --git a/xen/include/Makefile b/xen/include/Makefile
index 058b0a566b8b97305554add529ede6ba9ac53a7e..a7820e0e99763fbad36c52ba4f95290798e34893 100644
--- a/xen/include/Makefile
+++ b/xen/include/Makefile
@@ -15,6 +15,7 @@ headers-y := \
     compat/sched.h \
     compat/vcpu.h \
     compat/version.h \
+    compat/virtdev.h \
     compat/xen.h \
     compat/xlat.h
 headers-$(CONFIG_X86)     += compat/arch-x86/pmu.h
diff --git a/xen/include/public/arch-x86/xen.h b/xen/include/public/arch-x86/xen.h
index fc2487986642a7694578ab9d2f5f16d09761bff8..fdf05875f26e63d7bcce34a1ad4e931ce22dbdc5 100644
--- a/xen/include/public/arch-x86/xen.h
+++ b/xen/include/public/arch-x86/xen.h
@@ -261,35 +261,7 @@ typedef struct arch_shared_info arch_shared_info_t;
  * XEN_DOMCTL_INTERFACE_VERSION.
  */
 struct xen_arch_domainconfig {
-#define _XEN_X86_EMU_LAPIC          0
-#define XEN_X86_EMU_LAPIC           (1U<<_XEN_X86_EMU_LAPIC)
-#define _XEN_X86_EMU_HPET           1
-#define XEN_X86_EMU_HPET            (1U<<_XEN_X86_EMU_HPET)
-#define _XEN_X86_EMU_PM             2
-#define XEN_X86_EMU_PM              (1U<<_XEN_X86_EMU_PM)
-#define _XEN_X86_EMU_RTC            3
-#define XEN_X86_EMU_RTC             (1U<<_XEN_X86_EMU_RTC)
-#define _XEN_X86_EMU_IOAPIC         4
-#define XEN_X86_EMU_IOAPIC          (1U<<_XEN_X86_EMU_IOAPIC)
-#define _XEN_X86_EMU_PIC            5
-#define XEN_X86_EMU_PIC             (1U<<_XEN_X86_EMU_PIC)
-#define _XEN_X86_EMU_VGA            6
-#define XEN_X86_EMU_VGA             (1U<<_XEN_X86_EMU_VGA)
-#define _XEN_X86_EMU_IOMMU          7
-#define XEN_X86_EMU_IOMMU           (1U<<_XEN_X86_EMU_IOMMU)
-#define _XEN_X86_EMU_PIT            8
-#define XEN_X86_EMU_PIT             (1U<<_XEN_X86_EMU_PIT)
-#define _XEN_X86_EMU_USE_PIRQ       9
-#define XEN_X86_EMU_USE_PIRQ        (1U<<_XEN_X86_EMU_USE_PIRQ)
-#define _XEN_X86_EMU_VPCI           10
-#define XEN_X86_EMU_VPCI            (1U<<_XEN_X86_EMU_VPCI)
-
-#define XEN_X86_EMU_ALL             (XEN_X86_EMU_LAPIC | XEN_X86_EMU_HPET |  \
-                                     XEN_X86_EMU_PM | XEN_X86_EMU_RTC |      \
-                                     XEN_X86_EMU_IOAPIC | XEN_X86_EMU_PIC |  \
-                                     XEN_X86_EMU_VGA | XEN_X86_EMU_IOMMU |   \
-                                     XEN_X86_EMU_PIT | XEN_X86_EMU_USE_PIRQ |\
-                                     XEN_X86_EMU_VPCI)
+    /* Hardware emulation flags. */
     uint32_t emulation_flags;
 
 /*
diff --git a/xen/include/public/virtdev.h b/xen/include/public/virtdev.h
new file mode 100644
index 0000000000000000000000000000000000000000..27434377ecacfe069a91dea3768d14b0c14e08b4
--- /dev/null
+++ b/xen/include/public/virtdev.h
@@ -0,0 +1,61 @@
+/* SPDX-License-Identifier: GPL-2.0-only */
+#ifndef XEN__PUBLIC_VIRTDEV_H
+#define XEN__PUBLIC_VIRTDEV_H
+
+/*
+ * Domain hardware emulation flags.
+ */
+enum {
+    VIRTDEV_LAPIC      = 1U << 0,
+    VIRTDEV_HPET       = 1U << 1,
+    VIRTDEV_PM         = 1U << 2,
+    VIRTDEV_RTC        = 1U << 3,
+    VIRTDEV_IOAPIC     = 1U << 4,
+    VIRTDEV_PIC        = 1U << 5,
+    VIRTDEV_VGA        = 1U << 6,
+    VIRTDEV_IOMMU      = 1U << 7,
+    VIRTDEV_PIT        = 1U << 8,
+    VIRTDEV_PIRQ       = 1U << 9,
+    VIRTDEV_PCI        = 1U << 10,
+};
+
+#if defined(__i386__) || defined(__x86_64__)
+#define XEN_X86_EMU_LAPIC           VIRTDEV_LAPIC
+#define XEN_X86_EMU_HPET            VIRTDEV_HPET
+#define XEN_X86_EMU_PM              VIRTDEV_PM
+#define XEN_X86_EMU_RTC             VIRTDEV_RTC
+#define XEN_X86_EMU_IOAPIC          VIRTDEV_IOAPIC
+#define XEN_X86_EMU_PIC             VIRTDEV_PIC
+#define XEN_X86_EMU_VGA             VIRTDEV_VGA
+#define XEN_X86_EMU_IOMMU           VIRTDEV_IOMMU
+#define XEN_X86_EMU_PIT             VIRTDEV_PIT
+#define XEN_X86_EMU_USE_PIRQ        VIRTDEV_PIRQ
+#define XEN_X86_EMU_VPCI            VIRTDEV_PCI
+
+#define XEN_X86_EMU_ALL             (XEN_X86_EMU_LAPIC | XEN_X86_EMU_HPET |  \
+                                     XEN_X86_EMU_PM | XEN_X86_EMU_RTC |      \
+                                     XEN_X86_EMU_IOAPIC | XEN_X86_EMU_PIC |  \
+                                     XEN_X86_EMU_VGA | XEN_X86_EMU_IOMMU |   \
+                                     XEN_X86_EMU_PIT | XEN_X86_EMU_USE_PIRQ |\
+                                     XEN_X86_EMU_VPCI)
+
+/* PIRQ (HVM) feature is user-selectable (libxl). */
+#define XEN_X86_EMU_OPTIONAL        (XEN_X86_EMU_VPCI | \
+                                     XEN_X86_EMU_USE_PIRQ)
+
+#define XEN_X86_EMU_BASELINE        xen_emflags_allowable(XEN_X86_EMU_ALL)
+
+#define xen_emflags_allowable(x)    ( (x) & ~XEN_X86_EMU_OPTIONAL )
+#endif /* #if defined(__i386__) || defined(__x86_64__) */
+
+#endif /* XEN__PUBLIC_VIRTDEV_H */
+
+/*
+ * Local variables:
+ * mode: C
+ * c-file-style: "BSD"
+ * c-basic-offset: 4
+ * tab-width: 4
+ * indent-tabs-mode: nil
+ * End:
+ */
diff --git a/xen/include/xen/domain.h b/xen/include/xen/domain.h
index 3de56352911347a54cce310f0211bcc213d8a08d..eec093e9e167c14a536383422d280ed5ee56f698 100644
--- a/xen/include/xen/domain.h
+++ b/xen/include/xen/domain.h
@@ -5,6 +5,7 @@
 #include <xen/numa.h>
 #include <xen/types.h>
 
+#include <public/virtdev.h>
 #include <public/xen.h>
 
 struct guest_area {

-- 
2.34.1

