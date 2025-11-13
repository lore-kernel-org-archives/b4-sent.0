From: David Heidelberg <david@ixit.cz>
Date: Thu, 13 Nov 2025 18:57:36 +0100
Subject: [PATCH v2 02/12] arch: arm64: qcom: sdm845-enchilada: Specify
 panel name within the compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251113-sofef00-rebuild-v2-2-e175053061ec@ixit.cz>
References: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
In-Reply-To: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=978; i=david@ixit.cz;
 h=from:subject:message-id; bh=XdEJMzUlqHmVFvRkb119Ya6neFS+DHA5Y7GV7B5h8w4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwUx5fxhZW3ru/k/CW3PaGg7zjqBNcd1dxuy
 WwS+gVUg/6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFAAKCRBgAj/E00kg
 ciOeD/94fR70j8mcyMtewNc7kRaVyQ+Uf9kvO5pfU7PAvyoGj6eaIMNgCZmw5d3CuDkjm1LlqRN
 KANBySbzAKuH3t+0rayZBiMjWPV72E2PuqMRYKk1/JnD6W9+GGaX0boMH+WbgdQjOTIxfgwMAcT
 VNXfgmsksZcsX+UM4XJXXFb3HHvd8r0gR7U1Fvz+gzT7fDlAE790cSJOnQ2YC4xHNQbqLSED1te
 5aac+sYU2kkbfbLJ3IsTGqRuxhltvmzE8daMEkekpyBqnFJnvc1FWTdjz/mg7c8aPGOyYyyMv3N
 4D7HDbVEuZ1b8m3De/F9WT/p9LO2Tx7k2YmTQZZ8QvIO+mu0QydnW6BsWxoJpIXb2cUOvD2r442
 T1KeNz2tJaTIN2e5jDeJ9ci8OVIStlFtY2m0HY3N4Tir/zZsu9NNxamFO9OHjjVu25EdZU/HWEw
 f6fE81aL2NV7HJ/8hAuAzqacp5NXMij3PwWUk2RnzBVixtSsiux181tt4R0HTZhVozMLeX7165/
 3IYWscFVeLGMY3QOoDCm9YzGfUE1K03YcJMCOyQZAe29mVkIw8HkhMa/GdbEQW/V5vCfwaRqCAe
 6ZmfmZgsuUzmWaAS6k8qrrEJh0PszMU1CL19KmfjgmpaPbUR3V/h5ORHylvpOXki0dZqD5zKYvO
 IyDko+cwq5UXTvQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sofef00 is name of the DDIC, it doesn't contain name of the panel used.
The DDIC is also paired with other panels, so make clear which panel is
used.

New device-tree will work with old driver as expected, due to secondary
compatible.

cosmetic: sort the node.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
index a259eb9d45ae0..8aead6dc25e00 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-enchilada.dts
@@ -31,9 +31,9 @@ battery: battery {
 };
 
 &display_panel {
-	status = "okay";
+	compatible = "samsung,sofef00-ams628nw01", "samsung,sofef00";
 
-	compatible = "samsung,sofef00";
+	status = "okay";
 };
 
 &bq27441_fg {

-- 
2.51.0

