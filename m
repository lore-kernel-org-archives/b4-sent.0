From: Brian Harring <ferringb@gmail.com>
Subject: [PATCH v2 0/2] ALSA: usb-audio: Mixer quirks for ASRock X870E
 Taichi
Date: Thu, 19 Nov 2026 17:08:17 +0100
Message-Id: <20261119-alc4082-taichi-v2-0-03ad1352f807@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw7CIBBFf6WZtRhAaKkr/8N0gThtx/RhABtN0
 38X6trlSc49d4WAnjDAuVjB40KB5imBPBTgejt1yOieGCSXpRDcMDs4xY1k0ZLridlWVaZudVW
 eENLo6bGl9x68Nj8Or9sDXcyVbPQU4uw/++Misvc3vgjGWa2k1oYbI3R16UZLw9HNIzTbtn0Bv
 R2Byr4AAAA=
X-Change-ID: 20261108-alc4082-taichi-af4789f5763e
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, Brian Harring <ferringb@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2863; i=ferringb@gmail.com;
 h=from:subject:message-id; bh=z6tUUulU6XunTD/d4f4XsZ4mbFtZJgNSWiAiriTFi6Y=;
 b=owGbwMvMwCW26vPpzMb96zwZT6slMWT9l2fyv8A9kz3q05tXXvm3RJcyOl7dOJu7esqMgBf/8
 iu47RK2d3xkYRDjYpgppsjy4EvOG4X4W99cjS65wMxhZQIZIi3SwAAELAx8uYl5pUY6Rnqm2oZ6
 hkCGjlE8RE6PQSOzuLg0tUg3raDIIS+/JLEkMz+vWC+/IDWvIL1ALy0zrSQjI7+oOBVohF5eaom
 rgZuJmbOrs5GBqZuLo5uZiamxkYuRiYmjo5uxs5OZpYWhk5ujq4klAxenAMw1gb6MDBOtn4RsdN
 u7YblZ6vG4H89leysVruz6nVn0xGr1i+bXLrsZGTrilx9xY1howyO267jhpuwgwZbLznyL76Y/E
 3EV3bBtEz8A
X-Developer-Key: i=ferringb@gmail.com; a=openpgp;
 fpr=E9C121C8F3E4519A7E8E7E39C5068414B0C044B7
X-Endpoint-Received: by B4 Relay for ferringb@gmail.com/default with auth_id=1454
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ASRock X870E Taichi / Taichi Lite onboard audio (26ce:0a0b, Realtek
ALC4082) has its headphone volume control misassigned to the rear
output, resulting in the rear output being full volume and only
mutable, and the headphones falling back to software control.

Patch 1 uses the existing ALC4080 map to correct the assignment. This is
a fix: the headphones get their actual hardware control, and the rear
output falls back to software.

Patch 2 adds a hardware volume control for the rear output through the
ESS ES9219 DAC behind it.

Validation was against alsa-ucm-conf 1.2.16 and a 7.3.3 kernel. The
resultant changes to the PipeWire sinks are below:

7.3.3:
  SPDIF       HARDWARE HW_MUTE_CTRL DECIBEL_VOLUME LATENCY
  Speaker     HARDWARE HW_MUTE_CTRL HW_VOLUME_CTRL DECIBEL_VOLUME LATENCY
  Headphones  HARDWARE DECIBEL_VOLUME LATENCY

with remap:
  SPDIF       HARDWARE HW_MUTE_CTRL DECIBEL_VOLUME LATENCY
  Speaker     HARDWARE HW_MUTE_CTRL DECIBEL_VOLUME LATENCY
  Headphones  HARDWARE HW_MUTE_CTRL HW_VOLUME_CTRL DECIBEL_VOLUME LATENCY

with remap + ES9219:
  SPDIF       HARDWARE HW_MUTE_CTRL DECIBEL_VOLUME LATENCY
  Speaker     HARDWARE HW_MUTE_CTRL HW_VOLUME_CTRL DECIBEL_VOLUME LATENCY
  Headphones  HARDWARE HW_MUTE_CTRL HW_VOLUME_CTRL DECIBEL_VOLUME LATENCY

---
Changes in v2:

The sashiko issues reported in [1] should be fully addressed, enumerated
below.
- patch 1: sashiko: correct the comment stating the wrong feature unit.
- patch 2: sashiko: update the cache only upon success, and now do it per
  channel.  Channels are now named left/right for clarity.
- patch 2: use FIELD_* functions for the cache.
- Link to v1: https://patch.msgid.link/20261108-alc4082-taichi-v1-0-942558088157@gmail.com

For the usage of FIELD_* functions, I realize that may seem like overkill-
I did this for clarity, and since in probing the driver a bit further,
there is some logic in there related to microphone boosts.  That probably
has relevance to bugs like [2], despite that being ALC4080 specific.

[1] https://lore.kernel.org/linux-sound/sashiko-outbox-203925@kernel.org/
[2] https://bugzilla.kernel.org/show_bug.cgi?id=218913

To: Jaroslav Kysela <perex@perex.cz>
To: Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org
Signed-off-by: Brian Harring <ferringb@gmail.com>

---
Brian Harring (2):
      ALSA: usb-audio: Use ALC4080 mixer map for ASRock X870E Taichi
      ALSA: usb-audio: Add ES9219 speaker volume for ASRock X870E Taichi

 sound/usb/mixer_maps.c   |  14 ++--
 sound/usb/mixer_quirks.c | 177 +++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 186 insertions(+), 5 deletions(-)
---
base-commit: 94dd534d2eb96ceea4e36f3d3f0651a1abaa9b99
change-id: 20261108-alc4082-taichi-af4789f5763e

Best regards,
--  
Brian Harring <ferringb@gmail.com>

