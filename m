From: Denis Mukhin <dmukhin@ford.com>
Date: Tue, 26 Nov 2024 15:22:17 -0800
Subject: [PATCH 27/36] xen/console: introduce hwdom_crashconsole=
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241126-vuart-ns8250-v1-v1-27-87b9a8375b7a@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732663312; l=3869;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=JESGJHjMxTvWh9SGyt0+xymQaxEqPkPKVM3b9HUELmI=;
 b=mY7Ag7UTh6FVmqmRN1Vz6+VT0ef9bxlfj+zIyWvTuiQ7Kzug6VSn9jEO79q8KDBzcMJb0BbLg
 SBhaZjR2X43Bt0VtujV+uNAm8/kuyShsWwnARo7ewwDgMfGgasQJAyr
X-Developer-Key: i=dmukhin@ford.com; a=ed25519;
 pk=SsDZ9p39s0fqcpUKQuqKqrbn0rq6EtEAClvpOpzx6+U=
X-Endpoint-Received: by B4 Relay for dmukhin@ford.com/20241125 with auth_id=287
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The new command line switch `hwdom_crashconsole=BOOL` allows to switch serial
console input focus to xen for machine state inspection using keyhandler
mechanism after the hardware domain crashes.

The new command line switch is aliased via `dom0=...,crashconsole` knob.

Such functionality can be useful while debugging dom0 bringup.

Signed-off-by: Denis Mukhin <dmukhin@ford.com>
---
 docs/misc/xen-command-line.pandoc |  5 +++++
 xen/arch/x86/dom0_build.c         |  2 ++
 xen/arch/x86/include/asm/setup.h  |  1 +
 xen/common/domain.c               | 14 +++++++++++++-
 4 files changed, 21 insertions(+), 1 deletion(-)

diff --git a/docs/misc/xen-command-line.pandoc b/docs/misc/xen-command-line.pandoc
index 293dbc1a957ba6e668fd4d55d58e84f643822126..fb77d7dca1ea517f79d6713aa6909422f31e7724 100644
--- a/docs/misc/xen-command-line.pandoc
+++ b/docs/misc/xen-command-line.pandoc
@@ -806,6 +806,7 @@ Specify the bit width of the DMA heap.
 
 ### dom0
     = List of [ pv | pvh, shadow=<bool>, verbose=<bool>,
+                crashconsole=<bool>,
                 cpuid-faulting=<bool>, msr-relaxed=<bool> ] (x86)
 
     = List of [ sve=<integer> ] (Arm64)
@@ -839,6 +840,10 @@ Controls for how dom0 is constructed on x86 systems.
     information during the dom0 build.  It defaults to the compile time choice
     of `CONFIG_VERBOSE_DEBUG`.
 
+*   The `crashconsole` boolean instructs Xen to drop into emergency console
+    in case of dom0 crash. May be useful for dom0 bringup on a custom
+    hardware.
+
 *   The `cpuid-faulting` boolean is an interim option, is only applicable to
     PV dom0, and defaults to true.
 
diff --git a/xen/arch/x86/dom0_build.c b/xen/arch/x86/dom0_build.c
index e8f5bf5447bc47a6daa3d95787106a4c11e80d31..706aeec0ecbb565a415edbfb33ca2fd72967c560 100644
--- a/xen/arch/x86/dom0_build.c
+++ b/xen/arch/x86/dom0_build.c
@@ -286,6 +286,8 @@ int __init parse_arch_dom0_param(const char *s, const char *e)
         opt_dom0_cpuid_faulting = val;
     else if ( (val = parse_boolean("msr-relaxed", s, e)) >= 0 )
         opt_dom0_msr_relaxed = val;
+    else if ( (val = parse_boolean("crashconsole", s, e)) >= 0 )
+        opt_hwdom_crashconsole = !!val;
     else
         return -EINVAL;
 
diff --git a/xen/arch/x86/include/asm/setup.h b/xen/arch/x86/include/asm/setup.h
index 296348655b9d146c73acc305cc9edd5fd46f7d47..5edae2d15cc0a1ad74eb1637a48dd3a74e0c37ee 100644
--- a/xen/arch/x86/include/asm/setup.h
+++ b/xen/arch/x86/include/asm/setup.h
@@ -68,5 +68,6 @@ extern bool opt_dom0_pvh;
 extern bool opt_dom0_verbose;
 extern bool opt_dom0_cpuid_faulting;
 extern bool opt_dom0_msr_relaxed;
+extern bool opt_hwdom_crashconsole;
 
 #endif
diff --git a/xen/common/domain.c b/xen/common/domain.c
index 56f5d3b2031c52d567bfcf839740600320d952e9..68112ca6de09d58f3df10b8545fec55583d2bf74 100644
--- a/xen/common/domain.c
+++ b/xen/common/domain.c
@@ -56,6 +56,13 @@ unsigned int xen_processor_pmbits = XEN_PROCESSOR_PM_PX;
 bool opt_dom0_vcpus_pin;
 boolean_param("dom0_vcpus_pin", opt_dom0_vcpus_pin);
 
+/*
+ * Hardware domain crash handler: if true, do not halt machine, but switch to
+ * Xen console for debugging.
+ */
+bool opt_hwdom_crashconsole;
+boolean_param("hwdom_crashconsole", opt_hwdom_crashconsole);
+
 /* Protect updates/reads (resp.) of domain_list and domain_hash. */
 DEFINE_SPINLOCK(domlist_update_lock);
 DEFINE_RCU_READ_LOCK(domlist_read_lock);
@@ -1144,7 +1151,12 @@ int domain_shutdown(struct domain *d, u8 reason)
     reason = d->shutdown_code;
 
     if ( is_hardware_domain(d) )
-        hwdom_shutdown(reason);
+    {
+        if ( opt_hwdom_crashconsole )
+            console_set_owner(DOMID_XEN);
+        else
+            hwdom_shutdown(reason);
+    }
 
     if ( d->is_shutting_down )
     {

-- 
2.34.1

