From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/8] Speakers for Pixel 3 / 3 XL
Date: Thu, 24 Sep 2026 15:24:05 +0200
Message-Id: <20260924-pixel3-audio-v4-0-85b5d133aa5e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12Oyw6CMBBFf8V0bU0fUKgr/8O4oHQqkxjAAg1K+
 HeLLFCW907OuTORDjxCR86HiXgI2GFTx5AcD6SsivoOFG3MRDChmOKStjjCQ9JisNhQY40ziYa
 cyYxEpPXg4n3RXW9r9vAcorXfygq7vvGv72TgS7vaM5b+2wOnjEqjlJMyT7XjFxyxP5VvsmiC2
 FDNdo8FEdGsFAKs5qnQO1T+oCLZoTKiqWUqUcyVeaE3dJ7nDx1G0sAxAQAA
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
 David Heidelberg <david@ixit.cz>, 
 Charles Keepax <ckeepax@opensource.cirrus.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2569; i=david@ixit.cz;
 h=from:subject:message-id; bh=yiFJJpfxAOUSXtMXv/1T/r3LQB/vNcSfkYlLVDmONI8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtSR4W455qy2Owgl/D3Vwdcno3oKxnkcfY2als
 JwxGx4LJu6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUkeAAKCRBgAj/E00kg
 clS8EACiBSbeXFCoOQapy9QtgKWyLfmfQTY9jRkEsHqYXP/7OZOCv0MBBJe+6Cm+JcPrPYAfcZL
 66EwCnfjIg+Mg1/tTgktBD6PyiC2SObX+P2Otv1uiMg+Tqu74UHN2XElYWycJbqmnNN3f13DLFH
 7uEAmVu17M0MuSKd1ipvkd9HdSEuZrC8IwSLAWb6sPSVkFK5oBobC/SPEdNEkl99nnHNGquw4uX
 fmY13oABE80Yev+zfcsDy7cXsvYr5CBzYg7i3bHwJXP4URc47dyjNRWPcI+pecIc5dnTn3jtmrY
 /zqPodcJr7ir8zdFS/aVllrq3y45MsKnH5lu/8H3c8td0ezFmxKC8sJhHDHFv7GJwPtQZWhhWm8
 15rwWrztxrClBZ2r/cGiMocj/27zApjZpi1O8xvz8XMXR5Gr8yA/MIo9r64TETrqsKl3sFXgz1v
 nPa+m0frSJGWHv5DO4B3PPrrwPrL2xlinmdZPGfoRCgNOin4epNvNvEK4vEZyMovPMUzUuSVwMn
 EEX7h7NQHzCth0Blzw9lJFsTdsWg5AI48avBNxzWJjNIRVMcUd0Qwa/XJc7LX0PwmADneM2OzJi
 bYUd9ej9pq7Tw1FAAWFaKjy00DrJwoFm/Tztgz+1L2qLCrtjOU+aU/Uy6b7w/LowJH9PumJd6fG
 H4H03W5DfgNSXPw==
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

As per previous discussion not seding patch removing the "Input Mux"
which now interferes with TDM callback. If wanted, I can send it as a
follow-up.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v4:
- Rebase on top of d4d1619ebd55 ("ASoC: codecs: cs35l*: use .auto_selectable_formats") (Mark)
- Link to v3: https://patch.msgid.link/20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz

Changes in v3:
- De-RFC, applied Reviewed-by tag.
- Link to v2: https://patch.msgid.link/20260903-pixel3-audio-v2-0-7c22ed915291@ixit.cz

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
David Heidelberg (8):
      ASoC: qcom: sdm845: Demystify TDM masks a bit
      ASoC: qcom: sdm845: use DSP_A format for TDM codec DAIs
      ASoC: qcom: sdm845: Use per-speaker RX masks for TDM slot assignment
      ASoC: qcom: sdm845: Set codec dai and component sysclk during startup
      ASoC: cs35l36: Implement set_tdm_slot to program RX and TX slots
      arm64: dts: qcom: sdm845-google: Add basic audio support
      slimbus: qcom-ngd-ctrl: Remove data channels on stream disable
      arm64: dts: qcom: sdm845-google: Add WCD9340 codec and microphone capture

 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi | 195 ++++++++++++++++++++-
 drivers/slimbus/qcom-ngd-ctrl.c                    |  81 +++++++++
 sound/soc/codecs/cs35l36.c                         |  44 +++++
 sound/soc/qcom/sdm845.c                            |  49 ++++--
 4 files changed, 357 insertions(+), 12 deletions(-)
---
base-commit: 3d7783543c2646af69ad65825e810060494bea21
change-id: 20260613-pixel3-audio-bdbfb49e8037

Best regards,
--  
David Heidelberg <david@ixit.cz>

