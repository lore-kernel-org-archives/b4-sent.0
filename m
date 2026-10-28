From: Jez Ng <jez@sfcompute.com>
Date: Wed, 28 Oct 2026 00:14:45 +0000
Subject: [PATCH 1/2] thermal: intel: hfi: Disable HFI on shutdown and kexec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-hfi-kexec-v1-1-956234dcfb2b@sfcompute.com>
References: <20261028-hfi-kexec-v1-0-956234dcfb2b@sfcompute.com>
In-Reply-To: <20261028-hfi-kexec-v1-0-956234dcfb2b@sfcompute.com>
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Ricardo Neri <ricardo.neri-calderon@linux.intel.com>, 
 Len Brown <len.brown@intel.com>, 
 Stanislaw Gruszka <stanislaw.gruszka@linux.intel.com>
Cc: "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Andrew James <ajames@sfcompute.com>, 
 John Ranzie <jranzie@sfcompute.com>, Jez Ng <jez@sfcompute.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793146828; l=5162;
 i=jez@sfcompute.com; s=20261027; h=from:subject:message-id;
 bh=dv3+YjTvTdGwFlEMyHW/rKlDFKBOFHdfyscbY7G2KH4=;
 b=17IUNS718UtNc8J4GnqlzzXMBBYEwGHFZrL8mq+4fhWeNKujtWmPphrbKZOcpaKbolPjE16wc
 3NPCe3VNhKnADAO4xZ0EycMqO8XWAZXvfu1p59i6sg49FnvQxAU7DMC
X-Developer-Key: i=jez@sfcompute.com; a=ed25519;
 pk=e8QxvBomwv96udVoo4EZvgPDtnl1YbPysb3vNdKi8JA=
X-Endpoint-Received: by B4 Relay for jez@sfcompute.com/20261027 with auth_id=1337
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HFI is enabled per package by writing the physical address of a table to
MSR_IA32_HW_FEEDBACK_PTR and setting the enable bit in
MSR_IA32_HW_FEEDBACK_CONFIG. From then on, hardware writes performance and
energy efficiency updates to that table on its own.

Nothing disables HFI when the kernel shuts down. After a kexec, hardware
keeps writing to the old kernel's table, which is now ordinary free memory
in the new kernel. The new kernel does not reprogram HFI unless a thermal
netlink client subscribes to events, so the writes continue indefinitely.

This was observed on dual-socket Sapphire Rapids systems (Xeon Platinum
8462Y+) that boot a Debian 6.1 kernel and kexec into a 7.0 kernel. Both
packages kept writing HFI updates (a timestamp, a changed flag and one
row per CPU) into the old kernel's table pages. When the inode hash table
landed on one of those pages, the new kernel oopsed in find_inode_fast().
Disabling HFI before kexec made the writes stop.

Add a syscore shutdown callback that disables HFI on every package with an
online CPU. syscore_shutdown() runs on reboot, power off and kexec, after
CPU hotplug is disabled and while the other CPUs are still online, so each
package can be reached with smp_call_function_single().

Do not enable HFI again once the callback has run. On kexec, user space
keeps running on the other CPUs until machine_shutdown() stops them, and
kernel_kexec() enables CPU hotplug again after syscore_shutdown(). A new
thermal netlink client, or the first CPU of a package coming online, would
otherwise enable HFI after it was disabled.

Skip packages where HFI is already disabled. hfi_disable() waits up to
2 ms for hardware to set HFI_UPDATED, which a package that is not
running HFI may never do.

Fixes: ab09b0744a99 ("thermal: intel: hfi: Enable notification interrupt")
Cc: stable@vger.kernel.org
Reviewed-by: Andrew James <ajames@sfcompute.com>
Reviewed-by: John Ranzie <jranzie@sfcompute.com>
Signed-off-by: Jez Ng <jez@sfcompute.com>
---
 drivers/thermal/intel/intel_hfi.c | 50 +++++++++++++++++++++++++++++++++++++--
 1 file changed, 48 insertions(+), 2 deletions(-)

diff --git a/drivers/thermal/intel/intel_hfi.c b/drivers/thermal/intel/intel_hfi.c
index 3273b8fe3d4d..8ff094eccbaf 100644
--- a/drivers/thermal/intel/intel_hfi.c
+++ b/drivers/thermal/intel/intel_hfi.c
@@ -161,6 +161,7 @@ static DEFINE_PER_CPU(struct hfi_cpu_info, hfi_cpu_info) = { .index = -1 };
 
 static int max_hfi_instances;
 static int hfi_clients_nr;
+static bool hfi_shutdown_done;
 static struct hfi_instance *hfi_instances;
 
 static struct hfi_features hfi_features;
@@ -398,6 +399,19 @@ static void hfi_disable(void)
 	}
 }
 
+/* Caller must hold hfi_instance_lock. */
+static bool hfi_disable_if_enabled(void)
+{
+	u64 msr_val;
+
+	rdmsrq(MSR_IA32_HW_FEEDBACK_CONFIG, msr_val);
+	if (!(msr_val & HW_FEEDBACK_CONFIG_HFI_ENABLE_BIT))
+		return false;
+
+	hfi_disable();
+	return true;
+}
+
 /**
  * intel_hfi_online() - Enable HFI on @cpu
  * @cpu:	CPU in which the HFI will be enabled
@@ -483,7 +497,8 @@ void intel_hfi_online(unsigned int cpu)
 	 * Enable this HFI instance if this is its first online CPU and
 	 * there are user-space clients of thermal events.
 	 */
-	if (cpumask_weight(hfi_instance->cpus) == 1 && hfi_clients_nr > 0) {
+	if (cpumask_weight(hfi_instance->cpus) == 1 && hfi_clients_nr > 0 &&
+	    !hfi_shutdown_done) {
 		hfi_set_hw_table(hfi_instance);
 		hfi_enable();
 	}
@@ -593,6 +608,11 @@ static void hfi_disable_instance(void *ptr)
 	hfi_disable();
 }
 
+static void hfi_shutdown_instance(void *ptr)
+{
+	hfi_disable_if_enabled();
+}
+
 static void hfi_syscore_resume(void *data)
 {
 	/* This code runs only on the boot CPU. */
@@ -612,9 +632,35 @@ static int hfi_syscore_suspend(void *data)
 	return 0;
 }
 
+static void hfi_syscore_shutdown(void *data)
+{
+	struct hfi_instance *hfi_instance;
+	int i;
+
+	/*
+	 * Hardware keeps writing to the HFI table after a kexec, into memory
+	 * that the next kernel owns. Disable HFI in every package, and keep it
+	 * disabled: user space runs until machine_shutdown() stops the other
+	 * CPUs, and kexec enables CPU hotplug again, so a new thermal netlink
+	 * client or a CPU coming online could otherwise enable it.
+	 */
+	mutex_lock(&hfi_instance_lock);
+	hfi_shutdown_done = true;
+	for (i = 0; i < max_hfi_instances; i++) {
+		hfi_instance = &hfi_instances[i];
+		if (cpumask_empty(hfi_instance->cpus))
+			continue;
+
+		smp_call_function_single(cpumask_any(hfi_instance->cpus),
+					 hfi_shutdown_instance, hfi_instance, true);
+	}
+	mutex_unlock(&hfi_instance_lock);
+}
+
 static const struct syscore_ops hfi_pm_ops = {
 	.resume = hfi_syscore_resume,
 	.suspend = hfi_syscore_suspend,
+	.shutdown = hfi_syscore_shutdown,
 };
 
 static struct syscore hfi_pm = {
@@ -649,7 +695,7 @@ static int hfi_thermal_notify(struct notifier_block *nb, unsigned long state,
 		break;
 	}
 
-	if (!func)
+	if (!func || hfi_shutdown_done)
 		goto out;
 
 	for (i = 0; i < max_hfi_instances; i++) {

-- 
2.39.5

