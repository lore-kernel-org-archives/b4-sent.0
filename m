From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:54 +0100
Subject: [PATCH 13/19] gpio: mpc8xxx: Add MPC8314 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-13-86f78ba2a7af@posteo.net>
References: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
In-Reply-To: <20250102-mpc83xx-v1-0-86f78ba2a7af@posteo.net>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, Frank Li <Frank.Li@nxp.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-gpio@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=815;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=IzujOZGh0Kdf7MR+FJDNa5Xge4jQ4IpjSUXuri6ZMCE=;
 b=Bg2Rwn5IPjZBCymZj2nPxRzynUvjtK0um3nebcnWTTRob7hfmVj+4hlVA6truDJxyBTZK1mYV
 E2XU37nLAAqCiLpCLQ1oQAs3PvepM7Q7YTnN9sKE6no/AuaZzWCsdZ7
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

GPIO input, output, and interrupts have been tested on a MPC8314E board.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 drivers/gpio/gpio-mpc8xxx.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/gpio/gpio-mpc8xxx.c b/drivers/gpio/gpio-mpc8xxx.c
index 24417c3247b0a832ad15fe93e9ba0339eac3b883..0cd4c36ae8aaf075a54795810d5eea755325d771 100644
--- a/drivers/gpio/gpio-mpc8xxx.c
+++ b/drivers/gpio/gpio-mpc8xxx.c
@@ -285,6 +285,7 @@ static const struct mpc8xxx_gpio_devtype mpc8xxx_gpio_devtype_default = {
 };
 
 static const struct of_device_id mpc8xxx_gpio_ids[] = {
+	{ .compatible = "fsl,mpc8314-gpio", },
 	{ .compatible = "fsl,mpc8349-gpio", },
 	{ .compatible = "fsl,mpc8572-gpio", .data = &mpc8572_gpio_devtype, },
 	{ .compatible = "fsl,mpc8610-gpio", },

-- 
2.45.2

