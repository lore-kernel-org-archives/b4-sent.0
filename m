From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/8] Speakers for Pixel 3 / 3 XL
Date: Thu, 24 Sep 2026 14:46:44 +0200
Message-Id: <20260924-pixel3-audio-v3-0-5d06460fc8a9@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/12Oyw6CMBBFf8V0bU0fUqgr/8O4oHQqkxjAFhqU8
 O8WWaAu752cc2ciATxCIKfdRDxEDNg2Kcj9jlR12dyAok2ZCCYUU1zSDke4S1oOFltqrHHmqKF
 gMicJ6Ty4dF90l+uaPTyGZO23ssbQt/75mYx8aVd7zrJfe+SUUWmUclIWmXb8jCP2h+pFFk0UG
 6rZ32NRJDSvhACreSb0FzrP8xveBPUs9gAAAA==
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2368; i=david@ixit.cz;
 h=from:subject:message-id; bh=WCww17Nbz5msM318Y+YiigiK/lae/kU3t0OrPKXBYxA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtRu33V70vGPgoK9kRrmF2zP8lixWUhtWMOIjj
 QJMDZckuYqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUbtwAKCRBgAj/E00kg
 csAxEAC2My1jTW1COPi529iCest+b+a27uNQ3d8MeloVj0nrXvwqgpr3nAGkGivckem3Mdet8Sa
 r77/Vy4C77CGHjL/LJp/t2rDg3J0rKk1bltL8M7Grrmbng6NuQadd1MxVhwKo+/7gJH+UQOz+v+
 LXzKf0Aod8+BlwK+ZTWKm/jYyoKz75yLJUOvgeYUcCAfz/WsqX30THqSr+uFc/kzP/H1igtGto6
 Caeq4tj0Wm7v9y6TWEPpfdjvI6o+NCWwHl29K5fDP/LwvJcYPjOWJ8w/306C/EJYnzGHihTwOmi
 op/7tUxtHEHXTfgKeYS2wny2elDUyapRfXvHrMrqv/FLDLVb/yHF9rHYygtevti86TM2B1tKhD6
 okd13WI5/WwJR7pE0NCvDIHaXq9XMvQ7h3jhiDa6kOOx1CxVm9RXL6NmKIauN1fJ+vh0QFgvyCD
 AIvUpd+sxxY4LO9Rdc9hbhzdZmWlrOmGTK+ryoTpqJhBo/wSrGAXRBPQEZwfZM4NXZcQtI3cjoz
 LeF+a96vKlumc3Ol6SmhRo8d8qg+T9u35M8F7kRmYfkxxcnfXXp3gDtNni+zfgOq5VjldjpVKtO
 Nk4W2nD3EVJQ8TBryNGGAjuPxuKvEVZjBTRzAyWVN24EG1BFbe6kmhLtnTimGBrQ6ejL8gp9fg1
 t/Gn1A0qp4i+svQ==
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
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260613-pixel3-audio-bdbfb49e8037

Best regards,
--  
David Heidelberg <david@ixit.cz>

