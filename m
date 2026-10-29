From: Chris Simpson <chris@nilk.net>
Date: Thu, 29 Oct 2026 16:49:10 -0600
Subject: [PATCH] ALSA: hda/realtek: Enable bass speakers on Alienware m17
 R3
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261029-alc289-m17r3-v1-1-5d3eac605e7a@nilk.net>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNL3cScZCMLS91cQ/MiY10DM4OUNFNTo9QUs2QloJaCotS0zAqwcdG
 xtbUAunRM9F4AAAA=
X-Change-ID: 20261029-alc289-m17r3-060df552ed6c
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Chris Simpson <chris@nilk.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793314173; l=2233;
 i=chris@nilk.net; s=20261017; h=from:subject:message-id;
 bh=ycvtrC06Uil7aW797VPCQ/Tcavwuyu8NiwvTlrPUnEY=;
 b=bsPkcmM+rMoWnu0/mTFOhvR034Ln0vgNgWzFV/cvfosNMVxuSmLvL3HBnVCuiYw7lmbs5BMM1
 LkhMTOXutN2ArQEomfa7LREKeAOZ87ZYaKrlp1qHVmYI3PdAsqIst9M
X-Developer-Key: i=chris@nilk.net; a=ed25519;
 pk=bwNSTJdm8iKtfcCRqyaQFQFlAxLuiAxLw4pMXey4Z+o=
X-Endpoint-Received: by B4 Relay for chris@nilk.net/20261017 with auth_id=1225
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Alienware m17 R3 (ALC289, PCI SSID 1028:09d1) has a second speaker
pair, the bass speakers, on pin 0x17, which the BIOS leaves unconnected
(0x411111f0). No PCI SSID quirk matches the machine, so it gets
ALC269_FIXUP_DELL4_MIC_NO_PRESENCE from the fallback pin quirk table,
and only the speakers on pin 0x14 play.

Use ALC289_FIXUP_DUAL_SPK, as on the Alienware x16 R2 and Dell XPS 15
9510/9520: it sets pin 0x17 up as a speaker on DAC 0x02, so one volume
control covers both pairs, and chains to
ALC269_FIXUP_DELL4_MIC_NO_PRESENCE, so the headset mic setup is
unchanged.

Tested on an Alienware m17 R3 (BIOS 1.38.0), Linux 7.3 with this change
applied: the bass speakers play, and volume and mute cover both pairs,
also after suspend and resume. Headphones and a headset mic were not
tested.

I used Claude Code (Claude Opus 5.5) to find the unused pin, pick the
existing fixup and write this patch and changelog; I did the listening
tests myself.

Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Chris Simpson <chris@nilk.net>
---
ALSA: hda/realtek: Enable bass speakers on Alienware m17 R3
---
 sound/hda/codecs/realtek/alc269.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index 23329d588..145db479f 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -7594,6 +7594,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x1028, 0x097e, "Dell Precision", ALC289_FIXUP_DUAL_SPK),
 	SND_PCI_QUIRK(0x1028, 0x098d, "Dell Precision", ALC233_FIXUP_ASUS_MIC_NO_PRESENCE),
 	SND_PCI_QUIRK(0x1028, 0x09bf, "Dell Precision", ALC233_FIXUP_ASUS_MIC_NO_PRESENCE),
+	SND_PCI_QUIRK(0x1028, 0x09d1, "Alienware m17 R3", ALC289_FIXUP_DUAL_SPK),
 	SND_PCI_QUIRK(0x1028, 0x0a2e, "Dell", ALC236_FIXUP_DELL_AIO_HEADSET_MIC),
 	SND_PCI_QUIRK(0x1028, 0x0a30, "Dell", ALC236_FIXUP_DELL_AIO_HEADSET_MIC),
 	SND_PCI_QUIRK(0x1028, 0x0a38, "Dell Latitude 7520", ALC269_FIXUP_DELL4_MIC_NO_PRESENCE_QUIET),

---
base-commit: a4311e9447bbb219044db38897f95be112f46a8a
change-id: 20261029-alc289-m17r3-060df552ed6c

Best regards,
-- 
Chris Simpson <chris@nilk.net>

