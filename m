From: Matt Johnston <matt@codeconstruct.com.au>
Date: Fri, 18 Oct 2024 11:07:56 +0800
Subject: [PATCH net] mctp i2c: handle NULL header address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241018-mctp-i2c-null-dest-v1-1-ba1ab52966e9@codeconstruct.com.au>
X-B4-Tracking: v=1; b=H4sIAAvREWcC/x3MQQqAIBBA0avErBtQEYquEi1MpxowC7UIwrsnL
 d/i/xcSRaYEQ/NCpJsTH6FCtg3YzYSVkF01KKG0FLLH3eYTWVkMl/foKGU0YjaqkySs7qGGZ6S
 Fn386QqAMUykfIW658GkAAAA=
To: Jeremy Kerr <jk@codeconstruct.com.au>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, stable@vger.kernel.org, 
 Dung Cao <dung@os.amperecomputing.com>, 
 Matt Johnston <matt@codeconstruct.com.au>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729220892; l=1006;
 i=matt@codeconstruct.com.au; s=20241018; h=from:subject:message-id;
 bh=7a9bBX5OhQLyOr0r2mEwMYUi2yLjFDmAXhWqLtXX1W8=;
 b=/kNBRjdGOn742jnFpm20G3DlxvqTct2cMcXuCtIZTiEISmQex18y9fVEgY0Ii8Ngu8YDHGt+7
 u6RB0cOeiE3AhBqtNltj+KYY4be3ke+hCZ26q0kNMwb8ifYDVhMCybB
X-Developer-Key: i=matt@codeconstruct.com.au; a=ed25519;
 pk=exersTcCYD/pEBOzXGO6HkLd6kKXRuWxHhj+LXn3DYE=
X-Endpoint-Received: by B4 Relay for matt@codeconstruct.com.au/20241018 with auth_id=253
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

daddr can be NULL if there is no neighbour table entry present,
in that case the tx packet should be dropped.

Fixes: f5b8abf9fc3d ("mctp i2c: MCTP I2C binding driver")
Cc: stable@vger.kernel.org
Reported-by: Dung Cao <dung@os.amperecomputing.com>
Signed-off-by: Matt Johnston <matt@codeconstruct.com.au>
---
 drivers/net/mctp/mctp-i2c.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git drivers/net/mctp/mctp-i2c.c drivers/net/mctp/mctp-i2c.c
index 4dc057c121f5..e70fb6687994 100644
--- drivers/net/mctp/mctp-i2c.c
+++ drivers/net/mctp/mctp-i2c.c
@@ -588,6 +588,9 @@ static int mctp_i2c_header_create(struct sk_buff *skb, struct net_device *dev,
 	if (len > MCTP_I2C_MAXMTU)
 		return -EMSGSIZE;
 
+	if (!daddr || !saddr)
+		return -EINVAL;
+
 	lldst = *((u8 *)daddr);
 	llsrc = *((u8 *)saddr);
 

---
base-commit: cb560795c8c2ceca1d36a95f0d1b2eafc4074e37
change-id: 20241018-mctp-i2c-null-dest-a0ba271e0c48

Best regards,
-- 
Matt Johnston <matt@codeconstruct.com.au>

