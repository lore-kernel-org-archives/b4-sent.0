From: Keke Li <keke.li@amlogic.com>
Date: Thu, 05 Dec 2024 17:04:36 +0800
Subject: [PATCH v4 10/10] Documentation: media: add documentation file
 c3-isp.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241205-c3isp-v4-10-cb1868be0105@amlogic.com>
References: <20241205-c3isp-v4-0-cb1868be0105@amlogic.com>
In-Reply-To: <20241205-c3isp-v4-0-cb1868be0105@amlogic.com>
To: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-media@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kieran.bingham@ideasonboard.com, 
 laurent.pinchart@ideasonboard.com, dan.scally@ideasonboard.com, 
 Keke Li <keke.li@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1733389471; l=8378;
 i=keke.li@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=H0RQU9asCesFOIT5c2J2aVn6KNIPpH4ysETliTY0WyI=;
 b=9+7KmOWDIz0lXYMVcfKr1pFFgjv7tYe6gW9Vqs6mNvZiKbrVJRfm4V6N7FN7trr+C5BGwbGb4
 v5ezg1+1MBRBWnA4RgB8gVKUmx62D52Z3UYijikbOOv4Ei+8+0+Wy+x
X-Developer-Key: i=keke.li@amlogic.com; a=ed25519;
 pk=XxNPTsQ0YqMJLLekV456eoKV5gbSlxnViB1k1DhfRmU=
X-Endpoint-Received: by B4 Relay for keke.li@amlogic.com/20240902 with auth_id=204
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the file 'c3-isp.rst' that documents the c3-isp driver.

Signed-off-by: Keke Li <keke.li@amlogic.com>
---
 Documentation/admin-guide/media/c3-isp.dot      |  26 ++++++
 Documentation/admin-guide/media/c3-isp.rst      | 109 ++++++++++++++++++++++++
 Documentation/admin-guide/media/v4l-drivers.rst |   1 +
 MAINTAINERS                                     |  11 +++
 4 files changed, 147 insertions(+)

diff --git a/Documentation/admin-guide/media/c3-isp.dot b/Documentation/admin-guide/media/c3-isp.dot
new file mode 100644
index 000000000000..f96217dbcebf
--- /dev/null
+++ b/Documentation/admin-guide/media/c3-isp.dot
@@ -0,0 +1,26 @@
+digraph board {
+	rankdir=TB
+	n00000001 [label="{{<port0> 0 | <port1> 1} | c3-isp-core\n/dev/v4l-subdev0 | {<port2> 2 | <port3> 3}}", shape=Mrecord, style=filled, fillcolor=green]
+	n00000001:port3 -> n00000006:port0
+	n00000001:port3 -> n00000009:port0
+	n00000001:port3 -> n0000000c:port0
+	n00000001:port2 -> n00000025
+	n00000006 [label="{{<port0> 0} | c3-isp-resizer0\n/dev/v4l-subdev1 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+	n00000006:port1 -> n00000019 [style=bold]
+	n00000009 [label="{{<port0> 0} | c3-isp-resizer1\n/dev/v4l-subdev2 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+	n00000009:port1 -> n0000001d [style=bold]
+	n0000000c [label="{{<port0> 0} | c3-isp-resizer2\n/dev/v4l-subdev3 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+	n0000000c:port1 -> n00000021 [style=bold]
+	n0000000f [label="{{<port0> 0} | c3-mipi-adapter\n/dev/v4l-subdev4 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+	n0000000f:port1 -> n00000001:port0 [style=bold]
+	n00000014 [label="{{<port0> 0} | c3-mipi-csi2\n/dev/v4l-subdev5 | {<port1> 1}}", shape=Mrecord, style=filled, fillcolor=green]
+	n00000014:port1 -> n0000000f:port0 [style=bold]
+	n00000019 [label="c3-isp-cap0\n/dev/video0", shape=box, style=filled, fillcolor=yellow]
+	n0000001d [label="c3-isp-cap1\n/dev/video1", shape=box, style=filled, fillcolor=yellow]
+	n00000021 [label="c3-isp-cap2\n/dev/video2", shape=box, style=filled, fillcolor=yellow]
+	n00000025 [label="c3-isp-stats\n/dev/video3", shape=box, style=filled, fillcolor=yellow]
+	n00000029 [label="c3-isp-params\n/dev/video4", shape=box, style=filled, fillcolor=yellow]
+	n00000029 -> n00000001:port1
+	n0000003d [label="{{} | imx290 2-001a\n/dev/v4l-subdev6 | {<port0> 0}}", shape=Mrecord, style=filled, fillcolor=green]
+	n0000003d:port0 -> n00000014:port0 [style=bold]
+}
diff --git a/Documentation/admin-guide/media/c3-isp.rst b/Documentation/admin-guide/media/c3-isp.rst
new file mode 100644
index 000000000000..8adac4605a6a
--- /dev/null
+++ b/Documentation/admin-guide/media/c3-isp.rst
@@ -0,0 +1,109 @@
+.. SPDX-License-Identifier: (GPL-2.0-only OR MIT)
+
+.. include:: <isonum.txt>
+
+=================================================
+Amlogic C3 Image Signal Processing (C3ISP) driver
+=================================================
+
+Introduction
+============
+
+This file documents the Amlogic C3ISP driver located under
+drivers/media/platform/amlogic/c3/isp.
+
+The current version of the driver supports the C3ISP found on
+Amlogic C308L processor.
+
+The driver implements V4L2, Media controller and V4L2 subdev interfaces.
+Camera sensor using V4L2 subdev interface in the kernel is supported.
+
+The driver has been tested on AW419-C308L-Socket platform.
+
+Anlogic Camera hardware
+=======================
+
+The Camera hardware found on C308L processors and supported by
+the driver consists of:
+
+- 1 MIPI-CSI2 module. It handle the Physical layer of the CSI2 receivers and
+  receive MIPI data.
+  A separate camera sensor can be connected to MIPI-CSi2 module.
+- 1 MIPI-ADAPTER module. Organize MIPI data to meet ISP input requirements and
+  send MIPI data to ISP
+- 1 ISP (Image Signal Processing) module. Contain a pipeline of image processing
+  hardware blocks.
+  The ISP pipeline contains three scalers at the end.
+  The ISP also contains the DMA interface which writes the output data to memory.
+
+A high level functional view of the C3 ISP is presented below. The ISP
+takes input from the sensor.::
+
+                                                                   +---------+    +-------+
+                                                                   | Scaler  |--->| WRMIF |
+  +---------+    +------------+    +--------------+    +-------+   |---------+    +-------+
+  | Sensor  |--->| MIPI CSI-2 |--->| MIPI ADAPTER |--->|  ISP  |---|---------+    +-------+
+  +---------+    +------------+    +--------------+    +-------+   | Scaler  |--->| WRMIF |
+                                                                   +---------+    +-------+
+                                                                   |---------+    +-------+
+                                                                   | Scaler  |--->| WRMIF |
+                                                                   +---------+    +-------+
+
+Supported functionality
+=======================
+
+The current version of the driver supports:
+
+- Input from camera sensor via MIPI-CSI2;
+
+- Pixel output interface of ISP
+
+  - Scaling support. Configuration of the scaler module
+    for downscalling with ratio up to 8x.
+
+Driver Architecture and Design
+==============================
+
+The driver implements the V4L2 subdev interface. With the goal to model the
+hardware links between the modules and to expose a clean, logical and usable
+interface, the driver is split into V4L2 sub-devices as follows:
+
+- 1 c3-mipi-csi2 sub-device - mipi-csi2 is represented by a single sub-device.
+- 1 c3-mipi-adapter sub-device - mipi-adapter is represented by a single sub-devices.
+- 1 c3-isp-core sub-device - isp-core is represented by a single sub-devices.
+- 3 c3-isp-resizer sub-devices - isp-resizer is represented by a number of sub-devices
+  equal to the number of capture device.
+
+c3-isp-core sub-device is linked to 2 separate video device nodes and
+3 c3-isp-resizer sub-devices nodes.
+
+- 1 capture statistics video device node.
+- 1 output parameters video device node.
+- 3 c3-isp-resizer sub-device nodes.
+
+c3-isp-resizer sub-device is linked to capture video device node.
+
+- c3-isp-resizer0 is linked to c3-isp-cap0
+- c3-isp-resizer1 is linked to c3-isp-cap1
+- c3-isp-resizer2 is linked to c3-isp-cap2
+
+The media controller pipeline graph is as follows (with connected a
+IMX290 camera sensor):
+
+.. _isp_topology_graph:
+
+.. kernel-figure:: c3-isp.dot
+    :alt:   c3-isp.dot
+    :align: center
+
+    Media pipeline topology
+
+Implementation
+==============
+
+Runtime configuration of the hardware via 'c3-isp-params' video device node.
+Acquiring statistics of ISP hardware via 'c3-isp-stats' video device node.
+Acquiring output image of ISP hardware via 'c3-isp-cap[0, 2]' video device node.
+
+The output size of the scaler module in the ISP is configured with
+the pixel format of 'c3-isp-cap[0, 2]' video device node.
diff --git a/Documentation/admin-guide/media/v4l-drivers.rst b/Documentation/admin-guide/media/v4l-drivers.rst
index e8761561b2fe..3bac5165b134 100644
--- a/Documentation/admin-guide/media/v4l-drivers.rst
+++ b/Documentation/admin-guide/media/v4l-drivers.rst
@@ -10,6 +10,7 @@ Video4Linux (V4L) driver-specific documentation
 	:maxdepth: 2
 
 	bttv
+	c3-isp
 	cafe_ccic
 	cx88
 	fimc
diff --git a/MAINTAINERS b/MAINTAINERS
index 0136101bef0d..ffd2c6ae827f 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1224,6 +1224,17 @@ F:	Documentation/devicetree/bindings/perf/amlogic,g12-ddr-pmu.yaml
 F:	drivers/perf/amlogic/
 F:	include/soc/amlogic/
 
+AMLOGIC ISP DRIVER
+M:	Keke Li <keke.li@amlogic.com>
+L:	linux-media@vger.kernel.org
+S:	Maintained
+F:	Documentation/admin-guide/media/c3-isp.dot
+F:	Documentation/admin-guide/media/c3-isp.rst
+F:	Documentation/devicetree/bindings/media/amlogic,c3-isp.yaml
+F:	Documentation/userspace-api/media/v4l/metafmt-c3-isp.rst
+F:	drivers/media/platform/amlogic/c3/isp/
+F:	include/uapi/linux/media/amlogic/
+
 AMLOGIC MIPI ADAPTER DRIVER
 M:	Keke Li <keke.li@amlogic.com>
 L:	linux-media@vger.kernel.org

-- 
2.47.0

