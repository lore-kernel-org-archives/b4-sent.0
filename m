From: Lorenzo Argentieri <uni.lorenzo.a@gmail.com>
Date: Mon, 23 Nov 2026 20:05:05 +0100
Subject: [PATCH] ALSA: hda/realtek: Enable speaker amp on ONEXPLAYER X1 i
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-oxp-x1-amp-v1-1-8b61da12d092@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MwQmAMAwF0FXCPxtoIyh2FfEgmmoOamlBCuLug
 m+A96BoNi0I9CDrbcWuE4F8Q1j2+dyUbUUgiJPOe2n5qomr5/lIHKOTQVyrOvRoCClrtPpn4/S
 +H+YFkA9cAAAA
X-Change-ID: 20261123-oxp-x1-amp-ff029203ee97
To: Takashi Iwai <tiwai@suse.com>, Jaroslav Kysela <perex@perex.cz>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Lorenzo Argentieri <uni.lorenzo.a@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795460705; l=5648;
 i=uni.lorenzo.a@gmail.com; s=20261123; h=from:subject:message-id;
 bh=p+vj4gtJ8f10edLkmyCCujVv4evAJNe4qqqgUaEN8Po=;
 b=jzIfid0FwYIE/RjC4FARKhdvo3wKbzPkYochhS7oV6AkXPJcWWTCBawfXY8ZczjBepxNS3zL5
 e9vI9dQIEoDDSS9oaQt4GkDAe1HGIiQ5uQO7QckOeCm+qXR3M60hFAI
X-Developer-Key: i=uni.lorenzo.a@gmail.com; a=ed25519;
 pk=b03MEcj4eqHxAtJC+G7tYbx5b58C77y/G5Sd5OgiaY0=
X-Endpoint-Received: by B4 Relay for uni.lorenzo.a@gmail.com/20261123 with auth_id=1619
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The internal speakers of the ONE-NETBOOK ONEXPLAYER X1 i (Intel Core
Ultra 7 155H, ALC245, subsystem ID 1f75:1602) are almost inaudible on
Linux. They are driven by a Realtek smart amplifier at I2C address 0x10,
behind the ALC245 coefficient tunnel. The firmware leaves the amplifier
unconfigured, and the Windows driver programs it at initialization.

Add a fixup that replays the register writes of the Windows driver
through the tunnel: coefficient 0x24 selects the amplifier, 0x25/0x26
hold the register address, 0x28 the value, and writing 0xb023 to 0x29
starts the transfer. Bit 5 of 0x29 is a self-clearing go bit; poll it
instead of using a fixed delay (a write completes in about 200 us).

The sequence was captured from Windows by the onexplayer2pro-audio-fix
project and decoded here. Its reads and address probes were dropped,
leaving 46 amplifier register writes. The fixup runs at every codec
init, so the configuration is restored after system resume.

Tested on ONEXPLAYER X1 i, BIOS 2.42, after a full power-off: a test
tone played through the speakers and recorded by the internal microphone
is about 50 dB louder with this fixup than without it.

Link: https://github.com/feederchain/onexplayer2pro-audio-fix
Signed-off-by: Lorenzo Argentieri <uni.lorenzo.a@gmail.com>
---
 sound/hda/codecs/realtek/alc269.c | 69 +++++++++++++++++++++++++++++++++++++++
 1 file changed, 69 insertions(+)

diff --git a/sound/hda/codecs/realtek/alc269.c b/sound/hda/codecs/realtek/alc269.c
index a6b5e8987..ca7fcc271 100644
--- a/sound/hda/codecs/realtek/alc269.c
+++ b/sound/hda/codecs/realtek/alc269.c
@@ -1909,6 +1909,69 @@ static void alc298_fixup_alc1316_amp(struct hda_codec *codec,
 	}
 }
 
+/*
+ * The ONEXPLAYER X1 i drives its speakers through a Realtek smart amplifier at
+ * I2C address 0x10, reached over the ALC245 coefficient tunnel. The firmware
+ * leaves the amplifier unconfigured, so the speakers stay silent. The register
+ * writes below replay what the Windows driver does at initialization.
+ *
+ * Tunnel layout: coefficient 0x24 selects the amplifier, 0x25 and 0x26 carry
+ * the high and low halves of the register address, 0x28 the value, and 0x29
+ * commits. Bit 5 of the commit word is a self-clearing go bit; a write takes
+ * about 200 us.
+ */
+static void alc245_onexplayer_amp_write(struct hda_codec *codec, u32 reg, u8 val)
+{
+	int i;
+
+	alc_write_coef_idx(codec, 0x24, 0x0010);
+	alc_write_coef_idx(codec, 0x25, reg >> 16);
+	alc_write_coef_idx(codec, 0x26, reg & 0xffff);
+	alc_write_coef_idx(codec, 0x27, 0x0000);
+	alc_write_coef_idx(codec, 0x28, val);
+	alc_write_coef_idx(codec, 0x29, 0xb023);
+
+	for (i = 0; i < 10; i++) {
+		if (!(alc_read_coef_idx(codec, 0x29) & 0x0020))
+			return;
+		usleep_range(100, 200);
+	}
+	codec_warn(codec, "amp write timeout, reg 0x%x\n", reg);
+}
+
+static void alc245_fixup_onexplayer_amp(struct hda_codec *codec,
+					const struct hda_fixup *fix, int action)
+{
+	static const struct {
+		u32 reg;
+		u8 val;
+	} init_seq[] = {
+		{ 0xf10a, 0x09 }, { 0xf104, 0xf6 }, { 0xf105, 0x22 },
+		{ 0xf10b, 0x2c }, { 0xf10b, 0x7c }, { 0xc000, 0x01 },
+		{ 0xf20d, 0x00 }, { 0xf212, 0x3e }, { 0xc001, 0x02 },
+		{ 0xc003, 0x22 }, { 0xc004, 0x44 }, { 0xc005, 0x44 },
+		{ 0xc007, 0x64 }, { 0xc00e, 0xe7 }, { 0xf223, 0x7f },
+		{ 0xf224, 0xdb }, { 0xf225, 0xee }, { 0xf226, 0x3f },
+		{ 0xf227, 0x0f }, { 0xf21a, 0x78 }, { 0xf242, 0x3c },
+		{ 0xc120, 0x40 }, { 0xc125, 0x03 }, { 0xc321, 0x0b },
+		{ 0xc200, 0xd8 }, { 0xc201, 0x27 }, { 0xc202, 0x0f },
+		{ 0xc400, 0x0e }, { 0xc401, 0x43 }, { 0xc402, 0xe0 },
+		{ 0xc403, 0x00 }, { 0xc404, 0x4c }, { 0xc406, 0x40 },
+		{ 0xc407, 0x02 }, { 0xc408, 0x3f }, { 0xc300, 0x01 },
+		{ 0x41001888, 0x00 }, { 0xc121, 0x0b }, { 0xf102, 0x00 },
+		{ 0xf103, 0x00 }, { 0xf104, 0xf5 }, { 0xf105, 0x23 },
+		{ 0xf109, 0x00 }, { 0xf10a, 0x0b }, { 0xf10b, 0x4c },
+		{ 0xf10b, 0x5c },
+	};
+	int i;
+
+	if (action != HDA_FIXUP_ACT_INIT)
+		return;
+
+	for (i = 0; i < ARRAY_SIZE(init_seq); i++)
+		alc245_onexplayer_amp_write(codec, init_seq[i].reg, init_seq[i].val);
+}
+
 static void alc298_fixup_samsung_amp(struct hda_codec *codec,
 				     const struct hda_fixup *fix, int action)
 {
@@ -4553,6 +4616,7 @@ enum {
 	ALC256_FIXUP_ASUS_SPEAKER_COEFS,
 	ALC245_FIXUP_MINISFORUM_V3_MIC_NO_PRESENCE,
 	ALC287_FIXUP_TAS2781_I2C_DAC,
+	ALC245_FIXUP_ONEXPLAYER_AMP,
 };
 
 /* A special fixup for Lenovo C940 and Yoga Duet 7;
@@ -7472,6 +7536,10 @@ static const struct hda_fixup alc269_fixups[] = {
 		.chained = true,
 		.chain_id = ALC245_FIXUP_BASS_HP_DAC
 	},
+	[ALC245_FIXUP_ONEXPLAYER_AMP] = {
+		.type = HDA_FIXUP_FUNC,
+		.v.func = alc245_fixup_onexplayer_amp,
+	},
 };
 
 static const struct hda_quirk alc269_fixup_tbl[] = {
@@ -8750,6 +8818,7 @@ static const struct hda_quirk alc269_fixup_tbl[] = {
 	SND_PCI_QUIRK(0x1f4c, 0xe001, "Minisforum V3 (SE)",
 		      ALC245_FIXUP_MINISFORUM_V3_MIC_NO_PRESENCE),
 	SND_PCI_QUIRK(0x1f66, 0x0105, "Ayaneo Portable Game Player", ALC287_FIXUP_CS35L41_I2C_2),
+	SND_PCI_QUIRK(0x1f75, 0x1602, "ONEXPLAYER X1 i", ALC245_FIXUP_ONEXPLAYER_AMP),
 	SND_PCI_QUIRK(0x2014, 0x800a, "Positivo ARN50", ALC269_FIXUP_LIMIT_INT_MIC_BOOST),
 	SND_PCI_QUIRK(0x2039, 0x0001, "Inspur S14-G1", ALC295_FIXUP_CHROME_BOOK),
 	SND_PCI_QUIRK(0x2145, 0x0001, "Star Labs StarFighter", ALC233_FIXUP_STARLABS_STARFIGHTER),

---
base-commit: 11ef0d515100259c7979f5b4c61b6ea97c6cdc27
change-id: 20261123-oxp-x1-amp-ff029203ee97

Best regards,
-- 
Lorenzo Argentieri <uni.lorenzo.a@gmail.com>

