From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH RFC v2 0/7] mfd: ls2kbmc: multiple fixes for this driver
Date: Wed, 08 Jul 2026 05:16:24 +0800
Message-Id: <20260708-ls2kbmc-mod-v2-0-2afdd1741766@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKhsTWoC/1WNwQ6CMBBEf4Xs2ZplgSqeTEz8AK+GQykFNlBqW
 kM0hH+36c3jm8m82SAYzybAJdvAm5UDuyUCHTLQo1oGI7iLDIQkUZIUc6CptVpY14mKsM7rArF
 uCeLi5U3Pn2R7wuN+gyaGI4e389/0sOapSrITnv9kay5Q6KIs277qTK+K62AVz0ftLDT7vv8AY
 Qbd6qsAAAA=
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2998;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=R5MYBkmg9DlEORfsOK2J6Cz+Av5R8RDX/POobqEtPto=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqTWyrC82Pv8V+XNEbLed3/hBmNUQ1SUG+iKJoV
 c2qZ9CsunqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCak1sqwAKCRCwMePKe/7Z
 bmO6D/9/P/pbfxEimrdNKf34i2O+V5h5bPKE5p8lGK0luddjmI0bUBkW+hbhWQkH+a2MBDwU/PB
 Skj79VERiEarHKHldzXOkKmCGJQTLdIE7XVBDN5acORXyB3GXIB9d8xYFOMTO1HDRKbTPB9sbK9
 R6CIaWmshi04588GPS8Wp8cE9IgbnmabLRw0BNuBkaAu6y34GRGIxG7DmBHJy6DXi9Lw6MvlmTy
 HLEhQEps0ZNI9SFzUXT4MHw6Ot9jTc9S7SXtC6v2hx4x9eqn02eE0/iOrThmou52CWbtnelA8Im
 umDo4XGxx99hkmgSiIY68oNHAOta+6FiUxeng/IIKk7giL2ha+7UFyEu00IeEdFT3GC/5tr8DT9
 m0GW8a3PzIo36Hl5mFy9WjGxSsMJRXprytUNqQCvnAk0s/xHka1kLhZ8mRrmNYXQuLoyHOZfBg4
 /lFRuSmYVEAyyKeBxFiOSlh0VQ6a87VNEIuDqPf/mXzoX5ZY11GEPjXTEigIp+NvqXM063/lEOK
 hPnsSsQ2/BbZKlwyJlb+q7g3m5pUVliJsBBHeskcj/PWU3EwlSuv+3yWSEWRTEwe5YBLtyLJwHS
 ezvLfYA2s4zSpzOpB1dXae5dsAvdAf/aE320q7UBapGvUF0RDy+vGvRg1JNQ0D3NGrbn8ewSR/Y
 4bTxEZ4Oux0qtOw==
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
 drivers/mfd/ls2k-bmc-core.c | 237 ++++++++++++++++++++++++++++++++++----------
 3 files changed, 186 insertions(+), 55 deletions(-)
---
base-commit: 0e35b9b6ec0ffcc5e23cbdec09f5c622ad532b53
change-id: 20260626-ls2kbmc-mod-5209193009b2

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

