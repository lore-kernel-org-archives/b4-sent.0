From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH RFC v5 0/7] mfd: ls2kbmc: multiple fixes for this driver
Date: Tue, 04 Aug 2026 00:55:48 +0800
Message-Id: <20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABTIcGoC/33NsY7CMAyA4VdBmcnJdtKkvQkJiQdgPd2QNg5ER
 ylqUAVCffeLMrUMjLb1/X6JxGPkJL43LzHyFFMcrnmothvRnd31xDL6PAsCMmDIyEuiv7bvZD9
 4WRE02CiApiWRxW3kEB+l9iOOh734zctzTPdhfJYPE5ZTiVmoV7EJJchOad2GynNwanfqXbx8d
 UNfOhN9sJQtueA9Wo3WmHerFhZhbVW2HCzWRhm2Nb9bvbAK11Zn6wmwAmodqWZp53n+B6W0kex
 fAQAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=4070;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=00R75UySHqyvWDXRIcvJrzFhhNQlK+S8CJZvS9Em2ag=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqcMhBYc2vOUvOY/wHPTljdj2Ftxko+pcQLIy6H
 CcaU4QBqL6JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCanDIQQAKCRCwMePKe/7Z
 bsXYD/9tG2QyBpwmX4FQAK664+oOveFBZxK4TleKwKKs1ZdbfDDzbrGEG/hSKpXIgSO0yxaIEHQ
 FWjg+G0W7fBSgPEDsyvkABrt9VwskjpJHQs+1zcxEqp7fDJcm2kl2djRtF8sLpgzCRKeMn+mXg6
 eAaSrJCTaw6nl4GR8co8AY2FSOlDRWf1Qmg/mAoCO/mUJ2FSE1A2y34fzAHAH0rGZtk6QeDR5Bb
 xmCVY95nqrTl/k4i+HW48IDI4OGOpY3SqKGOoWtTzvuCefUfZkWaitgw6FtQvt5ZsBZmpxTUrX6
 tmtoZZm7asCDDnmtBUMXyS+m64Ohf6OwoI+SqJf9NEsxdWt+f2k6COv53b41AUs2hD0vEAkyts8
 jySiF+NWd1slfqf69AJjbZkNknQU/V23pbdPaQ9A2rKc/vmpYod0m2cXpj1/xzcH7li7lUe2g3Z
 yQH49suD46/M9jBiEGgNP1oXqb211R6KfG3Rvhfwj3fPz0ap4wetSiMwrubQxeEIUtFX7IkbakQ
 khkx2/Y5eK5EZ/VM7hriQwC4L1cE2qM41/9JdgRsy5bLkfe/wqMB1JJpXVsQ4Ly3ULqKKt7Tqmi
 oEwDoLDWEluAMIYgMa4PUBwQmZYKxBtCFwr6745kREl0GitkB5Rb0zbHikq9uX1R4gDBcxYMjwT
 PwNGLA0sF0bKs0w==
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
Changes in v5:
- Address issues found by the Sashiko AI review bot
  - Maintain the compatibility with possible unexpected mode string when
    parsing, although such mode string is actually not expected, to
    satisfy the AI bot's concern.
  - Add a comment to point out that the adjustment of the Kconfig entry
    for ls2kbmc is in the following patch, to satisfy the AI bot's
    concern.
- Link to v4: https://lore.kernel.org/r/20260731-ls2kbmc-mod-v4-0-d201502ba239@gmail.com

Changes in v4:
- Use a better way to get the GPIO device fwnode.
- Add a comment to describe a problem found by AI bot which is actually
  intended.
- Link to v3: https://lore.kernel.org/r/20260710-ls2kbmc-mod-v3-0-ef718636e78e@gmail.com

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
 drivers/mfd/ls2k-bmc-core.c | 246 ++++++++++++++++++++++++++++++++++----------
 3 files changed, 192 insertions(+), 58 deletions(-)
---
base-commit: 11028ab62899e4191e074ee364c712b77823a9c4
change-id: 20260626-ls2kbmc-mod-5209193009b2

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

