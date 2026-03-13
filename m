From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Fri, 13 Mar 2026 11:14:24 +0100
Subject: [PATCH 2/2] powerpc: dts: Add missing model properties
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260313-ppc-model-v1-2-bf19b3d1b65d@posteo.net>
References: <20260313-ppc-model-v1-0-bf19b3d1b65d@posteo.net>
In-Reply-To: <20260313-ppc-model-v1-0-bf19b3d1b65d@posteo.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>
Cc: devicetree@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773396881; l=3236;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=qyXxRV38xWkpDO+hT68IGUbfYPxG01yo3fihfYhDmgU=;
 b=MGt01luTb+JtIHA5onvF3/Xiuo5FxKvu4GNC6SUJCflpd0lvLCTUuURz46iyDEhNRvlL18oMI
 nebfhkFGMQ1Bud9z7D1Vu2OPt30215o7ucVsq+aqJGjg0V2dtd9wlFW
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These are the remaining PowerPC devicetrees that do not have a /model
property, even though it is required by the devicetree specification.
Fix them by simply copying the compatible string.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/boot/dts/mpc8308_p1m.dts  | 1 +
 arch/powerpc/boot/dts/mpc8308rdb.dts   | 1 +
 arch/powerpc/boot/dts/mpc836x_rdk.dts  | 1 +
 arch/powerpc/boot/dts/mpc8377_rdb.dts  | 1 +
 arch/powerpc/boot/dts/mpc8377_wlan.dts | 1 +
 arch/powerpc/boot/dts/mpc8378_rdb.dts  | 1 +
 arch/powerpc/boot/dts/mpc8379_rdb.dts  | 1 +
 7 files changed, 7 insertions(+)

diff --git a/arch/powerpc/boot/dts/mpc8308_p1m.dts b/arch/powerpc/boot/dts/mpc8308_p1m.dts
index 2638555afcc454..2b24efd944113c 100644
--- a/arch/powerpc/boot/dts/mpc8308_p1m.dts
+++ b/arch/powerpc/boot/dts/mpc8308_p1m.dts
@@ -9,6 +9,7 @@
 
 / {
 	compatible = "denx,mpc8308_p1m";
+	model = "denx,mpc8308_p1m";
 	#address-cells = <1>;
 	#size-cells = <1>;
 
diff --git a/arch/powerpc/boot/dts/mpc8308rdb.dts b/arch/powerpc/boot/dts/mpc8308rdb.dts
index af2ed8380a867c..37b785dc787b7c 100644
--- a/arch/powerpc/boot/dts/mpc8308rdb.dts
+++ b/arch/powerpc/boot/dts/mpc8308rdb.dts
@@ -10,6 +10,7 @@
 
 / {
 	compatible = "fsl,mpc8308rdb";
+	model = "fsl,mpc8308rdb";
 	#address-cells = <1>;
 	#size-cells = <1>;
 
diff --git a/arch/powerpc/boot/dts/mpc836x_rdk.dts b/arch/powerpc/boot/dts/mpc836x_rdk.dts
index 4ff38e1a2185f8..d3d36fbf4e8695 100644
--- a/arch/powerpc/boot/dts/mpc836x_rdk.dts
+++ b/arch/powerpc/boot/dts/mpc836x_rdk.dts
@@ -14,6 +14,7 @@ / {
 	#address-cells = <1>;
 	#size-cells = <1>;
 	compatible = "fsl,mpc8360rdk";
+	model = "fsl,mpc8360rdk";
 
 	aliases {
 		serial0 = &serial0;
diff --git a/arch/powerpc/boot/dts/mpc8377_rdb.dts b/arch/powerpc/boot/dts/mpc8377_rdb.dts
index f137ccb8cfdedf..45f78da31da182 100644
--- a/arch/powerpc/boot/dts/mpc8377_rdb.dts
+++ b/arch/powerpc/boot/dts/mpc8377_rdb.dts
@@ -9,6 +9,7 @@
 
 / {
 	compatible = "fsl,mpc8377rdb";
+	model = "fsl,mpc8377rdb";
 	#address-cells = <1>;
 	#size-cells = <1>;
 
diff --git a/arch/powerpc/boot/dts/mpc8377_wlan.dts b/arch/powerpc/boot/dts/mpc8377_wlan.dts
index ce254dd74dd06b..318e2e1f4284f2 100644
--- a/arch/powerpc/boot/dts/mpc8377_wlan.dts
+++ b/arch/powerpc/boot/dts/mpc8377_wlan.dts
@@ -10,6 +10,7 @@
 
 / {
 	compatible = "fsl,mpc8377wlan";
+	model = "fsl,mpc8377wlan";
 	#address-cells = <1>;
 	#size-cells = <1>;
 
diff --git a/arch/powerpc/boot/dts/mpc8378_rdb.dts b/arch/powerpc/boot/dts/mpc8378_rdb.dts
index 19e5473d4161b5..1abec806525844 100644
--- a/arch/powerpc/boot/dts/mpc8378_rdb.dts
+++ b/arch/powerpc/boot/dts/mpc8378_rdb.dts
@@ -9,6 +9,7 @@
 
 / {
 	compatible = "fsl,mpc8378rdb";
+	model = "fsl,mpc8378rdb";
 	#address-cells = <1>;
 	#size-cells = <1>;
 
diff --git a/arch/powerpc/boot/dts/mpc8379_rdb.dts b/arch/powerpc/boot/dts/mpc8379_rdb.dts
index 61519acca22804..b1e6a85624bef8 100644
--- a/arch/powerpc/boot/dts/mpc8379_rdb.dts
+++ b/arch/powerpc/boot/dts/mpc8379_rdb.dts
@@ -9,6 +9,7 @@
 
 / {
 	compatible = "fsl,mpc8379rdb";
+	model = "fsl,mpc8379rdb";
 	#address-cells = <1>;
 	#size-cells = <1>;
 

-- 
2.51.0

