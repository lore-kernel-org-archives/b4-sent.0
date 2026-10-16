From: Ximing Zhang <xzhangjr@gmail.com>
Date: Fri, 16 Oct 2026 12:36:37 +0400
Subject: [PATCH] hwmon: (coretemp) Fix handling of isolated SMT siblings
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261016-codex-coretemp-housekeeping-v1-1-96618c5676b2@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBG4avIrBswERV6ldJFmvzVUZqEjBZBv
 Ltp3Tz4Nm8nQWYI3audMr4sHEOBvlXkRhsGKPbFZGrT6Vq3ykWPrTRjwSepMa6CGUgcBoXe6s6
 0jfWwVA4p483b//54Xpb1NcEtvyUdxwmtEmKJfwAAAA==
X-Change-ID: 20261015-codex-coretemp-housekeeping-e7a16253adea
To: Guenter Roeck <linux@roeck-us.net>, 
 Marcelo Tosatti <mtosatti@redhat.com>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ximing Zhang <xzhangjr@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792139803; l=4894;
 i=xzhangjr@gmail.com; s=20261015; h=from:subject:message-id;
 bh=a7LWa8R3yo5Y4Z1fjwmBO/zzVRbt+TmG7jDh9X78M1Q=;
 b=S9UcLvI4Te5rSCy03+KQz53dbkWX8qjV+QIiTtKF/D/LGFzFNX52mH8WNkre7ZvhkOGS3thOT
 Jm8aM/26tt8DI+XFWRbhQWLUEQ4A0IdCCvKac8bH8J4V0QB2f/WuExT
X-Developer-Key: i=xzhangjr@gmail.com; a=ed25519;
 pk=C7VXFeUl3Bjjb638l0w1D5vm9qSpdbzEYql77XoYqTQ=
X-Endpoint-Received: by B4 Relay for xzhangjr@gmail.com/20261015 with auth_id=1207
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 0f8b916bc5b5 ("hwmon: (coretemp) avoid RDMSR interrupts to
isolated CPUs") prevents create_core_data() from creating temperature
data for an isolated CPU. coretemp_cpu_online(), however, still adds
that CPU to pdata->cpumask.

When an isolated SMT thread is processed before a housekeeping sibling,
the mask makes coretemp_cpu_online() believe that the core is already
represented. The housekeeping sibling then gets no temperature
attributes. Package attributes are similarly not retried when the first
CPU processed in a die is isolated.

The mask is also used to select a replacement CPU when a sensor target
goes offline. Including isolated CPUs permits the driver to retarget a
sensor to one, causing subsequent sysfs reads to send an RDMSR IPI to an
isolated CPU.

Keep isolated CPUs out of pdata->cpumask by moving the housekeeping check
to coretemp_cpu_online(). Sensor creation is then deferred to an eligible
CPU, and hotplug replacement targets remain on housekeeping CPUs.

Tested on an Intel Core i7-10510U running 6.18.50-3-cachyos-lts, with
nohz_full=1 on CPU 1 and its housekeeping SMT sibling on CPU 5. The stock
driver omitted Core 1 after module load and retained its readable sensor
after CPU 5 was offlined. The patched driver exposed Core 1, removed it
when CPU 5 went offline, and restored it when CPU 5 returned.

Fixes: 0f8b916bc5b5 ("hwmon: (coretemp) avoid RDMSR interrupts to isolated CPUs")
Cc: stable@vger.kernel.org
Cc: Marcelo Tosatti <mtosatti@redhat.com>
Signed-off-by: Ximing Zhang <xzhangjr@gmail.com>
---
The patch was tested on an Intel Core i7-10510U running
6.18.50-3-cachyos-lts with CPU 1 isolated using nohz_full=1 and
housekeeping SMT sibling CPU 5.

The stock driver omitted Core 1 after module load and retained its
readable sensor after CPU 5 was offlined. The patched driver exposed
Core 1, removed it when CPU 5 went offline, and restored it when CPU 5
returned.
---
 drivers/hwmon/coretemp.c | 26 ++++++++++++++++----------
 1 file changed, 16 insertions(+), 10 deletions(-)

diff --git a/drivers/hwmon/coretemp.c b/drivers/hwmon/coretemp.c
index 0ab6bbff5637..ad9cadd99dc8 100644
--- a/drivers/hwmon/coretemp.c
+++ b/drivers/hwmon/coretemp.c
@@ -559,9 +559,6 @@ static int create_core_data(struct platform_device *pdev, unsigned int cpu,
 	u64 val;
 	int err;
 
-	if (!housekeeping_cpu(cpu, HK_TYPE_MISC))
-		return 0;
-
 	tdata = init_temp_data(pdata, cpu, pkg_flag);
 	if (!tdata)
 		return -ENOMEM;
@@ -681,6 +678,14 @@ static int coretemp_cpu_online(unsigned int cpu)
 	if (!cpu_has(c, X86_FEATURE_DTHERM))
 		return -ENODEV;
 
+	/*
+	 * Keep isolated CPUs out of pdata->cpumask. Besides tracking the CPUs
+	 * available to this driver, the mask is used to select the CPU on which
+	 * to read the temperature MSRs.
+	 */
+	if (!housekeeping_cpu(cpu, HK_TYPE_MISC))
+		return 0;
+
 	pdata = platform_get_drvdata(pdev);
 	if (!pdata->hwmon_dev) {
 		struct device *hwmon;
@@ -710,8 +715,8 @@ static int coretemp_cpu_online(unsigned int cpu)
 	}
 
 	/*
-	 * Check whether a thread sibling is already online. If not add the
-	 * interface for this CPU core.
+	 * Check whether a housekeeping thread sibling is already online. If
+	 * not, add the interface for this CPU core.
 	 */
 	if (!cpumask_intersects(&pdata->cpumask, topology_sibling_cpumask(cpu)))
 		coretemp_add_core(pdev, cpu, 0);
@@ -741,9 +746,9 @@ static int coretemp_cpu_offline(unsigned int cpu)
 	cpumask_clear_cpu(cpu, &pd->cpumask);
 
 	/*
-	 * If this is the last thread sibling, remove the CPU core
-	 * interface, If there is still a sibling online, transfer the
-	 * target cpu of that core interface to it.
+	 * If this is the last housekeeping thread sibling, remove the CPU core
+	 * interface. If there is still a housekeeping sibling online, transfer
+	 * the target CPU of that core interface to it.
 	 */
 	target = cpumask_any_and(&pd->cpumask, topology_sibling_cpumask(cpu));
 	if (target >= nr_cpu_ids) {
@@ -755,7 +760,8 @@ static int coretemp_cpu_offline(unsigned int cpu)
 	}
 
 	/*
-	 * If all cores in this pkg are offline, remove the interface.
+	 * If all housekeeping cores in this pkg are offline, remove the
+	 * interface.
 	 */
 	tdata = get_temp_data(pd, -1);
 	if (cpumask_empty(&pd->cpumask)) {
@@ -768,7 +774,7 @@ static int coretemp_cpu_offline(unsigned int cpu)
 
 	/*
 	 * Check whether this core is the target for the package
-	 * interface. We need to assign it to some other cpu.
+	 * interface. We need to assign it to some other housekeeping CPU.
 	 */
 	if (tdata && tdata->cpu == cpu) {
 		target = cpumask_first(&pd->cpumask);

---
base-commit: 4781ca52761e666cf18b591e6bb0478396c90320
change-id: 20261015-codex-coretemp-housekeeping-e7a16253adea

Best regards,
--  
Ximing Zhang <xzhangjr@gmail.com>

