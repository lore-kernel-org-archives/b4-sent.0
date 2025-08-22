From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Fri, 22 Aug 2025 20:58:08 +0800
Subject: [PATCH] ALSA: usb-audio: Add mute TLV for playback volumes on some
 devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250822-mixer-quirk-v1-1-b19252239c1c@uniontech.com>
X-B4-Tracking: v=1; b=H4sIAF9pqGgC/xWMQQqAIBAAvxJ7TjAtjL4SHSrXWiKrlSIQ/54dh
 2EmQkAmDNAVERgfCnT4DFVZwLyOfkFBNjMoqRrZKiV2epHFdRNvAqWpnZmM1UZDLk5Gl/V/64e
 UPo8oZktdAAAA
X-Change-ID: 20250822-mixer-quirk-e074f7b7d373
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 guanwentao@uniontech.com, niecheng1@uniontech.com, zhanjun@uniontech.com, 
 jeffbai@aosc.io, Guoli An <anguoli@uniontech.com>, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755867488; l=1344;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=CbanlkJhMdYwPVYycxuiequ7kNqYRPxDyM43A/LEFUw=;
 b=yCxulBPx293iMhoZV+mLoi+fq/AH8+tHNDLBwFVMn6E6UhqhkD30MdIhEOftKafe1+gSimyE5
 xepKmUPCykeB7T9W26JQvqix9eJaJpzL+4fglwhO8G5xr614LscM4pD
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Applying the quirk of that, the lowest Playback mixer volume setting
mutes the audio output, on more devices.

Link: https://gitlab.freedesktop.org/pipewire/pipewire/-/merge_requests/2514
Tested-by: Guoli An <anguoli@uniontech.com>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/mixer_quirks.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/sound/usb/mixer_quirks.c b/sound/usb/mixer_quirks.c
index 7cc27ae5512f07d5318443a7e03c1da7943bfb7a..6b47b3145d2cfd84bbadbe9e2b3e4383ed6828b4 100644
--- a/sound/usb/mixer_quirks.c
+++ b/sound/usb/mixer_quirks.c
@@ -4609,9 +4609,11 @@ void snd_usb_mixer_fu_apply_quirk(struct usb_mixer_interface *mixer,
 			snd_dragonfly_quirk_db_scale(mixer, cval, kctl);
 		break;
 	/* lowest playback value is muted on some devices */
+	case USB_ID(0x0572, 0x1b09): /* Conexant Systems (Rockwell), Inc. */
 	case USB_ID(0x0d8c, 0x000c): /* C-Media */
 	case USB_ID(0x0d8c, 0x0014): /* C-Media */
 	case USB_ID(0x19f7, 0x0003): /* RODE NT-USB */
+	case USB_ID(0x2d99, 0x0026): /* HECATE G2 GAMING HEADSET */
 		if (strstr(kctl->id.name, "Playback"))
 			cval->min_mute = 1;
 		break;

---
base-commit: 3957a5720157264dcc41415fbec7c51c4000fc2d
change-id: 20250822-mixer-quirk-e074f7b7d373

Best regards,
-- 
Cryolitia PukNgae <cryolitia@uniontech.com>

