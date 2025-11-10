From: David Heidelberg <david@ixit.cz>
Date: Mon, 10 Nov 2025 15:26:26 +0100
Subject: [PATCH v2 3/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 ath10k host-cap skip quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251110-skip-host-cam-qmi-req-v2-3-0daf485a987a@ixit.cz>
References: <20251110-skip-host-cam-qmi-req-v2-0-0daf485a987a@ixit.cz>
In-Reply-To: <20251110-skip-host-cam-qmi-req-v2-0-0daf485a987a@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath10k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Amit Pundir <amit.pundir@linaro.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=905; i=david@ixit.cz;
 h=from:subject:message-id; bh=qy5oPva7pVvXCU0lnaBR4INc65V2QzpyRC5geVzLuhk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEfYSEyRzkJmvfgAJpvXUzBxVbAyessE/n2pdK
 BpH66Qw9QKJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRH2EgAKCRBgAj/E00kg
 cuppD/9p2jsuLrWlZBehPEygW/swom728kSdtf3yvGUsD0T0LsJjNgjlZJcamWHr4Bq+LpDxGwL
 ERet9rdAVOH8F/8HBztFeOQz0FPcDcazFT2gru/awNWAJTgfCt/iR/lDGI+Tq59VfUTOzQFfWcj
 wn0ybPhxtjfggD/Rrx3Lb3cD+5G/ye+XXrox3BuhdrKozco5K0qqBIxthDsNb/dXHbRNBX8MMDl
 T7EeTMJKbMoWN3WEOrhUAnfgFAFsMNgXBp+LGmn68Pxft3d5822gIl0nYcawSgDHABfcmB1frGk
 LK21JVcx8cuC/Ap9vpxjx3U0+h9jea3utHU/mEE5+9ZUKc93I5SQ+9Qwi8TlIlV8WC7zSNTLeMs
 jKdVwjel7DJi4d3ppS9V3+cRPW6vaANpQHgnK5K27WzNEcMGyC731H4eat4+g/S4QqwhpRzVuCd
 EQxs9bnHztUmYLOvrahgnuvv7yii4tzb/hmmim2VEI3RteCq2DipwHRpVKkgBRHfZLktY8p3zv4
 aAqM4yhMRLtjmCMAGZLM1gQRZ1HdqEgVJk8DNqC5+DATVQpkJAaBcQDYhb1ezAAziBIrp4fWNvs
 9gQ8T3LgXsCNgWlQ+XshICR+/5/Xfr8RCOipx6fDIAKbit4tdvVqnc3/y2C8TlInlHh9wEhMLc8
 r8aH0c4r7KRkbrw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

The WiFi firmware used on Xiaomi PocoPhone F1 (beryllium) phone
doesn't support the host-capability QMI request, hence enable
the skip quirk for this device.

Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 785006a15e979..a3bfcf56ad3c8 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -636,4 +636,6 @@ &wifi {
 	vdd-1.3-rfa-supply = <&vreg_l17a_1p3>;
 	vdd-3.3-ch0-supply = <&vreg_l25a_3p3>;
 	vdd-3.3-ch1-supply = <&vreg_l23a_3p3>;
+
+	qcom,snoc-host-cap-skip-quirk;
 };

-- 
2.51.0

