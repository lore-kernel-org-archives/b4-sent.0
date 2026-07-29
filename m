From: David Heidelberg <david@ixit.cz>
Date: Wed, 29 Jul 2026 23:53:09 +0200
Subject: [PATCH 1/2] dt-bindings: media: i2c: dongwoon,dw9714: Document
 DW9714A and V variant
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260729-dw9714v-v1-1-3c479b3cf8c0@ixit.cz>
References: <20260729-dw9714v-v1-0-3c479b3cf8c0@ixit.cz>
In-Reply-To: <20260729-dw9714v-v1-0-3c479b3cf8c0@ixit.cz>
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1287; i=david@ixit.cz;
 h=from:subject:message-id; bh=e2G+yj7LX19KR7zqmeDyITbD76FzOrOow1iF5xDhISs=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqanZHxM0KLmvcgV7BdhURDMMW3n6PNAqkcyVv9
 gzpg0sMGSWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamp2RwAKCRBgAj/E00kg
 cm9XEACHX0nRCFdRQ1uy/mfcBT9iTEYSmGcPl07ga8humPeKh/FyTHHmhR5vuYMtxEbiuA0ew4r
 5DVVn4hVKqa0m8dT26loel4H2p94f2dxc3BgJpv5TPJ/DTvsv7TGyvFoqhfYSX+nD8jIVXnequE
 nBfGswnRack+s88cdqoor3gCxEtHuZY8mAsgw7SFeJhANjxywzoHjr6OOMgyXTZgKf+xuP5ao3O
 NOD+6n1Jzm5mDlMSZ2pWPv16iNu5Tl6mGcaSdoyOaZG0NVKtZXoE/Mlw6XkfKtWtGEidbr1Mfu3
 7auzvTZ5QP3TbOhTBUdp32BGe96gfyxIuNgWEyPt4te962Z6H2qLMkXC0J6SrfsVEslXirT+tYI
 9/LD1NdTdnjf6ATfhebvJ+Jua54g0LQ2vjXhNf/Kl9JHGw8rgo+YGWbp+9dY0TdpYc2o20ArUSZ
 aVomdeGcs+yEfLpI//D3FmX2sYPpze1qT0FvvPQ4hz/sPmd8g/H6CsWsxRr4XwMngUOnv+LMVb0
 cNujCBLQ8ibDyYbmYrSym7aYC9Fll7vhoV9YjcU0OY94uZAcUmvYusTztiQwxIIfVVEItAUDgDC
 iZw9925oOmj9YO18YVksioL55E3KdCybyoSIsNdzO+bvwuJPsYm2ALfgrLXoSP267NN9gn/NC3o
 kNc8YrQlenf31mA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Both of these successors are backward compatible, but introducing new
features.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 .../devicetree/bindings/media/i2c/dongwoon,dw9714.yaml         | 10 +++++++++-
 1 file changed, 9 insertions(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
index 66229a3dc05d6..e8ad2d3448d5f 100644
--- a/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
+++ b/Documentation/devicetree/bindings/media/i2c/dongwoon,dw9714.yaml
@@ -10,17 +10,25 @@ maintainers:
   - Krzysztof Kozlowski <krzk@kernel.org>
 
 description:
   DW9174 is a 10-bit DAC with current sink capability. It is intended for
   driving voice coil lenses in camera modules.
 
 properties:
   compatible:
-    const: dongwoon,dw9714
+    oneOf:
+      - items:
+          - const: dongwoon,dw9714v
+          - const: dongwoon,dw9714a
+          - const: dongwoon,dw9714
+      - items:
+          - const: dongwoon,dw9714a
+          - const: dongwoon,dw9714
+      - const: dongwoon,dw9714
 
   reg:
     maxItems: 1
 
   powerdown-gpios:
     description:
       XSD pin for shutdown (active low)
 

-- 
2.53.0

