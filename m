From: David Heidelberg <david@ixit.cz>
Date: Tue, 04 Nov 2025 23:16:10 +0100
Subject: [PATCH 02/12] arch: arm64: qcom: sdm845-enchilada: Specify panel
 name within the compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251104-sofef00-rebuild-v1-2-dfcfa17eb176@ixit.cz>
References: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
In-Reply-To: <20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=890; i=david@ixit.cz;
 h=from:subject:message-id; bh=gC1Y0XFWgXtqr21a8lQBohbuf2aAabfAVdPVUFhXq/o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCnsrefsVG8yAxscAoT5RPZOEbQJHkjvDDqUhp
 4qXbq5I9QmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQp7KwAKCRBgAj/E00kg
 cqtbEAC5gs+xlucpqIFCsdjxNByKIGfdOjoxZG0SHTZ16xG7TmDOwLvQdXOWphPKQl2a/GS++fC
 rWkI79nS8ZZTNCMqXBNiDA63gcdfAV71sOS9hgZVOOTYs9299wlSThIeQ7lib9UPzcGj6XeEIvX
 fLVYCABOblvN+Qr5xtE7UQ8yR0Ec2ftxb9egSX0DPop3fAW0Z99YZxZRbDthmP+lkD8wg+KHteV
 UusTrX2WXWk1ArdT9a83+RXnG6ebJEMp91ersFpyXaPHtYqleOZMzXSjpDQVCYVHualKvYI8qg6
 ppxjDpCBc8ceJJfbSNAXFbJ1wajoInunlutixL1Wkf/GAgIVgpMRKOQSPoD9xQAe+Wg3p32+frI
 37T0EuXDyIQjeZHB9qvAWFMZUXVKXZKBa5GVtqN2oAl3+qbSg6ecGhfZUDzbVDraxrcWtu1/RPN
 tK8SefyF6rGCwesQ6sQTwHV8zkOJPrh/NG0bBGkp8HUmOe/EA7zm0mutXvu51SGItE67so1ZtCW
 a5CPynaqjk6X/g/SrIHwcCvVMPejjZ8jHe6+AyslJb0Mz+24hZtY2yE1ZuN2atmTPtkDf3yIQ5Q
 K351c8f01gUScN4fy56kmQfBGUI7K0loSanWLxZJW6w/pXWkCtqxzYN8yoZwJoC0dnoixUcQTYk
 BLDJKoY/YcuCU2A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sofef00 is name of the DDIC, it doesn't contain name of the panel used.
The DDIC is also paired with other panels, so make clear which panel is
used.

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

