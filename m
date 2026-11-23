From: David Heidelberg <david@ixit.cz>
Date: Mon, 23 Nov 2026 02:21:47 +0100
Subject: [PATCH 2/3] media: dt-bindings: mipi-ccs: Support IMX371 and
 IMX376K
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261123-op6-upstream-cameras-v1-2-234fb3b7bb18@ixit.cz>
References: <20261123-op6-upstream-cameras-v1-0-234fb3b7bb18@ixit.cz>
In-Reply-To: <20261123-op6-upstream-cameras-v1-0-234fb3b7bb18@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, 
 Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1078; i=david@ixit.cz;
 h=from:subject:message-id; bh=WONKLUZwZONG/1eyGGSAmyn63j+1WD61eX0aPYZ8HQ8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrA5UvO124MmbWZgkQIqSWbuKBfOconQnBGfhXU
 ZTwfcG+M0SJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawOVLwAKCRBgAj/E00kg
 cu5hEAC1mEhErZKfCsK25+A4L7ozBWptF2uhmM9e7vVEplZi7u4q7P5z+YwlKgdqJheZ2DmvVJt
 c3ojF+bKgNZjGaO+1KC7JrG8J6w72Fph2hMXxEcS6CxABoeGoF01joildOyOSbI9i0tHhDIpj3j
 lPupEmXQJmBUmM70WgWGMLd+/LYTWWRou7rItmr/T6Jpqn8DqwWvuKRDM9ygDSs1EoeDYVx0JYZ
 tFz74UvE5m1ZWgmODZ4VV7cZiCjhhGuzKJg9VASZgxoZkUpIe0HdbysxAxzizBuLjkBUCalhdzy
 OaPy90Z6ksC63xNfLnhar3NuqZkznvPIJ5Z8t8h6VfgBuan+8kuBoPnGXQhI/jWYMr8l4vVdbOn
 HlGTtfqHlNmHm5EYwQsKqAQsNBNo8t0tV/xTk+7jHs4qMeAAnXHs7V7p0lnUJ8VxId241auGCQM
 7seQd2ShCtlXY7pXa0ioCPbUNp+hZ5nCq47ovdNbj3Lim5EPJPG37/GuQBeSbzmnmbLYkzEo5R1
 wvLg0LbU1e4/GCxnnDIfG9eX0SYzmlGSRRoE2coEevfw7ojbgU8C/iwVOmBiQRnCkYZxli1xr8L
 gLZakxtdZVlKqCpizAo5BB9CglYyxkfeG9dFLFkAlpE5P93j8P9z31p4xlgvgYxfcySvHujVpC1
 77O1SsLbIqVi7fg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend compatible list with these now supported sensors.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml b/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml
index 44faa2f613f37..049eaee31175a 100644
--- a/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/mipi-ccs.yaml
@@ -31,16 +31,22 @@ properties:
     oneOf:
       - items:
           - const: mipi-ccs-1.1
           - const: mipi-ccs
       - items:
           - const: mipi-ccs-1.0
           - const: mipi-ccs
       - const: nokia,smia
+      - items:
+          - const: sony,imx371
+          - const: mipi-ccs
+      - items:
+          - const: sony,imx376k
+          - const: mipi-ccs
 
   reg:
     maxItems: 1
 
   vana-supply:
     description: Analogue voltage supply (VANA), sensor dependent.
 
   vcore-supply:

-- 
2.55.0

