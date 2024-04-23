From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Tue, 23 Apr 2024 12:50:46 +0300
Subject: [PATCH v3 2/5] dt-bindings: arm: bcm: add bindings for ASUS
 RT-AC5300
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240423-for-soc-asus-rt-ac3200-ac5300-v3-2-23d33cfafe7a@arinc9.com>
References: <20240423-for-soc-asus-rt-ac3200-ac5300-v3-0-23d33cfafe7a@arinc9.com>
In-Reply-To: <20240423-for-soc-asus-rt-ac3200-ac5300-v3-0-23d33cfafe7a@arinc9.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>, 
 Hauke Mehrtens <hauke@hauke-m.de>, Rafal Milecki <zajec5@gmail.com>, 
 Florian Fainelli <florian.fainelli@broadcom.com>, 
 Broadcom internal kernel review list <bcm-kernel-feedback-list@broadcom.com>
Cc: Tom Brautaset <tbrautaset@gmail.com>, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713865858; l=820;
 i=arinc.unal@arinc9.com; s=arinc9-Xeront; h=from:subject:message-id;
 bh=bR3OtlLxsoLW4OgOTwPQgCaooezqCeVMoRpFlbGyxMw=;
 b=sZPI9h9sXXvsKJQNzYSAKsug3RZfz3KggVOvyq+m6a/+7Vd0fOL1c/GIPTxShzMus2Ervcq+F
 PsjcdxDIddzBbAaTjrGn9+pqRtJ1zbxYHeGXoiKdV1AizhCqgan7exg
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=z49tLn29CyiL4uwBTrqH9HO1Wu3sZIuRp4DaLZvtP9M=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-Xeront with auth_id=137
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add ASUS RT-AC5300 under BCM47094 based boards.

Acked-by: Krzysztof Kozlowski <krzk@kernel.org>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
 Documentation/devicetree/bindings/arm/bcm/brcm,bcm4708.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/bcm/brcm,bcm4708.yaml b/Documentation/devicetree/bindings/arm/bcm/brcm,bcm4708.yaml
index 215bef740aca..d925e7a3b5ef 100644
--- a/Documentation/devicetree/bindings/arm/bcm/brcm,bcm4708.yaml
+++ b/Documentation/devicetree/bindings/arm/bcm/brcm,bcm4708.yaml
@@ -68,6 +68,7 @@ properties:
         items:
           - enum:
               - asus,rt-ac3100
+              - asus,rt-ac5300
               - asus,rt-ac88u
               - dlink,dir-885l
               - dlink,dir-890l

-- 
2.40.1

