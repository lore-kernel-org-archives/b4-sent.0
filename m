From: fenugrec <fenugrec@mail.com>
Subject: [PATCH v2 0/2] ALSA: usb-audio: presonus s1810 minor cleanup and
 document
Date: Sun, 11 Jan 2026 16:36:39 -0500
Message-Id: <20260111-preso_clean1-v2-0-44b4e5129a75@mail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WMywrCMBBFf6XM2khm1KCu/A8pksdoB9pGEglKy
 b8bu3d57uWcBTIn4QznboHERbLEuQFtOvCDnR+sJDQG0mQ0olbPxDne/Mh2RoWGHLlwdMGdoCn
 tvMt7zV37xoPkV0yftV7wt/4JFVRaeaYQdmz3B20uk5Vx6+MEfa31C5Q7o7SnAAAA
X-Change-ID: 20260110-preso_clean1-162b2bd8bdb9
To: Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, linux-kernel@vger.kernel.org, 
 roy.vegard.ovesen@gmail.com, mickflemm@gmail.com, 
 fenugrec <fenugrec@mail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768167408; l=1149;
 i=fenugrec@mail.com; s=20260110; h=from:subject:message-id;
 bh=yzHufDSAmjhHeJmk9w8TQVb2dLlvp/K/O4FdfAf56cU=;
 b=NS7SnewJkiNsiaE5u3gF9KrKwzjhSkmxkGL+BmXSbd7JtjiE06audx4q7H3IkcDYIY/qQEJO+
 hPFedFvtvGYA8qp0XR/uxL2m8o19S52LLawyK9FJ4JaT1rHLQaF/ckL
X-Developer-Key: i=fenugrec@mail.com; a=ed25519;
 pk=lEWyQQHFuqFAWupzIuoHgEvr9FgSscJjTpmL97lrmOE=
X-Endpoint-Received: by B4 Relay for fenugrec@mail.com/20260110 with auth_id=597
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

patch v2 : apologies, I had missed an __le32 field.

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
Changes in v2:
- fix an overlooked __le32 conversion for .tag and .len fields
- Link to v1: https://lore.kernel.org/r/20260110-preso_clean1-v1-0-ce2dd3ea4506@mail.com

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

