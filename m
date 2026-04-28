From: Prasanna S <prasanna.s@oss.qualcomm.com>
Date: Tue, 28 Apr 2026 09:56:13 +0530
Subject: [PATCH v1] serial: qcom-geni: fix UART_RX_PAR_EN bit position
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260428-serial-bit-correct-v1-1-9131ad5b97d8@oss.qualcomm.com>
X-B4-Tracking: v=1; b=H4sIAOQ28GkC/x2MSQqAMAwAvyI5G7C1LvgV8aA1akBaSaUI4t+tH
 gdm5oZAwhSgy24QihzYuwQqz8Buo1sJeU4MutB1YbTBzx93nPhE60XInrhUpTJTrZtGtZDCQ2j
 h65/2EBUMz/MCME1V9mgAAAA=
X-Change-ID: 20260424-serial-bit-correct-f5314b627718
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>, Sagar Dharia <sdharia@codeaurora.org>, 
 Girish Mahadevan <girishm@codeaurora.org>, 
 Karthikeyan Ramasubramanian <kramasub@codeaurora.org>, 
 Doug Anderson <dianders@google.com>
Cc: linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-serial@vger.kernel.org, stable@vger.kernel.org, 
 Prasanna S <prasanna.s@oss.qualcomm.com>
X-Mailer: b4 0.16-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777350374; l=1216;
 i=prasanna.s@oss.qualcomm.com; s=20260428; h=from:subject:message-id;
 bh=92DZEPQq9gzbYu7wxhkrplbhyodAhccJZR/6Ys8Jr0E=;
 b=DF47/MZOJAkYmbFDkpCZ6t2dylwkyIF5j4bIvczMVo4KyYsJNj6KNfuEMpzXss606rJZzzhSG
 S0SN8xMx2SLAqD39rCyJMDR1wjYT7CE36RGrZiwcm4TIdVZOlgMU+FF
X-Developer-Key: i=prasanna.s@oss.qualcomm.com; a=ed25519;
 pk=ECtn3EnrN+3RY2I0/e72LjFYKGNLhhH+6UU2lBNO4+k=
X-Endpoint-Received: by B4 Relay for prasanna.s@oss.qualcomm.com/20260428 with auth_id=758
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

UART_RX_PAR_EN is incorrectly defined as bit 3, which triggers false
framing errors (S_GP_IRQ_1_EN) and causes received data to be dropped
when parity is enabled and the parity bit is 0.

Define UART_RX_PAR_EN as bit 4 of the SE_UART_RX_TRANS_CFG register, as
specified in the reference manual.

Fixes: c4f528795d1a ("tty: serial: msm_geni_serial: Add serial driver support for GENI based QUP")
Cc: stable@vger.kernel.org
Signed-off-by: Prasanna S <prasanna.s@oss.qualcomm.com>
---
 drivers/tty/serial/qcom_geni_serial.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/tty/serial/qcom_geni_serial.c b/drivers/tty/serial/qcom_geni_serial.c
index b365dd5da3cb..5139a9d21b2b 100644
--- a/drivers/tty/serial/qcom_geni_serial.c
+++ b/drivers/tty/serial/qcom_geni_serial.c
@@ -50,7 +50,7 @@
 #define TX_STOP_BIT_LEN_2		2
 
 /* SE_UART_RX_TRANS_CFG */
-#define UART_RX_PAR_EN			BIT(3)
+#define UART_RX_PAR_EN			BIT(4)
 
 /* SE_UART_RX_WORD_LEN */
 #define RX_WORD_LEN_MASK		GENMASK(9, 0)

---
base-commit: dd6c438c3e64a5ff0b5d7e78f7f9be547803ef1b
change-id: 20260424-serial-bit-correct-f5314b627718

Best regards,
--  
Prasanna S <prasanna.s@oss.qualcomm.com>

