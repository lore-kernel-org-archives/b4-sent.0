From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Subject: [PATCH 0/2] ASoC: Add LPASS VA CSR HeartBeat pulse clock support
Date: Tue, 14 Jul 2026 01:35:31 +0530
Message-Id: <20260714-master-v1-0-1ebe5993225e@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAtFVWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDc0MT3dzE4pLUIt3kRAvzJNM0Q8vEVAMloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0A+EPH3GoAAAA=
X-Change-ID: 20260714-master-ca87b5f19ae0
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 prasad.kumpatla@oss.qualcomm.com, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783973132; l=1707;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=fVYR9QJBEwKy0AHnOeETfy4OqM5XjQ3p+9fHZbjJe2c=;
 b=9JTqpKCkIA9r1TRRXYOCDAnpAg+56prw6wYSJ1wEy6qGQbUgggaAGrMc2rM+JwgJypzeQKNnU
 6i+2roaa0/DC/fk/yeqIhvSTLLgjpbNEWi77ar+WnevuZ6+Ke2YeZsV
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LPASS VA CSR block contains rate generator hardware that produces
a HeartBeat Pulse (also known as RateGen Pulse). This pulse
synchronizes the start of the DMAs and Codec Interfaces for the audio
usecases and can serve as a periodic wakeup source for the DSP.

This series adds the DT binding and driver support to model this
rate generator as a clock provider, and extends the VA macro binding
with a new hawi variant that consumes the heartbeatpulse clock
alongside its existing mclk, macro, and dcodec clocks.

Patch 1 adds the YAML binding for the new qcom,hawi-lpass-va-csr
clock provider node and extends qcom,lpass-va-macro to describe the
new qcom,hawi-lpass-va-macro compatible with its four-clock
constraint.

Patch 2 adds the lpass-va-csr driver that registers the
lpass_heartbeat_pulse clock and enables/disables the rate generator
via regmap when the clock consumer requests it.

Signed-off-by: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
---
Sarath Ganapathiraju (2):
      ASoC: dt-bindings: qcom,lpass-va-csr: Add HeartBeat pulse clock
      ASoC: Add LPASS VA CSR heartbeat pulse clock

 .../bindings/sound/qcom,lpass-va-csr.yaml          |  47 +++++++
 .../bindings/sound/qcom,lpass-va-macro.yaml        |  18 +++
 sound/soc/codecs/Kconfig                           |  13 ++
 sound/soc/codecs/Makefile                          |   2 +
 sound/soc/codecs/lpass-va-csr.c                    | 143 +++++++++++++++++++++
 5 files changed, 223 insertions(+)
---
base-commit: bee763d5f341b99cf472afeb508d4988f62a6ca1
change-id: 20260714-master-ca87b5f19ae0

Best regards,
--  
Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>

