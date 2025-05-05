From: =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
Date: Mon, 05 May 2025 09:52:58 +0200
Subject: [PATCH v2 1/2] dt-bindings: trivial-devices: Document SEN0322
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250505-iio-chemical-sen0322-v2-1-217473983b42@gmail.com>
References: <20250505-iio-chemical-sen0322-v2-0-217473983b42@gmail.com>
In-Reply-To: <20250505-iio-chemical-sen0322-v2-0-217473983b42@gmail.com>
To: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?T=C3=B3th_J=C3=A1nos?= <gomba007@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746431586; l=910;
 i=gomba007@gmail.com; s=20230706; h=from:subject:message-id;
 bh=1Mfxr5j12EbsEQWdQ2AY6ErLyezlks+9xDkOv+/nbsM=;
 b=kXQ6usTnCkZCv9d+dDS63qVsNQQKiFnQ8HkGcdC1VNXiaCoHf+pk17QrpX1IWEgIK0Usw2W/p
 OIvrkfPYZrTAu6I4g6MXLaDFdxwqtQ2AulBIOxE9E1azy83JaR8s3Xt
X-Developer-Key: i=gomba007@gmail.com; a=ed25519;
 pk=iY9MjPCbud82ULS2PQJIq3QwjKyP/Sg730I6T2M8Y5U=
X-Endpoint-Received: by B4 Relay for gomba007@gmail.com/20230706 with auth_id=60
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add documentation for the DFRobot SEN0322 oxygen sensor.

Signed-off-by: Tóth János <gomba007@gmail.com>
---
 Documentation/devicetree/bindings/trivial-devices.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/trivial-devices.yaml b/Documentation/devicetree/bindings/trivial-devices.yaml
index 8da408107e55..a25bf2135649 100644
--- a/Documentation/devicetree/bindings/trivial-devices.yaml
+++ b/Documentation/devicetree/bindings/trivial-devices.yaml
@@ -85,6 +85,8 @@ properties:
           - devantech,srf08
             # Devantech SRF10 ultrasonic ranger
           - devantech,srf10
+            # DFRobot SEN0322 oxygen sensor
+          - dfrobot,sen0322
             # DH electronics GmbH on-board CPLD trivial SPI device
           - dh,dhcom-board
             # DA9053: flexible system level PMIC with multicore support

-- 
2.34.1

