From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH RFC v7 0/8] mfd: ls2kbmc: multiple fixes for this driver
Date: Mon, 10 Aug 2026 20:25:26 +0800
Message-Id: <20260810-ls2kbmc-mod-v7-0-8aa0fb5a5462@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADbDeWoC/33PwUrEMBAG4FdZcjYyM0kmjSdB8AG8ioc0SXfDb
 rfSSlGWvruxF5sKHmeG7x/+m5jSmNMkHg43MaY5T3m4lsHeHUQ4+esxyRzLLAiIgYnlZaJz2wf
 ZD1EaAodOAbiWRBHvY+ry55r2Kl6en8RbWZ7y9DGMX+uHGdfTGmahqcJmlCCD0rrtTEydV4/H3
 ufLfRj6NWemfywVS76LEa1Gy7y3amMRaquKTZ3FhhUn26S91RursLa62EiABqj1pNzeml/bgK6
 t+fnLbTAhRufdn768taa2XCxyCDFppNhUfZdl+Qag+mZ01wEAAA==
X-Change-ID: 20260626-ls2kbmc-mod-5209193009b2
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 Miao Wang <shankerwangmiao@gmail.com>, Corey Minyard <cminyard@mvista.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5596;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=VqOH78WXAQ+kL8c6/URXimgA6Yb9obzRXJkHjuhqnyk=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqecM6fR9BI6w0RYLb3RUHW/M2Fhd5rFe8ufJPg
 Dm/ydBU3v+JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCannDOgAKCRCwMePKe/7Z
 buL0EACuphML4A2EaYvzjQagn3gTpo70JkafNCnA0sSauTPTfxfSPgOedao34pWWaQgB25t8GBO
 Yu3UPmNRbE91huxv71yYLAWkLZwi4/vJFOVDrQ+Yo2NU/fkpoqebpUjQi5MGkyHqSBWRz+3SNnl
 sVMxMc+l+ldfQAkHq9yG+FGkXRVncG1EJldvm/es3xSPHnjNIEE3CQ7zwgmCvtraVN5OBIzBSXK
 NG2JCHKaf0mBGAgYpW12ziHuY8YU/7zKEsh9E53Ly1Ra+qXOJOCFBD2+DWo3U3rPokWLJN8iSVN
 xLtknTbVsvjP5TsG9gDHchkJ3uef+JIlt8Y827EowftibVV6SrWMO/f+US+HaM8Z0ySKSBZOOqN
 a/28z9tq1LQtHUQkxq791o0PVInlcks3ntxIJFWnsfj6lGeN7iz97HjlB1+uvkB7de7PrwxihiQ
 TCEMlpeOCPGNSv9A5mPkO9KouG//uMUFPy+3jDiCEMivqsqNbPLf5Bmqf4e1cKYFhTS/LXsqcBn
 35w05ZRgUsDAz6bdHJO8UmP3SOAVS7KR5af0Mw0XNYPhvXA7e9VZfnRLBn4efQ1BpFWvHy7cl3O
 OYmQNeYbCA1BbnB1b7DCw0+NFIs/r6a0jWU285S5BT93N0l27vB1QW2b32pE8Iz8SmW0vOlsaW9
 4UAw3yxVtVNCHyg==
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
series by using the GPIO subsystem APIs instead. To associate a GPIO pin
with a certian PCI device, it should be declared in the firmware level,
i.e. in the ACPI table or the device tree, and thus the firmware
interface should be discussed and coordinated with Loongson personnels.
Despite of this, the proposed solution in this series should be the
minimum necessary change to express such association. Furthermore, the
conventional GPIO pin number and the controller address are also
provided, to be used as a fallback when the GPIO pin is not declared.

Finally, there is a minor issue in the driver where it changes the
mode string describing the screen resolution during probing, which
prevents the device from being probed again if -EPROBE_DEFER is
returned by the probe function.

I have tested the changes in this series on a single-socket Loongson
3C6000 server with a Loongson 2K BMC, and the driver works as expected
when the corresponding GPIO driver is additionally loaded.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Changes in v7:
- When parsing the mode string, require the mode string to start with
  "video=", reverting the change in v5. Add a comment to describe the
  reason for this change to satisfy the AI bot's concern.
- When printing the invalid mode string, use %*pE to print the string
  to prevent the string from printing garbage characters, as suggested
  by the AI bot.
- When calculating the stride, check that the multiplication of width
  and depth does not overflow, as suggested by the AI bot.
- Add gpio_device_get_fwnode() into gpiolib.c as a library function to
  get the fwnode of a GPIO device, as suggested by Bartosz.
- Adjust the coding style of the patch as suggested by Bartosz.
- Link to v6: https://lore.kernel.org/r/20260805-ls2kbmc-mod-v6-0-16ccde412d86@gmail.com

Changes in v6:
- Ajdust the Kconfig entry for IPMI_LS2K, moving the dependency on
  MFD_LS2K_BMC_CORE to the IPMI_SI Kconfig entry, as discussed with
  and agreed by Corey.
- Link to v5: https://lore.kernel.org/r/20260804-ls2kbmc-mod-v5-0-e6bc5cdd9a93@gmail.com

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
Miao Wang (8):
      mfd: ls2kbmc: Make a copy when parsing mode string
      mfd: ls2kbmc: Sanity check for the connected pci port
      mfd: ls2kbmc: Redraw using exported functions
      mfd: ls2kbmc: Cancel the work queue on removal
      ipmi: ls2k: adjust dependency to its mfd driver
      mfd: ls2kbmc: Able to be compiled as a module
      gpiolib: add gpio_device_get_fwnode() helper
      mfd: ls2kbmc: Capture the reset event of BMC through GPIO

 drivers/char/ipmi/Kconfig   |   2 +-
 drivers/gpio/gpiolib.c      |  13 +++
 drivers/mfd/Kconfig         |   2 +-
 drivers/mfd/ls2k-bmc-core.c | 251 ++++++++++++++++++++++++++++++++++----------
 include/linux/gpio/driver.h |   1 +
 5 files changed, 210 insertions(+), 59 deletions(-)
---
base-commit: 11028ab62899e4191e074ee364c712b77823a9c4
change-id: 20260626-ls2kbmc-mod-5209193009b2

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

