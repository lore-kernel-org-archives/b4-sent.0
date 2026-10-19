From: Vidhu Sarwal <vidhu.linux@gmail.com>
Date: Tue, 20 Oct 2026 00:03:41 +0530
Subject: [PATCH 1/3] dt-bindings: vendor-prefixes: Add Benewake
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261020-tf-luna-v1-1-53a88f93db24@gmail.com>
References: <20261020-tf-luna-v1-0-53a88f93db24@gmail.com>
In-Reply-To: <20261020-tf-luna-v1-0-53a88f93db24@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Vidhu Sarwal <vidhu.linux@gmail.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-iio@vger.kernel.org, Shuah Khan <skhan@linuxfoundation.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792434836; l=907;
 i=vidhu.linux@gmail.com; s=20260713; h=from:subject:message-id;
 bh=3nXcOelYeuYgIZXnvr6k1TA5JZRFGS+HfeRVRLAhW6A=;
 b=iqXLKAyV32p3msPs7yjRhiv5ucr/d49obYUpveOF8vtLHblFap2qWzj+lMUjMgEl/+PbzkBec
 aRLV6gpz3b1DHIiggq5QbPB+BLn3WCYguIJj3iGKFQmOtAax5WGsm5s
X-Developer-Key: i=vidhu.linux@gmail.com; a=ed25519;
 pk=xDu3Cbesz76CQXwY8lteI74n3ELVIV7wCsuYAvcX1Q4=
X-Endpoint-Received: by B4 Relay for vidhu.linux@gmail.com/20260713 with auth_id=869
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add vendor prefix for Benewake (Beijing) Co., Ltd., a manufacturer of
LiDAR distance sensors.
https://en.benewake.com/

Signed-off-by: Vidhu Sarwal <vidhu.linux@gmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index 0ec4e481c64b..7bc9c071913b 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -245,6 +245,8 @@ patternProperties:
     description: BeagleBoard.org Foundation
   "^belling,.*":
     description: Shanghai Belling Co., Ltd.
+  "^benewake,.*":
+    description: Benewake (Beijing) Co., Ltd.
   "^bestar,.*":
     description: Shenzhen Bestar Electronic Technology Co., Ltd.
   "^bhf,.*":

-- 
2.53.0

