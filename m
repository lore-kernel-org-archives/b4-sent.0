From: Golicza Alpar <galpar07@proton.me>
Date: Mon, 23 Nov 2026 16:25:15 +0200
Subject: [PATCH] ALSA: usb-audio: Add mixer quirks for Creative Sound
 Blaster Audigy Fx Pro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-audigy-fx-pro-quirk-v1-1-5fbc574e25d3@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/x3MQQqDMBAF0KsMf+1AEqXYXKV0YZOJHQS1EywW8
 e4F3wHegSqmUhHpgMlXqy4zIvmGkN7DPAprRiQEF27eh5aHLev447Lzagt/NrWJXS6p9a5P3eu
 OhrCaFN2v9fE8zz/+5UY5ZQAAAA==
X-Change-ID: 20261123-audigy-fx-pro-quirk-0dfc3108c4b9
To: Jaroslav Kysela <perex@perex.cz>
Cc: linux-kernel@vger.kernel.org, Golicza Alpar <galpar07@proton.me>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795444126; l=11555;
 i=galpar07@proton.me; s=20261123; h=from:subject:message-id;
 bh=0+ioq25eatgbDcR3VfY8s5zMHZnrWsxET58JAEhb7A4=;
 b=Pazw2gKECHA7bMaijfFmAYftB9/l39DTywmZELK5siTSF7WJuSyk7aN2iv0oKa2VGRARFaeET
 18Ra0FdIJBRDoqYNX/ePcQZLiHBc2dPv6EtlbkaCv4h8Et3hYqEAdxU
X-Developer-Key: i=galpar07@proton.me; a=ed25519;
 pk=ZMfYwlv1UUzfuCRVN6zqNd9z9RJzAVIVOGK0b23NP9Y=
X-Endpoint-Received: by B4 Relay for galpar07@proton.me/20261123 with auth_id=1615
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Creative Sound Blaster Audigy Fx Pro (041e:32b7) requires explicit
retasking for its rear combo output (Speakers/Headphones) and input
(Line-In/Mic) jacks, and supports a 4-step analog rear mic boost
(0/+10/+20/+30 dB). Without an explicit retask after a cold boot or
warm reboot, rear input is not functional.

Add mixer controls for these settings:
- "Rear Output Mode" (Speakers / Headphones)
- "Rear Input Mode" (Line-In / Mic)
- "Rear Mic Boost Volume" (0/+10/+20/+30 dB with TLV scale)

Retask the rear jacks during mixer initialization and restore all three
controls on resume.

Signed-off-by: Golicza Alpar <galpar07@proton.me>
---
 sound/usb/mixer_quirks.c | 337 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 337 insertions(+)

diff --git a/sound/usb/mixer_quirks.c b/sound/usb/mixer_quirks.c
index 4c7d68311..2a401a2cb 100644
--- a/sound/usb/mixer_quirks.c
+++ b/sound/usb/mixer_quirks.c
@@ -2213,6 +2213,340 @@ static int snd_soundblaster_e1_switch_create(struct usb_mixer_interface *mixer)
 					  NULL);
 }
 
+/*
+ * Creative Sound Blaster Audigy Fx Pro (041e:32b7)
+ * Rear combo jack retasking and analog rear mic boost (0/+10/+20/+30 dB).
+ */
+#define AUDIGY_FX_PRO_REQ_RETASK	0x6c
+#define AUDIGY_FX_PRO_REQ_REG_WRITE	0x24
+#define AUDIGY_FX_PRO_REQ_REG_READ	0x25
+
+#define AUDIGY_FX_PRO_IDX_INPUT		0x0001
+#define AUDIGY_FX_PRO_IDX_OUTPUT	0x000c
+#define AUDIGY_FX_PRO_REG_OUTPUT_STATE	0xc322
+#define AUDIGY_FX_PRO_REG_INPUT_STATE	0xc324
+
+#define AUDIGY_FX_PRO_REG_MIC_BOOST_HI	0x1700
+#define AUDIGY_FX_PRO_REG_MIC_BOOST_LO	0x0322
+#define AUDIGY_FX_PRO_MIC_BOOST_MAX	3
+#define AUDIGY_FX_PRO_MIC_BOOST_STEP	5
+
+#define AUDIGY_FX_PRO_VAL_SPEAKER	0x01
+#define AUDIGY_FX_PRO_VAL_HEADPHONE	0x02
+#define AUDIGY_FX_PRO_VAL_LINE_IN	0x12
+#define AUDIGY_FX_PRO_VAL_MIC		0x13
+
+#define AUDIGY_FX_PRO_DESC_SHIFT	8
+#define AUDIGY_FX_PRO_VAL_MASK		0xff
+
+struct audigy_fx_pro_ctl_desc {
+	const char *name;
+	const char *const items[2];
+	u16 retask_index;
+	u16 state_index;
+	u8 vals[2];
+	u8 default_idx;
+};
+
+static const struct audigy_fx_pro_ctl_desc audigy_fx_pro_ctls[] = {
+	{
+		.name = "Rear Output Mode",
+		.items = { "Speakers", "Headphones" },
+		.retask_index = AUDIGY_FX_PRO_IDX_OUTPUT,
+		.state_index = AUDIGY_FX_PRO_REG_OUTPUT_STATE,
+		.vals = {
+			AUDIGY_FX_PRO_VAL_SPEAKER,
+			AUDIGY_FX_PRO_VAL_HEADPHONE,
+		},
+		.default_idx = 0,
+	},
+	{
+		.name = "Rear Input Mode",
+		.items = { "Line-In", "Mic" },
+		.retask_index = AUDIGY_FX_PRO_IDX_INPUT,
+		.state_index = AUDIGY_FX_PRO_REG_INPUT_STATE,
+		.vals = {
+			AUDIGY_FX_PRO_VAL_LINE_IN,
+			AUDIGY_FX_PRO_VAL_MIC,
+		},
+		.default_idx = 1,
+	},
+};
+
+static int snd_audigy_fx_pro_reg_read_locked(struct snd_usb_audio *chip,
+					     u16 reg, u8 *val)
+{
+	int err;
+
+	err = snd_usb_ctl_msg(chip->dev, usb_rcvctrlpipe(chip->dev, 0),
+			      AUDIGY_FX_PRO_REQ_REG_READ,
+			      USB_RECIP_DEVICE | USB_TYPE_VENDOR | USB_DIR_IN,
+			      0, reg, val, sizeof(*val));
+	if (err < 0)
+		return err;
+	return err < 1 ? -EIO : 0;
+}
+
+static int snd_audigy_fx_pro_reg_write_locked(struct snd_usb_audio *chip,
+					      u16 reg, u8 val)
+{
+	int err;
+
+	err = snd_usb_ctl_msg(chip->dev, usb_sndctrlpipe(chip->dev, 0),
+			      AUDIGY_FX_PRO_REQ_REG_WRITE,
+			      USB_RECIP_DEVICE | USB_TYPE_VENDOR | USB_DIR_OUT,
+			      0, reg, &val, sizeof(val));
+	return err < 0 ? err : 0;
+}
+
+static int snd_audigy_fx_pro_reg_read(struct snd_usb_audio *chip,
+				      u16 reg, u8 *val)
+{
+	CLASS(snd_usb_lock, pm)(chip);
+	if (pm.err < 0)
+		return pm.err;
+
+	return snd_audigy_fx_pro_reg_read_locked(chip, reg, val);
+}
+
+static int snd_audigy_fx_pro_mic_boost_set(struct snd_usb_audio *chip,
+					   unsigned int level)
+{
+	u8 nib = level * AUDIGY_FX_PRO_MIC_BOOST_STEP;
+	u8 reg = 0;
+	int err;
+
+	CLASS(snd_usb_lock, pm)(chip);
+	if (pm.err < 0)
+		return pm.err;
+
+	/* Preserve unrelated bits in both boost registers via read-modify-write */
+	err = snd_audigy_fx_pro_reg_read_locked(chip,
+						AUDIGY_FX_PRO_REG_MIC_BOOST_HI,
+						&reg);
+	if (err < 0)
+		return err;
+	reg = (reg & 0x0f) | (nib << 4);
+	err = snd_audigy_fx_pro_reg_write_locked(chip,
+						 AUDIGY_FX_PRO_REG_MIC_BOOST_HI,
+						 reg);
+	if (err < 0)
+		return err;
+
+	err = snd_audigy_fx_pro_reg_read_locked(chip,
+						AUDIGY_FX_PRO_REG_MIC_BOOST_LO,
+						&reg);
+	if (err < 0)
+		return err;
+	reg = (reg & 0xf0) | nib;
+	return snd_audigy_fx_pro_reg_write_locked(chip,
+						  AUDIGY_FX_PRO_REG_MIC_BOOST_LO,
+						  reg);
+}
+
+static const DECLARE_TLV_DB_SCALE(audigy_fx_pro_mic_boost_tlv, 0, 1000, 0);
+
+static int snd_audigy_fx_pro_mic_boost_info(struct snd_kcontrol *kcontrol,
+					    struct snd_ctl_elem_info *uinfo)
+{
+	uinfo->type = SNDRV_CTL_ELEM_TYPE_INTEGER;
+	uinfo->count = 1;
+	uinfo->value.integer.min = 0;
+	uinfo->value.integer.max = AUDIGY_FX_PRO_MIC_BOOST_MAX;
+	return 0;
+}
+
+static int snd_audigy_fx_pro_mic_boost_get(struct snd_kcontrol *kcontrol,
+					   struct snd_ctl_elem_value *ucontrol)
+{
+	ucontrol->value.integer.value[0] = kcontrol->private_value;
+	return 0;
+}
+
+static int snd_audigy_fx_pro_mic_boost_put(struct snd_kcontrol *kcontrol,
+					   struct snd_ctl_elem_value *ucontrol)
+{
+	struct usb_mixer_elem_list *list = snd_kcontrol_chip(kcontrol);
+	long val = ucontrol->value.integer.value[0];
+	int err;
+
+	if (val < 0 || val > AUDIGY_FX_PRO_MIC_BOOST_MAX)
+		return -EINVAL;
+	if ((unsigned long)val == kcontrol->private_value)
+		return 0;
+
+	err = snd_audigy_fx_pro_mic_boost_set(list->mixer->chip, val);
+	if (err < 0)
+		return err;
+
+	kcontrol->private_value = val;
+	return 1;
+}
+
+static int snd_audigy_fx_pro_mic_boost_resume(struct usb_mixer_elem_list *list)
+{
+	return snd_audigy_fx_pro_mic_boost_set(list->mixer->chip,
+					       list->kctl->private_value);
+}
+
+static int snd_audigy_fx_pro_retask(struct snd_usb_audio *chip,
+				    u16 idx, u8 val)
+{
+	int err;
+
+	CLASS(snd_usb_lock, pm)(chip);
+	if (pm.err < 0)
+		return pm.err;
+
+	err = snd_usb_ctl_msg(chip->dev, usb_sndctrlpipe(chip->dev, 0),
+			      AUDIGY_FX_PRO_REQ_RETASK,
+			      USB_RECIP_DEVICE | USB_TYPE_VENDOR | USB_DIR_OUT,
+			      0, idx, &val, sizeof(val));
+	if (err < 0)
+		return err;
+
+	/* Allow the MCU to complete the jack retask before subsequent transfers */
+	msleep(150);
+	return 0;
+}
+
+static int snd_audigy_fx_pro_ctl_info(struct snd_kcontrol *kcontrol,
+				      struct snd_ctl_elem_info *uinfo)
+{
+	unsigned int desc_idx = kcontrol->private_value >> AUDIGY_FX_PRO_DESC_SHIFT;
+	const struct audigy_fx_pro_ctl_desc *desc = &audigy_fx_pro_ctls[desc_idx];
+
+	return snd_ctl_enum_info(uinfo, 1, ARRAY_SIZE(desc->items), desc->items);
+}
+
+static int snd_audigy_fx_pro_ctl_get(struct snd_kcontrol *kcontrol,
+				     struct snd_ctl_elem_value *ucontrol)
+{
+	ucontrol->value.enumerated.item[0] =
+		kcontrol->private_value & AUDIGY_FX_PRO_VAL_MASK;
+	return 0;
+}
+
+static int snd_audigy_fx_pro_ctl_put(struct snd_kcontrol *kcontrol,
+				     struct snd_ctl_elem_value *ucontrol)
+{
+	struct usb_mixer_elem_list *list = snd_kcontrol_chip(kcontrol);
+	unsigned int desc_idx = kcontrol->private_value >> AUDIGY_FX_PRO_DESC_SHIFT;
+	unsigned int cur_val = kcontrol->private_value & AUDIGY_FX_PRO_VAL_MASK;
+	unsigned int new_val = ucontrol->value.enumerated.item[0];
+	const struct audigy_fx_pro_ctl_desc *desc = &audigy_fx_pro_ctls[desc_idx];
+	int err;
+
+	if (new_val >= ARRAY_SIZE(desc->items))
+		return -EINVAL;
+	if (new_val == cur_val)
+		return 0;
+
+	err = snd_audigy_fx_pro_retask(list->mixer->chip,
+				       desc->retask_index,
+				       desc->vals[new_val]);
+	if (err < 0)
+		return err;
+
+	kcontrol->private_value =
+		(desc_idx << AUDIGY_FX_PRO_DESC_SHIFT) | new_val;
+	return 1;
+}
+
+static int snd_audigy_fx_pro_ctl_resume(struct usb_mixer_elem_list *list)
+{
+	unsigned long pval = list->kctl->private_value;
+	unsigned int desc_idx = pval >> AUDIGY_FX_PRO_DESC_SHIFT;
+	unsigned int val = pval & AUDIGY_FX_PRO_VAL_MASK;
+	const struct audigy_fx_pro_ctl_desc *desc = &audigy_fx_pro_ctls[desc_idx];
+
+	return snd_audigy_fx_pro_retask(list->mixer->chip,
+					desc->retask_index,
+					desc->vals[val]);
+}
+
+static int snd_audigy_fx_pro_controls_create(struct usb_mixer_interface *mixer)
+{
+	unsigned int i;
+	int err;
+
+	for (i = 0; i < ARRAY_SIZE(audigy_fx_pro_ctls); i++) {
+		const struct audigy_fx_pro_ctl_desc *desc = &audigy_fx_pro_ctls[i];
+		struct snd_kcontrol_new knew = {
+			.iface = SNDRV_CTL_ELEM_IFACE_MIXER,
+			.name = desc->name,
+			.info = snd_audigy_fx_pro_ctl_info,
+			.get = snd_audigy_fx_pro_ctl_get,
+			.put = snd_audigy_fx_pro_ctl_put,
+		};
+		unsigned int init_idx;
+		u8 reg = 0;
+
+		err = snd_audigy_fx_pro_reg_read(mixer->chip,
+						 desc->state_index, &reg);
+		if (err < 0)
+			return err;
+
+		if (reg == desc->vals[0])
+			init_idx = 0;
+		else if (reg == desc->vals[1])
+			init_idx = 1;
+		else
+			init_idx = desc->default_idx;
+
+		/*
+		 * Always apply the retask command on probe: after a cold boot
+		 * the input state register is uninitialized (0x00), and after
+		 * a warm reboot the state register may retain its value even
+		 * though the codec input mux needs an explicit 0x6c retask.
+		 */
+		err = snd_audigy_fx_pro_retask(mixer->chip,
+					       desc->retask_index,
+					       desc->vals[init_idx]);
+		if (err < 0)
+			return err;
+
+		knew.private_value = (i << AUDIGY_FX_PRO_DESC_SHIFT) | init_idx;
+		err = add_single_ctl_with_resume(mixer, 0,
+						 snd_audigy_fx_pro_ctl_resume,
+						 &knew, NULL);
+		if (err < 0)
+			return err;
+	}
+
+	{
+		struct snd_kcontrol_new boost_knew = {
+			.iface = SNDRV_CTL_ELEM_IFACE_MIXER,
+			.name = "Rear Mic Boost Volume",
+			.access = SNDRV_CTL_ELEM_ACCESS_READWRITE |
+				  SNDRV_CTL_ELEM_ACCESS_TLV_READ,
+			.info = snd_audigy_fx_pro_mic_boost_info,
+			.get = snd_audigy_fx_pro_mic_boost_get,
+			.put = snd_audigy_fx_pro_mic_boost_put,
+			.tlv = { .p = audigy_fx_pro_mic_boost_tlv },
+		};
+		u8 reg = 0;
+
+		err = snd_audigy_fx_pro_reg_read(mixer->chip,
+						 AUDIGY_FX_PRO_REG_MIC_BOOST_HI,
+						 &reg);
+		if (err < 0)
+			return err;
+
+		boost_knew.private_value =
+			min_t(unsigned int,
+			      (reg >> 4) / AUDIGY_FX_PRO_MIC_BOOST_STEP,
+			      AUDIGY_FX_PRO_MIC_BOOST_MAX);
+		err = add_single_ctl_with_resume(mixer, 0,
+						 snd_audigy_fx_pro_mic_boost_resume,
+						 &boost_knew, NULL);
+		if (err < 0)
+			return err;
+	}
+
+	return 0;
+}
+
 /*
  * Dell WD15 dock jack detection
  *
@@ -4787,6 +5121,9 @@ int snd_usb_mixer_apply_create_quirk(struct usb_mixer_interface *mixer)
 	case USB_ID(0x041e, 0x323b): /* Creative Sound Blaster E1 */
 		err = snd_soundblaster_e1_switch_create(mixer);
 		break;
+	case USB_ID(0x041e, 0x32b7): /* Creative Sound Blaster Audigy Fx Pro */
+		err = snd_audigy_fx_pro_controls_create(mixer);
+		break;
 	case USB_ID(0x0bda, 0x4014): /* Dell WD15 dock */
 		err = dell_dock_mixer_create(mixer);
 		if (err < 0)

---
base-commit: 0dfd513a15573ffa21710f77c2926c3cbb81a7ed
change-id: 20261123-audigy-fx-pro-quirk-0dfc3108c4b9

Best regards,
-- 
Golicza Alpar <galpar07@proton.me>

