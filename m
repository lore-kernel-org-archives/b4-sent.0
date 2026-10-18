From: George Christidis <gxristidis@gmail.com>
Date: Sun, 18 Oct 2026 18:56:31 +0200
Subject: [PATCH] ALSA: hda/realtek: Fix headset mic on ASUS Zenbook 14
 UX3402VA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261018-for-linus-v1-1-4d8e9ff27d89@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM0QpAMBSA4VfRubbaVkZeRS6MM4402jEpeXfD5
 Vd//wWMgZChzi4IeBDT6hNUnkE/dX5EQUMyaKmNkqoSbg1iIR9ZaGt1aWRnC2cg9VtAR+f3atr
 fHO2M/f4O4L4f5zB/zG0AAAA=
X-Change-ID: 20261018-for-linus-2bb2760ab5f6
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, George Christidis <gxristidis@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792342594; l=1568;
 i=gxristidis@gmail.com; s=20261018; h=from:subject:message-id;
 bh=WO42s5RZ6hbZHX1anwLnUs6RiGT8aq0KXyrmR3Fn9vI=;
 b=QgWJrj9Qpp1fCpRoh16U+axun5rMtlsLJ/obgxrMZptprt+QU8kMl0U/dMuYYg3D9Y0nsg0hy
 p0h9w83tomhAJA7xDeWYteWFx+8QV5fZZetdGYyjRhH+OnU7W0ftD9Q
X-Developer-Key: i=gxristidis@gmail.com; a=ed25519;
 pk=LWp/LBe13KlT/70ZpW3a73MV3ESP4a0DmOo2Zrz0Dhg=
X-Endpoint-Received: by B4 Relay for gxristidis@gmail.com/20261018 with auth_id=1227
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The UX3402VA (1043:16a3) BIOS leaves pin 0x19 unconfigured, so the
headset mic does not work. Use ALC294_FIXUP_ASUS_SPI_HEADSET_MIC like
the UX3405MA, it sets up the mic and keeps the CS35L41 speaker fixup.

Tested on a UX3402VA: headset mic, internal mic and speakers work.

Cc: stable@vger.kernel.org
Signed-off-by: George Christidis <gxristidis@gmail.com>
---
 sound/hda/codecs/realtek/alc269.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index 1623cf926..cea8c7091 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -7867,7 +7867,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x1043, 0x1663, "ASUS GU603ZI/ZJ/ZQ/ZU/ZV", ALC285_FIXUP_ASUS_HEADSET_MIC),
 	SND_PCI_QUIRK(0x1043, 0x1664, "ASUS ExpertBook PM3406CHA", ALC256_FIXUP_ASUS_PM3406CHA),
 	SND_PCI_QUIRK(0x1043, 0x1683, "ASUS UM3402YAR", ALC287_FIXUP_CS35L41_I2C_2),
-	SND_PCI_QUIRK(0x1043, 0x16a3, "ASUS UX3402VA", ALC245_FIXUP_CS35L41_SPI_2),
+	SND_PCI_QUIRK(0x1043, 0x16a3, "ASUS UX3402VA", ALC294_FIXUP_ASUS_SPI_HEADSET_MIC),
 	SND_PCI_QUIRK(0x1043, 0x16b2, "ASUS GU603", ALC289_FIXUP_ASUS_GA401),
 	SND_PCI_QUIRK(0x1043, 0x16d3, "ASUS UX5304VA", ALC245_FIXUP_CS35L41_SPI_2),
 	SND_PCI_QUIRK(0x1043, 0x16e3, "ASUS UX50", ALC269_FIXUP_STEREO_DMIC),

---
base-commit: 8e8cd9a4c6dc006e9bd51b8ad0079fb4576b48d3
change-id: 20261018-for-linus-2bb2760ab5f6

Best regards,
--  
George Christidis <gxristidis@gmail.com>

