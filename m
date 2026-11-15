From: Jonas Juffinger <jonas.juffinger@liebherr.com>
Subject: [PATCH 0/2] serial: fsl_lpuart: 8-bit FSL-LPUART driver
 improvements
Date: Sun, 15 Nov 2026 19:01:55 +0100
Message-Id: <20261115-fsl_lpuart_8_bit_break_detection-v1-0-b7ac2307dd55@liebherr.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJPz+WoC/yWNUQqDMBAFryL73UBibJVepUhIzKbdVqxsYimId
 3dtPwfmzVshIxNmuFYrMH4o03sSMKcKhoef7qgoCkOt64sx5qxSHt04L56L61yg4gKjf7mIBYc
 iY9W1uo2NtU2yGiQzMyb6/i5u/Z/zEp5iH13Yth0C9D/RhAAAAA==
X-Change-ID: 20261115-fsl_lpuart_8_bit_break_detection-8707d4334f30
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-serial@vger.kernel.org, 
 michael@walle.cc, sherry.sun@nxp.com, 
 Jonas Juffinger <jonas.juffinger@liebherr.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794765771; l=707;
 i=jonas.juffinger@liebherr.com; s=20260615; h=from:subject:message-id;
 bh=fnQPw0pmRVdCP+5XQzrfDbwdYcVNnwCxka3433C0+4A=;
 b=jEHvDvl+O1IqBZEXiC0TmN3OkceNCHSmhP+tYDhhbzeJslHsniqg5Q4w1XS7UOnAfKvtk1eqe
 8ImrOLrm3RlC8tv5/XNzcFmsARTAL+H4ft6ojerCOBIXZW5EQ2B0flk
X-Developer-Key: i=jonas.juffinger@liebherr.com; a=ed25519;
 pk=57Vzs2aKTP3E7TDrBuZMQibGR+Koattc4oIhiMOs3FI=
X-Endpoint-Received: by B4 Relay for jonas.juffinger@liebherr.com/20260615 with auth_id=821
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add break detection that is currently only working in the 32-bit part of
the driver.
Enable DMA for TX when it is a console for the 8-bit part of the driver.

Signed-off-by: Jonas Juffinger <jonas.juffinger@liebherr.com>
---
Jonas Juffinger (2):
      serial: fsl_lpuart: Enable break detection in 8-bit driver
      serial: fsl_lpuart: Enable DMA for TX in console mode

 drivers/tty/serial/fsl_lpuart.c | 35 ++++++++++++++++++++++++-----------
 1 file changed, 24 insertions(+), 11 deletions(-)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261115-fsl_lpuart_8_bit_break_detection-8707d4334f30

Best regards,
--  
Jonas Juffinger <jonas.juffinger@liebherr.com>

