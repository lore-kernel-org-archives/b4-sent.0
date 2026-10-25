From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sun, 25 Oct 2026 23:50:04 +0100
Subject: [PATCH 1/2] serial: tegra: Fix overflow in
 tegra_get_tolerance_rate()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-upstream-serial-tegra-overflow-v1-1-267b5b7a79ee@tsv-stahl-riesa.de>
References: <20261025-upstream-serial-tegra-overflow-v1-0-267b5b7a79ee@tsv-stahl-riesa.de>
In-Reply-To: <20261025-upstream-serial-tegra-overflow-v1-0-267b5b7a79ee@tsv-stahl-riesa.de>
To: Laxman Dewangan <ldewangan@nvidia.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: Shardar Shariff Md <smohammed@nvidia.com>, 
 Krishna Yarlagadda <kyarlagadda@nvidia.com>, 
 Svyatoslav Ryhel <clamor95@gmail.com>, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, linux-tegra@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792968614; l=2309;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=gJnftTJ6jB1jgdWypz21lUHPmEbydEvI3zikNjoJOxA=;
 b=85/ZmKHsXEBUB4ErFANq04SO6vKwA0ekArL5/pX4906QeA+JXgLi9gupwXcRW8pZdRbd+HyVo
 x/XKjCDg41oBgSsBgY25ZFYxvz4TGqPhbtp6TtrDbrgzHZsyB5XNXZz
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_get_tolerance_rate() raises or lowers the UART clock rate by the
tolerance from "nvidia,adjust-baud-rates", given in units of 0.01 %. It
calculates rate * tolerance in a long, which is only 32 bits wide on
32-bit ARM. With a tolerance of 136 this overflows from a clock rate of
about 15.8 MHz, i.e. from about 1 Mbaud, and the rate ends up adjusted
in the wrong direction.

The Tegra Note 7 (Tegra114) uses a tolerance of 136 for 1 to 4 Mbaud on
its Bluetooth UART, as in the downstream device tree. For 3 Mbaud the
driver asks for 47.79 MHz instead of 48.65 MHz, the clock rounds that
down to 408 MHz / 9 = 45.33 MHz (-5.6 %), and the WL1801 controller
stops answering after the switch to 3 Mbaud (HCI commands time out
with -110). The same overflow gives 23.31 MHz instead of 24 MHz at
1.5 Mbaud; both rates were confirmed on the device.

Do the multiplication in 64 bits. With that the driver asks for
48.65 MHz at 3 Mbaud and gets 48.00 MHz.

Tested on the Tegra Note 7 with the tolerance of 136: Bluetooth comes
up at 3 Mbaud, scans and connects to a paired device, and the HCI
counters show no errors.

64-bit platforms are not affected.

Fixes: f04a3cc8d455 ("serial: tegra: add support to adjust baud rate")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/tty/serial/serial-tegra.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index b0fc4ae3686f..cc09fbc3aad8 100644
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
@@ -368,8 +369,8 @@ static long tegra_get_tolerance_rate(struct tegra_uart_port *tup,
 	for (i = 0; i < tup->n_adjustable_baud_rates; ++i) {
 		if (baud >= tup->baud_tolerance[i].lower_range_baud &&
 		    baud <= tup->baud_tolerance[i].upper_range_baud)
-			return (rate + (rate *
-				tup->baud_tolerance[i].tolerance) / 10000);
+			return rate + div_s64((s64)rate *
+				tup->baud_tolerance[i].tolerance, 10000);
 	}
 
 	return rate;

-- 
2.56.0

