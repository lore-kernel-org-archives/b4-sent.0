From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC 0/3] Initial TFA2 family driver for tfa98xx
Date: Sun, 02 Aug 2026 14:42:39 +0200
Message-Id: <20260802-tfa98xx-upstream-v1-0-4dd55cdd658a@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDCwMj3ZK0REuLigrd0oLikqLUxFzdtEQLy+RUc/Mk87QkJaC2gqLUtMw
 KsJHRSkFuzkqxEMHi0qSs1OQSkGFKtbUAEn59dnkAAAA=
X-Change-ID: 20260802-tfa98xx-upstream-fa89ce77b7fb
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-sound@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1676; i=david@ixit.cz;
 h=from:subject:message-id; bh=LHd8IQtiCglZomN+UtHu/lSZZpaQjVgW1xEwT9BNfWk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbztEiZnS/iGr8vwcCTN7CWCBBcZcmD7+5eZR7
 Yet0CTQCqWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCam87RAAKCRBgAj/E00kg
 crFoD/43ZKjDyEsSBo7mc7a1yNkmdve6aqH1j4TkTcw5/MjdCAcsQyQOfMULb0K8+YtMFUFExCD
 RpDSUYzLrT8cZQmWBGWAwVL52s2YATl9nCvZCw+5+cBOSHcWNvDhoiimHaF79JaRJwsaX2GQmmt
 RPoLSZ+0466S7IMKC7BgNABxBbs6eX9HQ79gHTXTIubean9D/1YKnvtTEwNYd24OVJxbCCoIF/w
 Ts5W9IISU5YVcDF2xAF7l5m7Vze2W18Ue2vuMMwkc5V4FYQsghu/wD0rQ2FHfJEKLFtdKmUt0hS
 d7UTx0TKebC7iM6t6IquKVPgT/UAEqaQ8fIZ7G2HlMXhx2w/oxucWFEN1r12UxQPnswuuS2EtmS
 g5TjjqlLivGTYA/4CFOx733JIWkh0Izl3/kkfZMmeiKt5GSGG7ZXtKg8AjUP7550nxTUR9G6FgO
 XVizOuzif2V1VRYSSXHyemveLlc+XDly2/qRW91o3cpcE4ovj32sdusqmX1k75qwG/nTkmSKJZB
 TfO8dfw9gmyBKhB7LjitIDzz9V8WLWYBKny3aOMAvCnTvbXcwtf/N6fycnfGOmRjyvYUs/dywmh
 qF0LOoLWJSeh2mhdzRc19rDTaqdaxviC1Nxk0Zzy9uy+2+QuawA5hz32hLe1OVls/LmzMy42XRD
 QdS+9x3XauPPalQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce basic speaker support for the OnePlus 6T, using the tfa98xx
driver.

I've tested this driver only with speaker on OnePlus 6T. Please be
careful with volume levels, as the speaker protection are available only
with CoolFlux DSP enabled.

The downstream driver requires the firmware to bring up CoolFlux DSP,
but this driver completly avoids the DSP and thus operates without the
firmware.

This driver is different enough to not share the TFA1 codebase (tfa989x).

In the future, should be possible to extend this driver with other
tfa98xx TFA2 family based chips.

This RFC version mainly exist for early adopters (e.g. other phones
using tfa98xx amplifiers).

You can find the code at:
  https://codeberg.org/sdm845/linux/commits/branch/b4/tfa98xx-upstream

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (3):
      dt-bindings: sound: Add NXP TFA98XX TFA2 amplifier binding
      ASoC: codecs: tfa98xx: add driver for TFA2 amplifiers
      arm64: dts: qcom: sdm845-oneplus-fajita: Enable speaker codec

 .../devicetree/bindings/sound/nxp,tfa98xx.yaml     |  54 +++
 MAINTAINERS                                        |   7 +
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts |  22 +-
 sound/soc/codecs/Kconfig                           |  11 +
 sound/soc/codecs/Makefile                          |   2 +
 sound/soc/codecs/tfa98xx.c                         | 421 +++++++++++++++++++++
 6 files changed, 510 insertions(+), 7 deletions(-)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260802-tfa98xx-upstream-fa89ce77b7fb

Best regards,
--  
David Heidelberg <david@ixit.cz>

