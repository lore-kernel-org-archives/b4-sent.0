From: Fernando Antunez Antonio <fer.antunez24antonio@gmail.com>
Date: Sat, 02 May 2026 11:28:22 -0600
Subject: [PATCH v2] ALSA: hda/realtek: Fix mute and mic-mute LEDs for HP
 Envy X360 15-fh0xxx
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260502-hpenvy-muteled-fix-v2-1-df2ba19b3b4b@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32NzQ6CMBCEX4Xs2TVtkQqcfA/DAcoKa/hLC42E8
 O4WvHv8JjPzbeDIMjnIow0seXY8DgHUJQLTlkNDyHVgUEJpkQiJ7USDX7FfZuqoxhd/UKtEVmW
 W6ds9hTCcLIX4PH0WP3ZL9SYzH09Ho2U3j3Y9rV4evb8CL1FiajIRU6xFSvRo+pK7qxl7KPZ9/
 wKqzlRdxgAAAA==
X-Change-ID: 20260501-hpenvy-muteled-fix-6251ba996478
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Fernando Antunez Antonio <fer.antunez24antonio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777742945; l=1712;
 i=fer.antunez24antonio@gmail.com; s=20260501; h=from:subject:message-id;
 bh=dnfuLzMMMLgPx59tlBEYIF31US4c32XH7htV/V7Uxa8=;
 b=vBd+zSwT9lxFjoX4S8zEHSewL2flXi3bYRwiO1uoiVTBHS6akWgDic0H728w+lyNl1ZjvDIMd
 DZ+OFRUO+fqB9VnlWbfiUdD1FBC2ezT3y5r7RnK31Fc30j+ZmADlTzU
X-Developer-Key: i=fer.antunez24antonio@gmail.com; a=ed25519;
 pk=KtAZSzHv34SEFf0i38Wjweb1kiwZdCAcJmQ8koSweKY=
X-Endpoint-Received: by B4 Relay for fer.antunez24antonio@gmail.com/20260501 with auth_id=765
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This enables the mute and mic-mute LEDs on the HP Envy X360 15-fh0xxx
2-in-1 laptops.
The quirk 'ALC245_FIXUP_HP_X360_MUTE_LEDS' already exists and is now
enabled for this device.

Signed-off-by: Fernando Antunez Antonio <fer.antunez24antonio@gmail.com>
---
Changes in v2:
- Moved quirk entry to correct position to preserve PCI SSID order
- Removed redundant use of the word Laptop
- Changed subject from SOUND to ALSA
- Link to v1: https://patch.msgid.link/20260501-hpenvy-muteled-fix-v1-1-8c903e3608ee@gmail.com
---
 sound/hda/codecs/realtek/alc269.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index a9cd03bb73c4..ac669ae298d5 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -7098,6 +7098,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x103c, 0x8be7, "HP Envy 17", ALC287_FIXUP_CS35L41_I2C_2),
 	SND_PCI_QUIRK(0x103c, 0x8be8, "HP Envy 17", ALC287_FIXUP_CS35L41_I2C_2),
 	SND_PCI_QUIRK(0x103c, 0x8be9, "HP Envy 15", ALC287_FIXUP_CS35L41_I2C_2),
+	SND_PCI_QUIRK(0x103c, 0x8be9, "HP Envy x360 2-in-1 Laptop 15-fh0xxx", ALC245_FIXUP_HP_X360_MUTE_LEDS),
 	SND_PCI_QUIRK(0x103c, 0x8bf0, "HP", ALC236_FIXUP_HP_GPIO_LED),
 	SND_PCI_QUIRK(0x103c, 0x8c15, "HP Spectre x360 2-in-1 Laptop 14-eu0xxx", ALC245_FIXUP_HP_SPECTRE_X360_EU0XXX),
 	SND_PCI_QUIRK(0x103c, 0x8c16, "HP Spectre x360 2-in-1 Laptop 16-aa0xxx", ALC245_FIXUP_HP_SPECTRE_X360_16_AA0XXX),

---
base-commit: f1a5e78a55ebf2b05777fd5eb738038ddae609d6
change-id: 20260501-hpenvy-muteled-fix-6251ba996478

Best regards,
--  
Fernando Antunez <fer.antunez24antonio@gmail.com>

