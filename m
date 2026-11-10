From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Tue, 10 Nov 2026 03:56:42 +0000
Subject: [PATCH 1/2] can: kvaser_usb: hydra: reject commands shorter than
 the header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-kvaser-usb-validate-v1-1-f266b85aa908@gmail.com>
References: <20261110-kvaser-usb-validate-v1-0-f266b85aa908@gmail.com>
In-Reply-To: <20261110-kvaser-usb-validate-v1-0-f266b85aa908@gmail.com>
To: mkl@pengutronix.de, mailhol@kernel.org, joasantonio108@gmail.com
Cc: linux-can@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794283001; l=2462;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=WQBZhSAEzA9EWg/6IUMTZ+5l64+D6iO6t2jMkcYHrcE=;
 b=ng14H4NFwqtau2GbY5NiuCX/iT5hnlpAX9ifCs98whCYgnYAJrWT+AIcUZy8C0/5A0YRDe1L9
 x10OoQtrEG/Bjci/MEbYlRuOCwcE4MDTnf9z9/2p/DRznsU4WRBih4H
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

kvaser_usb_hydra_cmd_size() returns the length field supplied by the
device for extended commands.  Both command parsers advance through the
received buffer by that length:

  kvaser_usb_hydra_wait_cmd()            pos += cmd_len;
  kvaser_usb_hydra_read_bulk_callback()  pos += cmd_len;

Neither checks that the length is non-zero.  A device that sends an
extended command (cmd_no == CMD_EXTENDED) with a length of zero keeps
pos unchanged, so the loop never terminates.  In
kvaser_usb_hydra_read_bulk_callback() this happens in the URB completion
handler, which also calls kvaser_usb_hydra_handle_cmd() on the same
command in every iteration, and locks up the CPU.  In
kvaser_usb_hydra_wait_cmd() the loop spins in process context without
ever reaching the timeout check.

A command can never be shorter than its header, so treat a shorter
length as a format error in both parsers.

A similar infinite loop in the leaf command parsers was fixed in
commit 0c73772cd2b8 ("can: kvaser_usb: leaf: Fix potential infinite loop in command parsers").

Found by LLM-assisted source review.

Fixes: aec5fb2268b7 ("can: kvaser_usb: Add support for Kvaser USB hydra family")
Cc: stable@vger.kernel.org
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c b/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
index 687911d764de..92bfdcb04b01 100644
--- a/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
+++ b/drivers/net/can/usb/kvaser_usb/kvaser_usb_hydra.c
@@ -676,7 +676,8 @@ static int kvaser_usb_hydra_wait_cmd(const struct kvaser_usb *dev, u8 cmd_no,
 
 			tmp_cmd = buf + pos;
 			cmd_len = kvaser_usb_hydra_cmd_size(tmp_cmd);
-			if (pos + cmd_len > actual_len) {
+			if (cmd_len < sizeof(struct kvaser_cmd_header) ||
+			    pos + cmd_len > actual_len) {
 				dev_err_ratelimited(&dev->intf->dev,
 						    "Format error\n");
 				break;
@@ -2156,6 +2157,11 @@ static void kvaser_usb_hydra_read_bulk_callback(struct kvaser_usb *dev,
 
 		cmd_len = kvaser_usb_hydra_cmd_size(cmd);
 
+		if (cmd_len < sizeof(struct kvaser_cmd_header)) {
+			dev_err(&dev->intf->dev, "Format error\n");
+			return;
+		}
+
 		if (pos + cmd_len > len) {
 			/* We got first part of a command */
 			int leftover_bytes;

-- 
2.43.0

