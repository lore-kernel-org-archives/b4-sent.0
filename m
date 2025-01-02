From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:51 +0100
Subject: [PATCH 10/19] powerpc: dts: Add MPC8314E devicetree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-10-86f78ba2a7af@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=700;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=iJjsNtyNoaNU2zY47Wv9zZ+eAHSNUrFXjwgqJp3n0GM=;
 b=/hziTWMuTlV1P/hE3RO9qdSuDxn2Tgq0iTXT9NLI1DfKaJCijj1zAtFX2/zROAJn+CSjfQIeV
 aVmXNG9Z377Bcy1AgtoBVBdsz5VRDJOAmy4W6DgRCvAQXW3mczS1ogD
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The MPC8314E is a variant of the MPC8315E without SATA controllers.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8314e.dtsi | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/arch/powerpc/boot/dts/mpc8314e.dtsi b/arch/powerpc/boot/dts/mpc8314e.dtsi
new file mode 100644
index 0000000000000000000000000000000000000000..65a96a485dded5d4918d96b38778399d2f348190
--- /dev/null
+++ b/arch/powerpc/boot/dts/mpc8314e.dtsi
@@ -0,0 +1,7 @@
+// SPDX-License-Identifier: GPL-2.0-or-later
+// Copyright 2024 J. Neuschäfer
+#include "mpc8315e.dtsi"
+
+/* MPC8314E does not support SATA */
+/delete-node/ &sata0;
+/delete-node/ &sata1;

-- 
2.45.2

