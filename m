From: David Heidelberg <david@ixit.cz>
Date: Thu, 04 Dec 2025 11:41:24 +0100
Subject: [PATCH v4] arm64: qcom: sdm845-oneplus-enchilada: Specify panel
 name within the compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251204-sofef00-rebuild-v4-1-7f6e030ae5b7@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAFNlMWkC/3XNzQ6CMBAE4FchPVvThf6gJ9/DeICy1U2MaAsEJ
 by7BQ9gjMeZ5JsZWEBPGNg+GZjHjgLVtxjkJmH2UtzOyKmKmaUiVQBC8lA7dEJwj2VL14oLaZ3
 VqHM0wKK6e3TUz4vH0yd7fLRxuFnKC4Wm9s/5tYOp/X/QARe8ctYVYLAEow/UU7O1LzYtdelKQ
 /ar06gRjBIqExrQfutsrXe/Oota20opaQBziYsex/EN6JY/bT0BAAA=
X-Change-ID: 20251104-sofef00-rebuild-04cfc6e68e71
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
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2585; i=david@ixit.cz;
 h=from:subject:message-id; bh=gj0lInF8ociikTF3j/Wy5V0sdCoAD93LYDKcUIGln5I=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpMWVb9zK5trkln88z1jaFj44tBGnJQgnvtzvJK
 caiHY++boWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTFlWwAKCRBgAj/E00kg
 crfLD/9TX7X7yRxP/Wum7g46+lTMZ0chXFYuXJ0IPcbteaRDkRkUf1twwxaHIY8TQGlSwgk96BB
 pOIH6PYnw1mfd7ooLpsW6/6iwKkDeOqKSRizGH60JnJ9tBIs8ek5chquIvwpZVY+6M+CWCmYewI
 Pj0BcvNX3uU6p9oltQ8sCnccFRAjKk6taUOEko8Jvdux5lTlR84yYHh+zxN4eS9c58mVkNnNwpD
 f3Xhtxk6bVAnkddIsBvpqES5pxYodSzw+bpsko3qPOXyRvd0PAX25N2VZdEb+SaymqefL/1JaPb
 Kd5JiggOvnJfbQFYcQVkNo4XXMSqaSzp2TvVoym7eH+9gjH/YbXNFVtxLaZ8mtLq7y0/yPWRon7
 BhgRuLrdOZDBPobPp/dtvCIV7IqxmPcNbkv6dJ7c5M06UQ0U/ZrGsqS9z6zA+clkxCVUetkVQY/
 F/2Ki9aComJLw1a5V2uke4Ws0LzRGmHDm/HrFTCRdOocww5Ihrx1BoHO+IrhZJe7ViGdA1QX5ye
 RxGBrD9qUsnImDzeDKtYt7PjNNTHKJ5GlCZCEQ0+VVCCErKqsbnkBiP5gQEhlrPflj8SHjWHkuD
 E4BvBCr0uGectZq4ZbY9MX20isfmh/J6TASxpF7odzGZiPrw2sb58PWWBVjd97v3+vdBkTnSZZO
 ngekh7S334pjW7A==
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

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
This DDIC is essential for panels used in OnePlus 6 and Pixel 3a XL
(SDC variant). With proper support, all downstream patches in
sdm845-mainline and sdm670-mainline can be dropped.

The mainline driver was broken so far, and with my recent introduction
of S6E3FC2X01 driver, I had to "break it even more" due to OnePlus 6
common device-tree changes which defined all the regulators and
corrected properties.

At this moment the first version of the patchset will not include
Pixel 3a XL (SDC) as no testers yet volunteered.

The code, including the Pixel 3a XL enhancement can be found at
  https://gitlab.com/sdm845/sdm845-next/-/commits/b4%252Fsofef00-rebuild
---
Changes in v4:
- adjust commit msg s/enchilada/enchilada-oneplus/
- no code changes, just resend as all other commits got reviewed and merged in -next.
- Link to v3: https://lore.kernel.org/r/20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz

Changes in v3:
- Drop arch prefix from the commit. (Bjorn)
- Added Casey into MAINTAINERS file. (Casey)
- Moved compatible legacy comment inline.
- Link to v2: https://lore.kernel.org/r/20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz

Changes in v2:
- General fixes to device-tree binding (Krzysztof)
- Add myself as a maintainer
- Updated commits wording
- Link to v1: https://lore.kernel.org/r/20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz
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

---
base-commit: bc04acf4aeca588496124a6cf54bfce3db327039
change-id: 20251104-sofef00-rebuild-04cfc6e68e71

Best regards,
-- 
David Heidelberg <david@ixit.cz>

