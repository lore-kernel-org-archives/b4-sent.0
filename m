From: Cryolitia PukNgae <cryolitia@uniontech.com>
Date: Wed, 03 Sep 2025 13:09:48 +0800
Subject: [PATCH 4/4] ALSA: usb-audio: apply quirk for MOONDROP Quark2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250903-sound-v1-4-d4ca777b8512@uniontech.com>
References: <20250903-sound-v1-0-d4ca777b8512@uniontech.com>
In-Reply-To: <20250903-sound-v1-0-d4ca777b8512@uniontech.com>
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Mingcong Bai <jeffbai@aosc.io>, Kexy Biscuit <kexybiscuit@aosc.io>, 
 Nie Cheng <niecheng1@uniontech.com>, Zhan Jun <zhanjun@uniontech.com>, 
 Feng Yuan <fengyuan@uniontech.com>, Celeste Liu <uwu@coelacanthus.name>, 
 qaqland <anguoli@uniontech.com>, linux-doc@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia@uniontech.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756876185; l=882;
 i=cryolitia@uniontech.com; s=20250730; h=from:subject:message-id;
 bh=7pAYirEG6noZ5IXNpIYlyRGjI9vbDXOa2QYKKttvvvI=;
 b=G++rkHQVWT4ctoWBFWaBkDBP66wgyo7rvmHJAIrZIqjZVsBwYyoyP1LUt1nhxRDjgGa1RmAE5
 ebV8TrP6lF/CjRl2sNThL2XgI6qBiKNxV6CoZVjn9ubYedh7P/osLbW
X-Developer-Key: i=cryolitia@uniontech.com; a=ed25519;
 pk=tZ+U+kQkT45GRGewbMSB4VPmvpD+KkHC/Wv3rMOn/PU=
X-Endpoint-Received: by B4 Relay for cryolitia@uniontech.com/20250730 with auth_id=474
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It reports a MIN value -15360 for volume control, but will mute when
setting it less than -14208

Tested-by: Guoli An <anguoli@uniontech.com>
Signed-off-by: Cryolitia PukNgae <cryolitia@uniontech.com>
---
 sound/usb/mixer.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/usb/mixer.c b/sound/usb/mixer.c
index 5fcf1117777d1a1423806ea139a7692eea3c9ee8..34bcbfd8b54e66abc0229eefd354eb7bc4c01576 100644
--- a/sound/usb/mixer.c
+++ b/sound/usb/mixer.c
@@ -1182,6 +1182,13 @@ static void volume_control_quirks(struct usb_mixer_elem_info *cval,
 			cval->res = 1;
 		}
 		break;
+	case USB_ID(0x3302, 0x12db): /* MOONDROP Quark2 */
+		if (!strcmp(kctl->id.name, "PCM Playback Volume")) {
+			usb_audio_info(chip,
+				"set volume quirk for MOONDROP Quark2\n");
+			cval->min = -14208; /* Mute under it */
+		}
+		break;
 	}
 }
 

-- 
2.51.0

