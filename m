From: jiebing chen <jiebing.chen@amlogic.com>
Subject: [PATCH v4 0/6] Add support for S4 audio
Date: Wed, 19 Mar 2025 15:04:43 +0800
Message-Id: <20250319-audio_drvier-v4-0-686867fad719@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIts2mcC/2XM0QrCIBTG8VcZXmccPQ5dV71HRJi67UBluJIi9
 u5ZELV1+X3w+z/YEBKFga2qB0sh00DxVIZaVMz19tQFTr5sJkHWIARwe/UUdz5lComDtjUa4VS
 j9qyQcwot3d65zbbsnoZLTPd3PYvX+wnhNJQFB26cUFpDi8bC2h4PsSO3dPHIXqksv1wKNeOyc
 NTGiNaidk345/jDpZlxLNzvW49Qgw7KTfk4jk+GwYWoKAEAAA==
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742367997; l=1964;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=QDLS/Wim5Nao/KA6VbLQAFMVgRl1G3PVTVVLioUmM98=;
 b=arsiiQLog8tmh5gP4+Yx+BHf5KYBZ49xJ9Tq5lvwFBgSHMPE+mjSNadrBWP9eyjwZ+PL60eM/
 aR9NMYmt7EwAivyQQ5h11yaZcHAcGNBvDDoQzX1NJqNQskDFcKF/ih9
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add s4 audio base driver. 

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
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

---
jiebing chen (6):
      dt-bindings: clock: meson: Add audio power domain for s4 soc
      dt-bindings: clock: axg-audio: Add mclk and sclk pad clock ids
      dt-bindings: Asoc: axg-audio: Add s4 audio tocodec
      ASoC: meson: g12a-toacodec: Add s4 tocodec driver
      clk: meson: axg-audio: Add the mclk pad div for s4 chip
      arm64: dts: amlogic: Add Amlogic S4 Audio

 .../bindings/clock/amlogic,axg-audio-clkc.yaml     |  20 +-
 .../bindings/sound/amlogic,g12a-toacodec.yaml      |   1 +
 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     | 219 ++++++++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          | 372 ++++++++++++++++-
 drivers/clk/meson/axg-audio.c                      | 441 ++++++++++++++++++++-
 drivers/clk/meson/axg-audio.h                      |   6 +
 include/dt-bindings/clock/axg-audio-clkc.h         |  11 +
 sound/soc/meson/g12a-toacodec.c                    |  46 +++
 8 files changed, 1111 insertions(+), 5 deletions(-)
---
base-commit: 6ecd20965bdc21b265a0671ccf36d9ad8043f5ab
change-id: 20250110-audio_drvier-07a5381c494b

Best regards,
-- 
jiebing chen <jiebing.chen@amlogic.com>

