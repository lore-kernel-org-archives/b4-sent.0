From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Subject: [PATCH v2 0/3] ARM: dts: qcom: msm8926-motorola-peregrine: Update
 device tree of Motorola Moto G 4G (2013)
Date: Mon, 17 Jun 2024 23:22:26 +0200
Message-Id: <20240617-peregrine-v2-0-c8835d2da7af@apitzsch.eu>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABKpcGYC/23MwQ6CMBCE4Vche7aGbWhjPPkehkMtI91LaVogK
 uHdrZw9/pPJt1FBFhS6NhtlrFJkijX0qSEfXByhZKhNutVda9mqhIwxS4Sy8AbaPtjAU/2njKe
 8Duve1w5S5im/D3rl3/pPWVmxupiBOwd2zO7mksyf4sMZC/X7vn8ByCK5NKQAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1718659400; l=871;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=gxguENUktsJsPjFaq8UcvbJuvvei3DvrYMOWcTOkAw8=;
 b=r9wdA5EbSuCzt6TOOpC+UdYY6D094zXNEqld0DfTqtYhkVbD0sevSl4Hl0VgRDEAYR2x1ki9J
 WXXD2LOhk/0DrTFcYwBUXMERrD+u6y4Q/KyNz2gG9n1Vym5RCVRJBv9
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add accelerometer, magnetometer, regulator and temperature sensor alert
interrupt and update framebuffer supplies.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
Changes in v2:
- Split commit into three commits
- Link to v1: https://lore.kernel.org/r/20240616-peregrine-v1-1-85d14ae1a11a@apitzsch.eu

---
André Apitzsch (3):
      ARM: dts: qcom: msm8926-motorola-peregrine: Add accelerometer, magnetometer, regulator
      ARM: dts: qcom: msm8926-motorola-peregrine: Update temperature sensor
      ARM: dts: qcom: msm8926-motorola-peregrine: Add framebuffer supplies

 .../dts/qcom/qcom-msm8926-motorola-peregrine.dts   | 121 +++++++++++++++++++++
 1 file changed, 121 insertions(+)
---
base-commit: c71189547381bb5f176c6b22a9edc3414f1837b9
change-id: 20240616-peregrine-6ec5e26b15ec

Best regards,
-- 
André Apitzsch <git@apitzsch.eu>

