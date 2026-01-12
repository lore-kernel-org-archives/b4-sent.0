From: David Heidelberg <david@ixit.cz>
Date: Mon, 12 Jan 2026 13:33:18 +0100
Subject: [PATCH] needsreview! arm64: dts: qcom: sdm845: Add missing MDSS
 reset
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260112-mdss-reset-v1-1-af7c572204d3@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAA3qZGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDQ0Mj3dyU4mLdotTi1BJdAzNLC4s0A9PENEszJaCGgqLUtMwKsGHRsbW
 1ADZb8S5cAAAA
X-Change-ID: 20260112-mdss-reset-06988f05af96
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Petr Hodina <petr.hodina@protonmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1207; i=david@ixit.cz;
 h=from:subject:message-id; bh=xyL7eWXK7jE1/oIiV8yIed+nCW2dEm0vu5kEHX57DqY=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGlk6g6guz34GD1Dcwr00p0q3jdirNw/3X6blRI7zOKPG4PU5
 4kCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJpZOoOAAoJEGACP8TTSSByRqsQAIF9
 peF+lAX6NCY9jm4ex3bGjQu9iSD2u97EoXphVQLnebgrGS7B8xneLx68rSgGt0lS+GyYYwyqdzn
 nE7pAjnYHsm5dHc+TMtyMBT+kyjWn3MKlPRT9EjzRpguStL/Amo7DJ1ANwGREO0FgwPVWpgn+Q+
 qhDkdaX/eArcpB8lVo8EN4gu3dQvzAmlX4yhShZ0oAFAaDJHeKJQIhdAZ3kiSJclHNl5Xp0M3t9
 sShXaXqqjuHRImrhK/+f9WX9z/v53bjvOnccELxWvhHUTES1dDeIveGvcppOI5ySPWjvMO3TISf
 GiJWIBRyEyA2Pv5fjvdncyUEMpLUaIv9Yek1i89t+6KA7doS/kUJPLiyJKGQWTjciYlre5EkXc+
 dsS0R3PxUl71LcfIBMKpDtmFXx6o8hG6OqlZHPecXrfUzcjxNG2Jresn+Ihyn7pP4paSbRf8A9f
 9ipg53tfzmnDPKLQXGSAuHmgUDXNUGBOlkN98T59eLjnUjg0nregN/LUVs1BJoxVXIlF9xBtMiq
 AZAd2eGrzN1drMiaUz6rFYih1yApdcE12Sc8YKVPCO1+Se3bF8HVGzbgveSK50JSa+YaZeuEQ0z
 BC3YGMzBauA6s4f+Q3Za9JYvr3su7hayYdYV16P0TwZlrHbbcRijY2w2HmiWFoSvucz8GucChfo
 BxlzK
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

If the OS does not support recovering the state left by the
bootloader it needs a way to reset display hardware, so that it can
start from a clean state. Add a reference to the relevant reset.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
It efficiently fixes nothing for us (at least what we're aware), so I
assume the state left by bootloader is good enough

I sending this as a something "which seems right" and works for us in
sdm845-next tree.

David
---
 arch/arm64/boot/dts/qcom/sdm845.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845.dtsi b/arch/arm64/boot/dts/qcom/sdm845.dtsi
index bf2f9c04adba7..75c192eddc57c 100644
--- a/arch/arm64/boot/dts/qcom/sdm845.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845.dtsi
@@ -4550,6 +4550,7 @@ mdss: display-subsystem@ae00000 {
 			reg-names = "mdss";
 
 			power-domains = <&dispcc MDSS_GDSC>;
+			resets = <&dispcc DISP_CC_MDSS_RSCC_BCR>;
 
 			clocks = <&dispcc DISP_CC_MDSS_AHB_CLK>,
 				 <&dispcc DISP_CC_MDSS_MDP_CLK>;

---
base-commit: f417b7ffcbef7d76b0d8860518f50dae0e7e5eda
change-id: 20260112-mdss-reset-06988f05af96

Best regards,
-- 
David Heidelberg <david@ixit.cz>

