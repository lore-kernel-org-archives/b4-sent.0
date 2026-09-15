From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] Introduce support for Xiaomi Mi 8
Date: Tue, 15 Sep 2026 16:32:23 +0200
Message-Id: <20260915-dipper-v2-0-cbade54919ee@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zXMQQ7CIBCF4as0sxYzYLHoynuYLiwMdjYtgYZUG
 +4u1rj8X16+DRJFpgTXZoNImRPPUw11aMCOj+lJgl1tUKjO2CkUjkOgKIx3Jy+p7fRgoZ5DJM/
 rDt372iOnZY6v3c3yu/4Ig5c/kaVAQUPrNEoy2vkbr7wc7Rv6UsoHjb5qS5oAAAA=
X-Change-ID: 20260720-dipper-8fd3f1e475bc
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1593; i=david@ixit.cz;
 h=from:subject:message-id; bh=q79L61CA7e2y8xizqfBNTzm3tp/94ga0fZ23l5wPvDo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqVb6LsUVTVE683mcrWSWmXyTRm5z0DXFx6PuW
 vzBcW+yLC+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqlW+gAKCRBgAj/E00kg
 cuckEACkt2DxySYgI2eP6FvS2n5LonF9gB5/KkvaIM+qn0yhegFV1qCnf7C9KOGkLGt/IKr7nmd
 beo1vY1bDagxznjNVPgh8dc+6+NSs9r3Y6snIIC6Ytk3Wqy21UXaaYHjDYl52PQtlPw3T+GoRGO
 bD1pRaAiJYaTELtLhyLuZcPBTRQQmrkT84ed29reEil14idMCM5KfLlYycz40k9sFfBCEWhZ987
 BjQWm8qfg7BZuCl1laA5T6q4otK3Yhoa5My06OdbQnf0WCfXtOEgrfuFxLAXKM+MQyZJGivCKBy
 L45OoKzxXebN6uuF24ktqfvF0BDUXhReoQLDe5AKukv1jdtRv6h0mVXkreiOdm5Mut7dRpcXWkp
 hXD64Ir7eC1DaVeb9ej/1ZgU/SD7pJ6hKyuM8ZLKCPVfcT1m+7E6420Yz/SE0vHsjfcur1ni+vS
 fW8o0wvsGNHrmVyIuCD8feHmISeQ4hfkU7GV/P+3T+2yQQQ6ihgO24sX6omtY6QvvHKPQk0cOOa
 ZhMLvqrNnaoPrGK1k1tqKUAtT/bkuEyu3wfvZDkAteAROkUVE4RiXvaZ/cg0wX4XNJnmt0ipE5i
 HnnVLyT77vT/FDPReu8fulDjh7qRr2Sz4tldobTzf+kjrl8tfMOeIc1wngu/pRLMFFQI25JD2/d
 +6g5knRTh6G8UBQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Currently only Mi 8 itself is supported, but the
sdm845-xiaomi-dipper-common should ensure, that other family members
such as Mi 8 Pro, Mi 8 Explorer will be likely supported too without
much of additional work. These variants should differ only in the small
details (such as battery size, fingerprint sensor etc.).

Minimal viable support for xiaomi-dipper. Enough to get basic u-boot and
Linux functional. More improvements will follow.

The display and touchscreen support are work-in-progress, but waiting
for other bits to land.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Deduplicate simplified xiaomi,dipper compatbile from the dt-binding.
- Reorder reserved-memory by address.
- vreg-s4a-1p8 -> regulator-vreg-s4a-1p8. (Konrad)
- adsp firmware moved to dipper variant (as I cannot test others)
  (Konrad)
- Removed Bluetooth path comment. (Konrad)
- Link to v1: https://patch.msgid.link/20260809-dipper-v1-0-eb4d501e85df@ixit.cz

---
David Heidelberg (2):
      dt-bindings: arm: qcom: Add Xiaomi Mi 8 family compatibles
      arm64: dts: qcom: add Xiaomi Mi 8 (dipper)

 Documentation/devicetree/bindings/arm/qcom.yaml    |   9 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/sdm845-xiaomi-dipper-common.dtsi | 607 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-dipper.dts  |  36 ++
 4 files changed, 653 insertions(+)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260720-dipper-8fd3f1e475bc

Best regards,
--  
David Heidelberg <david@ixit.cz>

