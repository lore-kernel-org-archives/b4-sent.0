From: Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
Subject: [PATCH v3 0/2] Add LPASS VA CSR HeartBeat pulse clock support
Date: Thu, 23 Jul 2026 16:40:39 +0530
Message-Id: <20260723-master-v3-0-3d67b79b0515@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAK/2YWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyjHUUlJIzE
 vPSU3UzU4B8JSMDIzMDcyMj3dzE4pLUIl1TM1PDtDTT5BSLNEsloOKCotS0zAqwQdGxEH5xaVJ
 WanIJSLdSbS0AdQ+05WoAAAA=
X-Change-ID: 20260722-master-5651ff5cd8f9
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-sound@vger.kernel.org, prasad.kumpatla@oss.qualcomm.com, 
 konrad.dybcio@oss.qualcomm.com, 
 Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784805040; l=3227;
 i=sarath.ganapathiraju@oss.qualcomm.com; s=default;
 h=from:subject:message-id; bh=l3oa2HuoVkp/Srw9vbsk3o2ccBl5T2Eqv6SyF+2OwqU=;
 b=iEzY8De2aHeoWy6q98XC3hNCEw/nOsH6IRa1vojz2agk3llSXCskCIMmrbziRwZ/mUQhFKARQ
 SsQHznwtoz0AltKYpy3Rz77DYAh+xgk40xsZ1ipy0oi6sAhbJ9cxGmr
X-Developer-Key: i=sarath.ganapathiraju@oss.qualcomm.com; a=ed25519;
 pk=4p2FWGXM+F2sir13Lu5stw5aKX5trUymK/ttESvgxQg=
X-Endpoint-Received: by B4 Relay for sarath.ganapathiraju@oss.qualcomm.com/default with auth_id=870
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LPASS VA CSR block contains rate generator hardware that produces
a HeartBeat Pulse (also known as RateGen Pulse). This pulse
synchronizes the start of the DMAs and Codec Interfaces for the audio
usecases and can serve as a periodic wakeup source for the DSP.

This series adds the DT binding and driver support to model this
rate generator as a clock provider.

Patch 1 adds the YAML binding for the new qcom,hawi-lpass-va-csr
clock provider node under Documentation/devicetree/bindings/clock/.

Patch 2 adds the lpass-va-csr driver under drivers/clk/qcom that
registers the lpass_heartbeat_pulse clock and enables/disables the
rate generator via regmap when the clock consumer requests it.

Changes in v3:
- Moved the qcom,lpass-va-csr binding from
  Documentation/devicetree/bindings/sound/ to
  Documentation/devicetree/bindings/clock/ since it is a pure clock
  provider with no ASoC dependency (Krzysztof).
- Moved the driver from sound/soc/codecs/ to drivers/clk/qcom/ for
  the same reason; sound/soc/codecs/Kconfig now selects
  QCOM_CLK_LPASS_VA_CSR instead of carrying the driver (Krzysztof).
- Rewrote the binding description to explain the hardware instead of
  duplicating schema text (Krzysztof).
- Dropped redundant reg and "#clock-cells" descriptions from the
  binding (Krzysztof).
- Switched from unevaluatedProperties to additionalProperties: false
  in the binding (Krzysztof).
- Renamed the example node to the generic clock-controller@7ee0000
  (Krzysztof).
- Dropped the qcom,lpass-va-macro binding extension patch — no
  in-tree user yet; will be resubmitted with the hawi DTSI changes.
- Link to v2: https://lore.kernel.org/linux-arm-msm/20260717-master-v2-0-ae200627ad62@oss.qualcomm.com/

---
To: Bjorn Andersson <andersson@kernel.org>
To: Michael Turquette <mturquette@baylibre.com>
To: Stephen Boyd <sboyd@kernel.org>
To: Brian Masney <bmasney@redhat.com>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Srinivas Kandagatla <srinivas.kandagatla@oss.qualcomm.com>
To: Liam Girdwood <lgirdwood@gmail.com>
To: Mark Brown <broonie@kernel.org>
To: Jaroslav Kysela <perex@perex.cz>
To: Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org
Cc: linux-clk@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-sound@vger.kernel.org
Cc: prasad.kumpatla@oss.qualcomm.com
Cc: konrad.dybcio@oss.qualcomm.com

---
Sarath Ganapathiraju (2):
      dt-bindings: clock: qcom: Add LPASS VA CSR HeartBeat pulse clock
      clk: qcom: Add LPASS VA CSR heartbeat pulse clock

 .../bindings/clock/qcom,lpass-va-csr.yaml          |  49 +++++++
 drivers/clk/qcom/Kconfig                           |  12 ++
 drivers/clk/qcom/Makefile                          |   1 +
 drivers/clk/qcom/lpass-va-csr.c                    | 143 +++++++++++++++++++++
 sound/soc/codecs/Kconfig                           |   1 +
 5 files changed, 206 insertions(+)
---
base-commit: a6092686b891422f5ba0106b5e0962aecd480b05
change-id: 20260722-master-5651ff5cd8f9

Best regards,
--  
Sarath Ganapathiraju <sarath.ganapathiraju@oss.qualcomm.com>

