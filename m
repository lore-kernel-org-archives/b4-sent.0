From: Jerome Berclaz <jerome.berclaz@proton.me>
Date: Sun, 22 Nov 2026 09:50:09 -0800
Subject: [PATCH] regulator: tps65910: keep external control of always-on
 rails at shutdown
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-tps65910-shutdown-ext-control-v1-1-e86b284e8c6c@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQqDMAwA0F+RnBewATu6Xxk71JrNirTSRCeI/
 75uO77LO0C4RBa4NQcU3qLEnCrMpYEw+vRijEM1UEvWGCLURWznTIsyrjrkd0LeFUNOWvKM1ru
 ro9B33hHUYyn8jPvvvz/+lrWfOOg3hfP8AOVGYhqBAAAA
X-Change-ID: 20261122-tps65910-shutdown-ext-control-6a9792cb5a92
To: Aaro Koskinen <aaro.koskinen@iki.fi>, 
 Andreas Kemnade <andreas@kemnade.info>, Kevin Hilman <khilman@baylibre.com>, 
 Roger Quadros <rogerq@kernel.org>, Tony Lindgren <tony@atomide.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Laxman Dewangan <ldewangan@nvidia.com>
Cc: linux-omap@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-tegra@vger.kernel.org, 
 Jerome Berclaz <jerome.berclaz@proton.me>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3138;
 i=jerome.berclaz@proton.me; h=from:subject:message-id;
 bh=JN0M5HQcPQw6/FlwvnDvfBLOUL9wzUHnN0zQax/4z04=;
 b=owGbwMvMwCVmvC9341tRgSLG02pJDNnM2kkXLp+XqzrA1T5JVj9XtGjRaa2e1XzLGVdH/BJh1
 DjA0pDXUcrCIMbFICumyMLaYJg6/wRbQKH+vEMwc1iZQIYwcHEKwESytRkZ5rz+JDr3oCd7wIWN
 eamT2lpUtx8PtHhQovjLbO8p11/LngBViJ7QnHPMj9FnQ5e7Md/5WUaGaWxuplu+RvaWWb/O2MY
 HAA==
X-Developer-Key: i=jerome.berclaz@proton.me; a=openpgp;
 fpr=058031659FC80650712F9EC233BE6DB1ED151072
X-Endpoint-Received: by B4 Relay for jerome.berclaz@proton.me/default with auth_id=1608
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tps65910_shutdown() clears the external (EN1/EN2/sleep) control of every
regulator. On the Microsoft Surface RT (Tegra 30 + TPS65911), the CPU rail
VDDCTRL is always-on and assigned to EN1, which is driven by the SoC's
CPU_PWR_REQ, with a 0 V sleep voltage. Releasing that assignment drops the
CPU supply while the CPU is still running this loop, so the system hangs
before the PMIC receives the power-off (DEV_OFF) or restart (DEV_OFF_RST)
command: the screen goes black, the PMIC stays on, and the power button
has to be held to turn the device off.

Skip always-on regulators that have external control. They power the SoC
that is still executing, and the final power-off or restart resets the
PMIC anyway.

The hang was traced with netconsole and initcall_debug: the last message
was the clearing of regulator 4 (vddctrl, ext=0x1).

Tested on a Surface RT with a 7.3.1-based kernel (libre-tegra tree):
poweroff and reboot complete, booted either through the vendor UEFI or
through U-Boot. Mainline does not have a Surface RT device tree yet.

The problem was investigated, and this change and its description written,
with the help of an AI coding assistant (Claude); I reviewed the change and
tested it on my device as described above.

Fixes: 1e0c66f49762 ("regulator: tps65910: Sleep control through external inputs")
Signed-off-by: Jerome Berclaz <jerome.berclaz@proton.me>
---
Found while bringing up Linux on a Microsoft Surface RT (libre-tegra kernel
tree, https://codeberg.org/libre-tegra/linux/pulls/10). The Surface RT
device tree is not in mainline yet; the maintainer of that tree suggested
sending this fix here.

Since then, one incomplete shutdown was seen once, with cpuidle enabled
on the U-Boot boot path; it did not reproduce in 16 consecutive reboots
and 2 shutdowns, and I am keeping an eye on it.
---
 drivers/regulator/tps65910-regulator.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/regulator/tps65910-regulator.c b/drivers/regulator/tps65910-regulator.c
index 6b14c39e42de..db1f637fbdc0 100644
--- a/drivers/regulator/tps65910-regulator.c
+++ b/drivers/regulator/tps65910-regulator.c
@@ -1237,6 +1237,19 @@ static void tps65910_shutdown(struct platform_device *pdev)
 		if (!pmic->rdev[i])
 			continue;
 
+		/*
+		 * Keep external control on always-on rails: they power the
+		 * SoC that is still executing this code. On the Microsoft
+		 * Surface RT the CPU rail (VDDCTRL) is controlled by EN1 and
+		 * its sleep voltage is 0, so releasing EN1 here drops the CPU
+		 * supply before the PMIC can be told to power off or restart,
+		 * leaving the system hung with the PMIC still on.
+		 */
+		if (pmic->board_ext_control[i] &&
+		    pmic->rdev[i]->constraints &&
+		    pmic->rdev[i]->constraints->always_on)
+			continue;
+
 		err = tps65910_set_ext_sleep_config(pmic, i, 0);
 		if (err < 0)
 			dev_err(&pdev->dev,

---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261122-tps65910-shutdown-ext-control-6a9792cb5a92

Best regards,
--  
Jerome Berclaz <jerome.berclaz@proton.me>

