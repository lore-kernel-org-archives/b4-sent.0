From: Andy Chung <Andy.Chung@amd.com>
Subject: [PATCH v3 0/4] hwmon: Add Kandou KB9002 PCIe retimer driver
Date: Tue, 21 Jul 2026 14:31:31 +0800
Message-Id: <20260721-kb9002-upstream-v3-0-70563922be8d@amd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEMSX2oC/2WNyw7CIBQFf6VhLQa4llJX/odxQXlYNH0EWqJp+
 u9CjdHE5SRn5iwoGO9MQMdiQd5EF9zQJ4BdgVQr+6vBTidGjDBOKgr43tSEMDyPYfJGdphwxQU
 3UAkAlKzRG+seW/F8eXOYm5tRU87kRevCNPjndhlp3n3qh796pJhgYTWzpKFQanGSnd6roUO5H
 dmvXf7bLNnMaqgJCNCy/Nrrur4A+2rD/PwAAAA=
X-Change-ID: 20260713-kb9002-upstream-06c686e37833
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andy Chung <andy.chung@amd.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784615506; l=2675;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=iLj5HgtenDHXi0SHFSIAeJJT74tSyCYXvam8/Z5ATYM=;
 b=PeGkpAI3vkm7UOrD7MxNaZSGzbfEdsTgGrgcQdxx5pERdJGnbHRJWI2aPReQwuf/45hQIEgxa
 pwpZL8ExVjIA5gNN2KmeG6JhkxAj7apwBPAaaJZOtEdj17InF04hzVV
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
Changes in v3:
- Drop the private register-access mutex. The temperature read is
  already serialised by the hwmon core lock; the debugfs files
  (fw_ver, fw_load_status) now take hwmon_lock() to serialise
  against it, since they are read outside the core lock.
- Use a named initialiser for the i2c_device_id entry.
- dt-bindings: constrain the reg address range under 'items' rather
  than applying minimum/maximum to the array.
- Link to v2: https://patch.msgid.link/20260715-kb9002-upstream-v2-0-2fd390383da5@amd.com

Changes in v2:
- Drop the unconditional I2C_FUNC_I2C requirement at probe; require raw
  I2C only in the host-interface switch path, so the driver loads on
  SMBus-only adapters when the chip is already strapped to SMBus.
- kb9002_read_revid(): return immediately on a hard I2C read error
  instead of retrying the FIFO drain, avoiding needless bus traffic when
  the device is absent.
- Link to v1: https://lore.kernel.org/all/20260714-kb9002-upstream-v1-0-8fd2f0b135d8@amd.com

---
Andy Chung (4):
      dt-bindings: Add vendor prefix for Kandou
      dt-bindings: hwmon: Add Kandou KB9002
      hwmon: (kb9002) Add driver for Kandou KB9002 retimer
      hwmon: (kb9002) Add documentation

 .../devicetree/bindings/hwmon/kandou,kb9002.yaml   |  46 ++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 Documentation/hwmon/index.rst                      |   1 +
 Documentation/hwmon/kb9002.rst                     |  65 +++
 MAINTAINERS                                        |   8 +
 drivers/hwmon/Kconfig                              |  11 +
 drivers/hwmon/Makefile                             |   1 +
 drivers/hwmon/kb9002.c                             | 469 +++++++++++++++++++++
 8 files changed, 603 insertions(+)
---
base-commit: ca078d004cf58137bcf8cb24a8b271397431ba58
change-id: 20260713-kb9002-upstream-06c686e37833

Best regards,
--  
Andy Chung <Andy.Chung@amd.com>

