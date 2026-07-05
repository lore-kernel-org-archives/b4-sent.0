From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC 0/6] Speakers for Pixel 3 / 3 XL
Date: Sun, 05 Jul 2026 22:06:50 +0200
Message-Id: <20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFq5SmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDM0Nj3YLMitQcY93E0pTMfN2klKS0JBPLVAsDY3MloJaCotQ0oDzIuGi
 lIDdnpViIYFFqYSnQ6BKITGxtLQBUxJrleAAAAA==
X-Change-ID: 20260613-pixel3-audio-bdbfb49e8037
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>, 
 David Rhodes <david.rhodes@cirrus.com>, 
 Richard Fitzgerald <rf@opensource.cirrus.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 David Rhodes <drhodes@opensource.cirrus.com>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-sound@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, patches@opensource.cirrus.com, 
 devicetree@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1608; i=david@ixit.cz;
 h=from:subject:message-id; bh=S7zp59IV+EIooHSDmPyNRcnYaYzO7GZlM/V3CjNAfoQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqSrmMg/DrCOau8GMC+VQV0U2DfFXLz7KVPQk1/
 doa+FRM7piJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCakq5jAAKCRBgAj/E00kg
 ciGHEACP1Dg0KxLbYm20Ol6Bqx7HYPq3Evdjm9H4EdsvrD7/HUH1DHmlc8C2+g7xWtAFOJSwYv8
 CV0YayVLm9aOz0FW/dPE3gFX4m38tP1xCCcZj+c7dXfNbrtikqblCHCpppLBPIuyoEhuYFHZDBS
 HwmEnJdgGesuSlf65TYZzlTZ574ud8Kp3G7DNd9bnEyr3Ef4uCFN+OShWQgeK5+c4Us1sdYLfZA
 Ng+S5HF9JbFb1+9c3Uhs8WIrII6QCbcqQeeWTUWCFiYixLlCE8F87iS9EIgztD6UWAmb+WgJSYO
 Mk4xrIZht0+CXOIsBLqZItoUVQRzTVaSn1XONRVcXsw47CW4t/rRyEPqPoEHEHpOesFEszQ77m2
 4GCfkolQytcOa7RVHo6w2Gdm5W7/DmcQcyOH9CWuzfFI7Ns4hGjQuWHVJKtQy3S/4nMQ3nIOkic
 IqfPOa1CKSMPnra7g3xzuHUpTI4/ocbYBc7ko/L/VBjeeXCkfJanUFI3W+qI3gqlARlBLEBh1IC
 VV5EK0a4xFjL3qkjNjk98zNBztrPVCf2uSSlLKjy5lT7Lpl7knjdhWmklEZrOf8fYV/L7fDn4/p
 vBnUaUz0/tEDxIuUi2tR3q0zSq17citte4RNkXq0o6PjzppOMF2vp803Y4OvWo7kw4BnvF64/v9
 BRU1zBzG0wNAOfw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series address:

0. demistify the hex to BIT() macro and add left/right rx spk
1. most likely wrongly set DSP_B in sdm845.c
   my guess this is because TDM was never used in the mainline with
   sdm845
2. applying correct mask to left/right speaker for the TDM in sdm845.c,
   so both speakers can work simultaneusly
3. setting sysclk at startups, which some codecs need (such as cs35l36)
4. setting proper tdm slot in the cs35l36 driver
5. device-tree wiring for Pixel 3 / 3 XL

Consider my knowledge here limited, thus sending RFC. Some parts we're
heavily assisted by LLM - I believe I understand what I'm doing, but
my knowledge within audio realm is limited.

David

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (6):
      ASoC: qcom: sdm845: Demystify TDM masks a bit
      ASoC: qcom: sdm845: use DSP_A format for TDM codec DAIs
      ASoC: qcom: sdm845: Use per-speaker RX masks for TDM slot assignment
      ASoC: qcom: sdm845: Set codec dai and component sysclk during startup
      ASoC: cs35l36: Implement set_tdm_slot to program RX slot register
      arm64: dts: qcom: sdm845-google: Add basic audio support

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 133 ++++++++++++++++++++-
 sound/soc/codecs/cs35l36.c                         |  16 +++
 sound/soc/qcom/sdm845.c                            |  46 +++++--
 3 files changed, 183 insertions(+), 12 deletions(-)
---
base-commit: 2b763db0c2763d6bf73d7d3e69665222d1f377cf
change-id: 20260613-pixel3-audio-bdbfb49e8037

Best regards,
-- 
David Heidelberg <david@ixit.cz>

