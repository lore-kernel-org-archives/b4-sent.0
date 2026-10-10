From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 00/11] cmd: phonemenu: phone form factor boot menu
Date: Sat, 10 Oct 2026 23:07:48 +0200
Message-Id: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrE3SUj9xFbGgBiNR0iIS6d0Vy
 2/x3g2OLJODKrrB0smOVxMg4wj01JqRkPtgSESSSyEFdgq3aTW0kDnwj1FmQ1aoMi9SpSCUm6W
 Br+9aN7/d0c2k93cF3j9l3iUUdwAAAA==
X-Change-ID: 20261010-b4-phonemenu-series-15f574867344
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=3116;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=7APOP7QbN4fzG5Ms4rgUh81UyGymuMvzRWMyCEU7A5Q=;
 b=5alhi/tvg9vdbbCIjVlQiwcTXeft2MDX97az5pU9Fiye2H2atCU2vOxY91xxkk6vn3ftFMCw1
 W00mrR3fpOiDEihjNFJbR7WNSpRaiuA6T8p1oxFHrz4De0P/yakEVGK
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a boot menu for devices with a framebuffer where the only inputs are
the volume and power buttons. The menu is SoC independent and SoC specific
parts hook in through weak functions. Qualcomm implementation is provided
in the patch set.

1. Add helpers for several commands. dfu_pwr is needed because
   the stock dfu loop only exits on Ctrl-C which a phone doesn't have.

2. The core for the menu which reuses bootmenu_loop() for navigation
   so any board that maps its buttons to keys (BUTTON_REMAP_PHONE_KEYS)
   works unchanged.

3. Phones often have no usable display during bring-up, or are driven
   from a host so the same menu is also drawn with ANSI escapes.

4. Not specific to the menu: Qualcomm keeps A/B state in the GPT
   attribute flags, not in "misc", so ab_select_slot() is wrong there.

5. Generic header info for the slot lookup which is a weak hook and
   the block device comes from the "storage" env var.

6. The Snapdragon override of that hook kept out of the generic file.

7. Shows why the device booted (e.g. recovery, fastboot). Reads the BCB
   from the "storage" device.

8. PMIC reister layout QPNP-PON specific for PM660 to decode the boot reason.

9. The USB ACM stdio device can be listed before it has been started
    and puts() then dereferences NULL private data.

10. The weak default picks "mmc" from Kconfig, so on UFS boards
    "fastboot reboot bootloader" could never write the BCB.

11. Usage documentation for the commands above.

Here's the URL with image of the menu on blueline, sargo and enchilada:
https://download.ixit.cz/u-boot.png

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (11):
      cmd: phone_util: add poweroff, dfu_pwr and USB Ethernet commands
      cmd: phonemenu: pixel drawn boot menu rendering and navigation
      cmd: phonemenu: mirror the menu to byte-stream consoles
      boot: android_ab: read the A/B slot from the GPT on Snapdragon
      cmd: phonemenu: show active A/B slot in the header
      cmd: phonemenu: read the A/B slot on Snapdragon without "misc"
      cmd: phonemenu: show Android boot reason in the header
      cmd: phonemenu: show PMIC PON status in the header
      usb: gadget: f_acm: check the acm_stdio_puts() against an unstarted device
      cmd: phone_util: fix "Cannot set reboot flag" on fastboot reboot
      doc: usage: add phonemenu command documentation

 MAINTAINERS                 |   5 +
 boot/android_ab.c           |  42 ++++
 cmd/Kconfig                 |  11 +
 cmd/Makefile                |   1 +
 cmd/phone_util.c            | 148 ++++++++++++
 cmd/phonemenu.c             | 550 ++++++++++++++++++++++++++++++++++++++++++++
 cmd/phonemenu_qcom.c        | 112 +++++++++
 doc/usage/cmd/phonemenu.rst |  92 ++++++++
 drivers/usb/gadget/f_acm.c  |   3 +
 include/phonemenu.h         |  17 ++
 10 files changed, 981 insertions(+)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20261010-b4-phonemenu-series-15f574867344

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

