From: Andy Chung <Andy.Chung@amd.com>
Subject: [PATCH 0/4] hwmon: Add Kandou KB9002 PCIe retimer driver
Date: Tue, 14 Jul 2026 16:19:31 +0800
Message-Id: <20260714-kb9002-upstream-v1-0-8fd2f0b135d8@amd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABPxVWoC/yXMTQqEMAxA4atI1hZiC9XxKuKi1oxmxB8aFUG8u
 9VZfov3ThAKTAJlckKgnYXnKSJLE/C9mzpS3EaDRm0xz4wamg+iVtsiayA3KrTeFpZMXhgDsVo
 Cffl4j1X9t2zNj/z6bOC6btc+znpzAAAA
X-Change-ID: 20260713-kb9002-upstream-06c686e37833
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Chung <andy.chung@amd.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784017234; l=1648;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=YRQiObYZV7j4K+B9X4FSjAje/rXs+OimtUFNe3Mc5DU=;
 b=JKeIf8l4EpvoK7p0e3AeHEUfiK61el0DEgPKJanCxa3HUQ4wvp2Ik8CYyxiuiYxGC+KMAYZD/
 iPn5stRt2DABJQdy8BTswG1gdHXRocWel+YJXvZ5m88hXiNqPcFuMSf
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Kandou KB9002 is an 8-lane PCIe 5.0 retimer with an integrated
microcontroller that exposes an SMBus 3.0 target (with mandatory PEC)
on its sideband interface. Its firmware aggregates per-lane die
temperatures and publishes the maximum through a register window.

This series adds a hwmon driver for it. The driver reports the
aggregated maximum die temperature as temp1_input, and exposes the
running firmware version and boot status under debugfs.

The series is organised as:

  1/4  add the "kandou" vendor prefix
  2/4  device tree binding for the retimer
  3/4  the driver, Kconfig/Makefile and MAINTAINERS entry
  4/4  hwmon documentation

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
Andy Chung (4):
      dt-bindings: Add vendor prefix for Kandou
      dt-bindings: hwmon: Add Kandou KB9002
      hwmon: (kb9002) Add driver for Kandou KB9002 retimer
      hwmon: (kb9002) Add documentation

 .../devicetree/bindings/hwmon/kandou,kb9002.yaml   |  45 ++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 Documentation/hwmon/index.rst                      |   1 +
 Documentation/hwmon/kb9002.rst                     |  65 +++
 MAINTAINERS                                        |   8 +
 drivers/hwmon/Kconfig                              |  11 +
 drivers/hwmon/Makefile                             |   1 +
 drivers/hwmon/kb9002.c                             | 473 +++++++++++++++++++++
 8 files changed, 606 insertions(+)
---
base-commit: ca078d004cf58137bcf8cb24a8b271397431ba58
change-id: 20260713-kb9002-upstream-06c686e37833

Best regards,
--  
Andy Chung <Andy.Chung@amd.com>

