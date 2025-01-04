From: Denis Mukhin <dmukhin@ford.com>
Date: Fri, 03 Jan 2025 17:58:19 -0800
Subject: [PATCH v3 13/24] xen/console: introduce hwdom_crashconsole=
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250103-vuart-ns8250-v3-v1-13-c5d36b31d66c@ford.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735955892; l=4542;
 i=dmukhin@ford.com; s=20241125; h=from:subject:message-id;
 bh=o12/OmA+RZtrOIYv5yea9Nc3i1rLnoZ0MtCOdADxSJE=;
 b=laDqlcBt7fXWKuNapo74tNzV0R3dtuySyU/fhDACTJj1HAdDb8hOd7TOnz2417TA0/aAgePzE
 m0fCgZPTNWVByduJodUh8Sxjnn3YP8OAQ5WwPrZV3Nq4hI/A+AC6YeP
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
 docs/misc/xen-command-line.pandoc | 14 ++++++++++++++
 xen/arch/x86/dom0_build.c         |  2 ++
 xen/common/domain.c               | 14 +++++++++++++-
 xen/include/xen/domain.h          |  1 +
 4 files changed, 30 insertions(+), 1 deletion(-)

diff --git a/docs/misc/xen-command-line.pandoc b/docs/misc/xen-command-line.pandoc
index 08b0053f9ced7a5c44318a3414f927c31fe4c876..1a5ee3c91c5cc8bf653e5054211035b5d1bd560f 100644
--- a/docs/misc/xen-command-line.pandoc
+++ b/docs/misc/xen-command-line.pandoc
@@ -822,6 +822,7 @@ Specify the bit width of the DMA heap.
 
 ### dom0
     = List of [ pv | pvh, shadow=<bool>, verbose=<bool>,
+                crashconsole=<bool>,
                 cpuid-faulting=<bool>, msr-relaxed=<bool> ] (x86)
 
     = List of [ sve=<integer> ] (Arm64)
@@ -855,6 +856,10 @@ Controls for how dom0 is constructed on x86 systems.
     information during the dom0 build.  It defaults to the compile time choice
     of `CONFIG_VERBOSE_DEBUG`.
 
+*   The `crashconsole` boolean instructs Xen to switch input console focus to
+    the hypervisor when dom0 shuts down and avoid performing dom0 domain
+    destruction.  Should only be used for debugging purposes.
+
 *   The `cpuid-faulting` boolean is an interim option, is only applicable to
     PV dom0, and defaults to true.
 
@@ -1491,6 +1496,15 @@ Specify whether guests are to be given access to physical port 80
 (often used for debugging purposes), to override the DMI based
 detection of systems known to misbehave upon accesses to that port.
 
+### hwdom_crashconsole
+> `= <boolean>`
+
+> Default: `false`
+
+The `hwdom_crashconsole` boolean instructs Xen to switch input console focus to
+the hypervisor when dom0 shuts down and avoid performing dom0 domain
+destruction.  Should only be used for debugging purposes.
+
 ### idle_latency_factor (x86)
 > `= <integer>`
 
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
 
diff --git a/xen/common/domain.c b/xen/common/domain.c
index 61e0890052eb0c7ff7c19cc2fbdbfb9af512a545..1063463789224818017f7c893312e819acc0714c 100644
--- a/xen/common/domain.c
+++ b/xen/common/domain.c
@@ -59,6 +59,13 @@ unsigned int xen_processor_pmbits = XEN_PROCESSOR_PM_PX;
 bool opt_dom0_vcpus_pin;
 boolean_param("dom0_vcpus_pin", opt_dom0_vcpus_pin);
 
+/*
+ * Hardware domain crash handler: if true, do not halt machine, but switch to
+ * Xen console for debugging.
+ */
+bool __ro_after_init opt_hwdom_crashconsole;
+boolean_param("hwdom_crashconsole", opt_hwdom_crashconsole);
+
 /* Protect updates/reads (resp.) of domain_list and domain_hash. */
 DEFINE_SPINLOCK(domlist_update_lock);
 DEFINE_RCU_READ_LOCK(domlist_read_lock);
@@ -1162,7 +1169,12 @@ int domain_shutdown(struct domain *d, u8 reason)
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
diff --git a/xen/include/xen/domain.h b/xen/include/xen/domain.h
index eef36bafd3574c97d2f1f5c1fc93b4b7b46b78ba..1edebdce3754861244f23f6b884dd07d63958881 100644
--- a/xen/include/xen/domain.h
+++ b/xen/include/xen/domain.h
@@ -154,6 +154,7 @@ extern unsigned int xen_processor_pmbits;
 extern bool opt_dom0_vcpus_pin;
 extern cpumask_t dom0_cpus;
 extern bool dom0_affinity_relaxed;
+extern bool opt_hwdom_crashconsole;
 
 /* vnuma topology per domain. */
 struct vnuma_info {

-- 
2.34.1

