From: David Heidelberg <david@ixit.cz>
Date: Sun, 07 Jun 2026 16:12:18 +0200
Subject: [PATCH 1/2] arm64: dts: qcom: qcm6490-shift-otter: Convert fb to
 use memory-region
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260607-shift8-fb-v1-1-72b9dac25f4a@ixit.cz>
References: <20260607-shift8-fb-v1-0-72b9dac25f4a@ixit.cz>
In-Reply-To: <20260607-shift8-fb-v1-0-72b9dac25f4a@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1010; i=david@ixit.cz;
 h=from:subject:message-id; bh=31h4ioQzbcHAXb50MokaSyiYOmg1H0n523N8ZRz5iGE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqJXxH+olj1QhBfSEcCgVsdItddc0Xa0lU7S+A5
 GLYM453ssyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaiV8RwAKCRBgAj/E00kg
 cjCKEACjSjFf012CANltf8ay6OM0l87B7IiCRnqWqFyZsObAonCKbj9zyDXvu5EGjftS75bYrGL
 ctMD+3x2i9RRpHTKIaJabHUda531b+zJu8uuGANflhFCjNiUhN9qTnYgMwcVE4o2UP8/N86WkCI
 Ayw3p8pmeezbQHVHsO/iVDOVPLwCGb71gnLFAYanFyai4oBISQn6qQvcDFbIrCZTlFZIAK+6oJu
 SMgsuszb9Ewq0+8axLNNShE0mETmqOAD/xcLgHrVC+J5cRPJKzjqXZetBEMf1qLMQt5KFrq5OE9
 oaOcplLAY+otIqCL5lx2W1N4you/rPEDgYxBmuGiBdSKLHOloP11ozq/4X0g6y7coAeNqAKpmex
 Gh/5corsONX/Z4VN+VwdBKOek6/vxA42Q7KkfQIgRhVte+GQ7HDXeHspwXVR6PvAV179XJMPZMr
 KgWcR8VsdkpM9hFHULTkrxikYwn3mnbhAW6SJx4NRK+amaYAmfFhtEZwPoPGsfbEKF5rVBIk3x5
 MstEYsrP6SXo09U7R4rMNaD0Gzww6Ue/qaS/IUxCJlo0cv/iL08Oo2OStKKonDqpiOKasJCZNFT
 qjSqrK26alLt6//OrIfXKQs6iE52tCdmpUDWuxHPZ8/VszxYaCAVzlKmukdtSQPwHLKgeseRB9U
 /nZpaWwcRrVYGJA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of manually specifying reg, reuse the memory region.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/qcm6490-shift-otter.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/qcm6490-shift-otter.dts b/arch/arm64/boot/dts/qcom/qcm6490-shift-otter.dts
index 797f37596bf19..9b90143d2c332 100644
--- a/arch/arm64/boot/dts/qcom/qcm6490-shift-otter.dts
+++ b/arch/arm64/boot/dts/qcom/qcm6490-shift-otter.dts
@@ -34,19 +34,19 @@ aliases {
 
 	chosen {
 		#address-cells = <2>;
 		#size-cells = <2>;
 		ranges;
 
 		stdout-path = "serial0:115200n8";
 
-		framebuffer0: framebuffer@a000000 {
+		framebuffer {
 			compatible = "simple-framebuffer";
-			reg = <0x0 0xe1000000 0x0 (2400 * 1080 * 4)>;
+			memory-region = <&cont_splash_mem>;
 			width = <1080>;
 			height = <2400>;
 			stride = <(1080 * 4)>;
 			format = "a8r8g8b8";
 			clocks = <&gcc GCC_DISP_HF_AXI_CLK>;
 		};
 	};
 

-- 
2.53.0

