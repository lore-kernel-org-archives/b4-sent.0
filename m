From: Alexandre MINETTE <contact@alex-min.fr>
Date: Tue, 21 Apr 2026 11:45:07 +0200
Subject: [PATCH 1/8] dt-bindings: arm: qcom: Add Samsung Galaxy S4
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260421-mainline-send-v1-sending-v1-1-bcb0857724de@alex-min.fr>
References: <20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr>
In-Reply-To: <20260421-mainline-send-v1-sending-v1-0-bcb0857724de@alex-min.fr>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, MyungJoo Ham <myungjoo.ham@samsung.com>, 
 Chanwoo Choi <cw00.choi@samsung.com>, 
 Guru Das Srinagesh <linux@gurudas.dev>, Linus Walleij <linusw@kernel.org>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Kees Cook <kees@kernel.org>, Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-gpio@vger.kernel.org, 
 iommu@lists.linux.dev, Alexandre MINETTE <contact@alex-min.fr>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776764711; l=776;
 i=contact@alex-min.fr; s=20260421; h=from:subject:message-id;
 bh=Akgl3hzfClofydDGp4o3os1sJpq4Hx+LaZv5zck8bfU=;
 b=+8CpDr4EzIFz+bunBXtMybY6nKObFYFwHNsn8kPnztW+RXdinyTWtxwdUvcKVVKiF4sqAFGWY
 uiqJGGzqA0gCp/6wT/Z/7k/9dTi8ZAIh9ZbiqknebkATY+p+fp7BPCf
X-Developer-Key: i=contact@alex-min.fr; a=ed25519;
 pk=KOCaxY4v16ptaT0uk1FRkuaDF2n1JhmnYwLiqWD76M4=
X-Endpoint-Received: by B4 Relay for contact@alex-min.fr/20260421 with auth_id=743
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the compatible for this Samsung smartphone, codenamed jflte.

Signed-off-by: Alexandre MINETTE <contact@alex-min.fr>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index b4943123d2e4..2ec9f8be9609 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -40,6 +40,7 @@ properties:
               - asus,nexus7-flo
               - lg,nexus4-mako
               - sony,xperia-yuga
+              - samsung,jflte
               - qcom,apq8064-cm-qs600
               - qcom,apq8064-ifc6410
           - const: qcom,apq8064

-- 
2.43.0

