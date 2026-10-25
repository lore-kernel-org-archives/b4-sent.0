From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Sun, 25 Oct 2026 23:50:05 +0100
Subject: [PATCH 2/2] serial: tegra: Fix overflow in
 tegra_check_rate_in_range()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261025-upstream-serial-tegra-overflow-v1-2-267b5b7a79ee@tsv-stahl-riesa.de>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792968614; l=1845;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=itgIcGWGOLTyUm1KE2QunM+q/33HpForOO0+9QOkieo=;
 b=ifzVpAwj3ytlam2cPbnwHEpgbVut600nZsB8xfp8yN+PiAPG/fl0ebaGnWo93f+fn/JFOt1PD
 DyJny1Zu3E3BqCKSZejwKM+IswXF+xrNvbegyTICip8X/rspzZoLoSW
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

tegra_check_rate_in_range() calculates the deviation of the configured
from the required clock rate as (configured_rate - required_rate) *
10000 in a long, which is only 32 bits wide on 32-bit ARM. This
overflows as soon as the two rates differ by more than about 214.7 kHz,
so the check lets through exactly the large deviations it is meant to
catch.

On the Tegra Note 7 (Tegra114) the Bluetooth UART ran at 45.33 MHz
instead of 48 MHz at 3 Mbaud (-5.6 %, see the previous patch). The
check calculated -0.18 % and let it pass, although the limit is 4 %.

Do the multiplication in 64 bits.

Tested on the Tegra Note 7 with a tolerance of -500 for 1 to 4 Mbaud,
which gives 45.33 MHz at 3 Mbaud: the driver now logs
"configured baud rate is out of range by -555" and does not apply the
rate. With the tolerance of 136 (48.00 MHz) it logs nothing.

64-bit platforms are not affected.

Fixes: d781ec21bae6 ("serial: tegra: report clk rate errors")
Cc: stable@vger.kernel.org
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
 drivers/tty/serial/serial-tegra.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/tty/serial/serial-tegra.c b/drivers/tty/serial/serial-tegra.c
index cc09fbc3aad8..cb5ef8aac198 100644
--- a/drivers/tty/serial/serial-tegra.c
+++ b/drivers/tty/serial/serial-tegra.c
@@ -380,8 +380,8 @@ static int tegra_check_rate_in_range(struct tegra_uart_port *tup)
 {
 	long diff;
 
-	diff = ((long)(tup->configured_rate - tup->required_rate) * 10000)
-		/ tup->required_rate;
+	diff = div_s64((s64)(tup->configured_rate - tup->required_rate) * 10000,
+		       tup->required_rate);
 	if (diff < (tup->cdata->error_tolerance_low_range * 100) ||
 	    diff > (tup->cdata->error_tolerance_high_range * 100)) {
 		dev_err(tup->uport.dev,

-- 
2.56.0

