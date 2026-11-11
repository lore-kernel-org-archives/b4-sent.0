From: Asdlerto Korry <korryasdlerto@gmail.com>
Date: Wed, 11 Nov 2026 17:07:46 +0200
Subject: [PATCH v2 2/4] dt-bindings: net: nfc: samsung,s3fwrn5: Add
 pvdd-supply
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-m52xq-dts-v2-2-063289405882@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794409665; l=1265;
 i=korryasdlerto@gmail.com; s=20261104; h=from:subject:message-id;
 bh=L3UEvXwsJbgHO/GEznzm7PXr2KKeR3S/1EqK+t4yPzU=;
 b=i0VR4iGhTSmc8cV5jr++3UqpOeZRMViCIAaivmXMGkhdgtI+u2HPgQhzQswBXn7Dz15sO62pB
 lickrXv8lNWBNSZZFYbcRqO1ZgargNK/UNPevQYGO4fCJ0q4VcFw4bb
X-Developer-Key: i=korryasdlerto@gmail.com; a=ed25519;
 pk=RqttIGkm2XZ8NhLQBzPgpXXawOdVa1uODGsk+sagbxs=
X-Endpoint-Received: by B4 Relay for korryasdlerto@gmail.com/20261104 with auth_id=1411
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The PVDD pin of the S3FWRN5 has to be powered before the chip is
enabled. On some boards, like the Samsung Galaxy M52 5G, this supply
is switched by a SoC GPIO. Document it, so that the regulator can be
handed to the driver instead of being kept always on.

Signed-off-by: Asdlerto Korry <korryasdlerto@gmail.com>
---
 Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml b/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml
index 12baee45752c..3c5a579a7108 100644
--- a/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml
+++ b/Documentation/devicetree/bindings/net/nfc/samsung,s3fwrn5.yaml
@@ -34,6 +34,10 @@ properties:
     description:
       Output GPIO pin used to enter firmware mode and sleep/wakeup control
 
+  pvdd-supply:
+    description:
+      Power supply of the PVDD pin
+
   s3fwrn5,en-gpios:
     maxItems: 1
     deprecated: true
@@ -84,6 +88,7 @@ examples:
             wake-gpios = <&gpj0 2 GPIO_ACTIVE_HIGH>;
 
             clocks = <&rpmcc 20>;
+            pvdd-supply = <&nfc_pvdd>;
         };
     };
   # UART example on Raspberry Pi

-- 
2.25.1

