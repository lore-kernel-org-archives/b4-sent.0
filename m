From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v3 0/9] media: rockchip: rkcif: add support for rk3588
 vicap
Date: Wed, 25 Mar 2026 12:51:05 +0100
Message-Id: <20250430-rk3588-vicap-v3-0-e38e428868cc@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIACnMw2kC/33Py2rDMBAF0F8xWldBT1vyKv8RutBjVIumkSOlo
 iH436vYhJRSurwDc+7MDRXIEQoauxvKUGOJ6dQCf+mQm8zpDXD0LSNGmCSCE5zfuVQK1+jMjLW
 nvXBKMmUG1FbmDCF+rdzhdcsZzp9NvWzDJzp2jRSEsY3sH6TVlgetmQxCjFWhn4esO5L0tH+c4
 UrEfp6u2GnwzHjhvA5jpejePsVySfm6/tZG9/q/36gUE2y59T4MQmsq9i4dj8ambHYufaxYZf8
 BrAHD4EECaCIU/AaWZfkGYXCQwWsBAAA=
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
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774439467; l=4230;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=vbZLOt7EIgfb8wzXcMEkH5OJviNmVkjkd3ow5gAmiUc=;
 b=J2s0+HJP6GwhPiHb/6T3kiNxUwA7owRv7p6n2lIShYxe0OZPdqFw3RozfsnzKdXDUJO3dri3o
 B0CPaB36R0AA5amYbV4IbZj/fAVxzt+6utvdrDvgV06SEbg6T+AIH2v
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

The RK3588 Video Capture (VICAP) constitutes an essential piece of the
RK3588 camera interface with one DVP, six MIPI CSI-2 receivers,
scale/crop units, and a data path multiplexer (to scaler units, to ISP,
...). This series introduces basic support for the RK3588 VICAP unit
to the rkcif driver, thus paving the way for video capture in general
and for camera sensor image processing in particular.

The changes have been tested successfully on a Radxa ROCK 5B+ with two
Radxa 4K cameras attached to it. The raw images from the sensors can
be streamed after configuring the hardware pipeline with

media-ctl -d 0 --set-v4l2 '"dw-mipi-csi2rx fdd30000.csi":0 \
  [fmt:SGBRG10_1X10/3864x2192 field:none colorspace:raw xfer:none]'
media-ctl -d 0 --set-v4l2 '"rkcif-mipi2":0 \
  [fmt:SGBRG10_1X10/3864x2192 field:none colorspace:raw xfer:none]'
media-ctl -d 0 --set-v4l2 '"dw-mipi-csi2rx fdd50000.csi":0 \
  [fmt:SGBRG10_1X10/3864x2192 field:none colorspace:raw xfer:none]'
media-ctl -d 0 --set-v4l2 '"rkcif-mipi4":0 \ 
  [fmt:SGBRG10_1X10/3864x2192 field:none colorspace:raw xfer:none]'

and using e.g., GStreamer

gst-launch-1.0 v4l2src \
  device=/dev/v4l/by-path/platform-fdce0000.video-capture-video-index0 \
  ! video/x-bayer,format=gbrg10le,width=3864,height=2192 ! bayer2rgb \
  ! ...
(or -index4 for the other camera sensor).

Note that this series requires the RK3588 MIPI CSI-2 receiver patches
[0]. I included them here to provide the possibility to test the changes
without any nasty merge conflicts.

Looking forward to your comments!

[0] https://lore.kernel.org/all/20260305-rk3588-csi2rx-v2-0-79d01b615486@collabora.com

Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Changes in v3:
- fixed copy-paste mistake "RK3568" -> "RK3588" in docs (Charalampos)
- fixed reg properties of ports in dtsi (port@10 <=> <16>, ...)
- added comment w.r.t. RKCIF_MIPI_CTRL_CAP_EN bit (Mehdi)
- removed redundant minItems and maxItems from dt-binding (Conor)
- revised device tree overlays for the Radxa CAMs according to the
  schematics that I recently received
- Link to v2: https://lore.kernel.org/r/20250430-rk3588-vicap-v2-0-77de5ee9048e@collabora.com

Changes in v2:
- modified rockchip,rk3568-vicap binding instead of creating a new one
  (Conor)
- aligned clock names and reset names with rockchip,rk3568-vicap
- Link to v1: https://lore.kernel.org/r/20250430-rk3588-vicap-v1-0-b3bddf749914@collabora.com

---
Michael Riesch (9):
      Documentation: admin-guide: media: add rk3588 vicap
      media: dt-bindings: add rockchip rk3588 vicap
      media: rockchip: rkcif: add support for rk3588 vicap mipi capture
      [DONOTMERGE] media: dt-bindings: rockchip,rk3568-mipi-csi2: add rk3588 compatible
      [DONOTMERGE] arm64: dts: rockchip: add mipi csi-2 receiver nodes to rk3588
      arm64: dts: rockchip: add vicap node to rk3588
      arm64: dts: rockchip: add radxa camera 4k on rock 5b+ cam0
      arm64: dts: rockchip: add radxa camera 4k on rock 5b+ cam1
      arm64: defconfig: enable designware mipi csi-2 receiver

 .../admin-guide/media/rkcif-rk3588-vicap.dot       |  29 ++++
 Documentation/admin-guide/media/rkcif.rst          |  32 ++++
 .../bindings/media/rockchip,rk3568-mipi-csi2.yaml  |   8 +-
 .../bindings/media/rockchip,rk3568-vicap.yaml      | 187 ++++++++++++++++++---
 arch/arm64/boot/dts/rockchip/Makefile              |   7 +
 arch/arm64/boot/dts/rockchip/rk3588-base.dtsi      | 143 ++++++++++++++++
 .../rk3588-rock-5b-plus-radxa-cam4k-cam0.dtso      |  99 +++++++++++
 .../rk3588-rock-5b-plus-radxa-cam4k-cam1.dtso      |  99 +++++++++++
 arch/arm64/configs/defconfig                       |   1 +
 .../platform/rockchip/rkcif/rkcif-capture-mipi.c   | 141 ++++++++++++++++
 .../platform/rockchip/rkcif/rkcif-capture-mipi.h   |   1 +
 .../media/platform/rockchip/rkcif/rkcif-common.h   |   2 +-
 drivers/media/platform/rockchip/rkcif/rkcif-dev.c  |  18 ++
 13 files changed, 740 insertions(+), 27 deletions(-)
---
base-commit: 882ac913e67d2462a18bdc2958b496c0f51d1647
change-id: 20250430-rk3588-vicap-9d164c8528a7

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

