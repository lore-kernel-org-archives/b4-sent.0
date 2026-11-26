From: Felipe Pesce <coding@fpesce.com>
Date: Thu, 26 Nov 2026 13:41:46 -0300
Subject: [PATCH] ALSA: hda/cirrus: Control SPDIF out pin on MacBookPro 11,1
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-macbookpro11-1-spdif-v1-1-8316370457f8@fpesce.com>
X-B4-Tracking: v=1; b=H4sIAElhCGsC/x3MTQrCMBBA4auUWTvoRJKCVxEX+Zm0gzQJExGh9
 O5Gl9/ivR06q3CH27SD8lu61DJApwni6svCKGkYzMU4IuNw8zHU+mxaiZCwtyQZ3TXYNFv2ds4
 w0qac5fPf3h/DwXfGoL7E9TerKouU8+b7ixWO4wuOkJ4khgAAAA==
X-Change-ID: 20261126-macbookpro11-1-spdif-63b5d75ea57f
To: Takashi Iwai <tiwai@suse.com>, Jaroslav Kysela <perex@perex.cz>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Felipe Pesce <coding@fpesce.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795711305; l=1846;
 i=coding@fpesce.com; s=20261126; h=from:subject:message-id;
 bh=aXC3IyVGZ218SrwScWZYu42Cdp/Cm3nySQ3+C2EcmKw=;
 b=iMepBdKxNB1cmw4S796X9Ifw/WumI8mu62kXExFL4hHOpT38pMgmSjyE23TM0pMDfcNawrTH8
 yshixN97rbkDAvAbKcXtnVrNlQ644MwPqsFdRNuNRO7IJ2M5CK0MNQo
X-Developer-Key: i=coding@fpesce.com; a=ed25519;
 pk=cQ6L0+gycqDMWGyg+5rl+808vU//qlaPY0zjUWM2Two=
X-Endpoint-Received: by B4 Relay for coding@fpesce.com/20261126 with auth_id=1655
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MacBookPro 11,1 (CS4208, codec SSID 0x106b5d00) has the same
combo headphone / mini-TOSLINK jack as the MacBookPro 11,2, but is
missing from cs4208_mac_fixup_tbl, so it only gets the default GPIO0
fixup. As a result the "IEC958 Playback Switch" does not touch the
SPDIF pin (0x21), whose pin control stays at PIN_OUT, and the red
optical light in the jack turns on whenever the codec is powered up,
even with no optical cable plugged in.

Apply the CS4208_MBP11 fixup to this model as well. Tested with
model=mbp11 on a MacBookPro11,1: turning off the IEC958 switch now
clears the pin control and the light stays off across runtime
suspend/resume, while analog headphone, speaker and mic are
unaffected.

Signed-off-by: Felipe Pesce <coding@fpesce.com>
---
The codec SSID was read from /sys/class/sound/hwC1D0/subsystem_id on a
MacBookPro11,1 (DMI product_name) running Debian 6.12.
---
 sound/hda/codecs/cirrus/cs420x.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/hda/codecs/cirrus/cs420x.c b/sound/hda/codecs/cirrus/cs420x.c
index 85c2ecf46d3834984d17bc8c67b274ac1938502c..160c4e10714e81fb4de0a25e4835c4387f184c39 100644
--- a/sound/hda/codecs/cirrus/cs420x.c
+++ b/sound/hda/codecs/cirrus/cs420x.c
@@ -576,6 +576,7 @@ static const struct hda_quirk cs4208_fixup_tbl[] = {
 
 /* codec SSID matching */
 static const struct hda_quirk cs4208_mac_fixup_tbl[] = {
+	SND_PCI_QUIRK(0x106b, 0x5d00, "MacBookPro 11,1", CS4208_MBP11),
 	SND_PCI_QUIRK(0x106b, 0x5e00, "MacBookPro 11,2", CS4208_MBP11),
 	SND_PCI_QUIRK(0x106b, 0x6c00, "MacMini 7,1", CS4208_MACMINI),
 	SND_PCI_QUIRK(0x106b, 0x7100, "MacBookAir 6,1", CS4208_MBA6),

---
base-commit: 40212b29a6f718d4e7fb3275cede181cb8e137cf
change-id: 20261126-macbookpro11-1-spdif-63b5d75ea57f

Best regards,
-- 
Felipe Pesce <coding@fpesce.com>

