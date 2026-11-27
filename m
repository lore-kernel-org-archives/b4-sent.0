From: Andrei Aleksandrov <aladex@gmail.com>
Date: Fri, 27 Nov 2026 08:15:21 +0100
Subject: [PATCH RFC 1/2] ALSA: usb-audio: Add Windows volume scale quirk
 for EPOS GSX 1000 v2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-gsx1000-v1-1-833554c37b82@gmail.com>
References: <20261127-gsx1000-v1-0-833554c37b82@gmail.com>
In-Reply-To: <20261127-gsx1000-v1-0-833554c37b82@gmail.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-input@vger.kernel.org, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Andrei Aleksandrov <aladex@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795763720; l=9431;
 i=aladex@gmail.com; s=20261127; h=from:subject:message-id;
 bh=M1bNH+VrHBiPs8XX+iZZQarsoTF3kHnz6t6wAtEYxj0=;
 b=FpuBs+9ql73x0CYlWPOHCDkhf5u3ua/Gi5hFWx1mr3aOjB5KyvT532WrISgOVG+4V7BmWXSdh
 OgrEuLKzad4CDq2YEvQS6wIZEqEfkoKAcow9ghhFmS8FFEcfezFnRmm
X-Developer-Key: i=aladex@gmail.com; a=ed25519;
 pk=BRFQEVGQ1X027TItMW+SIsAtbYscopzlk1EJT8Girkg=
X-Endpoint-Received: by B4 Relay for aladex@gmail.com/20261127 with auth_id=1663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The EPOS / Sennheiser GSX 1000 v2 (1395:00b1) is a UAC1 device whose game
output volume lives in Feature Unit 12 on interface 3. The descriptor
claims -74..0 dB with 1 dB resolution, but the device expects the volume
in the finer steps that the Windows inbox driver writes: Windows maps its
0..100 % scale to fractional dB values (raw = trunc(dB * 256)) and writes
them to channels 1 and 2, leaving the master channel alone. The number on
the device display is derived from that value and shows the Windows
percent.

With the stock 1 dB control the device never sees the value it expects.
The display drifts from the desktop volume, and the volume ring (which
sends HID Vol+/Vol- until the host volume matches the ring position, see
the next patch) keeps correcting forever.

Replace the FU 12 volume with a single 0..100 control that writes the
exact Windows value to channels 1 and 2. The table was measured with
USBPcap from a 0 -> 100 -> 0 sweep on Windows; up and down produced the
same 101 values. The control has no dB TLV on purpose, so user space maps
its volume linearly onto the steps and the device shows the same number as
the desktop. The value is written again on probe and on resume, because
the device falls back to -1 dB on reconnect.

Captures and the decoded protocol:
Link: https://github.com/Aladex/epos-gsx

Signed-off-by: Andrei Aleksandrov <aladex@gmail.com>
---
 sound/usb/mixer_maps.c   |  11 +++
 sound/usb/mixer_quirks.c | 195 +++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 206 insertions(+)

diff --git a/sound/usb/mixer_maps.c b/sound/usb/mixer_maps.c
index 9218ca6314ad..7db0de3e55b1 100644
--- a/sound/usb/mixer_maps.c
+++ b/sound/usb/mixer_maps.c
@@ -566,6 +566,12 @@ static const struct usbmix_name_map avermedia_gc553pro_map[] = {
  * Control map entries
  */
 
+/* EPOS GSX 1000 v2: FU 12 volume is provided by a mixer quirk */
+static const struct usbmix_name_map epos_gsx1000_map[] = {
+	{ 12, NULL, UAC_FU_VOLUME },
+	{ 0 }
+};
+
 static const struct usbmix_ctl_map usbmix_ctl_maps[] = {
 	{
 		.id = USB_ID(0x041e, 0x3000),
@@ -799,6 +805,11 @@ static const struct usbmix_ctl_map usbmix_ctl_maps[] = {
 		.id = USB_ID(0x1532, 0x0552),
 		.map = razer_barracuda_x_2_4_map,
 	},
+	{
+		/* EPOS GSX 1000 v2 */
+		.id = USB_ID(0x1395, 0x00b1),
+		.map = epos_gsx1000_map,
+	},
 	{
 		/* Sennheiser Communications Headset [PC 8] */
 		.id = USB_ID(0x1395, 0x0025),
diff --git a/sound/usb/mixer_quirks.c b/sound/usb/mixer_quirks.c
index 4c7d68311f20..6e96e8020855 100644
--- a/sound/usb/mixer_quirks.c
+++ b/sound/usb/mixer_quirks.c
@@ -4656,6 +4656,198 @@ static int snd_xiisound_init_fu_pins(struct usb_mixer_interface *mixer)
 	return 0;
 }
 
+/*
+ * EPOS / Sennheiser GSX 1000 v2
+ *
+ * The volume ring does not report its direction: it sends HID Vol+/Vol-
+ * until the host volume written to FU 12 matches the ring position, and the
+ * display shows the host volume on the Windows audio-taper scale.  The
+ * descriptor claims 1 dB resolution, but Windows writes fractional dB values,
+ * so a 1 dB grid never lands on the value the device expects.
+ *
+ * Replace the FU 12 volume with a 0..100 control on the Windows scale.  The
+ * control has no dB TLV, so user space maps its volume linearly to these
+ * steps and the number on the device matches the desktop volume percent.
+ */
+#define SND_GSX1000_CTRL_IFNUM	3
+#define SND_GSX1000_FU_ID	12
+#define SND_GSX1000_VOL_STEPS	100
+#define SND_GSX1000_VOL_DEFAULT	60
+
+/* Volume per percent in 1/256 dB, as written by the Windows inbox driver */
+static const s16 snd_gsx1000_vol_table[SND_GSX1000_VOL_STEPS + 1] = {
+	-18944, -15718, -13978, -12781, -11866, -11126, -10505, -9969, -9498, -9078,
+	-8699, -8354, -8037, -7743, -7471, -7216, -6977, -6751, -6538, -6336,
+	-6144, -5961, -5787, -5620, -5459, -5305, -5157, -5014, -4877, -4744,
+	-4615, -4491, -4370, -4253, -4140, -4029, -3922, -3818, -3716, -3617,
+	-3520, -3426, -3334, -3244, -3156, -3070, -2986, -2904, -2823, -2744,
+	-2667, -2591, -2517, -2444, -2372, -2301, -2232, -2164, -2098, -2032,
+	-1967, -1904, -1841, -1780, -1719, -1660, -1601, -1543, -1486, -1430,
+	-1375, -1320, -1266, -1213, -1161, -1109, -1058, -1008, -958, -909,
+	-860, -812, -765, -718, -672, -627, -582, -537, -493, -449,
+	-406, -364, -321, -280, -238, -198, -157, -117, -78, -38,
+	0,
+};
+
+struct snd_gsx1000_vol {
+	struct usb_mixer_elem_list list;	/* kctl private data */
+	struct mutex lock;			/* serializes value and USB writes */
+	unsigned int value;			/* 0..SND_GSX1000_VOL_STEPS */
+};
+
+#define to_gsx1000_vol(l)	container_of(l, struct snd_gsx1000_vol, list)
+
+/* Caller holds vol->lock */
+static int snd_gsx1000_vol_write(struct snd_gsx1000_vol *vol)
+{
+	struct snd_usb_audio *chip = vol->list.mixer->chip;
+	__le16 buf;
+	int ch, err;
+
+	CLASS(snd_usb_lock, pm)(chip);
+	if (pm.err < 0)
+		return pm.err;
+
+	/*
+	 * Windows writes the same value to channels 1 and 2 and leaves the
+	 * master channel alone, so expose a single value and do the same.
+	 */
+	buf = cpu_to_le16((u16)snd_gsx1000_vol_table[vol->value]);
+	for (ch = 0; ch < 2; ch++) {
+		err = snd_usb_ctl_msg(chip->dev, usb_sndctrlpipe(chip->dev, 0),
+				      UAC_SET_CUR,
+				      USB_RECIP_INTERFACE | USB_TYPE_CLASS | USB_DIR_OUT,
+				      (UAC_FU_VOLUME << 8) | (ch + 1),
+				      (SND_GSX1000_FU_ID << 8) | SND_GSX1000_CTRL_IFNUM,
+				      &buf, sizeof(buf));
+		if (err < 0)
+			return err;
+	}
+	return 0;
+}
+
+/* Returns 1 if the value changed, 0 if not, or a negative error */
+static int __snd_gsx1000_vol_set(struct snd_gsx1000_vol *vol, unsigned int value)
+{
+	unsigned int old;
+	int err;
+
+	lockdep_assert_held(&vol->lock);
+	if (value == vol->value)
+		return 0;
+	old = vol->value;
+	vol->value = value;
+	err = snd_gsx1000_vol_write(vol);
+	if (err < 0) {
+		vol->value = old;
+		return err;
+	}
+	return 1;
+}
+
+static int snd_gsx1000_vol_set(struct snd_gsx1000_vol *vol, unsigned int value)
+{
+	guard(mutex)(&vol->lock);
+	return __snd_gsx1000_vol_set(vol, value);
+}
+
+static int snd_gsx1000_vol_info(struct snd_kcontrol *kcontrol,
+				struct snd_ctl_elem_info *uinfo)
+{
+	uinfo->type = SNDRV_CTL_ELEM_TYPE_INTEGER;
+	uinfo->count = 1;
+	uinfo->value.integer.min = 0;
+	uinfo->value.integer.max = SND_GSX1000_VOL_STEPS;
+	uinfo->value.integer.step = 1;
+	return 0;
+}
+
+static int snd_gsx1000_vol_get(struct snd_kcontrol *kcontrol,
+			       struct snd_ctl_elem_value *ucontrol)
+{
+	struct snd_gsx1000_vol *vol = to_gsx1000_vol(snd_kcontrol_chip(kcontrol));
+
+	ucontrol->value.integer.value[0] = READ_ONCE(vol->value);
+	return 0;
+}
+
+static int snd_gsx1000_vol_put(struct snd_kcontrol *kcontrol,
+			       struct snd_ctl_elem_value *ucontrol)
+{
+	struct snd_gsx1000_vol *vol = to_gsx1000_vol(snd_kcontrol_chip(kcontrol));
+	long value = ucontrol->value.integer.value[0];
+
+	if (value < 0 || value > SND_GSX1000_VOL_STEPS)
+		return -EINVAL;
+	return snd_gsx1000_vol_set(vol, value);
+}
+
+static int snd_gsx1000_vol_resume(struct usb_mixer_elem_list *list)
+{
+	struct snd_gsx1000_vol *vol = to_gsx1000_vol(list);
+
+	guard(mutex)(&vol->lock);
+	return snd_gsx1000_vol_write(vol);
+}
+
+static const struct snd_kcontrol_new snd_gsx1000_vol_control = {
+	.iface = SNDRV_CTL_ELEM_IFACE_MIXER,
+	.name = "PCM Playback Volume",
+	.info = snd_gsx1000_vol_info,
+	.get = snd_gsx1000_vol_get,
+	.put = snd_gsx1000_vol_put,
+};
+
+static void snd_gsx1000_vol_free(struct snd_kcontrol *kctl)
+{
+	struct snd_gsx1000_vol *vol = to_gsx1000_vol(snd_kcontrol_chip(kctl));
+
+	mutex_destroy(&vol->lock);
+	kfree(vol);
+	kctl->private_data = NULL;
+}
+
+static int snd_gsx1000_controls_create(struct usb_mixer_interface *mixer)
+{
+	struct snd_gsx1000_vol *vol;
+	struct snd_kcontrol *kctl;
+	int err;
+
+	if (mixer->hostif->desc.bInterfaceNumber != SND_GSX1000_CTRL_IFNUM)
+		return 0;
+
+	vol = kzalloc_obj(*vol);
+	if (!vol)
+		return -ENOMEM;
+
+	vol->list.mixer = mixer;
+	vol->list.id = SND_GSX1000_FU_ID;
+	vol->list.resume = snd_gsx1000_vol_resume;
+	vol->value = SND_GSX1000_VOL_DEFAULT;
+	mutex_init(&vol->lock);
+
+	kctl = snd_ctl_new1(&snd_gsx1000_vol_control, &vol->list);
+	if (!kctl) {
+		mutex_destroy(&vol->lock);
+		kfree(vol);
+		return -ENOMEM;
+	}
+	kctl->private_free = snd_gsx1000_vol_free;
+
+	/* On failure the control is freed together with vol */
+	err = snd_usb_mixer_add_list(&vol->list, kctl, false, true);
+	if (err < 0)
+		return err;
+
+	/* The device falls back to -1 dB on reconnect; make it match the control */
+	scoped_guard(mutex, &vol->lock)
+		err = snd_gsx1000_vol_write(vol);
+	if (err < 0)
+		usb_audio_warn(mixer->chip,
+			       "GSX 1000: cannot set initial volume: %d\n", err);
+	return 0;
+}
+
 int snd_usb_mixer_apply_create_quirk(struct usb_mixer_interface *mixer)
 {
 	int err = 0;
@@ -4852,6 +5044,9 @@ int snd_usb_mixer_apply_create_quirk(struct usb_mixer_interface *mixer)
 	case USB_ID(0x1c75, 0xaf02): /* Arturia AudioFuse */
 		err = snd_audiofuse_controls_create(mixer);
 		break;
+	case USB_ID(0x1395, 0x00b1): /* EPOS GSX 1000 v2 */
+		err = snd_gsx1000_controls_create(mixer);
+		break;
 	}
 
 	return err;

-- 
2.56.1

