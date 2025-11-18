From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Nov 2025 15:11:35 +0100
Subject: [PATCH 1/3] arm64: dts: qcom: sdm845-oneplus: Don't mark ts supply
 boot-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-dts-oneplus-regulators-v1-1-79fb2f0f253b@ixit.cz>
References: <20251118-dts-oneplus-regulators-v1-0-79fb2f0f253b@ixit.cz>
In-Reply-To: <20251118-dts-oneplus-regulators-v1-0-79fb2f0f253b@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, 
 Casey Connolly <casey.connolly@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=822; i=david@ixit.cz;
 h=from:subject:message-id; bh=EBu0veDmUKkqndi/R0MzeoYGegTyBnWZ2KGLTX6A6Jk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHH6YQwCJN5mh2aVBhARO89TA6DDAnVhFvh95q
 /FJv85FTKuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRx+mAAKCRBgAj/E00kg
 cqRtEADGHYqpaOuG1irM7X9WmPbUkjChUCUvf80HUnoDZaV3jA4sH/+ZjrdUjd0yEnmyqLP8vH9
 OWPx2+pT64wbNI5AcBdTYRHz+96PIIwtXdHonK34kToE4u2JZYILtaalKpavxhehzGB8BsJaVc1
 /oddaXcRzZDi8J1o6GBkvVLKqxRyNMmyLb/Xgw9IQbdVwtoQ4GPm/88yQP3eOCIyhcclL2Of8dB
 p8bO1TWmXoEGBIXjcKJHjQCg9nWnkSKmOnbYpu5dOQ34jU0leusc0x2YjzbvHVe23mL5ISdiS7N
 Rj7RzL0ugQKwoV6S9bKX4GSLRPN9PCkqqec1q5DgzQqt7gQvXKR34fZvaWf7/1QlCIm+xSlJqRl
 IaUpUkDrEjIsj+DKJ9WIFM5aEwFGqFVd1iVSTRBKOrR14kvgtlTJvxY/E0CPsIpmt5pfx92pzeQ
 UT7WfT3BUYFWSuard92sKh7CgdemWwgwg5Lr3pfNiubYT1rzEDy9M8ccdAVTduq1uxfvoxyU2DI
 8ZPf45zbgwVT/cjPZHG0zIxCm4nK+MZz1dxZxYGSnJ1A9x54hNd0mJye84RJLwiPwgx++aADgog
 cQg8ZAzNLQkS8BjUBSKDb8hQeP0+89FXRuBm4SsY+CROkgCaSgNKGar4Rj+A+kvmxxFqr8iEsYV
 6qGDakfP7dJ+pHA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Casey Connolly <casey.connolly@linaro.org>

The touchscreen 1.8v supply doesn't need to be enabled at boot, only
when the driver probes. Remove the regulator-boot-on property.

Signed-off-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index db6dd04c51bb5..ee62adfa6af0b 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -148,7 +148,6 @@ ts_1p8_supply: ts-1p8-regulator {
 
 		gpio = <&tlmm 88 0>;
 		enable-active-high;
-		regulator-boot-on;
 	};
 
 	panel_vci_3v3: panel-vci-3v3-regulator {

-- 
2.51.0

