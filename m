From: Abhiraj Dutta <abhirajdutta7@gmail.com>
Date: Sun, 22 Nov 2026 17:02:47 -0500
Subject: [PATCH] ALSA: hda/realtek: Add quirk for HP Spectre x360 2-in-1
 Laptop 16-f2xxx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-hp-spectre-16-f2-quirk-v1-1-2011ef8986fb@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MWwqDQAwF0K2E+21gJoqlsxXxw0fUULDTTFsK4
 t4LngWcA0XdtCDRAdevFXvuSBQrwrQN+6psMxJBgrQxivCWuWSd3q4cW16EXx/zB9cS7vUwhlG
 bGypCdl3sd8Vdf55/a7O4mmgAAAA=
X-Change-ID: 20261122-hp-spectre-16-f2-quirk-32093ab0be47
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Abhiraj Dutta <abhirajdutta7@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795384986; l=2863;
 i=abhirajdutta7@gmail.com; s=20261122; h=from:subject:message-id;
 bh=TXikiVOH5pXwin/sZNAkTdAEDOogwSuDt60eoDtzQoQ=;
 b=Y/iIqrnriFOBEFhC8p5oXoBVoBkZdkL8qjhZMBoFtLIqLBvyv+nXgaUnwf8827IvXQzQ0olnZ
 P+GxCMHAkPjCS2iVLQg4vNwk4/W+0BRyKSI+AwY8aLfuwXpPpMr3/so
X-Developer-Key: i=abhirajdutta7@gmail.com; a=ed25519;
 pk=3ETcWPbWUjdsP3Pv+/VwZOZKPt9O4SvxqiXNMNNY4gc=
X-Endpoint-Received: by B4 Relay for abhirajdutta7@gmail.com/20261122 with auth_id=1610
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The HP Spectre x360 16-f2xxx (SSID 103c:891e) has the same speaker
problem as the 14-eu0xxx and 16-aa0xxx: the BIOS marks the treble
speaker pin 0x14 as unconnected, so only the bass speakers on 0x17
play. The mute and mic-mute LEDs don't work either.

Use the existing EU0XXX pin fixup and chain ALC245_FIXUP_HP_X360_MUTE_LEDS.
The mute LED is on COEF 0x0b bits 2-3 and the mic-mute LED on GPIO2
(active low), which is what that fixup already handles. Unlike the
16-aa0xxx, the bass speaker amp works without toggling GPIO0, so the
EU0XXX variant is enough.

Under SOF the PCI SSID on this machine reads as 103c:0000, so the entry
is matched against the codec SSID.

Tested on a 16-f2xxx: all four speakers play and both LEDs follow the
mute state.

Cc: stable@vger.kernel.org
Signed-off-by: Abhiraj Dutta <abhirajdutta7@gmail.com>
---
 sound/hda/codecs/realtek/alc269.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index d38be4d50..edfd5ebe8 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -4524,6 +4524,7 @@ enum {
 	ALC256_FIXUP_HEADPHONE_AMP_VOL,
 	ALC245_FIXUP_HP_SPECTRE_X360_EU0XXX,
 	ALC245_FIXUP_HP_SPECTRE_X360_16_AA0XXX,
+	ALC245_FIXUP_HP_SPECTRE_X360_16_F2XXX,
 	ALC245_FIXUP_HP_ZBOOK_FIREFLY_G12A,
 	ALC285_FIXUP_ASUS_GA403U,
 	ALC285_FIXUP_ASUS_GA403U_HEADSET_MIC,
@@ -7226,6 +7227,12 @@ static const struct hda_fixup alc269_fixups[] = {
 		.type = HDA_FIXUP_FUNC,
 		.v.func = alc245_fixup_hp_spectre_x360_16_aa0xxx,
 	},
+	[ALC245_FIXUP_HP_SPECTRE_X360_16_F2XXX] = {
+		.type = HDA_FIXUP_FUNC,
+		.v.func = alc245_fixup_hp_spectre_x360_eu0xxx,
+		.chained = true,
+		.chain_id = ALC245_FIXUP_HP_X360_MUTE_LEDS
+	},
 	[ALC245_FIXUP_HP_ZBOOK_FIREFLY_G12A] = {
 		.type = HDA_FIXUP_FUNC,
 		.v.func = alc245_fixup_hp_zbook_firefly_g12a,
@@ -7869,6 +7876,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x103c, 0x8902, "HP OMEN 16", ALC285_FIXUP_HP_MUTE_LED),
 	SND_PCI_QUIRK(0x103c, 0x890e, "HP 255 G8 Notebook PC", ALC236_FIXUP_HP_MUTE_LED_COEFBIT2),
 	SND_PCI_QUIRK(0x103c, 0x8919, "HP Pavilion Aero Laptop 13-be0xxx", ALC287_FIXUP_HP_GPIO_LED),
+	SND_PCI_QUIRK(0x103c, 0x891e, "HP Spectre x360 2-in-1 Laptop 16-f2xxx", ALC245_FIXUP_HP_SPECTRE_X360_16_F2XXX),
 	SND_PCI_QUIRK(0x103c, 0x896d, "HP ZBook Firefly 16 G9", ALC245_FIXUP_CS35L41_SPI_2_HP_GPIO_LED),
 	SND_PCI_QUIRK(0x103c, 0x896e, "HP EliteBook x360 830 G9", ALC245_FIXUP_CS35L41_SPI_2_HP_GPIO_LED),
 	SND_PCI_QUIRK(0x103c, 0x8971, "HP EliteBook 830 G9", ALC245_FIXUP_CS35L41_SPI_2_HP_GPIO_LED),

---
base-commit: d1458f8c2282975f2bd7467cd3c3cf4c0c58c1ca
change-id: 20261122-hp-spectre-16-f2-quirk-32093ab0be47

Best regards,
-- 
Abhiraj Dutta <abhirajdutta7@gmail.com>

