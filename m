From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 08 May 2026 21:31:51 +0200
Subject: [PATCH v4 8/8] arm64: defconfig: enable designware mipi csi-2
 receiver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-rk3588-vicap-v4-8-6a6cd6f7c90b@collabora.com>
References: <20260508-rk3588-vicap-v4-0-6a6cd6f7c90b@collabora.com>
In-Reply-To: <20260508-rk3588-vicap-v4-0-6a6cd6f7c90b@collabora.com>
To: Mehdi Djait <mehdi.djait@linux.intel.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Kever Yang <kever.yang@rock-chips.com>, 
 Jagan Teki <jagan@amarulasolutions.com>, 
 =?utf-8?q?=D0=9A=D1=83=D0=B7=D0=BD=D0=B5=D1=86=D0=BE=D0=B2_=D0=9C=D0=B8=D1=85=D0=B0=D0=B8=D0=BB?= <mai.kuznetsov.misha@gmail.com>, 
 Charalampos Mitrodimas <charmitro@posteo.net>, 
 Sebastian Reichel <sebastian.reichel@collabora.com>, 
 Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Collabora Kernel Team <kernel@collabora.com>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778268716; l=1048;
 i=michael.riesch@collabora.com; s=20260428; h=from:subject:message-id;
 bh=a8sioWJftfSyXN0rqDXq8bBppSiXX8eZImBE70llAi8=;
 b=k+9b89ylohfx4XhLo13ZZ8+1xS+5spcQu5ypNg2QKU4QuObf5FXVwZudj+nb4bW5JLkDETZsV
 E6/bPi+jYKaBNXJiVjojvUp0VQTHopdEZ5A9spZGsuw0nW8j9CBO/w8
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=tAbmpPTE1MELYweXqqDU40fa18uCO6s32GJL/RzyW2Y=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20260428 with auth_id=759
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Synopsys DesignWare MIPI CSI-2 Receiver is integrated into recent
Rockchip SoCs, such as the RK3568 and the RK3588. As a consequence, they
are used on a lot of Rockchip-based single board computers and/or
corresponding camera modules, such as the Radxa Camera 4K. Enable the
driver for it in the default configuration.

Reviewed-by: Mehdi Djait <mehdi.djait@linux.intel.com>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index d905a0777f939c51cc39df6230591a31058b765f..9171f750337e540f0feec998c7aa33d3444b806e 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -918,6 +918,7 @@ CONFIG_SDR_PLATFORM_DRIVERS=y
 CONFIG_V4L_MEM2MEM_DRIVERS=y
 CONFIG_VIDEO_AMPHION_VPU=m
 CONFIG_VIDEO_CADENCE_CSI2RX=m
+CONFIG_VIDEO_DW_MIPI_CSI2RX=m
 CONFIG_VIDEO_MEDIATEK_JPEG=m
 CONFIG_VIDEO_MEDIATEK_VCODEC=m
 CONFIG_VIDEO_WAVE_VPU=m

-- 
2.47.3

