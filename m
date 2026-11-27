From: Igor Velkov <iav@iav.lv>
Date: Fri, 27 Nov 2026 08:38:45 +0200
Subject: [PATCH RFC 08/10] coresight: cpu-debug: Dump CPUs that ignore a
 backtrace request
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-b4-coresight-cpu-debug-lockup-v1-8-69d3ad1e0fc8@iav.lv>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=12370; i=iav@iav.lv;
 h=from:subject:message-id; bh=k6ab9zbMYAvqluqjYld4j7mEr9YKv9hgDwRa0r/jJpQ=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDNmcqsU/P6/qXBIo1v2z/33pbtcaI1aeeibBv4cTdqU8a
 zzGYaPZUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACbCycLI0BT0KPSyWxzX1cjl
 Fy4/i3fwjhJfr7RvydWkvsm9D+u/XWFkmJ7I8jpie9S8UtH7Pv7u0Tu2LH4TwbL3afhkwW1TD2z
 04AAA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A CPU that is locked up with interrupts masked does not respond to a
backtrace request unless the request is delivered as an NMI, and the
kernel can only report that it did not respond. Its program counter can
still be sampled through the external debug interface.

Register for the backtrace stall notification and dump the CPUs it
names. A CPU that the scheduler does not see as idle is expected to be
powered: sample it without the EDPRCR power request, only if EDPRSR
shows it accessible, and clear the OS lock only if it is set. An idle
CPU goes through the same path as on panic, with the power request.

The notification also comes on a system that keeps running, for
example on SysRq-l or on an RCU stall warning, and the path with the
power request is not safe everywhere. On RK3399 a test module running
the register sequence of that path raises an SError on the reading CPU
for an idle core of either cluster: the write to EDOSLAR faults, and
COREPURQ powers a Cortex-A53 only for a moment. Add the skip_idle
parameter to leave idle CPUs alone on such platforms.

The notifier can run in NMI context and cannot take debug_lock. Make
the per-CPU pointer RCU protected; on disable and on remove, clear
debug_enable or the pointer first and wait for a grace period before
the runtime PM reference is dropped.

Suggested-by: Leo Yan <leo.yan@arm.com>
Link: https://lore.kernel.org/r/20261118104917.GW9176@e132581.arm.com
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 Documentation/admin-guide/kernel-parameters.txt    |  10 ++
 .../trace/coresight/coresight-cpu-debug.rst        |  16 +++
 drivers/hwtracing/coresight/coresight-cpu-debug.c  | 136 ++++++++++++++++++---
 3 files changed, 145 insertions(+), 17 deletions(-)

diff --git a/Documentation/admin-guide/kernel-parameters.txt b/Documentation/admin-guide/kernel-parameters.txt
index 0b3c140babd9..b1ca2ca599b2 100644
--- a/Documentation/admin-guide/kernel-parameters.txt
+++ b/Documentation/admin-guide/kernel-parameters.txt
@@ -1011,6 +1011,16 @@ Kernel parameters
 			0: default value, disable debugging
 			1: enable debugging at boot time
 
+	coresight_cpu_debug.skip_idle
+			[ARM,ARM64]
+			Format: <bool>
+			Of the CPUs that do not respond to a backtrace
+			request, do not sample the idle ones. For platforms
+			where the debug registers of an idle CPU are not
+			safe to access.
+			0: default value, sample idle CPUs
+			1: skip idle CPUs
+
 	cpcihp_generic=	[HW,PCI] Generic port I/O CompactPCI driver
 			Format:
 			<first_slot>,<last_slot>,<port>,<enum_bit>[,<debug>]
diff --git a/Documentation/trace/coresight/coresight-cpu-debug.rst b/Documentation/trace/coresight/coresight-cpu-debug.rst
index 04bfd318cb2b..e25177b3b857 100644
--- a/Documentation/trace/coresight/coresight-cpu-debug.rst
+++ b/Documentation/trace/coresight/coresight-cpu-debug.rst
@@ -40,6 +40,15 @@ Implementation
   bit width, etc; EDCIDSR is context ID value which contains the sampled value
   of CONTEXTIDR_EL1.
 
+- The driver also dumps the CPUs that do not respond to a backtrace request.
+  A CPU that is locked up with interrupts masked does not respond unless the
+  request is delivered as an NMI. A CPU that the scheduler does not report as
+  idle is sampled without the EDPRCR power request, and only if EDPRSR shows
+  it accessible (powered, out of reset, OS Double Lock clear). An idle CPU is
+  sampled the way the panic notifier does it, with the power request, unless
+  the "skip_idle" parameter is set. Idle is what idle_cpu() reports: the CPU
+  runs its idle task and has no task waiting to run.
+
 - The driver supports a CPU running in either AArch64 or AArch32 mode. The
   registers naming convention is a bit different between them, AArch64 uses
   'ED' for register prefix (ARM DDI 0487A.k, chapter H9.1) and AArch32 uses
@@ -150,6 +159,13 @@ controller cannot work well for the request from EDPRCR, then you should
 firstly constraint CPU idle states before enable CPU debugging feature; so can
 ensure the accessing to debug logic.
 
+The dump of the CPUs that do not respond to a backtrace request can also happen
+on a system that keeps running, for example on SysRq-l or on an RCU stall
+warning. If the idle states are to stay enabled there, set
+"coresight_cpu_debug.skip_idle=1" in the kernel command line or write '1' into
+/sys/module/coresight_cpu_debug/parameters/skip_idle: the driver then does not
+sample the idle CPUs. The dump on panic still reads every CPU.
+
 If you want to limit idle states at boot time, you can use "nohlt" or
 "cpuidle.off=1" in the kernel command line.
 
diff --git a/drivers/hwtracing/coresight/coresight-cpu-debug.c b/drivers/hwtracing/coresight/coresight-cpu-debug.c
index 63bc4cb8df52..ffbdad1204a4 100644
--- a/drivers/hwtracing/coresight/coresight-cpu-debug.c
+++ b/drivers/hwtracing/coresight/coresight-cpu-debug.c
@@ -18,9 +18,12 @@
 #include <linux/kernel.h>
 #include <linux/module.h>
 #include <linux/moduleparam.h>
+#include <linux/nmi.h>
+#include <linux/notifier.h>
 #include <linux/panic_notifier.h>
 #include <linux/platform_device.h>
 #include <linux/pm_qos.h>
+#include <linux/rcupdate.h>
 #include <linux/slab.h>
 #include <linux/smp.h>
 #include <linux/types.h>
@@ -51,6 +54,7 @@
 
 /* bits definition for EDPRSR */
 #define EDPRSR_DLK			BIT(6)
+#define EDPRSR_OSLK			BIT(5)
 #define EDPRSR_R			BIT(2)
 #define EDPRSR_PU			BIT(0)
 
@@ -106,7 +110,7 @@ struct debug_drvdata {
 };
 
 static DEFINE_MUTEX(debug_lock);
-static DEFINE_PER_CPU(struct debug_drvdata *, debug_drvdata);
+static DEFINE_PER_CPU(struct debug_drvdata __rcu *, debug_drvdata);
 static int debug_count;
 static struct dentry *debug_debugfs_dir;
 
@@ -114,6 +118,17 @@ static bool debug_enable = IS_ENABLED(CONFIG_CORESIGHT_CPU_DEBUG_DEFAULT_ON);
 module_param_named(enable, debug_enable, bool, 0400);
 MODULE_PARM_DESC(enable, "Control to enable coresight CPU debug functionality");
 
+static bool debug_skip_idle;
+module_param_named(skip_idle, debug_skip_idle, bool, 0600);
+MODULE_PARM_DESC(skip_idle, "Do not sample idle CPUs (for platforms where their debug registers are not safe to access)");
+
+/* The per-CPU pointers change only under debug_lock */
+static struct debug_drvdata *debug_drvdata_locked(int cpu)
+{
+	return rcu_dereference_protected(per_cpu(debug_drvdata, cpu),
+					 lockdep_is_held(&debug_lock));
+}
+
 static void debug_os_unlock(struct debug_drvdata *drvdata)
 {
 	/* Unlocks the debug registers */
@@ -255,6 +270,26 @@ static void debug_read_regs(struct debug_drvdata *drvdata)
 	CS_LOCK(drvdata->base);
 }
 
+/*
+ * Sample a CPU that is not idle and so is expected to be powered: leave
+ * EDPRCR alone and touch the core only if EDPRSR shows it accessible.
+ */
+static void debug_read_regs_running(struct debug_drvdata *drvdata)
+{
+	CS_UNLOCK(drvdata->base);
+
+	drvdata->edprsr = readl_relaxed(drvdata->base + EDPRSR);
+
+	if (debug_access_permitted(drvdata)) {
+		if (drvdata->edprsr & EDPRSR_OSLK)
+			debug_os_unlock(drvdata);
+
+		debug_read_pcsr(drvdata);
+	}
+
+	CS_LOCK(drvdata->base);
+}
+
 #ifdef CONFIG_64BIT
 static unsigned long debug_adjust_pc(struct debug_drvdata *drvdata)
 {
@@ -404,7 +439,7 @@ static int debug_notifier_call(struct notifier_block *self,
 	pr_emerg("ARM external debug module:\n");
 
 	for_each_possible_cpu(cpu) {
-		drvdata = per_cpu(debug_drvdata, cpu);
+		drvdata = debug_drvdata_locked(cpu);
 		if (!drvdata)
 			continue;
 
@@ -423,6 +458,56 @@ static struct notifier_block debug_notifier = {
 	.notifier_call = debug_notifier_call,
 };
 
+/*
+ * Dump the CPUs that did not respond to a backtrace request. This can run
+ * in NMI context.
+ */
+static int debug_stall_notifier_call(struct notifier_block *self,
+				     unsigned long v, void *p)
+{
+	const struct nmi_backtrace_stall *stall = p;
+	struct debug_drvdata *drvdata;
+	bool banner = false;
+	bool idle;
+	int cpu;
+
+	if (!READ_ONCE(debug_enable))
+		return NOTIFY_DONE;
+
+	for_each_cpu(cpu, stall->cpus) {
+		drvdata = rcu_dereference(per_cpu(debug_drvdata, cpu));
+		if (!drvdata)
+			continue;
+
+		if (!banner) {
+			pr_emerg("ARM external debug module:\n");
+			banner = true;
+		}
+
+		idle = cpumask_test_cpu(cpu, stall->idle);
+		if (idle && READ_ONCE(debug_skip_idle)) {
+			dev_emerg(drvdata->dev, "CPU[%d]: idle, not sampled\n",
+				  drvdata->cpu);
+			continue;
+		}
+
+		dev_emerg(drvdata->dev, "CPU[%d]:\n", drvdata->cpu);
+
+		if (idle)
+			debug_read_regs(drvdata);
+		else
+			debug_read_regs_running(drvdata);
+
+		debug_dump_regs(drvdata);
+	}
+
+	return NOTIFY_DONE;
+}
+
+static struct notifier_block debug_stall_notifier = {
+	.notifier_call = debug_stall_notifier_call,
+};
+
 static int debug_enable_func(void)
 {
 	struct debug_drvdata *drvdata;
@@ -436,7 +521,7 @@ static int debug_enable_func(void)
 	cpumask_clear(&mask);
 
 	for_each_possible_cpu(cpu) {
-		drvdata = per_cpu(debug_drvdata, cpu);
+		drvdata = debug_drvdata_locked(cpu);
 		if (!drvdata)
 			continue;
 
@@ -455,7 +540,7 @@ static int debug_enable_func(void)
 	 * that have been enabled before that.
 	 */
 	for_each_cpu(cpu, &mask) {
-		drvdata = per_cpu(debug_drvdata, cpu);
+		drvdata = debug_drvdata_locked(cpu);
 		pm_runtime_put_noidle(drvdata->dev);
 	}
 
@@ -473,7 +558,7 @@ static void debug_disable_func(void)
 	 * encountered.
 	 */
 	for_each_possible_cpu(cpu) {
-		drvdata = per_cpu(debug_drvdata, cpu);
+		drvdata = debug_drvdata_locked(cpu);
 		if (!drvdata)
 			continue;
 
@@ -496,18 +581,22 @@ static ssize_t debug_func_knob_write(struct file *f,
 	if (val == debug_enable)
 		goto out;
 
-	if (val)
+	if (val) {
 		ret = debug_enable_func();
-	else
-		debug_disable_func();
+		if (ret) {
+			pr_err("%s: unable to enable debug function: %d\n",
+			       __func__, ret);
+			goto err;
+		}
 
-	if (ret) {
-		pr_err("%s: unable to %s debug function: %d\n",
-		       __func__, val ? "enable" : "disable", ret);
-		goto err;
-	}
+		WRITE_ONCE(debug_enable, true);
+	} else {
+		WRITE_ONCE(debug_enable, false);
 
-	debug_enable = val;
+		/* The stall notifier must be done before the clocks stop */
+		synchronize_rcu();
+		debug_disable_func();
+	}
 out:
 	ret = count;
 err:
@@ -553,8 +642,18 @@ static int debug_func_init(void)
 		goto err;
 	}
 
+	ret = nmi_backtrace_stall_notifier_register(&debug_stall_notifier);
+	if (ret) {
+		pr_err("%s: unable to register stall notifier: %d\n",
+		       __func__, ret);
+		goto err_stall;
+	}
+
 	return 0;
 
+err_stall:
+	atomic_notifier_chain_unregister(&panic_notifier_list,
+					 &debug_notifier);
 err:
 	debugfs_remove_recursive(debug_debugfs_dir);
 	return ret;
@@ -562,6 +661,7 @@ static int debug_func_init(void)
 
 static void debug_func_exit(void)
 {
+	nmi_backtrace_stall_notifier_unregister(&debug_stall_notifier);
 	atomic_notifier_chain_unregister(&panic_notifier_list,
 					 &debug_notifier);
 	debugfs_remove_recursive(debug_debugfs_dir);
@@ -587,7 +687,7 @@ static int __debug_probe(struct device *dev, struct resource *res)
 	if (drvdata->cpu < 0)
 		return drvdata->cpu;
 
-	if (per_cpu(debug_drvdata, drvdata->cpu)) {
+	if (rcu_access_pointer(per_cpu(debug_drvdata, drvdata->cpu))) {
 		dev_err(dev, "CPU%d drvdata has already been initialized\n",
 			drvdata->cpu);
 		return -EBUSY;
@@ -625,7 +725,7 @@ static int __debug_probe(struct device *dev, struct resource *res)
 	}
 
 	mutex_lock(&debug_lock);
-	per_cpu(debug_drvdata, drvdata->cpu) = drvdata;
+	rcu_assign_pointer(per_cpu(debug_drvdata, drvdata->cpu), drvdata);
 	/* Turn off debug power domain if debugging is disabled */
 	if (!debug_enable)
 		pm_runtime_put(dev);
@@ -645,7 +745,9 @@ static void __debug_remove(struct device *dev)
 	struct debug_drvdata *drvdata = dev_get_drvdata(dev);
 
 	mutex_lock(&debug_lock);
-	per_cpu(debug_drvdata, drvdata->cpu) = NULL;
+	RCU_INIT_POINTER(per_cpu(debug_drvdata, drvdata->cpu), NULL);
+	/* The stall notifier may still be reading this CPU */
+	synchronize_rcu();
 	/* Turn off debug power domain before rmmod the module */
 	if (debug_enable)
 		pm_runtime_put(dev);

-- 
2.43.0

