From: Brian Harring <ferringb@gmail.com>
Subject: [PATCH 0/2] Subject: [PATCH 0/2] ALSA: usb-audio: Mixer quirks for
 ASRock X870E Taichi
Date: Sun, 08 Nov 2026 19:58:36 +0100
Message-Id: <20261108-alc4082-taichi-v1-0-942558088157@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDVp669cRSyqpowI0iIScXfF8
 lu8d4FHR+ihii5weJCnZQ4QcQRm0HOPjLpgkFzmQnDF9GRSriTbNJmBmLZpoUqbFXmCEKLVoaX
 zG9bNb7+3I5rtvcB9P563ci5yAAAA
X-Change-ID: 20261108-alc4082-taichi-af4789f5763e
To: Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, Brian Harring <ferringb@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1872; i=ferringb@gmail.com;
 h=from:subject:message-id; bh=vrFXkHUybNoqbXxYoKxBLOsUmPlm1G96lF/xP/jdz/U=;
 b=owGbwMvMwCW26vPpzMb96zwZT6slMWR9OJaYfIRj5rKe2oOi+5ruWijVbJJ9dWvaTdeE7g9F+
 3WtmJ/ZdHxkYRDjYpgppsjy4EvOG4X4W99cjS65wMxhZQIZIi3SwAAELAx8uYl5pUY6Rnqm2oZ6
 hkCGjlE8RE6PQSOzuLg0tUg3raDIIS+/JLEkMz+vWC+/IDWvIL1ALy0zrSQjI7+oOBVohF5eaom
 rgZuJmbOrs5GBqZuLo5uZiamxkYuRiYmjo5uxs5OZpYWhk5ujq4klAxenAMw1C00Y/hcqHnQzFl
 U4M/uDeUza/WzP50vvblvc8SzgkppnmXTUw0RGhsXxYosCyzc5Vb+aFx6hN+2ZyG+PgzFm9uENk
 2Ya8ySd5QUA
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

Signed-off-by: Brian Harring <ferringb@gmail.com>
---
Brian Harring (2):
      ALSA: usb-audio: Use ALC4080 mixer map for ASRock X870E Taichi
      ALSA: usb-audio: Add ES9219 speaker volume for ASRock X870E Taichi

 sound/usb/mixer_maps.c   |  14 +++--
 sound/usb/mixer_quirks.c | 157 +++++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 166 insertions(+), 5 deletions(-)
---
base-commit: 94dd534d2eb96ceea4e36f3d3f0651a1abaa9b99
change-id: 20261108-alc4082-taichi-af4789f5763e

Best regards,
--  
Brian Harring <ferringb@gmail.com>

