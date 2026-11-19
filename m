From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH v3 0/2] ASoC: Add the NXP TFA9865 amplifier
Date: Thu, 19 Nov 2026 14:01:45 +0530
Message-Id: <20261119-vantage-tfa9865-v3-0-5257fa45df57@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNwQ7CIBAFf6XhLAYopeDJ/zAekC4WE4sBJDZN/
 12oFy/G42zezC4oQnAQ0aFZUIDsovNTgXbXIDPq6QrYDYURI0xQSgXOekq6nJPVSooOSyk7oig
 ozltUrEcA615b8XT+cHxebmBSzdTF6GLyYd5eZlp3v+uZYoJBSksGYwxn/XHWo/d74++o1jP74
 7Pia9Va1QujeK++/XVd39F2l2IAAQAA
X-Change-ID: 20261116-vantage-tfa9865-8885091e9443
To: Venkat Yadlapati <venkat.yadlapati@yahoo.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, phone-devel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795077105; l=2734;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=SAuP7YfgYJXDpKBvo+qN5QpyZqR/SPWVmvxD2Fy4rBQ=;
 b=3tgadcKcihpP0BgIT0cM6R8z5zLMi7y9KTgJDIP5dqlXMjyzOhOnmhMLpbDes+SMRzEHN7YPI
 74ZS4CNb3W1AnpcS2tMfsato6b+dd2yBql4uNzs9Xo9QP5QurMpAzRb
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
and the earpiece play audio. The register cache, rebinding both amplifiers
and switching an amplifier on and off during playback were tested too.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Changes in v3:
- Driver: cache the registers (REGCACHE_MAPLE) as suggested by Mark Brown,
  thanks for the review.
  Only the registers the chip changes by itself (SYS_CTRL0 with the
  self-clearing I2CR, the status and interrupt flags, the unlock keys)
  stay volatile. The cache is dropped after the I2CR reset in the
  initialization, so a rebind does not use stale values.
- Link to v2: https://patch.msgid.link/20261116-vantage-tfa9865-v2-0-a93f976c9479@yahoo.com

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
 sound/soc/codecs/tfa9865.c                         | 400 +++++++++++++++++++++
 5 files changed, 486 insertions(+)
---
base-commit: 4e019254b80b70f6fb90d17a50f211de1daf7ffe
change-id: 20261116-vantage-tfa9865-8885091e9443

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

