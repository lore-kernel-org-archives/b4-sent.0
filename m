From: Moad Tarrih <tarrihmoad@proton.me>
Date: Sat, 21 Nov 2026 21:12:59 +0000
Subject: [PATCH] platform/asus: asus-armoury: add power limits quirk for
 G814FP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-asus-armoury-g814fp-v1-1-6b5ae34fd9c3@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrm0ynRAGvYpxUbBgTQTSMkZDu
 LujLt/i/w1cTMXhVG1g8lTXeSqgQwX9jadRUK/FEENsiGJA9uzI9pizvXFsqR4WTNKmRIG5kSO
 UcjEZ9PW7ni9/e+7u0q/fFez7BxZymrV3AAAA
X-Change-ID: 20261120-asus-armoury-g814fp-7e87710aa6e9
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Moad Tarrih <tarrihmoad@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795295586; l=2842;
 i=tarrihmoad@proton.me; s=20261108; h=from:subject:message-id;
 bh=DPUJpKF8RbaOpYEFNVa4zs2Ih/YJpmPkRRd8Np0e9P4=;
 b=eP3PVy4urFkTB9/mzoVzPMOYltucm29xHjRhMCWq+7pfbQYCQmvESY+YldNH7bx920a+H7OAt
 BaLw5p+EPqrCLQXagqv14iamJCo8VTKljT7tMIK4f1kWXEkFjcvSuvs
X-Developer-Key: i=tarrihmoad@proton.me; a=ed25519;
 pk=wtwpmYxZldK7Qebavgtx7P5WmSQOiWjicK0506NOKLg=
X-Endpoint-Received: by B4 Relay for tarrihmoad@proton.me/20261108 with auth_id=1453
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a power limits quirk entry for the ASUS ROG Strix G18 G814FP laptop.
The limits and defaults were read from the Manual mode sliders in
Armoury Crate on Windows.

Without this entry the driver logs "No matching power limits found for
this system" and the PPT and NVIDIA power attributes return -ENODEV.

Signed-off-by: Moad Tarrih <tarrihmoad@proton.me>
---
Tested on BIOS G814FP.317 (Ryzen 9 9955HX, RTX 5070 Laptop).

All values are the Armoury Crate Manual mode slider ranges. The entry
matches G614FP, the 16" model of the same generation, except that the
PL2/PL3 maximum is 162 W instead of 165 W.

The GPU values agree with the ASUS GPU power specification for G814FP:
https://rog.asus.com/us/articles/rog-gaming-laptops/the-complete-list-of-geforce-gpu-power-specifications-for-2025-rog-and-tuf-gaming-laptops

I concluded `requires_fan_curve` to be `true` by setting it to false
in a test build, writes to ppt_pl1_spl, ppt_pl2_sppt and ppt_pl3_fppt
were accepted and read back, but the package still drew ~140 W under an
all-core load, using `stress-ng` and turbostat to read the wattage.
With a custom fan curve enabled, the same SPL 45 / SPPT 65 / FPPT 65
limits held it at ~65 W.
---
 drivers/platform/asus/asus-armoury.h | 34 ++++++++++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/drivers/platform/asus/asus-armoury.h b/drivers/platform/asus/asus-armoury.h
index 331c3bddf013..3b8937fefd9b 100644
--- a/drivers/platform/asus/asus-armoury.h
+++ b/drivers/platform/asus/asus-armoury.h
@@ -2638,6 +2638,40 @@ static const struct dmi_system_id power_limits[] = {
 			.requires_fan_curve = false,
 		},
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_BOARD_NAME, "G814FP"),
+		},
+		.driver_data = &(struct power_data) {
+			.ac_data = &(struct power_limits) {
+				.ppt_pl1_spl_min = 30,
+				.ppt_pl1_spl_max = 120,
+				.ppt_pl2_sppt_min = 65,
+				.ppt_pl2_sppt_def = 140,
+				.ppt_pl2_sppt_max = 162,
+				.ppt_pl3_fppt_min = 65,
+				.ppt_pl3_fppt_def = 140,
+				.ppt_pl3_fppt_max = 162,
+				.nv_temp_target_min = 75,
+				.nv_temp_target_max = 87,
+				.nv_dynamic_boost_min = 5,
+				.nv_dynamic_boost_max = 15,
+				.nv_tgp_min = 50,
+				.nv_tgp_max = 100,
+			},
+			.dc_data = &(struct power_limits) {
+				.ppt_pl1_spl_min = 25,
+				.ppt_pl1_spl_max = 65,
+				.ppt_pl2_sppt_min = 25,
+				.ppt_pl2_sppt_max = 65,
+				.ppt_pl3_fppt_min = 35,
+				.ppt_pl3_fppt_max = 75,
+				.nv_temp_target_min = 75,
+				.nv_temp_target_max = 87,
+			},
+			.requires_fan_curve = true,
+		},
+	},
 	{
 		.matches = {
 			DMI_MATCH(DMI_BOARD_NAME, "G814J"),

---
base-commit: 9c82959c37bf69c2ace8a0f975cf2129ec1fd982
change-id: 20261120-asus-armoury-g814fp-7e87710aa6e9

Best regards,
--  
Moad Tarrih <tarrihmoad@proton.me>

