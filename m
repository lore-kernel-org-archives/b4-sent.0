From: Arnaud Ungaro <contact@arnaud-ungaro.fr>
Date: Sat, 24 Oct 2026 22:39:28 +0200
Subject: [PATCH] platform/x86: hp-wmi: Handle cTGP left enabled after the
 EC timer expires
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261024-hp-wmi-rechargement-v1-1-45d9f8447f41@arnaud-ungaro.fr>
X-B4-Tracking: v=1; b=H4sIAIAX3WoC/x2MSQqAMAwAvyI5G2iDC/Ur4sElag6tkooK4t8tH
 odh5oHIKhyhyR5QPiXKFhLYPINx7cPCKFNiIEOVNVTguuPlBZWT1oU9hwOdKa2leaodDZDKXXm
 W+7+23ft+KYUVYWUAAAA=
X-Change-ID: 20261024-hp-wmi-rechargement-905112fd792b
To: =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Hans de Goede <hansg@kernel.org>
Cc: linux-kernel@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 Krishna Chomal <krishna.chomal108@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792874368; l=2857;
 i=contact@arnaud-ungaro.fr; s=20261024; h=from:subject:message-id;
 bh=WHIOpMJQcoqQDNURmL6QodtJb2QRPTimKwNCf0bbr9Y=;
 b=jzG7e2xlatCWljfyicjvPSKBNNYWStHl0T3eT+3A+N33CDoLr4io5myHUsV1ZU1TIOQc7hVQ1
 E98jQfhfZGsCd1GsRJJG87w2Zn5whxyljqrOoE+ypZTY3M61wRHaDbr
X-Developer-Key: i=contact@arnaud-ungaro.fr; a=ed25519;
 pk=E36DBHlmRhVNV3rriuNdMXwzVy3fGJ5rWE/saD1H0XU=
X-Endpoint-Received: by B4 Relay for contact@arnaud-ungaro.fr/20261024 with auth_id=1313
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Board 8A4C uses omen_v1_legacy_board_params. About two minutes after
switching to performance the EC moves the thermal profile in register
0x95 back to its default value while cTGP and PPAB stay enabled. The
same fallback is reported on 8A4D in the bugzilla entry linked below.

platform_profile_victus_s_get_ec() returns -EINVAL for this state
because it only accepts the default thermal profile with cTGP disabled.
If hp-wmi is loaded again at that point thermal_profile_setup() fails
and no platform profile is registered. The power source event handler
also fails to read the profile in that state.

Read this state as balanced since this is what the EC thermal profile
says. thermal_profile_setup() then sets balanced again and this
disables cTGP to match.

Tested on an OMEN 16-k0001nf (board 8A4C, BIOS F.21) with kernel 7.2.9.
Unloading and loading hp-wmi after the EC timer expired registered the
platform profile again. Without this change
/sys/firmware/acpi/platform_profile was missing and in my test it only
came back after a reboot.

Link: https://bugzilla.kernel.org/show_bug.cgi?id=221680
Fixes: eeeb4c9874bb ("platform/x86: hp-wmi: Add EC offsets to read Victus S thermal profile")
Cc: stable@vger.kernel.org
Signed-off-by: Arnaud Ungaro <contact@arnaud-ungaro.fr>
---
Found while adding board 8A4C (OMEN 16-k0001nf). That patch is sent
separately.

Tested on the laptop with 7.2.9. The change also applies to 7.0.14,
7.1.13, 7.2.12 and 7.3. They all have the code from the Fixes commit.
---
 drivers/platform/x86/hp/hp-wmi.c | 12 +++++++++---
 1 file changed, 9 insertions(+), 3 deletions(-)

diff --git a/drivers/platform/x86/hp/hp-wmi.c b/drivers/platform/x86/hp/hp-wmi.c
index 52077833ac89d3f4bd9b99fbbc1812c4f09d16c7..699531157b5e8b002b28a3669acb33b7223cee75 100644
--- a/drivers/platform/x86/hp/hp-wmi.c
+++ b/drivers/platform/x86/hp/hp-wmi.c
@@ -2414,12 +2414,18 @@ static int platform_profile_victus_s_get_ec(enum platform_profile_option *profil
 						       &current_gpu_slowdown_temp);
 		if (ret < 0)
 			return ret;
-		if (current_ctgp_state == 0 && current_ppab_state == 0)
+		if (current_ctgp_state == 0 && current_ppab_state == 0) {
 			*profile = PLATFORM_PROFILE_LOW_POWER;
-		else if (current_ctgp_state == 0 && current_ppab_state == 1)
+		} else if (current_ppab_state == 1) {
+			/*
+			 * cTGP stays enabled when the EC thermal profile timer
+			 * drops performance back to default, so treat it as
+			 * balanced, which the caller can set again.
+			 */
 			*profile = PLATFORM_PROFILE_BALANCED;
-		else
+		} else {
 			return -EINVAL;
+		}
 	} else {
 		return -EINVAL;
 	}

---
base-commit: 9d3475065167197742b0882aff21cf8e78393277
change-id: 20261024-hp-wmi-rechargement-905112fd792b

Best regards,
-- 
Arnaud Ungaro <contact@arnaud-ungaro.fr>

