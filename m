From: David Heidelberg <david@ixit.cz>
Date: Fri, 03 Apr 2026 15:58:48 +0200
Subject: [PATCH v3 3/5] arm64: dts: qcom: sdm845-shift-axolotl: Correct
 touchscreen sleep state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260403-oneplus-nfc-v3-3-fbdce57d63c1@ixit.cz>
References: <20260403-oneplus-nfc-v3-0-fbdce57d63c1@ixit.cz>
In-Reply-To: <20260403-oneplus-nfc-v3-0-fbdce57d63c1@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Alexander Martinz <amartinz@shift.eco>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Alexander Martinz <amartinz@shiftphones.com>
Cc: Petr Hodina <petr.hodina@protonmail.com>, 
 biemster <l.j.beemster@gmail.com>, netdev@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, oe-linux-nfc@lists.linux.dev, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=928; i=david@ixit.cz;
 h=from:subject:message-id; bh=3p89nuzWMcLg3xFnxiidibI8l/wXleSjVbWxGiy6epA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpz8ebx4SmbawhVTwGcmD5aeTpVlKAwXUN9BFhw
 il9hg1v4WmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCac/HmwAKCRBgAj/E00kg
 crlbEACv+62mnegW2bXxUSY6S+Ho+OdsRXU58kz9iSpMeQv7uSoNdUP7YYhA7cRxEd1OVR5OGu5
 zEvo/0FEtb97tsjc6aYz2Adz86uNyju5Zdg8tgB/vc74/RwizMIL5FJm1YYkxV8GvEqR1aybDQ8
 Fpjwgo1/Q8aoCVVtaET6cHHw31oQzdO4m7A6QfokYx/ymPOa4RM8NifKareBSAFor8roSUX01ru
 W08+RRSXBX28zCA8+cHldHHDHTljhpBZJm4OJUL4F4m38nm9rdW9JrnxwrEAxaFZiGtb+bOdyUF
 i2ZTC4bhO6Dx1dXCJ0iIim5P2ciCqNBdma/goSc7QTdcCjwMCkdOi8MzlgbSSJmrxvXxyQy3f8E
 81MlFwEQVWOcbtrbJU67cmTmNhpHUKvmI0sMs07//8uBv7H6p2kr+0Fi3WvmZiMnxZLPpCDUS8H
 VADfUNFT7Wyu88YAWx+nbMh4NpPLRGBhTN/MGjdDE+MRm8KA6YJmLhhK2C3U5NpRLiZN9mORYlA
 E9sqCJnKdxW943hRlytLJcmf8x5BNtB72FRrCr3TaoY0M3gatG6uE1SICcpaVgUwWrMjPpKAkFb
 XiAc2pwnM58TZty4ummFQBD3p9bY+VW1aYs4yordJxM7ZIqevkFXwMlBWYRCbzxOIBlQ0tX2eS1
 jqi5Vb6OP1PTl/A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There is no suspend state in the mainline kernel, use the sleep state
intended for this purpose.

Fixes: 45882459159d ("arm64: dts: qcom: sdm845: add device tree for SHIFT6mq")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
index 740eb22550724..783d66cf5b0f8 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-shift-axolotl.dts
@@ -446,7 +446,7 @@ touchscreen@38 {
 
 		pinctrl-0 = <&ts_int_active &ts_reset_active>;
 		pinctrl-1 = <&ts_int_suspend &ts_reset_suspend>;
-		pinctrl-names = "default", "suspend";
+		pinctrl-names = "default", "sleep";
 
 		touchscreen-size-x = <1080>;
 		touchscreen-size-y = <2160>;

-- 
2.53.0

