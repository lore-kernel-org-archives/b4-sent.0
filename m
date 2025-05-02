From: George Moussalem <george.moussalem@outlook.com>
Date: Fri, 02 May 2025 14:15:46 +0400
Subject: [PATCH 4/6] dt-bindings: mfd: qcom,tcsr: Add compatible for
 IPQ5018
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-ipq5018-cmn-pll-v1-4-27902c1c4071@outlook.com>
References: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
In-Reply-To: <20250502-ipq5018-cmn-pll-v1-0-27902c1c4071@outlook.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Luo Jie <quic_luoj@quicinc.com>, 
 Lee Jones <lee@kernel.org>, Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746180945; l=819;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=rWOkA/E/Z9CidEDzLfL6fySdOSwBg0HFYVj2bD8wwdw=;
 b=lgtEHtO41HG6bV8PodAOUvv4/8xckPbBymX1w3Wj6XQeY35/cFoP15GLYqTsSna6obsLzbh9X
 3fygYMoK3lWC99OHGLNYSUI2JedeVmSHU3BJzbdJ7L7JO4JMNLe3lAI
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the qcom,tcsr-ipq5018 compatible.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 Documentation/devicetree/bindings/mfd/qcom,tcsr.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/mfd/qcom,tcsr.yaml b/Documentation/devicetree/bindings/mfd/qcom,tcsr.yaml
index 7e7225aadae3285f59ec303294cf1515772a629b..14ae3f00ef7e00e607bba93f49f03bb244253b0e 100644
--- a/Documentation/devicetree/bindings/mfd/qcom,tcsr.yaml
+++ b/Documentation/devicetree/bindings/mfd/qcom,tcsr.yaml
@@ -41,6 +41,7 @@ properties:
           - qcom,sm8450-tcsr
           - qcom,tcsr-apq8064
           - qcom,tcsr-apq8084
+          - qcom,tcsr-ipq5018
           - qcom,tcsr-ipq5332
           - qcom,tcsr-ipq5424
           - qcom,tcsr-ipq6018

-- 
2.49.0

