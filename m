From: Samuel Wheeler <swheel33@gmail.com>
Date: Wed, 11 Nov 2026 21:54:27 -0500
Subject: [PATCH 2/2] platform/x86: hp-wmi: Add charge_behaviour quirk for
 OmniBook Ultra 14
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-omnibook-8eb4-v1-2-3127f45cc338@gmail.com>
References: <20261111-omnibook-8eb4-v1-0-3127f45cc338@gmail.com>
In-Reply-To: <20261111-omnibook-8eb4-v1-0-3127f45cc338@gmail.com>
To: Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shang En Sim <sim@shangen.org>, Samuel Wheeler <swheel33@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794452066; l=1792;
 i=swheel33@gmail.com; s=20261112; h=from:subject:message-id;
 bh=3rQb4zPlj81vHDH6Pp13jpcbbVrpCBIEniSdrYQoMtg=;
 b=PruIecKRs9hMdB5lPPcLRHS//QndOA5nh3ZOQuca7TklY/SWlW4q67BbEKQ23VkKn0OJMBMLK
 TDxpOa5VSJcB+ITfWLrSm0ok57jjCUkpJFmJKkkqeBpiLWF6F42kkj1
X-Developer-Key: i=swheel33@gmail.com; a=ed25519;
 pk=cokeT6B31W84o+Gc4wuP2okLF8wShbbGQ7pb5h5JPXg=
X-Endpoint-Received: by B4 Relay for swheel33@gmail.com/20261112 with auth_id=1494
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP OmniBook Ultra Laptop 14-kd0xxx (board 8EB4) implements the same
battery charge mode interface as the Spectre x360 boards supported since
commit 929433336e0a ("platform/x86: hp-wmi: add charge_behaviour support
for Spectre 8C15/8C17").

Reading HPWMI_BATTERY_CHARGE_MODE returns the mode in byte 0
(00 ff 01 ff with automatic charging). The write handler (SBCC in the
SSDT that defines \_SB.WMID) takes the mode from byte 1, accepts values
0-7 and passes it to EC command 0xbb. That matches the layout the driver
already uses.

Add the board to hp_wmi_charge_control_quirks.

Tested on the OmniBook Ultra 14-kd0xxx (BIOS F.06) with AC connected:
writing inhibit-charge to charge_behaviour changes the battery status to
"Not charging" with zero current, and writing auto resumes charging.
force-discharge was not tested.

This patch was prepared with an AI coding assistant (Claude, by
Anthropic). It read the firmware's WMI methods, wrote the change and this
description, and ran the tests on my laptop under my direction. I
reviewed the change and the test results.

Signed-off-by: Samuel Wheeler <swheel33@gmail.com>
---
 drivers/platform/x86/hp/hp-wmi.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/platform/x86/hp/hp-wmi.c b/drivers/platform/x86/hp/hp-wmi.c
index 46c9a5a532ba..bf68a1c46c03 100644
--- a/drivers/platform/x86/hp/hp-wmi.c
+++ b/drivers/platform/x86/hp/hp-wmi.c
@@ -634,6 +634,13 @@ static const struct dmi_system_id hp_wmi_charge_control_quirks[] __initconst = {
 			DMI_MATCH(DMI_BOARD_NAME, "8C15"),
 		},
 	},
+	{
+		/* HP OmniBook Ultra Laptop 14-kd0xxx */
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "HP"),
+			DMI_MATCH(DMI_BOARD_NAME, "8EB4"),
+		},
+	},
 	{}
 };
 #endif

-- 
2.56.0

