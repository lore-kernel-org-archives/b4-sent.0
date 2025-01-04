From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:26 -0800
Subject: [PATCH v3 20/24] x86/hvm: add HVM-specific Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-20-c5d36b31d66c@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=5996;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=ZuTYcfV9biFH1je7dgKxHOvxFrMn/uUk/GeyiLFF3sY=;
 b=Ku3PacZpewsitaaL+kvBF+lfGyiiPlFVCVhhsjjgR1C+JMZqsYY5+po+CuFLwLCorvFrQSYaU
 tUP9VKEu1XVD7+pNk0pEDd3kjb5KXYHvZukXa/aIu2dExvh5lytJzrv
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add separate menu for configuring HVM build-time settings to help organizing
HVM-specific options.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/Kconfig     | 76 +-----------------------------------------------
 xen/arch/x86/hvm/Kconfig | 74 ++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 75 insertions(+), 75 deletions(-)

diff --git a/xen/arch/x86/Kconfig b/xen/arch/x86/Kconfig
index 9cdd04721afa1916c7edd8fdf7d606858c73ce88..37362c205dc664a1e809322c2cfe9f45394e30df 100644
--- a/xen/arch/x86/Kconfig
+++ b/xen/arch/x86/Kconfig
@@ -30,7 +30,6 @@ config X86
 	select HAS_SCHED_GRANULARITY
 	select HAS_UBSAN
 	select HAS_VMAP
-	select HAS_VPCI if HVM
 	select NEEDS_LIBELF
 
 config ARCH_DEFCONFIG
@@ -107,42 +106,7 @@ config PV_LINEAR_PT
 
          If unsure, say Y.
 
-config HVM
-	bool "HVM support"
-	depends on !PV_SHIM_EXCLUSIVE
-	default !PV_SHIM
-	select COMPAT
-	select IOREQ_SERVER
-	select MEM_ACCESS_ALWAYS_ON
-	help
-	  Interfaces to support HVM domains.  HVM domains require hardware
-	  virtualisation extensions (e.g. Intel VT-x, AMD SVM), but can boot
-	  guests which have no specific Xen knowledge.
-
-	  This option is needed if you want to run HVM or PVH domains.
-
-	  If unsure, say Y.
-
-config AMD_SVM
-	bool "AMD-V" if EXPERT
-	depends on HVM
-	default y
-	help
-	  Enables virtual machine extensions on platforms that implement the
-	  AMD Virtualization Technology (AMD-V).
-	  If your system includes a processor with AMD-V support, say Y.
-	  If in doubt, say Y.
-
-config INTEL_VMX
-	bool "Intel VT-x" if EXPERT
-	depends on HVM
-	default y
-	select ARCH_VCPU_IOREQ_COMPLETION
-	help
-	  Enables virtual machine extensions on platforms that implement the
-	  Intel Virtualization Technology (Intel VT-x).
-	  If your system includes a processor with Intel VT-x support, say Y.
-	  If in doubt, say Y.
+source "arch/x86/hvm/Kconfig"
 
 config XEN_SHSTK
 	bool "Supervisor Shadow Stacks"
@@ -201,25 +165,6 @@ config BIGMEM
 
 	  If unsure, say N.
 
-config HVM_FEP
-	bool "HVM Forced Emulation Prefix support (UNSUPPORTED)" if UNSUPPORTED
-	default DEBUG
-	depends on HVM
-	help
-
-	  Compiles in a feature that allows HVM guest to arbitrarily
-	  exercise the instruction emulator.
-
-	  This feature can only be enabled during boot time with
-	  appropriate hypervisor command line option. Please read
-	  hypervisor command line documentation before trying to use
-	  this feature.
-
-	  This is strictly for testing purposes, and not appropriate
-	  for use in production.
-
-	  If unsure, say N.
-
 config TBOOT
 	bool "Xen tboot support (UNSUPPORTED)"
 	depends on INTEL && UNSUPPORTED
@@ -348,14 +293,6 @@ config HYPERV_GUEST
 
 endif
 
-config MEM_PAGING
-	bool "Xen memory paging support (UNSUPPORTED)" if UNSUPPORTED
-	depends on HVM
-
-config MEM_SHARING
-	bool "Xen memory sharing support (UNSUPPORTED)" if UNSUPPORTED
-	depends on HVM
-
 config REQUIRE_NX
 	bool "Require NX (No eXecute) support"
 	help
@@ -372,17 +309,6 @@ config REQUIRE_NX
 	  was unavailable. However, if enabled, Xen will no longer boot on
 	  any CPU which is lacking NX support.
 
-config ALTP2M
-	bool "Alternate P2M support" if EXPERT
-	depends on INTEL_VMX
-	default y
-	help
-	  Alternate-p2m allows a guest to manage multiple p2m guest physical
-	  "memory views" (as opposed to a single p2m).
-	  Useful for memory introspection.
-
-	  If unsure, stay with defaults.
-
 endmenu
 
 source "common/Kconfig"
diff --git a/xen/arch/x86/hvm/Kconfig b/xen/arch/x86/hvm/Kconfig
new file mode 100644
index 0000000000000000000000000000000000000000..fdfa9f80d30347ac9c34e52f5ba829bc11916dc0
--- /dev/null
+++ b/xen/arch/x86/hvm/Kconfig
@@ -0,0 +1,74 @@
+menuconfig HVM
+	bool "HVM support"
+	depends on !PV_SHIM_EXCLUSIVE
+	default !PV_SHIM
+	select COMPAT
+	select IOREQ_SERVER
+	select MEM_ACCESS_ALWAYS_ON
+	select HAS_VPCI
+	help
+	  Interfaces to support HVM domains.  HVM domains require hardware
+	  virtualisation extensions (e.g. Intel VT-x, AMD SVM), but can boot
+	  guests which have no specific Xen knowledge.
+
+	  This option is needed if you want to run HVM or PVH domains.
+
+	  If unsure, say Y.
+
+if HVM
+
+config AMD_SVM
+	bool "AMD-V" if EXPERT
+	default y
+	help
+	  Enables virtual machine extensions on platforms that implement the
+	  AMD Virtualization Technology (AMD-V).
+	  If your system includes a processor with AMD-V support, say Y.
+	  If in doubt, say Y.
+
+config INTEL_VMX
+	bool "Intel VT-x" if EXPERT
+	default y
+	select ARCH_VCPU_IOREQ_COMPLETION
+	help
+	  Enables virtual machine extensions on platforms that implement the
+	  Intel Virtualization Technology (Intel VT-x).
+	  If your system includes a processor with Intel VT-x support, say Y.
+	  If in doubt, say Y.
+
+config ALTP2M
+	bool "Alternate P2M support" if EXPERT
+	depends on INTEL_VMX
+	default y
+	help
+	  Alternate-p2m allows a guest to manage multiple p2m guest physical
+	  "memory views" (as opposed to a single p2m).
+	  Useful for memory introspection.
+
+	  If unsure, stay with defaults.
+
+config MEM_PAGING
+	bool "Xen memory paging support (UNSUPPORTED)" if UNSUPPORTED
+
+config MEM_SHARING
+	bool "Xen memory sharing support (UNSUPPORTED)" if UNSUPPORTED
+
+config HVM_FEP
+	bool "HVM Forced Emulation Prefix support (UNSUPPORTED)" if UNSUPPORTED
+	default DEBUG
+	help
+
+	  Compiles in a feature that allows HVM guest to arbitrarily
+	  exercise the instruction emulator.
+
+	  This feature can only be enabled during boot time with
+	  appropriate hypervisor command line option. Please read
+	  hypervisor command line documentation before trying to use
+	  this feature.
+
+	  This is strictly for testing purposes, and not appropriate
+	  for use in production.
+
+	  If unsure, say N.
+
+endif

-- 
2.34.1

