From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] NFC support for two Qualcomm SDM845 phones
Date: Tue, 24 Mar 2026 00:20:38 +0100
Message-Id: <20260324-oneplus-nfc-v2-0-3eef052c9bc6@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMbKwWkC/1XMQQ6CMBCF4auQWVvTjtSoK+5hWGCZkUlMIS02K
 OndLexc/i953wqRglCEW7VCoCRRRl8CDxW4ofNPUtKXBtRojTEXNXqaXu+oPDvltCY2rufu+oD
 ymAKxLLt2b0sPEucxfHY8mW3dnLM+If45ySitLCOyrWvWhI0sMh/dF9qc8w8SIr7KpAAAAA==
X-Change-ID: 20251118-oneplus-nfc-c00ef1cdfa9b
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexander Martinz <amartinz@shift.eco>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=995; i=david@ixit.cz;
 h=from:subject:message-id; bh=DTkjcea9B8KRecgVExXsvF5s2GkNdZDwc4sp+EiE1ZI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpwcrK6HzKCQoxBnDKPKHQiGdLFIHTx8Ukl2wsm
 cptojhQUxeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacHKygAKCRBgAj/E00kg
 co5cEADDmglzvpHlEw87TYP9XDKl4ARiyplmy1OtuKf2YBd+eCfa4x85EpaVy75QUU2r9PUbCi6
 M4QcP5RzFvDvtzSQuyWyH+lvu4jxYSkQY6fJCvYWVrXSzfezHpEt2+kSat38qyDB4r50dcne7mF
 B2ESIpclwq8FfiWM/mJ/bDVnYH+MDbNJAANzvoKAIgS6N8L1wjmDwNiQbWkCNYv2IRsUMwnou1J
 UJzPkISOcmycHt27Qo3zYMqt10N/Gl4Tb5d0BdYP330MvnmKUDt7HdW7TSGqF7+9pVffOFRZJkV
 9DCDIucmfFa6FgAJNQfu2JDaWA52KiEIb515FCjKASk+Mh3mO5Zc8hnqhub95VQIU99dwd/0bHg
 moBEHwH79TQXjG+24D6kt/7Nu+TJmFePVT73no4uzk0dF59sJFPVIK24XIbHHjNYzKeJehcNO3C
 pQWRHcoSqMIC1xvUxKcJ3EoDS/1sqR+7o+bCNPfOpcrNxbDtmpHzdgfjRqkGsxZUGseMKEgx13y
 0qjLYgnng88wNt0C3T6JQKJfzJZl4P6OIhw4rucMAXmsO0qLeDbl46AzCr7O946UndqY+NeV8Cv
 eXU/+vBHs7oJQFePRXW3/kybg/8v4silyQgx9EsjpGC9c1AQk/JJQEAeBm7MnzqUOJy0vcjYTxf
 AuphiWhykkApbKw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Verified with neard and

nfctool -d nfc0 -p

successfully detecting a tag.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Use interrupts-extended. (Konrad)
- Dropped QUESTION prefix, as it's verified this settings work.
- Added compatible for OnePlus 6 based on schematics.
- Corrected axolotl NFC compatible based on information from Alexander (SHIFT).
- Link to v1: https://lore.kernel.org/r/20260322-oneplus-nfc-v1-0-5f22f544f0e2@ixit.cz

---
David Heidelberg (1):
      arm64: dts: qcom: sdm845-shift-axolotl: Enable NFC

biemster (1):
      arm64: dts: qcom: sdm845-oneplus: Enable NFC

 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 31 ++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts  | 33 ++++++++++++++++++++++
 2 files changed, 64 insertions(+)
---
base-commit: 09c0f7f1bcdbc3c37a5a760cbec76bf18f278406
change-id: 20251118-oneplus-nfc-c00ef1cdfa9b

Best regards,
-- 
David Heidelberg <david@ixit.cz>

