From: Paul Adam <adamp@posteo.de>
Date: Sat, 21 Feb 2026 21:55:40 +0100
Subject: [PATCH v2 2/3] dt-bindings: arm: qcom: add wiko,chuppito
 compatible string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260221-wiko-chuppito-v2-2-6336b1b12389@posteo.de>
References: <20260221-wiko-chuppito-v2-0-6336b1b12389@posteo.de>
In-Reply-To: <20260221-wiko-chuppito-v2-0-6336b1b12389@posteo.de>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 phone-devel@vger.kernel.org, Paul Adam <adamp@posteo.de>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771707381; l=721;
 i=adamp@posteo.de; s=20260215; h=from:subject:message-id;
 bh=wLOaGkFmyUQde9kh0HFArEBPrWfyqvUjaJBrO7MX19I=;
 b=m1rro/7hs7Z4FF0Xm9njEJ/1S1Q5Fq/P3VQ85amohSZptxIUvG7KYkQ+yHDextmXuPTn4OC6y
 B4inj3RUsnmD7SouFSAUqIwro9Ep5CGkMziasJ96o/2gzfnddrtMre2
X-Developer-Key: i=adamp@posteo.de; a=ed25519;
 pk=mtrPhSn7htywc4S5zrKNrWM6laAdfnaJzIs0BDiCyAs=
X-Endpoint-Received: by B4 Relay for adamp@posteo.de/20260215 with auth_id=640
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a compatible for Wiko PULP 4G

Signed-off-by: Paul Adam <adamp@posteo.de>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index d48c625d3fc4..c9525b61f8ff 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -186,6 +186,7 @@ properties:
               - samsung,serranove
               - thwc,uf896
               - thwc,ufi001c
+              - wiko,chuppito
               - wingtech,wt86518
               - wingtech,wt86528
               - wingtech,wt88047

-- 
2.53.0

