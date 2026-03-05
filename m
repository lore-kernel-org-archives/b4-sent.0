From: Cory Keitz <ckeitz@amazon.com>
Date: Thu, 05 Mar 2026 14:40:12 +0000
Subject: [PATCH 1/2] dt-bindings: i2c: qcom-cci: Document
 qcom,scl-stretch-enable property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-cci-scl-stretch-v1-1-8412abc65745@amazon.com>
References: <20260305-cci-scl-stretch-v1-0-8412abc65745@amazon.com>
In-Reply-To: <20260305-cci-scl-stretch-v1-0-8412abc65745@amazon.com>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Cory Keitz <ckeitz@amazon.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772721621; l=1216;
 i=ckeitz@amazon.com; s=20260304; h=from:subject:message-id;
 bh=SEC34wu+SscLbukgX+vbjxvf9VZq9+C1PossueU0r34=;
 b=VA1yx/Bl2YXmKzeNq7V/WvDBPSwJw04soOHIVsHHluEbIUS+vB1Tdtukh57FFBTQQao/bYNbT
 ZjzXBxDbpGhCgvGZdPYTylW8bxeBhUJwBA0qPMDy004tT5q5DjlY6TX
X-Developer-Key: i=ckeitz@amazon.com; a=ed25519;
 pk=IWSPbPI9mzOdPU5zG2ROe/O75E4ckVxuBLNJVYVZCag=
X-Endpoint-Received: by B4 Relay for ckeitz@amazon.com/20260304 with auth_id=662
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the optional boolean property "qcom,scl-stretch-enable" to the
CCI i2c-bus sub-nodes. This property enables SCL clock stretching on
the corresponding CCI master, which is needed by peripherals such as
GMSL deserializers that hold SCL low to absorb forwarding latency.

Signed-off-by: Cory Keitz <ckeitz@amazon.com>
---
 Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml b/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml
index 399a09409e07..fea609fa2f05 100644
--- a/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml
+++ b/Documentation/devicetree/bindings/i2c/qcom,i2c-cci.yaml
@@ -78,6 +78,14 @@ patternProperties:
       clock-frequency:
         default: 100000
 
+      qcom,scl-stretch-enable:
+        type: boolean
+        description:
+          Enable SCL clock stretching on this CCI master. When set, the
+          CCI hardware will assert the SCL stretch enable bit in the
+          MISC_CTL register, allowing peripherals to hold SCL low to
+          throttle the bus.
+
 required:
   - compatible
   - clock-names

-- 
2.47.3

