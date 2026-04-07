From: David Heidelberg <david@ixit.cz>
Date: Tue, 07 Apr 2026 08:43:56 +0200
Subject: [PATCH v5 3/3] arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable
 ath10k host-cap skip quirk
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260407-skip-host-cam-qmi-req-v5-3-dfa8a05c6538@ixit.cz>
References: <20260407-skip-host-cam-qmi-req-v5-0-dfa8a05c6538@ixit.cz>
In-Reply-To: <20260407-skip-host-cam-qmi-req-v5-0-dfa8a05c6538@ixit.cz>
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Baochen Qiang <baochen.qiang@oss.qualcomm.com>, 
 Vasanthakumar Thiagarajan <vasanthakumar.thiagarajan@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=932; i=david@ixit.cz;
 h=from:subject:message-id; bh=DU/dXePFyTa55SQv+lhHqY4KIdvjaGH0tSQ5egVr5Ig=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGnUp66g1k1G2PXK1XLApKqh8rZQqnP+rM1X6ccdHnoc1CQiZ
 YkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJp1KeuAAoJEGACP8TTSSByrA0P/3wf
 qabD5CEeb4B4+PsJgKOZY/BrgJN1A4Zdw5C35f3dwpNPtBQTwOkxEcSCHj5GYoAtZRGeJWCr+0Z
 6Za616Xc2FfWBQa3wtnFtArLaTN58RK4j9patgL5m1lOe+iXo9A8ZyowzTRgnLA3jvxqfibnXdU
 Cab7tJzP2IyopQE4WpkfMYjj6PbA72EmXSMtVqBpPr73FIyYL1rSswZ52gOxhVIGOx6SAaZg+4c
 KsKnhg03Fzx7Y3UKTFqJ2JYMadV/h+GgmL4PfmYQqcLUtEcMm8BBRPiVFKGproGfkJ6hDA59JFH
 CVwyIV3QEC8op9GElbGGXsiAq0XbBFo+qvLme+gDcpTakvz1EzLv/bfYG+SPP9K4a1LlklC5Ehl
 AX+zAk15id1qDONaAxEvMqmb3cGD13a+fh+2UIdFC85hqzpGzUYqUZR1HtQmwu00VcA40aMZ1OC
 2YgTBb6/gn82TMc4560FcTrUfrifRtAe1/jzgA1JvZsFhZHb+cCT2TqqduU7OmB4HfUxlWW/dm+
 776t78Z0IxeMPAMYeg2sSjUubPOWtuRYWn1A/dpuXxY2+75D6wlD/mukE0f+FzRdqVIQ8zImbK9
 fxQTk8iTFc8OkBhZ6pTMXKdAKOP5igNOcTaLWDJlAmQ74V63pcGF7c3fFwrZU38fc94/eSp9NM8
 hmeoN
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Amit Pundir <amit.pundir@linaro.org>

The Wi-Fi firmware used on Xiaomi Poco F1 (beryllium) phone doesn't
support the host-capability QMI request, so add a quirk to skip it on
this device.

Signed-off-by: Amit Pundir <amit.pundir@linaro.org>
Reviewed-by: Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
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

