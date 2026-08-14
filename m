From: Christian Wehba <weebnuts@hotmail.com>
Date: Fri, 14 Aug 2026 21:29:28 +1000
Subject: [PATCH] ALSA: hda/realtek: Match Lenovo Yoga Slim 7 14AKP10 by
 codec SSID
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-alc287-akp10-v1-1-60b3d619f72d@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Nj3cScZCMLc93E7AJDA92kZAODZEPTRPPEVAMloJaCotS0zAqwcdG
 xtbUAR7xwk14AAAA=
X-Change-ID: 20260813-alc287-akp10-bc00c15a7ae0
To: linux-sound@vger.kernel.org
Cc: stable@vger.kernel.org, Christian Wehba <weebnuts@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786706967; l=4514;
 i=weebnuts@hotmail.com; h=from:subject:message-id;
 bh=XN40BnZnWOGYHA+7GO2mZkGtsNIWrNdk7lHPf86eDyM=;
 b=HPrXYTWO2VzjjGrDZRPQMPUjEVwkWHxQrAvdIwKXMyiJ7R8iiH4SDjhiDgMDp78qAk6QtdLIR
 l7Kgz9njSpqAYYu2Dmw8dZZP5NBx5QQEi3u+Asez6suw/GIHHCafcsI
X-Developer-Key: i=weebnuts@hotmail.com; a=ed25519;
 pk=x+EJ28Iu4dCXlGo0o5ZYbAdHluOsP4d5LHGiwTLloZI=
X-Endpoint-Received: by B4 Relay for weebnuts@hotmail.com/default with auth_id=948
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit e6c888202297 ("ALSA: hda/realtek: Add quirk for Lenovo Yoga Slim
7 14AKP10") added an entry for 17aa:391a using SND_PCI_QUIRK, so it is
only tested against the PCI SSID. On this machine 0x391a is the codec
SSID; the PCI SSID is 17aa:38b4, which is shared with the Legion Slim 7
16IRH8.

snd_hda_pick_fixup() walks the quirk table in order and returns on the
first match, so the earlier 17aa:38b4 entry wins and the codec-SSID
fallback at the end of the function is never reached:

  snd_hda_codec_alc269 hdaudioC1D0: ALC287: picked fixup  for PCI SSID 17aa:38b4

The machine consequently gets ALC287_FIXUP_CS35L41_I2C_2 even though it
has no CS35L41 amplifiers, and the intended fixup never runs. Its bass
speakers hang off pin 0x17, which the BIOS reports as unconnected, so
only the tweeters on pin 0x14 are driven and playback is very quiet.

Convert the entry to HDA_CODEC_QUIRK and move it ahead of the colliding
17aa:38b4 entry so that it is evaluated first. With
ALC287_FIXUP_YOGA9_14IAP7_BASS_SPK_PIN applied, pin 0x17 is enabled and
both 0x14 and 0x17 are bound to DAC 0x02, so a single "Speaker Playback
Volume" drives both speaker pairs:

  autoconfig for ALC287: line_outs=2 (0x14/0x17/0x0/0x0/0x0) type:speaker

Verified on a Yoga Slim 7 14AKP10 by forcing the same fixup with
model=alc287-yoga9-bass-spk-pin, which restores full volume and keeps
the volume control effective across its whole range.

Note that the existing 17aa:391c and 17aa:391d entries are likewise
placed after the 17aa:38b4 entry; should those machines also report PCI
SSID 17aa:38b4 they would need the same reordering, but that could not
be confirmed here for lack of the hardware.

Fixes: e6c888202297 ("ALSA: hda/realtek: Add quirk for Lenovo Yoga Slim 7 14AKP10")
Link: https://bugzilla.kernel.org/show_bug.cgi?id=221298
Cc: stable@vger.kernel.org
Signed-off-by: Christian Wehba <weebnuts@hotmail.com>
---
Single patch; the full analysis is in the commit message.

Tested on a Lenovo Yoga Slim 7 14AKP10 (AMD, ALC287) running 7.1.7 on
Fedora 44. Without the change the machine matches the Legion Slim 7
16IRH8 entry on PCI SSID 17aa:38b4 and gets ALC287_FIXUP_CS35L41_I2C_2
despite having no CS35L41 amplifiers; only the tweeters on pin 0x14 are
driven, so playback is very quiet. With the fixup applied both speaker
pairs are driven and the volume control stays effective across its whole
range.

Reported and tracked at:
https://bugzilla.kernel.org/show_bug.cgi?id=221298
---
 sound/hda/codecs/realtek/alc269.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index be7287ea2..488293612 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -8069,6 +8069,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x17aa, 0x38a8, "Y780P AMD VECO dual", ALC287_FIXUP_TAS2781_I2C),
 	SND_PCI_QUIRK(0x17aa, 0x38a9, "Thinkbook 16P", ALC287_FIXUP_MG_RTKC_CSAMP_CS35L41_I2C_THINKPAD),
 	SND_PCI_QUIRK(0x17aa, 0x38ab, "Thinkbook 16P", ALC287_FIXUP_MG_RTKC_CSAMP_CS35L41_I2C_THINKPAD),
+	HDA_CODEC_QUIRK(0x17aa, 0x391a, "Lenovo Yoga Slim 7 14AKP10", ALC287_FIXUP_YOGA9_14IAP7_BASS_SPK_PIN),
 	SND_PCI_QUIRK(0x17aa, 0x38b4, "Legion Slim 7 16IRH8", ALC287_FIXUP_CS35L41_I2C_2),
 	HDA_CODEC_QUIRK(0x17aa, 0x391c, "Lenovo Yoga 7 2-in-1 14AKP10", ALC287_FIXUP_YOGA9_14IAP7_BASS_SPK_PIN),
 	HDA_CODEC_QUIRK(0x17aa, 0x391d, "Lenovo Yoga 7 2-in-1 16AKP10", ALC287_FIXUP_YOGA9_14IAP7_BASS_SPK_PIN),
@@ -8117,7 +8118,6 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x17aa, 0x3911, "Lenovo Yoga Pro 7 14IAH10", ALC287_FIXUP_YOGA9_14IAP7_BASS_SPK_PIN),
 	SND_PCI_QUIRK(0x17aa, 0x3912, "Lenovo Xiaoxin 14 GT", ALC287_FIXUP_YOGA9_14IAP7_BASS_SPK_PIN),
 	SND_PCI_QUIRK(0x17aa, 0x3913, "Lenovo 145", ALC236_FIXUP_LENOVO_INV_DMIC),
-	SND_PCI_QUIRK(0x17aa, 0x391a, "Lenovo Yoga Slim 7 14AKP10", ALC287_FIXUP_YOGA9_14IAP7_BASS_SPK_PIN),
 	SND_PCI_QUIRK(0x17aa, 0x391f, "Yoga S990-16 pro Quad YC Quad", ALC287_FIXUP_TXNW2781_I2C),
 	SND_PCI_QUIRK(0x17aa, 0x3920, "Yoga S990-16 pro Quad VECO Quad", ALC287_FIXUP_TXNW2781_I2C),
 	SND_PCI_QUIRK(0x17aa, 0x3929, "Thinkbook 13x Gen 5", ALC287_FIXUP_MG_RTKC_CSAMP_CS35L41_I2C_THINKPAD),

---
base-commit: f42eb0bd059781dc7f3046c7d37e76f59b874744
change-id: 20260813-alc287-akp10-bc00c15a7ae0

Best regards,
-- 
Christian Wehba <weebnuts@hotmail.com>

