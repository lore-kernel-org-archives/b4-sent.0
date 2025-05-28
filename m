From: meowmeowbeanz <meowmeowbeanz@gmx.com>
Date: Wed, 28 May 2025 10:56:58 -0700
Subject: [PATCH] ASoC: amd: yc: Add support for Lenovo Yoga 7 16ARP8
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250528-yoga-7-16arp8-microphone-fix-v1-1-bfeed2ecd0c2@gmx.com>
X-B4-Tracking: v=1; b=H4sIAGlON2gC/x3MTQqAIBBA4avIrBsw+6WrRAvRqWaRyghRRHdPW
 n5v8R7IJEwZJvWA0MmZYyioKwVut2EjZF8MRptOd2bEO24WB6x7K2nEg53EtMdAuPKFpAfv2r5
 tSBsoiyRU8r+fl/f9AJXfnF1uAAAA
X-Change-ID: 20250528-yoga-7-16arp8-microphone-fix-e07dc4643e02
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 mario.limonciello@amd.com, alsa-devel@alsa-project.org, 
 meowmeowbeanz <meowmeowbeanz@gmx.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748455029; l=1199;
 i=meowmeowbeanz@gmx.com; s=20250528; h=from:subject:message-id;
 bh=pwC5yCZaXPRUyPuizllISjCOfre1eAHhzXvSoc3WKtk=;
 b=JdOuKTlrwAqDQaZnvlonVdIhlTPvxaOs7dr5et2hG5rqVyEKcXes5mNivLjLvz99mNAPqMp06
 KB/7zo6ufxxBiPBOsw3yUubthEW1aCB2WNPc+VfsoGaaUcvddWrzXJn
X-Developer-Key: i=meowmeowbeanz@gmx.com; a=ed25519;
 pk=gUBt2QAUfouneGh4/++G7dhBBU8WNcaw4woqB/QUV5M=
X-Endpoint-Received: by B4 Relay for meowmeowbeanz@gmx.com/20250528 with auth_id=415
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DMI quirk entry for Lenovo Yoga 7 16ARP8 (83BS) to enable
digital microphone support via ACP driver.

Fixes microphone detection on this specific model which was
previously falling back to non-functional generic audio paths.

Tested-by: meowmeowbeanz <meowmeowbeanz@gmx.com>
Signed-off-by: meowmeowbeanz <meowmeowbeanz@gmx.com>
---
 sound/soc/amd/yc/acp6x-mach.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/soc/amd/yc/acp6x-mach.c b/sound/soc/amd/yc/acp6x-mach.c
index 3d9da93d22ee84914a92cfdc1de7b977dfd3bfa4..7e62445e02c1d0632f5f5e35cf97265f42829ba0 100644
--- a/sound/soc/amd/yc/acp6x-mach.c
+++ b/sound/soc/amd/yc/acp6x-mach.c
@@ -311,6 +311,13 @@ static const struct dmi_system_id yc_acp_quirk_table[] = {
 			DMI_MATCH(DMI_PRODUCT_NAME, "83AS"),
 		}
 	},
+	{
+		.driver_data = &acp6x_card,
+		.matches = {
+			DMI_MATCH(DMI_BOARD_VENDOR, "LENOVO"),
+			DMI_MATCH(DMI_PRODUCT_NAME, "83BS"),
+		}
+	},
 	{
 		.driver_data = &acp6x_card,
 		.matches = {

---
base-commit: 76f8d35964e4de1b464de22e4f3fdc14937ed854
change-id: 20250528-yoga-7-16arp8-microphone-fix-e07dc4643e02

Best regards,
-- 
meowmeowbeanz <meowmeowbeanz@gmx.com>

