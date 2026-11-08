From: Brian Harring <ferringb@gmail.com>
Date: Sun, 08 Nov 2026 19:58:38 +0100
Subject: [PATCH 2/2] ALSA: usb-audio: Add ES9219 speaker volume for ASRock
 X870E Taichi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-alc4082-taichi-v1-2-942558088157@gmail.com>
References: <20261108-alc4082-taichi-v1-0-942558088157@gmail.com>
In-Reply-To: <20261108-alc4082-taichi-v1-0-942558088157@gmail.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, Brian Harring <ferringb@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6121; i=ferringb@gmail.com;
 h=from:subject:message-id; bh=CrUI3MaXbG+WmdY+DVmVexEKKmLG1d8AUhv7tprf/RU=;
 b=owGbwMvMwCW26vPpzMb96zwZT6slMWR9OJbYtuD5rAubcn+u3ioX4fhThPlNFrd7v+sJ2caNU
 vmH3i1/0PGRhUGMi2GmmCLLgy85bxTib31zNbrkAjOHlQlkiLRIAwMQsDDw5SbmlRrpGOmZahvq
 GQIZOkbxEDk9Bo3M4uLS1CLdtIIih7z8ksSSzPy8Yr38gtS8gvQCvbTMtJKMjPyi4lSgEXp5qSW
 uBm4mZs6uzkYGpm4ujm5mJqbGRi5GJiaOjm7Gzk5mlhaGTm6OriaWDFycAjDXmE9kZPj4VDZNsn
 7Nvo1nxZX8/e5lZvgumdck/n1h1AvmA2v1sx8x/FPY5XjgxdOPLgcinFO4nA795Cp8c9tpwnI5i
 wfh7NfLe3gB
X-Developer-Key: i=ferringb@gmail.com; a=openpgp;
 fpr=E9C121C8F3E4519A7E8E7E39C5068414B0C044B7
X-Endpoint-Received: by B4 Relay for ferringb@gmail.com/default with auth_id=1454
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The rear output of the ASRock X870E Taichi / Taichi Lite onboard audio
(26ce:0a0b, Realtek ALC4082) has a feature unit with only a mute, but an
ESS ES9219 DAC sits behind it which can be used for volume control.

The DAC is reachable through the codec's I2C bridge, using the vendor
requests found in Realtek's Windows 10 driver (version 6.4.0.2449). That
driver doesn't enable this for any ASRock device; at a guess, ASRock
simply overlooked it.

Assisted-by: Claude Opus 5.5
Signed-off-by: Brian Harring <ferringb@gmail.com>
---
 sound/usb/mixer_quirks.c | 157 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 157 insertions(+)

diff --git a/sound/usb/mixer_quirks.c b/sound/usb/mixer_quirks.c
index 4c7d68311f20..075fb5847030 100644
--- a/sound/usb/mixer_quirks.c
+++ b/sound/usb/mixer_quirks.c
@@ -4656,6 +4656,159 @@ static int snd_xiisound_init_fu_pins(struct usb_mixer_interface *mixer)
 	return 0;
 }
 
+/*
+ * ASRock X870E Taichi (ALC4082): the rear line exposes only mute (feature
+ * unit 19), but there is an ESS ES9219 DAC behind it that is usable for
+ * volume control.
+ */
+#define TAICHI_I2C_READ		0x3d
+#define TAICHI_I2C_WRITE	0x3e
+#define TAICHI_I2C_INDEX	0x0100
+#define TAICHI_ES9219_I2C_ADDR	0x48
+#define TAICHI_ES9219_REG_VOL1	0x0f
+#define TAICHI_ES9219_REG_VOL2	0x10
+#define TAICHI_ES9219_VOL_MAX	0xff
+
+static int taichi_es9219_read(struct snd_usb_audio *chip, u8 reg, u8 *val)
+{
+	struct usb_device *dev = chip->dev;
+	u8 buf[2] = { reg, 0 };
+	int err;
+
+	err = snd_usb_ctl_msg(dev, usb_sndctrlpipe(dev, 0), TAICHI_I2C_READ,
+			      USB_RECIP_DEVICE | USB_TYPE_VENDOR | USB_DIR_OUT,
+			      TAICHI_ES9219_I2C_ADDR, TAICHI_I2C_INDEX,
+			      buf, sizeof(buf));
+	if (err < 0)
+		return err;
+	err = snd_usb_ctl_msg(dev, usb_rcvctrlpipe(dev, 0), TAICHI_I2C_READ,
+			      USB_RECIP_DEVICE | USB_TYPE_VENDOR | USB_DIR_IN,
+			      TAICHI_ES9219_I2C_ADDR, TAICHI_I2C_INDEX,
+			      buf, sizeof(buf));
+	if (err < 0)
+		return err;
+	if (err < 1)
+		return -EIO;
+	*val = buf[0];
+	return 0;
+}
+
+static int taichi_es9219_write(struct snd_usb_audio *chip, u8 reg, u8 val)
+{
+	struct usb_device *dev = chip->dev;
+	u8 buf[2] = { reg, val };
+	int err;
+
+	err = snd_usb_ctl_msg(dev, usb_sndctrlpipe(dev, 0), TAICHI_I2C_WRITE,
+			      USB_RECIP_DEVICE | USB_TYPE_VENDOR | USB_DIR_OUT,
+			      TAICHI_ES9219_I2C_ADDR, TAICHI_I2C_INDEX,
+			      buf, sizeof(buf));
+	return err < 0 ? err : 0;
+}
+
+static int taichi_es9219_vol_update(struct usb_mixer_interface *mixer,
+				    unsigned long pv)
+{
+	struct snd_usb_audio *chip = mixer->chip;
+	int err;
+
+	CLASS(snd_usb_lock, pm)(chip);
+	if (pm.err < 0)
+		return pm.err;
+
+	err = taichi_es9219_write(chip, TAICHI_ES9219_REG_VOL1,
+				  TAICHI_ES9219_VOL_MAX - (pv & 0xff));
+	if (err < 0)
+		return err;
+	return taichi_es9219_write(chip, TAICHI_ES9219_REG_VOL2,
+				   TAICHI_ES9219_VOL_MAX - ((pv >> 8) & 0xff));
+}
+
+static int taichi_es9219_vol_info(struct snd_kcontrol *kctl,
+				  struct snd_ctl_elem_info *uinfo)
+{
+	uinfo->type = SNDRV_CTL_ELEM_TYPE_INTEGER;
+	uinfo->count = 2;
+	uinfo->value.integer.min = 0;
+	uinfo->value.integer.max = TAICHI_ES9219_VOL_MAX;
+	return 0;
+}
+
+static int taichi_es9219_vol_get(struct snd_kcontrol *kctl,
+				 struct snd_ctl_elem_value *ucontrol)
+{
+	ucontrol->value.integer.value[0] = kctl->private_value & 0xff;
+	ucontrol->value.integer.value[1] = (kctl->private_value >> 8) & 0xff;
+	return 0;
+}
+
+static int taichi_es9219_vol_put(struct snd_kcontrol *kctl,
+				 struct snd_ctl_elem_value *ucontrol)
+{
+	struct usb_mixer_elem_list *list = snd_kcontrol_chip(kctl);
+	long l = ucontrol->value.integer.value[0];
+	long r = ucontrol->value.integer.value[1];
+	unsigned long pv;
+	int err;
+
+	if (l < 0 || l > TAICHI_ES9219_VOL_MAX ||
+	    r < 0 || r > TAICHI_ES9219_VOL_MAX)
+		return -EINVAL;
+
+	pv = l | (r << 8);
+	if (pv == kctl->private_value)
+		return 0;
+
+	kctl->private_value = pv;
+	err = taichi_es9219_vol_update(list->mixer, pv);
+	return err < 0 ? err : 1;
+}
+
+static int taichi_es9219_vol_resume(struct usb_mixer_elem_list *list)
+{
+	return taichi_es9219_vol_update(list->mixer, list->kctl->private_value);
+}
+
+static const DECLARE_TLV_DB_SCALE(taichi_es9219_db_scale, -12750, 50, 0);
+
+static const struct snd_kcontrol_new taichi_es9219_vol = {
+	.iface = SNDRV_CTL_ELEM_IFACE_MIXER,
+	.name = "Speaker Playback Volume",
+	.access = SNDRV_CTL_ELEM_ACCESS_READWRITE |
+		  SNDRV_CTL_ELEM_ACCESS_TLV_READ,
+	.info = taichi_es9219_vol_info,
+	.get = taichi_es9219_vol_get,
+	.put = taichi_es9219_vol_put,
+	.tlv = { .p = taichi_es9219_db_scale },
+};
+
+static int taichi_es9219_controls_create(struct usb_mixer_interface *mixer)
+{
+	struct snd_usb_audio *chip = mixer->chip;
+	struct usb_mixer_elem_list *list;
+	u8 v1, v2;
+	int err;
+
+	err = taichi_es9219_read(chip, TAICHI_ES9219_REG_VOL1, &v1);
+	if (err < 0) {
+		usb_audio_dbg(chip, "ES9219 VOL1 read failed: %d\n", err);
+		return 0;
+	}
+	err = taichi_es9219_read(chip, TAICHI_ES9219_REG_VOL2, &v2);
+	if (err < 0) {
+		usb_audio_dbg(chip, "ES9219 VOL2 read failed: %d\n", err);
+		return 0;
+	}
+
+	err = add_single_ctl_with_resume(mixer, 0, taichi_es9219_vol_resume,
+					 &taichi_es9219_vol, &list);
+	if (err < 0)
+		return err;
+	list->kctl->private_value = (TAICHI_ES9219_VOL_MAX - v1) |
+				    ((TAICHI_ES9219_VOL_MAX - v2) << 8);
+	return 0;
+}
+
 int snd_usb_mixer_apply_create_quirk(struct usb_mixer_interface *mixer)
 {
 	int err = 0;
@@ -4797,6 +4950,10 @@ int snd_usb_mixer_apply_create_quirk(struct usb_mixer_interface *mixer)
 		err = dell_dock_mixer_create(mixer);
 		break;
 
+	case USB_ID(0x26ce, 0x0a0b): /* ASRock X870E Taichi (Lite) */
+		err = taichi_es9219_controls_create(mixer);
+		break;
+
 	case USB_ID(0x2a39, 0x3fd2): /* RME ADI-2 Pro */
 	case USB_ID(0x2a39, 0x3fd3): /* RME ADI-2 DAC */
 	case USB_ID(0x2a39, 0x3fd4): /* RME */

-- 
2.56.0

