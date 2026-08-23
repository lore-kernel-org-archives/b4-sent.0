From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH 0/2] arm64: dts: qcom: sc8280xp-microsoft-blackrock: DP
 audio + 4-lane altmode
Date: Sun, 23 Aug 2026 10:35:27 +0200
Message-Id: <20260823-blackrock-audio-v1-0-f319387fc6a6@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avIrBPMJKqrRItJpxoKDaUIwrsnL
 d/i/xcSRaYEg3gh0s2Jgy+oKwF2Q7+SZFcMWulWdVrL+UC7x2B3iZfjIBvslSOD1iw9lOqMtPD
 zH8cp5w8o/BthYQAAAA==
X-Change-ID: 20260822-blackrock-audio-3a90de4ac4f9
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787474149; l=1091;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=fypSaFdXAtNFNmFOmAKyGhkU5hxq6SpoITbmIH89J3M=;
 b=+7+yi0gzX852t0gInBHlDBNBiFBVoltZWZgTgBl8szvNcwpHsEWahyMv5sBobudhJzJWcD8UN
 yxvf/8TYCYBAr0EQm5sjRcRNrn4fCuwn+P/u9pCgKnEb36Op/bmA5kC
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series contains some well-tested improvements for the Windows Dev
Kit 2023 (Blackrock).

Patch 1 is for enabling audio via DisplayPort outputs (DP0..DP2).

Patch 2 enables full 4-lane DP altmode on the USB-C ports and the
mini-DP connector. It's the same treatment that was previously done 
for the X13s.

Related (still pending) fix that makes DP altmode on USB0 work in both
orientations on that port:

  https://lore.kernel.org/all/20250609-blackrock-usb0-mux-v1-1-7903c3b071e4@oldschoolsolutions.biz/

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Jens Glathe (2):
      arm64: dts: qcom: sc8280xp-microsoft-blackrock: enable DisplayPort audio
      arm64: dts: qcom: sc8280xp-microsoft-blackrock: enable 4-lane DP altmode

 .../boot/dts/qcom/sc8280xp-microsoft-blackrock.dts | 149 +++++----------------
 1 file changed, 31 insertions(+), 118 deletions(-)
---
base-commit: 903c1cf6dff9964e71eda98a39e2e5d442050472
change-id: 20260822-blackrock-audio-3a90de4ac4f9

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

