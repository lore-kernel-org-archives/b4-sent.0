From: Igor Velkov <iav@iav.lv>
Date: Mon, 02 Nov 2026 17:49:46 +0000
Subject: [PATCH] media: rkisp1: Depend on PM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-rkisp1-depends-on-pm-v1-1-35a26cb2bbce@iav.lv>
X-B4-Tracking: v=1; b=H4sIADnN6GoC/x3MQQqEMAxA0atI1gZMHIV6FXGh06hBrKWBQZDe3
 TLLt/j/AZOkYjBUDyT5qekVCqiu4LvPYRNUXwzccE/UMKZDLRJ6iRK84RUwnsjkvPtw65auh5L
 GJKve/+045fwCB8GFrmYAAAA=
To: Dafna Hirschfeld <dafna@fastmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: Nicolas Dufresne <nicolas.dufresne@collabora.com>, 
 Hans Verkuil <hverkuil@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 linux-media@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1497; i=iav@iav.lv;
 h=from:subject:message-id; bh=jIOYNEwnZtImPbbvWDWM3rNp8UHpADnjrlqR/x0YeIY=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkvzlorGesuDT/htuP9vsfeTXcsb6veX16Rckbs93YWB
 etfZReVOkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEIgoYGbruLmbNPF9mf728
 P7yRt8fjsK7pVedP5ca8/84EL5q76gLD/7qbqwve3p9/vZPr5dtJ2csqc0zvHO+qi8zZlHX2SLy
 hDTMA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

rkisp1_runtime_resume() enables the clocks and lets the interrupt
handlers run. Without CONFIG_PM it is never called, so rkisp1_probe()
reads RKISP1_CIF_VI_ID with the clocks disabled and every interrupt
handler returns IRQ_NONE.

ARCH_ROCKCHIP and arm64 ARCH_MXC select PM, and no arm32 i.MX has this
ISP, so only COMPILE_TEST builds lose the driver. rkcif already depends
on PM.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Split out of the rkvdec CONFIG_PM discussion, as Nicolas asked [1].
Without PM, olddefconfig on arm64 COMPILE_TEST now drops the driver;
with PM it builds as before (W=1).

[1] https://lore.kernel.org/r/8aafdbbf04a0d939c6b4d7d5577d97bb58d1c439.camel@collabora.com
---
 drivers/media/platform/rockchip/rkisp1/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/media/platform/rockchip/rkisp1/Kconfig b/drivers/media/platform/rockchip/rkisp1/Kconfig
index f53eb1f3f3e7..c825fbacee96 100644
--- a/drivers/media/platform/rockchip/rkisp1/Kconfig
+++ b/drivers/media/platform/rockchip/rkisp1/Kconfig
@@ -4,6 +4,7 @@ config VIDEO_ROCKCHIP_ISP1
 	depends on V4L_PLATFORM_DRIVERS
 	depends on VIDEO_DEV && OF
 	depends on ARCH_ROCKCHIP || ARCH_MXC || COMPILE_TEST
+	depends on PM
 	select MEDIA_CONTROLLER
 	select VIDEO_V4L2_SUBDEV_API
 	select VIDEOBUF2_DMA_CONTIG

---
base-commit: 27285b099fbc5cb2ae3aef20f3bbd7b3c88b3005
change-id: 20261102-rkisp1-depends-on-pm-219d94239b56

Best regards,
-- 
Igor Velkov <iav@iav.lv>

