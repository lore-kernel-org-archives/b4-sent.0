From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sat, 10 Oct 2026 23:07:57 +0200
Subject: [PATCH 09/11] usb: gadget: f_acm: check the acm_stdio_puts()
 against an unstarted device
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-b4-phonemenu-series-v1-9-bfa23de6eb0b@protonmail.com>
References: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
In-Reply-To: <20261010-b4-phonemenu-series-v1-0-bfa23de6eb0b@protonmail.com>
To: u-boot@lists.u-boot-project.org
Cc: Tom Rini <trini@konsulko.com>, 
 "Kory Maincent (TI.com)" <kory.maincent@bootlin.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Michael Trimarchi <michael@amarulasolutions.com>, 
 Mikhail Kshevetskiy <mikhail.kshevetskiy@iopsys.eu>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Frank Wunderlich <frank-w@public-files.de>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Heiko Schocher <hs@nabladev.com>, 
 Andrew Goodbody <andrew.goodbody@linaro.org>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Peter Robinson <pbrobinson@gmail.com>, Brian Sune <briansune@gmail.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Anatolij Gustschin <ag.dev.uboot@gmail.com>, Petr Pavlata <petr@acrux.cz>, 
 David Heidelberg <david@ixit.cz>, 
 =?utf-8?q?Guido_G=C3=BCnther?= <agx@sigxcpu.org>, 
 Alexander Martinz <amartinz@shiftphones.com>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791666485; l=712;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=JyCzEoNpBtsiWXoxzkm+I2ie19oOjjjfAo3JE5XeouA=;
 b=ieZmjf8fuIxZ7RzEB5h+IN70bGr9btiLhKA5J0mESVMXmM75st7Ul94/ul7vsukBSiip/4FI/
 xvOI3lezkaFArs74Cp+PtmV2sD6Dchqwu9tLy+qH4XmjXQ681aN7axJ
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dev->priv (the f_acm struct) is only allocated by acm_stdio_start()
so prevent acm_stdio_puts() to dereferenced it unconditionally.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 drivers/usb/gadget/f_acm.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/usb/gadget/f_acm.c b/drivers/usb/gadget/f_acm.c
index b6c11d97a62..b661ef4b0cf 100644
--- a/drivers/usb/gadget/f_acm.c
+++ b/drivers/usb/gadget/f_acm.c
@@ -612,6 +612,9 @@ static void acm_stdio_puts(struct stdio_dev *dev, const char *str)
 {
 	struct f_acm *f_acm = stdio_to_acm(dev);
 
+	if (!f_acm)
+		return;
+
 	while (*str) {
 		if (*str == '\n')
 			buf_push(&f_acm->tx_buf, "\r", 1);

-- 
2.55.0

