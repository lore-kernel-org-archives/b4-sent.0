From: Daniel Schaefer <dhs@frame.work>
Date: Sun, 05 Jul 2026 16:07:13 +0800
Subject: [PATCH] ALSA: hda/realtek: add quirk for Framework F111:0010
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260705-framework-audio-ssid-0x0010-v1-1-fffc8996ac18@frame.work>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSwqDQAwA0KtI1g3EtH7oVUoXUyejodQpCVVBv
 HsHl2/zdnAxFYd7tYPJoq55LqgvFQxTmEdBjcXAxC111GCy8JE12xvDL2pGd41IG1FNOLyuPdO
 Ne04JyvA1Sbqd++N5HH8I67UKbQAAAA==
X-Change-ID: 20260705-framework-audio-ssid-0x0010-cb38204282ff
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux@frame.work, 
 Daniel Schaefer <dhs@frame.work>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783238865; l=1317;
 i=dhs@frame.work; s=20260705; h=from:subject:message-id;
 bh=ZuKVyyBkhHa8+nRdHOgKdv02u2mQ8xtQLyrlEclnmFU=;
 b=N8uQZiYI539De94mhlvUExkl3biccVUH0yqr88v/hsZDHYesqbpn8NR+Z0gYmSKefmnLu/SQC
 ArWOkQ/6nihB5u5y+b2jRwBGafdxiHySGt8rIUIZhqN9KzJhu35MRMA
X-Developer-Key: i=dhs@frame.work; a=ed25519;
 pk=O1zF7VDnmz6EZNc7sEiawR+KK650uRg1XteQ8jHwScw=
X-Endpoint-Received: by B4 Relay for dhs@frame.work/20260705 with auth_id=852
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Similar to commit 67c738152207 ("ALSA: hda/realtek: fix mic boost on
Framework PTL") and previous quirks for Framework systems with
Realtek codecs.

0010 is another platform with an ALC285 which needs the same quirk.

Signed-off-by: Daniel Schaefer <dhs@frame.work>
---
 sound/hda/codecs/realtek/alc269.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index 21ab891fcb47..54c2470c3846 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -7942,6 +7942,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0xf111, 0x000c, "Framework Laptop", ALC295_FIXUP_FRAMEWORK_LAPTOP_MIC_NO_PRESENCE),
 	SND_PCI_QUIRK(0xf111, 0x000f, "Framework Laptop 13 Pro PTL", ALC295_FIXUP_FRAMEWORK_LAPTOP_LIMIT_INT_MIC_BOOST),
 	SND_PCI_QUIRK(0xf111, 0x010f, "Framework Laptop 13 PTL", ALC295_FIXUP_FRAMEWORK_LAPTOP_LIMIT_INT_MIC_BOOST),
+	SND_PCI_QUIRK(0xf111, 0x0010, "Framework Laptop", ALC295_FIXUP_FRAMEWORK_LAPTOP_LIMIT_INT_MIC_BOOST),
 
 #if 0
 	/* Below is a quirk table taken from the old code.

---
base-commit: c0933934d5d96fc641e8d0025f9099e554a7b47a
change-id: 20260705-framework-audio-ssid-0x0010-cb38204282ff

Best regards,
-- 
Daniel Schaefer <dhs@frame.work>

