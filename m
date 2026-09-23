From: Nikolay Plastinin <plaztininikolai@gmail.com>
Date: Thu, 24 Sep 2026 01:48:02 +0800
Subject: [PATCH] platform/x86: asus-nb-wmi: add tablet mode quirk for ROG
 Flow X13 GV302X
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-gv302-tablet-v1-1-a45dd3a383f1@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyMT3fQyYwMj3ZLEpJzUEt1UI/NUY0NjA2ODZBMloJaCotS0zAqwcdG
 xtbUASuQIq14AAAA=
X-Change-ID: 20260924-gv302-tablet-e27e313030c4
To: Corentin Chary <corentin.chary@gmail.com>, 
 "Luke D. Jones" <luke@ljones.dev>, Denis Benato <denis.benato@linux.dev>, 
 Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>
Cc: platform-driver-x86@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikolay Plastinin <plaztininikolai@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790185681; l=1659;
 i=plaztininikolai@gmail.com; s=20260924; h=from:subject:message-id;
 bh=2Ot8n3jSdiE6fRQ5ST3n0effn8wymsxPkZc37Zl9lIQ=;
 b=hLVuMgt3i8l2f6hoP50JFAsMhtLPwpCbVCWpiYsD5qHTxs+srgktibcl4J+Loi7tXdpcN6ZGt
 NwSFp2xSTjRCBVKcj5cipRsI3uM3UlFJHAi124wJJLofyIr3J/qGD/J
X-Developer-Key: i=plaztininikolai@gmail.com; a=ed25519;
 pk=bmHrETa14IbiLNkJSoiLqUMni+IeSFwhOSDM4vVFN4s=
X-Endpoint-Received: by B4 Relay for plaztininikolai@gmail.com/20260924 with auth_id=1052
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The 2023 ROG Flow X13 (GV302X*) is a 360-degree convertible like the
GV301, but the existing "GV301" DMI entry does not match it, so the
driver does not register SW_TABLET_MODE and the desktop does not switch
to tablet mode when the screen is folded back.

With asus_nb_wmi.tablet_mode_sw=3 (lid-flip-rog) the "Asus WMI hotkeys"
input device reports SW_TABLET_MODE on every fold and unfold, so apply
quirk_asus_tablet_mode to GV302X* too. Apart from the tablet switch this
quirk is the same as quirk_asus_unknown, which these models get today.

DMI product name of the tested machine: "ROG Flow X13 GV302XV_GV302XV".

Tested on GV302XV.

Signed-off-by: Nikolay Plastinin <plaztininikolai@gmail.com>
---
 drivers/platform/x86/asus-nb-wmi.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/platform/x86/asus-nb-wmi.c b/drivers/platform/x86/asus-nb-wmi.c
index da1ddd601..3b0f3346d 100644
--- a/drivers/platform/x86/asus-nb-wmi.c
+++ b/drivers/platform/x86/asus-nb-wmi.c
@@ -503,6 +503,16 @@ static const struct dmi_system_id asus_quirks[] = {
 		},
 		.driver_data = &quirk_asus_tablet_mode,
 	},
+	{
+		.callback = dmi_matched,
+		.ident = "ASUS ROG FLOW X13",
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "ASUSTeK COMPUTER INC."),
+			/* Match GV302X* */
+			DMI_MATCH(DMI_PRODUCT_NAME, "GV302X"),
+		},
+		.driver_data = &quirk_asus_tablet_mode,
+	},
 	{
 		.callback = dmi_matched,
 		.ident = "ASUS ROG FLOW X16",

---
base-commit: f475845eaf3d749114a63270bf2efea459e14dd2
change-id: 20260924-gv302-tablet-e27e313030c4

Best regards,
-- 
Nikolay Plastinin <plaztininikolai@gmail.com>

