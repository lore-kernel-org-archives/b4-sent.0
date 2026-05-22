From: Michael Riesch <michael.riesch@collabora.com>
Date: Fri, 22 May 2026 23:23:07 +0200
Subject: [PATCH v5 1/8] Documentation: admin-guide: media: add rk3588 vicap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260522-rk3588-vicap-v5-1-d1d1f5265c56@collabora.com>
References: <20260522-rk3588-vicap-v5-0-d1d1f5265c56@collabora.com>
In-Reply-To: <20260522-rk3588-vicap-v5-0-d1d1f5265c56@collabora.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779484994; l=4871;
 i=michael.riesch@collabora.com; s=20260428; h=from:subject:message-id;
 bh=eS5mY4EZ7XDsw0jrDI/5w4/ofpel/2YcT5yOuU60IhQ=;
 b=N2pUoKptdlhLJYmC0x8IoCAFVpqaQxisqzjMxTaylG4mLUSPTY9g/7vxBKCsU7O/mJhmivWMP
 L/ZBO6ZK1rzCL/vfsAo0XnwuGGFKQP1eas0CWXXE51tbx/xS05JvHDn
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=tAbmpPTE1MELYweXqqDU40fa18uCO6s32GJL/RzyW2Y=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20260428 with auth_id=759
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a section that describes the Rockchip RK3588 VICAP.

Reviewed-by: Mehdi Djait <mehdi.djait@linux.intel.com>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
 .../admin-guide/media/rkcif-rk3588-vicap.dot       | 29 ++++++++++++++++++++
 Documentation/admin-guide/media/rkcif.rst          | 32 ++++++++++++++++++++++
 2 files changed, 61 insertions(+)

diff --git a/Documentation/admin-guide/media/rkcif-rk3588-vicap.dot b/Documentation/admin-guide/media/rkcif-rk3588-vicap.dot
new file mode 100644
index 0000000000000000000000000000000000000000..f6d3404920b544f921987d3240f89987b340e138
--- /dev/null
+++ b/Documentation/admin-guide/media/rkcif-rk3588-vicap.dot
@@ -0,0 +1,29 @@
+digraph board {
+        rankdir=TB
+        n00000007 [label="{{<port0> 0} | rkcif-mipi2\n/dev/v4l-subdev0 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+        n00000007:port1 -> n0000000a
+        n00000007:port1 -> n00000010 [style=dashed]
+        n00000007:port1 -> n00000016 [style=dashed]
+        n00000007:port1 -> n0000001c [style=dashed]
+        n0000000a [label="rkcif-mipi2-id0\n/dev/video0", shape=box, style=filled, fillcolor=yellow]
+        n00000010 [label="rkcif-mipi2-id1\n/dev/video1", shape=box, style=filled, fillcolor=yellow]
+        n00000016 [label="rkcif-mipi2-id2\n/dev/video2", shape=box, style=filled, fillcolor=yellow]
+        n0000001c [label="rkcif-mipi2-id3\n/dev/video3", shape=box, style=filled, fillcolor=yellow]
+        n00000025 [label="{{<port0> 0} | rkcif-mipi4\n/dev/v4l-subdev1 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+        n00000025:port1 -> n00000028
+        n00000025:port1 -> n0000002e [style=dashed]
+        n00000025:port1 -> n00000034 [style=dashed]
+        n00000025:port1 -> n0000003a [style=dashed]
+        n00000028 [label="rkcif-mipi4-id0\n/dev/video4", shape=box, style=filled, fillcolor=yellow]
+        n0000002e [label="rkcif-mipi4-id1\n/dev/video5", shape=box, style=filled, fillcolor=yellow]
+        n00000034 [label="rkcif-mipi4-id2\n/dev/video6", shape=box, style=filled, fillcolor=yellow]
+        n0000003a [label="rkcif-mipi4-id3\n/dev/video7", shape=box, style=filled, fillcolor=yellow]
+        n00000043 [label="{{<port0> 0} | dw-mipi-csi2rx fdd30000.csi\n/dev/v4l-subdev2 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+        n00000043:port1 -> n00000007:port0
+        n00000048 [label="{{<port0> 0} | dw-mipi-csi2rx fdd50000.csi\n/dev/v4l-subdev3 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+        n00000048:port1 -> n00000025:port0
+        n0000004d [label="{{} | imx415 3-001a\n/dev/v4l-subdev4 | {<port0> 0}}", shape=Mrecord, style=filled, fillcolor=green]
+        n0000004d:port0 -> n00000043:port0
+        n00000051 [label="{{} | imx415 4-001a\n/dev/v4l-subdev5 | {<port0> 0}}", shape=Mrecord, style=filled, fillcolor=green]
+        n00000051:port0 -> n00000048:port0
+}
diff --git a/Documentation/admin-guide/media/rkcif.rst b/Documentation/admin-guide/media/rkcif.rst
index 2558c121abc466393b4a132e0d9abd2d37f2d25b..313a0ea45d16fe9bbb79d0798e8f8b1dbe1cb83f 100644
--- a/Documentation/admin-guide/media/rkcif.rst
+++ b/Documentation/admin-guide/media/rkcif.rst
@@ -77,3 +77,35 @@ and the following video devices:
 .. kernel-figure:: rkcif-rk3568-vicap.dot
     :alt:   Topology of the RK3568 Video Capture (VICAP) unit
     :align: center
+
+Rockchip RK3588 Video Capture (VICAP)
+-------------------------------------
+
+The RK3588 Video Capture (VICAP) unit features a digital video port and six
+MIPI CSI-2 capture interfaces that can receive video data independently.
+The DVP accepts parallel video data, BT.656 and BT.1120.
+Since the BT.1120 protocol may feature more than one stream, the RK3588 VICAP
+DVP features four DMA engines that can capture different streams.
+Similarly, the RK3588 VICAP MIPI CSI-2 receivers feature four DMA engines each
+to handle different Virtual Channels (VCs).
+
+The rkcif driver represents this hardware variant by exposing the following
+V4L2 subdevices:
+
+* dw-mipi-csi2rx fdd30000.csi: MIPI CSI-2 receiver connected to MIPI DPHY0
+* dw-mipi-csi2rx fdd50000.csi: MIPI CSI-2 receiver connected to MIPI DPHY1
+* rkcif-mipi2: INTERFACE/CROP block for the MIPI CSI-2 receiver connected to
+  MIPI DPHY0
+* rkcif-mipi4: INTERFACE/CROP block for the MIPI CSI-2 receiver connected to
+  MIPI DPHY1
+
+and the following video devices:
+
+* rkcif-mipi2-id{0,1,2,3}: The DMA engines connected to the rkcif-mipi2
+  INTERFACE/CROP block.
+* rkcif-mipi4-id{0,1,2,3}: The DMA engines connected to the rkcif-mipi4
+  INTERFACE/CROP block.
+
+.. kernel-figure:: rkcif-rk3588-vicap.dot
+    :alt:   Topology of the RK3588 Video Capture (VICAP) unit
+    :align: center

-- 
2.47.3

