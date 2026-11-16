From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v2 0/2] ASoC: Add the NXP TFA9865 amplifier
Date: Mon, 16 Nov 2026 13:09:48 +0530
Message-Id: <20261116-vantage-tfa9865-v2-0-a93f976c9479@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ7CIBREr9L8tRhAWsGV9zBdIP21mAgNILFpu
 Lu0rl2+ycybFSIGixEuzQoBs43Wuwr80ICZtHsgsUNl4JR3jLGOZO2SrnEatZJdS6SULVUMlRA
 nqKs54Gg/u/HW/zi+7080adNsjcnG5MOyX2a29f7bMyOUoJQjHYwxgp+vi568Pxr/gr6U8gUur
 5ScwAAAAA==
X-Change-ID: 20261116-vantage-tfa9865-8885091e9443
To: Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794814788; l=2137;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=tnkLifR8VCWfkQcPWoCVb9z6fxtCg2U6s3ff2KleuLE=;
 b=trKZAVj0XI+huVOT7XsovWfy1l6Mcley8jLtxrKo4gmwvzA6yMQI14Ukt+YZctBe23AuEnVTf
 pRYH0FxBcPkB575YYPPBi2nFYxNad00IlzPPsXodWrXwgIPNw+UgaMR
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Motorola Signature has two NXP (now Goodix) TFA9865 mono class-D
speaker amplifiers. This series adds the devicetree binding and a driver.

The chip has no DSP and a different register map than the TFA989x parts
of tfa989x.c. The driver applies the initialization sequence for the
device revision, selects the I2S slot feeding the amplifier and powers
the amplifier and its boost converter up and down. The register settings
come from the NXP tfa98xx driver. Only the B0 revision and the 32-bit I2S
slots configured at reset are supported for now.

Tested on a Motorola Signature: with the matching sound card the speaker
and the earpiece play audio.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v2:
- Binding: drop the redundant sound-name-prefix entry (comes from
  dai-common.yaml).
- Driver: no longer mute/unmute from the trigger callback, the register
  access sleeps. The amplifier is now enabled from mute_stream and a DAPM
  event on the AMPE widget, only while the path is powered and the stream
  is unmuted, so toggling "Amp Switch" during playback keeps it in sync.
- Driver: reset the registers (I2CR) at the start of the initialization,
  so a rebind without a reset GPIO does not find MANSCONF still set.
- Link to v1: https://patch.msgid.link/20261116-vantage-tfa9865-v1-0-e88f0dccc427@yahoo.com

---
Venkat Yadlapati (2):
      ASoC: dt-bindings: Add NXP TFA9865 amplifier
      ASoC: codecs: Add NXP TFA9865 amplifier driver

 .../devicetree/bindings/sound/nxp,tfa9865.yaml     |  63 ++++
 MAINTAINERS                                        |   7 +
 sound/soc/codecs/Kconfig                           |  14 +
 sound/soc/codecs/Makefile                          |   2 +
 sound/soc/codecs/tfa9865.c                         | 393 +++++++++++++++++++++
 5 files changed, 479 insertions(+)
---
base-commit: 4e019254b80b70f6fb90d17a50f211de1daf7ffe
change-id: 20261116-vantage-tfa9865-8885091e9443

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

