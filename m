From: David Heidelberg <david@ixit.cz>
Subject: [PATCH RFC v2 0/6] Speakers for Pixel 3 / 3 XL
Date: Thu, 03 Sep 2026 20:26:36 +0200
Message-Id: <20260903-pixel3-audio-v2-0-7c22ed915291@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/1WNSw6CMBCGr0JmbU1LpYArExMP4NawoDCVSQxgC
 wQlvbsFVi7/57eAQ0vo4BwtYHEiR10bRHyIoGrK9omM6qAh5rHiSkjW04wvycqxpo7pWht9yjH
 jMoUw6S2akK93D7jfrlDspsX3GK6HPVnNhtzQ2c/GncTW3xApT/4Rk2CcSa2UkTJLciMuNNNwr
 L5QeO9/GIJ0KMAAAAA=
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
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1964; i=david@ixit.cz;
 h=from:subject:message-id; bh=swhrbSD3HdK0AP2/e4RRVmalQc9TAXTMchmltY6AmDY=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmbvhftd5/BDYBefz6ncuVCrJMR4oiHkZymA2Y
 rhYtGPVMhOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapm74QAKCRBgAj/E00kg
 csJyD/9g2iBXVdmahUfPlV2YCq+X8+YMg4Kx9IpFkCAj5FPbRy+irB570MhZZ3CY7OZyYkp8KzZ
 9mnkOSzziuzrxGk1QQshe1sCxdnJ4SI+KUQkPaPmwUMIO9pLS1wdV/32+A9jSWmvQwVpiinN10R
 9suoCgEqM6b7VS9yFdPGHtYlfoxfO9YsbyGHgcyOCAPaVexup9C0m+mD9aZ0//PjzAn3qiL1q45
 Uow9oxLCfmgy9NOYoC646l65WsS9uon1EU89FFNYhaDwpjYOxbfcNUoTP5gBjo6Bk7m04Ltbx24
 +qSG4WJxwDGzK8lpvVzJENr87SYs1+vyuoy5a/eCR7U6iBFg5j4hwRxtn1AbhWHRHdevoUVRTu8
 9oCO9Gqvb5pS7SKVqTEzg2BHwEE2xeetR4qRmLLpEIvSqIUN2by+puo4Sd8yYCKQeixZvH3bozZ
 agmvaYIZ7nyGdkbs/Xlo1Ued9ZIQUFK6Sb7EWkAdX8hCoj5hnm563sT62NuGJkVP0xxH45aDdP3
 +kFV1S5kRtCepS0gDWgL/5hWKx1hynbTMxn1f/W81quT15eyKfHTWtl5CCLtMAF2vjC0zkT24Z5
 SZkQv2Qv13i1StKvYCYLtDbH6ypuAXSxkRPGox1sQv6ktdpplQ/2U6dH3KhdqgcRy7wC6FOGhvp
 mXaO/T/wg8x4bIQ==
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
heavily assisted by LLM.

David

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Device-tree name sorting, with exception keeping mm1-dai-link in it's
  place. (Konrad)
- Make set_tdm_slot cleaner and less leveled. (Konrad)
- Added TDM MIC defines in sdm845.c.
  Should we in capture use speaker mask?
- Renamed model from 'Google Pixel 3' to 'blueline', I would love to
  hear feedback on this one.
- Link to v1: https://lore.kernel.org/r/20260705-pixel3-audio-v1-0-3b66f33859f1@ixit.cz

---
David Heidelberg (6):
      ASoC: qcom: sdm845: Demystify TDM masks a bit
      ASoC: qcom: sdm845: use DSP_A format for TDM codec DAIs
      ASoC: qcom: sdm845: Use per-speaker RX masks for TDM slot assignment
      ASoC: qcom: sdm845: Set codec dai and component sysclk during startup
      ASoC: cs35l36: Implement set_tdm_slot to program RX and TX slots
      arm64: dts: qcom: sdm845-google: Add basic audio support

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 132 ++++++++++++++++++++-
 sound/soc/codecs/cs35l36.c                         |  44 +++++++
 sound/soc/qcom/sdm845.c                            |  49 ++++++--
 3 files changed, 213 insertions(+), 12 deletions(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260613-pixel3-audio-bdbfb49e8037

Best regards,
--  
David Heidelberg <david@ixit.cz>

