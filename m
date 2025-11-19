From: David Heidelberg <david@ixit.cz>
Date: Wed, 19 Nov 2025 15:21:27 +0100
Subject: [PATCH v3 02/12] arm64: qcom: sdm845-enchilada: Specify panel name
 within the compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-sofef00-rebuild-v3-2-6cd55471e84e@ixit.cz>
References: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
In-Reply-To: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=978; i=david@ixit.cz;
 h=from:subject:message-id; bh=XdEJMzUlqHmVFvRkb119Ya6neFS+DHA5Y7GV7B5h8w4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHdJyMXGU0SPjy59reJxJwEVMCdZvJTNqQQBvk
 4S+oxbaH9uJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaR3ScgAKCRBgAj/E00kg
 coTLD/4lKOUmsMD5Xn+6M9R8x4QoYPWL8BjkBYsn36pMAtB+fo0UXsLK07Cg+Cq7PcruRm9WbkH
 XRk7G6jYdM15pdTJnJnlPnwhfoIZ/S0WnaN3ADeh6zfX4+IbXPVT0wj17u7wxkaZrSkAAnllVS0
 QVxn0v3/v+YmXqA4lK/dhtlfi5wo1VLLnJnCsKJ3Q5fRdJldEoCO5EZQx2QDuHtNk0ar6N6niFN
 Mfkoi3Y0CjecGmejwCDyu1gWTzcGJiMacRGGaT6OhA551GYnk76QbmW6uUPOggu+dwrLprXu4kw
 Xw3eiXNvdTSHtUwME5GL1Y9eUtTsAxhj1WBsqAo68tR7Ecz1OjK7RzVpGtUG8LKx/xIGwbXEwnF
 r0aoNGtHJ41Gv2mybmDsXnVL/P0MQgkKnk8Mam9jeCPi0+VXcuYZXUQkhdXeJqrY1I2bL2MY6As
 SRlx2zb244gXIw43Bmv3BgCq2ByJlholZg5aseRxHRxUJEygdMnh8wDmjghUzOQ693MEjZpBc4G
 dgXo94bX0bXBp+rOIIp5au7Rk6tm1D27inCiO15gN5Zu/A3mE91UsYMOVqohIbrI1E56kvu5oAA
 z7yQCVF2V401x3EXWgCmHyprBj3U3VuzVvd6/IXJVpA27JlDe2OyspLLR9Of4pNYkFbddY/BKJE
 8RQ+I6ntAE0v/LQ==
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

