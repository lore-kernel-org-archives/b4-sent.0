From: jiebing chen <jiebing.chen@amlogic.com>
Subject: [PATCH v2 0/5] Add support for S4 audio
Date: Fri, 14 Feb 2025 10:13:39 +0800
Message-Id: <20250214-audio_drvier-v2-0-37881fa37c9e@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANOmrmcC/1XM0QrCIBTG8VcZ5zrjqBtaV71HjDB124E2Q0uK4
 btngy66/H/w/VZIPpJPcGxWiD5TorDUELsG7GSW0TNytUGg6JBzZObpKFxczOQjQ2U6qbltD+0
 V6uUe/UCvjTv3tSdKjxDfm575d/1B8h/KnCHTlrdK4SC1wZOZb2Eku7dhhr6U8gGrkwkdqgAAA
 A==
X-Change-ID: 20250110-audio_drvier-07a5381c494b
To: Jerome Brunet <jbrunet@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 jian.xu@amlogic.com, shuai.li@amlogic.com, zhe.wang@amlogic.com, 
 jiebing chen <jiebing.chen@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739499221; l=1437;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=ODJBeAyu7yG9wfg1tMx7ifensJoaGn0MRyzsb8NOKTs=;
 b=IrYG6+tVk3zdh0UgKNgdgxRY+xWdt28tefwfjiNO5BANQ+TJ21Qx+JAznmInNJ7kI3fsjNZfz
 IWlwUx5kJtmA4NHvM8XL6TIpzmiiJ1CRbtjSwHivS4etqDvXEIsuYMa
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add s4 audio base driver. 

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
Changes in v2:
- remove tdm pad control and change tocodec base on g12a
- change hifipll rate to support 24bit
- add s4 audio clock
- Link to v1: https://lore.kernel.org/r/20250113-audio_drvier-v1-0-8c14770f38a0@amlogic.com

---
jiebing chen (5):
      dt-bindings: clock: axg-audio: Add mclk and sclk pad for s4
      dt-bindings: Asoc: axg-audio: Add s4 audio tocodec
      ASoC: meson: s4:support the audio clk
      ASoC: meson: s4:support audio tocodec
      arm64: dts: amlogic: Add Amlogic S4 Audio

 .../bindings/clock/amlogic,axg-audio-clkc.yaml     |  18 +
 .../bindings/sound/amlogic,g12a-toacodec.yaml      |   1 +
 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     | 219 +++++++++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          | 370 ++++++++++++++++++-
 drivers/clk/meson/axg-audio.c                      | 410 ++++++++++++++++++++-
 drivers/clk/meson/axg-audio.h                      |   4 +
 include/dt-bindings/clock/axg-audio-clkc.h         |  11 +
 sound/soc/meson/axg-card.c                         |   3 +-
 sound/soc/meson/g12a-toacodec.c                    |  64 ++++
 9 files changed, 1095 insertions(+), 5 deletions(-)
---
base-commit: 6ecd20965bdc21b265a0671ccf36d9ad8043f5ab
change-id: 20250110-audio_drvier-07a5381c494b

Best regards,
-- 
jiebing chen <jiebing.chen@amlogic.com>

