From: =?utf-8?q?=E9=83=91=E9=B8=BF=E6=BA=90?= <spark_psc@outlook.com>
Date: Tue, 21 Jul 2026 03:31:58 +0800
Subject: [PATCH] ASoC: amd: yc: Add MSI Crosshair A16 HX D7WFKG to quirk
 table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260721-master-v1-1-6f56d5a54d96@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBCF4avIrA1NIrXWq4iL0Ux1Fo1lRkQI3
 t1olx+8/yVQEiaFtkggtLHyEjNcWcA4Y5zIcMgGb31tX96ZL+pKYt7UVE8XbKgdQh7/hD6830d
 dnz2gkhkE4zhf+SI8cXz8YziOEwUDumB4AAAA
X-Change-ID: 20260721-master-9e8351d0d61a
To: Vijendar Mukunda <Vijendar.Mukunda@amd.com>, 
 Mark Brown <broonie@kernel.org>
Cc: Venkata Prasad Potturu <venkataprasad.potturu@amd.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?=E9=83=91=E9=B8=BF=E6=BA=90?= <spark_psc@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784575921; l=1505;
 i=spark_psc@outlook.com; h=from:subject:message-id;
 bh=sPieR3UZfAQY/O5EmOaFntl04LzU4hXdSmuT+Pa9MUk=;
 b=tcrtQFzYLHt0rPWGpDtA+KzxseW/Lj0w5h1Gllgj12fDIlwnBoI5+A0dcq3wLcgoRi8fl9ltj
 uFXucVuRReGBJSNzfYY1reyukjPc/mC2Gc/sfvkMNIoiQKktRzx63wX
X-Developer-Key: i=spark_psc@outlook.com; a=ed25519;
 pk=2Jj+f2FmVYca2wcyeqtE4uty2ySW1dJ5k3c4Zde3V4Q=
X-Endpoint-Received: by B4 Relay for spark_psc@outlook.com/default with auth_id=886
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MSI Crosshair A16 HX D7WFKG has an internal digital microphone
connected through AMD ACP6x, but the system does not expose the
AcpDmicConnected ACPI property. As a result, acp_yc_mach does not bind
and no DMIC capture device is created.

Add a DMI quirk for this model. This was tested on a system with board
MS-15PL, BIOS E15PLAMS.10B, and AMD ACP6x rev 0x62. After applying the
quirk, the internal microphone appears as an acp6x DMIC capture device
and records correctly.

Signed-off-by: 郑鸿源 <spark_psc@outlook.com>
---
This patch adds a DMI quirk for the MSI Crosshair A16 HX D7WFKG.
The commit message contains the full rationale and test details.
---
 sound/soc/amd/yc/acp6x-mach.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/soc/amd/yc/acp6x-mach.c b/sound/soc/amd/yc/acp6x-mach.c
index d6df7de..3a8a5da 100644
--- a/sound/soc/amd/yc/acp6x-mach.c
+++ b/sound/soc/amd/yc/acp6x-mach.c
@@ -521,6 +521,13 @@ static const struct dmi_system_id yc_acp_quirk_table[] = {
 			DMI_MATCH(DMI_PRODUCT_NAME, "Vector A16 HX A8WHG"),
 		}
 	},
+	{
+		.driver_data = &acp6x_card,
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "Micro-Star International Co., Ltd."),
+			DMI_MATCH(DMI_PRODUCT_NAME, "Crosshair A16 HX D7WFKG"),
+		}
+	},
 	{
 		.driver_data = &acp6x_card,
 		.matches = {

---
base-commit: 1590cf0329716306e948a8fc29f1d3ee87d3989f
change-id: 20260721-master-9e8351d0d61a

Best regards,
-- 
郑鸿源 <spark_psc@outlook.com>

