From: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
Date: Thu, 02 Apr 2026 13:36:57 +0800
Subject: [PATCH] ALSA: usb-audio: apply quirk for MOONDROP JU Jiu
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260402-syy-v1-1-068d3bc30ddc@linux.dev>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDEwMj3eLKSt00IMvcJDnRzNzCSAmosqAoNS2zAmxKdCyEX1yalJWaXAL
 SqlRbCwCXVPFBZwAAAA==
X-Change-ID: 20260402-syy-f04074ca6782
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 zhanjun@uniontech.com, niecheng1@uniontech.com, kernel@uniontech.com, 
 =?utf-8?q?=E8=83=A1=E8=BF=9E=E5=8B=A4?= <hulianqin@vivo.com>, 
 Kagura <me@mail.kagurach.uk>, stable@vger.kernel.org, 
 Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1775108219; l=1249;
 i=cryolitia.pukngae@linux.dev; s=20260401; h=from:subject:message-id;
 bh=xZVGlTPTiBBef2iARx0bzLIZG1HD0uA8NNBbqan+D9U=;
 b=mN3VdwexnabeNtKme5CRAJUjMvNNN1boW1QiGM2+lyrdAETxPdhUbqOUPZwxKGaze+gHotoHZ
 NY8El/k505lBjtBAc29jTvff3lv6XwLH0SNoh7rBQtVFVtjk0ENHwwr
X-Developer-Key: i=cryolitia.pukngae@linux.dev; a=ed25519;
 pk=kF6wBkp7j9167keuk8Q9RvPgMRPuHlJztbLy0vbJ3K0=
X-Endpoint-Received: by B4 Relay for cryolitia.pukngae@linux.dev/20260401 with auth_id=712
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

It(ID 31b2:0111 JU Jiu) reports a MIN value -12800 for volume control, but
will mute when setting it less than -10880.

Thanks to my girlfriend Kagura for reporting this issue.

Cc: Kagura <me@mail.kagurach.uk>
Cc: stable@vger.kernel.org
Signed-off-by: Cryolitia PukNgae <cryolitia.pukngae@linux.dev>
---
Btw, is it a good idea for turn the volume_control_quirks from
switch-case to a table and sort it accroding to USB VID&PID?
---
 sound/usb/mixer.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/sound/usb/mixer.c b/sound/usb/mixer.c
index 69026cf54979..a25e8145af67 100644
--- a/sound/usb/mixer.c
+++ b/sound/usb/mixer.c
@@ -1204,6 +1204,13 @@ static void volume_control_quirks(struct usb_mixer_elem_info *cval,
 			cval->min = -11264; /* Mute under it */
 		}
 		break;
+	case USB_ID(0x31b2, 0x0111): /* MOONDROP JU Jiu */
+		if (!strcmp(kctl->id.name, "PCM Playback Volume")) {
+			usb_audio_info(chip,
+				       "set volume quirk for MOONDROP JU Jiu\n");
+			cval->min = -10880; /* Mute under it */
+		}
+		break;
 	}
 }
 

---
base-commit: 872c7433582a3570dd0c827967ba291450096bf0
change-id: 20260402-syy-f04074ca6782

Best regards,
--  
Cryolitia PukNgae <cryolitia.pukngae@linux.dev>

