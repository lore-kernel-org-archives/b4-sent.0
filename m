From: fenugrec <fenugrec@mail.com>
Date: Sat, 10 Jan 2026 19:00:04 -0500
Subject: [PATCH 2/2] ALSA: usb-audio: clean up presonus s1810 consts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260110-preso_clean1-v1-2-ce2dd3ea4506@mail.com>
References: <20260110-preso_clean1-v1-0-ce2dd3ea4506@mail.com>
In-Reply-To: <20260110-preso_clean1-v1-0-ce2dd3ea4506@mail.com>
To: Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 roy.vegard.ovesen@gmail.com, fenugrec <fenugrec@mail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768089611; l=12880;
 i=fenugrec@mail.com; s=20260110; h=from:subject:message-id;
 bh=sP5HPUrc3QNvvl+Ge3ijZd/GINyz/xMMHNznb65TW28=;
 b=Mk9gL5PkPpPEHGYl+3WgvISRRZYY7Lprp3huTZSy+WSp86V7bBj8nZMrvtocFvmpjGt3R3mD4
 1SJecHUzD0OBvBFq+qiSi5kkNzEwzgz42vnx1mrr1hTnm148KRRTCvO
X-Developer-Key: i=fenugrec@mail.com; a=ed25519;
 pk=lEWyQQHFuqFAWupzIuoHgEvr9FgSscJjTpmL97lrmOE=
X-Endpoint-Received: by B4 Relay for fenugrec@mail.com/20260110 with auth_id=597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Reorder some #define blocks
- Document mixer/volume levels
- Document some Ctl request fields (tag, len)
- replace some magic numbers with macros

No functional change intended. The information is based on reverse
engineering.

Signed-off-by: fenugrec <fenugrec@mail.com>
---
 sound/usb/mixer_s1810c.c | 204 ++++++++++++++++++++++++++++-------------------
 1 file changed, 124 insertions(+), 80 deletions(-)

diff --git a/sound/usb/mixer_s1810c.c b/sound/usb/mixer_s1810c.c
index fd9b4d11c7b2..9e9e2f2b6336 100644
--- a/sound/usb/mixer_s1810c.c
+++ b/sound/usb/mixer_s1810c.c
@@ -25,12 +25,6 @@
 #include "helper.h"
 #include "mixer_s1810c.h"
 
-#define SC1810C_CMD_REQ	160
-#define SC1810C_CMD_REQTYPE \
-	(USB_TYPE_VENDOR | USB_RECIP_DEVICE | USB_DIR_OUT)
-#define SC1810C_CMD_F1		0x50617269
-#define SC1810C_CMD_F2		0x14
-
 /*
  * DISCLAIMER: These are just guesses based on the
  * dumps I got.
@@ -42,9 +36,8 @@
  *  * b selects an input channel (see below).
  *  * c selects an output channel pair (see below).
  *  * d selects left (0) or right (1) of that pair.
- *  * e 0-> disconnect, 0x01000000-> connect,
- *	0x0109-> used for stereo-linking channels,
- *	e is also used for setting volume levels
+ *  * e level : see MIXER_LEVEL_* defines below.
+ *	Also used for setting volume levels
  *	in which case b is also set so I guess
  *	this way it is possible to set the volume
  *	level from the specified input to the
@@ -75,52 +68,98 @@
  * For output (0x65):
  *   * b is the output channel (see above).
  *   * c is zero.
- *   * e I guess the same as with mixer except 0x0109
- *	 which I didn't see in my dumps.
+ *   * e I guess the same as with mixer
+ *
+ */
+/** struct s1810c_ctl_packet - basic vendor request
+ * @selector: device/mixer/output
+ * @b: request-dependant field b
+ * @tag: fixed value identifying type of request
+ * @len: sizeof this struct - 8 (excludes first 2 fields)
+ *	i.e. for basic struct s1810c_ctl_packet: len is 5*4=0x14
+ * @c: request-dependant field c
+ * @d: request-dependant field d
+ * @e: request-dependant field e
  *
- * The two fixed fields have the same values for
- * mixer and output but a different set for device.
+ * See longer description above. This could be combined
+ * (as a union?) with the longer struct s1810c_state_packet
  */
 struct s1810c_ctl_packet {
-	__le32 a;
+	__le32 selector;
 	__le32 b;
-	__le32 fixed1;
-	__le32 fixed2;
+	__le32 tag;
+	__le32 len;
 	__le32 c;
 	__le32 d;
 	__le32 e;
 };
 
+/** selectors for CMD request
+ */
+#define SC1810C_SEL_DEVICE 0
+#define SC1810C_SEL_MIXER 0x64
+#define SC1810C_SEL_OUTPUT 0x65
+
+
+/** control ids */
 #define SC1810C_CTL_LINE_SW	0
 #define SC1810C_CTL_MUTE_SW	1
 #define SC1824C_CTL_MONO_SW	2
 #define SC1810C_CTL_AB_SW	3
 #define SC1810C_CTL_48V_SW	4
 
+/* USB Control (vendor) requests
+ */
+#define SC1810C_CMD_REQ	160
+#define SC1810C_CMD_REQTYPE \
+	(USB_TYPE_VENDOR | USB_RECIP_DEVICE | USB_DIR_OUT)
+#define SC1810C_CMD_TAG		0x50617269
+#define SC1810C_CMD_LEN		0x14
+
 #define SC1810C_SET_STATE_REQ	161
 #define SC1810C_SET_STATE_REQTYPE SC1810C_CMD_REQTYPE
-#define SC1810C_SET_STATE_F1	0x64656D73
-#define SC1810C_SET_STATE_F2	0xF4
+#define SC1810C_SET_STATE_TAG	0x64656D73
+#define SC1810C_SET_STATE_LEN	0xF4
 
 #define SC1810C_GET_STATE_REQ	162
 #define SC1810C_GET_STATE_REQTYPE \
 	(USB_TYPE_VENDOR | USB_RECIP_DEVICE | USB_DIR_IN)
-#define SC1810C_GET_STATE_F1	SC1810C_SET_STATE_F1
-#define SC1810C_GET_STATE_F2	SC1810C_SET_STATE_F2
-
-#define SC1810C_STATE_F1_IDX	2
-#define SC1810C_STATE_F2_IDX	3
+#define SC1810C_GET_STATE_TAG	SC1810C_SET_STATE_TAG
+#define SC1810C_GET_STATE_LEN	SC1810C_SET_STATE_LEN
+
+/** Mixer levels normally range from 0 (off) to 0x0100 0000 (0 dB).
+ * raw_level = 2^24 * 10^(db_level / 20), thus
+ * -3dB = 0xb53bf0 (technically, half-power -3.01...dB would be 0xb504f3)
+ * -96dB = 0x109
+ * -99dB = 0xBC
+ * PC software sliders cover -96 to +10dB (0x0329 8b08),
+ * but the value 0 (-inf dB) can be used when e.g. Mixer Bypass is enabled.
+ * Unclear what the hardware's maximum value is.
+ *
+ * Note, when a channel is panned to two channels (stereo),
+ * the mixer level is set to slider value (by default -96dB) minus 3dB,
+ * which explains the -99dB value seen in USB captures.
+ */
+#define MIXER_LEVEL_MUTE 0
+#define MIXER_LEVEL_N99DB 0xbc
+#define MIXER_LEVEL_N3DB 0xb53bf0
+#define MIXER_LEVEL_0DB 0x1000000
 
-/*
+/**
  * This packet includes mixer volumes and
  * various other fields, it's an extended
  * version of ctl_packet, with a and b
- * being zero and different f1/f2.
+ * being zero and different tag/length.
  */
 struct s1810c_state_packet {
 	__le32 fields[63];
 };
 
+/** indices into s1810c_state_packet.fields[]
+ */
+#define SC1810C_STATE_TAG_IDX	2
+#define SC1810C_STATE_LEN_IDX	3
+
 #define SC1810C_STATE_48V_SW	58
 #define SC1810C_STATE_LINE_SW	59
 #define SC1810C_STATE_MUTE_SW	60
@@ -134,16 +173,16 @@ struct s1810_mixer_state {
 };
 
 static int
-snd_s1810c_send_ctl_packet(struct usb_device *dev, u32 a,
+snd_s1810c_send_ctl_packet(struct usb_device *dev, u32 sel,
 			   u32 b, u32 c, u32 d, u32 e)
 {
 	struct s1810c_ctl_packet pkt = { 0 };
 	int ret = 0;
 
-	pkt.fixed1 = SC1810C_CMD_F1;
-	pkt.fixed2 = SC1810C_CMD_F2;
+	pkt.tag = SC1810C_CMD_TAG;
+	pkt.len = SC1810C_CMD_LEN;
 
-	pkt.a = __cpu_to_le32(a);
+	pkt.selector = __cpu_to_le32(sel);
 	pkt.b = __cpu_to_le32(b);
 	pkt.c = __cpu_to_le32(c);
 	pkt.d = __cpu_to_le32(d);
@@ -176,8 +215,8 @@ snd_sc1810c_get_status_field(struct usb_device *dev,
 	struct s1810c_state_packet pkt_in = { { 0 } };
 	int ret = 0;
 
-	pkt_out.fields[SC1810C_STATE_F1_IDX] = __cpu_to_le32(SC1810C_SET_STATE_F1);
-	pkt_out.fields[SC1810C_STATE_F2_IDX] = __cpu_to_le32(SC1810C_SET_STATE_F2);
+	pkt_out.fields[SC1810C_STATE_TAG_IDX] = __cpu_to_le32(SC1810C_SET_STATE_TAG);
+	pkt_out.fields[SC1810C_STATE_LEN_IDX] = __cpu_to_le32(SC1810C_SET_STATE_LEN);
 	ret = snd_usb_ctl_msg(dev, usb_sndctrlpipe(dev, 0),
 			      SC1810C_SET_STATE_REQ,
 			      SC1810C_SET_STATE_REQTYPE,
@@ -216,8 +255,8 @@ static int snd_s1810c_init_mixer_maps(struct snd_usb_audio *chip)
 	switch (chip->usb_id) {
 	case USB_ID(0x194f, 0x010c): /* 1810c */
 		/* Set initial volume levels ? */
-		a = 0x64;
-		e = 0xbc;
+		a = SC1810C_SEL_MIXER;
+		e = MIXER_LEVEL_N99DB;
 		for (n = 0; n < 2; n++) {
 			off = n * 18;
 			for (b = off; b < 18 + off; b++) {
@@ -234,22 +273,21 @@ static int snd_s1810c_init_mixer_maps(struct snd_usb_audio *chip)
 			 * I noticed on UC that DAW channels have different
 			 * initial volumes, so this makes sense.
 			 */
-			e = 0xb53bf0;
+			e = MIXER_LEVEL_N3DB;
 		}
 
 		/* Connect analog outputs ? */
-		a = 0x65;
-		e = 0x01000000;
+		a = SC1810C_SEL_OUTPUT;
 		for (b = 1; b < 3; b++) {
-			snd_s1810c_send_ctl_packet(dev, a, b, 0, 0, e);
-			snd_s1810c_send_ctl_packet(dev, a, b, 0, 1, e);
+			snd_s1810c_send_ctl_packet(dev, a, b, 0, 0, MIXER_LEVEL_0DB);
+			snd_s1810c_send_ctl_packet(dev, a, b, 0, 1, MIXER_LEVEL_0DB);
 		}
-		snd_s1810c_send_ctl_packet(dev, a, 0, 0, 0, e);
-		snd_s1810c_send_ctl_packet(dev, a, 0, 0, 1, e);
+		snd_s1810c_send_ctl_packet(dev, a, 0, 0, 0, MIXER_LEVEL_0DB);
+		snd_s1810c_send_ctl_packet(dev, a, 0, 0, 1, MIXER_LEVEL_0DB);
 
 		/* Set initial volume levels for S/PDIF mappings ? */
-		a = 0x64;
-		e = 0xbc;
+		a = SC1810C_SEL_MIXER;
+		e = MIXER_LEVEL_N99DB;
 		c = 3;
 		for (n = 0; n < 2; n++) {
 			off = n * 18;
@@ -257,26 +295,23 @@ static int snd_s1810c_init_mixer_maps(struct snd_usb_audio *chip)
 				snd_s1810c_send_ctl_packet(dev, a, b, c, 0, e);
 				snd_s1810c_send_ctl_packet(dev, a, b, c, 1, e);
 			}
-			e = 0xb53bf0;
+			e = MIXER_LEVEL_N3DB;
 		}
 
 		/* Connect S/PDIF output ? */
-		a = 0x65;
-		e = 0x01000000;
-		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 0, e);
-		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 1, e);
+		a = SC1810C_SEL_OUTPUT;
+		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 0, MIXER_LEVEL_0DB);
+		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 1, MIXER_LEVEL_0DB);
 
 		/* Connect all outputs (again) ? */
-		a = 0x65;
-		e = 0x01000000;
+		a = SC1810C_SEL_OUTPUT;
 		for (b = 0; b < 4; b++) {
-			snd_s1810c_send_ctl_packet(dev, a, b, 0, 0, e);
-			snd_s1810c_send_ctl_packet(dev, a, b, 0, 1, e);
+			snd_s1810c_send_ctl_packet(dev, a, b, 0, 0, MIXER_LEVEL_0DB);
+			snd_s1810c_send_ctl_packet(dev, a, b, 0, 1, MIXER_LEVEL_0DB);
 		}
 
 		/* Basic routing to get sound out of the device */
-		a = 0x64;
-		e = 0x01000000;
+		a = SC1810C_SEL_MIXER;
 		for (c = 0; c < 4; c++) {
 			for (b = 0; b < 36; b++) {
 				if ((c == 0 && b == 18) ||	/* DAW1/2 -> Main */
@@ -284,23 +319,29 @@ static int snd_s1810c_init_mixer_maps(struct snd_usb_audio *chip)
 					(c == 2 && b == 22) ||	/* DAW4/5 -> Line5/6 */
 					(c == 3 && b == 24)) {	/* DAW5/6 -> S/PDIF */
 					/* Left */
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 0, e);
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 1, 0);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 0, MIXER_LEVEL_0DB);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 1, MIXER_LEVEL_MUTE);
 					b++;
 					/* Right */
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 0, 0);
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 1, e);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 0, MIXER_LEVEL_MUTE);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 1, MIXER_LEVEL_0DB);
 				} else {
 					/* Leave the rest disconnected */
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 0, 0);
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 1, 0);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 0, MIXER_LEVEL_MUTE);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 1, MIXER_LEVEL_MUTE);
 				}
 			}
 		}
 
 		/* Set initial volume levels for S/PDIF (again) ? */
-		a = 0x64;
-		e = 0xbc;
+		a = SC1810C_SEL_MIXER;
+		e = MIXER_LEVEL_N99DB;
 		c = 3;
 		for (n = 0; n < 2; n++) {
 			off = n * 18;
@@ -308,29 +349,26 @@ static int snd_s1810c_init_mixer_maps(struct snd_usb_audio *chip)
 				snd_s1810c_send_ctl_packet(dev, a, b, c, 0, e);
 				snd_s1810c_send_ctl_packet(dev, a, b, c, 1, e);
 			}
-			e = 0xb53bf0;
+			e = MIXER_LEVEL_N3DB;
 		}
 
 		/* Connect S/PDIF outputs (again) ? */
-		a = 0x65;
-		e = 0x01000000;
-		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 0, e);
-		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 1, e);
+		a = SC1810C_SEL_OUTPUT;
+		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 0, MIXER_LEVEL_0DB);
+		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 1, MIXER_LEVEL_0DB);
 
 		/* Again ? */
-		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 0, e);
-		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 1, e);
+		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 0, MIXER_LEVEL_0DB);
+		snd_s1810c_send_ctl_packet(dev, a, 3, 0, 1, MIXER_LEVEL_0DB);
 		break;
 
 	case USB_ID(0x194f, 0x010d): /* 1824c */
 		/* Set all output faders to unity gain */
-		a = 0x65;
+		a = SC1810C_SEL_OUTPUT;
 		c = 0x00;
-		e = 0x01000000;
-
 		for (b = 0; b < 9; b++) {
-			snd_s1810c_send_ctl_packet(dev, a, b, c, 0, e);
-			snd_s1810c_send_ctl_packet(dev, a, b, c, 1, e);
+			snd_s1810c_send_ctl_packet(dev, a, b, c, 0, MIXER_LEVEL_0DB);
+			snd_s1810c_send_ctl_packet(dev, a, b, c, 1, MIXER_LEVEL_0DB);
 		}
 
 		/* Set
@@ -345,7 +383,7 @@ static int snd_s1810c_init_mixer_maps(struct snd_usb_audio *chip)
 		 * Daw 17 -> ADAT out 7, (left) Daw 18 -> ADAT out 8 (right)
 		 * Everything else muted
 		 */
-		a = 0x64;
+		a = SC1810C_SEL_MIXER;
 		/* The first Daw channel is channel 18 */
 		left = 18;
 
@@ -354,14 +392,20 @@ static int snd_s1810c_init_mixer_maps(struct snd_usb_audio *chip)
 
 			for (b = 0; b < 36; b++) {
 				if (b == left) {
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 0, 0x01000000);
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 1, 0x00);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 0, MIXER_LEVEL_0DB);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 1, MIXER_LEVEL_MUTE);
 				} else if (b == right) {
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 0, 0x00);
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 1, 0x01000000);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 0, MIXER_LEVEL_MUTE);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 1, MIXER_LEVEL_0DB);
 				} else {
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 0, 0x00);
-					snd_s1810c_send_ctl_packet(dev, a, b, c, 1, 0x00);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 0, MIXER_LEVEL_MUTE);
+					snd_s1810c_send_ctl_packet(dev,
+							a, b, c, 1, MIXER_LEVEL_MUTE);
 				}
 			}
 			left += 2;

-- 
2.52.0

