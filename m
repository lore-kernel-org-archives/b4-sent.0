From: jiebing chen <jiebing.chen@amlogic.com>
Subject: [PATCH 0/3] Add support for S4 audio
Date: Mon, 13 Jan 2025 14:35:12 +0800
Message-Id: <20250113-audio_drvier-v1-0-8c14770f38a0@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACG0hGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDQ0MD3cTSlMz8+JSisszUIl0D80RTYwvDZBNLkyQloJaCotS0zAqwcdG
 xtbUAVy28hV4AAAA=
X-Change-ID: 20250110-audio_drvier-07a5381c494b
To: Jerome Brunet <jbrunet@baylibre.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, jiebing chen <jiebing.chen@amlogic.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736750144; l=1136;
 i=jiebing.chen@amlogic.com; s=20250110; h=from:subject:message-id;
 bh=jTNH048J8/e37rPd6oTYl8kF3JhnEDxWF56FPekHMjE=;
 b=zGklfCbSRH4yBG2RsEX2vhu/9ldv5Wjvg/qtKRhQIJW7IToz0zt7qIztoJwr2Tg7lR98AKjfB
 4eXneib0EVrClzcwjQKfqXlUYUGjcwHG4T4zCfukXL2UQFptj3PvQys
X-Developer-Key: i=jiebing.chen@amlogic.com; a=ed25519;
 pk=6rFvvF45A84pLNRy03hfUHeROxHCnZ+1KAGw/DoqKic=
X-Endpoint-Received: by B4 Relay for jiebing.chen@amlogic.com/20250110 with auth_id=316
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the tdmout pad control and tocodec control driver. 

Signed-off-by: jiebing chen <jiebing.chen@amlogic.com>
---
jiebing chen (3):
      ASoC: dt-bindings: Add Amlogic S4 audio
      ASoC: meson: s4:support for the on-chip audio
      arm64: dts: amlogic: Add Amlogic S4 Audio

 .../bindings/sound/amlogic,s4-tdmout-pad.yaml      |  36 ++
 .../bindings/sound/amlogic,s4-tocodec.yaml         |  44 +++
 .../boot/dts/amlogic/meson-s4-s805x2-aq222.dts     | 226 ++++++++++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          | 385 ++++++++++++++++++++-
 sound/soc/meson/Kconfig                            |  16 +
 sound/soc/meson/Makefile                           |   6 +
 sound/soc/meson/s4-pad-out-control.c               | 372 ++++++++++++++++++++
 sound/soc/meson/s4-tocodec-control.c               | 376 ++++++++++++++++++++
 sound/soc/meson/t9015.c                            |   5 +-
 9 files changed, 1461 insertions(+), 5 deletions(-)
---
base-commit: 6ecd20965bdc21b265a0671ccf36d9ad8043f5ab
change-id: 20250110-audio_drvier-07a5381c494b

Best regards,
-- 
jiebing chen <jiebing.chen@amlogic.com>

