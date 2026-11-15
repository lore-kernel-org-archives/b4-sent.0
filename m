From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH 0/2] ASoC: qcom: Add the sound card of the Motorola
 Signature
Date: Mon, 16 Nov 2026 01:50:27 +0530
Message-Id: <20261116-vantage-sndcard-v1-0-df69a8759833@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBCF4avErBMaCYOuEi1Mx5oWFk5FEN09q
 +X34P0XCCUmgba4INHBwkvMwLIAN9k4kmKfDbrSBhGNOmzcbJ4lemeTVwGx1k6b0Pga8mtNFPj
 8il3/W/ZhJre9GbjvB/YVkhNzAAAA
X-Change-ID: 20261116-vantage-sndcard-f1142c26f7d4
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774027; l=1069;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=Oe6OeT8RwHKrTHvPAPN/a1CWaI7nMbR56LFpTyYY3Gs=;
 b=an9vVmlYBD2jj71PQbdMkvSlN1WF1nLtTvg+plnabK/0blSY1L2gBLnDwWkvvo+TDcBuRNmZL
 jvWHpds9rT+DcpXDqZN0yVwCofKjzuXdvYAM9FqKzWC2Dye+JMvc2iS
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Motorola Signature has two TFA9865 amplifiers on the senary MI2S
interface. They expect 32-bit I2S slots, which the sc8280xp machine
driver does not support so far. This series documents the sound card
compatible and adds an option for 32-bit MI2S backends together with the
card.

Tested on a Motorola Signature together with the TFA9865 driver: the
speaker and the earpiece play audio.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Venkat Yadlapati (2):
      ASoC: dt-bindings: qcom,sm8250: Add Motorola Signature sound card
      ASoC: qcom: sc8280xp: Add Motorola Signature sound card

 .../devicetree/bindings/sound/qcom,sm8250.yaml       |  1 +
 sound/soc/qcom/sc8280xp.c                            | 20 ++++++++++++++++++++
 2 files changed, 21 insertions(+)
---
base-commit: 4e019254b80b70f6fb90d17a50f211de1daf7ffe
change-id: 20261116-vantage-sndcard-f1142c26f7d4

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

