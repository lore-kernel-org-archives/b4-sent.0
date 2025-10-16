From: David Heidelberg <david@ixit.cz>
Date: Thu, 16 Oct 2025 18:17:02 +0200
Subject: [PATCH v3 7/8] arm64: dts: qcom: sdm845-oneplus: Describe TE gpio
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-s6e3fc2x01-v3-7-ce0f3566b903@ixit.cz>
References: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
In-Reply-To: <20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=805; i=david@ixit.cz;
 h=from:subject:message-id; bh=+89dIAb307+D766iUEdy+zPCpNwpfjUMxJzd8fVjBoI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo8Rp5q2dOvtsknUbjUNwSHcaNLRNWN+FecCpIt
 o82OFlYPC6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPEaeQAKCRBgAj/E00kg
 cn/QEACGgswW/P0zslsiphemBB0c6BW1Vy6E1tvxtQnoJBav+EVs0JadpTeE5PetRiOUEvqsGQb
 HghwyTCcVqgp2O0jwICNjHvQQ8gySMY1VCsC1YAwPZceB6HZ82KTb5dOayiANi1gFXUyxVNR7SZ
 phzAPO+o6jOhbcdIKIGWF5Erblk7sMQ3BjFRRpAW7PxbybKql4YIlX9nJ5F/bI7w5E0Kz/Dcg47
 Y0A/fdj4ZwuV7zHK+NvxhFTa0EbgL0SlqGnhl5iWtXXG6GXImmaka7lnzoSanZsKHcFy7L09UzM
 mBSwyjLAsPv2p4ablgaiub2nUEZOk8rjMCPp8Or6WDEcs7Q6kvVqTcbmZ2Iuser7jASNfMvvEc5
 PZG0M3x6TFVaUTnNX+nUnOCpn7n6DTCR1HWdrmBoEgY7hUvk0kpMio4W5PRqHK15n1cIdejWWwE
 iYBcrjthD8LE2M6e440JXw8gI3b8q8dDxfqcoCNm1dh/oAj7qVbdXtbmOQCmgKp4ccGf/HsJz8M
 vpBuH618ZRW1R3Ve72J2Y7dM4V8fXT8EMXUdrIe7YZLw4NVRNBDOw0aLLhsG5w4sDbKZlDf7uF8
 3C9PNCo9itZYeZQrys8fb0gfoTGVqN1n4qppakNwO9496U7KpoJH0n5VzslMPVKUqHWTdolyvxP
 UekX+jkJNo//+Sw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Describe panel Tearing Effect (TE) GPIO line.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index a8e87507d667b..b663345de0214 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -460,6 +460,7 @@ display_panel: panel@0 {
 		vci-supply = <&panel_vci_3v3>;
 		poc-supply = <&panel_vddi_poc_1p8>;
 
+		te-gpios = <&tlmm 30 GPIO_ACTIVE_HIGH>;
 		reset-gpios = <&tlmm 6 GPIO_ACTIVE_LOW>;
 
 		pinctrl-0 = <&panel_default>;

-- 
2.51.0

