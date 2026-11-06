From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Subject: [PATCH 0/2] thermal: tegra: Fix SOC_THERM temperatures on Tegra114
Date: Fri, 06 Nov 2026 21:31:54 +0100
Message-Id: <20261106-upstream-soctherm-t114-v1-0-c875d1921084@tsv-stahl-riesa.de>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CQAxA4auQrm1CBx0yXsW4gKFCSfhJOxgSw
 t0ddfkt3jvAWIUN7sUBym8xWeYMuhQQh2buGaXLBlc6T6WrcFstKTcT2hLTwDphIrpiuAWKvq3
 r0HnI8ar8kv03fjz/tq0dOabvDc7zA9qsbfJ6AAAA
X-Change-ID: 20261023-upstream-soctherm-t114-9591c6b779d6
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, 
 Mikko Perttunen <mperttunen@nvidia.com>, linux-pm@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793997117; l=3648;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=m929wZ0aCncaA6g4wkYgu+Bj9JMpo6dWskQPUoPSN2E=;
 b=xtP2fQjeUtnSoV0Y2B87u7WaClmxukXQDyJN/UzYWkJuDbTAKjEQ5+GNSj34QJY2FmjwXXeJG
 i9k7pnoV2GLBnhnRH3xHbSPAH+lnEpHGYW72sGn+XdBjZRFGtLjtZfM
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the NVIDIA Tegra Note 7 (Tegra114) all four SOC_THERM zones read 0 C
with mainline, in idle and under load, so throttling and thermtrip have
no effect on this SoC. There are two separate causes:

1. tegra_calc_shared_calib() sign-extends the whole fuse word instead of
   the SHIFT_CP field. On Tegra114, where SHIFT_CP is not in the low
   bits, this distorts the calibration of every sensor.

2. The hardware calculates THERMA * capture in 24 bits and discards the
   result above 2^24 (TCALC_OVER set, TEMP_VALID cleared). With the
   calibration in 0.5 C units a Tegra114 sensor is only valid for
   T < (2048 + THERMB) / 2, which is far below the thermtrip
   temperature. Patch 2 switches Tegra114 to 1 C units, as the
   downstream driver does. The fuse calibration stays in 0.5 C units,
   as discussed in the review of the Tegra114 series [1].

Patch 1 is Svyatoslav's fix, unchanged apart from the Fixes and stable
tags and a sentence on why the other SoCs are not affected. Without
patch 2 it gives three zones that work only up to about 45-53 C on this
device.

Zone temperatures on a Tegra Note 7 (P1640) in C, idle / after 60 s of
load on all four cores:

               mainline   patch 1      patches 1+2
  cpu           0 / 0     41.5 / 55.5*   43 / 63
  gpu           0 / 0      0   / 0       39 / 55
  pllx          0 / 0     44   / 52.5*   43 / 62
  mem           0 / 0     39   / 50.5    39 / 53
  thermistor      -       34   / 39      34 / 42

  * the sensors behind the zone were already invalid, the zone stayed
    below the real temperature

"thermistor" is the board thermistor on the PMIC GPADC, as a
reference. With both patches all eight sensors stay valid and thermtrip,
throttle and trip thresholds are programmed as 102, 100 and 90 C.

Tested with v7.3 on the Tegra Note 7 P1640 (me) and P1988 (Svyatoslav,
all four zones work; tags to follow from him on the list). The series
is unchanged on top of thermal/linux-next, but only build tested there.
Thermtrip and the hardware throttle were not provoked on purpose, the
highest temperature seen was 98 C. Suspend/resume was not tested.

The series is independent of "thermal/drivers/tegra/soctherm: Program
throttrip with hot trip temperature" [2], which is still pending; they
apply in either order.

Tool use (see Documentation/process/generated-content.rst): patch 2,
its changelog and this cover letter were prepared with an LLM coding
assistant (Claude Code). It evaluated the SOC_THERM register dumps from
the device, recalculated the calibration from the fuse values, wrote
the code change and drafted the texts from my measurements and
instructions. I reviewed the change and ran all tests on the device.
Patch 1 is Svyatoslav's own work.

[1] https://lore.kernel.org/all/22816196.EfDdHjke4D@senjougahara/
[2] https://lore.kernel.org/all/20261020-upstream-soctherm-throttrip-v1-1-c67f8a02ec3b@tsv-stahl-riesa.de/

---
Patrick Fischer (1):
      thermal/drivers/tegra: Avoid SOC_THERM calculation overflow on Tegra114

Svyatoslav Ryhel (1):
      thermal: tegra: soctherm-fuse: Fix shifted_cp extension

 drivers/thermal/tegra/soctherm-fuse.c     | 17 +++++++++++++----
 drivers/thermal/tegra/soctherm.c          | 21 +++++++++++++--------
 drivers/thermal/tegra/soctherm.h          |  6 ++++++
 drivers/thermal/tegra/tegra114-soctherm.c |  4 +++-
 4 files changed, 35 insertions(+), 13 deletions(-)
---
base-commit: 32cb06b34701827db0ff34244d84fc74e40ca350
change-id: 20261023-upstream-soctherm-t114-9591c6b779d6

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

