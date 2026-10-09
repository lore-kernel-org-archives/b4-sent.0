From: Dimitri Wegner <d@zerovolt.org>
Date: Fri, 09 Oct 2026 13:44:53 +0200
Subject: [PATCH] ALSA: usb-audio: Add feedback snap quirk for Mayflower ARC
 AMP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-mayflower-fb-v1-1-a84e82e05ac9@zerovolt.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAwNL3dzEyrSc/PLUIt20JN1EU0tj48RUS8NUC2MloJaCotS0zAqwcdG
 xtbUAm7JbC14AAAA=
X-Change-ID: 20261009-mayflower-fb-a5933ae91e83
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dimitri Wegner <d@zerovolt.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791546328; l=3572;
 i=d@zerovolt.org; s=20261009; h=from:subject:message-id;
 bh=CXyZ3NBP8s2rl6b2wgACCQszHWo9Z1js6VRgKjg/Rak=;
 b=AERUawIR4ry5e2wJ0eQNl58+jXIqDwcHd6XiY56WtLxqTSvCv2Roab1Dqv+0jgWcivEUrMlMq
 wMk07YKjcPnCk+n8y97AP5qn/yF96oGX18VHgaeaSRRSQ7uvFE/NxhU
X-Developer-Key: i=d@zerovolt.org; a=ed25519;
 pk=LvZetug4Pi01dwobr2q7O7RRa6xhnjAzWYqm6yuQZDI=
X-Endpoint-Received: by B4 Relay for d@zerovolt.org/20261009 with auth_id=1141
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Mayflower ARC AMP DAC (USB ID 0493:4170, MAG Technology front-end)
at times gets stuck reporting feedback of nominal+1 sample/frame (97
instead of 96 at 96 kHz) and does not recover. The driver follows this
feedback, and audible pops occur every 1-2s until the stream is
restarted.

Add a quirk for this device that ignores feedback values more than
1/128 (~0.8%) away from nominal and uses the nominal rate instead.
Normal feedback corrections are far smaller than that and pass
through unchanged. Other devices are not affected.

Signed-off-by: Dimitri Wegner <d@zerovolt.org>
---
Tested on this DAC at 96 kHz for ~10 weeks on kernels 7.1 and 7.2.
The pops no longer occur. The quirk triggered ~680 times over that
period, always with feedback 0x61.0000 against nominal 0x60.0000.
---
 sound/usb/card.h     |  1 +
 sound/usb/endpoint.c | 16 ++++++++++++++++
 sound/usb/quirks.c   | 10 ++++++++++
 3 files changed, 27 insertions(+)

diff --git a/sound/usb/card.h b/sound/usb/card.h
index 8299ac241c60..f956bcf00f77 100644
--- a/sound/usb/card.h
+++ b/sound/usb/card.h
@@ -123,6 +123,7 @@ struct snd_usb_endpoint {
 	unsigned int syncmaxsize;	/* sync endpoint packet size */
 	unsigned int fill_max:1;	/* fill max packet size always */
 	unsigned int tenor_fb_quirk:1;	/* corrupted feedback data */
+	unsigned int snap_fb_quirk:1;	/* ignore implausible feedback */
 	unsigned int datainterval;      /* log_2 of data packet interval */
 	unsigned int syncinterval;	/* P for adaptive mode, 0 otherwise */
 	unsigned char silence_value;
diff --git a/sound/usb/endpoint.c b/sound/usb/endpoint.c
index 879d0451536e..9c844c55ad3f 100644
--- a/sound/usb/endpoint.c
+++ b/sound/usb/endpoint.c
@@ -1908,6 +1908,22 @@ static void snd_usb_handle_sync_urb(struct snd_usb_endpoint *ep,
 	else
 		f >>= -ep->freqshift;
 
+	if (unlikely(sender->snap_fb_quirk) &&
+	    (f < ep->freqn - ep->freqn / 128 ||
+	     f > ep->freqn + ep->freqn / 128)) {
+		/*
+		 * Feedback deviates from nominal far beyond what real
+		 * clock differences can explain.  This firmware can get
+		 * stuck at nominal+1 sample per frame, causing audible
+		 * pops.  Trust the nominal rate instead.
+		 */
+		dev_warn_ratelimited(&ep->chip->dev->dev,
+				     "EP 0x%x: ignoring implausible feedback 0x%x.%04x (nominal 0x%x.%04x)\n",
+				     ep->ep_num, f >> 16, f & 0xffff,
+				     ep->freqn >> 16, ep->freqn & 0xffff);
+		f = ep->freqn;
+	}
+
 	if (likely(f >= ep->freqn - ep->freqn / 8 && f <= ep->freqmax)) {
 		/*
 		 * If the frequency looks valid, set it.
diff --git a/sound/usb/quirks.c b/sound/usb/quirks.c
index 170f68db74fa..fc377b7306f2 100644
--- a/sound/usb/quirks.c
+++ b/sound/usb/quirks.c
@@ -2198,6 +2198,16 @@ void snd_usb_endpoint_start_quirk(struct snd_usb_endpoint *ep)
 	     ep->chip->usb_id == USB_ID(0x1852, 0x5034)) && /* T+A Dac8 */
 	    ep->syncmaxsize == 4)
 		ep->tenor_fb_quirk = 1;
+
+	/*
+	 * Mayflower ARC AMP DAC (MAG Technology USB front-end): the
+	 * feedback can get stuck at nominal+1 sample per frame, causing
+	 * pops every 1-2 sec until stream restart.  Snap implausible
+	 * feedback to nominal.
+	 */
+	if (ep->chip->usb_id == USB_ID(0x0493, 0x4170) &&
+	    ep->type == SND_USB_ENDPOINT_TYPE_SYNC)
+		ep->snap_fb_quirk = 1;
 }
 
 /* quirk applied after snd_usb_ctl_msg(); not applied during boot quirks */

---
base-commit: f5e1a9a3fddab8421416b68bb132ae9626d07156
change-id: 20261009-mayflower-fb-a5933ae91e83

Best regards,
-- 
Dimitri Wegner <d@zerovolt.org>

