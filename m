From: Jiebing Chen <jiebing.chen@amlogic.com>
Subject: [PATCH v7 0/5] Add support for S4 audio
Date: Wed, 21 Oct 2026 15:08:27 +0800
Message-Id: <20261021-audio_drvier-v7-0-2b9aeae9cb8a@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOtk2GoC/2XQy2rDMBCF4VcJWtdlRreRsup7hFJkXRJBExc5F
 S3B7145ENzYaHUE3y/QjY2x5Diy/e7GSqx5zMOlDXrZMX9yl2PscmibceAKEKFz3yEPH6HUHEs
 H5JQw6KWVPWvkq8SUf+65w3vbpzxeh/J7r1ecbx8h8Ryq2EFnPEoiSMI4eHPnz+GY/asfzmxOV
 b5wjnLFeeOCjMHkBHkbt1z849ysuGg89CkIUEBR+i2XCxdoV1w2rk07lFwgtFuuFk7rT6xqfl2
 iUgkjSS23XD+4BuR6xXXj1kahwCjVe/7Mp2n6A46+2ovlAQAA
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792566509; l=3939;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=92tlw/eLjbgUFICrONHVrpp0evhwHUkrfMNmLdgv62w=;
 b=Y49zpmumAFlrrAseuLzXViiU4ec+at/SA10D5ud27D2hjJNLQfEeDDySusQBR6sTZWaFv9Gn4
 Tda5dtAjRuKBwoQJ55fGVjsUU5QoSecYHhQMVXNHf87izHtc0pAwP7O
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series completes the end-to-end audio support
for S4 SoC from hardware bindings to driver implementation
and system integration.

1 Device Tree Bindings Updates 
Added audio power domain and S4 audio clock support for S4 SoC.
Added S4 audio tocodec binding support.

2 Driver Implementation
Implemented S4 tocodec driver for G12A architecture.
Added S4 audio clock support in AXG audio clock 

3 Device Tree Integration
Add Amlogic S4 audio subsystem support in arm64 DTS.

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
Changes in v7:
- Use the supply widget to manage the tocodec clock enable signal.
- Remove redundant MPLL frequencies.
- Fixed dt_binding warning
- Link to v6: https://lore.kernel.org/r/20260126-audio_drvier-v6-0-99e350855bc2@amlogic.com

Changes in v6:
- Fix the problem of string for Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yaml
- Remove clock pad register, and it will be submitted as an independent patch.
- Redescribe sound/soc/meson/g12a-toacodec.c
- Link to v5: https://lore.kernel.org/r/20250710-audio_drvier-v5-0-d4155f1e7464@amlogic.com

Changes in v5:
- Fix warning Documentation/devicetree/bindings/clock/amlogic,axg-audio-clkc.yam when make dt_binding_check
- The audio reg is mounted below the APB bus in dts file.
- Deal with pad clock in a distinct controller.
- Fix warning for sound/soc/meson/g12a-toacodec.c
- Link to v4: https://lore.kernel.org/r/20250319-audio_drvier-v4-0-686867fad719@amlogic.com

Changes in v4:
- fix dtb check warning 
- add maxItems of power domain for dt-bindings
- fixed audio clock pads regmap base and reg offset 
- use dapm widget to control tocodec bclk and mclk enable
- Link to v3: https://lore.kernel.org/r/20250228-audio_drvier-v3-0-dbfd30507e4c@amlogic.com

Changes in v3:
- remove g12a tocodec switch event
- Modify the incorrect title for dt-bindings
- Link to v2: https://lore.kernel.org/r/20250214-audio_drvier-v2-0-37881fa37c9e@amlogic.com

Changes in v2:
- remove tdm pad control and change tocodec base on g12a
- change hifipll rate to support 24bit
- add s4 audio clock
- Link to v1: https://lore.kernel.org/r/20250113-audio_drvier-v1-0-8c14770f38a0@amlogic.com

To: Neil Armstrong <neil.armstrong@linaro.org>
To: Jerome Brunet <jbrunet@baylibre.com>
To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Liam Girdwood <lgirdwood@gmail.com>
To: Mark Brown <broonie@kernel.org>
To: Jaroslav Kysela <perex@perex.cz>
To: Takashi Iwai <tiwai@suse.com>
To: Kevin Hilman <khilman@baylibre.com>
To: Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-sound@vger.kernel.org
Cc: linux-arm-kernel@lists.infradead.org

---
Jiebing Chen (5):
      dt-bindings: clock: meson: Add audio power domain for S4 soc
      dt-bindings: Asoc: axg-audio: Add S4 audio tocodec
      ASoC: meson: g12a-toacodec: Add S4 tocodec driver
      clk: meson: axg_audio: add S4 support
      arm64: dts: amlogic: Add Amlogic S4 Audio

 .../bindings/clock/amlogic,axg-audio-clkc.yaml     |  17 +-
 .../bindings/sound/amlogic,g12a-toacodec.yaml      |   1 +
 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     | 219 +++++++++++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          | 360 +++++++++++++++++++++
 drivers/clk/meson/axg-audio.c                      | 165 ++++++++++
 sound/soc/meson/g12a-toacodec.c                    |  49 +++
 6 files changed, 810 insertions(+), 1 deletion(-)
---
base-commit: a0c666c25aeefd16f4b088c6549a6fb6b65a8a1d
change-id: 20250110-audio_drvier-07a5381c494b

Best regards,
--  
Jiebing Chen <jiebing.chen@amlogic.com>

