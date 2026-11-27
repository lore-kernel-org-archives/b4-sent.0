From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:46 +0200
Subject: [PATCH RFC 09/10] coresight: cpu-debug: Remove the panic notifier
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-9-69d3ad1e0fc8@iav.lv>
References: <20261127-b4-coresight-cpu-debug-lockup-v1-0-69d3ad1e0fc8@iav.lv>
In-Reply-To: <20261127-b4-coresight-cpu-debug-lockup-v1-0-69d3ad1e0fc8@iav.lv>
To: Suzuki K Poulose <suzuki.poulose@arm.com>, 
 Mike Leach <mike.leach@arm.com>, James Clark <james.clark@linaro.org>, 
 Leo Yan <leo.yan@arm.com>, Andrew Morton <akpm@linux-foundation.org>, 
 Alexander Shishkin <alexander.shishkin@linux.intel.com>
Cc: coresight@lists.linaro.org, linux-arm-kernel@lists.infradead.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Douglas Anderson <dianders@chromium.org>, Petr Mladek <pmladek@suse.com>, 
 Feng Tang <feng.tang@linux.alibaba.com>, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=10556; i=iav@iav.lv;
 h=from:subject:message-id; bh=69Z8TmRBXxQ+yhXG6sdog2ItaDNEiEq/4FhCjNot2/E=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqsUhskr6LisTfE7LW9nqzH7lsE3+T0tN5P1zbIH9a
 74dez6ho5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAEyEXZCRof1t+Lwb7vcudflM
 /ushvlb3+e8lvNkx79su38uIKw1kPcrIsEo8bkd07Y5J4uJyF/dsOzLj3PcPs/Zud0tw/CG+taP
 YlBcA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CPUs that ignore a backtrace request are dumped from the backtrace
stall notifier. When the hard lockup detector finds another CPU locked
up, it sends such a request to that CPU before it panics, and the panic
notifier then dumps the same CPU once more.

The panic notifier also reads every possible CPU through the EDPRCR
power request. On the platforms where that is not safe it raises an
SError in the middle of the panic.

Remove it. This changes what a panic prints: the dump no longer covers
every CPU and no longer comes with every panic. "panic_sys_info=all_bt"
brings back the dump of the CPUs that do not respond, as the kernel
then requests a backtrace from all CPUs before it stops them.

Without SMP there is no backtrace request to ignore and the driver
would do nothing, so make it depend on SMP.

The example output in the documentation came from the panic notifier;
replace it with a dump of a CPU locked up by LKDTM HARDLOCKUP on
RK3399.

Suggested-by: Leo Yan <leo.yan@arm.com>
Link: https://lore.kernel.org/r/20261118104917.GW9176@e132581.arm.com
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 .../trace/coresight/coresight-cpu-debug.rst        | 47 +++++++++---------
 drivers/hwtracing/coresight/Kconfig                |  8 ++--
 drivers/hwtracing/coresight/coresight-cpu-debug.c  | 55 +---------------------
 3 files changed, 29 insertions(+), 81 deletions(-)

diff --git a/Documentation/trace/coresight/coresight-cpu-debug.rst b/Documentation/trace/coresight/coresight-cpu-debug.rst
index e25177b3b857..d841c2fb610e 100644
--- a/Documentation/trace/coresight/coresight-cpu-debug.rst
+++ b/Documentation/trace/coresight/coresight-cpu-debug.rst
@@ -20,9 +20,8 @@ The debug module provides sample-based profiling extension, which can be used
 to sample CPU program counter, secure state and exception level, etc; usually
 every CPU has one dedicated debug module to be connected. Based on self-hosted
 debug mechanism, Linux kernel can access these related registers from mmio
-region when the kernel panic happens. The callback notifier for kernel panic
-will dump related registers for every CPU; finally this is good for assistant
-analysis for panic.
+region when a CPU does not respond to a backtrace request. The driver then
+dumps the related registers of that CPU, which shows where it is stuck.
 
 
 Implementation
@@ -34,20 +33,23 @@ Implementation
   this feature is not supported then registration will fail.
 
 - At the time this documentation was written, the debug driver mainly relies on
-  information gathered by the kernel panic callback notifier from three
-  sampling registers: EDPCSR, EDVIDSR and EDCIDSR: from EDPCSR we can get
-  program counter; EDVIDSR has information for secure state, exception level,
-  bit width, etc; EDCIDSR is context ID value which contains the sampled value
-  of CONTEXTIDR_EL1.
+  information gathered from three sampling registers: EDPCSR, EDVIDSR and
+  EDCIDSR: from EDPCSR we can get program counter; EDVIDSR has information for
+  secure state, exception level, bit width, etc; EDCIDSR is context ID value
+  which contains the sampled value of CONTEXTIDR_EL1.
 
-- The driver also dumps the CPUs that do not respond to a backtrace request.
+- The driver dumps the CPUs that do not respond to a backtrace request.
   A CPU that is locked up with interrupts masked does not respond unless the
   request is delivered as an NMI. A CPU that the scheduler does not report as
   idle is sampled without the EDPRCR power request, and only if EDPRSR shows
   it accessible (powered, out of reset, OS Double Lock clear). An idle CPU is
-  sampled the way the panic notifier does it, with the power request, unless
-  the "skip_idle" parameter is set. Idle is what idle_cpu() reports: the CPU
-  runs its idle task and has no task waiting to run.
+  sampled with the power request, unless the "skip_idle" parameter is set.
+  Idle is what idle_cpu() reports: the CPU runs its idle task and has no task
+  waiting to run.
+
+- A panic by itself does not produce the dump. With "panic_sys_info=all_bt"
+  the kernel requests a backtrace from all CPUs before it stops them, and the
+  CPUs that do not respond are dumped.
 
 - The driver supports a CPU running in either AArch64 or AArch32 mode. The
   registers naming convention is a bit different between them, AArch64 uses
@@ -164,7 +166,7 @@ on a system that keeps running, for example on SysRq-l or on an RCU stall
 warning. If the idle states are to stay enabled there, set
 "coresight_cpu_debug.skip_idle=1" in the kernel command line or write '1' into
 /sys/module/coresight_cpu_debug/parameters/skip_idle: the driver then does not
-sample the idle CPUs. The dump on panic still reads every CPU.
+sample the idle CPUs.
 
 If you want to limit idle states at boot time, you can use "nohlt" or
 "cpuidle.off=1" in the kernel command line.
@@ -194,16 +196,13 @@ Documentation/admin-guide/pm/cpuidle.rst)::
 Output format
 -------------
 
-Here is an example of the debugging output format::
+Here is an example of the debugging output format, for CPU1 locked up with
+interrupts masked::
 
+  After 10 seconds, these CPUS still haven't responded to the NMI: 1
   ARM external debug module:
-  coresight-cpu-debug 850000.debug: CPU[0]:
-  coresight-cpu-debug 850000.debug:  EDPRSR:  00000001 (Power:On Reset:No DLK:Unlock)
-  coresight-cpu-debug 850000.debug:  EDPCSR:  handle_IPI+0x174/0x1d8
-  coresight-cpu-debug 850000.debug:  EDCIDSR: 00000000
-  coresight-cpu-debug 850000.debug:  EDVIDSR: 90000000 (State:Non-secure Mode:EL1/0 Width:64bits VMID:0)
-  coresight-cpu-debug 852000.debug: CPU[1]:
-  coresight-cpu-debug 852000.debug:  EDPRSR:  00000001 (Power:On Reset:No DLK:Unlock)
-  coresight-cpu-debug 852000.debug:  EDPCSR:  debug_notifier_call+0x23c/0x358
-  coresight-cpu-debug 852000.debug:  EDCIDSR: 00000000
-  coresight-cpu-debug 852000.debug:  EDVIDSR: 90000000 (State:Non-secure Mode:EL1/0 Width:64bits VMID:0)
+  coresight-cpu-debug fe432000.debug: CPU[1]:
+  coresight-cpu-debug fe432000.debug:  EDPRSR:  0000000b (Power:On Reset:No DLK:Unlock)
+  coresight-cpu-debug fe432000.debug:  EDPCSR:  lkdtm_HARDLOCKUP+0x14/0x38 [lkdtm]
+  coresight-cpu-debug fe432000.debug:  EDCIDSR: 00000000
+  coresight-cpu-debug fe432000.debug:  EDVIDSR: 90000000 (State:Non-secure Mode:EL1/0 Width:64bits VMID:0)
diff --git a/drivers/hwtracing/coresight/Kconfig b/drivers/hwtracing/coresight/Kconfig
index 6a4239ebb582..3bacb33af615 100644
--- a/drivers/hwtracing/coresight/Kconfig
+++ b/drivers/hwtracing/coresight/Kconfig
@@ -148,11 +148,13 @@ config CORESIGHT_CTCU
 config CORESIGHT_CPU_DEBUG
 	tristate "CoreSight CPU Debug driver"
 	depends on ARM || ARM64
+	depends on SMP
 	depends on DEBUG_FS
 	help
 	  This driver provides support for coresight debugging module. This
-	  is primarily used to dump sample-based profiling registers when
-	  system triggers panic, the driver will parse context registers so
+	  is primarily used to dump sample-based profiling registers when a
+	  CPU does not respond to a backtrace request, as when it is locked
+	  up with interrupts masked; the driver will parse context registers so
 	  can quickly get to know program counter (PC), secure state,
 	  exception level, etc. Before use debugging functionality, platform
 	  needs to ensure the clock domain and power domain are enabled
@@ -166,7 +168,7 @@ config CORESIGHT_CPU_DEBUG_DEFAULT_ON
 	bool "Enable CoreSight CPU Debug by default"
 	depends on CORESIGHT_CPU_DEBUG
 	help
-	  Say Y here to enable the CoreSight Debug panic-debug by default. This
+	  Say Y here to enable the CoreSight CPU Debug dump by default. This
 	  can also be enabled via debugfs, but this ensures the debug feature
 	  is enabled as early as possible.
 
diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index ffbdad1204a4..5c5a1f6a6e33 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -20,7 +20,6 @@
 #include <linux/moduleparam.h>
 #include <linux/nmi.h>
 #include <linux/notifier.h>
-#include <linux/panic_notifier.h>
 #include <linux/platform_device.h>
 #include <linux/pm_qos.h>
 #include <linux/rcupdate.h>
@@ -420,44 +419,6 @@ static void debug_init_arch_data(void *info)
 	}
 }
 
-/*
- * Dump out information on panic.
- */
-static int debug_notifier_call(struct notifier_block *self,
-			       unsigned long v, void *p)
-{
-	int cpu;
-	struct debug_drvdata *drvdata;
-
-	/* Bail out if we can't acquire the mutex or the functionality is off */
-	if (!mutex_trylock(&debug_lock))
-		return NOTIFY_DONE;
-
-	if (!debug_enable)
-		goto skip_dump;
-
-	pr_emerg("ARM external debug module:\n");
-
-	for_each_possible_cpu(cpu) {
-		drvdata = debug_drvdata_locked(cpu);
-		if (!drvdata)
-			continue;
-
-		dev_emerg(drvdata->dev, "CPU[%d]:\n", drvdata->cpu);
-
-		debug_read_regs(drvdata);
-		debug_dump_regs(drvdata);
-	}
-
-skip_dump:
-	mutex_unlock(&debug_lock);
-	return NOTIFY_DONE;
-}
-
-static struct notifier_block debug_notifier = {
-	.notifier_call = debug_notifier_call,
-};
-
 /*
  * Dump the CPUs that did not respond to a backtrace request. This can run
  * in NMI context.
@@ -633,27 +594,15 @@ static int debug_func_init(void)
 	debugfs_create_file("enable", 0644, debug_debugfs_dir, NULL,
 			    &debug_func_knob_fops);
 
-	/* Register function to be called for panic */
-	ret = atomic_notifier_chain_register(&panic_notifier_list,
-					     &debug_notifier);
-	if (ret) {
-		pr_err("%s: unable to register notifier: %d\n",
-		       __func__, ret);
-		goto err;
-	}
-
 	ret = nmi_backtrace_stall_notifier_register(&debug_stall_notifier);
 	if (ret) {
 		pr_err("%s: unable to register stall notifier: %d\n",
 		       __func__, ret);
-		goto err_stall;
+		goto err;
 	}
 
 	return 0;
 
-err_stall:
-	atomic_notifier_chain_unregister(&panic_notifier_list,
-					 &debug_notifier);
 err:
 	debugfs_remove_recursive(debug_debugfs_dir);
 	return ret;
@@ -662,8 +611,6 @@ static int debug_func_init(void)
 static void debug_func_exit(void)
 {
 	nmi_backtrace_stall_notifier_unregister(&debug_stall_notifier);
-	atomic_notifier_chain_unregister(&panic_notifier_list,
-					 &debug_notifier);
 	debugfs_remove_recursive(debug_debugfs_dir);
 }
 

-- 
2.43.0

