From: Ricky Cheung <rcheung844@gmail.com>
Date: Tue, 14 Jan 2025 22:46:49 +0800
Subject: [PATCH RESEND v2 2/3] dt-bindings: arm: qcom: Add XiaoXun JZ0145
 v33
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250114-xiaoxun-jz0145-v33-v2-2-495e986579ce@gmail.com>
References: <20250114-xiaoxun-jz0145-v33-v2-0-495e986579ce@gmail.com>
In-Reply-To: <20250114-xiaoxun-jz0145-v33-v2-0-495e986579ce@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Ricky Cheung <rcheung844@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736866013; l=777;
 i=rcheung844@gmail.com; s=20250114; h=from:subject:message-id;
 bh=rcWv0GEI8Tk+7bGBT8IFODLra+FIFnAENM9Ul2xHUTY=;
 b=ITFWCEWvKBi34RZ71YSdewYcfs9cqxSN5UKBTLpI/6UhNurtlD7Z9s92tiBgB1xU0MKrnoRcf
 ZRlM6HN2CGLAsqFUg+/+111m4nc9NkrKKZknsakgqGjnlMqnET7Qo/s
X-Developer-Key: i=rcheung844@gmail.com; a=ed25519;
 pk=JjZsSnuDD1xuR4EXY4XGKELgToA++HxxheDlHU/41yI=
X-Endpoint-Received: by B4 Relay for rcheung844@gmail.com/20250114 with auth_id=323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the MSM8916-based 4G LTE WiFi modem.

Signed-off-by: Ricky Cheung <rcheung844@gmail.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 5cb54d69af0b7206e0f6a66023a203b8d7087696..92dd91cb66b7b1b26b013a7d32c20dfe44690569 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -245,6 +245,7 @@ properties:
               - wingtech,wt86518
               - wingtech,wt86528
               - wingtech,wt88047
+              - xiaoxun,jz0145-v33
               - yiming,uz801-v3
           - const: qcom,msm8916
 

-- 
2.47.1

