From: Ricky Cheung <rcheung844@gmail.com>
Date: Tue, 14 Jan 2025 22:18:55 +0800
Subject: [PATCH v2 1/3] dt-bindings: vendor-prefixes: Add XiaoXun BiCheng
 Technology
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250114-xiaoxun-jz0145-v33-v2-1-8b42f77badfa@gmail.com>
References: <20250114-xiaoxun-jz0145-v33-v2-0-8b42f77badfa@gmail.com>
In-Reply-To: <20250114-xiaoxun-jz0145-v33-v2-0-8b42f77badfa@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Ricky Cheung <rcheung844@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736864336; l=1085;
 i=rcheung844@gmail.com; s=20250114; h=from:subject:message-id;
 bh=YLItZhmnioQz+msagvBTQwosqfJj9133Wi6WbhZanLw=;
 b=JG54DA3vK6ssV+27pPJLKGmBrIHn2deyI642+5k5tfAEgbZ4s9k8MvOiBB+RRYkEIbbmtefvg
 +0s5lA3mRHGDYfItHYiWo5ZtaFclcc76r2Ed2suckpLPb7dv42fV3uQ
X-Developer-Key: i=rcheung844@gmail.com; a=ed25519;
 pk=JjZsSnuDD1xuR4EXY4XGKELgToA++HxxheDlHU/41yI=
X-Endpoint-Received: by B4 Relay for rcheung844@gmail.com/20250114 with auth_id=323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a vendor prefix for XiaoXun BiCheng Technology, which was an online
store on TaoBao selling 4G LTE WiFi modems.

TaoBao mostly require stores to be operated by companies, so they are
a valid vendor. However, this company has ended operations recently.

Signed-off-by: Ricky Cheung <rcheung844@gmail.com>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index b320a39de7fe40ce4d97ed3ea264a5971a3428dd..9bbd21b47201d866ae68e6ae406189266871617f 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1673,6 +1673,8 @@ patternProperties:
     description: Extreme Engineering Solutions (X-ES)
   "^xiaomi,.*":
     description: Xiaomi Technology Co., Ltd.
+  "^xiaoxun,.*":
+    description: XiaoXun BiCheng Technology
   "^xillybus,.*":
     description: Xillybus Ltd.
   "^xingbangda,.*":

-- 
2.47.1

