From: Abdurrahman Hussain <abdurrahman@nexthop.ai>
Date: Mon, 27 Apr 2026 17:18:06 -0700
Subject: [PATCH 1/3] i2c: xiic: preserve PEC byte length in SMBus block
 read setup
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260427-i2c-xiic-v1-1-e6207f9aa5ad@nexthop.ai>
References: <20260427-i2c-xiic-v1-0-e6207f9aa5ad@nexthop.ai>
In-Reply-To: <20260427-i2c-xiic-v1-0-e6207f9aa5ad@nexthop.ai>
To: Michal Simek <michal.simek@amd.com>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-i2c@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abdurrahman Hussain <abdurrahman@nexthop.ai>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=2279;
 i=abdurrahman@nexthop.ai; h=from:subject:message-id;
 bh=WbRNSgR6fF75ujIFRpZT+WIk0CWNPjAlMacuue3U6KE=;
 b=owJ4nJvAy8zAJbYltPXv6rsCXxhPqyUxZL7/c3B1ziaWhgZtFrFK/7l1X/ruSL6cYMDSVjL1j
 c2+ms//ngV2lLIwiHExyIopssx55P+mraMtYkPMIXuYOaxMIEMYuDgFYCJT7jAydHBtfsJ7Ujyo
 QjBN2L0pu0lRwTj1x/cph3/Ku6i+WVcWz/BPQZ3xXJja3qblId0ujyKkJq17U3jguKjB1QquM6I
 zzQ/zAgDNJ07Z
X-Developer-Key: i=abdurrahman@nexthop.ai; a=openpgp;
 fpr=9CE24FEC86888658B05CC23FB45585FDABDD10F4
X-Endpoint-Received: by B4 Relay for abdurrahman@nexthop.ai/default with auth_id=756
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

xiic_smbus_block_read_setup() overwrites rx_msg->len based on the
announced block length byte, but the i2c core appends an extra byte to
msg->len when PEC is enabled on the client (see
__i2c_smbus_xfer_emulated in i2c-core-smbus.c). Before this handler
runs, rx_msg->len is therefore 1 + pec_len, where pec_len is 0 or 1.

Overwriting rx_msg->len to rxmsg_len + 1 drops that PEC byte from the
caller's buffer: the PEC byte is never drained from the FIFO and the
core's i2c_smbus_check_pec() reads the last payload byte instead of
the actual PEC, returning -EBADMSG even on clean transfers. Capture
pec_len before the overwrite and add it back when recomputing
rx_msg->len.

This is a pure bug fix; non-PEC behaviour is unchanged (pec_len == 0).
Tested on a Xilinx AXI IIC FPGA block driving an adm1266 PMBus
blackbox read -- with PEC enabled the full 64-byte record transfers
cleanly after this change.

Signed-off-by: Abdurrahman Hussain <abdurrahman@nexthop.ai>
---
 drivers/i2c/busses/i2c-xiic.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/i2c/busses/i2c-xiic.c b/drivers/i2c/busses/i2c-xiic.c
index 3e7735e1dae0..959a47b645a5 100644
--- a/drivers/i2c/busses/i2c-xiic.c
+++ b/drivers/i2c/busses/i2c-xiic.c
@@ -539,6 +539,8 @@ static void xiic_smbus_block_read_setup(struct xiic_i2c *i2c)
 
 	/* Check if received length is valid */
 	if (rxmsg_len <= I2C_SMBUS_BLOCK_MAX) {
+		unsigned int pec_len = i2c->rx_msg->len - 1;
+
 		/* Set Receive fifo depth */
 		if (rxmsg_len > IIC_RX_FIFO_DEPTH) {
 			/*
@@ -546,7 +548,7 @@ static void xiic_smbus_block_read_setup(struct xiic_i2c *i2c)
 			 * Receive fifo depth should set to Rx fifo capacity minus 1
 			 */
 			rfd_set = IIC_RX_FIFO_DEPTH - 1;
-			i2c->rx_msg->len = rxmsg_len + 1;
+			i2c->rx_msg->len = rxmsg_len + 1 + pec_len;
 		} else if ((rxmsg_len == 1) ||
 			(rxmsg_len == 0)) {
 			/*
@@ -562,7 +564,7 @@ static void xiic_smbus_block_read_setup(struct xiic_i2c *i2c)
 			 * Receive fifo depth should set to Rx msg len minus 2
 			 */
 			rfd_set = rxmsg_len - 2;
-			i2c->rx_msg->len = rxmsg_len + 1;
+			i2c->rx_msg->len = rxmsg_len + 1 + pec_len;
 		}
 		xiic_setreg8(i2c, XIIC_RFD_REG_OFFSET, rfd_set);
 

-- 
2.53.0

