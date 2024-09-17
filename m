From: Vedang Nagar <quic_vnagar@quicinc.com>
Date: Tue, 17 Sep 2024 14:54:31 +0530
Subject: [PATCH] arm64: dts: qcom: qcs6460-rb3gen2: enable venus node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240917-venus_rb3_gen2-v1-1-8fea70733592@quicinc.com>
X-B4-Tracking: v=1; b=H4sIAM5K6WYC/0XMWwqDMBCF4a3IPHdgnHhBt1JETBxtaBs1qVIQ9
 95QC338D5xvhyDeSoA62cHLZoOdXIz0koC5dW4UtH1sYOKMqrTETdwaWq9VO4pjzImlKLknYYJ
 4mr0M9v0Fr83ZXpY1uq9z/LN18kMVLuZZZBWheUzmjmZygx0DEqtqUKQ7rfN6S6E5jg8Ul7zks
 AAAAA==
X-Change-ID: 20240917-venus_rb3_gen2-502e672d0e20
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Vedang Nagar <quic_vnagar@quicinc.com>
X-Mailer: b4 0.15-dev-dedf8
X-Developer-Signature: v=1; a=ed25519-sha256; t=1726565071; l=1015;
 i=quic_vnagar@quicinc.com; s=20240917; h=from:subject:message-id;
 bh=ZOz1XrvGoup5DkTpUjnTAImnT63pIeOYTBQe0DKCiP4=;
 b=4CvhtO+l3KQXE/X5CjMCShcqBxg8W6nsJdtPKY22T4SZhGUtRDkxecxOX88BL8wbEicNPq8/S
 l2ELgUskF39DlugXTrKXvEFEeNn4MP9rvA2UGp2Jn3bDu1lt0FbLuKG
X-Developer-Key: i=quic_vnagar@quicinc.com; a=ed25519;
 pk=GHqLT8NPue4v+CDHbZork8Ps39CBHq345GQKvCZ1glE=
X-Endpoint-Received: by B4 Relay for quic_vnagar@quicinc.com/20240917 with auth_id=213
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the venus node on Qualcomm Rb3gen2 so that the
video decoder will start working.

Signed-off-by: Vedang Nagar <quic_vnagar@quicinc.com>
---
 arch/arm64/boot/dts/qcom/qcs6490-rb3gen2.dts | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2.dts b/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2.dts
index 0d45662b8028bff475024cff37c33e01d2ee251b..d52a7e0a35bf941c66ccaa00425147781976b359 100644
--- a/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2.dts
+++ b/arch/arm64/boot/dts/qcom/qcs6490-rb3gen2.dts
@@ -790,6 +790,10 @@ &ufs_mem_phy {
 	status = "okay";
 };
 
+&venus {
+	status = "okay";
+};
+
 &wifi {
 	memory-region = <&wlan_fw_mem>;
 };

---
base-commit: 3f52e32445a1f63b788bc8969b7dc2386a80a24d
change-id: 20240917-venus_rb3_gen2-502e672d0e20
prerequisite-change-id: 20240913-qcm6490-clock-configs-0239f30babb5:v1
prerequisite-patch-id: faac726ebdf08240ab0913132beb2c620e52a98a

Best regards,
-- 
Vedang Nagar <quic_vnagar@quicinc.com>

