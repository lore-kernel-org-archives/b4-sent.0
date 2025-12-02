From: David Heidelberg <david@ixit.cz>
Date: Tue, 02 Dec 2025 12:31:11 +0100
Subject: [PATCH] arm64: dts: qcom: sdm845-tama: Keep labibb on, so kernel
 can disable it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251202-tama-labibb-v1-1-f8f3fda53d1d@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAP7NLmkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDIKFbkpibqJuTmJSZlKRrbGqUYpBqnGRqbJqoBNRRUJSallkBNi06trY
 WAJK5FcNdAAAA
X-Change-ID: 20251202-tama-labibb-352d0e3b535a
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1307; i=david@ixit.cz;
 h=from:subject:message-id; bh=0UAAE/GYUfDSMLAMoQz/OVDB+waaDiiqt3ufPTsWZ7c=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpLs4Cxo4sEgA4auX8qDQVu1C0Ys5Z92vxDo5nR
 oWfeNHX+06JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaS7OAgAKCRBgAj/E00kg
 ctZ9D/4ph94Vj16a0ibUs8T7RMZ/uzH3ySwLHRXRnxEGxoS/zqT52pPpT8j7w9ArSLdreFh44d5
 9UyzpaZydzVssH4rV8ylCObkwBNuPdkt4WkCnz17nHMzj3IT9EYJweC8owuA+8LopalvRDJtoWZ
 GKbXICzbLd4QjakbRK3VpVsiMb8kPgd2A03hSECWLSX+NXMnBqA1bBAf3i2khjpkhFgGHifRnm6
 5lz1SXgurUKEa9grvASL4cHBTg1G+UnyFl+ccttkLVGdipdmaEx2O1gQ5NesyJoLitUEVsgijBm
 8gIDgSUkl1sO9klZjnjod/IXe5FpOwSabAlT8gtdXAAsv2EwGO9UTfxjr/1wTKGevcqCdS8WWte
 59r7+ojFjrFUkYxGyDO+BKyEU+9qFufLd7tKsfQ9hvYjCzOy3IVPxcbZjOT++gmrbw0QG+ZqOG8
 6M798CgG0R7LdVH9SVKOrsi2V5dWkyI1dNPAOU4h0bgTPPYGfohII5MlSvZ4bwExQC6JSXDyP6D
 /6TQ4s5pKZySmG/Arc4aTuqbv5sasQgeoOZuBpTUqxknt43Io2mZeYoASshThDXPWU2Q+WcMlSP
 YwHF90Y31GWyaTkMOPqfdIEuGz5U99LElQyDpbpVGrt/tZ26UhZVaTdg/YgMeKm3NEFyImFaDP5
 s33dy6dL/j/J51Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In case if they were enabled by the bootloader as part of some
reference/common routine and left hanging. Linux will switch them off if
they're never used.

Discussion about it can be found here:
  https://lore.kernel.org/all/20251130-oneplus-labibb-v1-1-bb3653e43120@ixit.cz/

Fixes: 5dcc6587fde2 ("arm64: dts: qcom: sdm845-tama: Add display nodes")
Suggested-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama-akatsuki.dts | 8 --------
 1 file changed, 8 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama-akatsuki.dts b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama-akatsuki.dts
index 82e59e4533549..c2b38ecb2e9cf 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama-akatsuki.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-sony-xperia-tama-akatsuki.dts
@@ -28,14 +28,6 @@ ts_vddio_supply: ts-vddio-regulator {
 	};
 };
 
-&ibb {
-	status = "disabled";
-};
-
-&lab {
-	status = "disabled";
-};
-
 &panel {
 	/* Akatsuki uses an OLED panel. */
 	/delete-property/ backlight;

---
base-commit: 95cb2fd6ce0ad61af54191fe5ef271d7177f9c3a
change-id: 20251202-tama-labibb-352d0e3b535a

Best regards,
-- 
David Heidelberg <david@ixit.cz>

