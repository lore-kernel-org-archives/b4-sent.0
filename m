From: Hermes Wu <Hermes.wu@ite.com.tw>
Subject: [PATCH v2 0/9] media: i2c: it6625: add HDMI audio capture over I2S
Date: Tue, 24 Nov 2026 11:04:37 +0800
Message-Id: <20261124-upstream-it6625-alsa-i2s-v2-0-a154685f6989@ite.com.tw>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMX+BGsC/3WNyw6CMBBFf4XM2iFtUWhZ+R+GRQujTCKPtBU1h
 H+34trlOck9d4VAnilAna3gaeHA05hAHTJoezveCLlLDEqoUgpp8DGH6MkOyLEs1QntPVhkFdB
 YTcVRV7pzLaT57OnKrz19aRL3HOLk3/vTIr/2F5Wi+B9dJAp0zkhSujJOyDNHyttpyOMTmm3bP
 j16ZyjBAAAA
X-Change-ID: 20261019-upstream-it6625-alsa-i2s-9a8e34878dbc
To: Hermes Wu <Hermes.Wu@ite.com.tw>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Hans Verkuil <hverkuil+cisco@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Mark Brown <broonie@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, linux-sound@vger.kernel.org, 
 linux-api@vger.kernel.org, Hermes Wu <Hermes.wu@ite.com.tw>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795489507; l=4862;
 i=Hermes.wu@ite.com.tw; s=20241230; h=from:subject:message-id;
 bh=vE3mJuwHS/greoet4bzWeW4mkaCUK2qOxxGLDNg9Lvw=;
 b=pgmH8rQI6cfhR1PMXnLyweUlaqR5DA93b4VupL8ghoS8YCi8aNyJgRvVfdXAB9lAcr+Up4+tN
 S5ntJGMQ5fIDMEZnp3G3VTIylfknggcFI05CuFqhiV+4UUHy8OBDd2d
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
with simple-audio-card. It also adds standard V4L2 controls for the
audio state of an HDMI receiver, and uses them in tc358743 and IT6625.

Patches 1 and 2 add read-only DV RX controls for the audio sampling
rate, audio presence and audio type to the V4L2 core.
Patch 3 makes tc358743 report the standard rate and presence controls
next to its custom ones.
Patch 4 adds the '#sound-dai-cells' and 'ite,i2s-data-lanes' properties
to the IT6625 binding.
Patch 5 decodes the IT6625 audio status registers with FIELD_GET() and
reads them in one place.
Patch 6 adds the I2S capture DAI for LPCM.
Patch 7 extends the DAI to compressed (IEC 61937) and HBR streams, and
reports the stream type through the standard audio type control.
Patch 8 switches IT6625 from its driver-specific audio rate and presence
controls to the standard ones.
Patch 9 removes the IT6625 driver-specific audio controls from the uAPI.
They came with the driver, which is in v7.4-rc1 but not in a released
kernel yet.

The series is based on media next.

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

Signed-off-by: Hermes Wu <Hermes.wu@ite.com.tw>
---
Changes in v2:
- New patches 1 and 2: standard read-only DV RX controls
  V4L2_CID_DV_RX_AUDIO_SAMPLING_RATE, V4L2_CID_DV_RX_AUDIO_PRESENT and
  V4L2_CID_DV_RX_AUDIO_TYPE, documented in ext-ctrls-dv.rst.
- New patch 3: tc358743 also reports the standard rate and presence
  controls.
- Drop the patch documenting the driver-specific IT6625 controls
  (it6625.rst); the standard controls are documented in the core.
- Patch 6 (I2S capture DAI): .shutdown re-arms the rate settle polling
  when a rate is still settling, and .startup, .hw_params and .prepare
  also update the V4L2 audio controls when they refresh the status.
- Patch 7: report the audio type through V4L2_CID_DV_RX_AUDIO_TYPE
  instead of a driver-specific control.
- New patch 8: IT6625 uses the standard rate and presence controls.
- New patch 9: remove the IT6625 driver-specific audio controls and the
  V4L2_CID_USER_IT6625_BASE reservation.
- Patch 4 (binding): add the Reviewed-by tag; no change.
- Rebase on the current media next, which now contains the IT6625 reset
  timing and DV timings fixes.
- Link to v1: https://lore.kernel.org/r/20261103-upstream-it6625-alsa-i2s-v1-0-bb91e2879b01@ite.com.tw

---
Hermes Wu (9):
      media: v4l2-ctrls: add DV RX audio sampling rate and present controls
      media: v4l2-ctrls: add the DV RX audio type control
      media: i2c: tc358743: also report the standard audio controls
      dt-bindings: media: ite,it6625: add audio DAI properties
      media: i2c: it6625: decode audio status fields with FIELD_GET()
      media: i2c: it6625: add I2S audio capture DAI
      media: i2c: it6625: capture compressed and HBR audio, not just LPCM
      media: i2c: it6625: use the standard audio rate and present controls
      media: uapi: it6625: remove the driver-specific audio controls

 .../devicetree/bindings/media/i2c/ite,it6625.yaml  |  23 +-
 .../userspace-api/media/v4l/ext-ctrls-dv.rst       |  35 +
 MAINTAINERS                                        |   1 -
 drivers/media/i2c/Kconfig                          |   1 +
 drivers/media/i2c/it6625.c                         | 905 ++++++++++++++++++---
 drivers/media/i2c/tc358743.c                       |  31 +-
 drivers/media/v4l2-core/v4l2-ctrls-defs.c          |  17 +
 include/uapi/linux/it6625.h                        |  25 -
 include/uapi/linux/v4l2-controls.h                 |  15 +-
 9 files changed, 910 insertions(+), 143 deletions(-)
---
base-commit: 48fe5a7834cc10081887d7bcd9ff0a4cadc3fa8c
change-id: 20261019-upstream-it6625-alsa-i2s-9a8e34878dbc

Best regards,
-- 
Hermes Wu <Hermes.wu@ite.com.tw>

