From: the-catman <thecatman12@proton.me>
Date: Wed, 25 Nov 2026 10:39:00 +0200
Subject: [PATCH] platform/x86: hp-wmi: Add support for HP OMEN 16-ae0xxx
 (8CC0)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-master-v1-1-e1d881b3b9d6@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6DIBCF4auYWZcE0EHwKsbFOI4tC7UF2zQx3
 r2kLr+Xl/+ALClKhq46IMkn5ritBeZWAT9ovYuKUzFYbZ0xFtVCeZek2nacfe1YkBjK+Zlkjt9
 /qB8uJ3m9S2+/Rhgpi+JtWeLeVc6wnogD2jHU2nvfhNpNGpkltOiQkH2guYHhPH9WGe7dpAAAA
 A==
X-Change-ID: 20261125-master-77bf836ce5ac
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 the-catman <thecatman12@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795595939; l=2098;
 i=thecatman12@proton.me; s=20261125; h=from:subject:message-id;
 bh=M0yFpvmo2x5mUnBrp9FOVjlBIXzYzVqyJCYqNxofh8c=;
 b=65A/lvkz+js5Gg3beosykTNyR3Ezg/8o30lRw64I7BgvJAbFbG0IRJBylL04uuRt0TOhQK1s0
 TqV2K+kTh2tC/7Wgmsc80rd1llV/Sz51l6eHwfDEGVcOGONyhFsgy6d
X-Developer-Key: i=thecatman12@proton.me; a=ed25519;
 pk=JZyk9fkPTWRMiA5uAyXbspvMRf6+lV/HhmhAgXXUfNs=
X-Endpoint-Received: by B4 Relay for thecatman12@proton.me/20261125 with auth_id=1635
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP OMEN 16-ae0xxx (board ID 8CC0) has the same WMI interface as
other Victus S boards, but requires quirks for correctly switching
thermal profile (similar to HP Omen 16-wf1xxx, board ID 8C78).

Without an entry, the driver falls back to the generic HP thermal
profile path, whose query fails on this board
("hp_wmi: query 0x4c returned error 0x6"), so no platform profile is
registered and the EC can't be switched out of its default mode from
Linux.

Add the DMI board name to the hp_wmi_feature_boards[] table and map it
to omen_v1_board_params.

Tested on an HP OMEN 16-ae0xxx (i7-14700HX, RTX 4070 Laptop GPU,
BIOS F.14): the platform profile registers with low-power, balanced
and performance, the profile read back from the EC matches the
selected one, fan RPMs are readable, and switching profiles changes
the CPU power limits programmed by the firmware (MSR PL1/PL2 of
55/130 W in low-power and balanced, 130/130 W in performance).

Signed-off-by: the-catman <thecatman12@proton.me>
---
Tested on Ubuntu's 7.0.0-44 kernel with the equivalent pre-rework entry
(victus_s_thermal_profile_boards[] -> omen_v1_thermal_params), which
matches what omen_v1_board_params selects in for-next.
---
 drivers/platform/x86/hp/hp-wmi.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/platform/x86/hp/hp-wmi.c b/drivers/platform/x86/hp/hp-wmi.c
index 16cfac5..376e8a1 100644
--- a/drivers/platform/x86/hp/hp-wmi.c
+++ b/drivers/platform/x86/hp/hp-wmi.c
@@ -325,6 +325,10 @@ static const struct dmi_system_id hp_wmi_feature_boards[] __initconst = {
 		.matches = { DMI_MATCH(DMI_BOARD_NAME, "8C9C") },
 		.driver_data = (void *)&victus_s_board_params,
 	},
+	{
+		.matches = { DMI_MATCH(DMI_BOARD_NAME, "8CC0") },
+		.driver_data = (void *)&omen_v1_board_params,
+	},
 	{
 		.matches = { DMI_MATCH(DMI_BOARD_NAME, "8D26") },
 		.driver_data = (void *)&omen_v1_legacy_board_params,

---
base-commit: 61c0dac952b9308884936d05cce97565a5c89af4
change-id: 20261125-master-77bf836ce5ac

Best regards,
-- 
the-catman <thecatman12@proton.me>

