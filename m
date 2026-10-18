From: George Neacsu <geocausa@gmail.com>
Subject: [PATCH v2 0/2] media: ov13858: device tree support for the Surface
 Pro 11 (Snapdragon)
Date: Sun, 18 Oct 2026 22:10:20 +0100
Message-Id: <20261018-ov13858-x1e-v2-0-cd35434cfcfe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23OTW7DIBCG4atYrEvFDAbGXvUeVRb8DDFSHafGt
 VJFuXtxsu3yG2kevXdReS1cxdjdxcp7qWW5tIFvnYiTv5xZltS2QIUWFBi57KDJkLwBS6IcUiD
 qM6FoH9eVc7k9tc9T21Op27L+PvEdjuv/zg5SSR9TGoByn4P9OM++fL3HZRanxwte+fun1W0vX
 Vz9FqfWNnax98FFBQmZYWCbko2AGYEHw8oadJ4jaj4Cg68smzqXbeySYxeid2AHcjr0lsk0CE0
 ElbXWB2MoUUt4/AERhAU3KAEAAA==
X-Change-ID: 20261015-ov13858-x1e-88fbdb884f82
To: Sakari Ailus <sakari.ailus@linux.intel.com>
Cc: Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Sergey Lebedev <lsa.uz@pm.me>, 
 German Pablo Lindo <germanpapulindez@gmail.com>, 
 Bryan O'Donoghue <bod@kernel.org>, linux-media@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, George Neacsu <geocausa@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792357821; l=2545;
 i=geocausa@gmail.com; s=20261015; h=from:subject:message-id;
 bh=bS/6/i6Fqjy0XUY7goCfpZnpjhJR3lPocnmskSL3GX4=;
 b=rDqpoMN+J33AG8ak1CbPrKpqfBHtykw9PbGFurFmqhyZYHn/qtZXGfZFv170VjJX43IwSp/mj
 YcupXwAb/ZsDj/wPUjJB6Zsfdrxutj25jCOx0yPmhDLzfZtUdzFWz7Y
X-Developer-Key: i=geocausa@gmail.com; a=ed25519;
 pk=KyQk/iWbxsikewDBh0SwlHI51RvAqahD3loqmRp9DVI=
X-Endpoint-Received: by B4 Relay for geocausa@gmail.com/20261015 with auth_id=1199
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi Sakari,

The Surface Pro 11 with a Snapdragon X Elite (X1E80100) has an OV13858
rear camera on Qualcomm CAMSS over four D-PHY lanes. This two-patch
series adds the DT binding and the OF/endpoint support for the existing
sensor driver.

v2 keeps Sergey's power-management work as a prerequisite, updated to
his v4:
<20261016210246.58562-1-lsa.uz@pm.me>

On the Snapdragon model, the v4 runtime-PM callbacks are equivalent to
the v3 callbacks used for the hardware test. I ran 20 open/stream/close
cycles on the rear sensor; it runtime-suspended between every cycle and
streamed again each time. Three additional cycles saved complete
4224x3136 RAW10 frames. The camera rails were enabled while streaming
and disabled between sessions.

System suspend has not yet been tested on the Snapdragon model.
Suspend/resume support for this platform is currently being brought up
separately, and I plan to include the camera in that testing once it is
ready. This series therefore makes no suspend/resume claim.

Sergey tested the DT patches on the Intel Surface Pro 11: the endpoint
check passes, 4224x3136 streams at 29.95 fps, and v4l2-compliance passes
46/46 on the subdev. His Tested-by is carried on both patches.

Thanks to Sakari, Krzysztof and Bryan for the review and guidance.
Krzysztof's Reviewed-by is carried on the binding, and Sakari's latest
review feedback is folded into v2.

Changes in v2:
- update the prerequisite from Sergey's v3 to v4;
- carry Sergey's Tested-by on both patches;
- remove the fixed 19.2 MHz claim from the binding description;
- let v4l2_fwnode_endpoint_alloc_parse() handle missing-endpoint deferral;
- trim the driver commit message to the implementation change;
- document the Snapdragon runtime-PM cycle results.

Link to v1:
https://lore.kernel.org/r/20261015-ov13858-x1e-v1-0-acdd918f4fb6@gmail.com

Signed-off-by: George Neacsu <geocausa@gmail.com>
---
George Neacsu (2):
      dt-bindings: media: i2c: Add OmniVision OV13858
      media: i2c: ov13858: Add device tree support

 .../bindings/media/i2c/ovti,ov13858.yaml           | 113 +++++++++++++++++++++
 MAINTAINERS                                        |   1 +
 drivers/media/i2c/ov13858.c                        |  54 ++++++++++
 3 files changed, 168 insertions(+)
---
base-commit: d7e7bca7169873b46e857c025c10f3336c1258d8
change-id: 20261015-ov13858-x1e-88fbdb884f82
prerequisite-patch-id: c4ab7c01d2ee19e6dd6c12f21e95e06527aec23e

Best regards,
-- 
George Neacsu <geocausa@gmail.com>

