From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Correct Xiaomi Poco F1 compatible strings and
 evaluation.
Date: Fri, 03 Apr 2026 18:55:32 +0200
Message-Id: <20260403-beryllium-compat-string-v1-0-0a6b9cb55a20@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAATxz2kC/x3MQQ5AMBBA0avIrE1SJZK6ili0NZiEkilCxN01l
 m/x/wORhClCkz0gdHLkNSQUeQZ+smEk5D4ZtNK1qlSJjuSeZz4W9Ouy2R3jLhxG9L6ojDPKatN
 Dqjehga//3Hbv+wGNbIWgaQAAAA==
X-Change-ID: 20260403-beryllium-compat-string-cc149b90a29d
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Joel Selvaraj <joelselvaraj.oss@gmail.com>, 
 Jens Reidel <adrian@travitia.xyz>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=690; i=david@ixit.cz;
 h=from:subject:message-id; bh=azPIcXHFapkiczhjKkBzlN9iLe+KM6jGYv3hkG7Ipqo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz/EFee5WwJT1VYWmq7xJrHYCNXiTOXM+QC7SN
 XkMMXcqPniJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/xBQAKCRBgAj/E00kg
 cs3zD/4qFUbU3XPuDX751Hdq2PMwz5080NUcDhWGea/Rll5v2JlJVC8TVQKOQIGkFe/ywILLgA3
 Iwt7QlLUuSYCJfhp3cSs9A9hldfs+HvqLiCJdlpBdonU0tU3EHKrvP8SyZezHg/UGaRQeutstuF
 jjJ3W2FoG79rC561oDf63FiuuHZWhPaW39WMKAoC4dOnAXB47SbvJ8yDIFDSilAmgg+TrPbGA6y
 BDZ92Gj8lGj6V8TdYI0gMobdqiyX0CrCWDCe4frgLe4ooMUA4zx12PZkOmYSlIaKTPKxWN2ROYq
 wvvRYaUiY/I/Zv3fZkmruLvo583Rx27RCswrGQFEudbrFOgRX6EkU8NzrO4obtAvIyJP1CRdZPk
 EqWCMLJNmOv10xgT4FVCrsnIUt402G7nhjef/Aqfs1c+SxnrgOiYTmt1KV6QL0thxFC6UMUkUzU
 iVQGkrXBgqBMgXFUqYd8uDxREk8e4gd4DbQofXDuV3GqIF97hSURSKFz0mBaYTLsAp0ZnET/PrY
 N4W26A4PZW1rHz45qyXb0x8h+qAvbFSPNCb9vOS7MU4BVkQ8mW15vEMLl7Vrq1OBrAE7pUaJf0N
 A8iIg8jz/D4rdZLph2c8u+2fkEEXGJmlKg2YnfScEbEWp8PV3PO7laoVOJe+yClje1k1AYprSvv
 xDZPiHJUohhtbtQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (1):
      dt-bindings: arm: qcom: Add Xiaomi Poco F1 Tianma variant bindings

Jens Reidel (1):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Fix compatible strings

 Documentation/devicetree/bindings/arm/qcom.yaml             | 10 ++++++++--
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-ebbg.dts   |  2 +-
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts |  2 +-
 3 files changed, 10 insertions(+), 4 deletions(-)
---
base-commit: cc13002a9f984d37906e9476f3e532a8cdd126f5
change-id: 20260403-beryllium-compat-string-cc149b90a29d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

