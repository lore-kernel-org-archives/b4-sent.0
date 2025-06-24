From: Cristian Cozzolino <cristian_ci@protonmail.com>
Date: Tue, 24 Jun 2025 03:20:06 +0200
Subject: [PATCH v2 2/3] dt-bindings: arm: qcom: Add Billion Capture+
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250624-rimob-initial-devicetree-v2-2-34f6045ebc30@protonmail.com>
References: <20250624-rimob-initial-devicetree-v2-0-34f6045ebc30@protonmail.com>
In-Reply-To: <20250624-rimob-initial-devicetree-v2-0-34f6045ebc30@protonmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, 
 Cristian Cozzolino <cristian_ci@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750728014; l=793;
 i=cristian_ci@protonmail.com; s=20250620; h=from:subject:message-id;
 bh=rX9AadKtpX+eNxD3sjDhJeQkUeOFBglGYJMKRi4cNf8=;
 b=GBHhvDIR3yaCru3eUZ9eyUoF3NE+9Z0bHd+wdPwQzpMG7LKuZYcIJqHSL/XMavr7GygyD9VOb
 AyYV29f0fqvAkN0OJIdpwlzU0ek1LR025cL93OHcQE4nDTVwWc+d4po
X-Developer-Key: i=cristian_ci@protonmail.com; a=ed25519;
 pk=xH5IvIPUNHV1Q8R0/pq2CfuVFR/wTiAyuyi6IwedjZY=
X-Endpoint-Received: by B4 Relay for cristian_ci@protonmail.com/20250620 with auth_id=438
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Billion Capture+ (flipkart,rimob) is a smartphone based on Qualcomm
Snapdragon 625 (MSM8953).

Signed-off-by: Cristian Cozzolino <cristian_ci@protonmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 618a87693ac1dc32b40a2201bc219a4f12e9f3e8..dbe605557af82c2382702011276e920ea18d3bb8 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -274,6 +274,7 @@ properties:
 
       - items:
           - enum:
+              - flipkart,rimob
               - motorola,potter
               - xiaomi,daisy
               - xiaomi,mido

-- 
2.49.0

