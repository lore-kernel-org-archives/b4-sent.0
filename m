From: Fernando Antunez Antonio <fer.antunez24antonio@gmail.com>
Date: Mon, 04 May 2026 07:33:26 -0600
Subject: [PATCH v3] ALSA: hda/realtek: Fix mute and mic-mute LEDs for HP
 Envy X360 15-fh0xxx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260504-hpenvy-muteled-fix-v3-1-5567fd9b3d25@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32Nyw6CMBBFf8V0bU0fUKkr/8O4aMsANbzSQiMh/
 LstblgYl2dy55wVeXAWPLqdVuQgWG+HPgI/n5BpVF8DtmVkxAgTJCcUNyP0YcHdPEELJa7sGwu
 WU62kFNm1QPFxdBDPu/Tx/LKf9QvMlExp0Vg/DW7Zq4Gm3d9AoJjiwkjCgQtSANzrTtn2YoYOp
 UBgRwX7qWBRUVZMKyo115k+KrZt+wBvEKfwCQEAAA==
X-Change-ID: 20260501-hpenvy-muteled-fix-6251ba996478
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fernando Antunez Antonio <fer.antunez24antonio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777901665; l=3093;
 i=fer.antunez24antonio@gmail.com; s=20260501; h=from:subject:message-id;
 bh=VijOgi0WUel34so1SFghTlCssUXe9O1y0V7ZHd+bqck=;
 b=cjwuZfj1kUpW2gwwCduxu0Y0NfM2o7jnrjFnB/tvM1JIK5boMB5tI/EYOCKCBARRvDX74Ox2H
 TD+j0inaKwoBWAwedgAlyDALHQRGTTiZksjHB1lTbtYIgEUXdK6J5OP
X-Developer-Key: i=fer.antunez24antonio@gmail.com; a=ed25519;
 pk=KtAZSzHv34SEFf0i38Wjweb1kiwZdCAcJmQ8koSweKY=
X-Endpoint-Received: by B4 Relay for fer.antunez24antonio@gmail.com/20260501 with auth_id=765
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This enables the mute and mic-mute LEDs on the HP Envy X360 15-fh0xxx
2-in-1 laptops.
The quirk 'ALC245_FIXUP_HP_ENVY_X360_15_FH0XXX' has been created and
is now enabled for this device.

This is my first patch, and I'm still getting to grips with the code,
so there's probably a better way to implement this fix.
I apologize for any inconvenience caused by the constant release of
new versions of this patch.

Signed-off-by: Fernando Antunez Antonio <fer.antunez24antonio@gmail.com>
---
Changes in v3:
- Removed duplicate entry with same PCI SSID
- While previous version used ALC245_FIXUP_HP_X360_MUTE_LEDS to fix
  the mute LEDs, it also rendered the laptop's built-in speakers 
  broken as it lacked the previous ALC287_FIXUP_CS35L41_I2C_2 fixup. 
  A new fixup was created that implements both of them, fixing the 
  mute LEDs and keeping the speaker functionality.
- Link to v2: https://patch.msgid.link/20260502-hpenvy-muteled-fix-v2-1-df2ba19b3b4b@gmail.com

Changes in v2:
- Moved quirk entry to correct position to preserve PCI SSID order
- Removed redundant use of the word Laptop
- Changed subject from SOUND to ALSA
- Link to v1: https://patch.msgid.link/20260501-hpenvy-muteled-fix-v1-1-8c903e3608ee@gmail.com
---
 sound/hda/codecs/realtek/alc269.c | 9 ++++++++-
 1 file changed, 8 insertions(+), 1 deletion(-)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index a9cd03bb73c4..8637f3394f67 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -4123,6 +4123,7 @@ enum {
 	ALC245_FIXUP_CS35L41_I2C_2_MUTE_LED,
 	ALC236_FIXUP_HP_DMIC,
 	ALC256_FIXUP_HONOR_MRB_XXX_M1020_AUDIO,
+	ALC245_FIXUP_HP_ENVY_X360_15_FH0XXX,
 };
 
 /* A special fixup for Lenovo C940 and Yoga Duet 7;
@@ -6675,6 +6676,12 @@ static const struct hda_fixup alc269_fixups[] = {
 			{ 0x1b, 0x90170110 },
 			{ }
 		}
+	},
+	[ALC245_FIXUP_HP_ENVY_X360_15_FH0XXX] = {
+		.type = HDA_FIXUP_FUNC,
+		.v.func = cs35l41_fixup_i2c_two,
+		.chained = true,
+		.chain_id = ALC245_FIXUP_HP_X360_MUTE_LEDS
 	}
 };
 
@@ -7097,7 +7104,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x103c, 0x8be6, "HP Envy 16", ALC287_FIXUP_CS35L41_I2C_2),
 	SND_PCI_QUIRK(0x103c, 0x8be7, "HP Envy 17", ALC287_FIXUP_CS35L41_I2C_2),
 	SND_PCI_QUIRK(0x103c, 0x8be8, "HP Envy 17", ALC287_FIXUP_CS35L41_I2C_2),
-	SND_PCI_QUIRK(0x103c, 0x8be9, "HP Envy 15", ALC287_FIXUP_CS35L41_I2C_2),
+	SND_PCI_QUIRK(0x103c, 0x8be9, "HP Envy x360 2-in-1 Laptop 15-fh0xxx", ALC245_FIXUP_HP_ENVY_X360_15_FH0XXX),
 	SND_PCI_QUIRK(0x103c, 0x8bf0, "HP", ALC236_FIXUP_HP_GPIO_LED),
 	SND_PCI_QUIRK(0x103c, 0x8c15, "HP Spectre x360 2-in-1 Laptop 14-eu0xxx", ALC245_FIXUP_HP_SPECTRE_X360_EU0XXX),
 	SND_PCI_QUIRK(0x103c, 0x8c16, "HP Spectre x360 2-in-1 Laptop 16-aa0xxx", ALC245_FIXUP_HP_SPECTRE_X360_16_AA0XXX),

---
base-commit: f1a5e78a55ebf2b05777fd5eb738038ddae609d6
change-id: 20260501-hpenvy-muteled-fix-6251ba996478

Best regards,
--  
Fernando Antunez <fer.antunez24antonio@gmail.com>

