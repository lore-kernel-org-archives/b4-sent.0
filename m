From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/3] ath10k calibration variants for sdm845 phones
Date: Mon, 10 Nov 2025 16:37:45 +0100
Message-Id: <20251110-sdm845-calibration-variants-v1-0-2c536ada77c2@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMkGEmkC/x3MQQqDQAxA0atI1g0YqzL0KtJFOpNpAzqVREQQ7
 96hyweff4KLqTg8mhNMdnX9lgq6NRA/XN6Cmqqha7uBiFr0tIR+wMizvoy3muPOplw2x3HkdKe
 cQ4gM9bCaZD3+9+l5XT80qa2rbQAAAA==
X-Change-ID: 20251110-sdm845-calibration-variants-66ad31ff88ca
To: Dylan Van Assche <me@dylanvanassche.be>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=808; i=david@ixit.cz;
 h=from:subject:message-id; bh=SA6xGNbHN6b9mWUXMWX+xDVjRNsrYUlySOFnrE7Xc90=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEgbJg4ACLHbh+CbhUqCU1Iqlj6FH3DtSXLTrq
 fQ3jFDg3mOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRIGyQAKCRBgAj/E00kg
 clmpEACAIlVRtrvTyYZp+9rq6kTrYLEedExOTvk2bp+o5P41RWmS/9UPBatSv/Llu4740RzC4LM
 Uod9xCjWeiiSHpGdmRSD4IBWI9eXofqAHBK+saxCYTB9j8DsgASFQkvcSl3bgkl4VTE8py3jN7n
 mmX18oBN3AnEtRH0sa9btpNZExZHZtJNKQPdRqf/pCdxBaFYzdjS2OaOu6rnYdotONo/m85eQP2
 fhcjq4/nhgX7ZM3OSaOLOEQ3SgJhjXnRSueHftxQNria+eI0XMbtDIGW+YYpvouB2x/R5t4NuZm
 jCRNkxih6eaJitx3JHvLpO65wuyDaQafZ92+hJUGoM00k+50U8DBje/absmmoH/Zti0IhtTMLBf
 q9DORt/Q0SAovdjlITnU8/Y/W61887SEwQZMEXiKFiFycygkjdJPUNqHZWassdhCq6Ids7OytwJ
 dLY8HC0Nl2u+ADIsOUo8FQLC1EvmZtcBHXZkdSTsdD53iFt1Ke44lT7tqfAQ2wLUpnfbxwdqda2
 nwtKrzeMiS1dQH7Oee7UZ/oo3ogyGL9AV+hPJxgMfbrozSunPI6mhqEGcAToDEEBXR2KrwIVjNA
 RIo7NzFQnni8m2noT0iQNywfD0JYxB5vTHZSaw/iX41A/KTjS5Ix2WAqETaDeW4NCsa/Dya1mE3
 a6TxPt8EfDfjShg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Let's leaverage linux-firmware and use calibration from the board-2.bin.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Dylan Van Assche (3):
      arm64: dts: qcom: sdm845-oneplus: add ath10k calibration variant
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Add ath10k calibration variant
      arm64: dts: qcom: sdm845-shift-axolotl: Add ath10k calibration variant

 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi          | 1 +
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts            | 1 +
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 3 +++
 3 files changed, 5 insertions(+)
---
base-commit: ab40c92c74c6b0c611c89516794502b3a3173966
change-id: 20251110-sdm845-calibration-variants-66ad31ff88ca

Best regards,
-- 
David Heidelberg <david@ixit.cz>

