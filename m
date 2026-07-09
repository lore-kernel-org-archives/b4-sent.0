From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH RFC v3 0/7] mfd: ls2kbmc: multiple fixes for this driver
Date: Fri, 10 Jul 2026 01:24:16 +0800
Message-Id: <20260710-ls2kbmc-mod-v3-0-ef718636e78e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAEDZT2oC/32NywrCMBREf0Xu2khy06bWlSD4AW7FRZpHG2waS
 aQopf9uyEo3LmeGc2aBZKIzCQ6bBaKZXXJhyoFvN6AGOfWGOJ0zIEVBBQoyJrx3XhEfNKmRtqz
 llLYdQiYe0Vj3KrYrXM4nuOVycOkZ4rs8zKxMRdbQ/Y9sZoQSxauqs7U2VvJj76Ubdyr44pnxD
 4uZRWm1Zk3FGiG+2XVdPzlMtBnnAAAA
X-Change-ID: 20260626-ls2kbmc-mod-5209193009b2
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3331;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=sukWlxC8McdyMqbXOPPFAxKItWB1p7RLYeJjYFSvLwg=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqT9lKe2UhEAclLxvizAebe3Mw+jE5JzpCIBFl1
 do84oJt6RmJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak/ZSgAKCRCwMePKe/7Z
 boFoD/4zNd1tNOwcPbcH8RsMUhxL3Z/D3tQHNXN8Vh/sMxjtT8QVk1W9incgMg0CxrFUW9q09XQ
 lzHakKOaZQ0vKGFcfiU3zKYl1WBTNkSTvKiyrpIa0bFUYAx5T2QcngzDxvLUR0pbMCw0SIdcPEp
 dy4ws/UYwgiFLca3LsybyE8wOcEDPARul3qPQrwWZEGapgw+FQbsU2o6tXN9lb9+9egv+6KMjxO
 2RnOp7av1CLIyONHVBEs7cxxw5DzO/suYSZ5Uu0adPiIRsNA7t5pH9A4EvniLC7+VMzMMdS8bcX
 96wSMZOdZIInmBop0j4sV8SVW27Q0vfpULsBiB5NTVG2ROiG8AjdV9aIcS5kiVJVD3OynUpigTe
 dixWQU8RaCwd43mqkjvqILJpMTkp8UwJoaERKiWcPcmt4OeNj8Om1yb/7Sr+AC4Bvomz8rvMhzh
 XLuTmtCmmLPzxxITNU4hDKaBCWbgmUd06rQovgmqq5PrgeeA8vaGd//4c2kUhyj2WZtHEHSQt2s
 0UZaCIwTduI0cWKXH+wJ5m0vCqVMaPQFR9taDkLW9lqkFehFOytNLqSCKTIvo9yevBpy7UBJSkz
 /5/AxUOebWjB2ab8LGq3LabHltqwwa/mRVHbHeXBLUonpdd/G86EBFWBk5isoi1rciOOf6EdfOB
 aIHX8caxYgUcSbA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Previously, the driver has been introduced to support the Loongson 2K
BMC running on the Loongson Servers, which is essential to prevent
the system from hanging when the BMC is being reset and the default
efi-framebuffer is being used. However, there are some drawbacks in the
driver.

Firstly, the driver tries to read and write to the connected PCI-E host
controller registers, assuming that the BMC is connected to LS7A PCI-E
host controller. This assumption should be true for real products, but
to prevent from accidentally reading and writing to the wrong PCI-E host
controller, this driver should be modified to check this before
accessing the registers.

Secondly, the driver uses non-exported functions to tell the vt
subsystem to redraw the screen, preventing the driver from being
compiling as a module. This can be fixed by using the exported
functions instead.

Thirdly, the driver directly accesses the GPIO controller registers
using hard-coded addresses, which might conflict with the loaded GPIO
controller driver for the same GPIO controller. This is fixed in this
series by using the GPIO subsystem APIs instead. However, legacy GPIO
APIs have to be used in this fixed to correctly request a GPIO
descriptor from the GPIO subsystem, which might be further discussed
to find a better solution.

Finally, there is a minor issue in the driver where it changes the
mode string describing the screen resolution during probing, which
prevents the device from being probed again if -EPROBE_DEFER is
returned by the probe function.

I have tested the changes in this series on a single-socket Loongson
3C6000 server with a Loongson 2K BMC, and the driver works as expected
when the corresponding GPIO driver is additionally loaded.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v3:
- Check the return value of devm_add_action_or_reset when registering
  the cleanup hook of the work queue
- Use swnode to create the link between the device to the GPIO chip,
  and prevent borrowing the legacy GPIO APIs
- Link to v2: https://lore.kernel.org/r/20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com

Changes in v2:
- Several fixes suggested by the Sashiko AI review bot
- Add a cleanup function for the wq on removal of the device
- Relax the reverse dependency from CONFIG_IPMI_LS2K to
  CONFIG_MFD_LS2K_BMC_CORE to allow the driver to be built as a module
- Link to v1: https://lore.kernel.org/r/20260708-ls2kbmc-mod-v1-0-c344bf5defa3@gmail.com

---
Miao Wang (7):
      mfd: ls2kbmc: Make a copy when parsing mode string
      mfd: ls2kbmc: Sanity check for the connected pci port
      mfd: ls2kbmc: Redraw using exported functions
      mfd: ls2kbmc: Cancel the work queue on removal
      ipmi: ls2k: Relax the dependency to its mfd driver
      mfd: ls2kbmc: Able to be compiled as a module
      mfd: ls2kbmc: Capture the reset event of BMC through GPIO

 drivers/char/ipmi/Kconfig   |   2 +-
 drivers/mfd/Kconfig         |   2 +-
 drivers/mfd/ls2k-bmc-core.c | 235 ++++++++++++++++++++++++++++++++++----------
 3 files changed, 184 insertions(+), 55 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260626-ls2kbmc-mod-5209193009b2

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

