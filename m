From: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>
Subject: [PATCH v3 0/5] Add Audio Support for Kaanapali MTP Boards
Date: Wed, 15 Oct 2025 13:27:14 +0530
Message-Id: <20251015-knp-audio-v2-v3-0-e0e3e4167d87@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANpT72gC/03MSw6DIBSF4a0Yxr2Ep9aOuo+mgxvAShShoKaJc
 e8lHXVykm9w/oMUl70r5NYcJLvdFx+XCnlpiBlxeTnwtpoIJjRnXMG0JMDN+gi7gB5l12lhrOG
 a1EvKbvCfX+7xrB5yDLCO2eFfhPVcyVYpKkXfCnYFDiljQUunLSRcZ7zHUuh7w9nEEGgdcp5fK
 /Z7DaoAAAA=
X-Change-ID: 20251014-knp-audio-v2-9a37752cdc15
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rao Mandadapu <quic_srivasam@quicinc.com>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Jingyi Wang <jingyi.wang@oss.qualcomm.com>, 
 Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760515036; l=2706;
 i=prasad.kumpatla@oss.qualcomm.com; s=20251014; h=from:subject:message-id;
 bh=oVjglxA2YVL+EWAe8G0L/QPujTzNnzrVGFjD3bYF2Go=;
 b=6v34mFGcATJ0yTodD94cdvkszAGp2RJ7NLQbNiAVtOYGS2We3CTlm4YnUqX0oqBwxwDO+ZJTn
 W/+3gQVz8sIAtgwa7d+LGBzCwoIcwmNuqOe0zGhGTzYtKMBwelJKgrb
X-Developer-Key: i=prasad.kumpatla@oss.qualcomm.com; a=ed25519;
 pk=I3mn8JNlYnnm7frqMGXms1Rm2H+0gpAfknMlnBYqCzw=
X-Endpoint-Received: by B4 Relay for prasad.kumpatla@oss.qualcomm.com/20251014 with auth_id=541
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add audio support for Kaanapali MTP boards. Introduces supporting
dependencies required to enable audio functionality on MTP platforms.
These changes have been validated on Kaanapali MTP hardware.

Signed-off-by: Jingyi Wang <jingyi.wang@oss.qualcomm.com>
Signed-off-by: Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>

Changes in [v3]:
	- Correct SoB chain, comments from Krzysztof.
	- Link to v2: https://lore.kernel.org/linux-arm-msm/20251009143644.3296208-1-prasad.kumpatla@oss.qualcomm.com/

Changes in [v2]:
	- Addressed compilation issue for lpass version check patch.
	- Sorted compatible string in machine driver.
	- Link to v1: https://lore.kernel.org/linux-arm-msm/20250924-knp-audio-v1-0-5afa926b567c@oss.qualcomm.com/

Konrad Dybcio (1):
  ASoC: codecs: va-macro: Rework version checking

Prasad Kumpatla (4):
  ASoC: dt-bindings: qcom,sm8250: Add kaanapali sound card
  ASoC: qcom: sc8280xp: Add support for Kaanapali
  dt-bindings: soundwire: qcom: Add SoundWire v2.2.0 compatible
  ASoC: dt-bindings: qcom: Add Kaanapali LPASS macro codecs

 .../bindings/sound/qcom,lpass-rx-macro.yaml   |  1 +
 .../bindings/sound/qcom,lpass-tx-macro.yaml   |  1 +
 .../bindings/sound/qcom,lpass-va-macro.yaml   |  1 +
 .../bindings/sound/qcom,lpass-wsa-macro.yaml  |  1 +
 .../bindings/sound/qcom,sm8250.yaml           |  1 +
 .../bindings/soundwire/qcom,soundwire.yaml    |  1 +
 sound/soc/codecs/lpass-va-macro.c             | 90 +++++++++++++------
 sound/soc/qcom/sc8280xp.c                     |  1 +
 8 files changed, 70 insertions(+), 27 deletions(-)

--
2.34.1

---
Konrad Dybcio (1):
      ASoC: codecs: va-macro: Rework version checking

Prasad Kumpatla (4):
      ASoC: dt-bindings: qcom,sm8250: Add kaanapali sound card
      ASoC: qcom: sc8280xp: Add support for Kaanapali
      dt-bindings: soundwire: qcom: Add SoundWire v2.2.0 compatible
      ASoC: dt-bindings: qcom: Add Kaanapali LPASS macro codecs

 .../bindings/sound/qcom,lpass-rx-macro.yaml        |  1 +
 .../bindings/sound/qcom,lpass-tx-macro.yaml        |  1 +
 .../bindings/sound/qcom,lpass-va-macro.yaml        |  1 +
 .../bindings/sound/qcom,lpass-wsa-macro.yaml       |  1 +
 .../devicetree/bindings/sound/qcom,sm8250.yaml     |  1 +
 .../bindings/soundwire/qcom,soundwire.yaml         |  1 +
 sound/soc/codecs/lpass-va-macro.c                  | 90 +++++++++++++++-------
 sound/soc/qcom/sc8280xp.c                          |  1 +
 8 files changed, 70 insertions(+), 27 deletions(-)
---
base-commit: 2b763d4652393c90eaa771a5164502ec9dd965ae
change-id: 20251014-knp-audio-v2-9a37752cdc15

Best regards,
-- 
Prasad Kumpatla <prasad.kumpatla@oss.qualcomm.com>

