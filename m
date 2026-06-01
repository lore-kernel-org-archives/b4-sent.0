From: Sam Day <me@samcday.com>
Date: Mon, 01 Jun 2026 18:12:56 +1000
Subject: [PATCH RESEND 15/16] serial: msm: wait for TX empty before reinit
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260601-qcom-armv7-v1-15-05a08d87e476@samcday.com>
References: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
In-Reply-To: <20260601-qcom-armv7-v1-0-05a08d87e476@samcday.com>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>, 
 Michal Simek <michal.simek@amd.com>, 
 Angelo Dureghello <angelo@kernel-space.org>, 
 Eugen Hristev <ehristev@kernel.org>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Yao Zi <me@ziyao.cc>, Simon Glass <sjg@chromium.org>, 
 Sughosh Ganu <sughosh.ganu@arm.com>, George Chan <gchan9527@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>, 
 Tien Fong Chee <tien.fong.chee@altera.com>, Peng Fan <peng.fan@nxp.com>, 
 Alif Zakuan Yuslaimi <alif.zakuan.yuslaimi@altera.com>, 
 Anshul Dalal <anshuld@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Tingting Meng <tingting.meng@altera.com>, Alice Guo <alice.guo@nxp.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 David Wronek <david.wronek@mainlining.org>, 
 Danila Tikhonov <danila@jiaxyga.com>, 
 Varadarajan Narayanan <quic_varada@quicinc.com>, 
 Lukasz Majewski <lukma@denx.de>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jens Reidel <adrian@mainlining.org>, Sam Day <me@samcday.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780301569; l=940;
 i=me@samcday.com; s=20240502; h=from:subject:message-id;
 bh=6h2JS7vb3rrgMzpe4XUkpAHDk1EZODZWYc14tqNSuVo=;
 b=XP/ENLw6bNzwF850cp92wJHgfDa/DU5Vfro42lB2S9GD2fwgqcpctpS2aPmp+ONGczJL+q/on
 fDpNoU3MW60C12tRC6pS/t3d1FmUXpLQzvYMpcH7xdbPUN01HqpYafF
X-Developer-Key: i=me@samcday.com; a=ed25519;
 pk=bzyS0akxWMqr9+AXzgBRIp28KKpEOs+GjYMc2yf+aeU=
X-Endpoint-Received: by B4 Relay for me@samcday.com/20240502 with auth_id=595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

At least on UARTDM 1.3, I was noticing the early UART debug banner
getting corrupted. It turns out this is because U-Boot was
re-initializing the UARTDM block and writing to it before it had
finished shifting out the FIFO from the previous bootloader. Waiting for
TX_EMPTY in the status register consistently fixes the issue.

Signed-off-by: Sam Day <me@samcday.com>
---
 drivers/serial/serial_msm.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/drivers/serial/serial_msm.c b/drivers/serial/serial_msm.c
index 10948e2aede..db085d68a0d 100644
--- a/drivers/serial/serial_msm.c
+++ b/drivers/serial/serial_msm.c
@@ -351,6 +351,8 @@ static inline void _debug_uart_init(void)
 	 *   - HMIBSC: GCC_BLSP1_UART1_APPS_CLK
 	 */
 	//apq8016_clk_init_uart(0x1800000, <uart_clk_id>);
+	while (!(readl(init_serial_data.base + UARTDM_SR) & UARTDM_SR_TX_EMPTY))
+		;
 	uart_dm_init(&init_serial_data);
 }
 

-- 
2.54.0

