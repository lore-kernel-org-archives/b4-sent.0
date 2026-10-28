From: "Ashton A." <me@ashtonantila.com>
Date: Wed, 28 Oct 2026 10:57:21 -0700
Subject: [PATCH] ACPI: processor: thermal: Do not leave a stale limit when
 not throttling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-acpi-thermal-stale-limit-v1-1-4b0ab3230f01@ashtonantila.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQqDMBBFryKz7oDJopZepbiYxLFOiVYyUQrBu
 3dqNx8e/PcqKGdhhXtTIfMuKu/FwF0aiBMtT0YZjMG3/upaf0OKq2CZOM+UUAslxiSzFOzIBXv
 YDgFMXzOP8jnTj/7PuoUXx/LrwXF8AUJ0NY98AAAA
X-Change-ID: 20261028-acpi-thermal-stale-limit-7a1b102a1bdb
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Zhang Rui <rui.zhang@intel.com>, Len Brown <lenb@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>
Cc: "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 linux-acpi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 "Ashton A." <me@ashtonantila.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3446; i=me@ashtonantila.com;
 h=from:subject:message-id; bh=x1WkoMix8m2IRMmaFk2Qs6ugRzKiV6VPomK9EBpWNAM=;
 b=owJ4nJvAy8zAJXborYascAmTHeNptSSGrEfmjdUsZluDn3d4J9aqT+UoTdyVE/2+su1mz80+y
 wP193VZOjpKWRjEuBhkxRRZ8kR2vQ3duPnrzMo1NjBzWJlAhjBwcQrARAJyGP5pH11b5P504o7P
 y/ZdbmZdcu8f04GaS2u62tKqpLJYosr9Gf7XXLAsYlDTPjE165BBw1Nv9oZ5fRnVHMv8uR6eEPW
 f9poDAC/fR6M=
X-Developer-Key: i=me@ashtonantila.com; a=openpgp;
 fpr=6E42C46BEA7CB8965829F486494594D16730FDC9
X-Endpoint-Received: by B4 Relay for me@ashtonantila.com/default with auth_id=1348
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

cpufreq_update_thermal_limit() sets thermal_req to cpuinfo.max_freq
scaled by the reduction step, also at step 0, when no throttling is
requested. cpuinfo.max_freq drops to the nominal frequency while boost
is disabled (amd-pstate, and intel_pstate with no_turbo), so a cooling
state update in that window leaves thermal_req at the nominal frequency
after boost is enabled again. The CPU then stays at its base clock
until the next cooling state change.

On systems with an ACPI thermal zone that has a passive trip (_PSV)
with the processors in its _PSL, such an update happens on every
resume, when the zone is re-initialized and step_wise re-applies the
cooling state. Suspending with boost disabled, e.g. in
power-profiles-daemon's "power-saver" profile, and switching back to
"performance" after resume is enough to hit this.

Before commit d15ce412737a ("ACPI: cpufreq: Switch to QoS requests
instead of cpufreq notifier"), the limit was recomputed on every policy
update and could not go stale.

Use FREQ_QOS_MAX_DEFAULT_VALUE at step 0, the value the request is
created with. ->verify() already clamps policy limits to
cpuinfo.max_freq, so this only drops the stale limit.

Reproducer on v7.3, ASUS ROG Flow Z13 (Ryzen AI MAX+ 395, amd-pstate
active), with N being any "Processor" cooling device:

  echo 0 > /sys/devices/system/cpu/cpufreq/boost
  cat /sys/class/thermal/cooling_deviceN/cur_state \
    > /sys/class/thermal/cooling_deviceN/cur_state
  echo 1 > /sys/devices/system/cpu/cpufreq/boost
  cat /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq

This prints 3000000 instead of 5187500. With this patch it prints
5187500, also after the power-profiles-daemon suspend and resume
sequence above.

Bug 221795 reports the same symptom on another ASUS laptop with the
same kind of ACPI thermal zone.

The issue was diagnosed and this patch drafted with an AI coding
assistant (Claude Code, Claude Opus 5.5). I have reviewed the cause
and fix, and I take full responsibility for this commit and the fix
included.

Fixes: d15ce412737a ("ACPI: cpufreq: Switch to QoS requests instead of cpufreq notifier")
Link: https://bugzilla.kernel.org/show_bug.cgi?id=221795
Signed-off-by: Ashton A. <me@ashtonantila.com>
---
 drivers/acpi/processor_thermal.c | 11 +++++++++--
 1 file changed, 9 insertions(+), 2 deletions(-)

diff --git a/drivers/acpi/processor_thermal.c b/drivers/acpi/processor_thermal.c
index 11036f0d2b9..3663a54c043 100644
--- a/drivers/acpi/processor_thermal.c
+++ b/drivers/acpi/processor_thermal.c
@@ -97,8 +97,15 @@ static bool cpufreq_update_thermal_limit(unsigned int cpu, struct acpi_processor
 	if (!policy)
 		return false;
 
-	max_freq = (policy->cpuinfo.max_freq *
-		(100 - reduction_step(cpu) * cpufreq_thermal_reduction_pctg)) / 100;
+	/*
+	 * cpuinfo.max_freq changes when boost is toggled, so storing it when
+	 * no reduction is requested would leave a stale limit behind.
+	 */
+	if (!reduction_step(cpu))
+		max_freq = FREQ_QOS_MAX_DEFAULT_VALUE;
+	else
+		max_freq = (policy->cpuinfo.max_freq *
+			(100 - reduction_step(cpu) * cpufreq_thermal_reduction_pctg)) / 100;
 
 	ret = freq_qos_update_request(&pr->thermal_req, max_freq);
 	if (ret < 0) {

---
base-commit: 65ba8f34ec886ec72b2c07ddc8cf3d815c32869d
change-id: 20261028-acpi-thermal-stale-limit-7a1b102a1bdb

Best regards,
--  
Ashton A. <me@ashtonantila.com>

