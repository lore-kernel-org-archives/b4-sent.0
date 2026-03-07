From: Paul Adam <adamp@posteo.de>
Date: Sat, 07 Mar 2026 18:23:10 +0100
Subject: [PATCH v4 1/3] dt-bindings: vendor-prefixes: add WIKO SAS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260307-wiko-chuppito-v4-1-325ac66ae338@posteo.de>
References: <20260307-wiko-chuppito-v4-0-325ac66ae338@posteo.de>
In-Reply-To: <20260307-wiko-chuppito-v4-0-325ac66ae338@posteo.de>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, Paul Adam <adamp@posteo.de>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772904201; l=846;
 i=adamp@posteo.de; s=20260215; h=from:subject:message-id;
 bh=p71bdLWPgJx8YbZwRJN3OjH5dKZ2Biw/XlIKc8Hj8V8=;
 b=COGpkrT/qwb78CSninXkVsxU/hwvR7di6vDacrRIu2RXUX1Tr2Ypp5KfHYvSSisShupVwyX7j
 oLbnVjoxZNzDnqM5EHifN7ckR2TKgpnc92nctk1vzmD8LNGHBVQysqT
X-Developer-Key: i=adamp@posteo.de; a=ed25519;
 pk=mtrPhSn7htywc4S5zrKNrWM6laAdfnaJzIs0BDiCyAs=
X-Endpoint-Received: by B4 Relay for adamp@posteo.de/20260215 with auth_id=640
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Wiko is a french smartphone company: https://wiko.com

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
Signed-off-by: Paul Adam <adamp@posteo.de>
---
 Documentation/devicetree/bindings/vendor-prefixes.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/vendor-prefixes.yaml b/Documentation/devicetree/bindings/vendor-prefixes.yaml
index edbce100cae4..187089eef983 100644
--- a/Documentation/devicetree/bindings/vendor-prefixes.yaml
+++ b/Documentation/devicetree/bindings/vendor-prefixes.yaml
@@ -1819,6 +1819,8 @@ patternProperties:
     description: Wi2Wi, Inc.
   "^widora,.*":
     description: Beijing Widora Technology Co., Ltd.
+  "^wiko,.*":
+    description: Wiko SAS
   "^wiligear,.*":
     description: Wiligear, Ltd.
   "^willsemi,.*":

-- 
2.53.0

