From: David Heidelberg <david@ixit.cz>
Date: Wed, 16 Sep 2026 00:25:47 +0200
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-xiaomi-polaris: Extend the
 xbl_mem region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-sdm845-xbl-mem-v1-2-6e3c88507997@ixit.cz>
References: <20260916-sdm845-xbl-mem-v1-0-6e3c88507997@ixit.cz>
In-Reply-To: <20260916-sdm845-xbl-mem-v1-0-6e3c88507997@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Amit Pundir <amit.pundir@linaro.org>, 
 Molly Sophia <mollysophia379@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>
Cc: Konrad Dybcio <konradybcio@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1740; i=david@ixit.cz;
 h=from:subject:message-id; bh=KhYtwAwwEEXXn9tBUw2nXm8/lwiJ0Ak0iHOYARf9L+U=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqcXyLbC8CHVLLesOcCo2SCkcuNpN3GjL6x/rH
 u2kBTerxUWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqnF8gAKCRBgAj/E00kg
 cuOKD/9jiRMig1oJLnCMIdmnE/PzVhRMa+SIv9Af4gTT+JywSfkc8vPV53MqqutyT1vvV7kqB8e
 YyvzSUhRnh8wKVEvqjy/XQPOK66YyKpeO4upTv0UsIwHjxK7EKBAxRRZP1ybhgKOrXcT5rUz7TG
 GNEjBVsAuvevgZ9vFAO3V2Iw9NNBuZkPhnYrXcEuVvdcLg+pMkUXaOc7uwl/wDpdL2k0PgNO+pH
 g0Ukyv+5HqycK9ekwogknYL/47aQQI36OY3dsdyHRVr3ObRsqZFUbX9XR/3Ne3Z5936I6C0Q5qd
 TAoZeC8N7Y7xMYh6BLt8HaP43otEwJ2ZfRjkB2hk6yuaDSEjiKuoOaaoku8DLax/j4dSVYiYNli
 yDQv+azssGsM3eqGNVwJY8DdkBAZ4xY+1uxahj8TTekzSc0Bu+Z8U4k/9sY9VTV3JcKgm8B/ea9
 Uv2k0Iif+FRpuwRrtgUAmqbs9ILTqTaSmCSYtLuSNGWPVSz1VW1Jfx/QUwsXVi6ET/7/bHxYhQ7
 UFxxOtfrR7PyW3RpdSScspGg+pXwgs34oxLUzWsohUXCbe32Vb/oQAz1LBY4obwQZyFQaQXELfN
 mD7MLjKYvasHwx5KHecZomdvI6dlc8QLYQWLXo2bWWN1sg4QBibtCXTQlZ4zh8DoHMczuLzs+0E
 RVVZkLUoU9AJPBA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Xiaomi's Oreo-era tree still had the CAF 1 MiB region, the 2 MiB version
arrived with the Pie import. This isn't a board-layout quirk, it tracks
the firmware. The later XBL wants one extra MiB below the old region.

Cc: stable@vger.kernel.org
Fixes: be497abe19bf ("arm64: dts: qcom: Add support for Xiaomi Mi Mix2s")

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
index d3162e4444532..a782023d0dcb3 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts
@@ -27,16 +27,17 @@
 /delete-node/ &adsp_mem;
 /delete-node/ &wlan_msa_mem;
 /delete-node/ &mpss_region;
 /delete-node/ &venus_mem;
 /delete-node/ &cdsp_mem;
 /delete-node/ &mba_region;
 /delete-node/ &slpi_mem;
 /delete-node/ &spss_mem;
+/delete-node/ &xbl_mem;
 
 / {
 	model = "Xiaomi Mi MIX 2S";
 	compatible = "xiaomi,polaris", "qcom,sdm845";
 	chassis-type = "handset";
 
 	/* required for bootloader to select correct board */
 	qcom,msm-id = <QCOM_ID_SDM845 0x20001>;
@@ -58,16 +59,21 @@ key-vol-up {
 			label = "Volume Up";
 			linux,code = <KEY_VOLUMEUP>;
 			gpios = <&pm8998_gpios 6 GPIO_ACTIVE_LOW>;
 			debounce-interval = <15>;
 		};
 	};
 
 	reserved-memory {
+		xbl-mem@85d00000 {
+			reg = <0 0x85d00000 0 0x200000>;
+			no-map;
+		};
+
 		adsp_mem: memory@8c500000 {
 			reg = <0 0x8c500000 0 0x1e00000>;
 			no-map;
 		};
 
 		wlan_msa_mem: memory@8e300000 {
 			reg = <0 0x8e300000 0 0x100000>;
 			no-map;

-- 
2.55.0

