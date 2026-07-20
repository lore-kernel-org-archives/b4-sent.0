From: Pawel Laszczak <pawell@cadence.com>
Date: Mon, 20 Jul 2026 13:11:58 +0200
Subject: [PATCH] usb: cdnsp: fix incorrect endian conversions for APB
 timeout register
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260720-endian-fix-v1-v1-1-b5681fa1ea9f@cadence.com>
X-B4-Tracking: v=1; b=H4sIAH4CXmoC/yXMwQqDMBCE4VeRPXchm2JEX6X0YOPYrodYEhVBf
 HejHj+G+TdKiIpETbFRxKJJx5Ahj4L8rw1fsHbZZI11prKGETptA/e68iLsxT1rV5cCAeXPPyI
 vV+/1vp3mzwA/nRHa9wNSwcW5cQAAAA==
X-Change-ID: 20260720-endian-fix-v1-c16396951e1e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Peter Chen <peter.chen@kernel.org>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Arnd Bergmann <arnd@arndb.de>, stable@vger.kernel.org, 
 Pawel Laszczak <pawell@cadence.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784545944; l=1525;
 i=pawell@cadence.com; h=from:subject:message-id;
 bh=4tdqriBTc2qKtG8H7cGabgQJM1xpL7ga0H8aaUvEcOc=;
 b=35y75WntvdfaxWt0sa3KMXBjGHpzkqUmWJNoSU0uLyGAZxWxz0d8Hx0dmpAGE2492xKqXu0OR
 L+tYpxObi9WAs6K+dTh8OzaPNsmYMM/K/g40gDha/BlppgL+S+t0XIu
X-Developer-Key: i=pawell@cadence.com; a=ed25519;
 pk=EUPBvLO9CDg7j6defeDl2iqi+z5Ivqu4Z46aiqe7dYc=
X-Endpoint-Received: by B4 Relay for pawell@cadence.com/default with auth_id=707
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

readl() already returns a CPU-endian value. Passing its return value to
le32_to_cpu() is therefore redundant and causes an incorrect double byte
swap on big-endian systems.

Similarly, writel() expects a CPU-endian value, so passing the result of
cpu_to_le32() is incorrect.

Remove the unnecessary conversions and operate on the MMIO register value
as a CPU-endian u32.

Fixes: 241e2ce88e5a ("usb: cdnsp: Fix issue with resuming from L1")
Suggested-by: Arnd Bergmann <arnd@arndb.de>
Cc: stable@vger.kernel.org
Signed-off-by: Pawel Laszczak <pawell@cadence.com>
---
 drivers/usb/cdns3/cdnsp-gadget.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/usb/cdns3/cdnsp-gadget.c b/drivers/usb/cdns3/cdnsp-gadget.c
index a5275c2fb43b..7a516e509198 100644
--- a/drivers/usb/cdns3/cdnsp-gadget.c
+++ b/drivers/usb/cdns3/cdnsp-gadget.c
@@ -163,9 +163,9 @@ static void cdnsp_set_apb_timeout_value(struct cdnsp_device *pdev)
 	offset = cdnsp_find_next_ext_cap(base, offset, D_XEC_PRE_REGS_CAP);
 	reg = base + offset + REG_CHICKEN_BITS_3_OFFSET;
 
-	val  = le32_to_cpu(readl(reg));
+	val  = readl(reg);
 	val = CHICKEN_APB_TIMEOUT_SET(val, cdns->override_apb_timeout);
-	writel(cpu_to_le32(val), reg);
+	writel(val, reg);
 }
 
 static void cdnsp_set_chicken_bits_2(struct cdnsp_device *pdev, u32 bit)

---
base-commit: abe651837cb394f76d738a7a747322fca3bf17ba
change-id: 20260720-endian-fix-v1-c16396951e1e

Best regards,
--  
Pawel Laszczak <pawell@cadence.com>

