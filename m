From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:59 +0200
Subject: [PATCH 11/11] doc: usage: add phonemenu command documentation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-11-bfa23de6eb0b@protonmail.com>
References: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
In-Reply-To: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 "Kory Maincent (TI.com)" <kory.maincent@bootlin.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Mikhail Kshevetskiy <mikhail.kshevetskiy@iopsys.eu>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Frank Wunderlich <frank-w@public-files.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Heiko Schocher <hs@nabladev.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Peter Robinson <pbrobinson@gmail.com>, Brian Sune <briansune@gmail.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>, Petr Pavlata <petr@acrux.cz>, 
 David Heidelberg <david@ixit.cz>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=3888;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=4rKlXqKLw5bbyh0WBX0SFqfRP/5sF4LVx6wodC4de+k=;
 b=sU/Uc0gIDUYK9ONTVYUdX4FFeTZootMqvUISQ2XKyzGOWPGjuyszS+6DWnDQ0YOmhTD3wuajc
 4LMgz0gc4lFAJ3UgTPdEULCs7OWMexy8Rf/4rkMb4yc0pt48LS9+4R/
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document the phonemenu command, its menus. header and the
phone_poweroff, dfu_pwr and usbether helper commands.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 MAINTAINERS                 |  1 +
 doc/usage/cmd/phonemenu.rst | 92 +++++++++++++++++++++++++++++++++++++++++++++
 2 files changed, 93 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index e4c108a0412..23382090ffd 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -687,6 +687,7 @@ R:	Sumit Garg <sumit.garg@kernel.org>
 L:	u-boot-qcom@groups.io
 S:	Maintained
 T:	git https://source.denx.de/u-boot/custodians/u-boot-snapdragon.git
+F:	doc/usage/cmd/phonemenu.rst
 F:	cmd/phone_util.c
 F:	cmd/phonemenu.c
 F:	cmd/phonemenu_qcom.c
diff --git a/doc/usage/cmd/phonemenu.rst b/doc/usage/cmd/phonemenu.rst
new file mode 100644
index 00000000000..918dbcfc44f
--- /dev/null
+++ b/doc/usage/cmd/phonemenu.rst
@@ -0,0 +1,92 @@
+.. SPDX-License-Identifier: GPL-2.0+
+
+.. index::
+   single: phonemenu (command)
+
+phonemenu command
+=================
+
+Synopsis
+--------
+
+::
+
+    phonemenu [advanced|diag]
+    phone_poweroff
+    dfu_pwr
+    usbether
+
+Description
+-----------
+
+The *phonemenu* command shows a boot menu on devices which have a
+framebuffer but only volume and power keys. It is enabled by
+CONFIG_CMD_PHONEMENU, which depends on CONFIG_VIDEO and CONFIG_ARM.
+
+The menu is drawn pixel by pixel with the video uclass and is divided into
+labelled sections. Navigation reuses the bootmenu key handler, so a board
+which maps its buttons to keys with CONFIG_BUTTON_REMAP_PHONE_KEYS works
+unchanged: volume up/down moves the highlight and power selects the entry.
+The same menu is also drawn with ANSI escape sequences on serial and USB
+CDC-ACM consoles, where the arrow keys and Enter can be used as well.
+
+advanced
+    show the advanced menu: TFTP and PXE boot over USB Ethernet, serial
+    gadget, USB mass storage, fastboot, DFU and the diagnostics submenu.
+    Entries are only present if the matching command is enabled.
+
+diag
+    show the diagnostics submenu: clock, environment, bootargs, board info
+    and button dumps.
+
+With no argument the main menu is shown, with *Boot*, *Advanced menu*,
+*Reset* and *Power off* entries. Each entry runs a U-Boot command and the
+submenus return to themselves afterwards.
+
+The header shows the device name, U-Boot version and a status line made of
+any of the following, each omitted if it cannot be determined:
+
+* the active A/B slot
+* the boot reason from the Android Bootloader Control Block (for example
+  recovery or fastboot)
+* the PMIC power-on trigger, if the platform provides it
+
+The block device used for these lookups is selected by the *storage*
+environment variable, either ``mmc`` or, by default, ``scsi`` (UFS).
+
+On Qualcomm Snapdragon the A/B state is kept in the attribute flags of the
+``boot_a`` and ``boot_b`` GPT entries rather than in ``misc``, so
+ab_select_slot() reads the slot from there when CONFIG_ARCH_SNAPDRAGON is
+enabled.
+
+Helper commands
+~~~~~~~~~~~~~~~
+
+The menu entries use a few small commands which are also available from the
+console:
+
+phone_poweroff
+    power off the device using PSCI SYSTEM_OFF. Fails if CONFIG_PSCI_RESET
+    is not enabled.
+
+dfu_pwr
+    run the ``dfu`` environment alias and leave DFU mode when the power
+    button is pressed. The stock DFU loop only exits on Ctrl-C, which a phone
+    does not have. Requires CONFIG_CMD_DFU.
+
+usbether
+    bind and probe the USB Ethernet (RNDIS) gadget on demand, for TFTP and
+    PXE boot. Requires CONFIG_USB_ETHER.
+
+Example
+-------
+
+::
+
+    => phonemenu
+    => phonemenu diag
+
+Configuration
+-------------
+
+The command is enabled with CONFIG_CMD_PHONEMENU.

-- 
2.55.0

