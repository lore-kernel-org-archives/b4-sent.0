From: David Heidelberg <david@ixit.cz>
Date: Sat, 06 Dec 2025 18:45:42 +0100
Subject: [PATCH 1/2] arm64: qcom: sdm845-oneplus-enchilada: Sort nodes
 alphabetically
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251206-sdm845-oneplus-fb-v1-1-19b666b27d6e@ixit.cz>
References: <20251206-sdm845-oneplus-fb-v1-0-19b666b27d6e@ixit.cz>
In-Reply-To: <20251206-sdm845-oneplus-fb-v1-0-19b666b27d6e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sam Day <me@samcday.com>, 
 David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=853; i=david@ixit.cz;
 h=from:subject:message-id; bh=f8AylPAfQwJYowskjfPG4hRtNdzKdwuU2ot2JsiEcNI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpNGvINIeTkY909kEAv2eAgp3zDkd3W7HQzp2EL
 gUtlwEfgQ6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTRryAAKCRBgAj/E00kg
 cm71EACjsfWlNkz/6eqQ8MTgVoRUzImvKTFKyu0w3zFj0gyysYiJdYICh7zQO5MUfdN/GqAxne2
 HKRvQGbUoRTm8ZRyEJskESRwIhkfV7S5JDg3VEsOmZEppgbUOUDYHnNXQsOmhCf2SkR+QKxfKmA
 VZH9WZZiO8PCEDtgVsV3Y3DpiTAc1wdTG7GpKA55L9sS/EFeoj+ph1VmV/DdvA9OcsXyhocNHjL
 FKjJyb2OvKA0dvRSUjS+8edVbuPhJRBRrYO5N+J2z0km5vRLJS5jccVwoEwmLKHyqcyjmPh0fzn
 4NUxvNrbr5p8PX7jLh+qX4knSaLuvqjo/m/Szfi3OK6DWnzD2D8w7zLlUTChI4fbmDx0IWTRGXs
 O6bRABrGcqdUqaSIqNwmGCZ+8YATMIJffuEDGRY8rk1JrYzfKtWiB1Hty9HZdZnvYvSJW5dfotM
 jSC0Xp+yBkBY5cRrlcwDyOWMyxyA7S2cxjHJ8Rip6Y5g7CTNbsmHnMFBjIotoxrq73PGrT+41Yr
 zNHEru66UmfFm3J9LMUXlmWbuKA3saSifDo86SMzgXy/Z+CdzlrOMHd2/oBRjZz/F2VUq7KpU2Z
 kTZWRHlb/5kpq4FC3dpPaKFyUfwiMp8CXBHKyp6174S/6GokMH3/NeL46PlLdP6xQlR0bDuBsP9
 TFEE9ghggXMZNLw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sort the nodes by alphabet, no functional changes.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 8 ++++----
 1 file changed, 4 insertions(+), 4 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index 8aead6dc25e00..c6b1edea2809d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -30,16 +30,16 @@ battery: battery {
 	};
 };
 
+&bq27441_fg {
+	monitored-battery = <&battery>;
+};
+
 &display_panel {
 	compatible = "samsung,sofef00-ams628nw01", "samsung,sofef00";
 
 	status = "okay";
 };
 
-&bq27441_fg {
-	monitored-battery = <&battery>;
-};
-
 &i2c4 {
 	status = "okay";
 

-- 
2.51.0

