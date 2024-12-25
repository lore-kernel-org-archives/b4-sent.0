From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Wed, 25 Dec 2024 13:53:42 +0100
Subject: [PATCH] powerpc/microwatt: Fix model property in device tree
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241225-microwatt-v1-1-8e071fcfc2bd@posteo.net>
X-B4-Tracking: v=1; b=H4sIAFUAbGcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDIyNT3dzM5KL88sSSEt0USyNTC0MLy8S0NFMloPqCotS0zAqwWdGxtbU
 AJNlPVVsAAAA=
X-Change-ID: 20241225-microwatt-d9258189aff5
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>, Madhavan Srinivasan <maddy@linux.ibm.com>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1735131236; l=823;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=3C1YCyi76jTrcxunvIWw4CH9zMDlOTH9wFP4VAcUHL0=;
 b=gkj0v9fIXqP50WvdD1SfkJUpjFjLAxSQVPwzXugvNYqFDK0iRkHSiJMzU4XvUxnmld76zHA1p
 pBfh2O1PUKDDClwd94hbm7Hf+I8lRPTvRO7Iz74DKLwhFi4IFvtAdAJ
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The standard property for the model name is called "model".

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/microwatt.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/powerpc/boot/dts/microwatt.dts b/arch/powerpc/boot/dts/microwatt.dts
index 269e930b3b0b14a2bf6a76261062294c1d003c72..162b5f2f8aac2d6c50824b55a8b894a19d741f07 100644
--- a/arch/powerpc/boot/dts/microwatt.dts
+++ b/arch/powerpc/boot/dts/microwatt.dts
@@ -3,7 +3,7 @@
 / {
 	#size-cells = <0x02>;
 	#address-cells = <0x02>;
-	model-name = "microwatt";
+	model = "microwatt";
 	compatible = "microwatt-soc";
 
 	aliases {

---
base-commit: 4bbf9020becbfd8fc2c3da790855b7042fad455b
change-id: 20241225-microwatt-d9258189aff5

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

