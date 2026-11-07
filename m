From: =?utf-8?q?Bekir_=C3=9Cn?= <bekiirun@gmail.com>
Date: Sat, 07 Nov 2026 23:20:02 +0300
Subject: [PATCH] platform/x86: acer-wmi: Add support for Acer Nitro AN16-51
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261107-acer-nitro-an16-51-v1-1-456278eb4cd0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ6DMAxA0asgz1jCFBLBVRBDSA2YISAHqkqIu
 zfQ8Q3/nxBZhSO02QnKH4myhgTKM/CzCxOjvJOhLEpDVFh0nhWD7LqiC2SwJmxMxdYM46uxFaR
 wUx7l+0y7/u94DAv7/T7Bdf0Aj1HNdXYAAAA=
X-Change-ID: 20261107-acer-nitro-an16-51-964e76bf3974
To: "Lee, Chun-Yi" <jlee@suse.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Bekir_=C3=9Cn?= <bekiirun@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794082812; l=2537;
 i=bekiirun@gmail.com; s=20261107; h=from:subject:message-id;
 bh=XbyK8OmmCdT09eWFW+p/K32iqIhSXoUAvUuuLGPFTsE=;
 b=gojpaeKoCAYDNWCaQNE0OspSdpAVSitkVKYPwY8SGeCEXT0VQYHUxMRQ7pdT46SYwViId1PtR
 rhEnvaqLsf/CKcDbVewLxh9/tbLl0Kd38rauB21QaCDbOBeBt2038xV
X-Developer-Key: i=bekiirun@gmail.com; a=ed25519;
 pk=ThEeR1k91IQjKK+VVDMEgjG0h0zzy2D+IV65oEuWzxI=
X-Endpoint-Received: by B4 Relay for bekiirun@gmail.com/20261107 with auth_id=1446
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Acer Nitro AN16-51 supports the same gaming WMI interface as the
Nitro AN515-58 and AN16-41. Its ACPI tables (WMBH method on GUID
7A4DDFE7-5B5D-40B4-8595-4408E0CC7F56) handle the thermal profile misc
setting 0x0B with the values quiet (0x00), balanced (0x01), performance
(0x04), turbo (0x05) and eco (0x06), and report the supported sensors
as 0x0227 (CPU/GPU temperature, CPU/GPU fan speed, external
temperature 2).

Add a DMI entry so that platform profile, hwmon and fan control are
enabled without the predator_v4 module parameter.

Tested on an Acer Nitro AN16-51 (BIOS V1.12):
 - All five platform profiles can be selected through sysfs and
   power-profiles-daemon; the mode key cycles through them and the
   key LED changes accordingly.
 - fan1/fan2 and temp1/temp3 report plausible values; under full CPU
   load in the turbo profile both fans ramp up to ~5850 RPM. temp2
   (external temperature 2) always reads 0, the firmware advertises it
   but the EC field it reads is not populated.
 - pwm1/pwm2: pwm_enable 0 (max) gives ~6600 RPM, pwm_enable 1 with
   pwm 128 gives ~4000 RPM, pwm_enable 2 returns to automatic control.

Profiles and sensors were tested with predator_v4=1 on 7.2.14, fan
control with this DMI entry applied to the 7.2.11 acer-wmi driver.

The ACPI analysis, the change and this message were prepared with the
help of an AI coding assistant (Claude, Anthropic) and tested by me on
the hardware.

Signed-off-by: Bekir Ün <bekiirun@gmail.com>
---
Single DMI entry for the Acer Nitro AN16-51, reusing the AN515-58
quirk. Test details are in the commit message.
---
 drivers/platform/x86/acer-wmi.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/drivers/platform/x86/acer-wmi.c b/drivers/platform/x86/acer-wmi.c
index 3a018fdf5..08f663fc6 100644
--- a/drivers/platform/x86/acer-wmi.c
+++ b/drivers/platform/x86/acer-wmi.c
@@ -690,6 +690,15 @@ static const struct dmi_system_id acer_quirks[] __initconst = {
 		},
 		.driver_data = &quirk_acer_nitro_an515_58,
 	},
+	{
+		.callback = dmi_matched,
+		.ident = "Acer Nitro AN16-51",
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "Acer"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "Nitro AN16-51"),
+		},
+		.driver_data = &quirk_acer_nitro_an515_58,
+	},
 	{
 		.callback = dmi_matched,
 		.ident = "Acer Nitro AN515-58",

---
base-commit: c339f4010dea8b0d754f84ace70cd1b089878ef8
change-id: 20261107-acer-nitro-an16-51-964e76bf3974

Best regards,
--  
Bekir Ün <bekiirun@gmail.com>

