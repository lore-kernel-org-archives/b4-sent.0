From: David Heidelberg <david@ixit.cz>
Date: Wed, 25 Mar 2026 18:57:17 +0100
Subject: [PATCH v4 3/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 ath10k host-cap skip quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260325-skip-host-cam-qmi-req-v4-3-bc08538487aa@ixit.cz>
References: <20260325-skip-host-cam-qmi-req-v4-0-bc08538487aa@ixit.cz>
In-Reply-To: <20260325-skip-host-cam-qmi-req-v4-0-bc08538487aa@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=865; i=david@ixit.cz;
 h=from:subject:message-id; bh=7WCT4AIXs3RES5sBwcwPY1VLLZLiJwKsEh3sFLY3XeA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxCH731ERAs00JnGTMwhjDc7fvFNGG6zHnruKt
 CzctlaDyk6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacQh+wAKCRBgAj/E00kg
 ch0UD/9bRRDJsrM0G4teP9+2n5J/36wjbkVECTL3P9N4I0zEVmBUPaHYndwRhiz2OdWQ850FzrC
 9l3RUNEjqdi14CbA3wNDnNBlqGdS4m7pnEjPTCgz9rUa4pqqV0blSTnsxMPUkldndytGhBMwCKv
 0FZ3HnHYNjX/9p/OrHglUWmuuSeWS7pCWZQEuTC+yNesYSgdUoFJpgQKZ/AIephysyQGo06c0Cx
 3/5FajViggtoX8K9bYrnoRaOiBNoGs2i6iKNn6ybc++JRtcwDkUjKzhE36jVN8YpsvijHreLHyu
 73SmHDNuQxi7fq7P6paQx6SjMpNMrhSEvQocilCvJmiUYAH1t8Q5OFXGiuDDWcvcsz80tr+o37x
 R9i5YxVJ6xDXBT8XEJWfEIyqsu97obj4TILDO3NDEKOkduvAnVPsirgFlsnxi4DSL/i08yJOf3y
 eQGFnhEqzkok4HpJyylXIqGQ0sAQHXcPijZhs0lpdUz9hnhnzdCLxl8iUBx5Wm2HrKONCex7uSz
 VTG56POA1mOSu48mQV2blAZIyNk8lM52x8t8OAE1j7Ny0ov41eHqmcBT2KYnB6c0ZV4V+8/wraS
 zazwSChKzwhWB4ku7qk80ODz/xgoYzcE/trWbyUqIeyNCwAzGWpXLJeeyZisCa4PEQLcyF8covI
 zF7BssX7Fpp7DYA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

The Wi-Fi firmware used on Xiaomi Poco F1 (beryllium) phone doesn't
support the host-capability QMI request, so add a quirk to skip it on
this device.

Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 1298485c42142..950bbcc3bf91f 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -661,5 +661,6 @@ &wifi {
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
 
 	qcom,calibration-variant = "xiaomi_beryllium";
+	qcom,snoc-host-cap-skip-quirk;
 };
 

-- 
2.53.0

