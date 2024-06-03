From: Alexandre Messier <alex@me.ssier.org>
Subject: [PATCH 0/2] Add HTC One (M8) support
Date: Mon, 03 Jun 2024 02:28:55 -0400
Message-Id: <20240603-m8-support-v1-0-c7b6a1941ed2@me.ssier.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKdiXWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDMwNj3VwL3eLSgoL8ohJdSxNTiyRjc4s0QzMLJaCGgqLUtMwKsGHRsbW
 1AA+5+IZcAAAA
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Luca Weiss <luca@z3ntu.xyz>, linux-arm-kernel@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Alexandre Messier <alex@me.ssier.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717396145; l=682;
 i=alex@me.ssier.org; s=20240603; h=from:subject:message-id;
 bh=hB0J0IVOF/UpXjXGqBI7wM1bGQ+L+7aiaCg9Y6YiGMg=;
 b=JqOBv5ncABcnRaUXO918/ItOETjjhRbgnF8IqtnfKb5vSHCHgFit3kNfHqV336ernniM1WHRY
 Mgmt/Q3vZn6DFUDVsVlSc7a8J5vGxjk0Ce1iyJ06a4jNzCM1MjR6qYP
X-Developer-Key: i=alex@me.ssier.org; a=ed25519;
 pk=JjRqVfLd2XLHX2QTylKoROw346/1LOyZJX0q6cfnrKw=
X-Endpoint-Received: by B4 Relay for alex@me.ssier.org/20240603 with auth_id=168
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add an initial device tree to support the HTC One (M8) smartphone,
aka "htc,m8".

Signed-off-by: Alexandre Messier <alex@me.ssier.org>
---
Alexandre Messier (2):
      dt-bindings: arm: qcom: add HTC One (M8)
      ARM: dts: qcom: Add initial support for HTC One (M8)

 Documentation/devicetree/bindings/arm/qcom.yaml   |   1 +
 arch/arm/boot/dts/qcom/Makefile                   |   1 +
 arch/arm/boot/dts/qcom/qcom-msm8974pro-htc-m8.dts | 353 ++++++++++++++++++++++
 3 files changed, 355 insertions(+)
---
base-commit: 1613e604df0cd359cf2a7fbd9be7a0bcfacfabd0
change-id: 20240603-m8-support-9458b378f168

Best regards,
-- 
Alexandre Messier <alex@me.ssier.org>

