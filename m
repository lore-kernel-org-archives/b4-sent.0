From: Amit Sunil Dhamne <amitsd@google.com>
Date: Fri, 02 May 2025 16:57:03 -0700
Subject: [PATCH] usb: typec: tcpm/tcpci_maxim: Fix bounds check in
 process_rx()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250502-b4-new-fix-pd-rx-count-v1-1-e5711ed09b3d@google.com>
X-B4-Tracking: v=1; b=H4sIAM5bFWgC/x2MywqAIBAAfyX23EJKJfYr0SFrq71YrD0E6d+Tj
 gMzkyCQMAXoigRCNwfefQZVFjBto18Jec4MutJNVWuFrkZPDy4c8ZhRIk775U80VlvjxlZZZyD
 Hh1BW/nE/vO8H7HJeNWgAAAA=
X-Change-ID: 20250421-b4-new-fix-pd-rx-count-79297ba619b7
To: Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Badhri Jagan Sridharan <badhri@google.com>
Cc: =?utf-8?q?Andr=C3=A9_Draszik?= <andre.draszik@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Tudor Ambarus <tudor.ambarus@linaro.org>, RD Babiera <rdbabiera@google.com>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Amit Sunil Dhamne <amitsd@google.com>, 
 Kyle Tso <kyletso@google.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746230235; l=1638;
 i=amitsd@google.com; s=20241031; h=from:subject:message-id;
 bh=vGHl5bogQ6MXAcBZGSBqyO6WniDKbsq9TxUanfyP/D0=;
 b=MQhqKGSoGaDHNV4VW4oJMLEmFrNWzWKJNYBUplKvCqCSZqAVLDl/+35LL0ic7i9TG1NFK70jL
 E5RET5hCJp+BAT2Miq/9XIT16NDxYi/ks97Ovyj79IDKQYKRsAm9XrE
X-Developer-Key: i=amitsd@google.com; a=ed25519;
 pk=wD+XZSST4dmnNZf62/lqJpLm7fiyT8iv462zmQ3H6bI=
X-Endpoint-Received: by B4 Relay for amitsd@google.com/20241031 with auth_id=262
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Register read of TCPC_RX_BYTE_CNT returns the total size consisting of:

  PD message (pending read) size + 1 Byte for Frame Type (SOP*)

This is validated against the max PD message (`struct pd_message`) size
without accounting for the extra byte for the frame type. Note that the
struct pd_message does not contain a field for the frame_type. This
results in false negatives when the "PD message (pending read)" is equal
to the max PD message size.

Fixes: 6f413b559f86 ("usb: typec: tcpci_maxim: Chip level TCPC driver")
Signed-off-by: Amit Sunil Dhamne <amitsd@google.com>
Signed-off-by: Badhri Jagan Sridharan <badhri@google.com>
Reviewed-by: Kyle Tso <kyletso@google.com>
---
 drivers/usb/typec/tcpm/tcpci_maxim_core.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/usb/typec/tcpm/tcpci_maxim_core.c b/drivers/usb/typec/tcpm/tcpci_maxim_core.c
index fd1b80593367641a6f997da2fb97a2b7238f6982..648311f5e3cf135f23b5cc0668001d2f177b9edd 100644
--- a/drivers/usb/typec/tcpm/tcpci_maxim_core.c
+++ b/drivers/usb/typec/tcpm/tcpci_maxim_core.c
@@ -166,7 +166,8 @@ static void process_rx(struct max_tcpci_chip *chip, u16 status)
 		return;
 	}
 
-	if (count > sizeof(struct pd_message) || count + 1 > TCPC_RECEIVE_BUFFER_LEN) {
+	if (count > sizeof(struct pd_message) + 1 ||
+	    count + 1 > TCPC_RECEIVE_BUFFER_LEN) {
 		dev_err(chip->dev, "Invalid TCPC_RX_BYTE_CNT %d\n", count);
 		return;
 	}

---
base-commit: ebd297a2affadb6f6f4d2e5d975c1eda18ac762d
change-id: 20250421-b4-new-fix-pd-rx-count-79297ba619b7

Best regards,
-- 
Amit Sunil Dhamne <amitsd@google.com>

