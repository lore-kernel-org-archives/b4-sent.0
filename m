From: Ximing Zhang <xzhangjr@gmail.com>
Date: Tue, 20 Oct 2026 21:39:35 +0400
Subject: [PATCH] hwmon: (coretemp) Retry failed sensor creation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-coretemp-retry-sensor-creation-v1-1-7dd4851a34dc@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNywrCQAxFf6VkbWA6SH38irgY01QjOFOSqSil/
 25qV5ezuOfMYKzCBudmBuW3mJTs0O4aoEfKd0bpnSGG2LUhBqSiXPk1oo9+0ThbUSTlVP2K/bA
 /UTikSMcOXDIqD/L5By7XjW26PZnqaoVl+QEDUwdJggAAAA==
X-Change-ID: 20261020-coretemp-retry-sensor-creation-df49c07a2c86
To: Guenter Roeck <linux@roeck-us.net>
Cc: linux-hwmon@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ximing Zhang <xzhangjr@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792517975; l=5089;
 i=xzhangjr@gmail.com; s=20261015; h=from:subject:message-id;
 bh=MYBfcW2pD2/t3BIjxPJYWT5sIWj6owKm2KcGLQr+EfI=;
 b=9wpgk/F+Ccrk+9gWDW7q2I+eYgh0MGAs2XePYIoW0Wb910cbEglW8DF1IIADWTGlT+zNclZ6w
 R9hokX2V7INAo1VmvuswKKkG+4VWWiYEog/aKia79eXimyMopZyqXrK
X-Developer-Key: i=xzhangjr@gmail.com; a=ed25519;
 pk=C7VXFeUl3Bjjb638l0w1D5vm9qSpdbzEYql77XoYqTQ=
X-Endpoint-Received: by B4 Relay for xzhangjr@gmail.com/20261015 with auth_id=1207
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

coretemp_add_core() only logs create_core_data() failures, but
coretemp_cpu_online() still records the CPU in pdata->cpumask. When an
SMT sibling is processed later, the mask makes the driver skip sensor
creation. The core interface then remains absent until all siblings are
cycled or the module is reloaded.

Package sensor creation is similarly attempted only when the hwmon
device is first registered. A failure leaves the package interface
absent for the lifetime of that device.

Retry missing package and core sensors whenever an eligible CPU comes
online. Determine whether a core sensor exists from its temperature data
instead of the CPU mask, which continues to track CPUs available for MSR
reads and hotplug retargeting.

A package retry might fail after per-core data exists. Keep the core_data
array alive until the hwmon device is unregistered so failure cleanup
cannot discard live per-core pointers. Publish nr_cores only after that
array is allocated successfully, and rate-limit errors because a
permanent failure can now be retried.

Tested on an Intel Core i7-10510U running 7.2.5-1-cachyos. With
test-only fault injection, two package creation failures and one Core 0
creation failure left the unpatched driver without both interfaces. The
patched driver retried and exposed all five readable sensors. SMT sibling
hotplug and 20 module unload/load cycles also retained the expected
sensors.

Signed-off-by: Ximing Zhang <xzhangjr@gmail.com>
---
coretemp currently treats a failed package or per-core sensor creation as
permanent for the lifetime of the hwmon device. This change retries missing
sensors as eligible CPUs come online while keeping the CPU mask available for
MSR targeting and hotplug handling.

Tested on an Intel Core i7-10510U running 7.2.5-1-cachyos. Test-only fault
injection reproduced missing package and Core 0 interfaces with the current
driver. The patched driver recovered both interfaces after two package
creation failures and one core creation failure. SMT sibling hotplug and 20
module unload/load cycles also completed with the expected readable sensors.
---
 drivers/hwmon/coretemp.c | 30 ++++++++++++++----------------
 1 file changed, 14 insertions(+), 16 deletions(-)

diff --git a/drivers/hwmon/coretemp.c b/drivers/hwmon/coretemp.c
index 3836beade59f..fa3b04d0e041 100644
--- a/drivers/hwmon/coretemp.c
+++ b/drivers/hwmon/coretemp.c
@@ -489,13 +489,15 @@ static struct temp_data *
 init_temp_data(struct platform_data *pdata, unsigned int cpu, int pkg_flag)
 {
 	struct temp_data *tdata;
+	int nr_cores;
 
 	if (!pdata->core_data) {
-		pdata->nr_cores = topology_num_cores_per_package();
+		nr_cores = topology_num_cores_per_package();
 		pdata->core_data = kzalloc_objs(struct temp_data *,
-						pdata->nr_cores);
+						nr_cores);
 		if (!pdata->core_data)
 			return NULL;
+		pdata->nr_cores = nr_cores;
 	}
 
 	tdata = kzalloc_obj(struct temp_data);
@@ -533,9 +535,6 @@ static void destroy_temp_data(struct platform_data *pdata, struct temp_data *tda
 {
 	if (is_pkg_temp_data(tdata)) {
 		pdata->pkg_data = NULL;
-		kfree(pdata->core_data);
-		pdata->core_data = NULL;
-		pdata->nr_cores = 0;
 	} else {
 		pdata->core_data[tdata->index] = NULL;
 		ida_free(&pdata->ida, tdata->index);
@@ -605,7 +604,7 @@ static void
 coretemp_add_core(struct platform_device *pdev, unsigned int cpu, int pkg_flag)
 {
 	if (create_core_data(pdev, cpu, pkg_flag))
-		dev_err(&pdev->dev, "Adding Core %u failed\n", cpu);
+		dev_err_ratelimited(&pdev->dev, "Adding Core %u failed\n", cpu);
 }
 
 static void coretemp_remove_core(struct platform_data *pdata, struct temp_data *tdata)
@@ -714,20 +713,16 @@ static int coretemp_cpu_online(unsigned int cpu)
 		if (IS_ERR(hwmon))
 			return PTR_ERR(hwmon);
 		pdata->hwmon_dev = hwmon;
-
-		/*
-		 * Check whether pkgtemp support is available.
-		 * If so, add interfaces for pkgtemp.
-		 */
-		if (cpu_has(c, X86_FEATURE_PTS))
-			coretemp_add_core(pdev, cpu, 1);
 	}
 
 	/*
-	 * Check whether a housekeeping thread sibling is already online. If
-	 * not, add the interface for this CPU core.
+	 * Add missing package and core interfaces. Besides handling the first
+	 * CPU in the zone, this retries an earlier failed creation attempt.
 	 */
-	if (!cpumask_intersects(&pdata->cpumask, topology_sibling_cpumask(cpu)))
+	if (cpu_has(c, X86_FEATURE_PTS) && !pdata->pkg_data)
+		coretemp_add_core(pdev, cpu, 1);
+
+	if (!get_temp_data(pdata, cpu))
 		coretemp_add_core(pdev, cpu, 0);
 
 	cpumask_set_cpu(cpu, &pdata->cpumask);
@@ -778,6 +773,9 @@ static int coretemp_cpu_offline(unsigned int cpu)
 			coretemp_remove_core(pd, tdata);
 		hwmon_device_unregister(pd->hwmon_dev);
 		pd->hwmon_dev = NULL;
+		kfree(pd->core_data);
+		pd->core_data = NULL;
+		pd->nr_cores = 0;
 		return 0;
 	}
 

---
base-commit: 0b6eda22f9ab67ddb2a872b0c3fc578ad9f4e27e
change-id: 20261020-coretemp-retry-sensor-creation-df49c07a2c86

Best regards,
--  
Ximing Zhang <xzhangjr@gmail.com>

