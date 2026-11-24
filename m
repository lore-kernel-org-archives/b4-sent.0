From: Abhiraj Dutta <abhirajdutta7@gmail.com>
Date: Mon, 23 Nov 2026 21:17:57 -0500
Subject: [PATCH] ALSA: hda/realtek: Fix duplicate LEDs on HP Spectre x360
 16-f2xxx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-hp-spectre-16-f2-led-fix-v1-1-a2a333dceeb5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQqEMAwF0KuEvzZgqnTRqwyz0DbVgGhph0EQ7
 y74DvAuNK2mDYEuVP1bs2NHIOkIcZ32RdkSAsH1zou4gdfCrWj8VWXxnB1vmjjbydOoMswp+jQ
 LOkKpmu1868/3vh9jGemaagAAAA==
X-Change-ID: 20261123-hp-spectre-16-f2-led-fix-a4e13bdc6db1
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: Takashi Iwai <tiwai@suse.de>, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Abhiraj Dutta <abhirajdutta7@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795486735; l=2648;
 i=abhirajdutta7@gmail.com; s=20261122; h=from:subject:message-id;
 bh=2fGkl4MnRAFoBN/vsCmVD26p7qRSOwU1KzcdavldMmo=;
 b=1kMFy9uWM5jo+LSPu7W7mproAH6ITaAgaCkQSMjHlRjCut1TZfqS/EwqzfP6rCT9h0mnMH33E
 pC7f44DbUH+CV0kLKjDvBwBp2dihoZSs/kA5niqvab8+rugJT80i1f6
X-Developer-Key: i=abhirajdutta7@gmail.com; a=ed25519;
 pk=3ETcWPbWUjdsP3Pv+/VwZOZKPt9O4SvxqiXNMNNY4gc=
X-Endpoint-Received: by B4 Relay for abhirajdutta7@gmail.com/20261122 with auth_id=1610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The EU0XXX fixup already sets up the mute and mic-mute LEDs, so chaining
ALC245_FIXUP_HP_X360_MUTE_LEDS after it registers both LEDs twice
(hda::mute_1 and hda::micmute_1 appear). Use the EU0XXX fixup directly.

The original commit message also got the SSID wrong: under SOF the PCI
SSID is 103c:891e, not 103c:0000.

Fixes: e30ec632e1f0 ("ALSA: hda/realtek: Add quirk for HP Spectre x360 2-in-1 Laptop 16-f2xxx")
Cc: stable@vger.kernel.org
Signed-off-by: Abhiraj Dutta <abhirajdutta7@gmail.com>
---
 sound/hda/codecs/realtek/alc269.c | 9 +--------
 1 file changed, 1 insertion(+), 8 deletions(-)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index dfdcf8b98..406524178 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -4524,7 +4524,6 @@ enum {
 	ALC256_FIXUP_HEADPHONE_AMP_VOL,
 	ALC245_FIXUP_HP_SPECTRE_X360_EU0XXX,
 	ALC245_FIXUP_HP_SPECTRE_X360_16_AA0XXX,
-	ALC245_FIXUP_HP_SPECTRE_X360_16_F2XXX,
 	ALC245_FIXUP_HP_ZBOOK_FIREFLY_G12A,
 	ALC285_FIXUP_ASUS_GA403U,
 	ALC285_FIXUP_ASUS_GA403U_HEADSET_MIC,
@@ -7227,12 +7226,6 @@ static const struct hda_fixup alc269_fixups[] = {
 		.type = HDA_FIXUP_FUNC,
 		.v.func = alc245_fixup_hp_spectre_x360_16_aa0xxx,
 	},
-	[ALC245_FIXUP_HP_SPECTRE_X360_16_F2XXX] = {
-		.type = HDA_FIXUP_FUNC,
-		.v.func = alc245_fixup_hp_spectre_x360_eu0xxx,
-		.chained = true,
-		.chain_id = ALC245_FIXUP_HP_X360_MUTE_LEDS
-	},
 	[ALC245_FIXUP_HP_ZBOOK_FIREFLY_G12A] = {
 		.type = HDA_FIXUP_FUNC,
 		.v.func = alc245_fixup_hp_zbook_firefly_g12a,
@@ -7876,7 +7869,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x103c, 0x8902, "HP OMEN 16", ALC285_FIXUP_HP_MUTE_LED),
 	SND_PCI_QUIRK(0x103c, 0x890e, "HP 255 G8 Notebook PC", ALC236_FIXUP_HP_MUTE_LED_COEFBIT2),
 	SND_PCI_QUIRK(0x103c, 0x8919, "HP Pavilion Aero Laptop 13-be0xxx", ALC287_FIXUP_HP_GPIO_LED),
-	SND_PCI_QUIRK(0x103c, 0x891e, "HP Spectre x360 2-in-1 Laptop 16-f2xxx", ALC245_FIXUP_HP_SPECTRE_X360_16_F2XXX),
+	SND_PCI_QUIRK(0x103c, 0x891e, "HP Spectre x360 2-in-1 Laptop 16-f2xxx", ALC245_FIXUP_HP_SPECTRE_X360_EU0XXX),
 	SND_PCI_QUIRK(0x103c, 0x896d, "HP ZBook Firefly 16 G9", ALC245_FIXUP_CS35L41_SPI_2_HP_GPIO_LED),
 	SND_PCI_QUIRK(0x103c, 0x896e, "HP EliteBook x360 830 G9", ALC245_FIXUP_CS35L41_SPI_2_HP_GPIO_LED),
 	SND_PCI_QUIRK(0x103c, 0x8971, "HP EliteBook 830 G9", ALC245_FIXUP_CS35L41_SPI_2_HP_GPIO_LED),

---
base-commit: 896ec6bbe7dd2f29aff1a12eb318a6828be1edd8
change-id: 20261123-hp-spectre-16-f2-led-fix-a4e13bdc6db1

Best regards,
-- 
Abhiraj Dutta <abhirajdutta7@gmail.com>

