From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH RFC 0/5] mfd: ls2kbmc: multiple fixes for this driver
Date: Wed, 08 Jul 2026 03:24:01 +0800
Message-Id: <20260708-ls2kbmc-mod-v1-0-c344bf5defa3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFJSTWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDMyMz3Zxio+yk3GTd3PwUXVMjA0tDS2MDA8skIyWgjoKi1LTMCrBp0Up
 Bbs5KsbW1AHs6g9piAAAA
X-Change-ID: 20260626-ls2kbmc-mod-5209193009b2
To: Binbin Zhou <zhoubinbin@loongson.cn>, 
 Chong Qiao <qiaochong@loongson.cn>, Lee Jones <lee@kernel.org>, 
 Huacai Chen <chenhuacai@kernel.org>, Corey Minyard <corey@minyard.net>, 
 Linus Walleij <linusw@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>
Cc: Xi Ruoyao <xry111@xry111.site>, WANG Xuerui <kernel@xen0n.name>, 
 Yinbo Zhu <zhuyinbo@loongson.cn>, Jiaxun Yang <jiaxun.yang@flygoat.com>, 
 mfd@lists.linux.dev, linux-kernel@vger.kernel.org, 
 linux-gpio@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2483;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=Bt/q0n0w05U5iaF1GtMTt+11t9g0yfG2q6EzIbfOXug=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTVJUE1eQTF0tg4qKpKE5TVY5SQc+fBqBfzKle
 yUccej24LCJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1SVAAKCRCwMePKe/7Z
 bkPoD/4/pk8IBhQUNkY07oLMfY2c91J8OSgnwPm2aPokh0VuS2pSqLhxSOdoS9QcJHNuJL3XiE6
 AUVfsReXZjtrMXQ9z7prcoi2Jt1Owdqz7sP0xrOD8f97JfQbbzUoowt2L0LWb1u1d2EHNKElrxl
 LogcRw0v8wIIVFxP8r9/znRTNk0Nhs75h0tSvFgyKYSpCYsCklYr13HV0/rSfzr1nqA/nGb/byY
 TuFjdxEYYV+vzQgAMTIxHeLqeivFG/uETr8z6CugA/BhZGkX9FYIpqeWgTF5/V2EfLGXeg/MciL
 xu8ia6AVrY470yJrXt2JlznIZaVhgh1vw0K/n6w7CrBfNUiFLxTwp+rMke/vcDxZs3IXouFPWv+
 vhQi2LWJ8M8bdGxNkGQegyAsqtHByXYwO51MAI8QHydwrPcU2NQBUWKmA7HW1fn0mmos2Yn5Lmo
 BhYxt++D54YydtEOyrzw9hoSZukcXBar2N40bl8d+cv9fFqUjhcpo2EwVOJ149zvbcswJ/1gtby
 lkLE8WKUIai1qGwkX+uVXwy+UnefrBxsYNkhxwlb+/6C+Pm++/sHghyBz6JmbDjVMpdIKqYREci
 lu/wxKWXdlXkmdBa4uaLRtRDgK+DPp0LFoOcDegK9jsJdOD3D4/PIj7uj45zGe4fzPs+ZmLAJPl
 MQGTldZy+zCkmkA==
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
Miao Wang (5):
      mfd: ls2kbmc: make a copy when parsing mode string
      mfd: ls2kbmc: sanity check for the connected pci port
      mfd: ls2kbmc: redraw using exported functions
      mfd: ls2kbmc: able to compile as a module
      mfd: ls2kbmc: capture the reset event of BMC through GPIO

 drivers/mfd/Kconfig         |   2 +-
 drivers/mfd/ls2k-bmc-core.c | 224 ++++++++++++++++++++++++++++++++++----------
 2 files changed, 174 insertions(+), 52 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260626-ls2kbmc-mod-5209193009b2

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

