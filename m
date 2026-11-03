From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH 0/5] media: i2c: it6625: add HDMI audio capture over I2S
Date: Tue, 03 Nov 2026 14:50:18 +0800
Message-Id: <20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACqE6WoC/x3MQQrCMBBA0auEWXegiRqTXqW4GJtRBzSGTCtC6
 N0NLt/i/wbKVVhhMg0qf0TlnTvsYGB5UL4zSuoGNzpvRxtxK7pWphfK6r07IT2VUJxipMCHYzi
 HdF2g56XyTb7/9XzZ9x9IUoyyagAAAA==
X-Change-ID: 20261019-upstream-it6625-alsa-i2s-9a8e34878dbc
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793688630; l=2997;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=Nm+fsrBt7LJXn+KC2GFbWQ/8X/G2DwmBWKzhDgqwqdg=;
 b=l1cuymu/R23iIZBojovlJlGBLcPG4Zzq0c6k9OGEhwLVRMnxJNdnaXjmTdbgQq579U1xp9d2j
 IRgp47ihNlvAVKetj6CyPRXPTVLn00zkav2H3wfZxLrlMNsPJwR3x2b
X-Developer-Key: i=Hermes.wu@ite.com.tw; a=ed25519;
 pk=qho5Dawp2WWj9CGyjtJ6/Y10xH8odjRdS6SXDaDAerU=
X-Endpoint-Received: by B4 Relay for Hermes.wu@ite.com.tw/20241230 with auth_id=310
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

IT6625 and IT6626 decode the audio of their HDMI input and output it on
an I2S interface, driving the bit and frame clocks themselves. The audio
format is not configurable by the host; the bridge reports the stream it
passes through in read-only status registers.

This series adds an ASoC capture DAI to the IT6625 V4L2 driver, so that
this audio can be recorded through a SoC I2S controller, for example
with simple-audio-card.

Patch 1 adds the '#sound-dai-cells' and 'ite,i2s-data-lanes' properties
to the binding.
Patch 2 documents the existing driver-specific audio controls.
Patch 3 decodes the audio status registers with FIELD_GET() and reads
them in one place.
Patch 4 adds the I2S capture DAI for LPCM.
Patch 5 extends the DAI to compressed (IEC 61937) and HBR streams, and
adds a read-only audio type control.

The series is based on media next and does not depend on the pending
IT6625 reset timing [1] and DV timings [2] series; either applies before
or after this one.

Tested by capturing HDMI audio from a signal generator, a PC and a
second HDMI output looped back to the bridge, through an SoC I2S
controller with simple-audio-card:
- LPCM at 32 kHz to 192 kHz with 2 channels on one data line and 8
  channels on four data lines, from 16-bit and 24-bit sources. 128 kHz
  was not captured, as the I2S controller used does not support it.
- AC-3, DTS-HD and TrueHD bitstreams, captured bit-exact, including
  high bit rate streams on four data lines.
- Rate, channel and coding changes, unplug, AV mute and pause/resume
  while capturing, and the audio controls with no capture open.
One-bit, multi-stream and 3D audio could not be tested; the driver
rejects them.

[1] https://lore.kernel.org/r/20261007-upstream-it6625-reset-delay-v2-0-c5d6b2522bbe@ite.com.tw
[2] https://lore.kernel.org/r/20261103-upstream-it6625-dv-timings-fix-v2-0-127b879da6d3@ite.com.tw

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Hermes Wu (5):
      dt-bindings: media: ite,it6625: add audio DAI properties
      media: Documentation: it6625: document the audio controls
      media: i2c: it6625: decode audio status fields with FIELD_GET()
      media: i2c: it6625: add I2S audio capture DAI
      media: i2c: it6625: capture compressed and HBR audio, not just LPCM

 .../devicetree/bindings/media/i2c/ite,it6625.yaml  |  23 +-
 .../userspace-api/media/drivers/index.rst          |   1 +
 .../userspace-api/media/drivers/it6625.rst         |  48 ++
 MAINTAINERS                                        |   1 +
 drivers/media/i2c/Kconfig                          |   1 +
 drivers/media/i2c/it6625.c                         | 879 +++++++++++++++++++--
 include/uapi/linux/it6625.h                        |  25 +
 7 files changed, 899 insertions(+), 79 deletions(-)
---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261019-upstream-it6625-alsa-i2s-9a8e34878dbc

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

