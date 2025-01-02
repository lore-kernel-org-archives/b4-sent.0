From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:48 +0100
Subject: [PATCH 07/19] powerpc: dts: mpc8315erdb: Add missing model
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-7-86f78ba2a7af@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=689;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=i2m+p125oOMi3j6Rp3j8r0hNlqhm4mTOC27OluxVi5k=;
 b=jz8B5ynuEhfVPpf7QliuUWYwuGE/+fLv6S4QEVZTSRKh9vuo7oKhx4K5ZB/3HV0XhXRxx4tyP
 owTd0RUdADtB3j8aGvSMkGCN+0FQkHxUZK5mCetV0Jkq/2JyV31JdqG
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The mpc8315erdb devicetree did thus far not have a /model property, even
though it is required by the devicetree specification.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8315erdb.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/powerpc/boot/dts/mpc8315erdb.dts b/arch/powerpc/boot/dts/mpc8315erdb.dts
index 28c06faf8ce0eb330a0108eba321b4c1127a8ae2..44e82d8b26302b72676badd70c5ab26eba3d08e4 100644
--- a/arch/powerpc/boot/dts/mpc8315erdb.dts
+++ b/arch/powerpc/boot/dts/mpc8315erdb.dts
@@ -9,6 +9,7 @@
 
 / {
 	compatible = "fsl,mpc8315erdb";
+	model = "MPC8315E-RDB";
 
 	aliases {
 		ethernet0 = &enet0;

-- 
2.45.2

