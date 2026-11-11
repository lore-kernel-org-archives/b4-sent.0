From: Asdlerto Korry <korryasdlerto@gmail.com>
Date: Wed, 11 Nov 2026 17:07:45 +0200
Subject: [PATCH v2 1/4] dt-bindings: arm: qcom: Add Samsung Galaxy M52 5G
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-m52xq-dts-v2-1-063289405882@gmail.com>
References: <20261111-m52xq-dts-v2-0-063289405882@gmail.com>
In-Reply-To: <20261111-m52xq-dts-v2-0-063289405882@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 netdev@vger.kernel.org, Asdlerto Korry <korryasdlerto@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794409665; l=791;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=H56IcYVSNo0wgt3tuO8OiTWa9f7y69coL2KlUgR93oo=;
 b=c5jtXCSZpUzuCZUk/jg1jy0vVp74CDnkop3QLjilgNHGmfRwyu57zFaeEnhqQqkt1keQV8Ogm
 Cdd/8ifLAFfA2IZJAlrrvLDLdojNtOgrAp9mYhgjWf3iNmz/N4NO5+8
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the Samsung Galaxy M52 5G (samsung,m52xq) smartphone, which is
based on the Qualcomm SM7325 SoC.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 121ca557ce1e..fff2be0ecb47 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1124,6 +1124,7 @@ properties:
           - enum:
               - motorola,dubai
               - nothing,spacewar
+              - samsung,m52xq
               - xiaomi,lisa
               - xiaomi,taoyao
           - const: qcom,sm7325

-- 
2.25.1

