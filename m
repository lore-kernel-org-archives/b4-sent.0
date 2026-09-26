From: =?UTF-8?q?Bata=20Roland=20Kriszti=C3=A1n?= <batarolandkrisztian@gmail.com>
Date: Sat, 26 Sep 2026 12:21:55 +0200
Subject: [PATCH RFC] drm/xe/hwmon: refresh B70 temperature inputs after GT
 idle
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
Content-Type: text/plain; charset="utf-8"
To: intel-xe@lists.freedesktop.org
Cc: batarolandkrisztian@gmail.com, karthik.poosa@intel.com, 
 matthew.brost@intel.com, raag.jadav@intel.com, rodrigo.vivi@intel.com, 
 thomas.hellstrom@linux.intel.com
Message-ID: <179041811564.526373.13204522833274380927.b70-hwmon-rfc@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790418421; l=13182;
 i=batarolandkrisztian@gmail.com; s=b70-rfc-20260926;
 h=from:subject:message-id; bh=WjRW74hKdBPifqcI8jX/D0MkFd8adpAMbufnBmow6s0=;
 b=mLnhI1rQ0q2iT5/g9iVuRSL5BnvBe+koA/YQBdkrv7lUtUPbxJ+IjQYYPQpugG6EniVpRVF4J
 s1PVBySdSayDxax+m4C8hmi183c5T/b17pujyBsev/2EvRk971DouuP
X-Developer-Key: i=batarolandkrisztian@gmail.com; a=ed25519;
 pk=7yRw67BwHv8okGRYJIehsbjtaknESDTkZbyNra2ZCY4=
X-Endpoint-Received: by B4 Relay for batarolandkrisztian@gmail.com/b70-rfc-20260926 with auth_id=1065
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two Arc Pro B70 devices (8086:e223) retain their package temperature
after compute workloads despite both GTs returning to C6. A device
runtime PM reference does not refresh the sample while power/control
is already on.

With GuC 70.72.1 on Fedora kernel 7.1.10, a 60-second OpenCL workload
followed by 45 seconds of idle left package temperature at 55 C on both
cards. Acquiring all GT forcewake references still returned 55 C in
the first read, about 57 us after open completed. At about 1053 us the
reported value became 34 C on both cards. A brief GT-only pulse from
reading cur_freq did not refresh the package value.

As an RFC, acquire forcewake references for the temperature input read,
allow time for a new sample, then release the references on both the
success and partial-acquisition failure paths. Limit the experiment to
the measured PCI ID and leave labels, limits and other hwmon types on
their existing paths.

The 2 ms interval and use of all domains are empirical, not a hardware
specification guarantee. This needs review of the sensor conversion
time, minimum wake domains and alternatives such as a PCODE refresh or
readiness indication before it can become a production fix.

Compile-tested xe_hwmon.o on current drm-tip with W=1 and Xe display both
disabled and enabled. The wake/wait/read sequence was measured through
debugfs on two B70s; the modified kernel has not been boot-tested.

Link: https://gitlab.freedesktop.org/drm/xe/kernel/-/work_items/7805
Assisted-by: OpenAI:gpt-6-astra
Signed-off-by: Bata Roland Krisztián <batarolandkrisztian@gmail.com>
---
RFC: proposed direction for issue 7805, not a claim of a production-ready fix.

Hi Xe maintainers,

I am following up on my B70 stale-temperature report with a smaller
reproduction, timing measurements, and a prototype read-side change.

Questions before turning this into v1:

1. Is there a PCODE operation or freshness/conversion-ready indication that
   should be used instead of a fixed settling interval? The first MMIO read
   after successful forcewake still returned the old temperature.
2. Which wake domains are actually required? A GT0 hw_engines read, which
   holds all domains for that GT while dumping registers, also refreshed
   package/mctrl/PCIe readings. The conservative prototype mirrors the
   device forcewake_all sequence used for the controlled timing experiment.
3. Should a refresh cover/cache several temperature channels together? The
   prototype wakes per input read. The power measurements below are for one
   batch per device every two seconds, not for reading every hwmon channel
   at high frequency and not measurements of this compiled patch.
4. Is this a known firmware issue with a preferred fix? Should the eventual
   driver handling apply to other Battlemage IDs? This RFC only opts in the
   tested 8086:e223 devices.

Hardware and reproduction
-------------------------
Two Intel Arc Pro B70s, PCI ID 8086:e223, on an ASRock X870E Taichi / Ryzen
5 9600X. Fedora CoreOS 44.20260829.3.1, kernel 7.1.10-200.fc44.x86_64,
GuC 70.72.1, HuC 8.2.10. power/control=on was kept throughout; it is an
existing workaround for noisy PCI runtime suspend/resume cycling.

A bounded 60-second OpenCL workload used a private 1 MiB output buffer per
device, followed by 45 seconds without GPU submissions. Both GTs reached
C6, actual frequency was zero, and idle residency continued advancing.
Package readings stayed at 55 C on both cards. A short GT0 cur_freq read
(itself a GT-only forcewake pulse) did not correct the package reading.

Opening forcewake_all, then reading temperatures while holding the fd:

                    B70 A                  B70 B
before              55 C                   55 C
first read          55 C at 57.769 us       55 C at 56.119 us
first correction    34 C at 1053.529 us     34 C at 1053.039 us

Times are measured from completion of open, not the initial wake request.
The 2, 5, 10 ms and later samples were also refreshed. These two observations
are not a guaranteed maximum sensor-conversion latency.

In a separate 30-second observation / short-pulse / observation sequence,
16 two-millisecond holds at two-second intervals returned approximately
24 C and 22-23 C. The complete open/wait/read/close scope was about 3.06 ms
and 3.07 ms median. GT idle residency during the pulse phase exceeded 99.7%.

Energy-counter-derived card power, W:
                    before       pulses       after
B70 A               5.30         5.51         4.87
B70 B               4.31         4.48         4.39

These are short observations with normal background system activity; they
are not a general power-regression benchmark. Holding all domains for two
seconds during the timing experiment cost about 81 W per card at the
retained 2800 MHz request and caused self-heating. A permanent forcewake is
therefore unsuitable. References were released and both GTs returned to C6
after every completed experiment. No reset, rebind or PM-policy change was
used for these measurements.

Source/build checks
-------------------
The BMG temperature read path is unchanged between v7.1.10, v7.2.5 and the
current drm-tip version examined here. The newer Fedora 20260910 firmware
collection contains byte-identical BMG GuC/HuC files to 20260810.

Base: drm-tip 666d2f09d9045fc8f72cc1f71528a04acbaf5229
      2026-09-26 04:44:20 UTC integration manifest
Checked: checkpatch --strict, zero errors/warnings/checks for the patch;
         xe_hwmon.o compile with W=1, Xe display disabled and enabled.
Not yet tested: booted patched kernel, IGT/CI, suspend/resume, hardware
               acquisition-error paths, other GPU variants, high-rate
               multi-channel reads.

The attached change is deliberately an RFC. I would appreciate guidance on
the correct hardware handshake and domain scope, and can test a revised
approach on these two cards.

A later smoke test of the standalone reproducer below also changed a
previously low reading upward (26 to 44 C on one card). I therefore do not
use an unchanged/high-value heuristic to declare a value stale, or replace
readings with an inferred idle temperature. The observations concern the
reported values; independent physical thermometry was not performed.

Standalone reproduction aid
---------------------------
After a GPU workload and idle interval, save this as repro.py and run:
  sudo python3 repro.py 0000:03:00.0 0000:08:00.0
Use your cards' PCI addresses. This script itself starts no workload.

#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Measure B70 temperature refresh after forcewake; run after workload/idle.

No workload, PM-policy/frequency write, reset or driver rebind is performed.
Only the requested 8086:e223 Xe devices are read. Each wake lasts about 10 ms;
readings are printed after the descriptor has been closed.
"""
import argparse
import json
import os
from pathlib import Path
import re
import signal
import time


def text(path):
    return path.read_text().strip()


def card(bdf, debugfs):
    if not re.fullmatch(r"[0-9a-f]{4}:[0-9a-f]{2}:[0-9a-f]{2}\.[0-7]", bdf):
        raise ValueError("Expected a full lowercase PCI address")
    pci = Path("/sys/bus/pci/devices") / bdf
    if (text(pci / "vendor"), text(pci / "device")) != ("0x8086", "0xe223"):
        raise ValueError(f"Not the tested B70 PCI ID: {bdf}")
    if (pci / "driver").resolve() != Path("/sys/bus/pci/drivers/xe"):
        raise ValueError(f"Not bound to xe: {bdf}")
    hw = list((pci / "hwmon").glob("hwmon*"))
    if len(hw) != 1 or text(hw[0] / "name") != "xe":
        raise ValueError(f"Ambiguous hwmon: {bdf}")
    labels = {text(p): p.with_name(p.name.replace("_label", "_input"))
              for p in hw[0].glob("temp*_label")}
    if "pkg" not in labels:
        raise ValueError(f"Missing package sensor: {bdf}")
    paths = {label: labels[label] for label in ("pkg", "vram", "mctrl", "pcie")
             if label in labels}
    return bdf, pci, paths, debugfs / bdf / "forcewake_all"


def snapshot(pci, paths):
    start = time.monotonic_ns()
    values = {label: int(text(path)) for label, path in paths.items()}
    return {"temp_read_start_ns": start, "temp_read_end_ns": time.monotonic_ns(),
            "millidegrees": values,
            "gt_idle": [text(pci / "tile0" / f"gt{n}" / "gtidle/idle_status")
                        for n in (0, 1)]}


def interrupted(signum, _frame):
    raise SystemExit(f"Interrupted by signal {signum}; descriptors will close")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--debugfs-root", type=Path, default=Path("/sys/kernel/debug/dri"))
    parser.add_argument("devices", nargs="+")
    args = parser.parse_args()
    if os.geteuid() != 0:
        parser.error("Run with sudo for debugfs access")
    if len(args.devices) > 8 or len(set(args.devices)) != len(args.devices):
        parser.error("Select at most eight distinct devices")
    cards = [card(bdf, args.debugfs_root) for bdf in args.devices]
    signal.signal(signal.SIGTERM, interrupted)
    signal.signal(signal.SIGALRM, interrupted)
    signal.alarm(30)
    for bdf, pci, paths, wake in cards:
        before = snapshot(pci, paths)
        if before["gt_idle"] != ["gt-c6", "gt-c6"]:
            print(json.dumps({"bdf": bdf, "skipped": "GT is active", "before": before}))
            continue
        samples = []
        opened_at = time.monotonic_ns()
        with wake.open("rb"):
            open_returned_at = time.monotonic_ns()
            for target_us in (0, 1000, 2000, 5000, 10000):
                remaining_ns = open_returned_at + target_us * 1000 - time.monotonic_ns()
                if remaining_ns > 0:
                    time.sleep(remaining_ns / 1e9)
                value = snapshot(pci, paths)
                samples.append({"target_us": target_us,
                                "since_open_us": (value["temp_read_start_ns"] - open_returned_at) / 1000,
                                **value})
        closed_at = time.monotonic_ns()
        time.sleep(1)
        print(json.dumps({"bdf": bdf, "kernel": os.uname().release,
                          "power_control": text(pci / "power/control"),
                          "before": before, "samples": samples,
                          "open_us": (open_returned_at - opened_at) / 1000,
                          "total_scope_us": (closed_at - opened_at) / 1000,
                          "after_close": snapshot(pci, paths)}), flush=True)


if __name__ == "__main__":
    main()

 drivers/gpu/drm/xe/xe_hwmon.c | 38 +++++++++++++++++++++++++++++++++++
 1 file changed, 38 insertions(+)

diff --git a/drivers/gpu/drm/xe/xe_hwmon.c b/drivers/gpu/drm/xe/xe_hwmon.c
index 5edeac96..2bb5bca2 100644
--- a/drivers/gpu/drm/xe/xe_hwmon.c
+++ b/drivers/gpu/drm/xe/xe_hwmon.c
@@ -3,6 +3,7 @@
  * Copyright © 2023 Intel Corporation
  */
 
+#include <linux/delay.h>
 #include <linux/hwmon-sysfs.h>
 #include <linux/hwmon.h>
 #include <linux/jiffies.h>
@@ -14,6 +15,8 @@
 #include "regs/xe_mchbar_regs.h"
 #include "regs/xe_pcode_regs.h"
 #include "xe_device.h"
+#include "xe_force_wake.h"
+#include "xe_gt.h"
 #include "xe_hwmon.h"
 #include "xe_mmio.h"
 #include "xe_pcode.h"
@@ -1096,6 +1099,35 @@ xe_hwmon_temp_read(struct xe_hwmon *hwmon, u32 attr, int channel, long *val)
 	}
 }
 
+static int xe_hwmon_b70_temp_read(struct xe_hwmon *hwmon, u32 attr,
+				  int channel, long *val)
+{
+	unsigned int refs[XE_MAX_TILES_PER_DEVICE * XE_MAX_GT_PER_TILE] = {};
+	struct xe_device *xe = hwmon->xe;
+	struct xe_gt *gt;
+	int ret = -ETIMEDOUT;
+	u8 id;
+
+	for_each_gt(gt, xe, id) {
+		refs[id] = xe_force_wake_get(gt_to_fw(gt), XE_FORCEWAKE_ALL);
+		if (!xe_force_wake_ref_has_domain(refs[id], XE_FORCEWAKE_ALL))
+			goto out;
+	}
+
+	/*
+	 * A forcewake acknowledgment does not imply a fresh thermal sample.
+	 * RFC: this interval is empirical on 8086:e223; the conversion time
+	 * and minimum required wake domains need hardware-spec confirmation.
+	 */
+	usleep_range(2000, 2500);
+	ret = xe_hwmon_temp_read(hwmon, attr, channel, val);
+out:
+	for_each_gt(gt, xe, id)
+		xe_force_wake_put(gt_to_fw(gt), refs[id]);
+
+	return ret;
+}
+
 static umode_t
 xe_hwmon_power_is_visible(struct xe_hwmon *hwmon, u32 attr, int channel)
 {
@@ -1408,6 +1440,12 @@ xe_hwmon_read(struct device *dev, enum hwmon_sensor_types type, u32 attr,
 
 	switch (type) {
 	case hwmon_temp:
+		/* Limit the RFC workaround to the PCI ID measured in issue 7805. */
+		if (attr == hwmon_temp_input &&
+		    hwmon->xe->info.platform == XE_BATTLEMAGE &&
+		    hwmon->xe->info.devid == 0xe223)
+			return xe_hwmon_b70_temp_read(hwmon, attr, channel, val);
+
 		return xe_hwmon_temp_read(hwmon, attr, channel, val);
 	case hwmon_power:
 		return xe_hwmon_power_read(hwmon, attr, channel, val);

base-commit: 666d2f09d9045fc8f72cc1f71528a04acbaf5229
-- 
2.55.0

