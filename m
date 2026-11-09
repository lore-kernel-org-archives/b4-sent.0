From: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
Subject: [PATCH 0/4] ASoC: cs35l45: Adds support for brownout prevention
 engines
Date: Mon, 09 Nov 2026 11:57:02 -0600
Message-Id: <20261109-cs35l45-bpe-v1-0-9d7bc95a90a4@opensource.cirrus.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG4J8moC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQwMj3eRiY9McE1PdpIJUXWMTA3MLg1RLM7OUNCWgjoKi1LTMCrBp0bG
 1tQCfyX8bXQAAAA==
To: David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-sound@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794247023; l=2099;
 i=rriveram@opensource.cirrus.com; s=20261106; h=from:subject:message-id;
 bh=PtyzFMLYZ2W+DMpbpRtm8ckdAT7wzVIuyr4J6iCsXHc=;
 b=JKz/iV5I1OQGOI3J+aP4R6qwPniwE64mXmsM4v8opWLqKNVyCJD8k1xxR+sNjKfbZZjhT4oSY
 xkkuc2437obDbq+Zti+z3//bHQFryjkO7dLVHD0WEGykZY0LN6u7i6Y
X-Developer-Key: i=rriveram@opensource.cirrus.com; a=ed25519;
 pk=k/iAEAtSPXvaWRDFupudzm6His7B7iJP1uiZ578a7Y8=
X-Endpoint-Received: by B4 Relay for rriveram@opensource.cirrus.com/20261106 with auth_id=1437
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The CS35L45 amplifier has two independent brownout prevention engines
used to prevent system brownout events induced by transient audio peaks.

The amplifier brownount prevention engine (ABPE) monitors the battery
voltage and applies attenuation to audio output in terms of either
decibles, voltage, or wattage. The ABPE response is configured across
four thresholds with four corresponding attenuation values. The attack,
hold, and release parameters of the associated limiter are also
configurable.

The boost converter brownout prevention engine (BBPE) monitors the
battery voltage and the current passing through the inductor in the
boost converter circuit and applies current limit to the boost
converter. The BBPE can be configured to monitor either both the battery
voltage and inductor current or only the battery voltage. When operating
in the combined response mode, the more conservative limitis applied.
The thresholds for the voltage response are configurable across four
levels and the thresholds for the inductor current response are
configurable across three levels. The BBPE's attack, hold, and release
parameters are configurable for both of the response limiters. 

Signed-off-by: Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>
---
Ricardo Rivera-Matos (4):
      ASoC: dt-bindings: cs35l45: Adds ABPE properties
      ASoC: cs35l45: Adds support for ABPE feature
      ASoC: dt-bindings: cs35l45: Adds Boost BPE properties
      ASoC: cs35l45: Adds Boost BPE configuration

 .../devicetree/bindings/sound/cirrus,cs35l45.yaml  | 415 ++++++++++++++
 include/dt-bindings/sound/cs35l45.h                |  45 ++
 sound/soc/codecs/cs35l45-tables.c                  |  95 ++++
 sound/soc/codecs/cs35l45.c                         | 601 +++++++++++++++++++++
 sound/soc/codecs/cs35l45.h                         | 193 +++++++
 5 files changed, 1349 insertions(+)
---
base-commit: cde5523c75f1320a55ac1d55a717ccbb566557f0
change-id: 20261102-cs35l45-bpe-340780e966df

Best regards,
-- 
Ricardo Rivera-Matos <rriveram@opensource.cirrus.com>

