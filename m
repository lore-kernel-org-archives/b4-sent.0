From: Arnaud Ungaro <contact@arnaud-ungaro.fr>
Date: Sat, 24 Oct 2026 22:39:12 +0200
Subject: [PATCH] platform/x86: hp-wmi: Add OMEN 16-k0xxx board 8A4C support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-hp-wmi-8a4c-v1-1-5297fe0104de@arnaud-ungaro.fr>
X-B4-Tracking: v=1; b=H4sIAG8X3WoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyMT3YwC3fLcTF2LRJNk3eRE02Qjy0QLUwuTRCWgjoKi1LTMCrBp0bG
 1tQAtXBcCXQAAAA==
X-Change-ID: 20261024-hp-wmi-8a4c-ca5c29a8584a
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Hans de Goede <hansg@kernel.org>
Cc: platform-driver-x86@vger.kernel.org, 
 Krishna Chomal <krishna.chomal108@gmail.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792874351; l=3562;
 i=contact@arnaud-ungaro.fr; s=20261024; h=from:subject:message-id;
 bh=rRskuoSffCBZeKa0EotDA49CXzGteq8ptZIW1CoaE4M=;
 b=0cC0d+4wMxvOvKTcdgD2Oi3wvky9K4u6kCNl0PVAxIU3dqQxTnRnC84774fTJQDz7Om4+ztQB
 XucxRR4r9OSCiBRjpZTGdRPPGj63GZTnEo2Ts+MaFqKHmvZngOydqkT
X-Developer-Key: i=contact@arnaud-ungaro.fr; a=ed25519;
 pk=E36DBHlmRhVNV3rriuNdMXwzVy3fGJ5rWE/saD1H0XU=
X-Endpoint-Received: by B4 Relay for contact@arnaud-ungaro.fr/20261024 with auth_id=1313
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP OMEN 16-k0xxx ships with at least two DMI board names. 8A4D is
already mapped to omen_v1_legacy_board_params but 8A4C is not. On 8A4C
the driver falls back to the generic thermal profile path so the
performance profile never enables the GPU configurable TGP. The RTX
3070 Ti Laptop GPU stays capped at 105 W instead of 150 W with
nvidia-powerd running.

The board reports thermal policy version 1 through
HPWMI_GET_SYSTEM_DESIGN_DATA and keeps its thermal profile in EC
register 0x95 (0x30 by default). This is what
omen_v1_legacy_board_params expects.

Add 8A4C to hp_wmi_feature_boards[] and map it to
omen_v1_legacy_board_params.

Tested on an OMEN 16-k0001nf (board 8A4C, BIOS F.21) with nvidia-powerd
running:

- With this change on 7.2.9 the performance profile enables cTGP. The
  GPU power limit goes from 80 W to 125 W at idle and 150 W under load.
- With hp-wmi.c from for-next the low-power, balanced and performance
  profiles all switch. EC 0x95 reads 0x31 in performance. The GPU power
  limit at idle is 125 W in performance and 80 W otherwise. Both fan
  speeds are reported and the max and auto fan modes work.

Cc: stable@vger.kernel.org # 7.2.x
Signed-off-by: Arnaud Ungaro <contact@arnaud-ungaro.fr>
---
Notes on this board, not changed by this patch:

- Like on 8A4D (https://bugzilla.kernel.org/show_bug.cgi?id=221680) the
  EC moves 0x95 back to 0x30 120 to 132 s after switching to
  performance while cTGP stays enabled and platform_profile still reads
  "performance". Under a long CPU load the CPU is already limited by its
  temperature (97 C) and package power is about the same before and
  after the fallback.

- I cleared the EC timer (0x63) and set the NOTIMER and TURBO flags in
  0x62 after each profile change as the driver does for the boards in
  omen_timed_thermal_profile_boards[]. 0x95 then stays at 0x31 but the
  fans stay at 2100 and 0 RPM under full CPU load and the CPU throttles
  down to 40 W. So I left the timer alone.

- Reloading hp-wmi after the fallback left no platform profile
  registered. A separate patch handles that.

Kernel versions:

- Tested on the laptop with 7.2.9.
- Applies to 7.2.12 and 7.3 and builds without warnings with W=1
  (7.2.12 against the 7.2.9 headers, 7.3 against for-next).
- Does not apply to 7.0 and 7.1. They list 8A4D in
  victus_s_thermal_profile_boards[] with omen_v1_legacy_thermal_params
  so a backport there would add 8A4C to that table instead.
- 6.19 and older have no support for 8A4D.

This is why the stable tag is limited to 7.2.x.
---
 drivers/platform/x86/hp/hp-wmi.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/platform/x86/hp/hp-wmi.c b/drivers/platform/x86/hp/hp-wmi.c
index 52077833ac89d3f4bd9b99fbbc1812c4f09d16c7..1cebc7e0cf47668761491091c50af0fb25d42572 100644
--- a/drivers/platform/x86/hp/hp-wmi.c
+++ b/drivers/platform/x86/hp/hp-wmi.c
@@ -257,6 +257,10 @@ static const struct dmi_system_id hp_wmi_feature_boards[] __initconst = {
 		.matches = { DMI_MATCH(DMI_BOARD_NAME, "8A44") },
 		.driver_data = (void *)&omen_v1_legacy_board_params,
 	},
+	{
+		.matches = { DMI_MATCH(DMI_BOARD_NAME, "8A4C") },
+		.driver_data = (void *)&omen_v1_legacy_board_params,
+	},
 	{
 		.matches = { DMI_MATCH(DMI_BOARD_NAME, "8A4D") },
 		.driver_data = (void *)&omen_v1_legacy_board_params,

---
base-commit: 9d3475065167197742b0882aff21cf8e78393277
change-id: 20261024-hp-wmi-8a4c-ca5c29a8584a

Best regards,
-- 
Arnaud Ungaro <contact@arnaud-ungaro.fr>

