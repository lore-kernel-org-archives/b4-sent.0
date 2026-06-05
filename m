From: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
Date: Fri, 05 Jun 2026 15:27:21 +0800
Subject: [PATCH] Input: atkbd - skip deactivate for HONOR BCC-N's internal
 keyboard
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-honor-v1-1-78e05e491193@linux.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMwNT3Yz8vPwiXdNk45Rkk5Q0C1PjJCWg2oKi1LTMCrA50bEQfnFpUlZ
 qcglIs1JtLQAqqQSLaQAAAA==
X-Change-ID: 20260605-honor-5c3dc4df853b
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Hans de Goede <hansg@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 zhanjun@uniontech.com, niecheng1@uniontech.com, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 kernel@uniontech.com, Hongfei Ren <lcrhf@outlook.com>, stable@kernel.org, 
 Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780644442; l=1506;
 i=cryolitia.pukngae@linux.dev; s=20260401; h=from:subject:message-id;
 bh=GWUiIg7q9Err0QhQ40mgTt2t3Sl0KinkLwFX/Ry3g3k=;
 b=3OAl+cNxKXdpXzsrO8ofFXw1xxP2uSMpIrDt8MGEXllFFBWRELu6WlslyUCRkHb0lpUhQo8hm
 5bOcE4iV61tAD9Ms2e9tXAeeST76hBwiACVqMoxTvN47Qs4zJBoP4T2
X-Developer-Key: i=cryolitia.pukngae@linux.dev; a=ed25519;
 pk=kF6wBkp7j9167keuk8Q9RvPgMRPuHlJztbLy0vbJ3K0=
X-Endpoint-Received: by B4 Relay for cryolitia.pukngae@linux.dev/20260401 with auth_id=712
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After commit 9cf6e24c9fbf17e52de9fff07f12be7565ea6d61 ("Input: atkbd -
do not skip atkbd_deactivate() when skipping ATKBD_CMD_GETID"), HONOR
BCC-N, aka HONOR MagicBook 14 2026's internal keyboard stops
working. Adding the atkbd_deactivate_fixup quirk fixes it.

DMI: HONOR BCC-N/BCC-N-PCB, BIOS 1.04 04/07/2026

Fixes: 9cf6e24c9fbf17e52de9fff07f12be7565ea6d61 ("Input: atkbd - do not skip atkbd_deactivate() when skipping ATKBD_CMD_GETID")
Reported-by: Hongfei Ren <lcrhf@outlook.com>
Link: https://github.com/colorcube/Linux-on-Honor-Magicbook-14-Pro/issues/1#issuecomment-4562679891
Tested-by: Hongfei Ren <lcrhf@outlook.com>
Cc: stable@kernel.org
Signed-off-by: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
---
 drivers/input/keyboard/atkbd.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/input/keyboard/atkbd.c b/drivers/input/keyboard/atkbd.c
index c8ad55f26ea8..de8edab3cb0f 100644
--- a/drivers/input/keyboard/atkbd.c
+++ b/drivers/input/keyboard/atkbd.c
@@ -1923,6 +1923,13 @@ static const struct dmi_system_id atkbd_dmi_quirk_table[] __initconst = {
 		},
 		.callback = atkbd_deactivate_fixup,
 	},
+	{
+		.matches = {
+			DMI_MATCH(DMI_SYS_VENDOR, "HONOR"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "BCC-N"),
+		},
+		.callback = atkbd_deactivate_fixup,
+	},
 	{ }
 };
 

---
base-commit: ddd664bbff63e09e7a7f9acae9c43605d4cf185f
change-id: 20260605-honor-5c3dc4df853b

Best regards,
--  
Cryolitia PukNgae <cryolitia.pukngae@linux.dev>

