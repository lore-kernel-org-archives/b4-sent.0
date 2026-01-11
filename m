From: fenugrec <fenugrec@mail.com>
Subject: [PATCH 0/2] ALSA: usb-audio: presonus s1810 minor cleanup and
 document
Date: Sat, 10 Jan 2026 19:00:02 -0500
Message-Id: <20260110-preso_clean1-v1-0-ce2dd3ea4506@mail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MWwqAIBAAryL7neD6IdVVIsLHVguhoRCBePekz
 2GYqVAoMxWYRYVMDxdOsQMOAvxp40GSQ2fQShuFqOSdqaTNX2QjSjTaaRdGF9wEPely5/ffLWt
 rH2Bv/0JeAAAA
X-Change-ID: 20260110-preso_clean1-162b2bd8bdb9
To: Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 roy.vegard.ovesen@gmail.com, fenugrec <fenugrec@mail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768089611; l=917;
 i=fenugrec@mail.com; s=20260110; h=from:subject:message-id;
 bh=H4N9PsBGEJPo4IAeq0qKuUDWqwRsGooNAVwhlwSdv3Y=;
 b=sRBThhzhd4AEjrhXoBisahm0ALdhRUUg3Gm8f+O9n147AezVgh4S9tfaUiHzT3D9+AbLq7PKQ
 Ld0cQQEyDuXAgRKB5egQRlVaZnBIPTm9yqZkpl74Mh2+ZsB51Uh+NaX
X-Developer-Key: i=fenugrec@mail.com; a=ed25519;
 pk=lEWyQQHFuqFAWupzIuoHgEvr9FgSscJjTpmL97lrmOE=
X-Endpoint-Received: by B4 Relay for fenugrec@mail.com/20260110 with auth_id=597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

- Use __le32 fields for structures sent/received over USB
 Addresses a comment from when this driver was initially merged:
  https://lore.kernel.org/all/s5hd0agcjw1.wl-tiwai@suse.de/

- Document constants and protocol details common to the Studio 1810 and
1824c devices

Except for a hypothetical big-endian platform (which I cannot test) where the first
commit would make a difference, both these should have no functional
change.

Signed-off-by: fenugrec <fenugrec@mail.com>
---
fenugrec (2):
      ALSA: usb-audio: presonus s18xx uses little-endian
      ALSA: usb-audio: clean up presonus s1810 consts

 sound/usb/mixer_s1810c.c | 224 ++++++++++++++++++++++++++++-------------------
 1 file changed, 134 insertions(+), 90 deletions(-)
---
base-commit: 7d0a66e4bb9081d75c82ec4957c50034cb0ea449
change-id: 20260110-preso_clean1-162b2bd8bdb9

Best regards,
-- 
fenugrec <fenugrec@mail.com>

