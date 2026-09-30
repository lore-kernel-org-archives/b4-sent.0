From: Igor Velkov <iav@iav.lv>
Date: Wed, 30 Sep 2026 17:26:47 +0000
Subject: [PATCH] arm: mvebu: helios4_defconfig: enable the RTC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-helios4-rtc-v1-1-0e6ea4ce400b@iav.lv>
X-B4-Tracking: v=1; b=H4sIAFZGvWoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDS2MD3YzUnMz8YhPdopJk3RRjI9MkM1PLVHNzEyWgjoKi1LTMCrBp0bG
 1tQApVi+cXQAAAA==
To: Stefan Roese <stefan.roese@mailbox.org>, 
 Dennis Gilmore <dgilmore@redhat.com>
Cc: Tom Rini <trini@konsulko.com>, u-boot@lists.u-boot-project.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1019; i=iav@iav.lv;
 h=from:subject:message-id; bh=Z1m9AfZCgsRoTLxgUsNpAbVYQPwoPwUJtO4gm0s+YbU=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl73WKfTAhpC5l4uUXc8OW2jNV8Jsxpm9fOn5ts6z9x1
 7uCnvqujlIWBjEuBlkxRZYJhzRuZSy5+tffw/wBzBxWJpAhDFycAjCRs2oM/z0Cv1hbZaTe9Fs6
 7/TpAw4H9rae+VZ5Uq7O83dTXsKBvxsY/rvuffer84FZ3os/+08WdK2uYA9kEpF5xM3JYiWmOav
 EjBEA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Helios4 has the Armada 38x internal RTC, with a battery on the board.
Enable its driver so that the date command reads it.

Based on a patch by Aditya Prayoga in Armbian.

Signed-off-by: Igor Velkov <iav@iav.lv>
---
Tested on Helios4 with an Armbian v2026.07 build that carries the same
options: date shows the RTC time. The main build is compile-tested
only.
---
 configs/helios4_defconfig | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/configs/helios4_defconfig b/configs/helios4_defconfig
index d218949e307..fa00fbc809d 100644
--- a/configs/helios4_defconfig
+++ b/configs/helios4_defconfig
@@ -71,6 +71,8 @@ CONFIG_MVMDIO=y
 CONFIG_PHY_ANEG_TIMEOUT=8000
 CONFIG_PHY_MARVELL=y
 CONFIG_PCI_MVEBU=y
+CONFIG_DM_RTC=y
+CONFIG_RTC_ARMADA38X=y
 CONFIG_SPL_DEBUG_UART_BASE=0xd0012000
 CONFIG_DEBUG_UART_SHIFT=2
 CONFIG_SYS_NS16550=y

---
base-commit: f8eb3469e1a17c79b047b3fd38ae820e8816a115
change-id: 20260930-helios4-rtc-d325b659e774

Best regards,
-- 
Igor Velkov <iav@iav.lv>

