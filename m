From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:12:24 +0000
Subject: [PATCH] thermal/drivers/tegra: Sign-extend the extracted
 shifted_cp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-tegra-soctherm-shifted-cp-v1-1-528e3621226c@enser.io>
X-B4-Tracking: v=1; b=H4sIALd5AmsC/yXMywrCMBCF4Vcps3bUxJKCryJd5DJpItiWmViE0
 nc30eV3OPw7CHEmgXu3A9OWJS9zhTp14JOdJ8IcqkFftVFKa3Q9FprYoiy+JOIXSsqxUEC/or0
 5PURjTFQBamJlivnzyz/Gv+XtnuRLa7aHs0Lo2M4+tanxsg3nHtlrOI4v6YOPbaAAAAA=
X-Change-ID: 20261122-b4-tegra-soctherm-shifted-cp-a3b27f666f1d
To: Daniel Lezcano <daniel.lezcano@kernel.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Zhang Rui <rui.zhang@intel.com>, Lukasz Luba <lukasz.luba@arm.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, Wei Ni <wni@nvidia.com>, 
 linux-pm@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324344; l=2716;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=1sMu9mVDGd6aaArtCRb7zlONQ4RxQR24b0aSqbo+xiA=;
 b=tCR53qlWrAmq3smR2lCgPWXmohcgdE0R0LYNquoih7cWfLPWnmIgJ/N9R0EuV6bUy2Iq9r7gk
 CwCh6fupDOjC+FrD3wpnc5VmhROGZOGrveWGP1F0qokku9JRTVRxAYF
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_calc_shared_calib() extracts shifted_cp from its mask and shift,
then throws that value away on the next line and sign-extends the raw
fuse word instead:

	shifted_cp = (val & tfuse->fuse_shift_cp_mask) >>
		     tfuse->fuse_shift_cp_shift;
	shifted_cp = sign_extend32(val, 5);

shifted_ft, two lines above, is sign-extended from the extracted value,
which shows the intent.

This was harmless while every supported SoC placed the field at bit 0:
tegra124, tegra132 and tegra210 all have fuse_shift_cp_shift = 0, so the
masked extraction and sign_extend32(val, 5) name the same bits. Tegra114
has fuse_shift_cp_mask = 0x3f << 10 and fuse_shift_cp_shift = 10, so it
reads bits [5:0] of FUSE_VSENSOR_CALIB instead, which belong to base_cp.
actual_temp_cp, and with it the THERMA/THERMB coefficients programmed into
SENSOR_CONFIG2, come out wrong. The hardware then flags most conversions
as overflowed and never publishes them.

On a Tegra Note 7 (Tegra114) seven of the eight sensors report an
overflow with TEMP_VALID = 0, their thermctl group registers stay at
zero, and cpu-thermal, gpu-thermal and pllx-thermal read 0 in sysfs. Only
mem-thermal reads a temperature. cpu-thermal carries the passive trip and
the cpufreq cooling device, so software throttling never engages. The
hardware thermtrip compares against the sensors directly and is not
affected.

With this change all four zones read plausible, distinct and moving
temperatures (cpu 32.5-33.5, gpu 30.5-31, pllx 34-35.5, mem 31-31.5 C on
an idle unit).

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: 65b6d57c24ed ("thermal: tegra: split tegra_soctherm driver")
Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/thermal/tegra/soctherm-fuse.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/thermal/tegra/soctherm-fuse.c b/drivers/thermal/tegra/soctherm-fuse.c
index 8d37cd8c91..2de1d0cb67 100644
--- a/drivers/thermal/tegra/soctherm-fuse.c
+++ b/drivers/thermal/tegra/soctherm-fuse.c
@@ -102,7 +102,7 @@ int tegra_calc_shared_calib(const struct tegra_soctherm_fuse *tfuse,
 
 	shifted_cp = (val & tfuse->fuse_shift_cp_mask) >>
 		     tfuse->fuse_shift_cp_shift;
-	shifted_cp = sign_extend32(val, 5);
+	shifted_cp = sign_extend32(shifted_cp, 5);
 
 	shared->actual_temp_cp = 2 * NOMINAL_CALIB_CP + shifted_cp;
 	shared->actual_temp_ft = 2 * tfuse->nominal_calib_ft + shifted_ft;

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-tegra-soctherm-shifted-cp-a3b27f666f1d

Best regards,
--  
EMCP333 <emcp@enser.io>

