From: Richard Leitner <richard.leitner@linux.dev>
Subject: [PATCH 0/3] Add Vision Components MIPI Camera Module support
Date: Tue, 15 Sep 2026 22:20:22 +0200
Message-Id: <20260915-vc-mipi-ctrl-v1-0-8a42b693d889@linux.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrE1S1Ui4ilgwBiP+0pZIxN0Vy
 2/x3gWOrbCDIrrA8iFO1iUgiSOgoV56RmmDQSudqVyleBDOsgmStxNmrTGauCMyCkKyWe7k/HZ
 l9dvtzcjk3wfc9wP7JxdScAAAAA==
X-Change-ID: 20260903-vc-mipi-ctrl-6d442cefcc40
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>
Cc: Alexander Stein <alexander.stein@ew.tq-group.com>, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, Richard Leitner <richard.leitner@linux.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789503653; l=2059;
 i=richard.leitner@linux.dev; s=20250225; h=from:subject:message-id;
 bh=ZEQ3J4FqxnkpYsTzOtwn2mqHYYGvQR0TAxGTCP4Bj0Q=;
 b=xuekxFxW6sSoMFjNUpYSX4OEcsRNM1xs3u3YsE37zqH+GLe4pa9+Ym99UgNx+/HSXGn/OWjdq
 LHFDTiXYaERD6qmelw838XYCWw0ZwK2GJk3e7ZovoROtS+xjshaAyOn
X-Developer-Key: i=richard.leitner@linux.dev; a=ed25519;
 pk=8hZNyyyQFqZ5ruVJsSGBSPIrmJpfDm5HwHU4QVOP1Pk=
X-Endpoint-Received: by B4 Relay for richard.leitner@linux.dev/20250225 with auth_id=350
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for Vision Components MIPI camera modules by
adding a device driver for the controller chip found on those modules.

The controller is an I2C-accessible FPGA that provides three main
functions for the attached image sensor:

 - power sequencing and control of the module supply
 - a fixed clock output used as the sensor input clock
 - routing of I2C traffic between the host and the sensor

The initial version of this driver was written by Laurent Pinchart and
is available at: gitlab.com/ideasonboard/nxp/linux.git in the
v7.0/sensors/vcmipi branch. Therefore I've added Laurent and me as a
maintainer for this driver and left Laurent as MODULE_AUTHOR. If that's
incorrect or not desired, please feel free to reach out! Thanks

This series was tested using ov9282 camera modules from Vision
Components. Those were flashed with different FPGA firmware versions and
connected to an i.MX8MP SoC.

Any feedback is warmly welcome.

Thanks!

Link: https://lore.kernel.org/all/20260728092856.GB1494774@killaraus.ideasonboard.com/
Link: https://gitlab.com/ideasonboard/nxp/linux/-/commits/v7.0/sensors/vcmipi
Signed-off-by: Richard Leitner <richard.leitner@linux.dev>
---
Richard Leitner (3):
      dt-bindings: vendor-prefixes: add Vision Components GmbH
      dt-bindings: media: i2c: Add vision-components,mipi-module-controller
      media: i2c: vc-mipi: add Vision Components MIPI Module Controller

 .../vision-components,mipi-module-controller.yaml  |  92 ++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 MAINTAINERS                                        |   8 +
 drivers/media/i2c/Kconfig                          |  13 +
 drivers/media/i2c/Makefile                         |   1 +
 drivers/media/i2c/vc-mipi.c                        | 541 +++++++++++++++++++++
 6 files changed, 657 insertions(+)
---
base-commit: fd73f4a6659897191fa0d40695fe370925dd3780
change-id: 20260903-vc-mipi-ctrl-6d442cefcc40

Best regards,
--  
Richard Leitner <richard.leitner@linux.dev>

