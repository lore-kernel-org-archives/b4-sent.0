From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:21 -0800
Subject: [PATCH 31/36] x86/hvm: add HVM-specific Kconfig
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-31-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=5119;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=xth/C4RssnpHF5d1BFSmQSRG1c+DKNwkoUPEyi1j9F4=;
 b=SOUETyT5mODqIQZsTEddy3lHiDVCjngDNDkNnn32sXy/ZccYCCpVCwy+fm7nrRFJ0PM9nFBaT
 yp2ZeAxEGFSCAl6mI+CVbAxa55bdaoZsW+pk5yz0S5PBRuTMQtP31rr
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add separate menu for configuring HVM build-time settings.
That will help organizing HVM-specific options under a separate menu.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 xen/arch/x86/Kconfig     | 66 +++---------------------------------------------
 xen/arch/x86/hvm/Kconfig | 63 +++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 66 insertions(+), 63 deletions(-)

diff --git a/xen/arch/x86/Kconfig b/xen/arch/x86/Kconfig
index 9cdd04721afa1916c7edd8fdf7d606858c73ce88..5afee9a9f9bafa3c760b06b8601fad4cad3b7191 100644
--- a/xen/arch/x86/Kconfig
+++ b/xen/arch/x86/Kconfig
@@ -107,42 +107,9 @@ config PV_LINEAR_PT
 
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
+menu "HVM Support"
+source "arch/x86/hvm/Kconfig"
+endmenu
 
 config XEN_SHSTK
 	bool "Supervisor Shadow Stacks"
@@ -201,25 +168,6 @@ config BIGMEM
 
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
@@ -348,14 +296,6 @@ config HYPERV_GUEST
 
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
diff --git a/xen/arch/x86/hvm/Kconfig b/xen/arch/x86/hvm/Kconfig
new file mode 100644
index 0000000000000000000000000000000000000000..361bb6572e633f3cf0fc972a3b391e8341c33361
--- /dev/null
+++ b/xen/arch/x86/hvm/Kconfig
@@ -0,0 +1,63 @@
+config HVM
+	bool "HVM support"
+	depends on !PV_SHIM_EXCLUSIVE
+	default !PV_SHIM
+	select COMPAT
+	select IOREQ_SERVER
+	select MEM_ACCESS_ALWAYS_ON
+	help
+	  Interfaces to support HVM domains.  HVM domains require hardware
+	  virtualisation extensions (e.g. Intel VT-x, AMD SVM), but can boot
+	  guests which have no specific Xen knowledge.
+
+	  This option is needed if you want to run HVM or PVH domains.
+
+	  If unsure, say Y.
+
+config AMD_SVM
+	bool "AMD-V" if EXPERT
+	depends on HVM
+	default y
+	help
+	  Enables virtual machine extensions on platforms that implement the
+	  AMD Virtualization Technology (AMD-V).
+	  If your system includes a processor with AMD-V support, say Y.
+	  If in doubt, say Y.
+
+config INTEL_VMX
+	bool "Intel VT-x" if EXPERT
+	depends on HVM
+	default y
+	select ARCH_VCPU_IOREQ_COMPLETION
+	help
+	  Enables virtual machine extensions on platforms that implement the
+	  Intel Virtualization Technology (Intel VT-x).
+	  If your system includes a processor with Intel VT-x support, say Y.
+	  If in doubt, say Y.
+
+config MEM_PAGING
+	bool "Xen memory paging support (UNSUPPORTED)" if UNSUPPORTED
+	depends on HVM
+
+config MEM_SHARING
+	bool "Xen memory sharing support (UNSUPPORTED)" if UNSUPPORTED
+	depends on HVM
+
+config HVM_FEP
+	bool "HVM Forced Emulation Prefix support (UNSUPPORTED)" if UNSUPPORTED
+	default DEBUG
+	depends on HVM
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

-- 
2.34.1

