From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:11:23 +0000
Subject: [PATCH] serial: tegra: do the baud tolerance math in 64 bits
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-serial-tegra-baud-tolerance-v1-1-39907382281f@enser.io>
X-B4-Tracking: v=1; b=H4sIAHp5AmsC/yWNwQ6CMBBEf4Xs2VVam0r8FeNhuyxQQ4ppCzEh/
 LutHt9k3swOSaKXBPdmhyibT34JBdSpAZ4ojIK+Lwy61VYprdEZrArNmGWMhI7WHvMyS6TAggP
 ba9sRd2wNlJF3lMF/fgeP55/T6l7Cua7WhqMk6Ko91ajiZbudDUbWcBxfsOFZvqIAAAA=
X-Change-ID: 20261122-b4-serial-tegra-baud-tolerance-fc6308ac8c64
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>, 
 Krishna Yarlagadda <kyarlagadda@nvidia.com>, linux-serial@vger.kernel.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324319; l=3906;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=GXIk9AQVC2K8tTVlGwvFv8h3R35+N798W5Ucf2ARQvE=;
 b=G/EK8deCg7wtRnWgFOWfHw6ZHJdTUxTHk9IExb1Hv0blbsDDDpfAiqpVu6QkkfQKOSwAbdcP1
 S/HZNlh3NuCBcJO0Y/rrs+31xMe2Wi3Jftk2RnFdORd89ryHdXoeAi+
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On a 32-bit kernel both halves of the baud tolerance logic overflow
`long`, so a Tegra20/30/114/124 board whose DT has an
nvidia,adjust-baud-rates entry runs its fast UART rates at the wrong
speed, and the range check then reports the wrong speed as fine.

tegra_get_tolerance_rate() returns rate + rate * tolerance / 10000, with
rate = 16 x baud. For any baud above ~986 kbaud, rate * tolerance
exceeds 2^31 and wraps, so the adjustment comes out negative and the
clock divider rounds the request down a further half step. On a Tegra
Note 7 (pll_p 408 MHz, nvidia,adjust-baud-rates = <1000000 4000000 136>),
read back from clk_summary:

    baud      wanted uartc   got uartc     actual baud   error
    3000000   48652800       45333334      2833333       -5.56 %
    1500000   24326400       23314286      1457143       -2.86 %

Both "got" values follow exactly from the wrapped arithmetic. With 64-bit
math the clock comes out at 48000000 and 24000000, i.e. 3000000 and
1500000 baud exactly.

tegra_check_rate_in_range() is meant to catch this, and cannot: it
computes (long)(configured - required) * 10000, which wraps for any
delta above ~215 kHz. The -5.56 % above reads as -0.18 % and passes the
window, so "configured baud rate is out of range" is never printed.

Found through Bluetooth: hci_ll moves a WL18xx on uartc to 3 Mbaud after
the firmware download, the host lands 5.56 % low, and the controller
never answers the next command (HCI_Reset times out). With this change
the controller comes up at 3 Mbaud and scans. Tested on that board with
an otherwise unmodified driver on a next-20260422-based kernel; 64-bit
kernels are unaffected, as long is 64 bits there.

Use div_s64() for both expressions so the result does not depend on the
width of long.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Fixes: f04a3cc8d455 ("serial: tegra: add support to adjust baud rate")
Fixes: d781ec21bae6 ("serial: tegra: report clk rate errors")
Signed-off-by: EMCP333 <emcp@enser.io>
---
 drivers/tty/serial/serial-tegra.c | 12 ++++++++----
 1 file changed, 8 insertions(+), 4 deletions(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index e93873a1d1..b5973c0a95 100644
--- a/drivers/tty/serial/serial-tegra.c
+++ b/drivers/tty/serial/serial-tegra.c
@@ -18,6 +18,7 @@
 #include <linux/err.h>
 #include <linux/io.h>
 #include <linux/irq.h>
+#include <linux/math64.h>
 #include <linux/module.h>
 #include <linux/of.h>
 #include <linux/pagemap.h>
@@ -365,11 +366,13 @@ static long tegra_get_tolerance_rate(struct tegra_uart_port *tup,
 {
 	int i;
 
+	/* 64-bit: rate * tolerance overflows a 32-bit long */
 	for (i = 0; i < tup->n_adjustable_baud_rates; ++i) {
 		if (baud >= tup->baud_tolerance[i].lower_range_baud &&
 		    baud <= tup->baud_tolerance[i].upper_range_baud)
-			return (rate + (rate *
-				tup->baud_tolerance[i].tolerance) / 10000);
+			return rate + div_s64((s64)rate *
+					      tup->baud_tolerance[i].tolerance,
+					      10000);
 	}
 
 	return rate;
@@ -379,8 +382,9 @@ static int tegra_check_rate_in_range(struct tegra_uart_port *tup)
 {
 	long diff;
 
-	diff = ((long)(tup->configured_rate - tup->required_rate) * 10000)
-		/ tup->required_rate;
+	/* 64-bit: delta * 10000 overflows a 32-bit long above ~215 kHz */
+	diff = div_s64((s64)(tup->configured_rate - tup->required_rate) * 10000,
+		       tup->required_rate);
 	if (diff < (tup->cdata->error_tolerance_low_range * 100) ||
 	    diff > (tup->cdata->error_tolerance_high_range * 100)) {
 		dev_err(tup->uport.dev,

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-serial-tegra-baud-tolerance-fc6308ac8c64

Best regards,
--  
EMCP333 <emcp@enser.io>

