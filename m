From: Zhentao Guo <zhentao.guo@amlogic.com>
Date: Mon, 14 Sep 2026 16:10:23 +0800
Subject: [PATCH v9 6/6] arm64: defconfig: Enable CONFIG_VIDEO_AMLOGIC_VDEC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-b4-s4-vdec-upstream-v9-6-72fdb0d71b02@amlogic.com>
References: <20260914-b4-s4-vdec-upstream-v9-0-72fdb0d71b02@amlogic.com>
In-Reply-To: <20260914-b4-s4-vdec-upstream-v9-0-72fdb0d71b02@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, Zhentao Guo <zhentao.guo@amlogic.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789373423; l=804;
 i=zhentao.guo@amlogic.com; s=20251024; h=from:subject:message-id;
 bh=pkxh5YjN/46und6BilAFWFBEvRqbE1Z6teriyhXV5cA=;
 b=CAyXaceybdAKLUeLU2d0HLWWUDMcmAoH1I4NhFQbtFxR8UL6nWQG2fnK9u29DD+O2uA5TnFAA
 981k6/vvwhcCGondGMgxGoi+J9HhvGSCvsxZPV7hnZR/0F5abF5ignt
X-Developer-Key: i=zhentao.guo@amlogic.com; a=ed25519;
 pk=5yfDKrjreXwcAoEUsdtWafy6YN500upXp/CgtnXjLVU=
X-Endpoint-Received: by B4 Relay for zhentao.guo@amlogic.com/20251024 with auth_id=555
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the Amlogic V4L2 stateless video decoder driver as a module
in the arm64 defconfig to support stateless video decoder on Amlogic
SoCs. The driver is used by Amlogic S4 platform, such as S805X2
board.

Signed-off-by: Zhentao Guo <zhentao.guo@amlogic.com>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index f0947c8176a1..d29e7bf5769f 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -919,6 +919,7 @@ CONFIG_USB_VIDEO_CLASS=m
 CONFIG_V4L_PLATFORM_DRIVERS=y
 CONFIG_SDR_PLATFORM_DRIVERS=y
 CONFIG_V4L_MEM2MEM_DRIVERS=y
+CONFIG_VIDEO_AMLOGIC_VDEC=m
 CONFIG_VIDEO_AMPHION_VPU=m
 CONFIG_VIDEO_CADENCE_CSI2RX=m
 CONFIG_VIDEO_WAVE_VPU=m

-- 
2.42.0

