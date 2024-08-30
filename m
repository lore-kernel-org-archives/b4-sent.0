From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Fri, 30 Aug 2024 10:36:41 +0200
Subject: [PATCH v7 3/3] dt-bindings: vendor-prefixes: Add DFRobot.
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240830-rtc-sd2405al-v7-3-2f7102621b1d@gmail.com>
References: <20240830-rtc-sd2405al-v7-0-2f7102621b1d@gmail.com>
In-Reply-To: <20240830-rtc-sd2405al-v7-0-2f7102621b1d@gmail.com>
To: Alexandre Belloni <alexandre.belloni@bootlin.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-rtc@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1725007003; l=804;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=ncH4Nose8ybtnpgQlMcSo58ScS7tXEPtFaOCy+e67Ts=;
 b=Hz6d/p862molA2KSGaZs8bmNVaTxxf6kUPq7qIl4lrAdbhzNJA/3/7iApn+1vs4xl7+GBVQnp
 7+4/E3iRneuC0EjWrhGsee84n7kH3SqAmxOmgZz5eRF3/GokhzN/o7T
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Link: https://www.dfrobot.com/about-us

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Tóth János <gomba007@gmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index a70ce43b3dc0..bd8b279a5152 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -368,6 +368,8 @@ patternProperties:
     description: Devantech, Ltd.
   "^dfi,.*":
     description: DFI Inc.
+  "^dfrobot,.*":
+    description: DFRobot Corporation
   "^dh,.*":
     description: DH electronics GmbH
   "^difrnce,.*":

-- 
2.34.1

