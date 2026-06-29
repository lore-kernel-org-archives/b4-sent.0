From: Shubham Nayak <shubhamnayak392reborn@gmail.com>
Date: Mon, 29 Jun 2026 19:04:55 +0530
Subject: [PATCH] ALSA: hda/realtek: Add quirk for HP Victus 16-e0xxx (88EE)
 to enable mute LED
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-hp-victus-16-mute-led-v1-1-ab0f4a8a533b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqEMAxG4atI1ga0YESvIi4k/dXAjEqrRRDvP
 mWW3+K9hyKCIVJfPBSQLNq+ZdRlQbpO2wI2n02uclKJ63g9OJmeV+Ra+Hud4A88Q7t2lkbFKyi
 3R8Bs9/87jO/7A2iTRhdnAAAA
X-Change-ID: 20260629-hp-victus-16-mute-led-ec97f65c6dce
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Shubham Nayak <shubhamnayak392reborn@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782740100; l=1490;
 i=shubhamnayak392reborn@gmail.com; s=20260629; h=from:subject:message-id;
 bh=Qqf8k6jfE2KXdV3i+h3bvmF6ziZnAh3BjiKApx91t8k=;
 b=3h6uuSCkcS9U8ax/2mywgKHAV5otQGMtnuYXT+3jJrY0OuzGHp7+rK+3GuLMryRieVk2h5Vya
 9opf0c5OLFOCGtOfJmNrFT7B1xAo+eA+/a7zp/L0eRCLJMhdMKMfaMm
X-Developer-Key: i=shubhamnayak392reborn@gmail.com; a=ed25519;
 pk=pfvgsrur4oBhDMjTahMVCzHlwIm99bphVOKDDAwksd8=
X-Endpoint-Received: by B4 Relay for shubhamnayak392reborn@gmail.com/20260629 with auth_id=845
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mute LED on the HP Victus 16-e0xxx (board ID 88EE, ALC245 codec)
does not function by default. Add the ALC245_FIXUP_HP_MUTE_LED_COEFBIT
quirk to enable it. Tested on my HP Victus 16-e0xxx with kernel 7.1.2.

Signed-off-by: Shubham Nayak <shubhamnayak392reborn@gmail.com>
---
 sound/hda/codecs/realtek/alc269.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index 21ab891fcb47..9ce143598b66 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -7087,6 +7087,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x103c, 0x88d1, "HP Pavilion 15-eh1xxx (mainboard 88D1)", ALC245_FIXUP_HP_MUTE_LED_V1_COEFBIT),
 	SND_PCI_QUIRK(0x103c, 0x88dd, "HP Pavilion 15z-ec200", ALC285_FIXUP_HP_MUTE_LED),
 	SND_PCI_QUIRK(0x103c, 0x88eb, "HP Victus 16-e0xxx", ALC245_FIXUP_HP_MUTE_LED_V2_COEFBIT),
+	SND_PCI_QUIRK(0x103c, 0x88ee, "HP Victus 16-e0xxx (MB 88EE)", ALC245_FIXUP_HP_MUTE_LED_COEFBIT),
 	SND_PCI_QUIRK(0x103c, 0x8902, "HP OMEN 16", ALC285_FIXUP_HP_MUTE_LED),
 	SND_PCI_QUIRK(0x103c, 0x890e, "HP 255 G8 Notebook PC", ALC236_FIXUP_HP_MUTE_LED_COEFBIT2),
 	SND_PCI_QUIRK(0x103c, 0x8919, "HP Pavilion Aero Laptop 13-be0xxx", ALC287_FIXUP_HP_GPIO_LED),

---
base-commit: bcb8896e30a3cd684af57a16df0111f4ab4baf59
change-id: 20260629-hp-victus-16-mute-led-ec97f65c6dce

Best regards,
-- 
Shubham Nayak <shubhamnayak392reborn@gmail.com>

