From: Andrei Aleksandrov <aladex@gmail.com>
Date: Fri, 27 Nov 2026 08:15:22 +0100
Subject: [PATCH RFC 2/2] ALSA: usb-audio: Handle the EPOS GSX 1000 v2
 volume ring in the driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-gsx1000-v1-2-833554c37b82@gmail.com>
References: <20261127-gsx1000-v1-0-833554c37b82@gmail.com>
In-Reply-To: <20261127-gsx1000-v1-0-833554c37b82@gmail.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-input@vger.kernel.org, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Andrei Aleksandrov <aladex@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795763720; l=7660;
 i=aladex@gmail.com; s=20261127; h=from:subject:message-id;
 bh=QKnifHR+kHoir3i33Gcno4lNkMpcJZdKXwkR4yRONoI=;
 b=k5Ks+0GQH7yXH99sYblm5H3LRbPCa5gdpLNOits/d7TJzUpkIrhhxSI05IalyHGpAxFOKcR9O
 JnanlldpikbAZLnmFNVJTYD2+Rw0BVWvkCE9Hxr+Y8TrSyWqXcn7eaW
X-Developer-Key: i=aladex@gmail.com; a=ed25519;
 pk=BRFQEVGQ1X027TItMW+SIsAtbYscopzlk1EJT8Girkg=
X-Endpoint-Received: by B4 Relay for aladex@gmail.com/20261127 with auth_id=1663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The volume ring of the GSX 1000 v2 is an encoder that does not report
its direction. The device sends HID Vol+/Vol- (consumer usages 0xe9 and
0xea, report 2 on interface 5) until the volume the host writes to FU 12
matches the ring position, one event per detent. Windows answers every
event with a 2 % step on its volume scale; the device compares the
written value with 1/256 dB precision and stops asking once it matches.

On Linux these events reach the desktop as global KEY_VOLUMEUP and
KEY_VOLUMEDOWN, the desktop applies its own step size (5 % by default in
KDE), the result does not match the ring, and the device keeps
correcting: the volume oscillates or runs away. Existing workarounds
remap the keys to "reserved" in hwdb, which disables the ring.

Register an input handler that filters KEY_VOLUMEUP/KEY_VOLUMEDOWN only
from input devices whose parent is this USB device, so another keyboard
or another GSX is not affected. Each press steps the control added in the
previous patch by 2, as Windows does, and notifies user space; the
device then sees the expected value and the ring, the desktop volume and
the display stay in sync. The step runs in a work item because the
filter is called in atomic context and the USB write sleeps.

Tested with a GSX 1000 v2 (firmware 2.13) on PipeWire/KDE: slow and fast
turns in both directions, 0 -> 100 % by the ring, slider changes,
unplug/replug and suspend/resume (the desktop volume is restored on the
device).
usbmon shows one SET_CUR pair per detent and no reversals, as in the
Windows captures.

Link: https://github.com/Aladex/epos-gsx
Signed-off-by: Andrei Aleksandrov <aladex@gmail.com>
---
 sound/usb/mixer_quirks.c | 148 +++++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 148 insertions(+)

diff --git a/sound/usb/mixer_quirks.c b/sound/usb/mixer_quirks.c
index 6e96e8020855..d16d548a5b45 100644
--- a/sound/usb/mixer_quirks.c
+++ b/sound/usb/mixer_quirks.c
@@ -4689,10 +4689,17 @@ static const s16 snd_gsx1000_vol_table[SND_GSX1000_VOL_STEPS + 1] = {
 	0,
 };
 
+#define SND_GSX1000_RING_STEP	2	/* one ring detent, as on Windows */
+
 struct snd_gsx1000_vol {
 	struct usb_mixer_elem_list list;	/* kctl private data */
 	struct mutex lock;			/* serializes value and USB writes */
 	unsigned int value;			/* 0..SND_GSX1000_VOL_STEPS */
+	struct work_struct ring_work;
+	atomic_t ring_delta;
+	struct input_handler ih;
+	struct input_device_id id_table[2];
+	bool ih_registered;
 };
 
 #define to_gsx1000_vol(l)	container_of(l, struct snd_gsx1000_vol, list)
@@ -4798,10 +4805,147 @@ static const struct snd_kcontrol_new snd_gsx1000_vol_control = {
 	.put = snd_gsx1000_vol_put,
 };
 
+/*
+ * The ring keeps sending Vol+/Vol- until the host volume matches the ring
+ * position, one detent per event.  Answer these requests here instead of
+ * passing them on as global volume keys, so the desktop does not apply its
+ * own step size to them and only this card is affected.
+ */
+static void snd_gsx1000_ring_work(struct work_struct *work)
+{
+	struct snd_gsx1000_vol *vol =
+		container_of(work, struct snd_gsx1000_vol, ring_work);
+	int delta = atomic_xchg(&vol->ring_delta, 0);
+	int value, changed;
+
+	if (!delta)
+		return;
+
+	scoped_guard(mutex, &vol->lock) {
+		value = clamp_t(int, vol->value + delta * SND_GSX1000_RING_STEP,
+				0, SND_GSX1000_VOL_STEPS);
+		changed = __snd_gsx1000_vol_set(vol, value);
+	}
+	if (changed > 0)
+		snd_ctl_notify(vol->list.mixer->chip->card,
+			       SNDRV_CTL_EVENT_MASK_VALUE, &vol->list.kctl->id);
+}
+
+#if IS_REACHABLE(CONFIG_INPUT)
+static bool snd_gsx1000_ih_filter(struct input_handle *handle,
+				  unsigned int type, unsigned int code,
+				  int value)
+{
+	struct snd_gsx1000_vol *vol =
+		container_of(handle->handler, struct snd_gsx1000_vol, ih);
+
+	if (type != EV_KEY ||
+	    (code != KEY_VOLUMEUP && code != KEY_VOLUMEDOWN))
+		return false;
+
+	/* Act on presses only; swallow releases and repeats as well */
+	if (value == 1) {
+		atomic_add(code == KEY_VOLUMEUP ? 1 : -1, &vol->ring_delta);
+		schedule_work(&vol->ring_work);
+	}
+	return true;
+}
+
+static bool snd_gsx1000_ih_match(struct input_handler *handler,
+				 struct input_dev *dev)
+{
+	struct snd_gsx1000_vol *vol =
+		container_of(handler, struct snd_gsx1000_vol, ih);
+	struct usb_device *snd_dev = vol->list.mixer->chip->dev;
+	struct device *parent;
+
+	/* Only the HID interface of this very card, not an identical one */
+	for (parent = dev->dev.parent; parent; parent = parent->parent) {
+		if (parent == &snd_dev->dev)
+			return true;
+	}
+	return false;
+}
+
+static int snd_gsx1000_ih_connect(struct input_handler *handler,
+				  struct input_dev *dev,
+				  const struct input_device_id *id)
+{
+	struct input_handle *handle;
+	int err;
+
+	handle = kzalloc_obj(*handle);
+	if (!handle)
+		return -ENOMEM;
+
+	handle->dev = dev;
+	handle->handler = handler;
+	handle->name = handler->name;
+
+	err = input_register_handle(handle);
+	if (err)
+		goto err_free;
+
+	err = input_open_device(handle);
+	if (err)
+		goto err_unregister;
+
+	return 0;
+
+err_unregister:
+	input_unregister_handle(handle);
+err_free:
+	kfree(handle);
+	return err;
+}
+
+static void snd_gsx1000_ih_disconnect(struct input_handle *handle)
+{
+	input_close_device(handle);
+	input_unregister_handle(handle);
+	kfree(handle);
+}
+
+static void snd_gsx1000_ih_register(struct snd_gsx1000_vol *vol)
+{
+	struct usb_mixer_interface *mixer = vol->list.mixer;
+	struct input_device_id *id = &vol->id_table[0];
+	int err;
+
+	id->flags = INPUT_DEVICE_ID_MATCH_VENDOR | INPUT_DEVICE_ID_MATCH_PRODUCT |
+		    INPUT_DEVICE_ID_MATCH_EVBIT | INPUT_DEVICE_ID_MATCH_KEYBIT;
+	id->vendor = USB_ID_VENDOR(mixer->chip->usb_id);
+	id->product = USB_ID_PRODUCT(mixer->chip->usb_id);
+	id->evbit[BIT_WORD(EV_KEY)] = BIT_MASK(EV_KEY);
+	id->keybit[BIT_WORD(KEY_VOLUMEUP)] = BIT_MASK(KEY_VOLUMEUP);
+
+	vol->ih.filter = snd_gsx1000_ih_filter;
+	vol->ih.match = snd_gsx1000_ih_match;
+	vol->ih.connect = snd_gsx1000_ih_connect;
+	vol->ih.disconnect = snd_gsx1000_ih_disconnect;
+	vol->ih.name = "snd-usb-gsx1000-ring";
+	vol->ih.id_table = vol->id_table;
+
+	err = input_register_handler(&vol->ih);
+	if (err)
+		usb_audio_warn(mixer->chip,
+			       "GSX 1000: cannot register ring handler: %d\n", err);
+	else
+		vol->ih_registered = true;
+}
+#else
+static void snd_gsx1000_ih_register(struct snd_gsx1000_vol *vol) {}
+#endif /* IS_REACHABLE(CONFIG_INPUT) */
+
 static void snd_gsx1000_vol_free(struct snd_kcontrol *kctl)
 {
 	struct snd_gsx1000_vol *vol = to_gsx1000_vol(snd_kcontrol_chip(kctl));
 
+#if IS_REACHABLE(CONFIG_INPUT)
+	if (vol->ih_registered)
+		input_unregister_handler(&vol->ih);
+#endif
+	cancel_work_sync(&vol->ring_work);
 	mutex_destroy(&vol->lock);
 	kfree(vol);
 	kctl->private_data = NULL;
@@ -4825,6 +4969,8 @@ static int snd_gsx1000_controls_create(struct usb_mixer_interface *mixer)
 	vol->list.resume = snd_gsx1000_vol_resume;
 	vol->value = SND_GSX1000_VOL_DEFAULT;
 	mutex_init(&vol->lock);
+	INIT_WORK(&vol->ring_work, snd_gsx1000_ring_work);
+	atomic_set(&vol->ring_delta, 0);
 
 	kctl = snd_ctl_new1(&snd_gsx1000_vol_control, &vol->list);
 	if (!kctl) {
@@ -4845,6 +4991,8 @@ static int snd_gsx1000_controls_create(struct usb_mixer_interface *mixer)
 	if (err < 0)
 		usb_audio_warn(mixer->chip,
 			       "GSX 1000: cannot set initial volume: %d\n", err);
+
+	snd_gsx1000_ih_register(vol);
 	return 0;
 }
 

-- 
2.56.1

