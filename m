From: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
Date: Wed, 19 Nov 2025 14:06:42 +0800
Subject: [PATCH v3 1/2] dt-bindings: leds: qcom-lpg: Explain standalone PWM
 usage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-lpg_triled_fix-v3-1-84b6dbdc774a@oss.qualcomm.com>
References: <20251119-lpg_triled_fix-v3-0-84b6dbdc774a@oss.qualcomm.com>
In-Reply-To: <20251119-lpg_triled_fix-v3-0-84b6dbdc774a@oss.qualcomm.com>
To: kernel@oss.qualcomm.com, Lee Jones <lee@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Bjorn Andersson <andersson@kernel.org>, linux-arm-msm@vger.kernel.org, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Subbaraman Narayanamurthy <subbaraman.narayanamurthy@oss.qualcomm.com>, 
 Pavel Machek <pavel@ucw.cz>, linux-leds@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Fenglin Wu <fenglin.wu@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763532404; l=1399;
 i=fenglin.wu@oss.qualcomm.com; s=20240327; h=from:subject:message-id;
 bh=fm6f+mHZk9XQAu2fqBegNtPPu3AH+lJL7icnO/wPnuA=;
 b=7esyEgh0jpdYkUrVM6O/QNlvNQdL8cIhftNM37xGPAgzGa4njb6xJH69lrB4JqnN5TooTy6Ff
 O6/ODUy4YCxD2lqBB3Ae84FxYPF8MSguiw3Ynmumi7q6+TlWcHYK7k6
X-Developer-Key: i=fenglin.wu@oss.qualcomm.com; a=ed25519;
 pk=BF8SA4IVDk8/EBCwlBehKtn2hp6kipuuAuDAHh9s+K4=
X-Endpoint-Received: by B4 Relay for fenglin.wu@oss.qualcomm.com/20240327 with auth_id=406
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LPG channels can be used for only outputting PWM signals by routing to
PMIC GPIOs without enabling TRILED. Explain this usage in the description
for better clarity.

Signed-off-by: Fenglin Wu <fenglin.wu@oss.qualcomm.com>
---
 Documentation/devicetree/bindings/leds/leds-qcom-lpg.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/leds/leds-qcom-lpg.yaml b/Documentation/devicetree/bindings/leds/leds-qcom-lpg.yaml
index 841a0229c472a4764426d25d9dbb900adc20fc11..c4b7e57b251845a6970b34bc9ae0c00647b1bf96 100644
--- a/Documentation/devicetree/bindings/leds/leds-qcom-lpg.yaml
+++ b/Documentation/devicetree/bindings/leds/leds-qcom-lpg.yaml
@@ -13,6 +13,11 @@ description: >
   The Qualcomm Light Pulse Generator consists of three different hardware blocks;
   a ramp generator with lookup table (LUT), the light pulse generator and a three
   channel current sink. These blocks are found in a wide range of Qualcomm PMICs.
+  The light pulse generator (LPG) can also be used independently to output PWM
+  signal for standard PWM applications. In this scenario, the LPG output should
+  be routed to a specific PMIC GPIO by setting the GPIO pin mux to the special
+  functions indicated in the datasheet, the TRILED driver for the channel will
+  not be enabled in this configuration.
 
 properties:
   compatible:

-- 
2.34.1

