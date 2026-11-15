From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/3] arm: meson: odroid-c4/hc4: Wake-on-LAN from suspend
Date: Sun, 15 Nov 2026 03:50:29 +0000
Message-Id: <20261115-b4-meson-scp-wol-v1-0-80c3e9f4deda@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAUs+WoC/x3MwQpAQBCA4VfRnE0ZLOVV5LAYTLGrnUJt3t3m+
 B3+P4JyEFbosgiBL1HxLoHyDKbNupVR5mQoi7IhIoNjjQerd6jTibff0dY0c2NbLkwFKTsDL/L
 8y3543w99hJQ7YgAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, u-boot-amlogic@groups.io
Cc: Tom Rini <trini@konsulko.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2136; i=iav@iav.lv;
 h=from:subject:message-id; bh=1f4rcOl0WM800WyLDxnBIBr8IxSjl/eCc4sHv9kkPzM=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFk/ddiuS96ttw9rPKzyclf40SWzXmvxdnk55F86nLng1
 oFbp6ubOkpZGMS4GGTFFFkmHNK4lbHk6l9/D/MHMHNYmUCGMHBxCsBEAhcy/FNbrSm6/fGTqy9V
 p29wPagU+Zi3vYM30XTCpbdxB+9Nby5gZPj13uGZi4RO2p+/4iVhGko7lFU8Zx085/h/yaMjZyq
 3f+MCAA==
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The BL301 that Hardkernel builds for ODROID-C4/HC4 wakes the board on
the Ethernet PHY only after the AP has sent SCPI SET_USR_DATA for client
7 with a non-zero value. Neither mainline U-Boot nor Linux sends it, so
a magic packet does not wake these boards from deep suspend.

This series sends 0 or 1 from the DTB fixup, following wakeup-source on
the PHY node of the DTB the OS boots with [1].

Tested on ODROID-HC4 (U-Boot chainloaded from SPI, BL301 built from
Hardkernel's odroidg12-v2015.01 with unrelated RTC alarm changes, Linux
7.4-rc2): with wakeup-source a magic packet wakes the board from deep
suspend 3/3; without it the packet does not and the RTC alarm does.
fdt boardsetup sends the expected value with the property present,
absent, and with the MAC disabled.

Client 7 is an extension of this BL301, so the option is enabled per
board, for C4 and HC4. The N2 BL301 has the same client, but I could
not test it, nor C4. The G12 device trees have no MHU node, hence a bare
helper rather than a DM mailbox driver; I can rework it if preferred.

[1] https://lore.kernel.org/r/20261109-hc4-phy-wakeup-v1-1-d98784ecac88@iav.lv

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Igor Velkov (3):
      arm: meson: g12a: send SCPI user data to the SCP firmware
      board: amlogic: odroid-n2: tell BL301 whether to wake on LAN
      configs: odroid-c4, odroid-hc4: enable Wake-on-LAN from suspend

 arch/arm/include/asm/arch-meson/scpi.h | 17 +++++++++++
 arch/arm/mach-meson/Kconfig            |  9 ++++++
 arch/arm/mach-meson/Makefile           |  1 +
 arch/arm/mach-meson/scpi-g12a.c        | 55 ++++++++++++++++++++++++++++++++++
 board/amlogic/odroid-n2/odroid-n2.c    | 31 +++++++++++++++++++
 configs/odroid-c4_defconfig            |  1 +
 configs/odroid-hc4_defconfig           |  1 +
 doc/board/amlogic/odroid-c4.rst        |  9 ++++++
 doc/board/amlogic/odroid-hc4.rst       |  9 ++++++
 9 files changed, 133 insertions(+)
---
base-commit: 6487c50b8a40f2668ab98a892b9300ad5c181f38
change-id: 20261115-b4-meson-scp-wol-a41de6a7e053

Best regards,
-- 
Igor Velkov <iav@iav.lv>

