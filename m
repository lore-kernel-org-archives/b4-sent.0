From: David Heidelberg <david@ixit.cz>
Date: Mon, 20 Oct 2025 23:12:56 +0200
Subject: [PATCH] arm64: dts: qcom: sdm845: Define guard pages within the
 rmtfs region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251020-sdm845-use-guard-pages-v1-1-64d714f8bd73@ixit.cz>
X-B4-Tracking: v=1; b=H4sIANel9mgC/x3MSQqAMAxA0atI1gbaoDhcRVy0NtYsHGhQBPHuF
 pdv8f8DyklYoS8eSHyJyr5l2LKAaXFbZJSQDWSotoYMaljbqsZTGePpUsDDRVbsJvI0O+Mby5D
 jI/Es9z8exvf9ANN3t0RoAAAA
X-Change-ID: 20251020-sdm845-use-guard-pages-9c2b2fa0b71e
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Paul Sajna <sajattack@postmarketos.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2915; i=david@ixit.cz;
 h=from:subject:message-id; bh=E2eVtp9CZo235rNLq7eCdbNC0gKfjdqyqcrfaduc4TA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo9qXdl3mY7plSvTx0oldYpigYKjtk6zobkvdyJ
 cbZnG1oJDuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaPal3QAKCRBgAj/E00kg
 chXkD/9f5U607VemeAM2+jdhdbFPYzpHwX7OZtx3hLqgJkBJN1dC0xGvHiG8H0K4EUHbCQkhRxv
 QwdSeKNbcJmUs8xH8KxYUiLo3jHCeaAyp1keRtpIdDlFBZ5L1pR+vK9LN4blahQM4bLI7ZB1W0b
 MxurXBTOm3AGlwAhRpBv0kV7b/4N+gQnbI646YbQtobSx3glV46lXUj3BmbsLC6OcFAuRnpFU+7
 OzNOkX2Zc9nd+ftZ1nCr4IWACQ2xXxjJWJ3upw7pk5SoLc+mrJmo0+7rpZxDtVJ0SyFsb1xoBLs
 PaqkliW6Ncalr4WSghdwrVJ1E6n52lD3Pw5n553/CG1JD6TM5YWSCAZaeVOgXhlIdoquZL7ATeC
 YT5jTDo0C8O4sSsvBSfgW28XtNFZJvP8EIshF1KTww8/fo+v5pxkgvpdHJVO8hG1IVgeHJC2eck
 EYR9wcVX35nG4YQ4OyOsAX6zDrIBRhgq9C/yRJtj4kSYiNdbTFfkzU2oFQ3Q3WVSEzASkxsQtNc
 pa/Hce6ETuvOEHLJWDk5rRfjvt/Y/BuNCAZgYU6wvHNx7ghZFuWFZJ5qffWsiJLLwIndUeH3Dpr
 5qbOA7GXDqXdkN0uQe5lajrqiopiU6fwLCXlCGzfzrdD2TcWftF9oCuUybgIamLwQgZzOxuAz/6
 1Fw6sSftNiMU1ew==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use qcom,use-guard-pages property instead of polluting device-tree with
lower and upper rmtfs guard nodes.

No functional change intended.

cosmetic: set name the node rmtfs-region.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Tested on OnePlus 6T.
---
 arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi      | 17 +++--------------
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 18 +++---------------
 2 files changed, 6 insertions(+), 29 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
index 99dafc6716e76..83b98bad19dd2 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-lg-common.dtsi
@@ -99,26 +99,15 @@ memory@9d400000 {
 			no-map;
 		};
 
-		/* rmtfs lower guard */
-		memory@f0800000 {
-			reg = <0 0xf0800000 0 0x1000>;
-			no-map;
-		};
-
-		rmtfs_mem: memory@f0801000 {
+		rmtfs_mem: rmtfs-region@f0800000 {
 			compatible = "qcom,rmtfs-mem";
-			reg = <0 0xf0801000 0 0x200000>;
+			reg = <0 0xf0800000 0 0x202000>;
+			qcom,use-guard-pages;
 			no-map;
 
 			qcom,client-id = <1>;
 			qcom,vmid = <QCOM_SCM_VMID_MSS_MSA>;
 		};
-
-		/* rmtfs upper guard */
-		memory@f0a01000 {
-			reg = <0 0xf0a01000 0 0x1000>;
-			no-map;
-		};
 	};
 
 	gpio-keys {
diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index dcfffb271fcf3..61d63003fa371 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -75,32 +75,20 @@ key-vol-up {
 	};
 
 	reserved-memory {
-		/*
-		 * The rmtfs_mem needs to be guarded due to "XPU limitations"
-		 * it is otherwise possible for an allocation adjacent to the
-		 * rmtfs_mem region to trigger an XPU violation, causing a crash.
-		 */
-		rmtfs_lower_guard: rmtfs-lower-guard@f5b00000 {
-			no-map;
-			reg = <0 0xf5b00000 0 0x1000>;
-		};
 		/*
 		 * The rmtfs memory region in downstream is 'dynamically allocated'
 		 * but given the same address every time. Hard code it as this address is
 		 * where the modem firmware expects it to be.
 		 */
-		rmtfs_mem: rmtfs-mem@f5b01000 {
+		rmtfs_mem: rmtfs-region@f5b00000 {
 			compatible = "qcom,rmtfs-mem";
-			reg = <0 0xf5b01000 0 0x200000>;
+			reg = <0 0xf5b00000 0 0x202000>;
+			qcom,use-guard-pages;
 			no-map;
 
 			qcom,client-id = <1>;
 			qcom,vmid = <QCOM_SCM_VMID_MSS_MSA>;
 		};
-		rmtfs_upper_guard: rmtfs-upper-guard@f5d01000 {
-			no-map;
-			reg = <0 0xf5d01000 0 0x1000>;
-		};
 
 		/*
 		 * It seems like reserving the old rmtfs_mem region is also needed to prevent

---
base-commit: 606da5bb165594c052ee11de79bf05bc38bc1aa6
change-id: 20251020-sdm845-use-guard-pages-9c2b2fa0b71e

Best regards,
-- 
David Heidelberg <david@ixit.cz>

