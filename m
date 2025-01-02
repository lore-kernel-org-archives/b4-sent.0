From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 02 Jan 2025 19:31:50 +0100
Subject: [PATCH 09/19] powerpc: boot: Build devicetrees when
 CONFIG_MPC831x=y
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250102-mpc83xx-v1-9-86f78ba2a7af@posteo.net>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735842735; l=893;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=XjJyRLNOBRP8dGxJA13fx4b2smChJ2cfKB3451J6wqs=;
 b=gmnc4iytyw/+dvM1kg+2tdYLt8bjZsFxnmFDZtWUSklxe3fMmDu7KXGlPW8DD6cw1T4smCFzT
 mLXZOMO1dRiCkO80JYXYkXfSTVloW/oUetQpX+gD5lCg5yh6cqAzjFz
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In order to produce useful FIT images, the kernel needs to know which
devicetrees to build. To that end, follow the same approach as other
architectures, and enable devicetrees per platform.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---

I've only enabled MPC831x devicetrees, because that's the hardware I have.
---
 arch/powerpc/boot/dts/Makefile | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/arch/powerpc/boot/dts/Makefile b/arch/powerpc/boot/dts/Makefile
index 0cd0d8558b475cfe342f36f4b78240ef88dd2e37..6aee895d5baaa2c978d4b1c82a6d198d9e166ea2 100644
--- a/arch/powerpc/boot/dts/Makefile
+++ b/arch/powerpc/boot/dts/Makefile
@@ -3,3 +3,8 @@
 subdir-y += fsl
 
 dtb-$(CONFIG_OF_ALL_DTBS) := $(patsubst $(src)/%.dts,%.dtb, $(wildcard $(src)/*.dts))
+
+dtb-$(CONFIG_MPC831x) += \
+	kmeter1.dtb \
+	mpc8313erdb.dtb \
+	mpc8315erdb.dtb

-- 
2.45.2

