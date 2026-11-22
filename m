From: Oleg Antonyan <oleg.b.antonyan@gmail.com>
Date: Sun, 22 Nov 2026 14:18:37 +0100
Subject: [PATCH] ALSA: hda/realtek: Fix headset mic on ASUS Zenbook S 13
 UX5304MA
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-ux5304ma-headset-mic-v1-1-80589ae749a8@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKzrAmsC/yXMQQ6CMBBG4auQWTtJO2KDXsWwqOVHxgQ0HTAkh
 Ltbdfkt3tvIkBVGl2qjjLeaPqcCf6goDXG6g7UrJnESvBfhZT0dXT1GHhA7w8yjJoYATQh1484
 9lfSV0ev6217bv225PZDm74v2/QPbQQspeAAAAA==
X-Change-ID: 20261122-ux5304ma-headset-mic-e2ee8664809f
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Stefan Binding <sbinding@opensource.cirrus.com>
Cc: Takashi Iwai <tiwai@suse.de>, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Oleg Antonyan <oleg.b.antonyan@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795353517; l=1835;
 i=oleg.b.antonyan@gmail.com; s=20261122; h=from:subject:message-id;
 bh=tTuD5gMzmbpXEeh4kAfA/ft27GJCym2dy3cdc5+lNNU=;
 b=4TrP/nP+pzlrxDU+GUMC/J/I3G+a3TzxaR7aweX53XAOAUEl3sgzRbSnzwe7cltGJu2X5FKw4
 CZxl6NTm/ZkDTdOUevh9EWvfhWv+T9HBSPAe+JwPj4PsWnEHc6Ks0my
X-Developer-Key: i=oleg.b.antonyan@gmail.com; a=ed25519;
 pk=AA4/X8a4Pvsu+cn8cLNZ3XDbM6VmZZJ57ZuDUycpXD0=
X-Endpoint-Received: by B4 Relay for oleg.b.antonyan@gmail.com/20261122 with auth_id=1603
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASUS Zenbook S 13 UX5304MA (1043:1c33) uses an ALC294 codec with
CS35L41 amplifiers over SPI. Its BIOS leaves pin 0x19 unconfigured, so
the headset mic on the combo jack does not work.

Use ALC294_FIXUP_ASUS_SPI_HEADSET_MIC like the UX3405MA and UX3402VA.
It configures the headset mic pin and chains to
ALC245_FIXUP_CS35L41_SPI_2 to keep the speakers working.

Tested on a UX5304MA: headset mic, internal mic and speakers work.

Fixes: 61cbc08fdb04 ("ALSA: hda/realtek: Add quirks for ASUS 2024 Zenbooks")
Cc: stable@vger.kernel.org
Signed-off-by: Oleg Antonyan <oleg.b.antonyan@gmail.com>
---
 sound/hda/codecs/realtek/alc269.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index a6b5e8987294..50bbb5b4529c 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -8213,7 +8213,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x1043, 0x1bbd, "ASUS Z550MA", ALC255_FIXUP_ASUS_MIC_NO_PRESENCE),
 	SND_PCI_QUIRK(0x1043, 0x1c03, "ASUS UM3406HA", ALC294_FIXUP_ASUS_I2C_HEADSET_MIC),
 	SND_PCI_QUIRK(0x1043, 0x1c23, "Asus X55U", ALC269_FIXUP_LIMIT_INT_MIC_BOOST),
-	SND_PCI_QUIRK(0x1043, 0x1c33, "ASUS UX5304MA", ALC245_FIXUP_CS35L41_SPI_2),
+	SND_PCI_QUIRK(0x1043, 0x1c33, "ASUS UX5304MA", ALC294_FIXUP_ASUS_SPI_HEADSET_MIC),
 	SND_PCI_QUIRK(0x1043, 0x1c43, "ASUS UX8406MA", ALC245_FIXUP_CS35L41_SPI_2),
 	SND_PCI_QUIRK(0x1043, 0x1c62, "ASUS GU603", ALC289_FIXUP_ASUS_GA401),
 	SND_PCI_QUIRK(0x1043, 0x1c63, "ASUS GU605M", ALC285_FIXUP_ASUS_GU605_SPI_SPEAKER2_TO_DAC1),

---
base-commit: 0dfd513a15573ffa21710f77c2926c3cbb81a7ed
change-id: 20261122-ux5304ma-headset-mic-e2ee8664809f

Best regards,
--  
Oleg Antonyan <oleg.b.antonyan@gmail.com>

