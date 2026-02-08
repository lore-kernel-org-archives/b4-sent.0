From: Baoyuan Geng <geng.baoyuan@gmail.com>
Date: Mon, 09 Feb 2026 00:16:05 +0800
Subject: [PATCH] thermal: qcom-spmi-temp-alarm: fix out-of-bounds when
 copying temp map
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260209-fix-qcom-spmi-temp-alarm-oob-v1-1-3f1c67090e77@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqDMBBA0avIrB2YziJWryIu0nRSB4xJE5FC8
 O6GLh98foUiWaXA1FXIcmrRuDc8+g7cavePoL6bgYkNMT3R6w+/LgYsKSgeEhLazeaAMb7QjDQ
 Y8o4tG2iLlKX1//28XNcNKYx98W4AAAA=
X-Change-ID: 20260208-fix-qcom-spmi-temp-alarm-oob-690760fc2a26
To: Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@linaro.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>
Cc: linux-pm@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Baoyuan Geng <geng.baoyuan@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1770567397; l=3171;
 i=geng.baoyuan@gmail.com; s=20260208; h=from:subject:message-id;
 bh=IPx2aYZrJ7XVu7bN4arD9CKDHc8AbrpqAhkC0NxaMcs=;
 b=GL7ylGAiRQkvObp1NvpwrrYJTbgoT0im3QK/Sp1/y4+MwOxQeMz9RRBRxXcRNZZDulWPXdY15
 Dtk+3rCS2hyCOUAz70sEj9wfWF+B8cj6DA8mjjwyZzNA4MbSTFHPQcz
X-Developer-Key: i=geng.baoyuan@gmail.com; a=ed25519;
 pk=K8rZZQg2HZ88njeBrQUyqUdFffk6Lle8CFZzfh55wfU=
X-Endpoint-Received: by B4 Relay for geng.baoyuan@gmail.com/20260208 with auth_id=630
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The way to index the pointer of array missed a dereference, fix it.

The bug is reported by KASAN[0].

[0]:
==================================================================
BUG: KASAN: global-out-of-bounds in qpnp_tm_sync_thresholds+0x11c/0x1a4 [qcom_spmi_temp_alarm]
Read of size 24 at addr ffffbb86e7685280 by task (udev-worker)/928

CPU: 6 UID: 0 PID: 928 Comm: (udev-worker) \
    Not tainted 6.19.0-rc8-00185-g2687c848e578 #4 PREEMPT
Hardware name: Thundercomm RUBIK Pi 3 (DT)
Call trace:
 show_stack+0x18/0x30 (C)
 dump_stack_lvl+0x60/0x80
 print_report+0x18c/0x4e0
 kasan_report+0xac/0xf0
 kasan_check_range+0xfc/0x1ac
 __asan_memcpy+0x3c/0xa0
 qpnp_tm_sync_thresholds+0x11c/0x1a4 [qcom_spmi_temp_alarm]
 qpnp_tm_probe+0x390/0xb60 [qcom_spmi_temp_alarm]
 platform_probe+0xc0/0x1f0
 really_probe+0x190/0x604
 __driver_probe_device+0x160/0x2c0
 driver_probe_device+0x5c/0x2b8
 __driver_attach+0x134/0x534
 bus_for_each_dev+0xf4/0x180
 driver_attach+0x3c/0x60
 bus_add_driver+0x1f0/0x510
 driver_register+0x154/0x39c
 __platform_driver_register+0x58/0x84
 qpnp_tm_driver_init+0x2c/0x1000 [qcom_spmi_temp_alarm]
 do_one_initcall+0xd4/0x354
 do_init_module+0x30c/0x8bc
 load_module+0x3de0/0x5764
 init_module_from_file+0x144/0x254
 __arm64_sys_finit_module+0x338/0x710
 invoke_syscall.constprop.0+0x64/0x220
 do_el0_svc+0x144/0x200
 el0_svc+0x38/0xb8
 el0t_64_sync_handler+0xa0/0xe4
 el0t_64_sync+0x198/0x19c

The buggy address belongs to the variable:
 temp_map_gen2_v1+0x60/0xffffffffffff9de0 [qcom_spmi_temp_alarm]
==================================================================

Fixes: 703f13285a6c ("thermal/drivers/qcom-spmi-temp-alarm: Add temp alarm data struct based on HW subtype")
Fixes: 1f835c6a4c84 ("thermal/drivers/qcom-spmi-temp-alarm: Prepare to support additional Temp Alarm subtypes")

Signed-off-by: Baoyuan Geng <geng.baoyuan@gmail.com>
---
 drivers/thermal/qcom/qcom-spmi-temp-alarm.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/thermal/qcom/qcom-spmi-temp-alarm.c b/drivers/thermal/qcom/qcom-spmi-temp-alarm.c
index f39ca0ddd17b..faaa56b399e8 100644
--- a/drivers/thermal/qcom/qcom-spmi-temp-alarm.c
+++ b/drivers/thermal/qcom/qcom-spmi-temp-alarm.c
@@ -345,7 +345,7 @@ static int qpnp_tm_update_critical_trip_temp(struct qpnp_tm_chip *chip,
 	}
 
 skip:
-	memcpy(chip->temp_thresh_map, chip->data->temp_map[threshold],
+	memcpy(chip->temp_thresh_map, (*chip->data->temp_map)[threshold],
 		sizeof(chip->temp_thresh_map));
 	reg |= threshold;
 	if (disable_stage2_shutdown && !chip->require_stage2_shutdown)
@@ -535,7 +535,7 @@ static int qpnp_tm_sync_thresholds(struct qpnp_tm_chip *chip)
 		return ret;
 
 	threshold = reg & SHUTDOWN_CTRL1_THRESHOLD_MASK;
-	memcpy(chip->temp_thresh_map, chip->data->temp_map[threshold],
+	memcpy(chip->temp_thresh_map, (*chip->data->temp_map)[threshold],
 		sizeof(chip->temp_thresh_map));
 
 	return ret;

---
base-commit: 2687c848e57820651b9f69d30c4710f4219f7dbf
change-id: 20260208-fix-qcom-spmi-temp-alarm-oob-690760fc2a26

Best regards,
-- 
Baoyuan Geng <geng.baoyuan@gmail.com>

