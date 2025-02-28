From: jiebing chen <jiebing.chen@amlogic.com>
Subject: [PATCH v3 0/6] Add support for S4 audio
Date: Fri, 28 Feb 2025 16:04:08 +0800
Message-Id: <20250228-audio_drvier-v3-0-dbfd30507e4c@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPhtwWcC/13M0QrCIBiG4VsZHmf4q0PXUfcREebc9kOboSXF8
 N5zg4h1+H3wPjOJLqCL5FDNJLiEEf1UhthVxA5m6h3FtmzCGa8ZAKPm2aK/tCGhC5QpUwsNVjb
 ySkpyD67D18qdzmUPGB8+vFc9wfJ+IbGFElBGtQWpFOuENuxoxpvv0e6tH8lCJf7LOci/nJdcK
 K2hM0LZxm3znPMH59QOeOkAAAA=
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1740729872; l=1652;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=x2141hNFezK6mYwqWQI9537WXt7YCIJnzh0zwLxszv8=;
 b=D0A/1LXJsQqSGXP7YG/LoMPSb5KDruBemjmW99wLhc4KV+CLVtukH8eStEK+HV3PGNIo4yL/o
 9+irLhQOedMDqh4SfvL/ccR5s7Ie9UnlESjSA7Etj+eVhwTWTgYbH3T
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add s4 audio base driver. 

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
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
      clk: meson: axg-audio: Add the mclk pad div for s4
      ASoC: meson: s4: Add s4 tocodec driver
      arm64: dts: amlogic: Add Amlogic S4 Audio

 .../bindings/clock/amlogic,axg-audio-clkc.yaml     |  18 +
 .../bindings/sound/amlogic,g12a-toacodec.yaml      |   1 +
 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     | 219 +++++++++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          | 371 ++++++++++++++++++-
 drivers/clk/meson/axg-audio.c                      | 410 ++++++++++++++++++++-
 drivers/clk/meson/axg-audio.h                      |   4 +
 include/dt-bindings/clock/axg-audio-clkc.h         |  11 +
 sound/soc/meson/g12a-toacodec.c                    |  51 +++
 8 files changed, 1081 insertions(+), 4 deletions(-)
---
base-commit: 6ecd20965bdc21b265a0671ccf36d9ad8043f5ab
change-id: 20250110-audio_drvier-07a5381c494b

Best regards,
-- 
jiebing chen <jiebing.chen@amlogic.com>

