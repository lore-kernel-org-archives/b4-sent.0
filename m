From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v3 0/2] usb: typec: Find a Type-C partner after a warm
 reboot on the Orange Pi 5
Date: Thu, 26 Nov 2026 09:19:20 +0000
Message-Id: <20261126-tcpm-attach-reboot-v3-0-1c97dfa5024a@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/32Nyw7CIBQFf6VhLYZHH9aV/2FcwIW2GFsaQKJp+
 u9C3XRhXE5yzsyCvHZGe3QuFuR0NN7YKQE/FAgGMfUaG5UYMcJqSinBAeYRixAEDNhpaW3AquW
 q6nhdEi5ROs5Od+a1Sa+3L/unvGsI2ZQXg/HBuvdWjTTv/gYixQQ3ddUAUM0UiEs/CvM4gh1RD
 kS2V7CfCpYUspRQgzjxsiV7xbquH4Iq5u8JAQAA
X-Change-ID: 20261110-tcpm-attach-reboot-d93d5f36403b
To: Badhri Jagan Sridharan <badhri@google.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Guenter Roeck <linux@roeck-us.net>, Heiko Stuebner <heiko@sntech.de>
Cc: linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 Arun Iyengar <aiyengar1990@gmail.com>, stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795684760; l=1385;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=O8mJr7+GZG2WrudGQ9eZZi1UioAIWkg07uAFPVTyYSU=;
 b=GA9s3Yl1E+f6Nk1yfkUbft03ym7vcUn4ZSTL1j7Pzs8LGaQ6jkS+AQr0uamuXWBhYGc9IiOYg
 ft/6LOPSeyHCD2EFF8mbH03W4AUfswZ2lTkN1cZBWewx/Q9dyAvEomb
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After a warm reboot, an Orange Pi 5 (FUSB302) often did not find a
USB-C to DisplayPort cable that stayed plugged in; only a replug
brought DisplayPort back. Two causes:

  1. tcpm: a re-queue at port registration cut the 100 ms
     ErrorRecovery after PORT_RESET to 6 us.
  2. fusb302: the chip never found this cable while toggling with
     Rp 3.0A.

Tested on an Orange Pi 5 with a USB-C DisplayPort monitor: DP alt mode
on 16/16 warm reboots. Not tested: other TCPCs, ports without PD.

Developed with Claude (Anthropic), which wrote the code and the commit
messages. I reviewed every change.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v3:
- Patch 2: Cc stable (Heikki Krogerus)
- Code comments dropped, shorter messages, no functional change
- Link to v2: https://patch.msgid.link/20261112-tcpm-attach-reboot-v2-0-b4bc6ca83490@gmail.com

---
Arun Iyengar (2):
      usb: typec: tcpm: Don't cut a pending state delay short on a re-queue
      usb: typec: fusb302: Toggle with the default Rp current

 drivers/usb/typec/tcpm/fusb302.c | 12 ++++++++++--
 drivers/usb/typec/tcpm/tcpm.c    |  5 +++++
 2 files changed, 15 insertions(+), 2 deletions(-)
---
base-commit: 90d6263e867be7089b3d3323bef8d2accd327c77
change-id: 20261110-tcpm-attach-reboot-d93d5f36403b

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

